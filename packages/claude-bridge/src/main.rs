use axum::{
    Router,
    extract::Query,
    http::{Method, StatusCode, header},
    response::Json,
    routing::get,
};
use base64::Engine;
use serde::{Deserialize, Serialize};
use std::{
    env,
    net::{IpAddr, SocketAddr},
    path::PathBuf,
    process::Stdio,
    time::Duration,
};
use tokio::{
    io::{AsyncBufReadExt, AsyncWriteExt, BufReader},
    net::TcpStream,
    process::Command,
};
use tower_http::cors::CorsLayer;
use url::Url;

const VERSION: &str = env!("CARGO_PKG_VERSION");
const DEFAULT_PORT: u16 = 8787;
const MARIONETTE_PORT: u16 = 2828;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(30);
const SCREENSHOT_TIMEOUT: Duration = Duration::from_secs(60);
const SCREENSHOT_WAIT_MS: &str = "1000";
const CLAUDE_TIMEOUT: Duration = Duration::from_secs(120);
const MAX_RESPONSE_SIZE: usize = 10 * 1024 * 1024;

#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("Missing parameter: {0}")]
    MissingParam(&'static str),
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
    #[error("Blocked URL: {0}")]
    BlockedUrl(String),
    #[error("Unknown action: {0}")]
    UnknownAction(String),
    #[error("Failed to fetch content: {0}")]
    FetchError(String),
    #[error("Command failed: {0}")]
    CommandError(String),
}

impl axum::response::IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status, message) = match &self {
            AppError::MissingParam(_) | AppError::InvalidUrl(_) | AppError::UnknownAction(_) => {
                (StatusCode::BAD_REQUEST, self.to_string())
            }
            AppError::BlockedUrl(_) => (StatusCode::FORBIDDEN, self.to_string()),
            AppError::FetchError(_) | AppError::CommandError(_) => {
                (StatusCode::INTERNAL_SERVER_ERROR, self.to_string())
            }
        };
        (status, Json(ErrorResponse { error: message })).into_response()
    }
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

#[derive(Serialize)]
struct SuccessResponse {
    result: String,
}

#[derive(Deserialize)]
struct BridgeParams {
    action: Option<String>,
    url: Option<String>,
    prompt: Option<String>,
    #[serde(default)]
    screenshot: bool,
}

fn is_private_ip(ip: &IpAddr) -> bool {
    match ip {
        IpAddr::V4(v4) => {
            v4.is_loopback()
                || v4.is_private()
                || v4.is_link_local()
                || v4.is_broadcast()
                || v4.is_unspecified()
        }
        IpAddr::V6(v6) => {
            v6.is_loopback()
                || v6.is_unspecified()
                || (v6.segments()[0] & 0xffc0) == 0xfe80
                || (v6.segments()[0] & 0xfe00) == 0xfc00
        }
    }
}

fn validate_url(url_str: &str) -> Result<Url, AppError> {
    let url = Url::parse(url_str).map_err(|e| AppError::InvalidUrl(e.to_string()))?;

    if !matches!(url.scheme(), "http" | "https") {
        return Err(AppError::InvalidUrl(format!(
            "Only http/https allowed, got: {}",
            url.scheme()
        )));
    }

    if let Some(host) = url.host_str() {
        let blocked = ["localhost", "metadata.google.internal"];
        if blocked.contains(&host) {
            return Err(AppError::BlockedUrl(format!("Host not allowed: {}", host)));
        }

        if let Ok(ip) = host
            .trim_matches(|c| c == '[' || c == ']')
            .parse::<IpAddr>()
        {
            if is_private_ip(&ip) {
                return Err(AppError::BlockedUrl(format!(
                    "Private/internal IP not allowed: {}",
                    ip
                )));
            }
        }
    }

    Ok(url)
}

fn stdout_to_string(output: &std::process::Output) -> String {
    String::from_utf8_lossy(&output.stdout).to_string()
}

fn is_youtube_url(url: &Url) -> bool {
    url.host_str()
        .map(|h| h.contains("youtube.com") || h.contains("youtu.be"))
        .unwrap_or(false)
}

