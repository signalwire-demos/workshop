#!/usr/bin/env bash
# Pre-workshop smoke test. Validates each example's source compiles / parses.
#
# This is a SOURCE-LEVEL smoke. It does NOT boot the apps or hit SignalWire's
# servers — that requires real credentials and is out of scope for CI. The
# day-of "fresh user" dry-run (see LAB.md) is the live validation.
#
# Run from repo root: bash scripts/smoke.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
SKIP=0

check_python() {
    local dir="$1"
    if [ ! -d "$dir" ]; then SKIP=$((SKIP+1)); echo "  [SKIP] $dir (not built)"; return; fi
    if python3 -m py_compile "$dir"/*.py 2>/dev/null; then
        PASS=$((PASS+1)); echo "  [PASS] $dir (python syntax)"
    else
        FAIL=$((FAIL+1)); echo "  [FAIL] $dir (python syntax)"
    fi
}

check_typescript() {
    local dir="$1"
    if [ ! -d "$dir" ]; then SKIP=$((SKIP+1)); echo "  [SKIP] $dir (not built)"; return; fi
    if ! command -v node >/dev/null 2>&1; then
        SKIP=$((SKIP+1)); echo "  [SKIP] $dir (node not installed)"; return
    fi
    # Quick parse via node --check on each .ts after stripping types? Not
    # practical without tsc. Instead, syntax-check the package.json + verify
    # required files exist.
    local missing=()
    for f in package.json tsconfig.json app.ts demo.js; do
        [ -f "$dir/$f" ] || missing+=("$f")
    done
    if [ ${#missing[@]} -eq 0 ]; then
        PASS=$((PASS+1)); echo "  [PASS] $dir (files present)"
    else
        FAIL=$((FAIL+1)); echo "  [FAIL] $dir (missing: ${missing[*]})"
    fi
}

echo "=== Workshop source smoke test ==="
echo ""

echo "Pillar 1 — AI Agent"
check_python  "examples/01-ai-agent/python"
check_typescript "examples/01-ai-agent/typescript"

echo ""
echo "Pillar 2 — REST Tour"
check_python  "examples/02-rest-tour/python"
check_typescript "examples/02-rest-tour/typescript"

echo ""
echo "Pillar 3 — RELAY Realtime"
check_python  "examples/03-relay-realtime/python"
check_typescript "examples/03-relay-realtime/typescript"

echo ""
echo "Shared UI"
for f in shared/ui/creds-form.html shared/ui/setup.js shared/ui/styles.css; do
    if [ -f "$f" ]; then PASS=$((PASS+1)); echo "  [PASS] $f"
    else FAIL=$((FAIL+1)); echo "  [FAIL] $f missing"; fi
done

echo ""
echo "Deploy configs"
for f in .devcontainer/devcontainer.json .replit replit.nix; do
    if [ -f "$f" ]; then PASS=$((PASS+1)); echo "  [PASS] $f"
    else FAIL=$((FAIL+1)); echo "  [FAIL] $f missing"; fi
done

echo ""
echo "=== Summary: $PASS pass, $FAIL fail, $SKIP skip ==="
[ "$FAIL" -eq 0 ]
