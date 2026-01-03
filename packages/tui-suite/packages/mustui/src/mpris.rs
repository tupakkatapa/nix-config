use mpris_server::{Metadata, PlaybackStatus, Player};
use std::sync::mpsc;
use std::thread;
use tokio::sync::watch;
use tokio::task::LocalSet;

#[derive(Debug, Clone)]
pub enum MprisCommand {
    PlayPause,
    Play,
    Pause,
    Stop,
    Next,
    Previous,
}

#[derive(Debug, Clone)]
pub struct MprisState {
    pub title: String,
    pub artist: String,
    pub album: String,
    pub playing: bool,
    pub volume: f64,
}

impl Default for MprisState {
    fn default() -> Self {
        Self {
            title: String::new(),
            artist: String::new(),
            album: String::new(),
            playing: false,
            volume: 0.5,
        }
    }
}

pub struct MprisHandle {
    pub cmd_rx: mpsc::Receiver<MprisCommand>,
    state_tx: watch::Sender<MprisState>,
}

impl MprisHandle {
    pub fn update_state(&self, state: MprisState) {
        let _ = self.state_tx.send(state);
    }
}

pub fn spawn_mpris_server() -> MprisHandle {
    let (cmd_tx, cmd_rx) = mpsc::channel();
    let (state_tx, mut state_rx) = watch::channel(MprisState::default());

    thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("Failed to create tokio runtime");

        let local = LocalSet::new();
        local.block_on(&rt, async move {
            // Use "a_mustui" to sort before firefox alphabetically for playerctl priority
            let player = match Player::builder("a_mustui")
                .can_play(true)
                .can_pause(true)
                .can_go_next(true)
                .can_go_previous(true)
                .can_control(true)
                .build()
                .await
            {
                Ok(p) => p,
                Err(e) => {
                    eprintln!("Failed to create MPRIS player: {e}");
                    return;
                }
            };

            // Connect play/pause handler
            let tx = cmd_tx.clone();
            player.connect_play_pause(move |_| {
                let _ = tx.send(MprisCommand::PlayPause);
            });

            let tx = cmd_tx.clone();
            player.connect_play(move |_| {
                let _ = tx.send(MprisCommand::Play);
            });

            let tx = cmd_tx.clone();
            player.connect_pause(move |_| {
                let _ = tx.send(MprisCommand::Pause);
            });

            let tx = cmd_tx.clone();
            player.connect_stop(move |_| {
                let _ = tx.send(MprisCommand::Stop);
            });

            let tx = cmd_tx.clone();
            player.connect_next(move |_| {
                let _ = tx.send(MprisCommand::Next);
            });

            let tx = cmd_tx.clone();
            player.connect_previous(move |_| {
                let _ = tx.send(MprisCommand::Previous);
            });

            // Spawn the player event loop in background (local task)
            tokio::task::spawn_local(player.run());

            // Update loop for state changes
            loop {
                if state_rx.changed().await.is_err() {
                    break;
                }
                let state = state_rx.borrow().clone();
                let status = if state.playing {
                    PlaybackStatus::Playing
                } else if !state.title.is_empty() {
                    PlaybackStatus::Paused
                } else {
                    PlaybackStatus::Stopped
                };

                let mut metadata = Metadata::new();
                if !state.title.is_empty() {
                    metadata.set_title(Some(state.title));
                }
                if !state.artist.is_empty() {
                    metadata.set_artist(Some(vec![state.artist]));
                }
                if !state.album.is_empty() {
                    metadata.set_album(Some(state.album));
                }

                let _ = player.set_playback_status(status).await;
                let _ = player.set_metadata(metadata).await;
                let _ = player.set_volume(state.volume).await;
            }
        });
    });

    MprisHandle { cmd_rx, state_tx }
}
