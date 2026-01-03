use chrono::{Datelike, Local, NaiveDate};
use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout, Rect},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
};
use tuigreat::{
    Action, App, AppResult, Theme,
    widgets::{HelpPopup, Tabs},
};

struct CalTui {
    theme: Theme,
    tabs: Tabs,
    year: i32,
    month: u32,
    selected_day: u32,
    today: NaiveDate,
    show_help: bool,
}

impl CalTui {
    fn new() -> Self {
        let today = Local::now().date_naive();
        Self {
            theme: Theme::default(),
            tabs: Tabs::new(vec!["Calendar".to_string()]).with_app_title("Calendar v0.1"),
            year: today.year(),
            month: today.month(),
            selected_day: today.day(),
            today,
            show_help: false,
        }
    }

    fn days_in_month(year: i32, month: u32) -> u32 {
        let next_month = if month == 12 {
            // Safely handle year overflow
            year.checked_add(1)
                .and_then(|y| NaiveDate::from_ymd_opt(y, 1, 1))
        } else {
            NaiveDate::from_ymd_opt(year, month + 1, 1)
        };
        next_month
            .and_then(|d| d.pred_opt())
            .map_or(30, |d| d.day())
    }

    fn first_weekday(year: i32, month: u32) -> u32 {
        // Monday = 0, Sunday = 6
        NaiveDate::from_ymd_opt(year, month, 1).map_or(0, |d| d.weekday().num_days_from_monday())
    }

    fn week_number(year: i32, month: u32, day: u32) -> u32 {
        NaiveDate::from_ymd_opt(year, month, day).map_or(0, |d| d.iso_week().week())
    }

    fn prev_month(&mut self) {
        if self.month == 1 {
            self.month = 12;
            if self.year > 1 {
                self.year -= 1;
            }
        } else {
            self.month -= 1;
        }
        self.clamp_day();
    }

    fn next_month(&mut self) {
        if self.month == 12 {
            self.month = 1;
            if self.year < 9999 {
                self.year += 1;
            }
        } else {
            self.month += 1;
        }
        self.clamp_day();
    }

    fn prev_year(&mut self) {
        // Limit to year 1 (chrono's minimum practical year)
        if self.year > 1 {
            self.year -= 1;
            self.clamp_day();
        }
    }

    fn next_year(&mut self) {
        // Limit to year 9999 to avoid overflow and chrono limits
        if self.year < 9999 {
            self.year += 1;
            self.clamp_day();
        }
    }

    fn clamp_day(&mut self) {
        let max = Self::days_in_month(self.year, self.month);
        if self.selected_day > max {
            self.selected_day = max;
        }
    }

    fn go_today(&mut self) {
        self.year = self.today.year();
        self.month = self.today.month();
        self.selected_day = self.today.day();
    }

    fn is_today(&self, year: i32, month: u32, day: u32) -> bool {
        year == self.today.year() && month == self.today.month() && day == self.today.day()
    }

    fn is_selected(&self, year: i32, month: u32, day: u32) -> bool {
        year == self.year && month == self.month && day == self.selected_day
    }

    fn month_name(month: u32) -> &'static str {
        match month {
            1 => "January",
            2 => "February",
            3 => "March",
            4 => "April",
            5 => "May",
            6 => "June",
            7 => "July",
            8 => "August",
            9 => "September",
            10 => "October",
            11 => "November",
            12 => "December",
            _ => "Unknown",
        }
    }

    fn get_adjacent_month(&self, offset: i32) -> (i32, u32) {
        use chrono::Months;
        NaiveDate::from_ymd_opt(self.year, self.month, 1)
            .and_then(|d| {
                if offset >= 0 {
                    u32::try_from(offset)
                        .ok()
                        .and_then(|n| d.checked_add_months(Months::new(n)))
                } else {
                    u32::try_from(-offset)
                        .ok()
                        .and_then(|n| d.checked_sub_months(Months::new(n)))
                }
            })
            .map_or((self.year, self.month), |d| (d.year(), d.month()))
    }

    fn format_selected_date(&self) -> String {
        NaiveDate::from_ymd_opt(self.year, self.month, self.selected_day)
            .map(|d| {
                let day_of_year = d.ordinal();
                format!(
                    " {}, {} {:02}, {} (Day {})",
                    d.format("%A"),
                    Self::month_name(self.month),
                    self.selected_day,
                    self.year,
                    day_of_year
                )
            })
            .unwrap_or_default()
    }
}