async fn fetch_webpage(url: &Url) -> Result<String, AppError> {
    let client = reqwest::Client::builder()
        .timeout(REQUEST_TIMEOUT)
        .redirect(reqwest::redirect::Policy::limited(5))
        .build()
        .map_err(|e| AppError::FetchError(e.to_string()))?;

    let response = client
        .get(url.as_str())
        .header("User-Agent", format!("claude-bridge/{}", VERSION))
        .send()
        .await
        .map_err(|e| AppError::FetchError(e.to_string()))?;

    if response
        .content_length()
        .is_some_and(|len| len as usize > MAX_RESPONSE_SIZE)
    {
        return Err(AppError::FetchError("Response too large".to_string()));
    }

    let bytes = response
        .bytes()
        .await
        .map_err(|e| AppError::FetchError(e.to_string()))?;

    if bytes.len() > MAX_RESPONSE_SIZE {
        return Err(AppError::FetchError("Response too large".to_string()));
    }

    let html = String::from_utf8_lossy(&bytes).to_string();

    // Convert HTML to text using html2text
    let mut child = Command::new("html2text")
        .arg("-utf8")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| AppError::CommandError(e.to_string()))?;

    if let Some(mut stdin) = child.stdin.take() {
        use tokio::io::AsyncWriteExt;
        stdin
            .write_all(html.as_bytes())
            .await
            .map_err(|e| AppError::CommandError(e.to_string()))?;
    }

    let output = child
        .wait_with_output()
        .await
        .map_err(|e| AppError::CommandError(e.to_string()))?;

    Ok(stdout_to_string(&output))
}

async fn fetch_youtube_transcript(url: &Url) -> Result<String, AppError> {
    let output = Command::new("yt-subs")
        .arg(url.as_str())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .await
        .map_err(|e| AppError::CommandError(e.to_string()))?;

    if !output.status.success() {
        return Err(AppError::FetchError(
            "Failed to fetch YouTube transcript".to_string(),
        ));
    }

    Ok(stdout_to_string(&output))
}

/// Read a Marionette message: "len:json"
async fn marionette_read(
    reader: &mut BufReader<tokio::net::tcp::OwnedReadHalf>,
) -> Result<serde_json::Value, AppError> {
    let mut len_str = String::new();
    loop {
        let mut buf = [0u8; 1];
        tokio::io::AsyncReadExt::read_exact(reader, &mut buf)
            .await
            .map_err(|e| AppError::CommandError(format!("Marionette read error: {}", e)))?;
        if buf[0] == b':' {
            break;
        }
        len_str.push(buf[0] as char);
    }
    let len: usize = len_str
        .parse()
        .map_err(|_| AppError::CommandError("Invalid Marionette length".to_string()))?;

    let mut json_buf = vec![0u8; len];
    tokio::io::AsyncReadExt::read_exact(reader, &mut json_buf)
        .await
        .map_err(|e| AppError::CommandError(format!("Marionette read error: {}", e)))?;

    serde_json::from_slice(&json_buf)
        .map_err(|e| AppError::CommandError(format!("Marionette JSON error: {}", e)))
}

/// Write a Marionette message
async fn marionette_write(
    writer: &mut tokio::net::tcp::OwnedWriteHalf,
    msg: &serde_json::Value,
) -> Result<(), AppError> {
    let json = serde_json::to_string(msg).unwrap();
    let packet = format!("{}:{}", json.len(), json);
    writer
        .write_all(packet.as_bytes())
        .await
        .map_err(|e| AppError::CommandError(format!("Marionette write error: {}", e)))
}

