#!/usr/bin/env bash
# Pre-workshop smoke test. Boots each Python example against the porting-sdk
# mock servers and verifies /api/setup returns a JWT + subscriber_id.
#
# Run from repo root: bash scripts/smoke.sh
#
# NOTE: This is a Phase 5 placeholder. Real implementation will:
#   - Spin up mock_signalwire and mock_relay from porting-sdk
#   - Start each example app.py on a dedicated port
#   - POST canned creds to /api/setup
#   - Assert response shape (ok=true, jwt non-empty, subscriber_id non-empty)
#   - Tear down everything

set -euo pipefail

echo "[smoke] placeholder — implementation pending Phase 5"
echo "[smoke] examples to verify:"
for ex in examples/01-ai-agent examples/02-rest-tour examples/03-relay-realtime; do
  for impl in $ex/python $ex/typescript; do
    if [ -f "$impl/app.py" ] || [ -f "$impl/app.ts" ] || [ -f "$impl/index.ts" ]; then
      echo "  - $impl (ready)"
    else
      echo "  - $impl (not yet built)"
    fi
  done
done
