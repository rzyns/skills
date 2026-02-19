# Quality — Audit TypeScript/JavaScript Code Quality

Use this skill when you need to assess code quality: find lint errors, identify overly complex functions, locate dead code, or get a structured view of issues before a PR or code review.

**Prerequisite**: `eslint` installed (project-local preferred: `npm install -D eslint`).

---

## ESLint: Lint Analysis

### Get a Full JSON Report

```bash
# Lint entire src directory, JSON output
eslint src/ --format json

# Save to file for later reference or diffing
eslint src/ --format json -o lint-report.json

# Lint specific files
eslint src/auth/login.ts src/middleware/auth.ts --format json

# Lint with glob pattern
eslint "src/**/*.{ts,tsx}" --format json
```

**JSON output shape** — use `messages[]` to find issues:
```json
[
  {
    "filePath": "/src/auth/login.ts",
    "messages": [
      {
        "ruleId": "no-unused-vars",
        "severity": 2,
        "message": "'token' is defined but never used.",
        "line": 42,
        "column": 7
      }
    ],
    "errorCount": 1,
    "warningCount": 0
  }
]
```

Severity: `2` = error, `1` = warning.

---

### Count and Triage Issues

```bash
# Quick summary: errors only (exit 0 = clean)
eslint src/ --quiet --format stylish

# Count total errors
eslint src/ --format json | \
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); \
  console.log('Errors:', d.reduce((s,f)=>s+f.errorCount,0), \
  'Warnings:', d.reduce((s,f)=>s+f.warningCount,0))"

# Fail if more than N warnings (useful for CI gates)
eslint src/ --max-warnings 5
```

---

### Auto-Fix What Can Be Fixed

```bash
# Fix all auto-fixable issues in place
eslint src/ --fix

# Preview what would be fixed (dry run)
eslint src/ --fix-dry-run --format json

# Fix only a specific rule
eslint src/ --fix --rule "no-trailing-spaces: error"
```

---

### Focused Analysis

```bash
# Only specific rules (useful when investigating a single issue type)
eslint src/ \
  --rule '{"no-unused-vars": "error"}' \
  --rule '{"no-console": "warn"}' \
  --format json

# Ignore test files for production code audit (ESLint 9: use ignores in eslint.config.js)
# eslint.config.js: export default [{ ignores: ["**/*.test.ts", "**/*.spec.ts"] }]
eslint src/ --format json
```

---

## tree-sitter-analyzer: Structural Complexity

### Identify Complex Files

```bash
# Advanced analysis with complexity metrics on a file
uv run tree-sitter-analyzer src/auth/login.ts --advanced

# JSON output for all files (pipe to filter)
uv run tree-sitter-analyzer src/ --json
```

### Find High-Complexity Functions

```bash
# Get all methods with complexity info
uv run tree-sitter-analyzer src/services/orderService.ts \
  --query-key methods

# Filter for public methods only
uv run tree-sitter-analyzer src/services/orderService.ts \
  --query-key methods --filter "public=true"

# Get summary stats per file
uv run tree-sitter-analyzer src/auth/login.ts --summary
```

Output example:
```
File: src/auth/login.ts (247 lines)
Language: typescript
Metrics: 189 code / 28 comment / 30 blank
Elements: 2 classes, 14 methods, 5 fields, 8 imports
```

---

## code-graph-mcp: Architectural Quality (MCP)

For deeper structural analysis, use the code-graph MCP server:

```
mcp__code-graph__analyze_codebase()
→ Build full code graph (call this first, required for other tools)

mcp__code-graph__complexity_analysis(threshold=15)
→ All functions exceeding complexity threshold 15

mcp__code-graph__centrality_analysis()
→ PageRank + betweenness: which files/symbols are architectural hotspots

mcp__code-graph__detect_patterns()
→ Code smells and duplicate detection

mcp__code-graph__dependency_graph()
→ Module-level dependency visualization
```

---

## Quality Audit Workflow

### Before a Pull Request

```bash
# 1. Capture baseline
eslint src/ --format json -o lint-report.json

# 2. Check for auto-fixable issues
eslint src/ --fix-dry-run --format compact

# 3. Identify structurally complex files
uv run tree-sitter-analyzer src/ --summary 2>/dev/null | \
  grep -E "methods|classes" | sort -t: -k2 -rn | head -20

# 4. Type check
npx tsc --noEmit

# 5. Fix auto-fixable lint issues
eslint src/ --fix
```

### Ongoing Quality Monitoring

```bash
# Quick clean check (exit 0 = no errors)
eslint src/ --quiet && echo "✓ No lint errors"

# After any refactor: re-lint affected files only
eslint src/auth/ src/middleware/ --format json
```

---

## Quality Checklist

- [ ] `eslint src/ --format json` — zero errors
- [ ] `eslint src/ --max-warnings 10` — warnings under threshold
- [ ] `npx tsc --noEmit` — no TypeScript type errors
- [ ] High-complexity functions reviewed (`--advanced`)
- [ ] No unused variables or imports (`eslint src/ --rule '{"no-unused-vars": "error"}'` or @typescript-eslint/no-unused-vars)
- [ ] `eslint src/ --fix` applied for auto-fixable issues
