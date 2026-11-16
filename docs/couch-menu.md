# Couch menu

vladof's TV session: a fuzzel menu that shows one app at a time, full screen. Apps: Firefox (with Plex and YouTube), RetroArch, Steam, Plexamp.

## Parts

| Part | Where |
|---|---|
| Session (`couchMenu`), start page (`startPage`) | `home-manager/hosts/vladof/default.nix` |
| Menu | `couch-menu.sh` |
| Pad | `couch-pad.py`, one `couch-pad@` service per pad |
| On-screen keyboard | `couch-osk.py` |

## Behaviour

- An app keeps running, hidden in the scratchpad, once started; so does a Steam game, and picking Steam brings the game back. Firefox starts with the session, on screen.
- An app owns the windows of its `couch-<app>.scope`.
- The menu opens over whatever is on screen. A pick takes the place of what was there.
- The menu opens by itself while nothing is on screen.
- An app without a window gets its log in a terminal, with retry.
- Runtime-module apps show a dot: green installed, yellow building, red missing. They build detached. Picks within 10 s of each other share one rebuild.

## Keyboard

| Key | Action |
|---|---|
| `Super`, `Alt+Q`, Home | Open the menu; again, or Esc, closes it |
| `Alt+Shift+Q` | Close a window |
| `Alt+Return` | Bring back the one terminal |

## Pad

The pad follows what is on screen. A game (RetroArch, Steam) gets the pad to itself. Otherwise the service holds the pad and turns it into keys and a mouse, so a hidden game stays quiet.

| Where | Control | Action |
|---|---|---|
| Outside games | Xbox button | Open the menu; again, or B, closes it |
| In a game | Right paddle + Xbox button | Open the menu; the Xbox button alone stays the game's (Steam's overlay) |
| Menu | D-pad, A | Choose |
| App | Left stick | Pointer |
| App | Right stick | Scroll |
| App | A | Click |
| App | Right stick click | Right-click |
| App | X | Close the tab |
| App | B | Backspace (a page back in Firefox) |
| App | LB / RB | Switch tabs |
| App | View | Esc |
| App | D-pad | Arrows |
| App | Menu | Open the on-screen keyboard |
| Firefox | Y | New tab with the start page: hand-picked sites as tiles, walked with the d-pad |

### Remote (a paddle held, in a game too)

| Control | Action |
|---|---|
| D-pad up / down | Volume |
| D-pad left / right | Skip tracks |
| A | Play / pause |
| B | Mute |

### On-screen keyboard

| Control | Action |
|---|---|
| D-pad | Move |
| A | Type |
| X | Shift; twice locks |
| B | Delete |
| Y | Space |
| LB / RB | Move the cursor |
| ⏎ key, or Menu | Close |
