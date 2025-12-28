mod bluetooth;

use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
};
use tuigreat::{
    Action, App, AppResult, StatusLevel, Theme,
    widgets::{HelpPopup, SearchDirection, SearchPopup, SelectableList, Tabs, centered_rect},
    yank,
};

use bluetooth::{
    Device, confirm_passkey, connect_device, disconnect_device, get_available_devices,
    get_controller_info, get_paired_devices, get_pending_passkey, remove_device, restart_discovery,
    scan, set_power, start_pairing,
};

#[derive(Debug, Clone, Copy, PartialEq, Default)]
enum UiMode {
    #[default]
    Normal,
    Help,
    Search,
    Jump {
        forward: bool,
    },
    PinConfirm,
}

struct BtTui {
    theme: Theme,
    tabs: Tabs,
    paired: SelectableList<Device>,
    available: SelectableList<Device>,
    mode: UiMode,
    status: String,
    controller_powered: bool,
    scanning: bool,
    tick_count: u32,
    discovery_tick: u32,
    // Pairing state
    pairing_in_progress: bool,
    pairing_device: String,
    // PIN value for confirmation
    pin_value: String,
}

impl BtTui {
    fn new() -> AppResult<Self> {
        let (powered, _) = get_controller_info()?;
        let paired = get_paired_devices().unwrap_or_default();
        let available = get_available_devices().unwrap_or_default();

        // Auto-start scanning if bluetooth is powered on
        let scanning = if powered {
            scan(true);
            true
        } else {
            false
        };

        let tabs = Tabs::new(vec!["Available".to_string(), "Paired".to_string()])
            .with_app_title("Bluetooth Manager v0.1");

        Ok(Self {
            theme: Theme::default(),
            tabs,
            paired: SelectableList::new(paired, |d| {
                let connected = if d.connected { "*" } else { " " };
                let icon = device_icon(&d.icon);
                format!("{} {} {}", connected, icon, d.name)
            }),
            available: SelectableList::new(available, |d| {
                let icon = device_icon(&d.icon);
                format!("  {} {}", icon, d.name)
            }),
            mode: UiMode::default(),
            status: if scanning {
                " Scanning...".to_string()
            } else if powered {
                " Bluetooth ON".to_string()
            } else {
                " Bluetooth OFF".to_string()
            },
            controller_powered: powered,
            scanning,
            tick_count: 0,
            discovery_tick: 0,
            pairing_in_progress: false,
            pairing_device: String::new(),
            pin_value: String::new(),
        })
    }

    fn current_tab(&self) -> usize {
        self.tabs.selected()
    }

    fn refresh(&mut self) -> AppResult<()> {
        let (powered, _) = get_controller_info()?;
        self.controller_powered = powered;

        let paired = get_paired_devices().unwrap_or_default();
        let available = get_available_devices().unwrap_or_default();

        self.paired.set_items(paired);
        self.available.set_items(available);

        self.status = if powered {
            " Bluetooth ON".to_string()
        } else {
            " Bluetooth OFF".to_string()
        };
        Ok(())
    }

    fn toggle_power(&mut self) -> AppResult<()> {
        let turning_on = !self.controller_powered;
        set_power(turning_on)?;
        self.refresh()?;
        // Start scanning when turning on
        if turning_on && self.controller_powered {
            self.start_scan();
        }
        Ok(())
    }

    fn start_scan(&mut self) {
        self.scanning = true;
        self.status = " Scanning...".to_string();
        scan(true);
    }

    fn stop_scan(&mut self) -> AppResult<()> {
        self.scanning = false;
        scan(false);
        self.refresh()
    }

