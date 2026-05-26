// Workshop REST tour — Pillar 2 (Go).
//
// Pure net/http. 4 demo endpoints exercising rest.RestClient.

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/signalwire/signalwire-go/pkg/rest"
)

type creds struct{ ProjectID, Space, Token string }

var (
	mu sync.Mutex
	c  *creds
)

func client() (*rest.RestClient, error) {
	mu.Lock()
	cc := c
	mu.Unlock()
	if cc == nil {
		return nil, fmt.Errorf("run setup first")
	}
	return rest.NewRestClient(cc.ProjectID, cc.Token, cc.Space)
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
		port = "8001"
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
		var body struct {
			ProjectID string `json:"project_id"`
			Space     string `json:"space"`
			Token     string `json:"token"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		pid := strings.TrimSpace(body.ProjectID)
		sp := strings.TrimSpace(body.Space)
		tk := strings.TrimSpace(body.Token)
		if pid == "" || sp == "" || tk == "" {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "All fields required"})
			return
		}
		rc, err := rest.NewRestClient(pid, tk, sp)
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		if _, err := rc.PhoneNumbers.List(map[string]any{"limit": 1}); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": fmt.Sprintf("Credential check failed: %v", err)})
			return
		}
		mu.Lock()
		c = &creds{ProjectID: pid, Space: sp, Token: tk}
		mu.Unlock()
		writeJSON(w, 200, map[string]any{"ok": true, "jwt": "session-validated", "subscriber_id": "n/a"})
	})

	mux.HandleFunc("/api/list-numbers", func(w http.ResponseWriter, r *http.Request) {
		rc, err := client()
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		resp, err := rc.PhoneNumbers.List(map[string]any{"limit": 20})
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, 200, map[string]any{
			"ok":       true,
			"sdk_call": `client.PhoneNumbers.List(map[string]any{"limit": 20})`,
			"response": resp,
		})
	})

	mux.HandleFunc("/api/send-sms", func(w http.ResponseWriter, r *http.Request) {
		rc, err := client()
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		var body struct{ From, To, Body string }
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		from := strings.TrimSpace(body.From)
		to := strings.TrimSpace(body.To)
		text := strings.TrimSpace(body.Body)
		if text == "" {
			text = "Hello from the SignalWire workshop!"
		}
		if from == "" || to == "" {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "from + to required"})
			return
		}
		resp, err := rc.Compat.Messages.Create(map[string]any{"from": from, "to": to, "body": text})
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, 200, map[string]any{
			"ok":       true,
			"sdk_call": fmt.Sprintf(`client.Compat.Messages.Create(...from: %q, to: %q...)`, from, to),
			"response": resp,
		})
	})

	mux.HandleFunc("/api/recent-calls", func(w http.ResponseWriter, r *http.Request) {
		rc, err := client()
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		resp, err := rc.Compat.Calls.List(map[string]any{"page_size": 10})
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, 200, map[string]any{
			"ok":       true,
			"sdk_call": `client.Compat.Calls.List(map[string]any{"page_size": 10})`,
			"response": resp,
		})
	})

	mux.HandleFunc("/api/wire-number", func(w http.ResponseWriter, r *http.Request) {
		rc, err := client()
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		var body struct{ SID, VoiceURL string }
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		sid := strings.TrimSpace(body.SID)
		voiceURL := strings.TrimSpace(body.VoiceURL)
		if sid == "" || voiceURL == "" {
			writeJSON(w, 400, map[string]any{"ok": false, "error": "sid + voice_url required"})
			return
		}
		resp, err := rc.PhoneNumbers.Update(sid, map[string]any{"voice_url": voiceURL, "voice_method": "POST"})
		if err != nil {
			writeJSON(w, 400, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, 200, map[string]any{
			"ok":       true,
			"sdk_call": fmt.Sprintf(`client.PhoneNumbers.Update(%q, voice_url=%q)`, sid, voiceURL),
			"response": resp,
		})
	})

	addr := "0.0.0.0:" + port
	log.Printf("REST tour listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
