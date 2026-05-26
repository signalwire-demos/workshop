//! Workshop REST tour — Pillar 2 (Rust).
//!
//! Axum + signalwire RestClient. 4 demo endpoints calling phone_numbers,
//! compat.messages, compat.calls, phone_numbers update.

use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::{get, post},
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
}

static STATE: OnceCell<AppState> = OnceCell::const_new();

fn shared_ui_dir() -> PathBuf {
    let cwd = std::env::current_dir().unwrap();
    cwd.join("..").join("..").join("..").join("..").join("shared").join("ui").canonicalize()
        .unwrap_or_else(|_| cwd.join("../../../../shared/ui"))
}

fn client() -> Result<RestClient, String> {
    let g = STATE.get().unwrap().creds.lock().unwrap();
    let (p, sp, tk) = g.as_ref().ok_or("Run setup first")?.clone();
    drop(g);
    Ok(RestClient::new(&p, &tk, &sp))
}

#[derive(Deserialize)]
struct SetupBody { project_id: String, space: String, token: String }

#[derive(Deserialize)]
struct SmsBody { from: String, to: String, body: Option<String> }

#[derive(Deserialize)]
struct WireBody { sid: String, voice_url: String }

async fn setup(Json(b): Json<SetupBody>) -> impl IntoResponse {
    let pid = b.project_id.trim();
    let sp = b.space.trim();
    let tk = b.token.trim();
    if pid.is_empty() || sp.is_empty() || tk.is_empty() {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "All fields required"})));
    }
    let c = RestClient::new(pid, tk, sp);
    // Validate by listing numbers (best-effort)
    if let Err(e) = c.phone_numbers().list(json!({"limit": 1})).await {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": format!("Credential check failed: {}", e)})));
    }
    *STATE.get().unwrap().creds.lock().unwrap() = Some((pid.into(), sp.into(), tk.into()));
    (StatusCode::OK, Json(json!({"ok": true, "jwt": "session-validated", "subscriber_id": "n/a"})))
}

async fn list_numbers() -> impl IntoResponse {
    let c = match client() { Ok(c) => c, Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e}))) };
    match c.phone_numbers().list(json!({"limit": 20})).await {
        Ok(r) => (StatusCode::OK, Json(json!({"ok": true, "sdk_call": "client.phone_numbers().list({limit: 20})", "response": r}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

async fn send_sms(Json(b): Json<SmsBody>) -> impl IntoResponse {
    let c = match client() { Ok(c) => c, Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e}))) };
    let body = b.body.unwrap_or_else(|| "Hello from the SignalWire workshop!".into());
    let payload = json!({"from": &b.from, "to": &b.to, "body": &body});
    match c.compat().messages().create(payload).await {
        Ok(r) => (StatusCode::OK, Json(json!({"ok": true, "sdk_call": format!("client.compat().messages().create(from: {}, to: {})", b.from, b.to), "response": r}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

async fn recent_calls() -> impl IntoResponse {
    let c = match client() { Ok(c) => c, Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e}))) };
    match c.compat().calls().list(json!({"page_size": 10})).await {
        Ok(r) => (StatusCode::OK, Json(json!({"ok": true, "sdk_call": "client.compat().calls().list({page_size: 10})", "response": r}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

async fn wire_number(Json(b): Json<WireBody>) -> impl IntoResponse {
    let c = match client() { Ok(c) => c, Err(e) => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e}))) };
    match c.phone_numbers().update(&b.sid, json!({"voice_url": &b.voice_url, "voice_method": "POST"})).await {
        Ok(r) => (StatusCode::OK, Json(json!({"ok": true, "sdk_call": format!("client.phone_numbers().update({}, voice_url: {})", b.sid, b.voice_url), "response": r}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

#[tokio::main]
async fn main() {
    STATE.set(AppState::default()).ok();
    let shared = shared_ui_dir();
    let app = Router::new()
        .route("/api/setup", post(setup))
        .route("/api/list-numbers", get(list_numbers))
        .route("/api/send-sms", post(send_sms))
        .route("/api/recent-calls", get(recent_calls))
        .route("/api/wire-number", post(wire_number))
        .nest_service("/shared", ServeDir::new(&shared))
        .route("/", get(move || {
            let path = shared.join("creds-form.html");
            async move { (
                [(axum::http::header::CONTENT_TYPE, "text/html")],
                std::fs::read_to_string(&path).unwrap_or_default(),
            ) }
        }))
        .route("/demo.js", get(|| async {
            (
                [(axum::http::header::CONTENT_TYPE, "application/javascript")],
                std::fs::read_to_string("demo.js").unwrap_or_default(),
            )
        }));

    let port: u16 = std::env::var("PORT").ok().and_then(|s| s.parse().ok()).unwrap_or(8001);
    let addr: SocketAddr = ([0, 0, 0, 0], port).into();
    println!("REST tour listening on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
