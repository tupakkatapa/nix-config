mod pipewire;

use std::process::Command;

use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout},
    style::{Modifier, Style},
    widgets::{Block, Borders, List, ListItem, Paragraph},
};
use tuigreat::{
    Action, App, AppResult, Theme, status_line,
    widgets::{HelpPopup, SearchDirection, SearchPopup, SelectableList, Tabs},
    yank,
};

use pipewire::{
    Sink, Source, create_combined_sink, get_combined_modules, get_sinks, get_sources,
    remove_combined_sink, set_default_sink, set_default_source,
};

fn volume_bar(volume: u8) -> String {
    let filled = (usize::from(volume) / 10).min(10);
    let empty = 10 - filled;
    format!("[{}{}]", "=".repeat(filled), " ".repeat(empty))
}

fn format_sink(s: &Sink) -> String {
    let default = if s.is_default { "*" } else { " " };
    let mute = if s.muted { "M" } else { " " };
    let bar = volume_bar(s.volume);
    format!(
        "{}{} {} {:3}% {}",
        default, mute, bar, s.volume, s.description
    )
}

fn format_source(s: &Source) -> String {
    let default = if s.is_default { "*" } else { " " };
    let mute = if s.muted { "M" } else { " " };
    let bar = volume_bar(s.volume);
    format!(
        "{}{} {} {:3}% {}",
        default, mute, bar, s.volume, s.description
    )
}

struct PwTui {
    theme: Theme,
    tabs: Tabs,
    sinks: SelectableList<Sink>,
    sources: SelectableList<Source>,
    show_help: bool,
    status: String,
    refresh_tick: u32,
    // Multi-select for combined sinks
    selected_for_combine: std::collections::HashSet<String>,
    combined_modules: Vec<(u32, String)>,
    combined_selected: usize,
    // Which panel is focused in Combine tab: false = left (sinks), true = right (combined)
    combine_right_focus: bool,
    // Search mode
    search_mode: bool,
    // Jump mode (vim-style f/F)
    jump_mode: Option<bool>, // Some(true) = forward, Some(false) = backward
}

impl PwTui {
    fn new() -> AppResult<Self> {
        let sinks = get_sinks()?;
        let sources = get_sources()?;
        let combined_modules = get_combined_modules()?;

        Ok(Self {
            theme: Theme::default(),
            tabs: Tabs::new(vec![
                "Output".to_string(),
                "Input".to_string(),
                "Combine".to_string(),
            ])
            .with_app_title("PipeWire Manager v0.1"),
            sinks: SelectableList::new(sinks, format_sink),
            sources: SelectableList::new(sources, format_source),
            show_help: false,
            status: String::new(),
            refresh_tick: 0,
            selected_for_combine: std::collections::HashSet::new(),
            combined_modules,
            combined_selected: 0,
            combine_right_focus: false,
            search_mode: false,
            jump_mode: None,
        })
    }

    fn refresh(&mut self) -> AppResult<()> {
        self.sinks.set_items(get_sinks()?);
        self.sources.set_items(get_sources()?);
        self.combined_modules = get_combined_modules()?;
        // Ensure combined_selected stays in bounds after refresh
        if self.combined_modules.is_empty() {
            self.combined_selected = 0;
        } else {
            self.combined_selected = self.combined_selected.min(self.combined_modules.len() - 1);
        }
        Ok(())
    }

    fn current_tab(&self) -> usize {
        self.tabs.selected()
    }

