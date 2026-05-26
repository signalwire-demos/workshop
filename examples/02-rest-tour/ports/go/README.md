[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/signalwire-demos/workshop) [![Run on Replit](https://replit.com/badge/github/signalwire-demos/workshop)](https://replit.com/new/github/signalwire-demos/workshop)

# Pillar 2 — REST Tour (Go)

## Run

```bash
go mod tidy
go run .
# Open http://localhost:8001
```

Pure `net/http`. 4 demo endpoints calling `rest.RestClient`. Idiomatic Go method names (PascalCase): `client.PhoneNumbers.List`, `client.Compat.Messages.Create`, `client.Compat.Calls.List`, `client.PhoneNumbers.Update`.
