mod library;
mod mpris;
mod playback;

use std::collections::HashSet;
use std::env;
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use library::{
    Album, Artist, Song, expand_tilde, scan_albums_in_artist, scan_music_dir, scan_songs,
    scan_songs_recursive,
};
use mpris::{MprisCommand, MprisHandle, MprisState, spawn_mpris_server};
use playback::{PlaybackOptions, ShuffleLevel};

use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout},
    style::{Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, Paragraph},
};
use rodio::{Decoder, OutputStream, Sink, Source};
use tuigreat::{
    Action, App, AppResult, StatusLevel, Theme,
    widgets::{HelpPopup, SearchDirection, SearchPopup, SelectableList, Tabs, centered_rect},
    yank,
};

/// UI input mode - mutually exclusive states
#[derive(Debug, Clone, Copy, PartialEq, Default)]
enum UiMode {
    #[default]
    Normal,
    Help,
    PathInput,
    Search,
    Jump {
        forward: bool,
    },
}

struct MusicTui {
    theme: Theme,
    tabs: Tabs,
    artists: SelectableList<Artist>,
    albums: SelectableList<Album>,
    songs: SelectableList<Song>,
    ui_mode: UiMode,
    focus: usize,      // 0 = artists, 1 = albums, 2 = songs
    has_artists: bool, // Whether we have artist-level hierarchy
    // Playback state
    sink: Option<Sink>,
    _stream: Option<rodio::OutputStream>,
    stream_handle: Option<rodio::OutputStreamHandle>,
    playing_artist: Option<String>,
    playing_album: Option<String>,
    playing_song: Option<usize>,
    playing_song_path: Option<PathBuf>,
    /// Volume stored as 0-100 percent to avoid float-to-int casts
    volume_pct: u8,
    start_time: Option<Instant>,
    pause_duration: Duration,
    song_duration: Option<Duration>,
    status: String,
    // Playback options
    playback: PlaybackOptions,
    // Music library root for "All" shuffle
    music_root: Option<PathBuf>,
    // Directory input popup
    path_input: String,
    path_error: Option<String>,
    // MPRIS
    mpris: MprisHandle,
}

impl MusicTui {
    fn new() -> AppResult<Self> {
        // Initialize audio output first
        let (stream, handle) = OutputStream::try_default()?;

        let (artists, albums, has_artists, need_path_input, music_root) =
            if let Some(arg) = env::args().nth(1) {
                let dir = expand_tilde(&arg);
                let (artists, albums, has_artists) = scan_music_dir(&dir);
                let is_empty = artists.is_empty() && albums.is_empty();
                let root = if is_empty { None } else { Some(dir) };
                (artists, albums, has_artists, is_empty, root)
            } else {
                // Check if current directory has music
                let cwd = PathBuf::from(".");
                let (artists, albums, has_artists) = scan_music_dir(&cwd);
                let is_empty = artists.is_empty() && albums.is_empty();
                if is_empty {
                    (vec![], vec![], false, true, None)
                } else {
                    (artists, albums, has_artists, false, Some(cwd))
                }
            };

        let status = if need_path_input {
            " Enter music directory path".to_string()
        } else if has_artists {
            format!(" {} artists", artists.len())
        } else {
            format!(" {} albums", albums.len())
        };

        // If no artists, start focus on albums (index 1)
        let initial_focus = usize::from(!has_artists);

        let ui_mode = if need_path_input {
            UiMode::PathInput
        } else {
            UiMode::Normal
        };

        let mut app = Self {
            theme: Theme::default(),
            tabs: Tabs::new(vec!["Library".to_string(), "Now Playing".to_string()])
                .with_app_title("Music Player v0.1"),
            artists: SelectableList::new(artists, |a| a.name.clone()),
            albums: SelectableList::new(albums, |a| a.name.clone()),
            songs: SelectableList::new(vec![], |s| s.name.clone()),
            ui_mode,
            focus: initial_focus,
            has_artists,
            sink: None,
            _stream: Some(stream),
            stream_handle: Some(handle),
            playing_artist: None,
            playing_album: None,
            playing_song: None,
            playing_song_path: None,
            volume_pct: 50,
            start_time: None,
            pause_duration: Duration::ZERO,
            song_duration: None,
            status,
            playback: PlaybackOptions::default(),
            music_root,
            path_input: String::new(),
            path_error: None,
            mpris: spawn_mpris_server(),
        };

        // Load initial data
        if has_artists {
            app.load_albums_for_selected_artist();
        }
        app.load_songs_for_selected_album();

        Ok(app)
    }

    fn load_directory(&mut self, path: &str) {
        let expanded = expand_tilde(path);

        if !expanded.exists() {
            self.path_error = Some(format!("Path does not exist: {}", expanded.display()));
            return;
        }

        if !expanded.is_dir() {
            self.path_error = Some("Not a directory".to_string());
            return;
        }

        let (artists, albums, has_artists) = scan_music_dir(&expanded);
        if artists.is_empty() && albums.is_empty() {
            self.path_error = Some("No music found in directory".to_string());
            return;
        }

        self.artists.set_items(artists);
        self.albums.set_items(albums);
        self.has_artists = has_artists;
        self.music_root = Some(expanded);
        self.ui_mode = UiMode::Normal;
        self.path_input.clear();
        self.path_error = None;

        if has_artists {
            self.focus = 0;
            self.status = format!(" {} artists", self.artists.items().len());
            self.load_albums_for_selected_artist();
        } else {
            self.focus = 1;
            self.status = format!(" {} albums", self.albums.items().len());
        }
        self.load_songs_for_selected_album();
    }

