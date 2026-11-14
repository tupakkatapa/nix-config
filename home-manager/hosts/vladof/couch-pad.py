"""Couch pad: the Xbox button is the home key; in a game it is the game's
own, and opens the menu only with the right paddle held. Outside the games
the pad drives the menu, is a mouse and a keyboard, and opens an on-screen
keyboard with Menu. Outside the games it holds the pad, so a game left
running hidden stays quiet; the game on screen gets the pad to itself."""

import glob
import os
import select
import signal
import subprocess
import sys
import threading
import time

import evdev
import i3ipc
from evdev import ecodes as e

GAMES = ("/couch-retroarch.scope", "/couch-rt.steam.scope", "/app-steam-app")
TICK = 0.01
# At full deflection: pixels per tick, and wheel units per tick (120 a notch)
POINTER = 8
SCROLL = 24
DEADZONE = 0.15
# A held d-pad moves across the on-screen keyboard: delay, then interval
REPEAT = (0.4, 0.1)

MENU, APP, GAME = range(3)
STICKS = (e.ABS_X, e.ABS_Y, e.ABS_RX, e.ABS_RY)
HATS = {
    e.ABS_HAT0X: (e.KEY_LEFT, e.KEY_RIGHT),
    e.ABS_HAT0Y: (e.KEY_UP, e.KEY_DOWN),
}

# With a paddle held the pad is a remote, in a game too: the d-pad turns the
# volume and skips tracks, A plays and pauses, B mutes
REMOTE = e.BTN_GRIPR
REMOTE_HATS = {
    e.ABS_HAT0X: (e.KEY_PREVIOUSSONG, e.KEY_NEXTSONG),
    e.ABS_HAT0Y: (e.KEY_VOLUMEUP, e.KEY_VOLUMEDOWN),
}
REMOTE_KEYS = {e.BTN_A: e.KEY_PLAYPAUSE, e.BTN_B: e.KEY_MUTE}
REMOTE_OUT = {
    *REMOTE_KEYS.values(),
    *(key for pair in REMOTE_HATS.values() for key in pair),
}
# On the menu A picks and B closes. In an app, buttons that act as a key
# while held, and ones that tap a chord: the bumpers for the next and the
# previous tab, X to close the tab. In Firefox Y runs the home command, and
# Menu the keyboard, both given in the environment
MENU_KEYS = {e.BTN_A: e.KEY_ENTER, e.BTN_B: e.KEY_ESC}
APP_KEYS = {
    e.BTN_A: e.BTN_LEFT,
    e.BTN_THUMBR: e.BTN_RIGHT,
    e.BTN_B: e.KEY_BACKSPACE,
    e.BTN_SELECT: e.KEY_ESC,
}
APP_CHORDS = {
    e.BTN_X: (e.KEY_LEFTCTRL, e.KEY_W),
    e.BTN_TR: (e.KEY_LEFTCTRL, e.KEY_TAB),
    e.BTN_TL: (e.KEY_LEFTCTRL, e.KEY_LEFTSHIFT, e.KEY_TAB),
}
# With the on-screen keyboard open; the d-pad and A, X go to the keyboard
OSK_KEYS = {
    e.BTN_B: e.KEY_BACKSPACE,
    e.BTN_Y: e.KEY_SPACE,
    e.BTN_TL: e.KEY_LEFT,
    e.BTN_TR: e.KEY_RIGHT,
}
OSK_COMMANDS = {e.BTN_A: b"press", e.BTN_X: b"shift"}
OSK_MOVES = {e.ABS_HAT0X: (b"left", b"right"), e.ABS_HAT0Y: (b"up", b"down")}

OUTPUT_KEYS = list(range(e.KEY_ESC, e.KEY_KPDOT + 1)) + [
    e.KEY_RIGHTALT,
    e.KEY_LEFTMETA,
    *REMOTE_OUT,
    *(key for pair in HATS.values() for key in pair),
    e.BTN_LEFT,
    e.BTN_RIGHT,
]


def connect():
    """Sway's IPC, through whichever of its sockets answers."""
    sockets = glob.glob(f"{os.environ['XDG_RUNTIME_DIR']}/sway-ipc.*")
    for socket in [os.environ.get("SWAYSOCK"), *sockets]:
        if socket:
            try:
                return i3ipc.Connection(socket_path=socket)
            except (OSError, ConnectionError):
                pass
    raise OSError("sway is not running")


def mode_of(sway):
    """What is on screen: nothing but the menu, a game, or another app, and
    the app's id."""
    focused = sway.get_tree().find_focused()
    if focused is None or focused.pid is None:
        return MENU, None
    try:
        with open(f"/proc/{focused.pid}/cgroup") as cgroup:
            scopes = cgroup.read()
        if any(scope in scopes for scope in GAMES):
            return GAME, focused.app_id
    except OSError:
        pass
    return APP, focused.app_id


