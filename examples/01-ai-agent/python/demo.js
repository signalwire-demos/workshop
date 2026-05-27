// Pillar 1 / AI Agent — demo view shown after creds setup.
// Shows the agent's webhook URL (with embedded basic-auth credentials),
// the auth user/password separately for the SignalWire dashboard form,
// and a number picker that auto-wires a chosen number.

(function () {
  const mountPoint = document.getElementById("demo-mount");

  window.workshop?.onReady(({ numbers, agentBasicAuth }) => {
    const publicUrl = window.location.origin;
    const auth = agentBasicAuth || { user: "workshop", password: "workshop-demo" };

    // Two URL flavors: plain (display) + credentialed (paste-into-dashboard).
    const plainAgentUrl = `${publicUrl}/agent`;
    const credentialedAgentUrl = (() => {
      try {
        const u = new URL(plainAgentUrl);
        u.username = encodeURIComponent(auth.user);
        u.password = encodeURIComponent(auth.password);
        return u.toString();
      } catch {
        return plainAgentUrl;
      }
    })();

    mountPoint.innerHTML = `
      <h3>Wire a phone number to your agent</h3>
      <p class="hint">Either click <em>Wire</em> next to a number below (auto-wires
      via the API), or manually paste the URL + auth fields into the SignalWire
      dashboard's voice settings.</p>

      <h4>Agent webhook URL (with basic auth embedded)</h4>
      <pre id="agent-url-pre"><code>${credentialedAgentUrl}</code></pre>
      <button class="copy-btn" data-copy="agent-url-pre">Copy</button>

      <h4>Or paste these into the dashboard's separate fields</h4>
      <dl class="kv">
        <dt>Voice URL</dt><dd><code>${plainAgentUrl}</code></dd>
        <dt>HTTP Basic Auth User</dt><dd><code>${auth.user}</code></dd>
        <dt>HTTP Basic Auth Password</dt><dd><code>${auth.password}</code></dd>
      </dl>

      <h4>Or auto-wire a number from your account</h4>
      <div id="number-list"></div>
      <p id="call-prompt" class="hint" hidden></p>
      <p id="wire-error" class="error" hidden></p>
    `;

    // Copy button
    document.querySelectorAll(".copy-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        const target = document.getElementById(btn.dataset.copy);
        navigator.clipboard.writeText(target.textContent).then(() => {
          const original = btn.textContent;
          btn.textContent = "Copied ✓";
          setTimeout(() => { btn.textContent = original; }, 1500);
        });
      });
    });

    const list = document.getElementById("number-list");
    const nums = numbers || [];
    if (!nums.length) {
      list.innerHTML = `<p class="hint">No phone numbers found in your account.
        Buy one in <a href="https://dashboard.signalwire.com" target="_blank">the
        SignalWire dashboard</a> and refresh, or use the manual paste above.</p>`;
      return;
    }

    nums.forEach((n) => {
      const row = document.createElement("div");
      row.className = "number-row";
      row.innerHTML = `
        <span>${n.phone_number}</span>
        <button class="wire-btn" data-sid="${n.sid}">Wire to agent</button>
      `;
      list.appendChild(row);
    });

    list.addEventListener("click", async (e) => {
      const btn = e.target.closest(".wire-btn");
      if (!btn) return;
      const sid = btn.dataset.sid;
      btn.disabled = true;
      btn.textContent = "Wiring…";
      document.getElementById("wire-error").hidden = true;

      try {
        const res = await fetch("/api/wire-number", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ sid, public_url: publicUrl }),
        });
        const json = await res.json();
        if (!res.ok || !json.ok) throw new Error(json.error || "Failed");

        btn.textContent = "Wired ✓";
        const prompt = document.getElementById("call-prompt");
        const numberText = btn.previousElementSibling.textContent;
        prompt.textContent = `Now call ${numberText} — your agent will answer.`;
        prompt.hidden = false;
      } catch (err) {
        const errEl = document.getElementById("wire-error");
        errEl.textContent = err.message;
        errEl.hidden = false;
        btn.disabled = false;
        btn.textContent = "Wire to agent";
      }
    });
  });
})();
