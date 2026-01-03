use ratatui::{
    Frame,
    layout::Rect,
    style::Modifier,
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState},
};

use crate::Theme;

pub struct SelectableList<T> {
    items: Vec<T>,
    state: ListState,
    display_fn: fn(&T) -> String,
    // Search state
    search_query: String,
    search_matches: Vec<usize>,
    current_match: Option<usize>,
    search_direction: SearchDirection,
    // Page size for navigation (set during render)
    page_size: usize,
}

#[derive(Clone, Copy, PartialEq)]
pub enum SearchDirection {
    Forward,
    Backward,
}

impl<T> SelectableList<T> {
    pub fn new(items: Vec<T>, display_fn: fn(&T) -> String) -> Self {
        let mut state = ListState::default();
        if !items.is_empty() {
            state.select(Some(0));
        }
        Self {
            items,
            state,
            display_fn,
            search_query: String::new(),
            search_matches: Vec::new(),
            current_match: None,
            search_direction: SearchDirection::Forward,
            page_size: 10, // Default, updated during render
        }
    }

    #[must_use]
    pub fn items(&self) -> &[T] {
        &self.items
    }

    pub fn set_items(&mut self, items: Vec<T>) {
        self.items = items;
        self.search_matches.clear();
        self.current_match = None;
        if self.items.is_empty() {
            self.state.select(None);
        } else if self.state.selected().is_none() {
            self.state.select(Some(0));
        } else if let Some(i) = self.state.selected()
            && i >= self.items.len()
        {
            self.state.select(Some(self.items.len() - 1));
        }
    }

    #[must_use]
    pub fn selected(&self) -> Option<&T> {
        self.state.selected().and_then(|i| self.items.get(i))
    }

    #[must_use]
    pub fn selected_index(&self) -> Option<usize> {
        self.state.selected()
    }

    pub fn select(&mut self, index: usize) {
        if index < self.items.len() {
            self.state.select(Some(index));
        }
    }