def curve(value):
    """A stick's deflection in -1..1 as a response: nothing inside the dead
    zone, then rising gently so small moves are precise."""
    size = abs(value)
    if size < DEADZONE:
        return 0.0
    size = (size - DEADZONE) / (1 - DEADZONE)
    return size * size if value > 0 else -size * size


class Smooth:
    """Whole steps out of fractional motion, the remainder carried over."""

    def __init__(self):
        self.rest = 0.0

    def step(self, amount):
        self.rest += amount
        whole = int(self.rest)
        self.rest -= whole
        return whole


class Couch:
    def __init__(self, path):
        self.pad = evdev.InputDevice(path)
        self.keyboard = os.environ["COUCH_KEYBOARD"].split()
        self.home = os.environ["COUCH_HOME"].split()
        self.out = evdev.UInput(
            {
                e.EV_KEY: OUTPUT_KEYS,
                e.EV_REL: [
                    e.REL_X,
                    e.REL_Y,
                    e.REL_WHEEL,
                    e.REL_WHEEL_HI_RES,
                    e.REL_HWHEEL,
                    e.REL_HWHEEL_HI_RES,
                ],
            },
            name="Couch pad",
            vendor=0x0C0C,
            product=0x0001,
        )
        self.mode = MENU
        self.app = None
        self.seen = MENU
        self.held = set()
        self.grabbed = False
        self.remote = False
        self.overlay = False
        self.osk = None
        self.osk_buffer = b""
        self.repeats = {}
        self.ranges = {}
        self.sticks = dict.fromkeys(STICKS, 0.0)
        for code in STICKS:
            info = self.pad.absinfo(code)
            self.ranges[code] = (info.min, (info.max - info.min) / 2)
        self.motion = {code: Smooth() for code in STICKS}
        self.notches = {e.REL_WHEEL: 0, e.REL_HWHEEL: 0}
        # The focus watcher wakes the loop up through this
        self.wake_read, self.wake_write = os.pipe()
        threading.Thread(target=self.watch_focus, daemon=True).start()

    def watch_focus(self):
        """Keeps the mode current for as long as sway runs."""
        while True:
            try:
                sway = connect()
                self.set_mode(*mode_of(sway))
                for event in ("WINDOW", "WORKSPACE", "OUTPUT"):
                    sway.on(
                        i3ipc.Event[event],
                        lambda sway, _: self.set_mode(*mode_of(sway)),
                    )
                sway.main()
            except (OSError, ConnectionError):
                pass
            self.set_mode(MENU)
            time.sleep(1)

    def set_mode(self, mode, app=None):
        self.mode, self.app = mode, app
        os.write(self.wake_write, b"\0")

    # The menu over an app is the pad's too; the menu tells when it opens and
    # closes
    def set_overlay(self, on):
        self.overlay = on
        os.write(self.wake_write, b"\0")

    # A mode change releases what is held: a key pressed in one mode would
    # never see its release in the next
    def enter(self, mode):
        self.seen = mode
        for code in list(self.held):
            self.key(code, 0)
        self.repeats.clear()
        self.close_osk()
        self.grab(mode != GAME or self.remote)

    # A game has the pad to itself, except while the remote is held
    def grab(self, want):
        try:
            if want and not self.grabbed:
                self.pad.grab()
            elif not want and self.grabbed:
                self.pad.ungrab()
        except OSError:
            return
        self.grabbed = want

    def key(self, code, value):
        self.out.write(e.EV_KEY, code, value)
        if value:
            self.held.add(code)
        else:
            self.held.discard(code)

    def tap(self, codes):
        for code in codes:
            self.key(code, 1)
        self.out.syn()
        for code in reversed(codes):
            self.key(code, 0)

    def open_osk(self):
        self.osk = subprocess.Popen(
            self.keyboard, stdin=subprocess.PIPE, stdout=subprocess.PIPE
        )
        self.osk_buffer = b""

    def close_osk(self):
        if not self.osk:
            return
        osk, self.osk = self.osk, None
        try:
            osk.stdin.close()
            osk.wait(1)
        except (OSError, subprocess.TimeoutExpired):
            osk.kill()
            osk.wait()

    def tell(self, command):
        try:
            self.osk.stdin.write(command + b"\n")
            self.osk.stdin.flush()
        except OSError:
            self.close_osk()

    # The keyboard prints the keys to type, and ends itself after Enter
    def hear(self):
        data = os.read(self.osk.stdout.fileno(), 4096)
        if not data:
            self.close_osk()
            return
        self.osk_buffer += data
        while b"\n" in self.osk_buffer:
            line, self.osk_buffer = self.osk_buffer.split(b"\n", 1)
            self.tap([e.ecodes[name] for name in line.decode().split()])

    def handle(self, event):
        code, value = event.code, event.value
        if event.type == e.EV_ABS and code in STICKS:
            low, half = self.ranges[code]
            self.sticks[code] = (value - low - half) / half
        elif event.type == e.EV_KEY and code == e.BTN_MODE:
            if self.seen != GAME or self.remote:
                self.key(e.KEY_LEFTMETA, value)
        elif event.type == e.EV_KEY and code == REMOTE:
            self.remote = bool(value)
            for key in self.held & REMOTE_OUT:
                self.key(key, 0)
            self.grab(self.seen != GAME or self.remote)
        elif self.remote:
            if event.type == e.EV_ABS and code in REMOTE_HATS:
                self.hat(code, value, REMOTE_HATS)
            elif event.type == e.EV_KEY and code in REMOTE_KEYS:
                self.key(REMOTE_KEYS[code], value)
        elif self.seen == GAME:
            pass
        elif self.seen == MENU:
            if event.type == e.EV_ABS and code in HATS:
                self.hat(code, value)
            elif event.type == e.EV_KEY and code in MENU_KEYS:
                self.key(MENU_KEYS[code], value)
        elif self.osk:
            if event.type == e.EV_ABS and code in OSK_MOVES:
                self.repeats.pop(code, None)
                if value:
                    command = OSK_MOVES[code][value > 0]
                    self.tell(command)
                    due = time.monotonic() + REPEAT[0]
                    self.repeats[code] = (command, due)
            elif event.type == e.EV_KEY and code in OSK_COMMANDS:
                if value == 1:
                    self.tell(OSK_COMMANDS[code])
            elif event.type == e.EV_KEY and code in OSK_KEYS:
                self.key(OSK_KEYS[code], value)
            elif event.type == e.EV_KEY and value == 1:
                if code in (e.BTN_START, e.BTN_SELECT):
                    self.close_osk()
        else:
            if event.type == e.EV_ABS and code in HATS:
                self.hat(code, value)
            elif event.type == e.EV_KEY and code in APP_KEYS:
                self.key(APP_KEYS[code], value)
            elif event.type == e.EV_KEY and value == 1:
                if code in APP_CHORDS:
                    self.tap(APP_CHORDS[code])
                elif code == e.BTN_Y and self.app == "firefox":
                    subprocess.Popen(self.home)
                elif code == e.BTN_START:
                    self.open_osk()

    def hat(self, code, value, pairs=HATS):
        low, high = pairs[code]
        self.key(low, int(value < 0))
        self.key(high, int(value > 0))

    def tick(self):
        """Motion for the sticks held right now, and the keyboard's repeats."""
        if self.seen != GAME:
            x = self.amount(e.ABS_X, POINTER)
            y = self.amount(e.ABS_Y, POINTER)
            if x or y:
                self.out.write(e.EV_REL, e.REL_X, x)
                self.out.write(e.EV_REL, e.REL_Y, y)
            self.scroll(e.ABS_RX, e.REL_HWHEEL, e.REL_HWHEEL_HI_RES, 1)
            self.scroll(e.ABS_RY, e.REL_WHEEL, e.REL_WHEEL_HI_RES, -1)
        now = time.monotonic()
        for code, (command, due) in list(self.repeats.items()):
            if now >= due:
                self.tell(command)
                self.repeats[code] = (command, due + REPEAT[1])

    def amount(self, stick, gain):
        """The stick's whole steps this tick."""
        return self.motion[stick].step(curve(self.sticks[stick]) * gain)

    def scroll(self, stick, wheel, fine, sign):
        units = self.amount(stick, SCROLL * sign)
        if not units:
            return
        self.out.write(e.EV_REL, fine, units)
        self.notches[wheel] += units
        while abs(self.notches[wheel]) >= 120:
            notch = 1 if self.notches[wheel] > 0 else -1
            self.out.write(e.EV_REL, wheel, notch)
            self.notches[wheel] -= 120 * notch

    def moving(self):
        return self.repeats or any(curve(v) for v in self.sticks.values())

    def run(self):
        """Ends when the pad is gone."""
        self.enter(MENU if self.overlay else self.mode)
        while True:
            watched = [self.pad, self.wake_read]
            if self.osk:
                watched.append(self.osk.stdout)
            timeout = TICK if self.moving() else None
            ready, _, _ = select.select(watched, [], [], timeout)
            if self.wake_read in ready:
                os.read(self.wake_read, 64)
            wanted = MENU if self.overlay else self.mode
            if wanted != self.seen:
                self.enter(wanted)
            if self.osk and self.osk.stdout in ready:
                self.hear()
            if self.pad in ready:
                try:
                    for event in self.pad.read():
                        self.handle(event)
                except OSError:
                    self.close_osk()
                    return
            self.tick()
            self.out.syn()


if __name__ == "__main__":
    # The keyboard and the home command need the display, which a pad
    # connected early does not know yet
    displays = glob.glob(f"{os.environ['XDG_RUNTIME_DIR']}/wayland-[0-9]")
    for display in displays[:1]:
        os.environ.setdefault("WAYLAND_DISPLAY", os.path.basename(display))
    couch = Couch(sys.argv[1])
    signal.signal(signal.SIGUSR1, lambda *_: couch.set_overlay(True))
    signal.signal(signal.SIGUSR2, lambda *_: couch.set_overlay(False))
    couch.run()
