use ratatui::{
    Frame,
    layout::Rect,
    text::{Line, Span},
    widgets::Paragraph,
};

use crate::Theme;

pub struct Tabs {
    app_title: Option<String>,
    titles: Vec<String>,
    selected: usize,
}

impl Tabs {
    #[must_use]
    pub fn new(titles: Vec<String>) -> Self {
        Self {
            app_title: None,
            titles,
            selected: 0,
        }
    }

    #[must_use]
    pub fn with_app_title(mut self, title: impl Into<String>) -> Self {
        self.app_title = Some(title.into());
        self
    }

    pub fn select(&mut self, index: usize) {
        if index < self.titles.len() {
            self.selected = index;
        }
    }

    #[must_use]
    pub fn selected(&self) -> usize {
        self.selected
    }

    pub fn next(&mut self) {
        if !self.titles.is_empty() {
            self.selected = (self.selected + 1) % self.titles.len();
        }
    }

    pub fn previous(&mut self) {
        if self.titles.is_empty() {
            return;
        }
        if self.selected == 0 {
            self.selected = self.titles.len() - 1;
        } else {
            self.selected -= 1;
        }
    }

    /// Render tabs as part of a top border line
    /// Output:  ┌─ Tab1 ─┬─ Tab2 ─┐        App Title v0.1 ─┐
    pub fn render(&self, frame: &mut Frame, area: Rect, theme: &Theme) {
        let mut spans: Vec<Span> = vec![Span::raw(" "), Span::styled("┌", theme.border())];

        // Tabs on the left
        for (i, title) in self.titles.iter().enumerate() {
            if i > 0 {
                spans.push(Span::styled("┬", theme.border()));
            }
            spans.push(Span::styled("─ ", theme.border()));
            if i == self.selected {
                spans.push(Span::styled(title.as_str(), theme.highlight()));
            } else {
                spans.push(Span::styled(title.as_str(), theme.muted()));
            }
            spans.push(Span::styled(" ─", theme.border()));
        }
        spans.push(Span::styled("┐", theme.border()));

        // Calculate title width (title + " ─┐")
        let title_width = self.app_title.as_ref().map_or(0, |t| t.len() + 3);
        let tabs_width: usize = self.titles.iter().map(|t| t.len() + 5).sum::<usize>() + 2;

        // Fill with spaces to push title to the right
        let fill_width = (area.width as usize)
            .saturating_sub(1)
            .saturating_sub(tabs_width)
            .saturating_sub(title_width);
        if fill_width > 0 {
            spans.push(Span::raw(" ".repeat(fill_width)));
        }

        // App title on the right (dimmed)
        if let Some(title) = &self.app_title {
            spans.push(Span::styled(title.as_str(), theme.muted()));
            spans.push(Span::styled(" ─┐", theme.border()));
        }

        let tabs = Paragraph::new(Line::from(spans));
        frame.render_widget(tabs, area);
    }
}