    fn load_albums_for_selected_artist(&mut self) {
        if let Some(artist) = self.artists.selected() {
            let albums = scan_albums_in_artist(&artist.path);
            let count = albums.len();
            self.albums.set_items(albums);
            self.status = format!(" {} albums by {}", count, artist.name);
        } else {
            self.albums.set_items(vec![]);
        }
    }

    fn load_songs_for_selected_album(&mut self) {
        if let Some(album) = self.albums.selected() {
            let songs = scan_songs(album);
            let count = songs.len();
            self.songs.set_items(songs);
            self.status = format!(" {} songs in {}", count, album.name);
        } else {
            self.songs.set_items(vec![]);
        }
    }

    /// Simple random number based on time
    fn simple_random(max: usize) -> usize {
        if max == 0 {
            return 0;
        }
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or(0);
        (nanos as usize) % max
    }

    /// Play the currently selected album from the first (or random) song
    fn play_album(&mut self) -> AppResult<()> {
        self.load_songs_for_selected_album();
        if self.songs.items().is_empty() {
            return Ok(());
        }

        // Pick first song or random if shuffle enabled
        let idx = if self.playback.shuffle {
            Self::simple_random(self.songs.items().len())
        } else {
            0
        };

        self.songs.select(idx);
        self.playing_artist = self.artists.selected().map(|a| a.name.clone());
        self.playing_album = self.albums.selected().map(|a| a.name.clone());
        self.playing_song = Some(idx);

        if let Some(song) = self.songs.items().get(idx).cloned() {
            self.playing_song_path = Some(song.path.clone());
            self.play_song(&song)?;
        }
        Ok(())
    }

    /// Play the first album of the currently selected artist
    fn play_artist(&mut self) -> AppResult<()> {
        self.load_albums_for_selected_artist();
        if self.albums.items().is_empty() {
            return Ok(());
        }

        // Select first album
        self.albums.first();
        self.play_album()
    }

    fn play_selected(&mut self) -> AppResult<()> {
        if let Some(song) = self.songs.selected().cloned() {
            self.playing_song_path = Some(song.path.clone());
            self.play_song(&song)?;
            self.playing_artist = self.artists.selected().map(|a| a.name.clone());
            self.playing_album = self.albums.selected().map(|a| a.name.clone());
            self.playing_song = self.songs.selected_index();
        }
        Ok(())
    }

    fn play_song(&mut self, song: &Song) -> AppResult<()> {
        if let Some(ref handle) = self.stream_handle {
            // Stop and drop current sink to free resources
            if let Some(old_sink) = self.sink.take() {
                old_sink.stop();
                drop(old_sink);
            }

            // Create new sink and play
            let sink = Sink::try_new(handle)?;
            let file = File::open(&song.path)?;
            let source = Decoder::new(BufReader::new(file))?;
            self.song_duration = source.total_duration();
            sink.append(source);
            sink.set_volume(self.volume_f32());
            sink.play();

            self.sink = Some(sink);
            self.playback.paused = false;
            self.start_time = Some(Instant::now());
            self.pause_duration = Duration::ZERO;
            self.status = format!(" Playing: {}", song.name);
            self.update_mpris_state();
        }
        Ok(())
    }

    fn toggle_pause(&mut self) {
        if let Some(ref sink) = self.sink {
            if self.playback.paused {
                // Resuming - restart the timer from now
                sink.play();
                self.playback.paused = false;
                self.start_time = Some(Instant::now());
                self.status = " Playing".to_string();
            } else {
                // Pausing - accumulate elapsed time before pausing
                if let Some(start) = self.start_time {
                    self.pause_duration += start.elapsed();
                }
                sink.pause();
                self.playback.paused = true;
                self.status = " Paused".to_string();
            }
        }
        self.update_mpris_state();
    }

