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

fn sudo_cmd(program: &str) -> Command {
    if needs_sudo() {
        let mut cmd = Command::new(SUDO);
        cmd.args(["--non-interactive", program]);
        cmd
    } else {
        Command::new(program)
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
    // Trigger scan
    let _ = sudo_cmd("wpa_cli").args(["-i", interface, "scan"]).output();

    // Get results
    let output = sudo_cmd("wpa_cli")
        .args(["-i", interface, "scan_results"])
        .output()?;

    if output.status.success() {
        Ok(parse_wpa_cli_output(
            &String::from_utf8_lossy(&output.stdout),
            interface,
        ))
    } else {
        Ok(vec![])
    }
}

pub fn wifi_scan_available() -> bool {
    Command::new("which")
        .arg("wpa_cli")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn parse_wpa_cli_output(output: &str, interface: &str) -> Vec<WifiNetwork> {
    // Get current connected network
    let status_output = sudo_cmd("wpa_cli")
        .args(["-i", interface, "status"])
        .output()
        .ok();

    let connected_ssid = status_output.and_then(|out| {
        let s = String::from_utf8_lossy(&out.stdout);
        s.lines()
            .find(|l| l.starts_with("ssid="))
            .map(|l| l.trim_start_matches("ssid=").to_string())
    });

    let networks: Vec<WifiNetwork> = output
        .lines()
        .skip(1) // Skip header
        .filter_map(|line| {
            let parts: Vec<&str> = line.split('\t').collect();
            if parts.len() < 5 {
                return None;
            }

            let ssid = (*parts.get(4)?).to_string();
            if ssid.is_empty() {
                return None;
            }

            // Convert signal level (dBm) to percentage
            let signal_dbm: i32 = parts.get(2)?.parse().unwrap_or(-80);
            // Result is always 0-100, fits in u8
            let signal_raw = (signal_dbm + 100).clamp(0, 60) * 100 / 60;
            let signal = u8::try_from(signal_raw).unwrap_or(0);

            let flags = parts.get(3)?;
            let secured = flags.contains("WPA") || flags.contains("WEP");

            Some(WifiNetwork {
                ssid: ssid.clone(),
                signal,
                secured,
                connected: connected_ssid.as_ref() == Some(&ssid),
            })
        })
        .collect();

    networks
}

pub fn connect_wifi(interface: &str, ssid: &str, _password: Option<&str>) -> AppResult<String> {
    // List configured networks and find the one matching SSID
    let list_output = sudo_cmd("wpa_cli")
        .args(["-i", interface, "list_networks"])
        .output()?;

    let output_str = String::from_utf8_lossy(&list_output.stdout);
    for line in output_str.lines().skip(1) {
        let parts: Vec<&str> = line.split('\t').collect();
        if parts.len() >= 2 && parts[1] == ssid {
            let network_id = parts[0];
            let select_output = sudo_cmd("wpa_cli")
                .args(["-i", interface, "select_network", network_id])
                .output()?;

            if select_output.status.success() {
                return Ok(format!("Connecting to {ssid}"));
            }
        }
    }

    Ok(format!("'{ssid}' not configured"))
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
