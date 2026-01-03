use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout, Rect},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
};

use crate::Theme;

pub struct HelpPopup;

impl HelpPopup {
    pub fn render(frame: &mut Frame, bindings: &[(&str, &str)], theme: &Theme) {
        let area = centered_rect_percent(60, 70, frame.area());

        frame.render_widget(Clear, area);

        let lines: Vec<Line> = bindings
            .iter()
            .map(|(key, desc)| {
                Line::from(vec![
                    Span::styled(format!("{key:>12}"), theme.highlight()),
                    Span::raw("  "),
                    Span::styled(*desc, theme.normal()),
                ])
            })
            .collect();

        let help = Paragraph::new(lines).block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(Theme::BORDER_TYPE)
                .border_style(theme.border_focused())
                .title(" ? Help ")
                .title_style(theme.title()),
        );

        frame.render_widget(help, area);
    }
}

#[must_use]
pub fn centered_rect_percent(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

/// Center a fixed-size rectangle within a container
#[must_use]
pub fn centered_rect(width: u16, height: u16, r: Rect) -> Rect {
    let x = r.x.saturating_add((r.width.saturating_sub(width)) / 2);
    let y = r.y.saturating_add((r.height.saturating_sub(height)) / 2);
    Rect::new(x, y, width.min(r.width), height.min(r.height))
}
