use ratatui::{
    Frame,
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
};

use super::help::centered_rect;
use crate::Theme;

/// A popup for search input with match info display.
pub struct SearchPopup;

impl SearchPopup {
    /// Render a search popup with the given title, query, and match info.
    ///
    /// - `title`: The popup title (e.g., " Search Artists ")
    /// - `query`: The current search query string
    /// - `match_info`: Optional (current, total) match count
    pub fn render(
        frame: &mut Frame,
        title: &str,
        query: &str,
        match_info: Option<(usize, usize)>,
        theme: &Theme,
    ) {
        let area = centered_rect(50, 5, frame.area());
        frame.render_widget(Clear, area);

        let block = Block::default()
            .title(title)
            .title_style(theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(theme.border_focused());

        let match_str = match_info
            .map(|(c, t)| format!(" ({c}/{t})"))
            .unwrap_or_default();

        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  /"),
                Span::raw(query),
                Span::styled("_", Style::default().add_modifier(Modifier::SLOW_BLINK)),
                Span::styled(match_str, theme.muted()),
            ]),
        ];

        let popup = Paragraph::new(content).block(block);
        frame.render_widget(popup, area);
    }
}
