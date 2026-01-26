use std::io::Write;
use std::process::{Command, Stdio};
use std::sync::OnceLock;

use tuigreat::AppResult;

static USE_SUDO: OnceLock<bool> = OnceLock::new();

// NixOS requires the wrapped sudo with setuid bit
const SUDO: &str = "/run/wrappers/bin/sudo";

pub fn needs_sudo() -> bool {
    *USE_SUDO.get_or_init(|| unsafe { libc::geteuid() != 0 })
}

/// Check if we have cached sudo credentials (no password needed)
pub fn has_sudo_cached() -> bool {
    if !needs_sudo() {
        return true;
    }
    Command::new(SUDO)
        .args(["--non-interactive", "true"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

/// Run a command with sudo, using provided password if needed
pub fn run_with_sudo(program: &str, args: &[&str], password: Option<&str>) -> AppResult<String> {
    if !needs_sudo() {
        let output = Command::new(program).args(args).output()?;
        return Ok(String::from_utf8_lossy(&output.stdout).to_string());
    }

    // Try non-interactive first (cached credentials)
    let try_cached = Command::new(SUDO)
        .args(["--non-interactive", program])
        .args(args)
        .output()?;

    if try_cached.status.success() {
        return Ok(String::from_utf8_lossy(&try_cached.stdout).to_string());
    }

    // Need password
    let Some(pass) = password else {
        return Err("Sudo password required".into());
    };

    let mut child = Command::new(SUDO)
        .args(["-S", program])
        .args(args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    if let Some(mut stdin) = child.stdin.take() {
        writeln!(stdin, "{pass}")?;
    }

    let output = child.wait_with_output()?;
    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if stderr.contains("incorrect password") || stderr.contains("Sorry") {
            Err("Incorrect password".into())
        } else {
            Err(stderr.trim().to_string().into())
        }
    }
}

#[derive(Clone)]
pub struct Interface {
    pub name: String,
    pub itype: String,
    pub oper_state: String,
    pub address: Option<String>,
}

#[derive(Clone)]
pub struct WifiNetwork {
    pub ssid: String,
    pub signal: u8,
    pub secured: bool,
    pub connected: bool,
}

pub fn get_interfaces() -> AppResult<Vec<Interface>> {
    let output = Command::new("networkctl")
        .args(["--json=short", "list"])
        .output()?;

    let json: serde_json::Value =
        serde_json::from_slice(&output.stdout).unwrap_or(serde_json::json!({"Interfaces": []}));

    let interfaces = json["Interfaces"]
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|iface| {
                    let name = iface["Name"].as_str()?.to_string();

                    // Skip loopback
                    if name == "lo" {
                        return None;
                    }

                    let itype = iface["Type"].as_str().unwrap_or("unknown").to_string();
                    let oper_state = iface["OperationalState"]
                        .as_str()
                        .unwrap_or("off")
                        .to_string();

                    // Get IPv4 address from Addresses array
                    let address = iface["Addresses"].as_array().and_then(|addrs| {
                        addrs.iter().find_map(|a| {
                            let bytes = a["Address"].as_array()?;
                            if bytes.len() == 4 {
                                let ip: Vec<String> = bytes
                                    .iter()
                                    .filter_map(|b| b.as_u64().map(|n| n.to_string()))
                                    .collect();
                                if ip.len() == 4 {
                                    return Some(ip.join("."));
                                }
                            }
                            None
                        })
                    });

                    Some(Interface {
                        name,
                        itype,
                        oper_state,
                        address,
                    })
                })
                .collect()
        })
        .unwrap_or_default();

    Ok(interfaces)
}

pub fn scan_wifi(interface: &str) -> AppResult<Vec<WifiNetwork>> {
    // Trigger scan (iwd doesn't require sudo)
    let _ = Command::new("iwctl")
        .args(["station", interface, "scan"])
        .output();

    // Small delay to let scan complete
    std::thread::sleep(std::time::Duration::from_millis(500));

    // Get results
    let output = Command::new("iwctl")
        .args(["station", interface, "get-networks"])
        .output()?;

    if output.status.success() {
        let connected = get_connected_network(interface);
        Ok(parse_iwctl_networks(
            &String::from_utf8_lossy(&output.stdout),
            connected.as_deref(),
        ))
    } else {
        Ok(vec![])
    }
}