/// Take screenshot using Firefox Marionette (uses your browser session)
async fn marionette_screenshot(url: &Url) -> Result<PathBuf, AppError> {
    let port: u16 = env::var("MARIONETTE_PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(MARIONETTE_PORT);

    let stream = TcpStream::connect(format!("127.0.0.1:{}", port))
        .await
        .map_err(|e| AppError::CommandError(format!("Cannot connect to Marionette: {}", e)))?;

    let (read_half, mut write_half) = stream.into_split();
    let mut reader = BufReader::new(read_half);

    // Read server hello
    let _hello = marionette_read(&mut reader).await?;
    eprintln!("[claude-bridge] Connected to Firefox Marionette");

    // Create new tab
    let msg = serde_json::json!([0, 1, "WebDriver:NewWindow", {"type": "tab"}]);
    marionette_write(&mut write_half, &msg).await?;
    let resp = marionette_read(&mut reader).await?;
    let handle = resp
        .get(3)
        .and_then(|r| r.get("handle"))
        .and_then(|h| h.as_str())
        .ok_or_else(|| AppError::CommandError("Failed to create tab".to_string()))?
        .to_string();

    // Switch to new tab
    let msg = serde_json::json!([0, 2, "WebDriver:SwitchToWindow", {"handle": handle}]);
    marionette_write(&mut write_half, &msg).await?;
    let _ = marionette_read(&mut reader).await?;

    // Navigate to URL
    let msg = serde_json::json!([0, 3, "WebDriver:Navigate", {"url": url.as_str()}]);
    marionette_write(&mut write_half, &msg).await?;
    let _ = marionette_read(&mut reader).await?;

    // Wait for page load
    tokio::time::sleep(Duration::from_millis(1500)).await;

    // Take screenshot
    let msg = serde_json::json!([0, 4, "WebDriver:TakeScreenshot", {"full": true}]);
    marionette_write(&mut write_half, &msg).await?;
    let resp = marionette_read(&mut reader).await?;

    let b64 = resp
        .get(3)
        .and_then(|r| r.get("value"))
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::CommandError("No screenshot data".to_string()))?;

    // Close the tab
    let msg = serde_json::json!([0, 5, "WebDriver:CloseWindow", {}]);
    marionette_write(&mut write_half, &msg).await?;
    let _ = marionette_read(&mut reader).await?;

    // Decode and save
    let png_data = base64::engine::general_purpose::STANDARD
        .decode(b64)
        .map_err(|e| AppError::CommandError(format!("Base64 decode error: {}", e)))?;

    let temp_dir = env::temp_dir();
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let screenshot_path = temp_dir.join(format!(
        "claude-bridge-{}-{}.png",
        timestamp,
        std::process::id()
    ));

    std::fs::write(&screenshot_path, png_data)
        .map_err(|e| AppError::CommandError(format!("Failed to save screenshot: {}", e)))?;

    eprintln!("[claude-bridge] Screenshot saved via Marionette");
    Ok(screenshot_path)
}

/// Fallback: take screenshot using shot-scraper (anonymous session)
async fn capture_screenshot(url: &Url) -> Result<PathBuf, AppError> {
    let temp_dir = env::temp_dir();
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let screenshot_path = temp_dir.join(format!(
        "claude-bridge-{}-{}.png",
        timestamp,
        std::process::id()
    ));

    let mut cmd = Command::new("shot-scraper");
    cmd.arg(url.as_str())
        .arg("-o")
        .arg(&screenshot_path)
        .arg("--wait")
        .arg(SCREENSHOT_WAIT_MS);

    // Add cookies file if configured
    if let Ok(cookies_path) = env::var("CLAUDE_BRIDGE_COOKIES") {
        if std::path::Path::new(&cookies_path).exists() {
            cmd.arg("--cookies").arg(&cookies_path);
            eprintln!("[claude-bridge] Using cookies from {}", cookies_path);
        }
    }

    // Add auth file if configured
    if let Ok(auth_path) = env::var("CLAUDE_BRIDGE_AUTH") {
        if std::path::Path::new(&auth_path).exists() {
            cmd.arg("--auth").arg(&auth_path);
            eprintln!("[claude-bridge] Using auth from {}", auth_path);
        }
    }

    let output = tokio::time::timeout(
        SCREENSHOT_TIMEOUT,
        cmd.stdout(Stdio::piped()).stderr(Stdio::piped()).output(),
    )
    .await
    .map_err(|_| AppError::CommandError("Screenshot timed out".to_string()))?
    .map_err(|e| AppError::CommandError(format!("Screenshot failed: {}", e)))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(AppError::CommandError(format!(
            "shot-scraper failed: {}",
            stderr
        )));
    }

    Ok(screenshot_path)
}

