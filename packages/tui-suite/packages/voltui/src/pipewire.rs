use std::process::Command;

use tuigreat::AppResult;

#[derive(Clone)]
pub struct Sink {
    pub name: String,
    pub description: String,
    pub volume: u8,
    pub muted: bool,
    pub is_default: bool,
}

#[derive(Clone)]
pub struct Source {
    pub name: String,
    pub description: String,
    pub volume: u8,
    pub muted: bool,
    pub is_default: bool,
}

pub fn get_default_sink() -> AppResult<String> {
    let output = Command::new("pactl").args(["get-default-sink"]).output()?;
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

pub fn get_default_source() -> AppResult<String> {
    let output = Command::new("pactl")
        .args(["get-default-source"])
        .output()?;
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

pub fn set_default_sink(name: &str) -> Result<(), String> {
    let output = Command::new("pactl")
        .args(["set-default-sink", name])
        .output()
        .map_err(|e| e.to_string())?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if stderr.is_empty() {
            return Err(format!("Failed to set default sink: {name}"));
        }
        return Err(stderr.trim().to_string());
    }
    Ok(())
}

pub fn set_default_source(name: &str) -> Result<(), String> {
    let output = Command::new("pactl")
        .args(["set-default-source", name])
        .output()
        .map_err(|e| e.to_string())?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if stderr.is_empty() {
            return Err(format!("Failed to set default source: {name}"));
        }
        return Err(stderr.trim().to_string());
    }
    Ok(())
}

/// Create a combined sink from multiple sinks
pub fn create_combined_sink(name: &str, sink_names: &[&str]) -> Result<(), String> {
    if sink_names.is_empty() {
        return Err("No sinks selected".to_string());
    }

    // Build slaves parameter
    let slaves = sink_names.join(",");

    let output = Command::new("pactl")
        .args([
            "load-module",
            "module-combine-sink",
            &format!("sink_name={name}"),
            &format!("slaves={slaves}"),
        ])
        .output()
        .map_err(|e| e.to_string())?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(stderr.trim().to_string());
    }
    Ok(())
}

/// Get existing combined sinks
pub fn get_combined_modules() -> AppResult<Vec<(u32, String)>> {
    let output = Command::new("pactl")
        .args(["--format=json", "list", "modules"])
        .output()?;

    let json: serde_json::Value =
        serde_json::from_slice(&output.stdout).unwrap_or(serde_json::json!([]));

    let modules = json
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|module| {
                    let name = module["name"].as_str()?;
                    if name != "module-combine-sink" {
                        return None;
                    }
                    // PipeWire module indexes are small positive integers
                    let index = u32::try_from(module["index"].as_u64()?).ok()?;
                    let args = module["argument"].as_str().unwrap_or("");
                    // Extract sink_name from arguments
                    let sink_name = args
                        .split_whitespace()
                        .find(|s| s.starts_with("sink_name="))
                        .and_then(|s| s.strip_prefix("sink_name="))
                        .unwrap_or("combined")
                        .to_string();
                    Some((index, sink_name))
                })
                .collect()
        })
        .unwrap_or_default();

    Ok(modules)
}

/// Remove a combined sink by module index
pub fn remove_combined_sink(module_index: u32) -> Result<(), String> {
    let output = Command::new("pactl")
        .args(["unload-module", &module_index.to_string()])
        .output()
        .map_err(|e| e.to_string())?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(stderr.trim().to_string());
    }
    Ok(())
}

pub fn get_sinks() -> AppResult<Vec<Sink>> {
    let default = get_default_sink()?;
    let output = Command::new("pactl")
        .args(["--format=json", "list", "sinks"])
        .output()?;

    let json: serde_json::Value =
        serde_json::from_slice(&output.stdout).unwrap_or(serde_json::json!([]));

    let sinks = json
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|sink| {
                    let name = sink["name"].as_str()?.to_string();
                    let description = sink["description"].as_str().unwrap_or(&name).to_string();
                    let muted = sink["mute"].as_bool().unwrap_or(false);

                    // Parse volume from the volume object
                    let volume = sink["volume"]
                        .as_object()
                        .and_then(|v| v.values().next())
                        .and_then(|ch| ch["value_percent"].as_str())
                        .and_then(|s| s.trim_end_matches('%').parse().ok())
                        .unwrap_or(0);

                    Some(Sink {
                        is_default: name == default,
                        name,
                        description,
                        volume,
                        muted,
                    })
                })
                .collect()
        })
        .unwrap_or_default();

    Ok(sinks)
}

pub fn get_sources() -> AppResult<Vec<Source>> {
    let default = get_default_source()?;
    let output = Command::new("pactl")
        .args(["--format=json", "list", "sources"])
        .output()?;

    let json: serde_json::Value =
        serde_json::from_slice(&output.stdout).unwrap_or(serde_json::json!([]));

    let sources = json
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|source| {
                    let name = source["name"].as_str()?.to_string();

                    // Skip monitor sources
                    if name.contains(".monitor") {
                        return None;
                    }

                    let description = source["description"].as_str().unwrap_or(&name).to_string();
                    let muted = source["mute"].as_bool().unwrap_or(false);

                    let volume = source["volume"]
                        .as_object()
                        .and_then(|v| v.values().next())
                        .and_then(|ch| ch["value_percent"].as_str())
                        .and_then(|s| s.trim_end_matches('%').parse().ok())
                        .unwrap_or(0);

                    Some(Source {
                        is_default: name == default,
                        name,
                        description,
                        volume,
                        muted,
                    })
                })
                .collect()
        })
        .unwrap_or_default();

    Ok(sources)
}