    fn connect_selected(&mut self) -> AppResult<()> {
        if !self.controller_powered {
            self.status = " Bluetooth is off".to_string();
            return Ok(());
        }
        match self.current_tab() {
            0 => {
                // Available tab - pair
                if let Some(device) = self.available.selected() {
                    self.pairing_device = device.name.clone();
                    self.pairing_in_progress = true;
                    self.status = format!(" Pairing with {}...", device.name);
                    start_pairing(&device.address)?;
                }
            }
            1 => {
                // Paired tab - connect/disconnect
                if let Some(device) = self.paired.selected() {
                    if device.connected {
                        disconnect_device(&device.address)?;
                        self.status = format!(" Disconnected from {}", device.name);
                    } else {
                        connect_device(&device.address)?;
                        self.status = format!(" Connecting to {}...", device.name);
                    }
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn confirm_pin(&mut self) -> AppResult<()> {
        confirm_passkey(true);
        self.status = format!(" Paired with {}", self.pairing_device);
        self.mode = UiMode::Normal;
        self.pin_value.clear();
        self.pairing_in_progress = false;
        self.pairing_device.clear();
        self.refresh()?;
        Ok(())
    }

    fn reject_pin(&mut self) {
        confirm_passkey(false);
        self.status = " Pairing cancelled".to_string();
        self.mode = UiMode::Normal;
        self.pin_value.clear();
        self.pairing_in_progress = false;
        self.pairing_device.clear();
    }

    fn remove_selected(&mut self) -> AppResult<()> {
        if !self.controller_powered {
            self.status = " Bluetooth is off".to_string();
            return Ok(());
        }
        if self.current_tab() == 1
            && let Some(device) = self.paired.selected()
        {
            remove_device(&device.address)?;
            self.status = format!(" Removed {}", device.name);
            self.refresh()?;
        }
        Ok(())
    }

    fn focused_list(&mut self) -> &mut SelectableList<Device> {
        if self.current_tab() == 0 {
            &mut self.available
        } else {
            &mut self.paired
        }
    }

    fn start_search(&mut self, direction: SearchDirection) {
        self.focused_list().start_search(direction);
        self.mode = UiMode::Search;
    }

    fn search_push(&mut self, c: char) {
        self.focused_list().search_push(c);
    }

    fn search_pop(&mut self) {
        self.focused_list().search_pop();
    }

    fn focused_search_query(&self) -> &str {
        if self.current_tab() == 0 {
            self.available.search_query()
        } else {
            self.paired.search_query()
        }
    }

    fn focused_match_info(&self) -> Option<(usize, usize)> {
        if self.current_tab() == 0 {
            self.available.match_info()
        } else {
            self.paired.match_info()
        }
    }

    fn clear_search(&mut self) {
        self.focused_list().clear_search();
        self.mode = UiMode::Normal;
    }

    fn next_match(&mut self) {
        self.focused_list().next_match();
    }

    fn prev_match(&mut self) {
        self.focused_list().prev_match();
    }

    fn half_page_down(&mut self) {
        self.focused_list().half_page_down();
    }

    fn half_page_up(&mut self) {
        self.focused_list().half_page_up();
    }

    fn full_page_down(&mut self) {
        self.focused_list().page_down();
    }

    fn full_page_up(&mut self) {
        self.focused_list().page_up();
    }

    fn search_popup_title(&self) -> &'static str {
        if self.current_tab() == 0 {
            " Search Available "
        } else {
            " Search Paired "
        }
    }

    fn render_pin_popup(&self, frame: &mut Frame) {
        let area = centered_rect(40, 7, frame.area());
        frame.render_widget(Clear, area);

        let block = Block::default()
            .title(format!(" Pair with {} ", self.pairing_device))
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border_focused());

        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  PIN: "),
                Span::styled(&self.pin_value, self.theme.highlight()),
            ]),
            Line::from(""),
            Line::from(Span::styled(
                "  [Enter] Accept  [Esc] Reject",
                self.theme.muted(),
            )),
        ];