async fn process_with_claude(
    content: &str,
    prompt: &str,
    screenshot_path: Option<&PathBuf>,
) -> Result<String, AppError> {
    let claude_cmd = env::var("CLAUDE_CMD").unwrap_or_else(|_| "claude".to_string());

    let mut cmd = Command::new(&claude_cmd);
    cmd.arg("--print").arg(prompt);

    // Add screenshot if provided
    if let Some(path) = screenshot_path {
        cmd.arg(path);
    }

    let mut child = cmd
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| AppError::CommandError(format!("Failed to spawn claude: {}", e)))?;

    if let Some(mut stdin) = child.stdin.take() {
        use tokio::io::AsyncWriteExt;
        stdin
            .write_all(content.as_bytes())
            .await
            .map_err(|e| AppError::CommandError(e.to_string()))?;
    }

    let output = tokio::time::timeout(CLAUDE_TIMEOUT, child.wait_with_output())
        .await
        .map_err(|_| AppError::CommandError("Claude command timed out".to_string()))?
        .map_err(|e| AppError::CommandError(e.to_string()))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(AppError::CommandError(format!("Claude failed: {}", stderr)));
    }

    Ok(stdout_to_string(&output))
}

async fn handle_bridge(
    Query(params): Query<BridgeParams>,
) -> Result<Json<SuccessResponse>, AppError> {
    let action = params.action.ok_or(AppError::MissingParam("action"))?;
    let url_str = params.url.ok_or(AppError::MissingParam("url"))?;

    let url = validate_url(&url_str)?;
    let is_youtube = is_youtube_url(&url);
    let want_screenshot = params.screenshot && !is_youtube;

    eprintln!(
        "[claude-bridge] action={} url={} screenshot={}",
        action, url, want_screenshot
    );

    // Fetch content
    let content = if is_youtube {
        fetch_youtube_transcript(&url).await?
    } else {
        fetch_webpage(&url).await?
    };

    if content.trim().is_empty() {
        return Err(AppError::FetchError(
            "Could not extract content from URL".to_string(),
        ));
    }

    // Optionally capture screenshot (not for YouTube)
    // Try Marionette first (uses your Firefox session), fall back to shot-scraper
    let screenshot_path = if want_screenshot {
        match marionette_screenshot(&url).await {
            Ok(path) => Some(path),
            Err(e) => {
                eprintln!(
                    "[claude-bridge] Marionette failed ({}), trying shot-scraper...",
                    e
                );
                match capture_screenshot(&url).await {
                    Ok(path) => Some(path),
                    Err(e) => {
                        eprintln!(
                            "[claude-bridge] Screenshot failed, continuing without: {}",
                            e
                        );
                        None
                    }
                }
            }
        }
    } else {
        None
    };

    // Build prompt with context
    let source_context = if is_youtube {
        "The following is a transcript from a YouTube video."
    } else if screenshot_path.is_some() {
        "The following is text extracted from a webpage. A screenshot of the page is also provided for visual context."
    } else {
        "The following is text extracted from a webpage."
    };

    let prompt = match params.prompt {
        Some(custom) => custom,
        None => match action.as_str() {
            "summarize" => format!("{} Summarize it concisely.", source_context),
            "tldr" => format!("{} Give a one-sentence TLDR.", source_context),
            "todo" => format!("{} Extract actionable todo items from it.", source_context),
            "explain" => format!("{} Explain the key points.", source_context),
            "critique" => format!(
                "{} Provide critical analysis: identify biases, flaws, or missing perspectives.",
                source_context
            ),
            _ => {
                return Err(AppError::UnknownAction(format!(
                    "{}. Available: summarize, tldr, todo, explain, critique",
                    action
                )));
            }
        },
    };

    let result = process_with_claude(&content, &prompt, screenshot_path.as_ref()).await;

    // Clean up screenshot file
    if let Some(path) = screenshot_path {
        let _ = std::fs::remove_file(path);
    }

    Ok(Json(SuccessResponse { result: result? }))
}

async fn health() -> &'static str {
    "ok"
}

#[tokio::main]
async fn main() {
    let port: u16 = env::var("CLAUDE_BRIDGE_PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(DEFAULT_PORT);

    let cors = CorsLayer::new()
        .allow_origin(tower_http::cors::Any)
        .allow_methods([Method::GET])
        .allow_headers([header::CONTENT_TYPE]);

    let app = Router::new()
        .route("/", get(handle_bridge))
        .route("/health", get(health))
        .layer(cors);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    eprintln!("[claude-bridge] Starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
