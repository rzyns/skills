# Search — Find Code by Meaning, Name, or Pattern

Use this skill when you need to locate code across a TypeScript/JavaScript codebase — whether you know the exact name, have a semantic description, or only know a pattern.

**Prerequisite**: Bootstrap must be complete (`.grepai/` index exists and watcher is running).

---

## Decision Tree: Which Search Tool?

```
Do you know the exact symbol name?
├── Yes → grepai trace or find-and-grep
└── No, I have a description of what it does
    └── grepai search (semantic)

Do you need callers/callees of a known symbol?
└── Yes → grepai trace callers / callees / graph

Do you need a regex/AST pattern across files?
└── Yes → uv run find-and-grep

Is this type-aware (need to follow TypeScript types)?
└── Yes → mcp__serena__find_symbol (MCP, not CLI)
```

---

## Semantic Search (Meaning-Based)

Use when you can describe what code does but don't know its name:

```bash
# Default: JSON output, compact (minimal tokens)
grepai search "user authentication flow" --json --compact

# Limit results to reduce noise
grepai search "database connection pooling" --json --compact --limit 5

# TOON format: ~50% fewer tokens than JSON, good for reasoning
grepai search "error handling middleware" --toon --compact

# Cross-workspace (monorepo)
grepai search "auth" --workspace my-fullstack --json --compact
```

**JSON output shape** — use `results[].file` and `results[].start_line` to locate code:
```json
{
  "query": "authentication flow",
  "count": 3,
  "results": [
    { "file": "src/auth/login.ts", "start_line": 23, "end_line": 45,
      "score": 0.94, "content": "..." }
  ]
}
```

After getting results, use partial-read to inspect without loading full files:
```bash
uv run tree-sitter-analyzer src/auth/login.ts \
  --partial-read --start-line 23 --end-line 45
```

---

## Call Graph Tracing (Known Symbol Name)

Use when you know a symbol name and need to understand its connections:

```bash
# Who calls this function? (blast radius awareness)
grepai trace callers "ValidateToken" --json
grepai trace callers "handleRequest" --toon

# What does this function call? (dependency graph)
grepai trace callees "ProcessOrder" --json
grepai trace callees "AuthMiddleware" --toon

# Full bidirectional call graph around a symbol
grepai trace graph "AuthMiddleware" --json
grepai trace graph "ProcessOrder" --depth 3 --toon
```

**Trace JSON output shape**:
```json
{
  "query": "ValidateToken",
  "mode": "callers",
  "count": 3,
  "results": [
    { "file": "src/handlers/auth.ts", "line": 42,
      "caller": "handleAuth", "context": "validateToken(ctx, token)" }
  ]
}
```

**Supported languages**: TypeScript, JavaScript, Python, Go, Rust, Java, C/C++, C#, PHP, Zig, Pascal

---

## Pattern Search (Regex / AST)

Use when you know the syntactic shape of what you're looking for:

```bash
# Find class declarations matching a pattern
uv run find-and-grep --roots src \
  --query "class.*Service" --extensions ts

# Find specific function definitions
uv run find-and-grep --roots src \
  --query "function validate" --extensions ts,js

# Find all imports of a specific module
uv run find-and-grep --roots src \
  --query "import.*from.*'@/auth'" --extensions ts,tsx

# Search across multiple root directories (monorepo)
uv run find-and-grep --roots src,packages,libs \
  --query "useEffect.*\[\]" --extensions tsx,jsx
```

---

## Type-Aware Symbol Search (MCP Fallback)

When pattern search isn't sufficient and you need TypeScript type resolution — fall back to Serena's MCP tools:

```
mcp__serena__find_symbol("ValidateToken")
→ Returns: file, line, type signature, all definitions across the project
```

```
mcp__serena__find_referencing_symbols("UserService")
→ Returns: every symbol that references UserService, with types
```

Use this when:
- A symbol is overloaded or has multiple definitions
- You need interface/type information, not just call sites
- Pattern search returns too many false positives

---

## Combining Tools: Full Search Workflow

```bash
# 1. Semantic: find the relevant area
grepai search "rate limiting middleware" --json --compact --limit 5

# 2. Pattern: confirm exact location
uv run find-and-grep --roots src \
  --query "rateLimiter\|rateLimit" --extensions ts

# 3. Call graph: understand connections
grepai trace callers "rateLimiter" --toon

# 4. Read: inspect only what you need
uv run tree-sitter-analyzer src/middleware/rateLimiter.ts \
  --partial-read --start-line 12 --end-line 55
```
