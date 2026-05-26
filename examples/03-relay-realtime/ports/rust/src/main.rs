//! Workshop RELAY realtime — Pillar 3 (Rust).
//!
//! Axum WS + signalwire::relay::client::Client with on_call handler
//! broadcasting events over a tokio::sync::broadcast channel.

use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use serde::Deserialize;
use serde_json::{json, Value};
use signalwire::relay::client::Client as RelayClient;
use signalwire::rest::client::RestClient;
use std::{net::SocketAddr, path::PathBuf, sync::{Arc, Mutex}};
use tokio::sync::{broadcast, OnceCell};
use tower_http::services::ServeDir;

struct AppState {
    creds: Mutex<Option<(String, String, String)>>,
    relay: Mutex<Option<Arc<RelayClient>>>,
    events_tx: broadcast::Sender<Value>,
}

static STATE: OnceCell<Arc<AppState>> = OnceCell::const_new();

fn shared_ui_dir() -> PathBuf {
    let cwd = std::env::current_dir().unwrap();
    cwd.join("..").join("..").join("..").join("..").join("shared").join("ui")
        .canonicalize().unwrap_or_else(|_| cwd.join("../../../../shared/ui"))
}

#[derive(Deserialize)]
struct SetupBody { project_id: String, space: String, token: String }

#[derive(Deserialize)]
struct DialBody { from: String, to: String }

async fn setup(Json(b): Json<SetupBody>) -> impl IntoResponse {
    let (pid, sp, tk) = (b.project_id.trim(), b.space.trim(), b.token.trim());
    if pid.is_empty() || sp.is_empty() || tk.is_empty() {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "All fields required"})));
    }
    if let Err(e) = RestClient::new(pid, tk, sp).phone_numbers().list(json!({"limit": 1})).await {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": format!("Credential check failed: {}", e)})));
    }

    let state = STATE.get().unwrap().clone();
    *state.creds.lock().unwrap() = Some((pid.into(), sp.into(), tk.into()));

    let tx = state.events_tx.clone();
    let rl = Arc::new(RelayClient::new(pid, tk, sp, &["workshop"]));
    let rl_clone = rl.clone();
    let tx_clone = tx.clone();

    rl.on_call(move |call| {
        let _ = tx_clone.send(json!({
            "kind": "call", "state": "incoming", "call_id": call.call_id(),
        }));
        let tx2 = tx_clone.clone();
        let call2 = call.clone();
        tokio::spawn(async move {
            match call2.answer().await {
                Ok(_) => { let _ = tx2.send(json!({"kind": "call", "state": "answered", "call_id": call2.call_id()})); }
                Err(e) => { let _ = tx2.send(json!({"kind": "error", "message": format!("answer failed: {}", e)})); }
            }
        });
    });

    let tx2 = tx.clone();
    tokio::spawn(async move {
        match rl_clone.connect().await {
            Ok(_) => { let _ = tx2.send(json!({"kind": "system", "message": "RELAY connected"})); }
            Err(e) => { let _ = tx2.send(json!({"kind": "error", "message": format!("RELAY connect failed: {}", e)})); }
        }
    });

    *state.relay.lock().unwrap() = Some(rl);
    (StatusCode::OK, Json(json!({"ok": true, "jwt": "session-validated", "subscriber_id": "n/a"})))
}

async fn dial(Json(b): Json<DialBody>) -> impl IntoResponse {
    let state = STATE.get().unwrap().clone();
    let rl = match state.relay.lock().unwrap().clone() {
        Some(r) => r,
        None => return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "Run setup first"}))),
    };
    let from = b.from.trim();
    let to = b.to.trim();
    if from.is_empty() || to.is_empty() {
        return (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": "from + to required"})));
    }
    let devices = vec![vec![json!({
        "type": "phone", "from": from, "to": to, "timeout": 30
    })]];
    match rl.dial(devices).await {
        Ok(call) => (StatusCode::OK, Json(json!({"ok": true, "call_id": call.call_id()}))),
        Err(e) => (StatusCode::BAD_REQUEST, Json(json!({"ok": false, "error": e.to_string()}))),
    }
}

async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_ws)
}

async fn handle_ws(mut socket: WebSocket) {
    let state = STATE.get().unwrap().clone();
    let mut rx = state.events_tx.subscribe();
    let opening = if state.relay.lock().unwrap().is_some() {
        json!({"kind": "system", "message": "ws connected"})
    } else {
        json!({"kind": "error", "message": "Run setup first"})
    };
    if socket.send(Message::Text(opening.to_string())).await.is_err() {
        return;
    }
    loop {
        tokio::select! {
            event = rx.recv() => {
                match event {
                    Ok(e) => if socket.send(Message::Text(e.to_string())).await.is_err() { return; },
                    Err(_) => return,
                }
            }
            msg = socket.recv() => {
                match msg {
                    Some(Ok(_)) => {} // ignore client messages
                    _ => return,
                }
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let (events_tx, _) = broadcast::channel::<Value>(256);
    STATE.set(Arc::new(AppState {
        creds: Mutex::new(None),
        relay: Mutex::new(None),
        events_tx,
    })).ok();

    let shared = shared_ui_dir();
    let shared_for_root = shared.clone();
    let app = Router::new()
        .route("/api/setup", post(setup))
        .route("/api/dial", post(dial))
        .route("/ws/events", get(ws_handler))
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
        .nest_service("/shared", ServeDir::new(&shared));

    let port: u16 = std::env::var("PORT").ok().and_then(|s| s.parse().ok()).unwrap_or(8002);
    let addr: SocketAddr = ([0, 0, 0, 0], port).into();
    println!("RELAY realtime listening on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
