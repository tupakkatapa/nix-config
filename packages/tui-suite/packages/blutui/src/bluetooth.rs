use std::io::Write;
use std::process::{Child, Command, Stdio};
use std::sync::Mutex;

use tuigreat::AppResult;

#[derive(Clone)]
pub struct Device {
    pub address: String,
    pub name: String,
    pub connected: bool,
    pub icon: String,
}

pub fn get_controller_info() -> AppResult<(bool, String)> {
    let output = Command::new("bluetoothctl").args(["show"]).output()?;

    let out = String::from_utf8_lossy(&output.stdout);

    let powered = out
        .lines()
        .find(|l| l.contains("Powered:"))
        .is_some_and(|l| l.contains("yes"));

    let name = out
        .lines()
        .find(|l| l.contains("Name:"))
        .and_then(|l| l.split(':').nth(1))
        .map_or_else(|| "Unknown".to_string(), |s| s.trim().to_string());

    Ok((powered, name))
}

pub fn set_power(on: bool) -> AppResult<()> {
    let state = if on { "on" } else { "off" };
    Command::new("bluetoothctl")
        .args(["power", state])
        .output()?;
    Ok(())
}

pub fn get_paired_devices() -> AppResult<Vec<Device>> {
    // Use "devices Paired"
    let output = Command::new("bluetoothctl")
        .args(["devices", "Paired"])
        .output()?;

    let out = String::from_utf8_lossy(&output.stdout);

    // For paired devices, we do want the full info (connected status, icon)
    let mut devices = Vec::new();
    for line in out.lines() {
        let parts: Vec<&str> = line.splitn(3, ' ').collect();
        if parts.len() >= 3 && parts[0] == "Device" {
            let address = parts[1].to_string();
            let name = parts[2].to_string();

            // Get device info only for paired devices
            let info = get_device_info(&address).unwrap_or((true, false, "device".to_string()));

            devices.push(Device {
                address,
                name,
                connected: info.1,
                icon: info.2,
            });
        }
    }

    Ok(devices)
}

pub fn get_available_devices() -> AppResult<Vec<Device>> {
    // First get paired device addresses to filter them out
    let paired_output = Command::new("bluetoothctl")
        .args(["devices", "Paired"])
        .output()?;
    let paired_out = String::from_utf8_lossy(&paired_output.stdout);
    let paired_addrs: std::collections::HashSet<String> = paired_out
        .lines()
        .filter_map(|line| {
            let parts: Vec<&str> = line.splitn(3, ' ').collect();
            if parts.len() >= 2 && parts[0] == "Device" {
                Some(parts[1].to_string())
            } else {
                None
            }
        })
        .collect();

    // Get devices from bluetoothctl (this includes discovered devices)
    let output = Command::new("bluetoothctl").args(["devices"]).output()?;
    let out = String::from_utf8_lossy(&output.stdout);

    let mut seen_addrs = std::collections::HashSet::new();
    let mut devices: Vec<Device> = out
        .lines()
        .filter_map(|line| {
            let parts: Vec<&str> = line.splitn(3, ' ').collect();
            if parts.len() >= 3 && parts[0] == "Device" {
                let address = parts[1].to_string();
                // Skip paired devices
                if paired_addrs.contains(&address) {
                    return None;
                }
                seen_addrs.insert(address.clone());
                let name = parts[2].to_string();
                Some(Device {
                    address,
                    name,
                    connected: false,
                    icon: "device".to_string(),
                })
            } else {
                None
            }
        })
        .collect();

    // Also try D-Bus to catch any devices bluetoothctl might have missed
    let dbus_devices = get_devices_from_dbus(&paired_addrs);
    for dev in dbus_devices {
        if !seen_addrs.contains(&dev.address) {
            devices.push(dev);
        }
    }

    Ok(devices)
}

fn get_devices_from_dbus(paired_addrs: &std::collections::HashSet<String>) -> Vec<Device> {
    // Use busctl to list all device objects under org.bluez
    let output = Command::new("busctl").args(["tree", "org.bluez"]).output();

    let Ok(out) = output else {
        return Vec::new();
    };

    if !out.status.success() {
        return Vec::new();
    }

    let tree_out = String::from_utf8_lossy(&out.stdout);
    let mut devices = Vec::new();

    for line in tree_out.lines() {
        // busctl tree output has lines like "├─/org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX"
        // or "│ └─/org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX"
        // We need to extract the path which starts with /
        let path = if let Some(idx) = line.find("/org/bluez") {
            &line[idx..]
        } else {
            continue;
        };

        // Device paths look like /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF
        if path.contains("/dev_") {
            // Extract MAC address from path
            if let Some(dev_part) = path.split('/').next_back()
                && let Some(addr_part) = dev_part.strip_prefix("dev_")
            {
                let address = addr_part.replace('_', ":");

                // Skip paired devices
                if paired_addrs.contains(&address) {
                    continue;
                }

                // Get device name using busctl
                let name = get_device_name_dbus(path).unwrap_or_else(|| address.clone());

                devices.push(Device {
                    address,
                    name,
                    connected: false,
                    icon: "device".to_string(),
                });
            }
        }
    }

    devices
}

fn get_device_name_dbus(device_path: &str) -> Option<String> {
    let output = Command::new("busctl")
        .args([
            "get-property",
            "org.bluez",
            device_path,
            "org.bluez.Device1",
            "Alias",
        ])
        .output()
        .ok()?;

    let out = String::from_utf8_lossy(&output.stdout);
    // Output format: s "Device Name"
    out.split('"')
        .nth(1)
        .map(ToString::to_string)
        .filter(|s| !s.is_empty())
}