    pub fn next(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let i = match self.state.selected() {
            Some(i) => {
                if i >= self.items.len() - 1 {
                    0
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.state.select(Some(i));
    }

    pub fn previous(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let i = match self.state.selected() {
            Some(i) => {
                if i == 0 {
                    self.items.len() - 1
                } else {
                    i - 1
                }
            }
            None => 0,
        };
        self.state.select(Some(i));
    }

    pub fn first(&mut self) {
        if !self.items.is_empty() {
            self.state.select(Some(0));
        }
    }

    pub fn last(&mut self) {
        if !self.items.is_empty() {
            self.state.select(Some(self.items.len() - 1));
        }
    }

    /// Move half page down
    pub fn half_page_down(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let half = self.page_size / 2;
        let current = self.state.selected().unwrap_or(0);
        let new_idx = (current + half).min(self.items.len() - 1);
        self.state.select(Some(new_idx));
    }

    /// Move half page up
    pub fn half_page_up(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let half = self.page_size / 2;
        let current = self.state.selected().unwrap_or(0);
        let new_idx = current.saturating_sub(half);
        self.state.select(Some(new_idx));
    }

    /// Move full page down
    pub fn page_down(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let current = self.state.selected().unwrap_or(0);
        let new_idx = (current + self.page_size).min(self.items.len() - 1);
        self.state.select(Some(new_idx));
    }

    /// Move full page up
    pub fn page_up(&mut self) {
        if self.items.is_empty() {
            return;
        }
        let current = self.state.selected().unwrap_or(0);
        let new_idx = current.saturating_sub(self.page_size);
        self.state.select(Some(new_idx));
    }

    /// Start a new search (clears previous results)
    pub fn start_search(&mut self, direction: SearchDirection) {
        self.search_query.clear();
        self.search_matches.clear();
        self.current_match = None;
        self.search_direction = direction;
    }

    /// Get current search query
    #[must_use]
    pub fn search_query(&self) -> &str {
        &self.search_query
    }

    /// Check if search is active (has query)
    #[must_use]
    pub fn has_search(&self) -> bool {
        !self.search_query.is_empty()
    }

    /// Add character to search query and update matches
    pub fn search_push(&mut self, c: char) {
        self.search_query.push(c);
        self.update_search_matches();
    }

    /// Remove character from search query and update matches
    pub fn search_pop(&mut self) {
        self.search_query.pop();
        self.update_search_matches();
    }

    /// Clear search
    pub fn clear_search(&mut self) {
        self.search_query.clear();
        self.search_matches.clear();
        self.current_match = None;
    }

    /// Update search matches based on current query
    fn update_search_matches(&mut self) {
        self.search_matches.clear();
        self.current_match = None;

        if self.search_query.is_empty() {
            return;
        }

        let query_lower = self.search_query.to_lowercase();
        for (i, item) in self.items.iter().enumerate() {
            let display = (self.display_fn)(item).to_lowercase();
            if display.contains(&query_lower) {
                self.search_matches.push(i);
            }
        }

        // Jump to first match from current position
        if !self.search_matches.is_empty() {
            let current = self.state.selected().unwrap_or(0);
            self.current_match = if self.search_direction == SearchDirection::Forward {
                self.search_matches
                    .iter()
                    .position(|&idx| idx >= current)
                    .or(Some(0))
            } else {
                self.search_matches
                    .iter()
                    .rposition(|&idx| idx <= current)
                    .or(Some(self.search_matches.len() - 1))
            };

            if let Some(match_idx) = self.current_match
                && let Some(&item_idx) = self.search_matches.get(match_idx)
            {
                self.state.select(Some(item_idx));
            }
        }
    }

    /// Get match count info (current/total)
    #[must_use]
    pub fn match_info(&self) -> Option<(usize, usize)> {
        if self.search_matches.is_empty() {
            return None;
        }
        self.current_match
            .map(|m| (m + 1, self.search_matches.len()))
    }

    /// Go to next search match
    pub fn next_match(&mut self) -> bool {
        if self.search_matches.is_empty() {
            return false;
        }

        let next = match self.current_match {
            Some(m) => (m + 1) % self.search_matches.len(),
            None => 0,
        };
        self.current_match = Some(next);
        if let Some(&item_idx) = self.search_matches.get(next) {
            self.state.select(Some(item_idx));
            true
        } else {
            false
        }
    }

    /// Go to previous search match
    pub fn prev_match(&mut self) -> bool {
        if self.search_matches.is_empty() {
            return false;
        }

        let prev = match self.current_match {
            Some(0) | None => self.search_matches.len() - 1,
            Some(m) => m - 1,
        };
        self.current_match = Some(prev);
        if let Some(&item_idx) = self.search_matches.get(prev) {
            self.state.select(Some(item_idx));
            true
        } else {
            false
        }
    }

    /// Jump to next item starting with the given character (vim-style f{char})
    pub fn jump_to_char(&mut self, c: char, forward: bool) -> bool {
        if self.items.is_empty() {
            return false;
        }

        let current = self.state.selected().unwrap_or(0);
        let target = c.to_lowercase().next().unwrap_or(c);

        let indices: Box<dyn Iterator<Item = usize>> = if forward {
            // Forward: search from current+1 to end, then wrap to start
            Box::new((current + 1..self.items.len()).chain(0..=current))
        } else {
            // Backward: search from current-1 to start, then wrap from end
            Box::new((0..current).rev().chain((current..self.items.len()).rev()))
        };

        for i in indices {
            let display = (self.display_fn)(&self.items[i]);
            // Skip prefix spaces and markers like "* " or "  "
            let text = display.trim_start();
            if let Some(first_char) = text.chars().next()
                && first_char.to_lowercase().next() == Some(target)
            {
                self.state.select(Some(i));
                return true;
            }
        }

        false
    }

    pub fn render(
        &mut self,
        frame: &mut Frame,
        area: Rect,
        title: &str,
        theme: &Theme,
        focused: bool,
    ) {
        self.render_with_marker(frame, area, title, theme, focused, None);
    }

    /// Render with an optional marker index (e.g., for "now playing" indicator)
    pub fn render_with_marker(
        &mut self,
        frame: &mut Frame,
        area: Rect,
        title: &str,
        theme: &Theme,
        focused: bool,
        marker_index: Option<usize>,
    ) {
        // Update page size based on visible area (minus borders)
        self.page_size = area.height.saturating_sub(2) as usize;

        let query_lower = self.search_query.to_lowercase();
        let has_query = !query_lower.is_empty();

        let items: Vec<ListItem> = self
            .items
            .iter()
            .enumerate()
            .map(|(i, item)| {
                let content = (self.display_fn)(item);
                let prefix = if marker_index == Some(i) { "* " } else { "  " };
                let full_text = format!("{prefix}{content}");

                // Highlight search matches in the text
                if has_query && self.search_matches.contains(&i) {
                    let lower = full_text.to_lowercase();
                    if let Some(pos) = lower.find(&query_lower) {
                        // Calculate end position safely using char boundaries
                        let match_end = pos + query_lower.len();
                        // Verify positions are valid char boundaries
                        if full_text.is_char_boundary(pos)
                            && full_text.is_char_boundary(match_end)
                            && match_end <= full_text.len()
                        {
                            let before = &full_text[..pos];
                            let matched = &full_text[pos..match_end];
                            let after = &full_text[match_end..];
                            return ListItem::new(Line::from(vec![
                                Span::raw(before.to_string()),
                                Span::styled(
                                    matched.to_string(),
                                    theme.highlight().add_modifier(Modifier::UNDERLINED),
                                ),
                                Span::raw(after.to_string()),
                            ]));
                        }
                    }
                }

                ListItem::new(Line::from(Span::raw(full_text)))
            })
            .collect();

        let border_style = if focused {
            theme.border_focused()
        } else {
            theme.border()
        };

        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_type(Theme::BORDER_TYPE)
                    .border_style(border_style)
                    .title(title)
                    .title_style(theme.title()),
            )
            .highlight_style(theme.selected())
            .highlight_symbol(">");

        frame.render_stateful_widget(list, area, &mut self.state);
    }
}
