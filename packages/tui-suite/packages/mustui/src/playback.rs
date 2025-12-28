//! Playback options and state management.

/// Shuffle scope level.
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum ShuffleLevel {
    #[default]
    Album, // Shuffle within current album (focus on songs)
    Artist, // Shuffle within current artist (focus on albums)
    All,    // Shuffle across entire library (focus on artists)
}

impl ShuffleLevel {
    /// Short display string for status bar.
    #[must_use]
    pub fn short(self) -> &'static str {
        match self {
            Self::Album => "A",
            Self::Artist => "R",
            Self::All => "*",
        }
    }
}

/// Playback options and state.
#[derive(Debug, Clone, Copy)]
pub struct PlaybackOptions {
    pub paused: bool,
    pub auto_play: bool,
    pub shuffle: bool,
    pub shuffle_level: ShuffleLevel,
}

impl Default for PlaybackOptions {
    fn default() -> Self {
        Self {
            paused: false,
            auto_play: true,
            shuffle: false,
            shuffle_level: ShuffleLevel::Album,
        }
    }
}
