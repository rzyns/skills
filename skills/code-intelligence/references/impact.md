# Impact — Assess Blast Radius Before Changing Code

Use this skill **before** renaming, deleting, or significantly changing any symbol. It tells you exactly what else in the codebase will break or need updating.

**Prerequisite**: Bootstrap must be complete. Run `flyto-index scan .` at the start of each session to keep the index current — re-scanning is incremental automatically (only changed files are re-processed).

---

## Step 0: Refresh the Index

Always do this at the start of a work session — takes seconds if nothing changed:

```bash
flyto-index scan .
```

---

## Step 1: Identify the Symbol Name

The CLI takes a plain symbol name plus `--path .` pointing to the project root. You do not need to construct a full symbol ID for CLI use — that format (`project:path:type:name`) is only used when calling flyto-index's MCP tools directly.

Identify the exact function, class, or method name you intend to change:

```bash
# Confirm the symbol exists in the index
flyto-index status .

# Or search for it by name to verify spelling
grepai search "validateToken" --json --compact --limit 3
```

---

## Step 2: Run Impact Analysis

```bash
# What breaks if I change this function?
flyto-index impact validateToken --path .

# What breaks if I change this class?
flyto-index impact User --path .

# Preview impact before a rename or signature change
flyto-index check . --json
```

Output lists all callsites, importers, and transitive dependents. If you want a CI-style risk assessment:

```bash
# Exits non-zero if impact exceeds threshold (good for pre-commit hooks)
flyto-index check . --threshold medium
```

---

## Step 3: Trace Call Graph (Complement Impact)

flyto-index gives you the dependency tree; grepai gives you the call context:

```bash
# All callers with code context
grepai trace callers "validateToken" --json

# All callees (what this function depends on)
grepai trace callees "validateToken" --json

# Full bidirectional graph
grepai trace graph "validateToken" --depth 3 --toon
```

---

## Step 4: Inspect Affected Files

After identifying affected files, read only the relevant sections:

```bash
# Get structure of each affected file first
uv run tree-sitter-analyzer src/affected/file.ts --table full

# Then read only the relevant lines
uv run tree-sitter-analyzer src/affected/file.ts \
  --partial-read --start-line N --end-line M
```

---

## Step 5: Type-Aware Reference Check (MCP Fallback)

For TypeScript-specific impact where types matter (e.g., changing an interface):

```
mcp__serena__find_referencing_symbols("AuthPayload")
→ Returns every symbol that uses this type, with full type context
```

Use this when `flyto-index impact` output needs TypeScript type resolution to determine whether a change is actually breaking.

---

## Step 6: Plan the Change

Once you have the full impact picture:

1. List all files that need updating
2. Order changes to avoid broken intermediate states (leaf nodes first)
3. For safe cross-file renames → use `mcp__serena__rename_symbol` (type-safe)
4. For logic changes → update each callsite manually, verify with lint after each file

---

## Pre-Refactor Checklist

- [ ] `flyto-index scan .` completed (re-scanning is incremental automatically)
- [ ] `flyto-index impact` run on the target symbol
- [ ] `grepai trace callers` run to see call context
- [ ] All affected files listed and reviewed
- [ ] Change order determined (leaf-first)
- [ ] ESLint baseline captured (`eslint src/ --format json -o pre-refactor-lint.json`)

---

## Post-Refactor Verification

After making changes:

```bash
# Check for new lint errors introduced
eslint src/ --format json

# Re-trace call graph to confirm connections are as expected
grepai trace callers "renamedFunction" --json

# Type check (if TypeScript project)
npx tsc --noEmit
```
