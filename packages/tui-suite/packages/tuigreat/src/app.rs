use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event},
    execute,
    terminal::{
        EnterAlternateScreen, LeaveAlternateScreen, SetTitle, disable_raw_mode, enable_raw_mode,
    },
};
use ratatui::{Terminal, backend::CrosstermBackend};
use std::io;

use crate::{Action, Theme, keys::KeyHandler};

pub type AppResult<T> = std::result::Result<T, Box<dyn std::error::Error>>;

pub trait App {
    fn title(&self) -> &str;
    fn theme(&self) -> &Theme;

    /// Handle an action and return whether to continue running.
    ///
    /// # Errors
    /// Returns an error if the action handling fails.
    fn handle_action(&mut self, action: Action) -> AppResult<bool>;
    fn render(&mut self, frame: &mut ratatui::Frame);

    /// Called on each tick of the event loop.
    ///
    /// # Errors
    /// Returns an error if the tick processing fails.
    fn tick(&mut self) -> AppResult<()> {
        Ok(())
    }
    /// When true, bypass vim keybindings and pass raw characters
    fn input_mode(&self) -> bool {
        false
    }
}

/// Run the TUI application event loop.
///
/// # Errors
/// Returns an error if terminal setup, rendering, or event handling fails.
pub fn run<A: App>(mut app: A) -> AppResult<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(
        stdout,
        EnterAlternateScreen,
        EnableMouseCapture,
        SetTitle(app.title())
    )?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let result = run_loop(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    result
}

fn run_loop<A: App>(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut A,
) -> AppResult<()> {
    loop {
        terminal.draw(|f| app.render(f))?;

        if event::poll(std::time::Duration::from_millis(100))?
            && let Event::Key(key) = event::read()?
        {
            let action = if app.input_mode() {
                KeyHandler::parse_input_mode(key)
            } else {
                KeyHandler::parse(key)
            };
            if !app.handle_action(action)? {
                return Ok(());
            }
        }

        app.tick()?;
    }
}
