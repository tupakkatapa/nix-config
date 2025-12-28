use ratatui::{
    style::{Color, Modifier, Style},
    widgets::{BorderType, block::Title},
};

// TUI Suite brand colors - clean, modern palette
pub struct Theme {
    pub bg: Color,
    pub fg: Color,
    pub accent: Color,
    pub accent_dim: Color,
    pub selected_bg: Color,
    pub selected_fg: Color,
    pub error: Color,
    pub success: Color,
    pub warning: Color,
    pub muted: Color,
}

impl Default for Theme {
    fn default() -> Self {
        Self {
            bg: Color::Reset,
            fg: Color::Rgb(220, 220, 220),          // Soft white
            accent: Color::Rgb(138, 180, 248),      // Soft blue
            accent_dim: Color::Rgb(88, 88, 88),     // Dim gray
            selected_bg: Color::Rgb(138, 180, 248), // Soft blue bg
            selected_fg: Color::Rgb(30, 30, 30),    // Dark text on selection
            error: Color::Rgb(242, 139, 130),       // Soft red
            success: Color::Rgb(129, 201, 149),     // Soft green
            warning: Color::Rgb(253, 214, 99),      // Soft yellow
            muted: Color::Rgb(120, 120, 120),       // Medium gray
        }
    }
}

impl Theme {
    pub const BORDER_TYPE: BorderType = BorderType::Rounded;

    #[must_use]
    pub fn normal(&self) -> Style {
        Style::default().fg(self.fg)
    }

    #[must_use]
    pub fn highlight(&self) -> Style {
        Style::default()
            .fg(self.accent)
            .add_modifier(Modifier::BOLD)
    }

    #[must_use]
    pub fn selected(&self) -> Style {
        Style::default()
            .fg(self.selected_fg)
            .bg(self.selected_bg)
            .add_modifier(Modifier::BOLD)
    }

    #[must_use]
    pub fn muted(&self) -> Style {
        Style::default().fg(self.muted)
    }

    #[must_use]
    pub fn error(&self) -> Style {
        Style::default().fg(self.error)
    }

    #[must_use]
    pub fn success(&self) -> Style {
        Style::default().fg(self.success)
    }

    #[must_use]
    pub fn warning(&self) -> Style {
        Style::default().fg(self.warning)
    }

    #[must_use]
    pub fn title(&self) -> Style {
        Style::default()
            .fg(self.accent)
            .add_modifier(Modifier::BOLD)
    }

    #[must_use]
    pub fn border(&self) -> Style {
        Style::default().fg(self.accent_dim)
    }

    #[must_use]
    pub fn border_focused(&self) -> Style {
        Style::default().fg(self.accent)
    }

    #[must_use]
    pub fn brand_title<'a>(&self, name: &'a str) -> Title<'a> {
        Title::from(format!(" {name} "))
    }
}