    fn set_volume(&mut self, delta: i8) -> AppResult<()> {
        match self.current_tab() {
            0 => {
                if let Some(sink) = self.sinks.selected() {
                    let vol = if delta > 0 { "+5%" } else { "-5%" };
                    Command::new("pactl")
                        .args(["set-sink-volume", &sink.name, vol])
                        .output()?;
                    let new_vol = (i16::from(sink.volume) + i16::from(delta) * 5).clamp(0, 100);
                    self.status = format!(" Volume: {new_vol}%");
                }
            }
            1 => {
                if let Some(source) = self.sources.selected() {
                    let vol = if delta > 0 { "+5%" } else { "-5%" };
                    Command::new("pactl")
                        .args(["set-source-volume", &source.name, vol])
                        .output()?;
                    let new_vol = (i16::from(source.volume) + i16::from(delta) * 5).clamp(0, 100);
                    self.status = format!(" Volume: {new_vol}%");
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn toggle_mute(&mut self) -> AppResult<()> {
        match self.current_tab() {
            0 => {
                if let Some(sink) = self.sinks.selected() {
                    Command::new("pactl")
                        .args(["set-sink-mute", &sink.name, "toggle"])
                        .output()?;
                    self.status = if sink.muted { " Unmuted" } else { " Muted" }.to_string();
                }
            }
            1 => {
                if let Some(source) = self.sources.selected() {
                    Command::new("pactl")
                        .args(["set-source-mute", &source.name, "toggle"])
                        .output()?;
                    self.status = if source.muted { " Unmuted" } else { " Muted" }.to_string();
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn restart_pipewire(&mut self) {
        self.status = " Restarting PipeWire...".to_string();

        // Stop all services
        let _ = Command::new("systemctl")
            .args([
                "--user",
                "stop",
                "pipewire",
                "pipewire-pulse",
                "wireplumber",
            ])
            .output();

        // Small delay
        std::thread::sleep(std::time::Duration::from_millis(500));

        // Start services in order
        let _ = Command::new("systemctl")
            .args([
                "--user",
                "start",
                "pipewire",
                "wireplumber",
                "pipewire-pulse",
            ])
            .output();

        // Wait for services to stabilize
        std::thread::sleep(std::time::Duration::from_millis(1000));

        // Refresh the device lists
        if self.refresh().is_ok() {
            self.status = " PipeWire restarted".to_string();
        } else {
            self.status = " PipeWire restarted (refresh failed)".to_string();
        }
    }

    fn set_default(&mut self) {
        match self.current_tab() {
            0 => {
                if let Some(sink) = self.sinks.selected() {
                    match set_default_sink(&sink.name) {
                        Ok(()) => self.status = format!(" Default: {}", sink.description),
                        Err(e) => self.status = format!(" Error: {e}"),
                    }
                }
            }
            1 => {
                if let Some(source) = self.sources.selected() {
                    match set_default_source(&source.name) {
                        Ok(()) => self.status = format!(" Default: {}", source.description),
                        Err(e) => self.status = format!(" Error: {e}"),
                    }
                }
            }
            _ => {}
        }
    }

    fn toggle_combine_selection(&mut self) {
        if let Some(sink) = self.sinks.selected() {
            if self.selected_for_combine.contains(&sink.name) {
                self.selected_for_combine.remove(&sink.name);
                self.status = format!(" Deselected: {}", sink.description);
            } else {
                self.selected_for_combine.insert(sink.name.clone());
                self.status = format!(
                    " Selected: {} ({} total)",
                    sink.description,
                    self.selected_for_combine.len()
                );
            }
        }
    }

    fn create_combined(&mut self) {
        if self.selected_for_combine.len() < 2 {
            self.status = " Select at least 2 sinks".to_string();
            return;
        }

        let sink_names: Vec<&str> = self
            .selected_for_combine
            .iter()
            .map(String::as_str)
            .collect();

        // Find the next available number for combined sink
        // Check both modules list AND existing sink names (in case module parsing failed)
        let mut next_num = 1u32;
        for (_, name) in &self.combined_modules {
            if let Some(num_str) = name.strip_prefix("combined_")
                && let Ok(num) = num_str.parse::<u32>()
            {
                next_num = next_num.max(num.saturating_add(1));
            }
        }
        // Also check existing sinks in case module detection failed
        for sink in self.sinks.items() {
            if let Some(num_str) = sink.name.strip_prefix("combined_")
                && let Ok(num) = num_str.parse::<u32>()
            {
                next_num = next_num.max(num.saturating_add(1));
            }
        }
        let combined_name = format!("combined_{next_num}");

        match create_combined_sink(&combined_name, &sink_names) {
            Ok(()) => {
                self.status = format!(" Created: Combined {next_num}");
                self.selected_for_combine.clear();
                let _ = self.refresh();
            }
            Err(e) => self.status = format!(" Error: {e}"),
        }
    }

    fn remove_selected_combined(&mut self) {
        if let Some((module_id, name)) = self.combined_modules.get(self.combined_selected) {
            // Format display name
            let display_name = name
                .strip_prefix("combined_")
                .map_or_else(|| name.clone(), |n| format!("Combined {n}"));
            match remove_combined_sink(*module_id) {
                Ok(()) => {
                    self.status = format!(" Removed: {display_name}");
                    // refresh() handles bounds adjustment for combined_selected
                    let _ = self.refresh();
                }
                Err(e) => self.status = format!(" Error: {e}"),
            }
        }
    }

    fn combined_next(&mut self) {
        if !self.combined_modules.is_empty() {
            self.combined_selected = (self.combined_selected + 1) % self.combined_modules.len();
        }
    }

    fn combined_previous(&mut self) {
        if !self.combined_modules.is_empty() {
            self.combined_selected = self
                .combined_selected
                .checked_sub(1)
                .unwrap_or(self.combined_modules.len().saturating_sub(1));
        }
    }

    fn start_search(&mut self, direction: SearchDirection) {
        match self.current_tab() {
            0 | 2 => self.sinks.start_search(direction),
            1 => self.sources.start_search(direction),
            _ => {}
        }
        self.search_mode = true;
    }

    fn search_push(&mut self, c: char) {
        match self.current_tab() {
            0 | 2 => self.sinks.search_push(c),
            1 => self.sources.search_push(c),
            _ => {}
        }
    }

    fn search_pop(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.search_pop(),
            1 => self.sources.search_pop(),
            _ => {}
        }
    }

    fn focused_search_query(&self) -> &str {
        match self.current_tab() {
            0 | 2 => self.sinks.search_query(),
            1 => self.sources.search_query(),
            _ => "",
        }
    }

    fn focused_match_info(&self) -> Option<(usize, usize)> {
        match self.current_tab() {
            0 | 2 => self.sinks.match_info(),
            1 => self.sources.match_info(),
            _ => None,
        }
    }

    fn clear_search(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.clear_search(),
            1 => self.sources.clear_search(),
            _ => {}
        }
        self.search_mode = false;
    }

    fn next_match(&mut self) {
        match self.current_tab() {
            0 | 2 => {
                self.sinks.next_match();
            }
            1 => {
                self.sources.next_match();
            }
            _ => {}
        }
    }

    fn prev_match(&mut self) {
        match self.current_tab() {
            0 | 2 => {
                self.sinks.prev_match();
            }
            1 => {
                self.sources.prev_match();
            }
            _ => {}
        }
    }

    fn half_page_down(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.half_page_down(),
            1 => self.sources.half_page_down(),
            _ => {}
        }
    }

    fn half_page_up(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.half_page_up(),
            1 => self.sources.half_page_up(),
            _ => {}
        }
    }

    fn full_page_down(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.page_down(),
            1 => self.sources.page_down(),
            _ => {}
        }
    }

    fn full_page_up(&mut self) {
        match self.current_tab() {
            0 | 2 => self.sinks.page_up(),
            1 => self.sources.page_up(),
            _ => {}
        }
    }

    fn render_combine_tab(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let content_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Percentage(60), // Sinks
                Constraint::Percentage(40), // Combined modules
            ])
            .split(area);

        // Sinks with selection indicators (exclude combined sinks)
        // Build filtered list with original indices for selection tracking
        let filtered_sinks: Vec<(usize, &Sink)> = self
            .sinks
            .items()
            .iter()
            .enumerate()
            .filter(|(_, sink)| !sink.name.starts_with("combined_"))
            .collect();

        let items: Vec<ListItem> = filtered_sinks
            .iter()
            .map(|(original_idx, sink)| {
                let selected = self.selected_for_combine.contains(&sink.name);
                let checkbox = if selected { "[x]" } else { "[ ]" };
                let text = format!("{} {}", checkbox, sink.description);
                let style = if Some(*original_idx) == self.sinks.selected_index()
                    && !self.combine_right_focus
                {
                    Style::default().add_modifier(Modifier::REVERSED)
                } else if selected {
                    self.theme.highlight()
                } else {
                    Style::default()
                };
                ListItem::new(text).style(style)
            })
            .collect();

        let left_border = if self.combine_right_focus {
            self.theme.border()
        } else {
            self.theme.border_focused()
        };
        let block = Block::default()
            .title(" Select Sinks ")
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(left_border);
        let list = List::new(items).block(block);
        frame.render_widget(list, content_chunks[0]);

        // Combined modules list with selection
        let combined_items: Vec<ListItem> = self
            .combined_modules
            .iter()
            .enumerate()
            .map(|(i, (_, name))| {
                let style = if i == self.combined_selected && self.combine_right_focus {
                    Style::default().add_modifier(Modifier::REVERSED)
                } else {
                    Style::default()
                };
                // Format "combined_N" as "Combined N"
                let display_name = name
                    .strip_prefix("combined_")
                    .map_or_else(|| name.clone(), |n| format!("Combined {n}"));
                ListItem::new(format!("  {display_name}")).style(style)
            })
            .collect();

        let right_border = if self.combine_right_focus {
            self.theme.border_focused()
        } else {
            self.theme.border()
        };
        let combined_block = Block::default()
            .title(" Combined Sinks ")
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(right_border);

        if combined_items.is_empty() {
            let msg = Paragraph::new(" No combined sinks").block(combined_block);
            frame.render_widget(msg, content_chunks[1]);
        } else {
            let list = List::new(combined_items).block(combined_block);
            frame.render_widget(list, content_chunks[1]);
        }
    }

    fn search_popup_title(&self) -> &'static str {
        match self.current_tab() {
            0 => " Search Output ",
            1 => " Search Input ",
            _ => " Search Sinks ",
        }
    }

