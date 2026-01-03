//! Music library scanning and data types.

use std::collections::HashSet;
use std::env;
use std::fs;
use std::path::PathBuf;

#[derive(Clone)]
pub struct Artist {
    pub name: String,
    pub path: PathBuf,
}

#[derive(Clone)]
pub struct Album {
    pub name: String,
    pub path: PathBuf,
}

#[derive(Clone)]
pub struct Song {
    pub name: String,
    pub path: PathBuf,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DirType {
    /// Directory contains audio files directly (it's an album)
    Album,
    /// Directory contains album directories (artist or flat library)
    ArtistOrLibrary,
    /// Directory contains artist directories which contain albums
    Library,
    /// No audio files found
    Empty,
}

const AUDIO_EXTENSIONS: &[&str] = &["mp3", "flac", "wav", "ogg", "m4a", "aac"];

/// Expand tilde in paths to home directory.
pub fn expand_tilde(path: &str) -> PathBuf {
    if let Some(rest) = path.strip_prefix("~/") {
        if let Ok(home) = env::var("HOME") {
            return PathBuf::from(home).join(rest);
        }
    } else if path == "~"
        && let Ok(home) = env::var("HOME")
    {
        return PathBuf::from(home);
    }
    PathBuf::from(path)
}

/// Detect what type of directory this is based on where audio files are.
pub fn detect_dir_type(dir: &PathBuf) -> DirType {
    // Check if this directory has audio files directly
    if has_direct_audio_files(dir) {
        return DirType::Album;
    }

    // Check subdirectories
    let mut has_album_subdirs = false;
    let mut has_artist_subdirs = false;

    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if has_direct_audio_files(&path) {
                    // Subdir has audio files directly - it's an album
                    has_album_subdirs = true;
                } else if has_album_subdirs_in(&path) {
                    // Subdir has album subdirs - it's an artist
                    has_artist_subdirs = true;
                }
            }
        }
    }

    if has_artist_subdirs {
        DirType::Library
    } else if has_album_subdirs {
        DirType::ArtistOrLibrary
    } else {
        DirType::Empty
    }
}

/// Check if directory has audio files directly (not in subdirs).
pub fn has_direct_audio_files(dir: &PathBuf) -> bool {
    let Ok(entries) = fs::read_dir(dir) else {
        return false;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_file()
            && let Some(ext) = path.extension().and_then(|e| e.to_str())
            && AUDIO_EXTENSIONS.contains(&ext.to_lowercase().as_str())
        {
            return true;
        }
    }
    false
}

/// Check if directory has subdirectories that contain audio files.
fn has_album_subdirs_in(dir: &PathBuf) -> bool {
    let Ok(entries) = fs::read_dir(dir) else {
        return false;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() && has_direct_audio_files(&path) {
            return true;
        }
    }
    false
}

/// Scan directory and return (artists, albums, `has_artists`).
pub fn scan_music_dir(dir: &PathBuf) -> (Vec<Artist>, Vec<Album>, bool) {
    let dir_type = detect_dir_type(dir);

    match dir_type {
        DirType::Album => {
            // This directory IS an album - no artists, just one album
            let name = dir
                .file_name()
                .and_then(|s| s.to_str())
                .unwrap_or("Unknown")
                .to_string();

            let albums = vec![Album {
                name,
                path: dir.clone(),
            }];
            (vec![], albums, false)
        }
        DirType::ArtistOrLibrary => {
            // Subdirs are albums - no artist hierarchy
            let mut albums = Vec::new();

            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.is_dir() && has_direct_audio_files(&path) {
                        let name = path
                            .file_name()
                            .and_then(|s| s.to_str())
                            .unwrap_or("Unknown")
                            .to_string();

                        albums.push(Album { name, path });
                    }
                }
            }

            albums.sort_by(|a, b| a.name.cmp(&b.name));
            (vec![], albums, false)
        }
        DirType::Library => {
            // Subdirs are artists - we have the full hierarchy
            let mut artists = Vec::new();

            if let Ok(entries) = fs::read_dir(dir) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.is_dir() && has_album_subdirs_in(&path) {
                        let name = path
                            .file_name()
                            .and_then(|s| s.to_str())
                            .unwrap_or("Unknown")
                            .to_string();

                        artists.push(Artist { name, path });
                    }
                }
            }

            artists.sort_by(|a, b| a.name.cmp(&b.name));
            // Albums will be loaded when artist is selected
            (artists, vec![], true)
        }
        DirType::Empty => (vec![], vec![], false),
    }
}

/// Scan albums within an artist directory.
pub fn scan_albums_in_artist(artist_path: &PathBuf) -> Vec<Album> {
    let mut albums = Vec::new();

    if let Ok(entries) = fs::read_dir(artist_path) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() && has_direct_audio_files(&path) {
                let name = path
                    .file_name()
                    .and_then(|s| s.to_str())
                    .unwrap_or("Unknown")
                    .to_string();

                albums.push(Album { name, path });
            }
        }
    }

    albums.sort_by(|a, b| a.name.cmp(&b.name));
    albums
}

/// Scan songs in an album directory.
pub fn scan_songs(album: &Album) -> Vec<Song> {
    let mut songs = Vec::new();
    let mut visited = HashSet::new();
    scan_songs_recursive(&album.path, &mut songs, &mut visited);
    songs.sort_by(|a, b| a.name.cmp(&b.name));
    songs
}

/// Recursively scan for songs in a directory.
pub fn scan_songs_recursive(dir: &PathBuf, songs: &mut Vec<Song>, visited: &mut HashSet<PathBuf>) {
    let Ok(canonical) = fs::canonicalize(dir) else {
        return;
    };

    if !visited.insert(canonical) {
        return;
    }

    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            scan_songs_recursive(&path, songs, visited);
        } else if path.is_file()
            && let Some(ext) = path.extension().and_then(|e| e.to_str())
            && AUDIO_EXTENSIONS.contains(&ext.to_lowercase().as_str())
        {
            let name = path
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("Unknown")
                .to_string();
            songs.push(Song { name, path });
        }
    }
}
