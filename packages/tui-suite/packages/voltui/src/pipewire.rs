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
/// Uses short format since `PipeWire` JSON doesn't include module index
pub fn get_combined_modules() -> AppResult<Vec<(u32, String)>> {
    let output = Command::new("pactl")
        .args(["list", "modules", "short"])
        .output()?;

    let text = String::from_utf8_lossy(&output.stdout);
    let modules: Vec<(u32, String)> = text
        .lines()
        .filter_map(|line| {
            // Format: index\tmodule-name\targuments
            let mut parts = line.split('\t');
            let index: u32 = parts.next()?.parse().ok()?;
            let name = parts.next()?;
            if name != "module-combine-sink" {
                return None;
            }
            let args = parts.next().unwrap_or("");
            let sink_name = extract_sink_name(args);
            Some((index, sink_name))
        })
        .collect();

    Ok(modules)
}

/// Extract `sink_name` from module arguments string
fn extract_sink_name(args: &str) -> String {
    // Try to find sink_name= in various formats
    for part in args.split(|c: char| c.is_whitespace() || c == '\t') {
        if let Some(name) = part.strip_prefix("sink_name=") {
            // Remove any quotes
            return name.trim_matches('"').trim_matches('\'').to_string();
        }
    }
    // Fallback: try regex-like search for sink_name=value pattern
    if let Some(start) = args.find("sink_name=") {
        let rest = &args[start + 10..];
        let end = rest
            .find(|c: char| c.is_whitespace() || c == '\t')
            .unwrap_or(rest.len());
        let name = &rest[..end];
        return name.trim_matches('"').trim_matches('\'').to_string();
    }
    "combined".to_string()
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