    fn yank_selected(&mut self) {
        let text = match self.current_tab() {
            0 | 2 => self.sinks.selected().map(|s| s.description.clone()),
            1 => self.sources.selected().map(|s| s.description.clone()),
            _ => None,
        };

        if let Some(text) = text {
            if yank(&text) {
                self.status = format!(" Yanked: {text}");
            } else {
                self.status = " Yank failed".to_string();
            }
        } else {
            self.status = " Nothing to yank".to_string();
        }
    }

    fn handle_search_action(&mut self, action: Action) {
        match action {
            Action::Back => {
                if self.focused_search_query().is_empty() {
                    self.clear_search();
                } else {
                    self.search_pop();
                }
            }
            Action::Quit => self.clear_search(),
            Action::Select => {
                self.search_mode = false;
                if let Some((cur, total)) = self.focused_match_info() {
                    self.status = format!(" Match {cur}/{total}");
                }
            }
            Action::Char(c) => self.search_push(c),
            _ => {}
        }
    }

    /// Move to next non-combined sink (for Combine tab navigation)
    fn next_non_combined(&mut self) {
        let items = self.sinks.items();
        if items.is_empty() {
            return;
        }
        let start = self.sinks.selected_index().map_or(0, |i| i + 1);
        for i in 0..items.len() {
            let idx = (start + i) % items.len();
            if !items[idx].name.starts_with("combined_") {
                self.sinks.select(idx);
                return;
            }
        }
    }

