// Shared setup flow. POSTs creds to /api/setup, stores JWT, fires "workshop:ready" event.
(function () {
  const form = document.getElementById("creds-form");
  const btn = document.getElementById("submit-btn");
  const errEl = document.getElementById("error");
  const credsCard = document.getElementById("creds");
  const readyCard = document.getElementById("ready");
  const subEl = document.getElementById("subscriber-id");
  const jwtEl = document.getElementById("jwt-snippet");

  // Each example sets this in its own page to display the pillar name in the header.
  const pillarName = document.querySelector("meta[name='workshop-pillar']")?.content || "Workshop";
  document.querySelector("[data-pillar-name]").textContent = pillarName;

  window.workshop = {
    jwt: null,
    subscriberId: null,
    onReady(callback) {
      if (this.jwt) {
        callback(this);
      } else {
        document.addEventListener("workshop:ready", () => callback(this), { once: true });
      }
    },
  };

  form?.addEventListener("submit", async (e) => {
    e.preventDefault();
    errEl.hidden = true;
    btn.disabled = true;
    btn.textContent = "Setting up…";

    const data = new FormData(form);
    const body = {
      project_id: data.get("project_id"),
      space: data.get("space"),
      token: data.get("token"),
    };

    try {
      const res = await fetch("/api/setup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const json = await res.json();
      if (!res.ok || !json.ok) {
        throw new Error(json.error || "Setup failed");
      }
      window.workshop.jwt = json.jwt;
      window.workshop.subscriberId = json.subscriber_id;
      window.workshop.projectId = body.project_id;
      window.workshop.space = body.space;
      window.workshop.numbers = json.numbers || [];
      window.workshop.agentBasicAuth = json.agent_basic_auth || null;

      sessionStorage.setItem("workshop_jwt", json.jwt);
      sessionStorage.setItem("workshop_subscriber_id", json.subscriber_id);

      subEl.textContent = json.subscriber_id;
      jwtEl.textContent = json.jwt.slice(0, 32) + "…";

      credsCard.hidden = true;
      readyCard.hidden = false;

      document.dispatchEvent(new CustomEvent("workshop:ready"));
    } catch (err) {
      errEl.textContent = err.message;
      errEl.hidden = false;
      btn.disabled = false;
      btn.textContent = "Set up and launch";
    }
  });
})();