fn get_device_info(address: &str) -> AppResult<(bool, bool, String)> {
    let output = Command::new("bluetoothctl")
        .args(["info", address])
        .output()?;

    let out = String::from_utf8_lossy(&output.stdout);

    let paired = out
        .lines()
        .find(|l| l.contains("Paired:"))
        .is_some_and(|l| l.contains("yes"));

    let connected = out
        .lines()
        .find(|l| l.contains("Connected:"))
        .is_some_and(|l| l.contains("yes"));

    let icon = out
        .lines()
        .find(|l| l.contains("Icon:"))
        .and_then(|l| l.split(':').nth(1))
        .map_or_else(|| "device".to_string(), |s| s.trim().to_string());

    Ok((paired, connected, icon))
}

static SCAN_PROCESS: Mutex<Option<Child>> = Mutex::new(None);

pub fn scan(start: bool) {
    if start {
        // Spawn interactive bluetoothctl that registers agent and keeps scanning
        // This process stays alive to maintain the D-Bus connection
        let child = Command::new("bluetoothctl")
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn();

        if let Ok(mut child) = child {
            if let Some(ref mut stdin) = child.stdin {
                let _ = writeln!(stdin, "agent on");
                let _ = writeln!(stdin, "default-agent");
                let _ = writeln!(stdin, "scan on");
            }
            if let Ok(mut guard) = SCAN_PROCESS.lock() {
                *guard = Some(child);
            }
        }
    } else {
        // Stop scanning and kill background process
        let _ = Command::new("bluetoothctl").args(["scan", "off"]).output();

        if let Ok(mut guard) = SCAN_PROCESS.lock()
            && let Some(mut child) = guard.take()
        {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

// Restart discovery to keep it active (bluez stops after timeout)
pub fn restart_discovery() {
    let needs_restart = if let Ok(mut guard) = SCAN_PROCESS.lock() {
        if let Some(ref mut child) = *guard
            && let Some(ref mut stdin) = child.stdin
        {
            let _ = writeln!(stdin, "scan on");
            false
        } else {
            true
        }
    } else {
        true
    };

    if needs_restart {
        scan(false);
        scan(true);
    }
}

pub fn connect_device(address: &str) -> AppResult<()> {
    Command::new("bluetoothctl")
        .args(["connect", address])
        .output()?;
    Ok(())
}

pub fn disconnect_device(address: &str) -> AppResult<()> {
    Command::new("bluetoothctl")
        .args(["disconnect", address])
        .output()?;
    Ok(())
}

static PAIR_PROCESS: Mutex<Option<Child>> = Mutex::new(None);

/// Start pairing process - returns immediately
/// Check `get_pending_passkey()` to see if confirmation is needed
pub fn start_pairing(address: &str) -> AppResult<()> {
    // Kill any existing pairing process
    if let Ok(mut guard) = PAIR_PROCESS.lock()
        && let Some(mut child) = guard.take()
    {
        let _ = child.kill();
        let _ = child.wait();
    }

    // Start interactive bluetoothctl for pairing with agent
    let child = Command::new("bluetoothctl")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    if let Ok(mut guard) = PAIR_PROCESS.lock() {
        *guard = Some(child);
    }

    // Send commands to set up agent and pair
    if let Ok(mut guard) = PAIR_PROCESS.lock()
        && let Some(ref mut child) = *guard
        && let Some(ref mut stdin) = child.stdin
    {
        let _ = writeln!(stdin, "agent on");
        let _ = writeln!(stdin, "default-agent");
        let _ = writeln!(stdin, "pair {address}");
    }

    Ok(())
}

/// Check if there's a pending passkey to confirm
/// Returns the passkey if found
pub fn get_pending_passkey() -> Option<String> {
    use std::io::Read;

    if let Ok(mut guard) = PAIR_PROCESS.lock()
        && let Some(ref mut child) = *guard
        && let Some(ref mut stdout) = child.stdout
    {
        let mut buffer = [0u8; 4096];
        // Set non-blocking read
        #[cfg(unix)]
        {
            use std::os::unix::io::AsRawFd;
            let fd = stdout.as_raw_fd();
            unsafe {
                let flags = libc::fcntl(fd, libc::F_GETFL);
                if flags != -1 {
                    libc::fcntl(fd, libc::F_SETFL, flags | libc::O_NONBLOCK);
                }
            }
        }

        if let Ok(n) = stdout.read(&mut buffer)
            && n > 0
        {
            let output = String::from_utf8_lossy(&buffer[..n]);
            // Look for passkey confirmation request
            for line in output.lines() {
                if line.contains("Confirm passkey")
                    || line.contains("confirm passkey")
                    || line.contains("Passkey:")
                {
                    // Extract 6-digit passkey
                    if let Some(pin) = line
                        .split_whitespace()
                        .find(|s| s.chars().all(|c| c.is_ascii_digit()) && s.len() == 6)
                    {
                        return Some(pin.to_string());
                    }
                }
            }
        }
    }
    None
}

/// Confirm or reject the pending passkey
pub fn confirm_passkey(accept: bool) {
    if let Ok(mut guard) = PAIR_PROCESS.lock()
        && let Some(ref mut child) = *guard
        && let Some(ref mut stdin) = child.stdin
    {
        if accept {
            let _ = writeln!(stdin, "yes");
        } else {
            let _ = writeln!(stdin, "no");
        }
    }

    // Give it a moment then clean up
    std::thread::sleep(std::time::Duration::from_millis(500));

    if let Ok(mut guard) = PAIR_PROCESS.lock()
        && let Some(mut child) = guard.take()
    {
        let _ = child.kill();
        let _ = child.wait();
    }
}

pub fn remove_device(address: &str) -> AppResult<()> {
    Command::new("bluetoothctl")
        .args(["remove", address])
        .output()?;
    Ok(())
}