    /// Move to previous non-combined sink (for Combine tab navigation)
    fn prev_non_combined(&mut self) {
        let items = self.sinks.items();
        if items.is_empty() {
            return;
        }
        let start = self
            .sinks
            .selected_index()
            .unwrap_or(0)
            .checked_sub(1)
            .unwrap_or(items.len() - 1);
        for i in 0..items.len() {
            let idx = (start + items.len() - i) % items.len();
            if !items[idx].name.starts_with("combined_") {
                self.sinks.select(idx);
                return;
            }
        }
    }

    fn handle_navigation(&mut self, action: Action) {
        match action {
            Action::Down => match self.current_tab() {
                1 => self.sources.next(),
                2 if self.combine_right_focus => self.combined_next(),
                2 => self.next_non_combined(),
                0 => self.sinks.next(),
                _ => {}
            },
            Action::Up => match self.current_tab() {
                1 => self.sources.previous(),
                2 if self.combine_right_focus => self.combined_previous(),
                2 => self.prev_non_combined(),
                0 => self.sinks.previous(),
                _ => {}
            },
            Action::Left => {
                // On Combine tab with right focus, move to left panel
                if self.current_tab() == 2 && self.combine_right_focus {
                    self.combine_right_focus = false;
                    self.status = " Focus: Select Sinks".to_string();
                } else {
                    self.tabs.previous();
                }
            }
            Action::Right => {
                // On Combine tab with left focus, move to right panel
                if self.current_tab() == 2 && !self.combine_right_focus {
                    self.combine_right_focus = true;
                    self.status = " Focus: Combined Sinks".to_string();
                } else {
                    self.tabs.next();
                }
            }
            Action::Top => match self.current_tab() {
                0 | 2 => self.sinks.first(),
                1 => self.sources.first(),
                _ => {}
            },
            Action::Bottom => match self.current_tab() {
                0 | 2 => self.sinks.last(),
                1 => self.sources.last(),
                _ => {}
            },
            Action::PageUp => self.half_page_up(),
            Action::PageDown => self.half_page_down(),
            Action::FullPageUp => self.full_page_up(),
            Action::FullPageDown => self.full_page_down(),
            _ => {}
        }
    }

