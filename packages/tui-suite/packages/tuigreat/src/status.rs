//! Status message helpers for consistent styling across TUI apps.

use ratatui::{
    style::Style,
    text::{Line, Span},
};

use crate::Theme;

/// Status message severity level.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum StatusLevel {
    /// Normal informational message (muted color)
    #[default]
    Info,
    /// Success message (green)
    Success,
    /// Warning message (yellow)
    Warning,
    /// Error message (red)
    Error,
}

impl StatusLevel {
    /// Detect status level from message content.
    /// Looks for common prefixes like "Error:", "Failed:", etc.
    #[must_use]
    pub fn from_text(text: &str) -> Self {
        let t = text.trim_start();
        if t.starts_with("Error:")
            || t.starts_with("Failed:")
            || t.starts_with("Invalid")
            || t.contains("failed")
        {
            Self::Error
        } else if t.starts_with("Warning:") {
            Self::Warning
        } else {
            Self::Info
        }
    }

    /// Get the appropriate style for this status level.
    #[must_use]
    pub fn style(self, theme: &Theme) -> Style {
        match self {
            Self::Info => theme.muted(),
            Self::Success => theme.success(),
            Self::Warning => theme.warning(),
            Self::Error => theme.error(),
        }
    }
}

/// A styled status message.
#[derive(Debug, Clone, Default)]
pub struct StatusMessage {
    pub text: String,
    pub level: StatusLevel,
}

impl StatusMessage {
    /// Create a new info-level status message.
    #[must_use]
    pub fn info(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            level: StatusLevel::Info,
        }
    }

    /// Create a new success-level status message.
    #[must_use]
    pub fn success(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            level: StatusLevel::Success,
        }
    }

    /// Create a new warning-level status message.
    #[must_use]
    pub fn warning(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            level: StatusLevel::Warning,
        }
    }

    /// Create a new error-level status message.
    #[must_use]
    pub fn error(text: impl Into<String>) -> Self {
        Self {
            text: text.into(),
            level: StatusLevel::Error,
        }
    }

    /// Get the appropriate style for this status level.
    #[must_use]
    pub fn style(&self, theme: &Theme) -> Style {
        self.level.style(theme)
    }

    /// Convert to a Line with proper styling.
    #[must_use]
    pub fn to_line(&self, theme: &Theme) -> Line<'static> {
        Line::from(vec![
            Span::raw(" "),
            Span::styled(self.text.clone(), self.style(theme)),
        ])
    }

    /// Check if the message is empty.
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.text.is_empty()
    }

    /// Clear the message.
    pub fn clear(&mut self) {
        self.text.clear();
        self.level = StatusLevel::Info;
    }
}

impl From<String> for StatusMessage {
    fn from(text: String) -> Self {
        Self::info(text)
    }
}

impl From<&str> for StatusMessage {
    fn from(text: &str) -> Self {
        Self::info(text)
    }
}

/// Render a status line with automatic level detection based on content.
/// This is a convenience function for apps that use plain strings for status.
#[must_use]
pub fn status_line(text: &str, theme: &Theme) -> Line<'static> {
    let level = StatusLevel::from_text(text);
    Line::from(vec![
        Span::raw(" "),
        Span::styled(text.to_string(), level.style(theme)),
    ])
}
