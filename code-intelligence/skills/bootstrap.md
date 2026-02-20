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
pip install flyto-indexer tree-sitter-analyzer[mcp] code-graph-mcp cognee --break-system-packages

# ESLint (project-local is preferred)
npm install -D eslint

# Serena runs via uvx — no install needed
uvx --from git+https://github.com/oraios/serena serena --help
```

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

```bash
# Initialize with OpenAI embeddings (requires OPENAI_API_KEY in environment)
grepai init --provider openai --yes

# Start background file watcher to keep index live
grepai watch --background

# Verify watcher is running
grepai watch --status
```

> **If using a local embedding model instead of OpenAI:**
> Replace `--provider openai` with `--provider ollama` or `--provider lmstudio`.
> Ensure the local model server is running before init.

Expected output: `.grepai/` directory created with `config.yaml`, `symbols.gob`, and vector store files.

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
# Quick semantic search smoke test
grepai search "main entry point" --json --compact --limit 3

# Quick structure smoke test  
repomix --no-files --stdout | head -50

# Quick flyto smoke test (list indexed projects)
flyto-index status .
```

---

## Bootstrap Checklist

- [ ] All CLI binaries respond to `--help` or `--version`
- [ ] `OPENAI_API_KEY` set in environment (or local embedder running)
- [ ] `.grepai/` directory exists and watcher is running
- [ ] `.flyto/` directory exists (created by `flyto-index init .`)
- [ ] `flyto-index brief .` produced output
- [ ] `PROJECT_NAME` variable resolved correctly from `package.json`

Once complete, proceed to the appropriate workflow sub-skill.
