"""On-screen keyboard for the pad. couch-pad sends it moves on stdin and types
the keys it prints, so the focused window keeps the keyboard focus, and it
ends itself after Enter. The keys are the Finnish layout's by position, for
xkb to turn into characters."""

import os
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import GLib, Gtk, GtkLayerShell  # noqa: E402


def letters(chars):
    return [(f"KEY_{c.upper()}", c, c.upper()) for c in chars]


# (key or chord, label, shifted label) per row, 11 columns each; the bottom
# row's keys span 2+1+1+1+2+2+2 of them
ROWS = [
    [(f"KEY_{n}", n, s) for n, s in zip("1234567890", '!"#¤%&/()=')]
    + [("KEY_MINUS", "+", "?")],
    letters("qwertyuiop") + [("KEY_LEFTBRACE", "å", "Å")],
    letters("asdfghjkl")
    + [("KEY_SEMICOLON", "ö", "Ö"), ("KEY_APOSTROPHE", "ä", "Ä")],
    [("KEY_102ND", "<", ">")]
    + letters("zxcvbnm")
    + [("KEY_COMMA", ",", ";"), ("KEY_DOT", ".", ":")]
    + [("KEY_SLASH", "-", "_")],
    [
        ("shift", "⇧", "⇧"),
        ("KEY_LEFTSHIFT KEY_7", "/", "/"),
        ("KEY_LEFTSHIFT KEY_DOT", ":", ":"),
        ("KEY_RIGHTALT KEY_2", "@", "@"),
        ("KEY_SPACE", "space", "space"),
        ("KEY_BACKSPACE", "⌫", "⌫"),
        ("KEY_ENTER", "⏎", "⏎"),
    ],
]
SPANS = [[1] * len(row) for row in ROWS[:-1]] + [[2, 1, 1, 1, 2, 2, 2]]
# Each key's first column, per row
STARTS = [[sum(spans[:i]) for i in range(len(spans))] for spans in SPANS]
# The middle of the letters, fewest moves to any of them
START = (2, 4)
OFF, ONCE, LOCKED = range(3)
HINT = "A type · B delete · X shift · Y space · LB RB cursor · Menu close"


class Keyboard(Gtk.Window):
    def __init__(self, css):
        super().__init__()
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 24)
        # Rounded corners need a see-through window
        self.set_visual(self.get_screen().get_rgba_visual())
        style = Gtk.CssProvider()
        style.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            self.get_screen(), style, Gtk.STYLE_PROVIDER_PRIORITY_USER
        )
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        panel.get_style_context().add_class("panel")
        self.add(panel)
        grid = Gtk.Grid(column_homogeneous=True, row_homogeneous=True)
        panel.add(grid)
        hint = Gtk.Label(label=HINT)
        hint.get_style_context().add_class("hint")
        panel.add(hint)
        self.labels = []
        for y, row in enumerate(ROWS):
            labels = []
            for x, span in zip(STARTS[y], SPANS[y]):
                label = Gtk.Label()
                label.get_style_context().add_class("key")
                grid.attach(label, x, y, span, 1)
                labels.append(label)
            self.labels.append(labels)
        self.row, self.col = START
        self.column = STARTS[self.row][self.col]
        self.shift = OFF
        self.draw()

    def draw(self):
        for y, row in enumerate(ROWS):
            for x, (key, plain, shifted) in enumerate(row):
                label = self.labels[y][x]
                context = label.get_style_context()
                if key == "shift":
                    label.set_text("⇪" if self.shift == LOCKED else plain)
                    context.remove_class("shift")
                    if self.shift:
                        context.add_class("shift")
                else:
                    label.set_text(shifted if self.shift else plain)
                context.remove_class("selected")
                if (y, x) == (self.row, self.col):
                    context.add_class("selected")

    # Up and down stay in the column: the key right above or below, and the
    # same key again on the way back
    def move(self, rows, cols):
        if rows:
            self.row = (self.row + rows) % len(ROWS)
            starts = STARTS[self.row]
            self.col = max(i for i, x in enumerate(starts) if x <= self.column)
        else:
            self.col = (self.col + cols) % len(ROWS[self.row])
            self.column = STARTS[self.row][self.col]

    # Shift once for the next key, twice to lock it, again to release
    def toggle_shift(self):
        self.shift = (self.shift + 1) % 3

    def press(self):
        key, plain, shifted = ROWS[self.row][self.col]
        if key == "shift":
            self.toggle_shift()
            return
        # Shift only where it makes a difference
        if self.shift and plain != shifted:
            key = f"KEY_LEFTSHIFT {key}"
        print(key, flush=True)
        if self.shift == ONCE:
            self.shift = OFF
        if key == "KEY_ENTER":
            Gtk.main_quit()

    def command(self, line):
        moves = {"up": (-1, 0), "down": (1, 0), "left": (0, -1)}
        moves["right"] = (0, 1)
        if line in moves:
            self.move(*moves[line])
        elif line == "press":
            self.press()
        elif line == "shift":
            self.toggle_shift()
        self.draw()


def main(css):
    keyboard = Keyboard(css)
    pending = b""

    def read(*_):
        nonlocal pending
        data = os.read(sys.stdin.fileno(), 4096)
        if not data:
            Gtk.main_quit()
            return False
        pending += data
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            keyboard.command(line.decode())
        return True

    GLib.io_add_watch(
        sys.stdin.fileno(),
        GLib.PRIORITY_DEFAULT,
        GLib.IO_IN | GLib.IO_HUP,
        read,
    )
    keyboard.show_all()
    Gtk.main()


if __name__ == "__main__":
    with open(sys.argv[1]) as style:
        main(style.read())
