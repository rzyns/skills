# Bootstrap — Fresh Codebase Setup

Run this skill when any of the following are missing from the project root:
- `.grepai/` directory
- `.flyto/` directory
- `.taskmaster/` directory (only needed if planning tasks)

---

## Step 0: Verify Prerequisites

Run the bootstrap check script from the project root for a full status report:

```bash
bash <skill-dir>/scripts/check-bootstrap.sh
```

This checks all binaries, index directories, watcher status, and environment in one pass — exits 0 if ready, 1 if action needed. If the skill directory is unknown, find it with `find ~/.claude -name "check-bootstrap.sh" 2>/dev/null`.

If any tools are missing, install them:

```bash
# Go binary
curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh

# Node.js tools
npm install -g repomix task-master-ai

# Python tools (use --break-system-packages on Ubuntu/Debian)
pip install flyto-indexer tree-sitter-analyzer[mcp] code-graph-mcp --break-system-packages

# ESLint (project-local is preferred)
npm install -D eslint

# Serena runs via uvx — no install needed
uvx --from git+https://github.com/oraios/serena serena --help
```

---

## Step 0.5: Environment & Git Worktrees Check

### direnv

If the project uses `direnv`, all tool commands must be prefixed with `direnv exec .` so background daemons inherit the environment:

```bash
# Check if direnv is in use
[ -f .envrc ] && echo "direnv in use — prefix all grepai commands with: direnv exec ."
```

When direnv is active, use `direnv exec .` for **every** grepai command, including the watcher start. The watcher daemon process inherits the environment from the shell that starts it, but only if that shell loaded direnv first.

### Git Worktrees (Critical for Rate Limits)

If this project uses git worktrees, grepai's watcher auto-discovers ALL sibling directories containing `.grepai/` and indexes them **simultaneously**. With many worktrees, this causes immediate and repeated OpenAI rate-limit exhaustion.

```bash
# Detect sibling worktrees with grepai configs
ls ../*/  .grepai/config.yaml 2>/dev/null | head -20
# or
find "$(dirname "$PWD")" -maxdepth 3 -name "config.yaml" -path "*/.grepai/*" 2>/dev/null
```

**If multiple worktrees are present:** Before starting the watcher for this project, temporarily rename all OTHER worktrees' `.grepai/` directories to `.grepai.bak/`. Then, after this project's initial indexing completes, restore them one at a time. This prevents concurrent indexing from saturating the token-per-minute limit.

```bash
# Hide other worktrees (do from this project's parent directory)
for wt in ../*/; do
  [ "$wt" = "../$(basename "$PWD")/" ] && continue
  [ -d "$wt/.grepai" ] && mv "$wt/.grepai" "$wt/.grepai.bak" && echo "hidden: $wt"
done
```

**Important:** grepai will re-create empty `.grepai/` directories in siblings when the watcher starts. You may need to remove those re-created directories too if they appear.

---

## Step 1: Discover Project Identity

The project name is used by flyto-index MCP tools (not the CLI) to construct symbol IDs. Resolve it dynamically for use in MCP calls later:

```bash
# Read project name from package.json
PROJECT_NAME=$(node -p "require('./package.json').name" 2>/dev/null || basename "$PWD")
echo "Project prefix: $PROJECT_NAME"
```

The CLI (`flyto-index impact`) takes just a symbol name + `--path .`. The full symbol ID format (`$PROJECT_NAME:path/to/file:type:symbol`) is only needed when calling flyto-index MCP tools directly.

---

## Step 2: Initialize grepai (Semantic Index)

### 2a: Pre-flight file count check

Before initializing, check how many files grepai would index. Large projects (>1000 source files) or projects with build artifact directories (`.next/`, `.rush/`, data dumps) need ignore-list tuning first — otherwise the initial indexing will take many minutes and may exhaust rate limits.

```bash
# Rough count of indexable source files (excluding known build artifacts)
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" \) \
  ! -path "*/.next/*" ! -path "*/node_modules/*" ! -path "*/.rush/*" \
  ! -path "*/dist/*" ! -path "*/build/*" 2>/dev/null | wc -l
```

If the count is very high, identify noisy directories:
```bash
find . -type f ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null \
  | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -20
```

### 2b: Initialize and tune ignore list

```bash
# Initialize with OpenAI embeddings (requires OPENAI_API_KEY in environment)
# Use "direnv exec ." prefix if the project uses direnv
grepai init --provider openai --yes
```

**After init, verify the generated config is correct:**

```bash
grep -A5 "embedder:" .grepai/config.yaml
```

The `endpoint` field must be `https://api.openai.com/v1` (not `http://localhost:11434`). If it shows the Ollama endpoint despite specifying `--provider openai`, edit it manually:

```yaml
embedder:
    provider: openai
    model: text-embedding-3-small
    endpoint: https://api.openai.com/v1
    dimensions: 1536
    parallelism: 1
```