    fn stop(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.stop();
        }
        self.sink = None;
        self.playing_artist = None;
        self.playing_album = None;
        self.playing_song = None;
        self.playing_song_path = None;
        self.playback.paused = false;
        self.start_time = None;
        self.song_duration = None;
        self.status = " Stopped".to_string();
        self.update_mpris_state();
    }

    fn update_mpris_state(&self) {
        let title = self
            .playing_song
            .and_then(|i| self.songs.items().get(i))
            .map(|s| s.name.clone())
            .unwrap_or_default();

        self.mpris.update_state(MprisState {
            title,
            artist: self.playing_artist.clone().unwrap_or_default(),
            album: self.playing_album.clone().unwrap_or_default(),
            playing: self.playing_song.is_some() && !self.playback.paused,
            volume: f64::from(self.volume_pct) / 100.0,
        });
    }

    /// Get shuffle level based on current focus (used when enabling shuffle)
    fn focus_to_shuffle_level(&self) -> ShuffleLevel {
        match self.focus {
            0 => ShuffleLevel::All,    // Artists focused = shuffle all
            1 => ShuffleLevel::Artist, // Albums focused = shuffle artist
            _ => ShuffleLevel::Album,  // Songs focused = shuffle album
        }
    }

    fn next_song(&mut self) -> AppResult<()> {
        if self.playback.shuffle {
            match self.playback.shuffle_level {
                ShuffleLevel::Album => self.next_song_shuffle_album()?,
                ShuffleLevel::Artist => self.next_song_shuffle_artist()?,
                ShuffleLevel::All => self.next_song_shuffle_all()?,
            }
        } else {
            self.next_song_sequential()?;
        }
        Ok(())
    }

    fn next_song_sequential(&mut self) -> AppResult<()> {
        let len = self.songs.items().len();
        if len == 0 {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }
        // Find current song by path, not stale index
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| self.songs.items().iter().position(|s| &s.path == p));
        let next_idx = match current_idx {
            Some(idx) => (idx + 1) % len,
            None => 0,
        };
        self.songs.select(next_idx);
        self.play_selected()
    }

    fn next_song_shuffle_album(&mut self) -> AppResult<()> {
        let len = self.songs.items().len();
        if len == 0 {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }
        // Find current song by path to avoid repeating
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| self.songs.items().iter().position(|s| &s.path == p));
        let next_idx = if len == 1 {
            0
        } else {
            let mut candidate = Self::simple_random(len);
            if Some(candidate) == current_idx {
                candidate = (candidate + 1) % len;
            }
            candidate
        };
        self.songs.select(next_idx);
        self.play_selected()
    }

    fn next_song_shuffle_artist(&mut self) -> AppResult<()> {
        // Get current artist
        let artist = match self.artists.selected() {
            Some(a) => a.clone(),
            None => return self.next_song_shuffle_album(), // Fallback
        };

        // Collect all songs from all albums by this artist
        let albums = scan_albums_in_artist(&artist.path);
        let mut all_songs: Vec<(usize, Song)> = Vec::new(); // (album_idx, song)

        for (album_idx, album) in albums.iter().enumerate() {
            for song in scan_songs(album) {
                all_songs.push((album_idx, song));
            }
        }

        if all_songs.is_empty() {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }

        // Find current song index to avoid repeating
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| all_songs.iter().position(|(_, s)| &s.path == p));

        // Pick random song, avoiding current
        let mut idx = Self::simple_random(all_songs.len());
        if all_songs.len() > 1 && Some(idx) == current_idx {
            idx = (idx + 1) % all_songs.len();
        }
        let (album_idx, song) = all_songs[idx].clone();

        // Update album selection and songs list
        self.albums.set_items(albums);
        self.albums.select(album_idx);
        self.load_songs_for_selected_album();

        // Find and select the song in the loaded list
        if let Some(song_idx) = self.songs.items().iter().position(|s| s.path == song.path) {
            self.songs.select(song_idx);
        }

        self.play_selected()
    }

    fn next_song_shuffle_all(&mut self) -> AppResult<()> {
        let root = match &self.music_root {
            Some(r) => r.clone(),
            None => return self.next_song_shuffle_album(), // Fallback
        };

        // Scan entire library for songs
        let mut all_songs: Vec<Song> = Vec::new();
        let mut visited: HashSet<PathBuf> = HashSet::new();
        scan_songs_recursive(&root, &mut all_songs, &mut visited);

        if all_songs.is_empty() {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }

        // Find current song index to avoid repeating
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| all_songs.iter().position(|s| &s.path == p));

        // Pick random song, avoiding current
        let mut idx = Self::simple_random(all_songs.len());
        if all_songs.len() > 1 && Some(idx) == current_idx {
            idx = (idx + 1) % all_songs.len();
        }
        let song = all_songs[idx].clone();

        // Find the album containing this song (parent directory)
        let Some(album_path) = song.path.parent().map(std::path::Path::to_path_buf) else {
            // Fallback: just play it
            self.playing_song_path = Some(song.path.clone());
            self.play_song(&song)?;
            self.playing_song = None;
            return Ok(());
        };

        // If we have artist hierarchy, find the artist first
        if self.has_artists
            && let Some(artist_path) = album_path.parent()
            && let Some(artist_idx) = self
                .artists
                .items()
                .iter()
                .position(|a| a.path == artist_path)
        {
            self.artists.select(artist_idx);
            self.load_albums_for_selected_artist();
        }

        // Now find the album in the (possibly updated) albums list
        if let Some(album_idx) = self
            .albums
            .items()
            .iter()
            .position(|a| a.path == album_path)
        {
            self.albums.select(album_idx);
            self.load_songs_for_selected_album();

            // Find the song in the loaded list
            if let Some(song_idx) = self.songs.items().iter().position(|s| s.path == song.path) {
                self.songs.select(song_idx);
                return self.play_selected();
            }
        }

        // Fallback: play directly if we couldn't navigate to it
        self.playing_song_path = Some(song.path.clone());
        self.play_song(&song)?;
        self.playing_artist = None;
        self.playing_album = album_path
            .file_name()
            .and_then(|n| n.to_str())
            .map(String::from);
        self.playing_song = None; // Not in current list
        self.status = format!(" Playing: {}", song.name);
        Ok(())
    }

    fn prev_song(&mut self) -> AppResult<()> {
        if self.playback.shuffle {
            // In shuffle mode, "previous" plays another random song from the same scope
            match self.playback.shuffle_level {
                ShuffleLevel::Album => self.prev_song_shuffle_album()?,
                ShuffleLevel::Artist => self.next_song_shuffle_artist()?, // Reuse next logic
                ShuffleLevel::All => self.next_song_shuffle_all()?,       // Reuse next logic
            }
        } else {
            self.prev_song_sequential()?;
        }
        Ok(())
    }

    fn prev_song_sequential(&mut self) -> AppResult<()> {
        let len = self.songs.items().len();
        if len == 0 {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }
        // Find current song by path, not stale index
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| self.songs.items().iter().position(|s| &s.path == p));
        let prev_idx = match current_idx {
            Some(idx) => {
                if idx == 0 {
                    len - 1
                } else {
                    idx - 1
                }
            }
            None => 0,
        };
        self.songs.select(prev_idx);
        self.play_selected()
    }

    fn prev_song_shuffle_album(&mut self) -> AppResult<()> {
        let len = self.songs.items().len();
        if len == 0 {
            self.playback.auto_play = false;
            self.status = " No songs available".to_string();
            return Ok(());
        }
        // Find current song by path to avoid repeating
        let current_idx = self
            .playing_song_path
            .as_ref()
            .and_then(|p| self.songs.items().iter().position(|s| &s.path == p));
        let prev_idx = if len == 1 {
            0
        } else {
            let mut candidate = Self::simple_random(len);
            if Some(candidate) == current_idx {
                candidate = (candidate + 1) % len;
            }
            candidate
        };
        self.songs.select(prev_idx);
        self.play_selected()
    }

    /// Get volume as f32 (0.0-1.0) for audio sink
    fn volume_f32(&self) -> f32 {
        f32::from(self.volume_pct) / 100.0
    }

    /// Get volume as percentage (0-100)
    fn volume_percent(&self) -> u32 {
        u32::from(self.volume_pct)
    }

    fn volume_up(&mut self) {
        self.volume_pct = self.volume_pct.saturating_add(5).min(100);
        if let Some(ref sink) = self.sink {
            sink.set_volume(self.volume_f32());
        }
        let pct = self.volume_percent();
        self.status = format!(" Volume: {pct}%");
    }

    fn volume_down(&mut self) {
        self.volume_pct = self.volume_pct.saturating_sub(5);
        if let Some(ref sink) = self.sink {
            sink.set_volume(self.volume_f32());
        }
        let pct = self.volume_percent();
        self.status = format!(" Volume: {pct}%");
    }

    fn jump_to_playing(&mut self) {
        // Jump to artist
        if let Some(ref artist_name) = self.playing_artist
            && let Some(idx) = self
                .artists
                .items()
                .iter()
                .position(|a| &a.name == artist_name)
        {
            self.artists.select(idx);
            self.load_albums_for_selected_artist();
        }

        // Jump to album
        if let Some(ref album_name) = self.playing_album
            && let Some(idx) = self
                .albums
                .items()
                .iter()
                .position(|a| &a.name == album_name)
        {
            self.albums.select(idx);
            self.load_songs_for_selected_album();
        }

        // Jump to song by path (more reliable after shuffle changes context)
        if let Some(ref song_path) = self.playing_song_path
            && let Some(idx) = self.songs.items().iter().position(|s| &s.path == song_path)
        {
            self.songs.select(idx);
        }

        self.status = " Jumped to playing".to_string();
    }

    fn current_tab(&self) -> usize {
        self.tabs.selected()
    }

    fn format_duration(d: Duration) -> String {
        let secs = d.as_secs();
        let mins = secs / 60;
        let secs = secs % 60;
        format!("{mins}:{secs:02}")
    }

    fn now_playing_info(&self) -> Vec<Line<'static>> {
        let mut lines = Vec::new();

        if let Some(ref artist) = self.playing_artist {
            lines.push(Line::from(format!("Artist: {artist}")));
        }

        if let Some(ref album) = self.playing_album {
            lines.push(Line::from(format!("Album: {album}")));
        }

        if let Some(ref song_path) = self.playing_song_path {
            // Look up song by path for accurate display after shuffle
            if let Some(song) = self.songs.items().iter().find(|s| &s.path == song_path) {
                let name = &song.name;
                lines.push(Line::from(format!("Song: {name}")));
            } else {
                // Song not in current list - get name from path
                let name = song_path
                    .file_stem()
                    .and_then(|s| s.to_str())
                    .unwrap_or("Unknown");
                lines.push(Line::from(format!("Song: {name}")));
            }
        } else {
            lines.push(Line::from("No song playing"));
        }

        // Time elapsed / total
        // pause_duration accumulates time from previous play segments
        // start_time marks when current segment started (reset on resume)
        let elapsed = if self.playback.paused {
            // When paused, pause_duration contains all accumulated time
            self.pause_duration
        } else if let Some(start) = self.start_time {
            // When playing, add current segment time to accumulated
            self.pause_duration + start.elapsed()
        } else {
            Duration::ZERO
        };

        if elapsed > Duration::ZERO || self.song_duration.is_some() {
            let elapsed_str = Self::format_duration(elapsed);
            let time_str = if let Some(total) = self.song_duration {
                let total_str = Self::format_duration(total);
                format!("Time: {elapsed_str} / {total_str}")
            } else {
                format!("Time: {elapsed_str}")
            };
            lines.push(Line::from(time_str));
        }

        let state = if self.playback.paused {
            "Paused"
        } else if self.playing_song_path.is_some() {
            "Playing"
        } else {
            "Stopped"
        };
        lines.push(Line::from(format!("State: {state}")));
        let pct = self.volume_percent();
        lines.push(Line::from(format!("Volume: {pct}%")));

        lines
    }

    /// Get the minimum focus level (0 if `has_artists`, 1 otherwise)
    fn min_focus(&self) -> usize {
        usize::from(!self.has_artists)
    }

    /// Start search on focused list
    fn start_search(&mut self, direction: SearchDirection) {
        match self.focus {
            0 => self.artists.start_search(direction),
            1 => self.albums.start_search(direction),
            _ => self.songs.start_search(direction),
        }
        self.ui_mode = UiMode::Search;
    }

    /// Push character to search on focused list
    fn search_push(&mut self, c: char) {
        match self.focus {
            0 => {
                self.artists.search_push(c);
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.search_push(c);
                self.load_songs_for_selected_album();
            }
            _ => self.songs.search_push(c),
        }
    }

    /// Pop character from search on focused list
    fn search_pop(&mut self) {
        match self.focus {
            0 => self.artists.search_pop(),
            1 => self.albums.search_pop(),
            _ => self.songs.search_pop(),
        }
    }

    /// Get search query from focused list
    fn focused_search_query(&self) -> &str {
        match self.focus {
            0 => self.artists.search_query(),
            1 => self.albums.search_query(),
            _ => self.songs.search_query(),
        }
    }

    /// Get match info from focused list
    fn focused_match_info(&self) -> Option<(usize, usize)> {
        match self.focus {
            0 => self.artists.match_info(),
            1 => self.albums.match_info(),
            _ => self.songs.match_info(),
        }
    }

    /// Clear search on focused list
    fn clear_search(&mut self) {
        match self.focus {
            0 => self.artists.clear_search(),
            1 => self.albums.clear_search(),
            _ => self.songs.clear_search(),
        }
        self.ui_mode = UiMode::Normal;
    }

    /// Next match on focused list
    fn next_match(&mut self) {
        match self.focus {
            0 => {
                self.artists.next_match();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.next_match();
                self.load_songs_for_selected_album();
            }
            _ => {
                self.songs.next_match();
            }
        }
    }

    /// Previous match on focused list
    fn prev_match(&mut self) {
        match self.focus {
            0 => {
                self.artists.prev_match();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.prev_match();
                self.load_songs_for_selected_album();
            }
            _ => {
                self.songs.prev_match();
            }
        }
    }

    /// Half page down on focused list
    fn half_page_down(&mut self) {
        match self.focus {
            0 => {
                self.artists.half_page_down();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.half_page_down();
                self.load_songs_for_selected_album();
            }
            _ => self.songs.half_page_down(),
        }
    }

    /// Half page up on focused list
    fn half_page_up(&mut self) {
        match self.focus {
            0 => {
                self.artists.half_page_up();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.half_page_up();
                self.load_songs_for_selected_album();
            }
            _ => self.songs.half_page_up(),
        }
    }

    /// Full page down on focused list
    fn full_page_down(&mut self) {
        match self.focus {
            0 => {
                self.artists.page_down();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.page_down();
                self.load_songs_for_selected_album();
            }
            _ => self.songs.page_down(),
        }
    }

    /// Full page up on focused list
    fn full_page_up(&mut self) {
        match self.focus {
            0 => {
                self.artists.page_up();
                self.load_albums_for_selected_artist();
                self.load_songs_for_selected_album();
            }
            1 => {
                self.albums.page_up();
                self.load_songs_for_selected_album();
            }
            _ => self.songs.page_up(),
        }
    }

    /// Yank selected item to clipboard
    fn yank_selected(&mut self) {
        let text = match self.focus {
            0 => self.artists.selected().map(|a| a.name.clone()),
            1 => self.albums.selected().map(|a| a.name.clone()),
            _ => self.songs.selected().map(|s| s.name.clone()),
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

    /// Render the library tab (artists/albums/songs)
    fn render_library_tab(&mut self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let content_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(40), Constraint::Percentage(60)])
            .split(area);

        let playing_artist_idx = self
            .playing_artist
            .as_ref()
            .and_then(|name| self.artists.items().iter().position(|a| &a.name == name));
        let playing_album_idx = self
            .playing_album
            .as_ref()
            .and_then(|name| self.albums.items().iter().position(|a| &a.name == name));

        if self.has_artists && self.focus <= 1 {
            self.artists.render_with_marker(
                frame,
                content_chunks[0],
                " Artists ",
                &self.theme,
                self.focus == 0,
                playing_artist_idx,
            );
            self.albums.render_with_marker(
                frame,
                content_chunks[1],
                " Albums ",
                &self.theme,
                self.focus == 1,
                playing_album_idx,
            );
        } else {
            // Look up playing song by path for accurate marker
            let playing_song_idx = self
                .playing_song_path
                .as_ref()
                .and_then(|path| self.songs.items().iter().position(|s| &s.path == path));
            self.albums.render_with_marker(
                frame,
                content_chunks[0],
                " Albums ",
                &self.theme,
                self.focus == 1,
                playing_album_idx,
            );
            self.songs.render_with_marker(
                frame,
                content_chunks[1],
                " Songs ",
                &self.theme,
                self.focus == 2,
                playing_song_idx,
            );
        }
    }

    /// Render the now playing tab
    fn render_now_playing_tab(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let info = self.now_playing_info();
        let block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());
        let para = Paragraph::new(info).block(block);
        frame.render_widget(para, area);
    }

    /// Render the status bar with indicators
    fn render_status_bar(&self, frame: &mut Frame, area: ratatui::layout::Rect) {
        let status_block = Block::default()
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border());

        // volume_pct is 0-100, so vol_level is 0-10
        let vol_level = self.volume_pct / 10;
        let vol_bar = format!(
            "[{}{}]",
            "=".repeat(vol_level as usize),
            " ".repeat((10 - vol_level) as usize)
        );

        let shuffle_indicator = if self.playback.shuffle {
            format!("[{}]", self.playback.shuffle_level.short())
        } else {
            "[-]".to_string()
        };
        let shuffle_style = if self.playback.shuffle {
            self.theme.success()
        } else {
            self.theme.muted()
        };
        let auto_style = if self.playback.auto_play {
            self.theme.success()
        } else {
            self.theme.muted()
        };

        let status_style = StatusLevel::from_text(&self.status).style(&self.theme);
        let status_text = Line::from(vec![
            Span::raw(" "),
            Span::styled(shuffle_indicator, shuffle_style),
            Span::styled("[A]", auto_style),
            Span::raw(vol_bar),
            Span::styled(self.status.clone(), status_style),
        ]);
        let status = Paragraph::new(status_text).block(status_block);
        frame.render_widget(status, area);
    }

    /// Get title for search popup based on current focus
    fn search_popup_title(&self) -> &'static str {
        match self.focus {
            0 => " Search Artists ",
            1 => " Search Albums ",
            _ => " Search Songs ",
        }
    }

    /// Render the path input popup
    fn render_path_input_popup(&self, frame: &mut Frame) {
        let area = centered_rect(60, 9, frame.area());
        frame.render_widget(Clear, area);

        let block = Block::default()
            .title(" Music Directory ")
            .title_style(self.theme.title())
            .borders(Borders::ALL)
            .border_type(Theme::BORDER_TYPE)
            .border_style(self.theme.border_focused());

        let error_line = if let Some(ref err) = self.path_error {
            Line::from(Span::styled(format!("  {err}"), self.theme.error()))
        } else {
            Line::from("")
        };

        let content = vec![
            Line::from(""),
            Line::from(vec![
                Span::raw("  Path: "),
                Span::raw(&self.path_input),
                Span::styled("_", Style::default().add_modifier(Modifier::SLOW_BLINK)),
            ]),
            Line::from(""),
            error_line,
            Line::from(""),
            Line::from(Span::styled(
                "  [Enter] Load  [Esc] Cancel",
                self.theme.muted(),
            )),
        ];

        let popup = Paragraph::new(content).block(block);
        frame.render_widget(popup, area);
    }

    /// Handle actions when in search mode
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
                // Confirm search, exit search mode but keep matches
                self.ui_mode = UiMode::Normal;
                if let Some((cur, total)) = self.focused_match_info() {
                    self.status = format!(" Match {cur}/{total}");
                }
            }
            Action::Char(c) => self.search_push(c),
            _ => {}
        }
    }

    /// Handle actions when in path input mode. Returns false if should quit.
    fn handle_path_input_action(&mut self, action: Action) -> bool {
        match action {
            Action::Back => {
                if self.path_input.is_empty() {
                    // Cancel - quit if no albums loaded
                    if self.albums.items().is_empty() {
                        return false;
                    }
                    self.ui_mode = UiMode::Normal;
                    self.path_error = None;
                } else {
                    self.path_input.pop();
                    self.path_error = None;
                }
            }
            Action::Quit => {
                if self.albums.items().is_empty() {
                    return false;
                }
                self.ui_mode = UiMode::Normal;
                self.path_input.clear();
                self.path_error = None;
            }
            Action::Select => {
                let path = self.path_input.clone();
                self.load_directory(&path);
            }
            Action::Char(c) => {
                self.path_input.push(c);
                self.path_error = None;
            }
            _ => {}
        }
        true
    }

    /// Handle navigation actions (up/down/left/right/top/bottom)
    fn handle_navigation(&mut self, action: Action) {
        if self.current_tab() != 0 {
            return;
        }
        match action {
            Action::Down => match self.focus {
                0 => {
                    self.artists.next();
                    self.load_albums_for_selected_artist();
                    self.load_songs_for_selected_album();
                }
                1 => {
                    self.albums.next();
                    self.load_songs_for_selected_album();
                }
                2 => self.songs.next(),
                _ => {}
            },
            Action::Up => match self.focus {
                0 => {
                    self.artists.previous();
                    self.load_albums_for_selected_artist();
                    self.load_songs_for_selected_album();
                }
                1 => {
                    self.albums.previous();
                    self.load_songs_for_selected_album();
                }
                2 => self.songs.previous(),
                _ => {}
            },
            Action::Top => match self.focus {
                0 => {
                    self.artists.first();
                    self.load_albums_for_selected_artist();
                    self.load_songs_for_selected_album();
                }
                1 => {
                    self.albums.first();
                    self.load_songs_for_selected_album();
                }
                2 => self.songs.first(),
                _ => {}
            },
            Action::Bottom => match self.focus {
                0 => {
                    self.artists.last();
                    self.load_albums_for_selected_artist();
                    self.load_songs_for_selected_album();
                }
                1 => {
                    self.albums.last();
                    self.load_songs_for_selected_album();
                }
                2 => self.songs.last(),
                _ => {}
            },
            _ => {}
        }
    }

    /// Handle playback-related actions
    fn handle_playback_action(&mut self, action: Action) -> AppResult<()> {
        match action {
            Action::Mute | Action::Char(' ') => self.toggle_pause(),
            Action::VolumeUp => self.volume_up(),
            Action::VolumeDown => self.volume_down(),
            Action::Delete => self.stop(),
            Action::Char('>') => self.next_song()?,
            Action::Char('<') => self.prev_song()?,
            Action::Char('a') => {
                self.playback.auto_play = !self.playback.auto_play;
                self.status = format!(
                    " Auto-play: {}",
                    if self.playback.auto_play { "ON" } else { "OFF" }
                );
            }
            Action::Char('S') => {
                self.playback.shuffle = !self.playback.shuffle;
                if self.playback.shuffle {
                    self.playback.shuffle_level = self.focus_to_shuffle_level();
                }
                self.status = format!(
                    " Shuffle: {}",
                    if self.playback.shuffle {
                        self.playback.shuffle_level.short()
                    } else {
                        "OFF"
                    }
                );
            }
            Action::Refresh | Action::Char('r') => {
                // Pick random from focused list and play
                match self.focus {
                    0 if !self.artists.items().is_empty() => {
                        let idx = Self::simple_random(self.artists.items().len());
                        self.artists.select(idx);
                        self.load_albums_for_selected_artist();
                        self.load_songs_for_selected_album();
                        self.play_selected()?;
                    }
                    1 if !self.albums.items().is_empty() => {
                        let idx = Self::simple_random(self.albums.items().len());
                        self.albums.select(idx);
                        self.load_songs_for_selected_album();
                        self.play_selected()?;
                    }
                    2 if !self.songs.items().is_empty() => {
                        let idx = Self::simple_random(self.songs.items().len());
                        self.songs.select(idx);
                        self.play_selected()?;
                    }
                    _ => {}
                }
            }
            _ => {}
        }
        Ok(())
    }
}