        let popup = Paragraph::new(content).block(block);
        frame.render_widget(popup, area);
    }

    fn yank_selected(&mut self) {
        let text = if self.current_tab() == 0 {
            self.available.selected().map(|d| d.name.clone())
        } else {
            self.paired.selected().map(|d| d.name.clone())
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
}

fn device_icon(icon: &str) -> &str {
    match icon {
        "audio-headphones" | "audio-headset" => "[H]",
        "audio-speakers" => "[S]",
        "input-keyboard" => "[K]",
        "input-mouse" => "[M]",
        "input-gaming" => "[G]",
        "phone" => "[P]",
        "computer" => "[C]",
        _ => "[?]",
    }
}

impl App for BtTui {
    fn title(&self) -> &'static str {
        "bt-tui"
    }

    fn theme(&self) -> &Theme {
        &self.theme
    }

    fn input_mode(&self) -> bool {
        matches!(self.mode, UiMode::Search | UiMode::Jump { .. })
    }

    fn tick(&mut self) -> AppResult<()> {
        // Check for pending passkey during pairing
        if self.pairing_in_progress
            && self.mode != UiMode::PinConfirm
            && let Some(passkey) = get_pending_passkey()
        {
            self.pin_value = passkey;
            self.mode = UiMode::PinConfirm;
            self.status = format!(" Confirm PIN for {}", self.pairing_device);
        }

        // Scanning logic
        if self.scanning && self.mode != UiMode::PinConfirm {
            self.tick_count += 1;
            self.discovery_tick += 1;

            // Refresh every ~1 second (10 ticks at 100ms each)
            if self.tick_count >= 10 {
                self.tick_count = 0;
                let available = get_available_devices().unwrap_or_default();
                let count = available.len();
                self.available.set_items(available);
                if !self.pairing_in_progress {
                    self.status = format!(" Scanning... ({count} found)");
                }
            }

            // Restart discovery every ~15 seconds to keep it active
            // (BlueZ stops discovery after timeout)
            if self.discovery_tick >= 150 {
                self.discovery_tick = 0;
                restart_discovery();
            }
        }
        Ok(())
    }

    #[allow(clippy::too_many_lines)]
    fn handle_action(&mut self, action: Action) -> AppResult<bool> {
        // Jump mode - waiting for character
        if let UiMode::Jump { forward } = self.mode {
            match action {
                Action::Char(c) => {
                    let found = if self.current_tab() == 0 {
                        self.available.jump_to_char(c, forward)
                    } else {
                        self.paired.jump_to_char(c, forward)
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
            self.mode = UiMode::Normal;
            return Ok(true);
        }

        // Search mode
        if self.mode == UiMode::Search {
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
                    self.mode = UiMode::Normal;
                    if let Some((cur, total)) = self.focused_match_info() {
                        self.status = format!(" Match {cur}/{total}");
                    }
                }
                Action::Char(c) => self.search_push(c),
                _ => {}
            }
            return Ok(true);
        }

        // PIN confirmation mode
        if self.mode == UiMode::PinConfirm {
            match action {
                Action::Select => self.confirm_pin()?,
                Action::Quit | Action::Back => self.reject_pin(),
                _ => {}
            }
            return Ok(true);
        }

        if self.mode == UiMode::Help {
            if matches!(action, Action::Help | Action::Back | Action::Quit) {
                self.mode = UiMode::Normal;
            }
            return Ok(true);
        }

        match action {
            Action::Quit => {
                if self.scanning {
                    self.stop_scan()?;
                }
                return Ok(false);
            }
            Action::Help => self.mode = UiMode::Help,
            Action::Refresh => {
                if self.scanning {
                    self.stop_scan()?;
                } else {
                    self.start_scan();
                }
            }
            Action::Down => match self.current_tab() {
                0 => self.available.next(),
                1 => self.paired.next(),
                _ => {}
            },
            Action::Up => match self.current_tab() {
                0 => self.available.previous(),
                1 => self.paired.previous(),
                _ => {}
            },
            Action::Left => self.tabs.previous(),
            Action::Right => self.tabs.next(),
            Action::Top => match self.current_tab() {
                0 => self.available.first(),
                1 => self.paired.first(),
                _ => {}
            },
            Action::Bottom => match self.current_tab() {
                0 => self.available.last(),
                1 => self.paired.last(),
                _ => {}
            },
            Action::Select => self.connect_selected()?,
            Action::Mute => self.toggle_power()?,
            Action::Delete => {
                if self.current_tab() == 1 {
                    self.remove_selected()?;
                }
            }
            // Page navigation
            Action::PageUp => self.half_page_up(),
            Action::PageDown => self.half_page_down(),
            Action::FullPageUp => self.full_page_up(),
            Action::FullPageDown => self.full_page_down(),
            // Search
            Action::Search => self.start_search(SearchDirection::Forward),
            Action::SearchNext => self.next_match(),
            Action::SearchPrev => self.prev_match(),
            // Yank
            Action::Yank => self.yank_selected(),
            // Jump to char (vim-style f/F)
            Action::JumpTo => {
                self.mode = UiMode::Jump { forward: true };
                self.status = " Jump to: ".to_string();
            }
            Action::JumpBack => {
                self.mode = UiMode::Jump { forward: false };
                self.status = " Jump back to: ".to_string();
            }
            _ => {}
        }
        Ok(true)
    }

    fn render(&mut self, frame: &mut Frame) {
        let main_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1), // Tabs
                Constraint::Min(5),    // Content
                Constraint::Length(3), // Status box
            ])
            .split(frame.area());

        // Tabs
        self.tabs.render(frame, main_chunks[0], &self.theme);

        // Content based on tab
        match self.current_tab() {
            0 => {
                self.available
                    .render(frame, main_chunks[1], "", &self.theme, true);
            }
            1 => {
                self.paired
                    .render(frame, main_chunks[1], "", &self.theme, true);
            }
            _ => {}
        }

        // Status box
        let power_indicator = if self.controller_powered {
            Span::styled(" [ON]", self.theme.success())
        } else {
            Span::styled(" [OFF]", self.theme.error())
        };

        let scan_indicator = if self.scanning {
            Span::styled("[SCAN]", self.theme.highlight())
        } else {
            Span::raw("")
        };

        let status_block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());
        let status_style = StatusLevel::from_text(&self.status).style(&self.theme);
        let status = Paragraph::new(Line::from(vec![
            power_indicator,
            scan_indicator,
            Span::styled(self.status.clone(), status_style),
        ]))
        .block(status_block);
        frame.render_widget(status, main_chunks[2]);

        if self.mode == UiMode::Help {
            let bindings = [
                ("j/k", "Navigate up/down"),
                ("h/l", "Switch panel"),
                ("g/G", "Top/Bottom"),
                ("C-u/C-d", "Half page"),
                ("C-b/C-f", "Full page"),
                ("/", "Search"),
                ("n/N", "Next/Prev match"),
                ("y", "Yank (copy)"),
                ("f/F", "Jump to char"),
                ("Enter", "Connect/Pair"),
                ("d", "Remove paired"),
                ("m", "Toggle power"),
                ("r", "Start/Stop scan"),
                ("q", "Quit"),
            ];
            HelpPopup::render(frame, &bindings, &self.theme);
        }

        if self.mode == UiMode::Search {
            SearchPopup::render(
                frame,
                self.search_popup_title(),
                self.focused_search_query(),
                self.focused_match_info(),
                &self.theme,
            );
        }

        if self.mode == UiMode::PinConfirm {
            self.render_pin_popup(frame);
        }
    }
}

fn main() -> AppResult<()> {
    let app = BtTui::new()?;
    tuigreat::app::run(app)
}
