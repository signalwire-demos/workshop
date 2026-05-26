[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 1 — AI Agent (PHP)

## Run

```bash
composer install
php -S 0.0.0.0:8000 index.php
# Open http://localhost:8000
```

Single front-controller (`index.php`) routes everything. PHP's built-in dev server is sufficient for the workshop.

Caveat: PHP's request-per-process model means `/agent` handling needs the agent's `handleRequest()` entry point. If that's not available in your `signalwire/sdk` version, you may need to reverse-proxy `/agent` to a dedicated agent server process.