impl App for MusicTui {
    fn title(&self) -> &'static str {
        "music-tui"
    }

    fn theme(&self) -> &Theme {
        &self.theme
    }

    fn input_mode(&self) -> bool {
        matches!(
            self.ui_mode,
            UiMode::PathInput | UiMode::Search | UiMode::Jump { .. }
        )
    }

    fn tick(&mut self) -> AppResult<()> {
        // Handle MPRIS commands
        while let Ok(cmd) = self.mpris.cmd_rx.try_recv() {
            match cmd {
                MprisCommand::PlayPause => self.toggle_pause(),
                MprisCommand::Play => {
                    if self.playback.paused {
                        self.toggle_pause();
                    }
                }
                MprisCommand::Pause => {
                    if !self.playback.paused && self.playing_song_path.is_some() {
                        self.toggle_pause();
                    }
                }
                MprisCommand::Stop => self.stop(),
                MprisCommand::Next => {
                    let _ = self.next_song();
                }
                MprisCommand::Previous => {
                    let _ = self.prev_song();
                }
            }
        }

        // Check if current song finished and auto-play is enabled
        if self.playback.auto_play
            && self.playing_song_path.is_some()
            && !self.playback.paused
            && let Some(ref sink) = self.sink
            && sink.empty()
        {
            // Song finished, play next
            self.next_song()?;
        }
        Ok(())
    }

    #[allow(clippy::too_many_lines)]
    fn handle_action(&mut self, action: Action) -> AppResult<bool> {
        // Jump mode - waiting for character
        if let UiMode::Jump { forward } = self.ui_mode {
            match action {
                Action::Char(c) => {
                    let found = match self.focus {
                        0 => self.artists.jump_to_char(c, forward),
                        1 => self.albums.jump_to_char(c, forward),
                        _ => self.songs.jump_to_char(c, forward),
                    };
                    if found {
                        // Load dependent data when artist/album changes
                        if self.focus == 0 {
                            self.load_albums_for_selected_artist();
                            self.load_songs_for_selected_album();
                        } else if self.focus == 1 {
                            self.load_songs_for_selected_album();
                        }
                        self.status = format!(" Jumped to '{c}'");
                    } else {
                        self.status = format!(" No match for '{c}'");
                    }
                }
                _ => {
                    self.status = " Jump cancelled".to_string();
                }
            }
            self.ui_mode = UiMode::Normal;
            return Ok(true);
        }

        // Search mode
        if self.ui_mode == UiMode::Search {
            self.handle_search_action(action);
            return Ok(true);
        }

        // Path input mode
        if self.ui_mode == UiMode::PathInput {
            return Ok(self.handle_path_input_action(action));
        }

        // Help mode
        if self.ui_mode == UiMode::Help {
            if matches!(action, Action::Help | Action::Back | Action::Quit) {
                self.ui_mode = UiMode::Normal;
            }
            return Ok(true);
        }

        // Normal mode - dispatch to appropriate handlers
        match action {
            Action::Quit => {
                self.stop();
                return Ok(false);
            }
            Action::Help => self.ui_mode = UiMode::Help,
            // Navigation
            Action::Down | Action::Up | Action::Top | Action::Bottom => {
                self.handle_navigation(action);
            }
            Action::Left => {
                if self.current_tab() == 0 && self.focus > self.min_focus() {
                    self.focus -= 1;
                } else {
                    self.tabs.previous();
                }
            }
            Action::Right => {
                if self.current_tab() == 0 && self.focus < 2 {
                    self.focus += 1;
                } else {
                    self.tabs.next();
                }
            }
            // Selection
            Action::Select => {
                if self.current_tab() == 0 {
                    match self.focus {
                        0 => self.play_artist()?,
                        1 => self.play_album()?,
                        2 => self.play_selected()?,
                        _ => {}
                    }
                }
            }
            // Page navigation
            Action::PageUp => self.half_page_up(),
            Action::PageDown => self.half_page_down(),
            Action::FullPageUp => self.full_page_up(),
            Action::FullPageDown => self.full_page_down(),
            // Search
            Action::Search => {
                if self.current_tab() == 0 {
                    self.start_search(SearchDirection::Forward);
                }
            }
            Action::SearchNext => self.next_match(),
            Action::SearchPrev => self.prev_match(),
            // Yank
            Action::Yank => self.yank_selected(),
            // Playback (delegate to helper)
            Action::Mute
            | Action::VolumeUp
            | Action::VolumeDown
            | Action::Delete
            | Action::Refresh
            | Action::Char(' ' | '>' | '<' | 'a' | 'S' | 'r') => {
                self.handle_playback_action(action)?;
            }
            // Jump to char (vim-style f/F)
            Action::JumpTo => {
                if self.current_tab() == 0 {
                    self.ui_mode = UiMode::Jump { forward: true };
                    self.status = " Jump to: ".to_string();
                }
            }
            Action::JumpBack => {
                if self.current_tab() == 0 {
                    self.ui_mode = UiMode::Jump { forward: false };
                    self.status = " Jump back to: ".to_string();
                }
            }
            // Jump to playing
            Action::Paste => self.jump_to_playing(),
            // Open directory picker
            Action::Char('o') => {
                self.ui_mode = UiMode::PathInput;
                self.path_input.clear();
                self.path_error = None;
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
            0 => self.render_library_tab(frame, main_chunks[1]),
            1 => self.render_now_playing_tab(frame, main_chunks[1]),
            _ => {}
        }

        // Status bar
        self.render_status_bar(frame, main_chunks[2]);

        // Popups based on UI mode
        match self.ui_mode {
            UiMode::Help => {
                let bindings = [
                    ("j/k", "Navigate"),
                    ("h/l", "Switch panel"),
                    ("g/G", "Top/Bottom"),
                    ("C-u/C-d", "Half page"),
                    ("C-b/C-f", "Full page"),
                    ("/", "Search"),
                    ("n/N", "Next/Prev match"),
                    ("y", "Yank (copy)"),
                    ("Enter", "Play"),
                    ("Space/m", "Pause"),
                    ("+/-", "Volume"),
                    ("</>", "Prev/Next song"),
                    ("f/F", "Jump to char"),
                    ("p", "Jump to playing"),
                    ("r", "Play random"),
                    ("S", "Toggle shuffle"),
                    ("a", "Toggle auto-play"),
                    ("o", "Open directory"),
                    ("d", "Stop"),
                    ("q", "Quit"),
                ];
                HelpPopup::render(frame, &bindings, &self.theme);
            }
            UiMode::Search => SearchPopup::render(
                frame,
                self.search_popup_title(),
                self.focused_search_query(),
                self.focused_match_info(),
                &self.theme,
            ),
            UiMode::PathInput => self.render_path_input_popup(frame),
            UiMode::Normal | UiMode::Jump { .. } => {}
        }
    }
}

fn main() -> AppResult<()> {
    let app = MusicTui::new()?;
    tuigreat::app::run(app)
}
