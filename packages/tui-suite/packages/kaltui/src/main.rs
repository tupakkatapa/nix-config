use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
};
use tuigreat::{
    Action, App, AppResult, Theme, paste, status_line,
    widgets::{HelpPopup, Tabs},
    yank,
};

const MAX_HISTORY: usize = 1000;

struct CalcTui {
    theme: Theme,
    tabs: Tabs,
    input: String,
    result: String,
    history: Vec<(String, String)>,
    history_state: ListState,
    show_help: bool,
    status: String,
    focus: usize, // 0 = input, 1 = result (in calculator tab)
}

impl CalcTui {
    fn new() -> Self {
        Self {
            theme: Theme::default(),
            tabs: Tabs::new(vec!["Calculator".to_string(), "History".to_string()])
                .with_app_title("Calculator v0.1"),
            input: String::new(),
            result: String::new(),
            history: Vec::new(),
            history_state: ListState::default(),
            show_help: false,
            status: String::new(),
            focus: 0,
        }
    }

    fn current_tab(&self) -> usize {
        self.tabs.selected()
    }

    fn evaluate(&mut self) {
        if self.input.is_empty() {
            self.status = " Nothing to evaluate".to_string();
            return;
        }

        match Self::parse_and_eval(&self.input.clone()) {
            Ok(value) => {
                if value.is_finite() {
                    self.result = format_number(value);
                    self.history.push((self.input.clone(), self.result.clone()));
                    if self.history.len() > MAX_HISTORY {
                        self.history.drain(0..(self.history.len() - MAX_HISTORY));
                    }
                    self.input.clear();
                    self.status = " Calculated".to_string();
                } else {
                    self.result = "Error".to_string();
                    self.status = " Error: Invalid result".to_string();
                }
            }
            Err(e) => {
                self.result.clear();
                self.status = format!(" Error: {e}");
            }
        }
    }

    fn validate_parens(expr: &str) -> bool {
        let mut depth = 0i32;
        for c in expr.chars() {
            match c {
                '(' => depth += 1,
                ')' => depth -= 1,
                _ => {}
            }
            if depth < 0 {
                return false;
            }
        }
        depth == 0
    }

    fn parse_and_eval(expr: &str) -> Result<f64, &'static str> {
        // Remove spaces and thousands separators
        let expr = expr.replace([' ', '\''], "");
        if expr.is_empty() {
            return Err("Empty expression");
        }

        // Validate balanced parentheses
        if !Self::validate_parens(&expr) {
            return Err("Unmatched parentheses");
        }

        // Handle addition and subtraction (lowest precedence)
        let mut depth: i32 = 0;
        let mut last_op = None;
        let bytes = expr.as_bytes();

        for (i, &c) in bytes.iter().enumerate().rev() {
            match c {
                b')' => depth += 1,
                b'(' => depth = depth.saturating_sub(1),
                b'+' | b'-' if depth == 0 && i > 0 => {
                    let prev = bytes[i - 1];
                    if prev != b'+' && prev != b'-' && prev != b'*' && prev != b'/' && prev != b'('
                    {
                        last_op = Some((i, c as char));
                        break;
                    }
                }
                _ => {}
            }
        }

        if let Some((i, op)) = last_op {
            if i == 0 || i + 1 >= expr.len() {
                return Err("Invalid expression");
            }
            let left = Self::parse_and_eval(&expr[..i])?;
            let right = Self::parse_and_eval(&expr[i + 1..])?;
            return Ok(match op {
                '+' => left + right,
                '-' => left - right,
                _ => unreachable!(),
            });
        }

        // Handle multiplication and division
        depth = 0;
        last_op = None;
        for (i, &c) in bytes.iter().enumerate().rev() {
            match c {
                b')' => depth += 1,
                b'(' => depth = depth.saturating_sub(1),
                b'*' | b'/' if depth == 0 => {
                    last_op = Some((i, c as char));
                    break;
                }
                _ => {}
            }
        }

        if let Some((i, op)) = last_op {
            if i == 0 || i + 1 >= expr.len() {
                return Err("Invalid expression");
            }
            let left = Self::parse_and_eval(&expr[..i])?;
            let right = Self::parse_and_eval(&expr[i + 1..])?;
            return Ok(match op {
                '*' => left * right,
                '/' => {
                    if right.abs() < f64::EPSILON {
                        return Err("Division by zero");
                    }
                    left / right
                }
                _ => unreachable!(),
            });
        }

        // Handle exponentiation (right-to-left associativity, so scan left-to-right)
        depth = 0;
        last_op = None;
        for (i, &c) in bytes.iter().enumerate() {
            match c {
                b'(' => depth += 1,
                b')' => depth = depth.saturating_sub(1),
                b'^' if depth == 0 => {
                    last_op = Some((i, '^'));
                    break;
                }
                _ => {}
            }
        }

        if let Some((i, _)) = last_op {
            if i == 0 || i + 1 >= expr.len() {
                return Err("Invalid expression");
            }
            let left = Self::parse_and_eval(&expr[..i])?;
            let right = Self::parse_and_eval(&expr[i + 1..])?;
            let result = left.powf(right);
            if !result.is_finite() {
                return Err("Invalid result");
            }
            return Ok(result);
        }

