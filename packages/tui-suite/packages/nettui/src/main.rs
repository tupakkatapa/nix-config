mod network;

use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
};
use tuigreat::{
    Action, App, AppResult, StatusLevel, Theme,
    widgets::{HelpPopup, SearchDirection, SearchPopup, SelectableList, Tabs, centered_rect},
    yank,
};

use network::{
    Interface, WifiNetwork, connect_wifi, get_interfaces, has_sudo_cached, needs_sudo, scan_wifi,
    toggle_interface, wifi_scan_available,
};

#[derive(Debug, Clone, PartialEq, Default)]
enum UiMode {
    #[default]
    Normal,
    Help,
    Search,
    Jump {
        forward: bool,
    },
    PasswordInput,
    SudoPassword {
        iface: String,
        bring_up: bool,
    },
    SudoForScan,
}

/// Wi-Fi scanning state
#[derive(Debug, Clone, Copy, Default)]
struct WifiState {
    available: bool,
    scanned: bool,
    scanning: bool,
}

struct NetTui {
    theme: Theme,
    tabs: Tabs,
    interfaces: SelectableList<Interface>,
    networks: SelectableList<WifiNetwork>,
    mode: UiMode,
    status: String,
    wifi: WifiState,
    scan_tick: u32,
    // WiFi password input
    password_input: String,
    pending_ssid: String,
    // Sudo password input
    sudo_password: String,
}

impl NetTui {
    fn new() -> AppResult<Self> {
        let interfaces = get_interfaces()?;

        Ok(Self {
            theme: Theme::default(),
            tabs: Tabs::new(vec!["Interfaces".to_string(), "Wi-Fi".to_string()])
                .with_app_title("Network Manager v0.1"),
            interfaces: SelectableList::new(interfaces, |i| {
                let addr = i.address.as_deref().unwrap_or("-");
                format!(
                    "{:<14} {:>10}  {:<12}  {}",
                    i.name, i.itype, i.oper_state, addr
                )
            }),
            networks: SelectableList::new(vec![], |n| {
                let connected = if n.connected { "*" } else { " " };
                let security = if n.secured { "WPA" } else { "   " };
                format!("{} {:3}% {} {}", connected, n.signal, security, n.ssid)
            }),
            mode: UiMode::default(),
            status: String::new(),
            wifi: WifiState {
                available: wifi_scan_available(),
                scanned: false,
                scanning: false,
            },
            scan_tick: 0,
            password_input: String::new(),
            pending_ssid: String::new(),
            sudo_password: String::new(),
        })
    }

    fn current_tab(&self) -> usize {
        self.tabs.selected()
    }

    fn has_wifi_enabled(&self) -> bool {
        self.interfaces
            .items()
            .iter()
            .any(|i| i.itype == "wlan" && i.oper_state != "off")
    }

    fn refresh(&mut self) -> AppResult<()> {
        self.interfaces.set_items(get_interfaces()?);
        Ok(())
    }

    fn scan_wifi_networks(&mut self) {
        if let Some(iface) = self.interfaces.items().iter().find(|i| i.itype == "wlan") {
            self.wifi.scanning = true;
            let networks = scan_wifi(&iface.name).unwrap_or_default();
            let count = networks.len();
            self.networks.set_items(networks);
            self.wifi.scanned = true;
            self.wifi.scanning = false;
            self.status = format!(" {count} networks found");
        }
    }

    fn toggle_selected_interface(&mut self, password: Option<&str>) -> AppResult<()> {
        if let Some(iface) = self.interfaces.selected() {
            let bring_up = iface.oper_state == "off";
            let name = iface.name.clone();

            match toggle_interface(&name, bring_up, password) {
                Ok(result) => {
                    self.status = format!(" {result}");
                    std::thread::sleep(std::time::Duration::from_millis(300));
                    self.refresh()?;
                }
                Err(e) if e.to_string() == "Sudo password required" => {
                    // Show sudo password popup
                    self.sudo_password.clear();
                    self.mode = UiMode::SudoPassword {
                        iface: name,
                        bring_up,
                    };
                }
                Err(e) => {
                    self.status = format!(" Error: {e}");
                }
            }
        }
        Ok(())
    }