    fn handle_combine_action(&mut self, action: Action) {
        match action {
            Action::Char('\t') => {
                self.combine_right_focus = !self.combine_right_focus;
                self.status = if self.combine_right_focus {
                    " Focus: Combined Sinks".to_string()
                } else {
                    " Focus: Select Sinks".to_string()
                };
            }
            Action::Char('c') => self.create_combined(),
            Action::Delete => {
                if self.combine_right_focus && !self.combined_modules.is_empty() {
                    self.remove_selected_combined();
                } else if !self.combine_right_focus {
                    self.status = " Press l to focus Combined Sinks, then d to delete".to_string();
                }
            }
            // Pass navigation actions through
            action => self.handle_navigation(action),
        }
    }
}

impl App for PwTui {
    fn title(&self) -> &'static str {
        "pw-tui"
    }

    fn theme(&self) -> &Theme {
        &self.theme
    }

    fn input_mode(&self) -> bool {
        self.search_mode || self.jump_mode.is_some()
    }

    fn tick(&mut self) -> AppResult<()> {
        self.refresh_tick += 1;
        // Refresh every ~1 second (10 ticks at 100ms each)
        if self.refresh_tick >= 10 {
            self.refresh_tick = 0;
            self.refresh()?;
        }
        Ok(())
    }

    fn handle_action(&mut self, action: Action) -> AppResult<bool> {
        // Jump mode - waiting for character
        if let Some(forward) = self.jump_mode {
            match action {
                Action::Char(c) => {
                    let found = match self.current_tab() {
                        0 | 2 => self.sinks.jump_to_char(c, forward),
                        1 => self.sources.jump_to_char(c, forward),
                        _ => false,
                    };
                    self.status = if found {
                        format!(" Jumped to '{c}'")
                    } else {
                        format!(" No match for '{c}'")
                    };
                }
                _ => {
                    self.status = " Jump cancelled".to_string();
                }
            }
            self.jump_mode = None;
            return Ok(true);
        }

        if self.search_mode {
            self.handle_search_action(action);
            return Ok(true);
        }

        if self.show_help {
            if matches!(action, Action::Help | Action::Back | Action::Quit) {
                self.show_help = false;
            }
            return Ok(true);
        }

        match action {
            Action::Quit => return Ok(false),
            Action::Help => self.show_help = true,
            Action::Refresh => self.refresh()?,
            Action::Select => match self.current_tab() {
                0 | 1 => {
                    self.set_default();
                    self.refresh()?;
                }
                2 => self.toggle_combine_selection(),
                _ => {}
            },
            Action::VolumeUp => {
                self.set_volume(1)?;
                self.refresh()?;
            }
            Action::VolumeDown => {
                self.set_volume(-1)?;
                self.refresh()?;
            }
            Action::Mute => {
                self.toggle_mute()?;
                self.refresh()?;
            }
            Action::Search => self.start_search(SearchDirection::Forward),
            Action::SearchNext => self.next_match(),
            Action::SearchPrev => self.prev_match(),
            Action::Yank => self.yank_selected(),
            Action::JumpTo => {
                self.jump_mode = Some(true);
                self.status = " Jump to: ".to_string();
            }
            Action::JumpBack => {
                self.jump_mode = Some(false);
                self.status = " Jump back to: ".to_string();
            }
            Action::Char('R') => self.restart_pipewire(),
            action if self.current_tab() == 2 => self.handle_combine_action(action),
            action => self.handle_navigation(action),
        }
        Ok(true)
    }

    fn render(&mut self, frame: &mut Frame) {
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1), // Tabs
                Constraint::Min(5),    // Content
                Constraint::Length(3), // Status box
            ])
            .split(frame.area());

        // Tabs
        self.tabs.render(frame, chunks[0], &self.theme);

        match self.current_tab() {
            0 => {
                self.sinks.render(frame, chunks[1], "", &self.theme, true);
            }
            1 => {
                self.sources.render(frame, chunks[1], "", &self.theme, true);
            }
            2 => self.render_combine_tab(frame, chunks[1]),
            _ => {}
        }

        // Status box
        let status_block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());
        let status = Paragraph::new(status_line(&self.status, &self.theme)).block(status_block);
        frame.render_widget(status, chunks[2]);

        if self.show_help {
            let bindings = if self.current_tab() == 2 {
                vec![
                    ("j/k", "Navigate"),
                    ("h/l", "Switch panel/tab"),
                    ("g/G", "Top/Bottom"),
                    ("C-u/C-d", "Half page"),
                    ("/", "Search"),
                    ("n/N", "Next/Prev match"),
                    ("y", "Yank (copy)"),
                    ("Enter", "Toggle selection"),
                    ("c", "Create combined"),
                    ("d", "Delete combined"),
                    ("R", "Restart PipeWire"),
                    ("q", "Quit"),
                ]
            } else {
                vec![
                    ("j/k", "Navigate"),
                    ("h/l", "Switch tab"),
                    ("g/G", "Top/Bottom"),
                    ("C-u/C-d", "Half page"),
                    ("/", "Search"),
                    ("n/N", "Next/Prev match"),
                    ("y", "Yank (copy)"),
                    ("f/F", "Jump to char"),
                    ("Enter", "Set default"),
                    ("+/-", "Volume"),
                    ("m", "Mute"),
                    ("R", "Restart PipeWire"),
                    ("q", "Quit"),
                ]
            };
            HelpPopup::render(frame, &bindings, &self.theme);
        }

        if self.search_mode {
            SearchPopup::render(
                frame,
                self.search_popup_title(),
                self.focused_search_query(),
                self.focused_match_info(),
                &self.theme,
            );
        }
    }
}

fn main() -> AppResult<()> {
    let app = PwTui::new()?;
    tuigreat::app::run(app)
}
