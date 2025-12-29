use crossterm::event::{KeyCode, KeyEvent, KeyModifiers};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    Quit,
    // Navigation
    Up,
    Down,
    Left,
    Right,
    Select,
    Back,
    // Jump navigation
    Top,          // g, gg, 0, ^
    Bottom,       // G, $
    PageUp,       // Ctrl+u (half page)
    PageDown,     // Ctrl+d (half page)
    FullPageUp,   // Ctrl+b
    FullPageDown, // Ctrl+f
    JumpTo,       // f{char} - jump forward to item starting with char
    JumpBack,     // F{char} - jump backward to item starting with char
    // Search
    Search,     // /
    SearchNext, // n
    SearchPrev, // N
    // Yank/paste
    Yank,  // y
    Paste, // p
    // Other
    Help,
    Refresh,
    VolumeUp,
    VolumeDown,
    Mute,
    Delete,
    // Pass-through
    Char(char),
    None,
}

pub struct KeyHandler;

impl KeyHandler {
    #[must_use]
    pub fn parse(key: KeyEvent) -> Action {
        match key.code {
            // Quit
            KeyCode::Char('q') => Action::Quit,
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => Action::Quit,

            // Vim navigation
            KeyCode::Char('j') | KeyCode::Down => Action::Down,
            KeyCode::Char('k') | KeyCode::Up => Action::Up,
            KeyCode::Char('h') | KeyCode::Left => Action::Left,
            KeyCode::Char('l') | KeyCode::Right => Action::Right,

            // Selection
            KeyCode::Enter => Action::Select,

            // Jump navigation (vim style)
            KeyCode::Char('g' | '0' | '^') | KeyCode::Home => Action::Top,
            KeyCode::Char('G' | '$') | KeyCode::End => Action::Bottom,
            // Half page (Ctrl+u/d)
            KeyCode::Char('u') if key.modifiers.contains(KeyModifiers::CONTROL) => Action::PageUp,
            KeyCode::Char('d') if key.modifiers.contains(KeyModifiers::CONTROL) => Action::PageDown,
            // Full page (Ctrl+b/f)
            KeyCode::Char('b') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                Action::FullPageUp
            }
            KeyCode::Char('f') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                Action::FullPageDown
            }
            KeyCode::PageUp => Action::FullPageUp,
            KeyCode::PageDown => Action::FullPageDown,

            // Search (vim style)
            KeyCode::Char('/') => Action::Search,
            KeyCode::Char('n') => Action::SearchNext,
            KeyCode::Char('N') => Action::SearchPrev,

            // Jump to char (vim-style f/F)
            KeyCode::Char('F') => Action::JumpBack,

            // Help
            KeyCode::Char('?') => Action::Help,
            KeyCode::Char('r') => Action::Refresh,

            // Audio controls (only + for volume, = passes through for calculators etc)
            KeyCode::Char('+') => Action::VolumeUp,
            KeyCode::Char('-' | '_') => Action::VolumeDown,
            KeyCode::Char('m') => Action::Mute,

            // Delete/backspace
            KeyCode::Esc | KeyCode::Backspace => Action::Back,
            KeyCode::Delete | KeyCode::Char('d') => Action::Delete,

            // Yank (vim style copy)
            KeyCode::Char('y') => Action::Yank,

            // Jump to (focus/playing item)
            KeyCode::Char('f') => Action::JumpTo,

            // Paste (vim style + terminal paste)
            KeyCode::Char('p') => Action::Paste,
            KeyCode::Char('v') if key.modifiers.contains(KeyModifiers::CONTROL) => Action::Paste,
            KeyCode::Char('V')
                if key
                    .modifiers
                    .contains(KeyModifiers::CONTROL | KeyModifiers::SHIFT) =>
            {
                Action::Paste
            }

            // Pass through other characters
            KeyCode::Char(c) => Action::Char(c),

            _ => Action::None,
        }
    }

    /// Parse keys in input mode - pass through most characters as-is
    #[must_use]
    pub fn parse_input_mode(key: KeyEvent) -> Action {
        match key.code {
            // Esc cancels/aborts input, Backspace deletes character
            KeyCode::Esc => Action::Quit,
            KeyCode::Backspace => Action::Back,
            KeyCode::Enter => Action::Select,
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => Action::Quit,
            KeyCode::Char(c) => Action::Char(c),
            _ => Action::None,
        }
    }
}