    fn confirm_sudo_password(&mut self) {
        if let UiMode::SudoPassword { iface, bring_up } = &self.mode {
            let iface = iface.clone();
            let bring_up = *bring_up;
            let pass = self.sudo_password.clone();

            match toggle_interface(&iface, bring_up, Some(&pass)) {
                Ok(result) => {
                    self.status = format!(" {result}");
                    std::thread::sleep(std::time::Duration::from_millis(300));
                    let _ = self.refresh();
                }
                Err(e) => {
                    self.status = format!(" {e}");
                }
            }
        }
        self.mode = UiMode::Normal;
        self.sudo_password.clear();
    }

    fn cancel_sudo(&mut self) {
        self.mode = UiMode::Normal;
        self.sudo_password.clear();
        self.status = " Cancelled".to_string();
    }

    fn selected_wifi_interface(&self) -> Option<&Interface> {
        self.interfaces.items().iter().find(|i| i.itype == "wlan")
    }

    fn connect_to_network(&mut self) {
        if let Some(network) = self.networks.selected() {
            if network.secured {
                // Show password prompt for secured networks
                self.pending_ssid = network.ssid.clone();
                self.password_input.clear();
                self.mode = UiMode::PasswordInput;
            } else {
                // Connect directly for open networks
                if let Some(iface) = self.selected_wifi_interface() {
                    match connect_wifi(&iface.name, &network.ssid, None) {
                        Ok(msg) => self.status = format!(" {msg}"),
                        Err(e) => self.status = format!(" Failed: {e}"),
                    }
                }
            }
        }
    }

    fn confirm_wifi_password(&mut self) {
        if let Some(iface) = self.selected_wifi_interface() {
            let ssid = self.pending_ssid.clone();
            let pass = self.password_input.clone();
            match connect_wifi(&iface.name, &ssid, Some(&pass)) {
                Ok(msg) => self.status = format!(" {msg}"),
                Err(e) => self.status = format!(" Failed: {e}"),
            }
        }
        self.mode = UiMode::Normal;
        self.password_input.clear();
        self.pending_ssid.clear();
    }

    fn cancel_password(&mut self) {
        self.mode = UiMode::Normal;
        self.password_input.clear();
        self.pending_ssid.clear();
        self.status = " Cancelled".to_string();
    }

    fn start_search(&mut self, direction: SearchDirection) {
        match self.current_tab() {
            0 => self.interfaces.start_search(direction),
            1 => self.networks.start_search(direction),
            _ => {}
        }
        self.mode = UiMode::Search;
    }

    fn search_push(&mut self, c: char) {
        match self.current_tab() {
            0 => self.interfaces.search_push(c),
            1 => self.networks.search_push(c),
            _ => {}
        }
    }

