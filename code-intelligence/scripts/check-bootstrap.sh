#!/usr/bin/env bash
# check-bootstrap.sh — Verify code-intelligence skill prerequisites
# Run from the project root directory.
# Exits 0 if all required checks pass, 1 if any required check fails.

set -uo pipefail

PASS="✓"
FAIL="✗"
WARN="!"
errors=0
warnings=0

check() {
  local label="$1"
  local result="$2"   # "pass", "fail", or "warn"
  local detail="${3:-}"
  if [[ "$result" == "pass" ]]; then
    printf "  %s  %s\n" "$PASS" "$label"
    [[ -n "$detail" ]] && printf "       %s\n" "$detail" || true
  elif [[ "$result" == "warn" ]]; then
    printf "  %s  %s\n" "$WARN" "$label"
    [[ -n "$detail" ]] && printf "       %s\n" "$detail" || true
    warnings=$((warnings + 1))
  else
    printf "  %s  %s\n" "$FAIL" "$label"
    [[ -n "$detail" ]] && printf "       %s\n" "$detail" || true
    errors=$((errors + 1))
  fi
}

echo ""
echo "=== Code Intelligence Bootstrap Check ==="
echo ""

# ── CLI Binaries ──────────────────────────────────────────────────────────────
echo "CLI Binaries:"

for bin in grepai repomix flyto-index task-master; do
  if command -v "$bin" &>/dev/null; then
    check "$bin" "pass" "$(command -v "$bin")"
  else
    check "$bin" "fail" "not found — see bootstrap.md for install instructions"
  fi
done

# ESLint (project-local preferred)
if ./node_modules/.bin/eslint --version &>/dev/null 2>&1; then
  ver=$(./node_modules/.bin/eslint --version 2>/dev/null)
  check "eslint (local)" "pass" "$ver"
elif command -v eslint &>/dev/null; then
  ver=$(eslint --version 2>/dev/null)
  check "eslint (global)" "warn" "$ver — project-local preferred: npm install -D eslint"
else
  check "eslint" "warn" "not found — install with: npm install -D eslint"
fi

# uv-based tools
if uv run tree-sitter-analyzer --version &>/dev/null 2>&1; then
  check "uv run tree-sitter-analyzer" "pass" ""
else
  check "uv run tree-sitter-analyzer" "fail" "install: pip install tree-sitter-analyzer[mcp]"
fi

if uv run find-and-grep --help &>/dev/null 2>&1; then
  check "uv run find-and-grep" "pass" ""
else
  check "uv run find-and-grep" "fail" "install: pip install tree-sitter-analyzer[mcp]"
fi

echo ""

# ── Index Directories ─────────────────────────────────────────────────────────
echo "Index Directories:"

if [[ -d ".grepai" ]]; then
  check ".grepai/ exists" "pass" ""
else
  check ".grepai/ exists" "fail" "run: grepai init --provider openai --yes"
fi

if [[ -d ".flyto" ]]; then
  check ".flyto/ exists" "pass" ""
else
  check ".flyto/ exists" "fail" "run: flyto-index init . && flyto-index scan . --full"
fi

if [[ -d ".taskmaster" ]]; then
  check ".taskmaster/ exists" "pass" "(optional — only needed for feature planning)"
else
  check ".taskmaster/ missing" "warn" "optional — run: task-master init (only if planning tasks)"
fi

echo ""

# ── Grepai Watcher ────────────────────────────────────────────────────────────
echo "Grepai Watcher:"

watcher_status=$(grepai watch --status 2>/dev/null || true)
if echo "$watcher_status" | grep -qi "running"; then
  check "watcher running" "pass" ""
else
  check "watcher not running" "warn" "start with: grepai watch --background"
fi

echo ""

# ── Environment ───────────────────────────────────────────────────────────────
echo "Environment:"

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  check "OPENAI_API_KEY set" "pass" ""
else
  check "OPENAI_API_KEY not set" "warn" "required for OpenAI embeddings — skip if using local embedder"
fi

# Project name from package.json
if [[ -f "package.json" ]]; then
  project_name=$(node -p "require('./package.json').name" 2>/dev/null || true)
  if [[ -n "$project_name" ]]; then
    check "PROJECT_NAME" "pass" "$project_name"
  else
    check "PROJECT_NAME" "warn" "could not read name from package.json"
  fi
else
  project_name=$(basename "$PWD")
  check "PROJECT_NAME" "warn" "no package.json — using directory name: $project_name"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "========================================="
if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
  echo "  All checks passed. Bootstrap complete."
elif [[ $errors -eq 0 ]]; then
  echo "  $warnings warning(s) — bootstrap usable, but review warnings above."
else
  echo "  $errors error(s), $warnings warning(s) — fix errors before proceeding."
fi
echo "========================================="
echo ""

exit $((errors > 0 ? 1 : 0))
