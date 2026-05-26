// Pillar 2 / REST tour — demo view. 4 buttons, each shows the SDK call and the response.
(function () {
  const mount = document.getElementById("demo-mount");

  window.workshop?.onReady(() => {
    mount.innerHTML = `
      <h3>REST tour</h3>
      <div class="rest-actions">
        <button data-action="list-numbers">List my phone numbers</button>
        <button data-action="send-sms-prompt">Send a test SMS</button>
        <button data-action="recent-calls">Show recent calls</button>
        <button data-action="wire-number-prompt">Point a number at an agent</button>
      </div>
      <div class="rest-output">
        <div class="rest-call">
          <h4>SDK call</h4>
          <pre id="rest-call-pre"><code>—</code></pre>
        </div>
        <div class="rest-response">
          <h4>Response</h4>
          <pre id="rest-response-pre"><code>—</code></pre>
        </div>
      </div>
    `;

    const callPre = document.getElementById("rest-call-pre");
    const respPre = document.getElementById("rest-response-pre");

    function show(call, response) {
      callPre.textContent = call;
      respPre.textContent =
        typeof response === "string" ? response : JSON.stringify(response, null, 2);
    }

    mount.querySelector(".rest-actions").addEventListener("click", async (e) => {
      const btn = e.target.closest("button[data-action]");
      if (!btn) return;
      const action = btn.dataset.action;

      try {
        if (action === "list-numbers") {
          const r = await fetch("/api/list-numbers").then((r) => r.json());
          show(r.sdk_call || "", r.response || r.error);
        } else if (action === "recent-calls") {
          const r = await fetch("/api/recent-calls").then((r) => r.json());
          show(r.sdk_call || "", r.response || r.error);
        } else if (action === "send-sms-prompt") {
          const from = prompt("From (must be a SignalWire number in your account):");
          if (!from) return;
          const to = prompt("To (any number):");
          if (!to) return;
          const r = await fetch("/api/send-sms", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ from, to, body: "Hello from the SignalWire workshop!" }),
          }).then((r) => r.json());
          show(r.sdk_call || "", r.response || r.error);
        } else if (action === "wire-number-prompt") {
          const sid = prompt("Phone number SID (run 'List my phone numbers' to find one):");
          if (!sid) return;
          const voice_url = prompt("Voice URL (e.g., https://your-agent.example.com/agent):");
          if (!voice_url) return;
          const r = await fetch("/api/wire-number", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ sid, voice_url }),
          }).then((r) => r.json());
          show(r.sdk_call || "", r.response || r.error);
        }
      } catch (err) {
        show("", String(err));
      }
    });
  });
})();
