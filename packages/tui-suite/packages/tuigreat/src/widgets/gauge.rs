use ratatui::{
    Frame,
    layout::Rect,
    widgets::{Block, Borders, Gauge},
};

use crate::Theme;

pub struct VolumeGauge;

impl VolumeGauge {
    pub fn render(
        frame: &mut Frame,
        area: Rect,
        label: &str,
        volume: u8,
        muted: bool,
        theme: &Theme,
    ) {
        let style = if muted {
            theme.muted()
        } else {
            theme.highlight()
        };

        let label_text = if muted {
            format!("{label} [MUTED]")
        } else {
            format!("{label} {volume}%")
        };

        let gauge = Gauge::default()
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .border_style(theme.border())
                    .title(label_text)
                    .title_style(style),
            )
            .gauge_style(style)
            .percent(u16::from(volume));

        frame.render_widget(gauge, area);
    }
}
