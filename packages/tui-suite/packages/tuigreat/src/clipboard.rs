use std::io::Write;
use std::process::{Command, Stdio};

/// Copy text to system clipboard
/// Tries wl-copy (Wayland) first, then xclip (X11)
#[must_use]
pub fn yank(text: &str) -> bool {
    if text.is_empty() {
        return false;
    }

    // Try wl-copy first (Wayland)
    let result = Command::new("wl-copy")
        .arg(text)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .and_then(|mut c| c.wait());

    if result.as_ref().is_ok_and(std::process::ExitStatus::success) {
        return true;
    }

    // Try xclip (X11)
    if let Ok(mut child) = Command::new("xclip")
        .args(["-selection", "clipboard"])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        && let Some(stdin) = child.stdin.as_mut()
        && stdin.write_all(text.as_bytes()).is_ok()
    {
        return child.wait().is_ok_and(|s| s.success());
    }

    false
}

/// Paste text from system clipboard
/// Tries wl-paste (Wayland) first, then xclip (X11)
#[must_use]
pub fn paste() -> Option<String> {
    // Try wl-paste first (Wayland)
    if let Ok(out) = Command::new("wl-paste")
        .arg("--no-newline")
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        && out.status.success()
    {
        let text = String::from_utf8_lossy(&out.stdout).to_string();
        if !text.is_empty() {
            return Some(text);
        }
    }

    // Try xclip (X11)
    if let Ok(out) = Command::new("xclip")
        .args(["-selection", "clipboard", "-o"])
        .stdin(Stdio::null())
        .stderr(Stdio::null())
        .output()
        && out.status.success()
    {
        let text = String::from_utf8_lossy(&out.stdout).to_string();
        if !text.is_empty() {
            return Some(text);
        }
    }

    None
}