    fn search_pop(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.search_pop(),
            1 => self.networks.search_pop(),
            _ => {}
        }
    }

    fn focused_search_query(&self) -> &str {
        match self.current_tab() {
            0 => self.interfaces.search_query(),
            1 => self.networks.search_query(),
            _ => "",
        }
    }

    fn focused_match_info(&self) -> Option<(usize, usize)> {
        match self.current_tab() {
            0 => self.interfaces.match_info(),
            1 => self.networks.match_info(),
            _ => None,
        }
    }

    fn clear_search(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.clear_search(),
            1 => self.networks.clear_search(),
            _ => {}
        }
        self.mode = UiMode::Normal;
    }

    fn next_match(&mut self) {
        match self.current_tab() {
            0 => {
                self.interfaces.next_match();
            }
            1 => {
                self.networks.next_match();
            }
            _ => {}
        }
    }

    fn prev_match(&mut self) {
        match self.current_tab() {
            0 => {
                self.interfaces.prev_match();
            }
            1 => {
                self.networks.prev_match();
            }
            _ => {}
        }
    }

    fn half_page_down(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.half_page_down(),
            1 => self.networks.half_page_down(),
            _ => {}
        }
    }

    fn half_page_up(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.half_page_up(),
            1 => self.networks.half_page_up(),
            _ => {}
        }
    }

    fn full_page_down(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.page_down(),
            1 => self.networks.page_down(),
            _ => {}
        }
    }

    fn full_page_up(&mut self) {
        match self.current_tab() {
            0 => self.interfaces.page_up(),
            1 => self.networks.page_up(),
            _ => {}
        }
    }

    fn render_status_bar(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let sudo_indicator = if !needs_sudo() {
            Span::styled(" [ROOT]", self.theme.success())
        } else if has_sudo_cached() {
            Span::styled(" [SUDO]", self.theme.highlight())
        } else {
            Span::styled(" [USER]", self.theme.muted())
        };

        let scan_indicator = if self.wifi.scanning {
            Span::styled(" [SCAN]", self.theme.highlight())
        } else {
            Span::raw("")
        };

        let status_block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());
        let status_style = StatusLevel::from_text(&self.status).style(&self.theme);
        let status = Paragraph::new(Line::from(vec![
            sudo_indicator,
            scan_indicator,
            Span::styled(self.status.clone(), status_style),
        ]))
        .block(status_block);
        frame.render_widget(status, area);
    }

    fn search_popup_title(&self) -> &'static str {
        if self.current_tab() == 0 {
            " Search Interfaces "
        } else {
            " Search Networks "
        }
    }

    fn render_password_popup(&self, frame: &mut Frame) {
        let area = centered_rect(50, 7, frame.area());
        frame.render_widget(Clear, area);

        let block = Block::default()
            .title(format!(" Password for {} ", self.pending_ssid))
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border_focused());

        let masked: String = "*".repeat(self.password_input.len());
        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  "),
                Span::raw(&masked),
                Span::styled("_", Style::default().add_modifier(Modifier::SLOW_BLINK)),
            ]),
            Line::from(""),
            Line::from(Span::styled(
                "  [Enter] Connect  [Esc] Cancel",
                self.theme.muted(),
            )),
        ];

        let input = Paragraph::new(content).block(block);
        frame.render_widget(input, area);
    }

    fn render_sudo_popup(&self, frame: &mut Frame) {
        let area = centered_rect(50, 7, frame.area());
        frame.render_widget(Clear, area);

        let title = if let UiMode::SudoPassword { iface, bring_up } = &self.mode {
            let action = if *bring_up { "up" } else { "down" };
            format!(" Sudo: {action} {iface} ")
        } else {
            " Sudo Password ".to_string()
        };

        let block = Block::default()
            .title(title)
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border_focused());

        let masked: String = "*".repeat(self.sudo_password.len());
        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  "),
                Span::raw(&masked),
                Span::styled("_", Style::default().add_modifier(Modifier::SLOW_BLINK)),
            ]),
            Line::from(""),
            Line::from(Span::styled(
                "  [Enter] Authenticate  [Esc] Cancel",
                self.theme.muted(),
            )),
        ];

        let input = Paragraph::new(content).block(block);
        frame.render_widget(input, area);
    }

    fn render_sudo_scan_popup(&self, frame: &mut Frame) {
        let area = centered_rect(50, 7, frame.area());
        frame.render_widget(Clear, area);

        let block = Block::default()
            .title(" Sudo: Wi-Fi scan ")
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border_focused());

        let masked: String = "*".repeat(self.sudo_password.len());
        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  "),
                Span::raw(&masked),
                Span::styled("_", Style::default().add_modifier(Modifier::SLOW_BLINK)),
            ]),
            Line::from(""),
            Line::from(Span::styled(
                "  [Enter] Authenticate  [Esc] Cancel",
                self.theme.muted(),
            )),
        ];

        let input = Paragraph::new(content).block(block);
        frame.render_widget(input, area);
    }

    fn yank_selected(&mut self) {
        let text = match self.current_tab() {
            0 => self.interfaces.selected().map(|i| i.name.clone()),
            1 => self.networks.selected().map(|n| n.ssid.clone()),
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
                self.mode = UiMode::Normal;
                if let Some((cur, total)) = self.focused_match_info() {
                    self.status = format!(" Match {cur}/{total}");
                }
            }
            Action::Char(c) => self.search_push(c),
            _ => {}
        }
    }

    fn handle_password_action(&mut self, action: Action) {
        match action {
            Action::Back => {
                if self.password_input.is_empty() {
                    self.cancel_password();
                } else {
                    self.password_input.pop();
                }
            }
            Action::Quit => self.cancel_password(),
            Action::Select => self.confirm_wifi_password(),
            Action::Char(c) => self.password_input.push(c),
            _ => {}
        }
    }

    fn handle_sudo_action(&mut self, action: Action) {
        match action {
            Action::Back => {
                if self.sudo_password.is_empty() {
                    self.cancel_sudo();
                } else {
                    self.sudo_password.pop();
                }
            }
            Action::Quit => self.cancel_sudo(),
            Action::Select => self.confirm_sudo_password(),
            Action::Char(c) => self.sudo_password.push(c),
            _ => {}
        }
    }

    fn handle_sudo_scan_action(&mut self, action: Action) {
        match action {
            Action::Back => {
                if self.sudo_password.is_empty() {
                    self.mode = UiMode::Normal;
                    self.tabs.previous(); // Go back to interfaces tab
                } else {
                    self.sudo_password.pop();
                }
            }
            Action::Quit => {
                self.mode = UiMode::Normal;
                self.tabs.previous();
            }
            Action::Select => self.confirm_sudo_for_scan(),
            Action::Char(c) => self.sudo_password.push(c),
            _ => {}
        }
    }

    fn handle_normal_action(&mut self, action: Action) -> AppResult<bool> {
        let prev_tab = self.current_tab();

        match action {
            Action::Quit => return Ok(false),
            Action::Help => self.mode = UiMode::Help,
            Action::Refresh => {
                self.refresh()?;
                if self.current_tab() == 1 {
                    self.scan_wifi_networks();
                }
            }
            Action::Down => match self.current_tab() {
                0 => self.interfaces.next(),
                1 => self.networks.next(),
                _ => {}
            },
            Action::Up => match self.current_tab() {
                0 => self.interfaces.previous(),
                1 => self.networks.previous(),
                _ => {}
            },
            Action::Left => self.tabs.previous(),
            Action::Right => self.tabs.next(),
            Action::Top => match self.current_tab() {
                0 => self.interfaces.first(),
                1 => self.networks.first(),
                _ => {}
            },
            Action::Bottom => match self.current_tab() {
                0 => self.interfaces.last(),
                1 => self.networks.last(),
                _ => {}
            },
            Action::Select => match self.current_tab() {
                0 => self.toggle_selected_interface(None)?,
                1 => self.connect_to_network(),
                _ => {}
            },
            Action::PageUp => self.half_page_up(),
            Action::PageDown => self.half_page_down(),
            Action::FullPageUp => self.full_page_up(),
            Action::FullPageDown => self.full_page_down(),
            Action::Search => self.start_search(SearchDirection::Forward),
            Action::SearchNext => self.next_match(),
            Action::SearchPrev => self.prev_match(),
            Action::Yank => self.yank_selected(),
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

        // Entering WiFi tab
        if self.current_tab() == 1 && prev_tab != 1 && self.has_wifi_enabled() && !self.wifi.scanned
        {
            if needs_sudo() && !has_sudo_cached() {
                self.sudo_password.clear();
                self.mode = UiMode::SudoForScan;
            } else {
                self.scan_wifi_networks();
            }
        }

        Ok(true)
    }

    fn confirm_sudo_for_scan(&mut self) {
        // Cache sudo credentials by running a simple command
        let pass = self.sudo_password.clone();
        match network::run_with_sudo("true", &[], Some(&pass)) {
            Ok(_) => {
                self.status = " Authenticated".to_string();
                self.scan_wifi_networks();
            }
            Err(e) => {
                self.status = format!(" {e}");
            }
        }
        self.mode = UiMode::Normal;
        self.sudo_password.clear();
    }
}

