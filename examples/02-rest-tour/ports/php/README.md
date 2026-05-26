[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 2 — REST Tour (PHP)

## Run

```bash
composer install
php -S 0.0.0.0:8001 index.php
# Open http://localhost:8001
```

Single front-controller. Same 4 endpoints, idiomatic PHP arrow-access on `RestClient` namespaces: `$client->phoneNumbers->list(...)`, `$client->compat->messages->create(...)`.
