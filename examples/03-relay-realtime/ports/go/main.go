// Workshop RELAY realtime — Pillar 3 (Go).
//
// Opens a SignalWire RELAY connection in the background, forwards events
// over a gorilla/websocket browser WS, exposes outbound /api/dial.

package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/signalwire/signalwire-go/pkg/relay"
	"github.com/signalwire/signalwire-go/pkg/rest"
)

type creds struct{ ProjectID, Space, Token string }

var (
	mu          sync.Mutex
	c           *creds
	relayClient *relay.Client
	subs        = make(map[*websocket.Conn]struct{})
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func broadcast(event map[string]any) {
	mu.Lock()
	defer mu.Unlock()
	for ws := range subs {
		if err := ws.WriteJSON(event); err != nil {
			ws.Close()
			delete(subs, ws)
		}
	}
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func sharedUIDir() string {
	wd, _ := os.Getwd()
	return filepath.Join(wd, "..", "..", "..", "..", "shared", "ui")
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8002"
	}
	sharedDir := sharedUIDir()

	mux := http.NewServeMux()
	mux.Handle("/shared/", http.StripPrefix("/shared/", http.FileServer(http.Dir(sharedDir))))

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		http.ServeFile(w, r, filepath.Join(sharedDir, "creds-form.html"))
	})

	mux.HandleFunc("/demo.js", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/javascript")
		http.ServeFile(w, r, "demo.js")
	})

	mux.HandleFunc("/api/setup", func(w http.ResponseWriter, r *http.Request) {
		var body struct{ ProjectID, Space, Token string }
		// JSON field names from frontend are snake_case; rebind via tags below.
		var raw struct {
			ProjectID string `json:"project_id"`
			Space     string `json:"space"`
			Token     string `json:"token"`
		}
		if err := json.NewDecoder(r.Body).Decode(&raw); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		body.ProjectID = strings.TrimSpace(raw.ProjectID)
		body.Space = strings.TrimSpace(raw.Space)
		body.Token = strings.TrimSpace(raw.Token)
		if body.ProjectID == "" || body.Space == "" || body.Token == "" {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "All fields required"})
			return
		}
		rc, err := rest.NewRestClient(body.ProjectID, body.Token, body.Space)
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		if _, err := rc.PhoneNumbers.List(map[string]any{"limit": 1}); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "Credential check failed: " + err.Error()})
			return
		}

		// Tear down any prior relay client
		mu.Lock()
		if relayClient != nil {
			relayClient.Disconnect()
			relayClient = nil
		}
		mu.Unlock()

		rl := relay.NewRelayClient(
			relay.WithProject(body.ProjectID),
			relay.WithToken(body.Token),
			relay.WithSpace(body.Space),
			relay.WithContexts("workshop"),
		)
		rl.OnCall(func(call *relay.Call) {
			broadcast(map[string]any{
				"kind":    "call",
				"state":   "incoming",
				"call_id": call.CallID,
			})
			if err := call.Answer(); err != nil {
				broadcast(map[string]any{"kind": "error", "message": "answer failed: " + err.Error()})
				return
			}
			broadcast(map[string]any{"kind": "call", "state": "answered", "call_id": call.CallID})
		})

		go func() {
			if err := rl.Connect(); err != nil {
				broadcast(map[string]any{"kind": "error", "message": "RELAY connect failed: " + err.Error()})
				return
			}
			broadcast(map[string]any{"kind": "system", "message": "RELAY connected"})
		}()

		mu.Lock()
		c = &creds{ProjectID: body.ProjectID, Space: body.Space, Token: body.Token}
		relayClient = rl
		mu.Unlock()

		writeJSON(w, 200, map[string]any{"ok": true, "jwt": "session-validated", "subscriber_id": "n/a"})
	})

	mux.HandleFunc("/api/dial", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		rl := relayClient
		mu.Unlock()
		if rl == nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "Run setup first"})
			return
		}
		var body struct{ From, To string }
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		from := strings.TrimSpace(body.From)
		to := strings.TrimSpace(body.To)
		if from == "" || to == "" {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "from + to required"})
			return
		}
		devices := [][]map[string]any{{{"type": "phone", "from": from, "to": to, "timeout": 30}}}
		call, err := rl.Dial(devices)
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, 200, map[string]any{"ok": true, "call_id": call.CallID})
	})

	mux.HandleFunc("/ws/events", func(w http.ResponseWriter, r *http.Request) {
		ws, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		mu.Lock()
		subs[ws] = struct{}{}
		hasClient := relayClient != nil
		mu.Unlock()
		if hasClient {
			_ = ws.WriteJSON(map[string]any{"kind": "system", "message": "ws connected"})
		} else {
			_ = ws.WriteJSON(map[string]any{"kind": "error", "message": "Run setup first"})
		}
		// Keep the connection open; reads drain control frames + detect close.
		for {
			if _, _, err := ws.NextReader(); err != nil {
				break
			}
		}
		mu.Lock()
		delete(subs, ws)
		mu.Unlock()
		ws.Close()
	})

	addr := "0.0.0.0:" + port
	log.Printf("RELAY realtime listening on %s", addr)
	_ = context.TODO()
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