impl App for NetTui {
    fn title(&self) -> &'static str {
        "net-tui"
    }

    fn theme(&self) -> &Theme {
        &self.theme
    }

    fn input_mode(&self) -> bool {
        matches!(
            self.mode,
            UiMode::PasswordInput
                | UiMode::Search
                | UiMode::Jump { .. }
                | UiMode::SudoPassword { .. }
                | UiMode::SudoForScan
        )
    }

    fn tick(&mut self) -> AppResult<()> {
        // Auto-scan WiFi when on Wi-Fi tab and have enabled wlan interface
        if self.current_tab() == 1 && self.has_wifi_enabled() && self.mode != UiMode::PasswordInput
        {
            self.scan_tick += 1;
            // Scan every ~10 seconds (100 ticks at 100ms) to reduce lag
            if !self.wifi.scanned || self.scan_tick >= 100 {
                self.scan_tick = 0;
                self.scan_wifi_networks();
            }
        }
        Ok(())
    }

    fn handle_action(&mut self, action: Action) -> AppResult<bool> {
        // Jump mode - waiting for character
        if let UiMode::Jump { forward } = self.mode {
            match action {
                Action::Char(c) => {
                    let found = match self.current_tab() {
                        0 => self.interfaces.jump_to_char(c, forward),
                        1 => self.networks.jump_to_char(c, forward),
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
            self.mode = UiMode::Normal;
            return Ok(true);
        }

        match &self.mode {
            UiMode::Search => {
                self.handle_search_action(action);
                Ok(true)
            }
            UiMode::PasswordInput => {
                self.handle_password_action(action);
                Ok(true)
            }
            UiMode::SudoPassword { .. } => {
                self.handle_sudo_action(action);
                Ok(true)
            }
            UiMode::SudoForScan => {
                self.handle_sudo_scan_action(action);
                Ok(true)
            }
            UiMode::Help => {
                if matches!(action, Action::Help | Action::Back | Action::Quit) {
                    self.mode = UiMode::Normal;
                }
                Ok(true)
            }
            UiMode::Normal => self.handle_normal_action(action),
            UiMode::Jump { .. } => unreachable!("Jump mode handled before match"),
        }
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
                self.interfaces
                    .render(frame, main_chunks[1], "", &self.theme, true);
            }
            1 => {
                if !self.wifi.available {
                    let block = Block::default()
                        .borders(Borders::ALL)
                        .border_type(Theme::BORDER_TYPE)
                        .border_style(self.theme.border());
                    let msg =
                        Paragraph::new(" Wi-Fi scanning requires wpa_supplicant").block(block);
                    frame.render_widget(msg, main_chunks[1]);
                } else if !self.has_wifi_enabled() {
                    let block = Block::default()
                        .borders(Borders::ALL)
                        .border_type(Theme::BORDER_TYPE)
                        .border_style(self.theme.border());
                    let msg =
                        Paragraph::new(" Wi-Fi interface is down - enable it in Interfaces tab")
                            .block(block);
                    frame.render_widget(msg, main_chunks[1]);
                } else {
                    self.networks
                        .render(frame, main_chunks[1], "", &self.theme, true);
                }
            }
            _ => {}
        }

        self.render_status_bar(frame, main_chunks[2]);

        if self.mode == UiMode::Help {
            let bindings = [
                ("j/k", "Navigate"),
                ("h/l", "Switch tab"),
                ("g/G", "Top/Bottom"),
                ("C-u/C-d", "Half page"),
                ("C-b/C-f", "Full page"),
                ("/", "Search"),
                ("n/N", "Next/Prev match"),
                ("y", "Yank (copy)"),
                ("f/F", "Jump to char"),
                ("Enter", "Toggle/Connect"),
                ("r", "Refresh"),
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

        if self.mode == UiMode::PasswordInput {
            self.render_password_popup(frame);
        }

        if matches!(self.mode, UiMode::SudoPassword { .. }) {
            self.render_sudo_popup(frame);
        }

        if self.mode == UiMode::SudoForScan {
            self.render_sudo_scan_popup(frame);
        }
    }
}

fn main() -> AppResult<()> {
    let app = NetTui::new()?;
    tuigreat::app::run(app)
}