**Add project-specific entries to the ignore list** in `.grepai/config.yaml`. Common ones beyond the defaults:

```yaml
ignore:
    # ... (keep existing entries) ...
    - .next          # Next.js build output
    - .turbo         # Turborepo cache
    - .rush          # Rush build cache
    - coverage       # Test coverage reports
    - build          # Generic build output
    # Add any data dump or vendor directories specific to this project
```

### 2c: Start the watcher

```bash
# Start background file watcher to keep index live
# Use "direnv exec ." prefix if the project uses direnv
grepai watch --background

# The 30s "timeout waiting for process to become ready" error is normal for large
# codebases — the daemon is still running and indexing. Verify with:
grepai watch --status

# Check actual progress in the log (macOS path):
tail -f ~/Library/Logs/grepai/grepai-watch.log 2>/dev/null \
  || tail -f ~/Library/Logs/grepai/grepai-worktree-*.log 2>/dev/null | head -20
```

### 2d: Rate limit guidance

OpenAI's embedding API has token-per-minute (TPM) limits. If initial indexing fails with 429 errors:

1. **Do NOT clear the index between restart attempts.** The index is written atomically at the end of each successful batch. Clearing it forces a full rescan from scratch every time.
2. Wait at least **3 full minutes** after the last failure before restarting — the rolling 1-minute window needs to fully clear, and retry bursts from previous attempts add up.
3. Check if the watcher is trying to index other worktrees simultaneously (Step 0.5).
4. If rate limits persist even after isolation, consider switching to a local embedder (Ollama with `nomic-embed-text`) which has no rate limits and was designed for this use case. Edit `.grepai/config.yaml`:

```yaml
embedder:
    provider: openai   # keep "openai" — grepai uses this for Ollama-compatible APIs too
    model: nomic-embed-text
    endpoint: http://localhost:11434
    dimensions: 768
    parallelism: 4
```

> **Tier guidance for OpenAI embeddings on large repos:**
> Tier 1 (default) = 1M TPM — not enough for initial indexing of repos >500 files.
> Tier 2 (add $5 to account) = 5M TPM — borderline for medium repos if other worktrees are isolated.
> For large repos with many worktrees, local embedders (Ollama) are more reliable.

---

## Step 3: Initialize flyto-index (Symbol + Impact Index)

```bash
# Initialize the project (creates config, required before first scan)
flyto-index init .

# Full scan (first time — forces complete rebuild)
flyto-index scan . --full

# Verify index was created
ls .flyto/
```

Expected output: `.flyto/` directory created with index files.

For subsequent sessions, run `flyto-index scan .` (without `--full`) — incremental re-scanning (only changed files) is automatic based on content hashes.

> **Note:** `flyto-index status .` reporting 0 files/symbols is expected — the status command reads from a summary metadata file, while scan data is stored in the index. Use `flyto-index outline .` or `flyto-index context --path . --query "..."` to verify the index is actually usable.

---

## Step 4: Get Architectural Brief (Recommended)

Once indexed, generate an architectural overview before doing any other work:

```bash
# High-level architecture brief (entry points, module boundaries)
flyto-index brief .

# Get a semantic description for a specific file
flyto-index describe src/index.ts --path .
```

`brief` gives you a project-wide map. `describe` annotates individual files — run it on key files as you discover them rather than all at once.

---

## Step 5 (Optional): Initialize task-master

Only needed if you'll be doing feature planning:

```bash
task-master init
```

This creates `.taskmaster/` with `config.json` and the tasks directory.

---

## Step 6: Verify Everything Works

```bash
# Quick semantic search smoke test (requires watcher to have indexed files)
grepai search "main entry point" --json --compact --limit 3

# Quick structure smoke test
repomix --no-files --stdout | head -50

# Quick flyto smoke test
flyto-index outline .
```

If grepai search returns `[]`, the index is still being built. Check watcher log progress (see Step 2c).

---

## Bootstrap Checklist

- [ ] All CLI binaries respond to `--help` or `--version`
- [ ] `OPENAI_API_KEY` set in environment (or local embedder running)
- [ ] If using direnv: `direnv exec .` prefix confirmed working
- [ ] If git worktrees: other worktrees' `.grepai/` dirs temporarily hidden
- [ ] File count checked — ignore list tuned before first watcher start
- [ ] `.grepai/config.yaml` has correct `endpoint` URL (not localhost for OpenAI)
- [ ] `.grepai/` directory exists and watcher is running
- [ ] `grepai search` returns results (not empty array)
- [ ] `.flyto/` directory exists (created by `flyto-index init .`)
- [ ] `flyto-index outline .` produced output
- [ ] `PROJECT_NAME` variable resolved correctly from `package.json`

Once complete, proceed to the appropriate workflow sub-skill.