impl App for CalTui {
    fn title(&self) -> &'static str {
        "cal-tui"
    }

    fn theme(&self) -> &Theme {
        &self.theme
    }

    fn handle_action(&mut self, action: Action) -> AppResult<bool> {
        if self.show_help {
            if matches!(action, Action::Help | Action::Back | Action::Quit) {
                self.show_help = false;
            }
            return Ok(true);
        }

        match action {
            Action::Quit => return Ok(false),
            Action::Help => self.show_help = true,
            Action::Left => {
                if self.selected_day > 1 {
                    self.selected_day -= 1;
                } else {
                    self.prev_month();
                    self.selected_day = Self::days_in_month(self.year, self.month);
                }
            }
            Action::Right => {
                if self.selected_day < Self::days_in_month(self.year, self.month) {
                    self.selected_day += 1;
                } else {
                    self.next_month();
                    self.selected_day = 1;
                }
            }
            Action::Up => {
                if self.selected_day > 7 {
                    self.selected_day -= 7;
                } else {
                    let day = self.selected_day;
                    self.prev_month();
                    let max = Self::days_in_month(self.year, self.month);
                    self.selected_day = max.saturating_sub(7 - day);
                }
            }
            Action::Down => {
                let days_in_month = Self::days_in_month(self.year, self.month);
                if self.selected_day + 7 <= days_in_month {
                    self.selected_day += 7;
                } else {
                    let overflow = self.selected_day + 7 - days_in_month;
                    self.next_month();
                    self.selected_day = overflow.min(Self::days_in_month(self.year, self.month));
                }
            }
            Action::PageUp => self.prev_month(),
            Action::PageDown => self.next_month(),
            Action::Top => self.prev_year(),
            Action::Bottom => self.next_year(),
            Action::Refresh => self.go_today(),
            _ => {}
        }
        Ok(true)
    }

    fn render(&mut self, frame: &mut Frame) {
        let main_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1), // Tabs
                Constraint::Min(10),   // Calendar area
                Constraint::Length(3), // Status box
            ])
            .split(frame.area());

        // Tabs
        self.tabs.render(frame, main_chunks[0], &self.theme);

        let calendar_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Percentage(33),
                Constraint::Percentage(34),
                Constraint::Percentage(33),
            ])
            .split(main_chunks[1]);

        // Render 3 months: prev, current, next
        let (prev_year, prev_month) = self.get_adjacent_month(-1);
        let (next_year, next_month) = self.get_adjacent_month(1);

        self.render_month(frame, calendar_chunks[0], prev_year, prev_month, false);
        self.render_month(frame, calendar_chunks[1], self.year, self.month, true);
        self.render_month(frame, calendar_chunks[2], next_year, next_month, false);

        // Status box with selected date and day of year
        let status_text = self.format_selected_date();
        let status_block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());
        let status = Paragraph::new(Line::from(vec![Span::raw(" "), Span::raw(status_text)]))
            .block(status_block);
        frame.render_widget(status, main_chunks[2]);

        if self.show_help {
            let bindings = [
                ("h/l", "Previous/next day"),
                ("j/k", "Next/previous week"),
                ("Ctrl+u/d", "Previous/next month"),
                ("g/G", "Previous/next year"),
                ("r", "Go to today"),
                ("q", "Quit"),
                ("?", "Toggle help"),
            ];
            HelpPopup::render(frame, &bindings, &self.theme);
        }
    }
}

impl CalTui {
    fn render_month(&self, frame: &mut Frame, area: Rect, year: i32, month: u32, focused: bool) {
        let border_style = if focused {
            self.theme.border_focused()
        } else {
            self.theme.border()
        };

        let block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(border_style);

        let inner = block.inner(area);
        frame.render_widget(block, area);

        // Month title line
        let title = format!("{:02} {} {}", month, Self::month_name(month), year);
        let title_style = if focused {
            self.theme.title()
        } else {
            self.theme.muted()
        };
        let title_line = Paragraph::new(Line::from(Span::styled(title, title_style)));
        let title_area = Rect { height: 1, ..inner };
        frame.render_widget(title_line, title_area);

        // Day headers with week number column (Monday first)
        let days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
        let mut header_spans: Vec<Span> = vec![Span::styled("W  ", self.theme.muted())];
        header_spans.extend(
            days.iter()
                .map(|d| Span::styled(format!("{d:>3}"), self.theme.muted())),
        );
        let header_line = Paragraph::new(Line::from(header_spans));
        let header_area = Rect {
            y: inner.y + 1,
            height: 1,
            ..inner
        };
        frame.render_widget(header_line, header_area);

        // Calendar days
        let first_weekday = Self::first_weekday(year, month);
        let days_in_month = Self::days_in_month(year, month);

        let mut lines: Vec<Line> = Vec::new();
        let mut current_line: Vec<Span> = Vec::new();
        let mut week_num_added = true;

        // Week number for first week
        current_line.push(Span::styled(
            format!("{:>2} ", Self::week_number(year, month, 1)),
            self.theme.muted(),
        ));

        // Padding for first week
        for _ in 0..first_weekday {
            current_line.push(Span::raw("   "));
        }

        for day in 1..=days_in_month {
            if !week_num_added {
                current_line.push(Span::styled(
                    format!("{:>2} ", Self::week_number(year, month, day)),
                    self.theme.muted(),
                ));
                week_num_added = true;
            }

            let style = if self.is_selected(year, month, day) {
                self.theme.selected()
            } else if self.is_today(year, month, day) {
                self.theme.highlight()
            } else {
                self.theme.normal()
            };

            current_line.push(Span::styled(format!("{day:>3}"), style));

            if (first_weekday + day).is_multiple_of(7) {
                lines.push(Line::from(std::mem::take(&mut current_line)));
                week_num_added = false;
            }
        }

        if !current_line.is_empty() {
            lines.push(Line::from(current_line));
        }

        let calendar = Paragraph::new(lines);
        let cal_area = Rect {
            y: inner.y + 2,
            height: inner.height.saturating_sub(2),
            ..inner
        };
        frame.render_widget(calendar, cal_area);
    }
}

fn main() -> AppResult<()> {
    let app = CalTui::new();
    tuigreat::app::run(app)
}
