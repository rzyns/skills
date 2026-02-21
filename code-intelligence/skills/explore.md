# Explore — Orient on an Unknown Codebase

Use this skill when starting work on an unfamiliar codebase and needing to understand its structure, entry points, module boundaries, and key symbols — before writing or changing any code.

**Prerequisite**: Bootstrap must be complete (`.grepai/` and `.flyto-index/` exist).

---

## Phase 1: Structural Overview (No File Content)

Start here — get shape and size without loading any source:

```bash
# Directory tree + file list + token counts per file, no code
repomix --no-files --stdout
```

This gives you: total file count, language breakdown, directory structure, and token budget estimate. Decide from here whether you need compressed signatures or targeted deep-dives.

---

## Phase 2: Architectural Brief

```bash
# Module boundaries, entry points, high-level purpose per file
flyto-index brief .

# Get semantic description for a specific file of interest
flyto-index describe src/index.ts --path .
```

Read the brief output carefully — it tells you which files are entry points, which are utilities, and where major subsystems live. Use `describe` to drill into specific files as you identify them.

---

## Phase 3: Compressed Code Map (Signatures Only)

When you need to see the shape of the actual code without full bodies:

```bash
# All files, function/class signatures only (~70% fewer tokens than full source)
repomix --compress --remove-comments --stdout

# Or focus on a specific subsystem
repomix --include "src/auth/**,src/middleware/**" --compress --stdout
```

Use `--parsable-style` if you encounter XML escaping issues:
```bash
repomix --compress --stdout --parsable-style
```

---

## Phase 4: Key Symbol Analysis

Once you've identified files of interest from phases 1–3:

```bash
# Get structure of a specific file without reading it fully
uv run tree-sitter-analyzer src/path/to/file.ts --summary

# Full element table (classes, methods, fields, imports)
uv run tree-sitter-analyzer src/path/to/file.ts --table full

# JSON output for programmatic use
uv run tree-sitter-analyzer src/path/to/file.ts --json
```

**Summary output example** (fast orientation):
```
File: src/auth/login.ts (247 lines)
Language: typescript
Metrics: 189 code / 28 comment / 30 blank
Elements: 2 classes, 14 methods, 5 fields, 8 imports
```

---

## Phase 5: Semantic Orientation

Find concepts rather than symbols — useful when you don't know the naming conventions yet:

```bash
# Find code by what it does
grepai search "user authentication flow" --json --compact --limit 5

# Find error handling patterns
grepai search "error handling middleware" --json --compact --limit 5

# Find configuration loading
grepai search "environment config loading" --toon --compact
```

---

## Phase 6: Read Only What You Need

Once you've identified the exact lines of interest, read surgically:

```bash
# Read specific line range (avoids loading full file)
uv run tree-sitter-analyzer src/auth/login.ts \
  --partial-read --start-line 45 --end-line 80

# Read a method's implementation
uv run tree-sitter-analyzer src/services/user.ts \
  --query-key methods --filter "name=handleLogin"
```

---

## Recommended Exploration Sequence

For a completely unknown TypeScript/JavaScript codebase:

1. `repomix --no-files --stdout` → understand size and shape
2. `flyto-index brief .` → understand architecture
3. `repomix --compress --stdout` → scan all signatures
4. `uv run tree-sitter-analyzer <key-file> --table full` → inspect important files
5. `grepai search "<domain concept>" --json --compact` → locate relevant code semantically
6. `uv run tree-sitter-analyzer <file> --partial-read --start-line N --end-line M` → read only the relevant sections

This sequence typically achieves **70–90% token reduction** vs reading raw files directly.

---

## Cross-Project Search

For monorepos or when symbols span multiple packages:

```bash
# Find all usages of a pattern across source and test dirs
uv run find-and-grep --roots src packages libs \
  --query "class.*Service" --extensions ts

# Find all imports of a module
uv run find-and-grep --roots src \
  --query "import.*from.*auth" --extensions ts tsx
```
