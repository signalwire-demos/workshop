// Pillar 1 / AI Agent — demo view shown after creds setup.
// Replaces #demo-mount with: number picker, "wire number to agent" button,
// call instructions, and a status line.

(function () {
  const mountPoint = document.getElementById("demo-mount");

  window.workshop?.onReady(({ projectId, space }) => {
    const numbers = window.workshopNumbers || [];

    const publicUrl = window.location.origin;

    mountPoint.innerHTML = `
      <h3>Wire a phone number to your agent</h3>
      <p class="hint">Pick a phone number from your account. Clicking <em>Wire</em>
      will set that number's voice webhook to this server's <code>/agent</code> endpoint.</p>
      <div id="number-list"></div>
      <p>Agent URL: <code>${publicUrl}/agent</code></p>
      <p id="call-prompt" class="hint" hidden></p>
      <p id="wire-error" class="error" hidden></p>
    `;

    const list = document.getElementById("number-list");
    if (!numbers.length) {
      list.innerHTML = `<p class="hint">No phone numbers found. Buy one in
        <a href="https://dashboard.signalwire.com" target="_blank">the SignalWire dashboard</a>,
        then refresh this page.</p>`;
      return;
    }

    numbers.forEach((n) => {
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
