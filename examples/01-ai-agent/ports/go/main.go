// Workshop AI Agent app — Pillar 1 (Go).
//
// Serves: /, /shared/*, /demo.js, /api/setup, /api/wire-number, /agent/*

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

type creds struct {
	ProjectID string
	Space     string
	Token     string
}

type numberInfo struct {
	SID         string `json:"sid"`
	PhoneNumber string `json:"phone_number"`
}

type state struct {
	mu      sync.Mutex
	creds   *creds
	numbers []numberInfo
}

var STATE = &state{}

func sharedUIDir() string {
	wd, _ := os.Getwd()
	return filepath.Join(wd, "..", "..", "..", "..", "shared", "ui")
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8000"
	}

	workshopAgent := newWorkshopAgent()

	mux := http.NewServeMux()

	sharedDir := sharedUIDir()
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
		http.ServeFile(w, r, filepath.Join("demo.js"))
	})

	// Agent at /agent/*
	mux.Handle("/agent/", http.StripPrefix("/agent", workshopAgent.AsRouter()))
	mux.Handle("/agent", http.StripPrefix("/agent", workshopAgent.AsRouter()))

	mux.HandleFunc("/api/setup", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "error": "POST only"})
			return
		}
		var body struct {
			ProjectID string `json:"project_id"`
			Space     string `json:"space"`
			Token     string `json:"token"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		projectID := strings.TrimSpace(body.ProjectID)
		space := strings.TrimSpace(body.Space)
		token := strings.TrimSpace(body.Token)
		if projectID == "" || space == "" || token == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": "All fields required"})
			return
		}
		client, err := rest.NewRestClient(projectID, token, space)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": fmt.Sprintf("Client init failed: %v", err)})
			return
		}
		numbersResp, err := client.PhoneNumbers.List(map[string]any{"limit": 20})
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": fmt.Sprintf("Credential check failed: %v", err)})
			return
		}
		numbers := []numberInfo{}
		if arr, ok := numbersResp.([]any); ok {
			for _, n := range arr {
				if m, ok := n.(map[string]any); ok {
					sid, _ := m["sid"].(string)
					pn, _ := m["phone_number"].(string)
					numbers = append(numbers, numberInfo{SID: sid, PhoneNumber: pn})
				}
			}
		}

		STATE.mu.Lock()
		STATE.creds = &creds{ProjectID: projectID, Space: space, Token: token}
		STATE.numbers = numbers
		STATE.mu.Unlock()

		writeJSON(w, http.StatusOK, map[string]any{
			"ok":            true,
			"jwt":           "",
			"subscriber_id": "",
			"numbers":       numbers,
			"agent_path":    "/agent",
		})
	})

	mux.HandleFunc("/api/wire-number", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]any{"ok": false, "error": "POST only"})
			return
		}
		STATE.mu.Lock()
		c := STATE.creds
		STATE.mu.Unlock()
		if c == nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": "Run /api/setup first"})
			return
		}
		var body struct {
			SID       string `json:"sid"`
			PublicURL string `json:"public_url"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": "invalid json"})
			return
		}
		sid := strings.TrimSpace(body.SID)
		publicURL := strings.TrimSpace(body.PublicURL)
		if sid == "" || publicURL == "" {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": "sid + public_url required"})
			return
		}
		client, _ := rest.NewRestClient(c.ProjectID, c.Token, c.Space)
		voiceURL := strings.TrimRight(publicURL, "/") + "/agent"
		_, err := client.PhoneNumbers.Update(sid, map[string]any{"voice_url": voiceURL, "voice_method": "POST"})
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]any{"ok": false, "error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "voice_url": voiceURL})
	})

	addr := "0.0.0.0:" + port
	log.Printf("AI Agent listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
