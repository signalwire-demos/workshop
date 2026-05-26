#!/usr/bin/env bash
# Pre-workshop smoke test. Source-level checks: file presence + Python syntax.
# Run from repo root: bash scripts/smoke.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

check_path() {
    if [ -e "$1" ]; then PASS=$((PASS+1)); echo "  [PASS] $1"
    else FAIL=$((FAIL+1)); echo "  [FAIL] $1 missing"; fi
}

check_python_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then FAIL=$((FAIL+1)); echo "  [FAIL] $dir (missing)"; return; fi
    if python3 -m py_compile "$dir"/*.py 2>/dev/null; then
        PASS=$((PASS+1)); echo "  [PASS] $dir (python syntax)"
    else
        FAIL=$((FAIL+1)); echo "  [FAIL] $dir (python syntax)"
    fi
}

check_lang() {
    local pillar_dir="$1" lang="$2" expected="$3"
    local dir
    if [ "$lang" = "python" ] || [ "$lang" = "typescript" ]; then
        dir="$pillar_dir/$lang"
    else
        dir="$pillar_dir/ports/$lang"
    fi
    if [ ! -d "$dir" ]; then
        FAIL=$((FAIL+1)); echo "  [FAIL] $dir (dir missing)"
        return
    fi
    local ok=true
    for f in $expected; do
        if [ ! -e "$dir/$f" ]; then ok=false; echo "  [FAIL] $dir/$f missing"; FAIL=$((FAIL+1)); fi
    done
    if $ok; then PASS=$((PASS+1)); echo "  [PASS] $dir ($expected)"; fi
}

echo "=== Workshop smoke test ==="

for pillar in 01-ai-agent 02-rest-tour 03-relay-realtime; do
    echo ""; echo "Pillar: $pillar"
    check_python_dir "examples/$pillar/python"
    check_lang "examples/$pillar" typescript "package.json tsconfig.json app.ts demo.js"
    check_lang "examples/$pillar" ruby      "Gemfile app.rb demo.js"
    check_lang "examples/$pillar" go        "go.mod main.go demo.js"
    check_lang "examples/$pillar" java      "build.gradle settings.gradle"
    check_lang "examples/$pillar" perl      "cpanfile app.pl demo.js"
    check_lang "examples/$pillar" php       "composer.json demo.js"
    check_lang "examples/$pillar" rust      "Cargo.toml src/main.rs demo.js"
    check_lang "examples/$pillar" dotnet    "Workshop.csproj demo.js"
    check_lang "examples/$pillar" cpp       "CMakeLists.txt main.cpp"
done

echo ""
echo "Shared UI"
for f in shared/ui/creds-form.html shared/ui/setup.js shared/ui/styles.css; do
    check_path "$f"
done

echo ""
echo "Deploy configs"
for f in .devcontainer/devcontainer.json .replit replit.nix; do
    check_path "$f"
done

echo ""
echo "=== Summary: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ]