        // Handle parentheses
        if expr.starts_with('(') && expr.ends_with(')') {
            return Self::parse_and_eval(&expr[1..expr.len() - 1]);
        }

        // Handle unary minus
        if let Some(rest) = expr.strip_prefix('-') {
            return Ok(-Self::parse_and_eval(rest)?);
        }

        // Parse number
        expr.parse::<f64>().map_err(|_| "Invalid number")
    }

    fn handle_char(&mut self, c: char) {
        // Only accept input when on calculator tab and focused on input
        if self.current_tab() != 0 || self.focus != 0 {
            return;
        }
        match c {
            '0'..='9' | '.' | '+' | '-' | '*' | '/' | '^' | '(' | ')' | '\'' => {
                self.input.push(c);
                self.status.clear();
            }
            // Space (only if not at start and previous char isn't space)
            ' ' => {
                if !self.input.is_empty() && !self.input.ends_with(' ') {
                    self.input.push(' ');
                }
            }
            // Alternative operators
            ':' => {
                self.input.push('/');
                self.status.clear();
            }
            'x' | 'X' => {
                self.input.push('*');
                self.status.clear();
            }
            // Calculate
            '=' => self.evaluate(),
            _ => {
                // Show error for invalid characters
                self.status = format!(" Invalid input: '{c}'");
            }
        }
    }

    fn do_paste(&mut self) {
        if self.current_tab() != 0 || self.focus != 0 {
            return;
        }

        let Some(text) = paste() else {
            self.status = " Nothing to paste".to_string();
            return;
        };

        // Filter to only valid calculator characters
        let filtered: String = text
            .chars()
            .filter(|c| {
                matches!(
                    c,
                    '0'..='9'
                        | '.'
                        | '+'
                        | '-'
                        | '*'
                        | '/'
                        | '^'
                        | '('
                        | ')'
                        | ' '
                        | 'x'
                        | 'X'
                        | ':'
                )
            })
            .map(|c| match c {
                'x' | 'X' => '*',
                ':' => '/',
                _ => c,
            })
            .collect();

        self.input.push_str(&filtered);
        self.status = format!(" Pasted: {filtered}");
    }

    fn render_calculator_tab(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let calc_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(3), // Input
                Constraint::Min(3),    // Result
            ])
            .split(area);

        // Input field
        let input_border = if self.focus == 0 {
            self.theme.border_focused()
        } else {
            self.theme.border()
        };
        let input = Paragraph::new(Line::from(vec![
            Span::styled(&self.input, self.theme.normal()),
            if self.focus == 0 {
                Span::styled("_", self.theme.muted())
            } else {
                Span::raw("")
            },
        ]))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(Theme::BORDER_TYPE)
                .border_style(input_border),
        );
        frame.render_widget(input, calc_chunks[0]);

        // Result field
        let result_border = if self.focus == 1 {
            self.theme.border_focused()
        } else {
            self.theme.border()
        };
        let result_style = if self.result.is_empty() {
            self.theme.muted()
        } else {
            self.theme.highlight()
        };
        let result = Paragraph::new(Span::styled(&self.result, result_style)).block(
            Block::default()
                .borders(Borders::ALL)
                .border_type(Theme::BORDER_TYPE)
                .border_style(result_border),
        );
        frame.render_widget(result, calc_chunks[1]);
    }

    fn render_history_tab(&mut self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let history_items: Vec<ListItem> = self
            .history
            .iter()
            .rev()
            .map(|(expr, res)| {
                ListItem::new(Line::from(vec![
                    Span::styled(expr, self.theme.muted()),
                    Span::raw(" = "),
                    Span::styled(res, self.theme.normal()),
                ]))
            })
            .collect();

        let history = List::new(history_items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_type(Theme::BORDER_TYPE)
                    .border_style(self.theme.border_focused()),
            )
            .highlight_style(self.theme.selected())
            .highlight_symbol(" > ");

        frame.render_stateful_widget(history, area, &mut self.history_state);
    }

    fn do_yank(&mut self) {
        let text = match self.current_tab() {
            0 => {
                // Yank based on focus: input if focus=0, result if focus=1
                if self.focus == 0 {
                    self.input.clone()
                } else {
                    self.result.clone()
                }
            }
            1 => self
                .history_state
                .selected()
                .and_then(|i| {
                    if i < self.history.len() {
                        self.history.get(self.history.len() - 1 - i)
                    } else {
                        None
                    }
                })
                .map(|(_, r)| r.clone())
                .unwrap_or_default(),
            _ => String::new(),
        };

        if text.is_empty() {
            self.status = " Nothing to yank".to_string();
            return;
        }

        if yank(&text) {
            self.status = format!(" Yanked: {text}");
        } else {
            self.status = " Yank failed".to_string();
        }
    }

    fn history_next(&mut self) {
        if self.history.is_empty() {
            return;
        }
        let i = match self.history_state.selected() {
            Some(i) => {
                if i >= self.history.len() - 1 {
                    0
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.history_state.select(Some(i));
    }

    fn history_prev(&mut self) {
        if self.history.is_empty() {
            return;
        }
        let i = match self.history_state.selected() {
            Some(i) => {
                if i == 0 {
                    self.history.len() - 1
                } else {
                    i - 1
                }
            }
            None => self.history.len() - 1,
        };
        self.history_state.select(Some(i));
    }
}

fn format_number(n: f64) -> String {
    // Try to format as integer with thousands separator if it's a whole number
    // Use epsilon comparison since float == 0.0 is unreliable
    if n.fract().abs() < f64::EPSILON
        && let Ok(int_val) = format!("{n:.0}").parse::<i64>()
    {
        return format_with_thousands(int_val);
    }

    // Fall back to decimal formatting
    let s = format!("{n:.10}")
        .trim_end_matches('0')
        .trim_end_matches('.')
        .to_string();

    // Format the integer part with thousands separator
    if let Some(dot_pos) = s.find('.') {
        let (int_part, dec_part) = s.split_at(dot_pos);
        if let Ok(i) = int_part.parse::<i64>() {
            format!("{}{}", format_with_thousands(i), dec_part)
        } else {
            s
        }
    } else {
        s
    }
}

fn format_with_thousands(n: i64) -> String {
    let (negative, abs_str) = if n == i64::MIN {
        (true, "9223372036854775808".to_string())
    } else {
        (n < 0, n.abs().to_string())
    };
    let chars: Vec<char> = abs_str.chars().collect();
    let mut result = String::new();

    for (i, c) in chars.iter().enumerate() {
        if i > 0 && (chars.len() - i).is_multiple_of(3) {
            result.push('\'');
        }
        result.push(*c);
    }

    if negative {
        format!("-{result}")
    } else {
        result
    }
}

impl App for CalcTui {
    fn title(&self) -> &'static str {
        "calc-tui"
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
            Action::Left => self.tabs.previous(),
            Action::Right => self.tabs.next(),
            Action::Select => {
                if self.current_tab() == 0 {
                    self.evaluate();
                }
            }
            Action::Back => {
                if self.current_tab() == 0 && !self.input.is_empty() {
                    self.input.pop();
                    self.status.clear();
                }
            }
            Action::Up => match self.current_tab() {
                0 => {
                    if self.focus > 0 {
                        self.focus -= 1;
                    }
                }
                1 => self.history_prev(),
                _ => {}
            },
            Action::Down => match self.current_tab() {
                0 => {
                    if self.focus < 1 {
                        self.focus += 1;
                    }
                }
                1 => self.history_next(),
                _ => {}
            },
            Action::Top => {
                if self.current_tab() == 0 && self.focus == 0 {
                    // In calculator input, '0' should be a digit (tuigreat maps 0 to Top)
                    self.input.push('0');
                    self.status.clear();
                } else if self.current_tab() == 1 && !self.history.is_empty() {
                    self.history_state.select(Some(0));
                }
            }
            Action::Bottom => {
                if self.current_tab() == 1 && !self.history.is_empty() {
                    self.history_state.select(Some(self.history.len() - 1));
                }
            }
            Action::Yank => self.do_yank(),
            Action::Char(c) => self.handle_char(c),
            // These are captured by keybindings, remap to operators
            Action::VolumeUp => {
                if self.current_tab() == 0 && self.focus == 0 {
                    self.input.push('+');
                    self.status.clear();
                }
            }
            Action::VolumeDown => {
                if self.current_tab() == 0 && self.focus == 0 {
                    self.input.push('-');
                    self.status.clear();
                }
            }
            Action::Search => {
                if self.current_tab() == 0 && self.focus == 0 {
                    self.input.push('/');
                    self.status.clear();
                }
            }
            Action::Delete => {
                self.input.clear();
                self.result.clear();
                self.status = " Cleared".to_string();
            }
            Action::Paste => self.do_paste(),
            _ => {}
        }
        Ok(true)
    }

    fn render(&mut self, frame: &mut Frame) {
        let chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1), // Tabs
                Constraint::Min(5),    // Content
                Constraint::Length(3), // Status
            ])
            .split(frame.area());

        // Tabs
        self.tabs.render(frame, chunks[0], &self.theme);

        // Content based on tab
        match self.current_tab() {
            0 => self.render_calculator_tab(frame, chunks[1]),
            1 => self.render_history_tab(frame, chunks[1]),
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
            let bindings = [
                ("h/l", "Switch tab"),
                ("0-9", "Digits"),
                ("+-*/ x :", "Operators"),
                ("^ ()", "Power, parens"),
                ("p", "Paste"),
                ("y", "Yank (copy)"),
                ("= / Enter", "Calculate"),
                ("d", "Clear all"),
                ("q", "Quit"),
            ];
            HelpPopup::render(frame, &bindings, &self.theme);
        }
    }
}

fn main() -> AppResult<()> {
    let app = CalcTui::new();
    tuigreat::app::run(app)
}
