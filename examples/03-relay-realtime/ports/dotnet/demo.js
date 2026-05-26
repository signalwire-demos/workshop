// Pillar 3 / RELAY realtime — demo view. Live event feed + outbound dial button.
(function () {
  const mount = document.getElementById("demo-mount");

  window.workshop?.onReady(() => {
    mount.innerHTML = `
      <h3>RELAY event feed</h3>
      <p class="hint">Now call your SignalWire number, or use the dial button below.
      Events stream in below.</p>

      <div class="relay-controls">
        <button id="dial-btn">Place outbound call…</button>
      </div>

      <div id="event-feed" class="event-feed"></div>
      <p id="relay-error" class="error" hidden></p>
    `;

    const feed = document.getElementById("event-feed");

    // Append event row to the feed.
    function pushEvent(ev) {
      const row = document.createElement("div");
      row.className = "event-row event-" + (ev.kind || "unknown");
      const ts = new Date().toLocaleTimeString();
      row.innerHTML = `<span class="ts">${ts}</span> <code>${JSON.stringify(ev)}</code>`;
      feed.prepend(row);
      // Keep last 50.
      while (feed.children.length > 50) feed.removeChild(feed.lastChild);
    }

    // Connect to backend WS.
    const wsScheme = window.location.protocol === "https:" ? "wss" : "ws";
    const ws = new WebSocket(`${wsScheme}://${window.location.host}/ws/events`);
    ws.onopen = () => pushEvent({ kind: "system", message: "ws connected" });
    ws.onmessage = (e) => {
      try {
        pushEvent(JSON.parse(e.data));
      } catch {
        pushEvent({ kind: "raw", data: e.data });
      }
    };
    ws.onclose = () => pushEvent({ kind: "system", message: "ws closed" });
    ws.onerror = () => pushEvent({ kind: "error", message: "ws error" });

    document.getElementById("dial-btn").addEventListener("click", async () => {
      const from = prompt("From (SignalWire number in your account):");
      if (!from) return;
      const to = prompt("To (any phone number, E.164):");
      if (!to) return;
      try {
        const res = await fetch("/api/dial", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ from, to }),
        });
        const json = await res.json();
        if (!res.ok || !json.ok) throw new Error(json.error || "Dial failed");
        pushEvent({ kind: "dial", call_id: json.call_id, from, to });
      } catch (err) {
        const errEl = document.getElementById("relay-error");
        errEl.textContent = err.message;
        errEl.hidden = false;
      }
    });
  });
})();