pub fn wifi_scan_available() -> bool {
    Command::new("which")
        .arg("iwctl")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

/// Get currently connected network from iwctl station show
fn get_connected_network(interface: &str) -> Option<String> {
    let output = Command::new("iwctl")
        .args(["station", interface, "show"])
        .output()
        .ok()?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("Connected network") {
            // Format: "Connected network   SSID"
            let parts: Vec<&str> = trimmed.splitn(2, "Connected network").collect();
            if parts.len() == 2 {
                return Some(parts[1].trim().to_string());
            }
        }
    }
    None
}

/// Parse iwctl get-networks output
/// Format:
/// ```
///                                Available networks                             *
/// --------------------------------------------------------------------------------
///       Network name                      Security            Signal
/// --------------------------------------------------------------------------------
///       hyperion-2g                       psk                 ****
///   >   OP9                               psk                 ***
/// ```
fn parse_iwctl_networks(output: &str, connected: Option<&str>) -> Vec<WifiNetwork> {
    let mut networks = Vec::new();
    let mut in_data = false;
    let mut header_count = 0;

    for line in output.lines() {
        // Skip until we've passed both header separator lines
        if line.contains("----") {
            header_count += 1;
            if header_count >= 2 {
                in_data = true;
            }
            continue;
        }

        if !in_data {
            continue;
        }

        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }

        // Check if connected (starts with >)
        let is_connected_indicator = line.trim_start().starts_with('>');
        let line_clean = if is_connected_indicator {
            line.trim_start().trim_start_matches('>').trim_start()
        } else {
            trimmed
        };

        // Parse the line - it's space-separated with variable spacing
        // We need to extract: SSID, Security, Signal
        // Signal is at the end (asterisks like ****)
        // Security is before signal (psk, open, etc.)

        // Find signal strength (asterisks at end)
        let signal_chars: String = line_clean
            .chars()
            .rev()
            .take_while(|c| *c == '*' || c.is_whitespace())
            .collect::<String>()
            .chars()
            .rev()
            .collect();
        let signal_count = signal_chars.chars().filter(|c| *c == '*').count();
        #[allow(
            clippy::cast_possible_truncation,
            clippy::cast_sign_loss,
            clippy::cast_precision_loss
        )]
        let signal = ((signal_count as f32 / 4.0) * 100.0) as u8;

        // Remove signal from end
        let without_signal = line_clean.trim_end_matches(|c: char| c == '*' || c.is_whitespace());

        // Security is the last word before signal
        let parts: Vec<&str> = without_signal.split_whitespace().collect();
        if parts.len() < 2 {
            continue;
        }

        let security = parts.last().unwrap_or(&"");
        let secured = *security != "open";

        // SSID is everything before security
        let ssid = parts[..parts.len() - 1].join(" ");

        if ssid.is_empty() || ssid == "Network name" {
            continue;
        }

        let is_connected = connected.is_some_and(|c| c == ssid) || is_connected_indicator;

        networks.push(WifiNetwork {
            ssid,
            signal,
            secured,
            connected: is_connected,
        });
    }

    networks
}

pub fn connect_wifi(interface: &str, ssid: &str, password: Option<&str>) -> AppResult<String> {
    // For iwd, connection is simple:
    // - If network is known (saved), just connect
    // - If new network with password, use --passphrase

    let output = if let Some(psk) = password {
        if psk.is_empty() {
            return Ok(format!("'{ssid}' requires a password"));
        }
        // Connect with passphrase (iwd will save it)
        Command::new("iwctl")
            .args(["--passphrase", psk, "station", interface, "connect", ssid])
            .output()?
    } else {
        // Try connecting (works for open networks or saved networks)
        Command::new("iwctl")
            .args(["station", interface, "connect", ssid])
            .output()?
    };

    if output.status.success() {
        Ok(format!("Connecting to {ssid}"))
    } else {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if stderr.contains("passphrase") || stderr.contains("Passphrase") {
            Ok(format!("'{ssid}' requires a password"))
        } else if stderr.is_empty() {
            Ok(format!("Connecting to {ssid}"))
        } else {
            Ok(format!("Failed: {}", stderr.trim()))
        }
    }
}

pub fn toggle_interface(
    interface: &str,
    bring_up: bool,
    password: Option<&str>,
) -> AppResult<String> {
    let action = if bring_up { "up" } else { "down" };

    match run_with_sudo("networkctl", &[action, interface], password) {
        Ok(_) => Ok(format!("{interface} {action}")),
        Err(e) => {
            let msg = e.to_string();
            if msg == "Sudo password required" {
                Err(e)
            } else {
                Ok(msg)
            }
        }
    }
}
