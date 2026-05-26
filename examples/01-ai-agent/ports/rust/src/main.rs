//! Workshop AI Agent app — Pillar 1 (Rust).
//!
//! Axum runs the workshop UI + /api/setup on port 8000. The SignalWire
//! AgentBase runs on an internal port (8081 by default) in a background
//! thread. /agent/* requests are reverse-proxied to the internal port.

mod agent;

use axum::{
    body::Body,
    extract::Path,
    http::{Request, StatusCode, Uri},
    response::{IntoResponse, Json, Response},
    routing::{any, get, post},
    Router,
};
use serde::Deserialize;
use serde_json::{json, Value};
use signalwire::rest::client::RestClient;
use std::{net::SocketAddr, path::PathBuf, sync::Mutex};
use tokio::sync::OnceCell;
use tower_http::services::ServeDir;

#[derive(Default)]
struct AppState {
    creds: Mutex<Option<(String, String, String)>>,
    numbers: Mutex<Vec<Value>>,
}

static STATE: OnceCell<AppState> = OnceCell::const_new();
const AGENT_INTERNAL_PORT: u16 = 8081;

fn shared_ui_dir() -> PathBuf {
    let cwd = std::env::current_dir().unwrap();
    cwd.join("..").join("..").join("..").join("..").join("shared").join("ui")
        .canonicalize()
        .unwrap_or_else(|_| cwd.join("../../../../shared/ui"))
}

#[derive(Deserialize)]
struct SetupBody { project_id: String, space: String, token: String }

#[derive(Deserialize)]
struct WireBody { sid: String, public_url: String }

async fn setup(Json(b): Json<SetupBody>) -> impl IntoResponse {
    let pid = b.project_id.trim();
    let sp = b.space.trim();
    let tk = b.token.trim();
    if pid.is_empty() || sp.is_empty() || tk.is_empty() {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "All fields required"})));
    }
    let c = RestClient::new(pid, tk, sp);
    let numbers = match c.phone_numbers().list(json!({"limit": 20})).await {
        Ok(v) => v,
        Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": format!("Credential check failed: {}", e)}))),
    };
    let list: Vec<Value> = numbers.as_array().cloned().unwrap_or_default();
    let s = STATE.get().unwrap();
    *s.creds.lock().unwrap() = Some((pid.into(), sp.into(), tk.into()));
    *s.numbers.lock().unwrap() = list.clone();
    (StatusCode::OK, Json(json!({
        "ok": true, "jwt": "", "subscriber_id": "",
        "numbers": list, "agent_path": "/agent",
    })))
}

async fn wire_number(Json(b): Json<WireBody>) -> impl IntoResponse {
    let creds = STATE.get().unwrap().creds.lock().unwrap().clone();
    let (p, sp, tk) = match creds {
        Some(c) => c,
        None => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "Run setup first"}))),
    };
    let sid = b.sid.trim();
    let public = b.public_url.trim_end_matches('/');
    if sid.is_empty() || public.is_empty() {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "sid + public_url required"})));
    }
    let voice_url = format!("{}/agent", public);
    let c = RestClient::new(&p, &tk, &sp);
    match c.phone_numbers().update(sid, json!({"voice_url": &voice_url, "voice_method": "POST"})).await {
        Ok(_) => (StatusCode::OK, Json(json!({"ok": true, "voice_url": voice_url}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

async fn proxy_to_agent(req: Request<Body>) -> Response {
    // Reverse-proxy /agent/* → http://127.0.0.1:8081/agent/*
    let mut uri = Uri::builder()
        .scheme("http")
        .authority(format!("127.0.0.1:{}", AGENT_INTERNAL_PORT));
    let path = req.uri().path_and_query().map(|p| p.as_str().to_string()).unwrap_or_else(|| "/agent".into());
    let uri = uri.path_and_query(path).build().unwrap();
    let (parts, body) = req.into_parts();
    let bytes = match axum::body::to_bytes(body, usize::MAX).await {
        Ok(b) => b,
        Err(_) => return (StatusCode::BAD_REQUEST, "bad body").into_response(),
    };
    let client = reqwest::Client::new();
    let mut builder = client.request(parts.method, uri.to_string());
    for (k, v) in parts.headers.iter() {
        if k != "host" { builder = builder.header(k, v); }
    }
    let res = match builder.body(bytes.to_vec()).send().await {
        Ok(r) => r,
        Err(e) => return (StatusCode::BAD_GATEWAY, format!("agent unreachable: {}", e)).into_response(),
    };
    let status = res.status();
    let headers = res.headers().clone();
    let body = res.bytes().await.unwrap_or_default();
    let mut response = Response::new(Body::from(body));
    *response.status_mut() = StatusCode::from_u16(status.as_u16()).unwrap_or(StatusCode::OK);
    for (k, v) in headers.iter() {
        response.headers_mut().insert(k.clone(), v.clone());
    }
    response
}

#[tokio::main]
async fn main() {
    STATE.set(AppState::default()).ok();

    // Spawn the signalwire AgentBase on an internal port in a thread.
    // AgentBase::run() blocks; we host it sub-port and reverse-proxy.
    std::thread::spawn(|| {
        let mut a = agent::build_agent();
        // The signalwire crate's agent listens on its own port — config
        // via constructor or env. If your installed version takes a host
        // + port via a builder method, adjust here. The pattern below is
        // the most-common shape; double-check against your SDK release.
        std::env::set_var("SWML_PORT", AGENT_INTERNAL_PORT.to_string());
        a.run();
    });

    let shared = shared_ui_dir();
    let shared_for_root = shared.clone();
    let app = Router::new()
        .route("/api/setup", post(setup))
        .route("/api/wire-number", post(wire_number))
        .route("/", get(move || {
            let p = shared_for_root.join("creds-form.html");
            async move { (
                [(axum::http::header::CONTENT_TYPE, "text/html")],
                std::fs::read_to_string(&p).unwrap_or_default(),
            ) }
        }))
        .route("/demo.js", get(|| async {
            (
                [(axum::http::header::CONTENT_TYPE, "application/javascript")],
                std::fs::read_to_string("demo.js").unwrap_or_default(),
            )
        }))
        .nest_service("/shared", ServeDir::new(&shared))
        // /agent → reverse-proxy to internal AgentBase port
        .route("/agent", any(proxy_to_agent))
        .route("/agent/*rest", any(proxy_to_agent));

    let port: u16 = std::env::var("PORT").ok().and_then(|s| s.parse().ok()).unwrap_or(8000);
    let addr: SocketAddr = ([0, 0, 0, 0], port).into();
    println!("AI Agent listening on http://{} (agent internal: 127.0.0.1:{})", addr, AGENT_INTERNAL_PORT);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
