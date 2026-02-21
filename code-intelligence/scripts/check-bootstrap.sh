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
if uv run tree-sitter-analyzer --show-supported-languages &>/dev/null 2>&1; then
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

# ── Environment ───────────────────────────────────────────────────────────────
echo "Environment:"

# direnv detection
if command -v direnv &>/dev/null && [[ -f ".envrc" ]]; then
  check "direnv in use" "warn" "prefix all grepai commands with: direnv exec . grepai ..."
elif [[ -f ".envrc" ]]; then
  check ".envrc found but direnv not in PATH" "warn" "grepai watcher may not inherit secrets"
fi

# OPENAI_API_KEY
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

# ── Git Worktrees Check ────────────────────────────────────────────────────────
echo "Git Worktrees:"

parent_dir="$(dirname "$PWD")"
sibling_grepai=$(find "$parent_dir" -maxdepth 3 -name "config.yaml" -path "*/.grepai/*" 2>/dev/null \
  | grep -v "^$PWD/" || true)
sibling_count=$(echo "$sibling_grepai" | grep -c "config.yaml" 2>/dev/null || echo 0)

if [[ $sibling_count -gt 0 ]]; then
  check "sibling worktrees with .grepai" "warn" \
    "$sibling_count other worktree(s) found — grepai will index ALL simultaneously (rate limit risk)"
  echo "       Hide others before starting watcher: see bootstrap.md Step 0.5"
  echo "$sibling_grepai" | head -5 | sed 's/^/         /'
  [[ $sibling_count -gt 5 ]] && echo "         ... and $((sibling_count - 5)) more"
else
  check "no sibling worktrees with .grepai" "pass" ""
fi

echo ""

# ── File Count Pre-flight ──────────────────────────────────────────────────────
echo "Project Scale:"

source_count=$(find . -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" \) \
  ! -path "*/.next/*" ! -path "*/node_modules/*" ! -path "*/.rush/*" \
  ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.git/*" ! -path "*/coverage/*" \
  2>/dev/null | wc -l | tr -d ' ')

if [[ $source_count -lt 300 ]]; then
  check "source file count" "pass" "$source_count files — initial indexing should be fast"
elif [[ $source_count -lt 1000 ]]; then
  check "source file count" "warn" \
    "$source_count files — indexing will take a few minutes; OpenAI Tier 1 may be marginal"
else
  check "source file count" "warn" \
    "$source_count files — large repo; tune ignore list before running watcher. OpenAI Tier 2+ recommended or use local embedder"
fi

echo ""

# ── Index Directories ─────────────────────────────────────────────────────────
echo "Index Directories:"

if [[ -d ".grepai" ]]; then
  check ".grepai/ exists" "pass" ""

  # Verify config endpoint
  if [[ -f ".grepai/config.yaml" ]]; then
    endpoint=$(grep "endpoint:" .grepai/config.yaml | head -1 | awk '{print $2}')
    provider=$(grep "provider:" .grepai/config.yaml | head -1 | awk '{print $2}')
    if [[ "$provider" == "openai" && "$endpoint" == "http://localhost"* ]]; then
      check ".grepai/config.yaml endpoint" "fail" \
        "provider=openai but endpoint=$endpoint — likely incorrect. Should be https://api.openai.com/v1"
      errors=$((errors + 1))
    else
      check ".grepai/config.yaml endpoint" "pass" "$provider @ $endpoint"
    fi
  fi

  # Check if index has actual content (not just the empty 385-byte sentinel)
  if [[ -f ".grepai/index.gob" ]]; then
    index_size=$(wc -c < ".grepai/index.gob" | tr -d ' ')
    if [[ $index_size -gt 10000 ]]; then
      check "grepai index has content" "pass" "${index_size} bytes"
    elif [[ $index_size -gt 384 ]]; then
      check "grepai index partially built" "warn" \
        "${index_size} bytes — indexing may still be in progress"
    else
      check "grepai index is empty" "warn" \
        "index.gob is ${index_size} bytes (sentinel only) — watcher has not indexed any files yet"
    fi
  else
    check "grepai index.gob missing" "warn" "watcher not yet started or index not built"
  fi
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
  pid=$(echo "$watcher_status" | grep -oE 'PID [0-9]+' | head -1)
  check "watcher running" "pass" "${pid:-}"

  # Check watcher log for recent errors
  log_file=$(find ~/Library/Logs/grepai -name "grepai-worktree-*.log" 2>/dev/null | head -1)
  [[ -z "$log_file" ]] && log_file=$(find ~/.local/state/grepai/logs -name "grepai-watch.log" 2>/dev/null | head -1 || true)
  if [[ -n "$log_file" && -f "$log_file" ]]; then
    recent_errors=$(tail -20 "$log_file" 2>/dev/null | grep -c "Error\|429\|failed" || true)
    if [[ $recent_errors -gt 0 ]]; then
      check "watcher recent errors" "warn" \
        "$recent_errors error lines in recent log — check: tail -20 $log_file"
    else
      check "watcher log clean" "pass" ""
    fi
  fi
else
  check "watcher not running" "warn" "start with: grepai watch --background"
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
