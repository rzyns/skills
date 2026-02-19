---
name: code-intelligence
description: CLI-first code intelligence for authoring, editing, and reasoning about TypeScript/JavaScript codebases. Use this skill whenever working with an unfamiliar codebase, searching for code by meaning or pattern, planning a refactor, assessing blast radius before changing a symbol, planning features from a PRD, or auditing code quality. Also use proactively any time the task involves navigating, understanding, or modifying a non-trivial TS/JS codebase — even if the user doesn't explicitly ask for code intelligence tools.
---

# Code Intelligence — Master Dispatcher

## Purpose

This skill gives you on-demand, context-efficient access to a suite of code intelligence tools for TypeScript/JavaScript projects. The design principle is **CLI-first**: 7 of 9 tools are invoked via `bash_tool` to avoid loading their MCP schemas into the context window. Only Serena (type-safe symbol ops) and code-graph-mcp (graph/centrality analysis) run as MCP servers.

**Result**: ~75% reduction in always-loaded MCP tool schema tokens, with full capability available on demand.

---

## Tool Roster

| Tool | Mode | Primary Use |
|------|------|-------------|
| `grepai` | CLI | Semantic search + call graph tracing |
| `repomix` | CLI | Pack codebase context for LLM consumption |
| `flyto-index` | CLI | Symbol indexing + blast-radius impact analysis |
| `task-master` | CLI | PRD → tasks, dependency management |
| `uv run tree-sitter-analyzer` | CLI | File structure analysis, partial reads |
| `uv run find-and-grep` | CLI | Cross-project pattern search |
| `eslint` | CLI | TS/JS lint with JSON output |
| `serena` | MCP | Type-safe rename, cross-file navigation |
| `code-graph-mcp` | MCP | Dependency graphs, centrality analysis |

---

## Routing — Which Sub-Skill to Read

Read the sub-skill file that matches the task before doing any work.

| Situation | Read |
|-----------|------|
| Tools not yet installed / fresh codebase | `skills/bootstrap.md` |
| New codebase, need to understand structure | `skills/explore.md` |
| Finding code by meaning, name, or pattern | `skills/search.md` |
| Before changing a symbol / refactoring | `skills/impact.md` |
| Planning a feature from a PRD or brief | `skills/plan.md` |
| Auditing code quality, finding lint issues | `skills/quality.md` |

**Always check bootstrap first** if `.grepai/`, `.flyto/`, or `.taskmaster/` do not exist in the project root.

---

## MCP Tools Reference (Always Available)

These are available without any CLI setup:

**Serena** (use when CLI tools can't resolve a type-aware operation):
- `mcp__serena__find_symbol` — locate symbol definitions with full type context
- `mcp__serena__rename_symbol` — safe cross-file rename
- `mcp__serena__get_symbols_overview` — high-level symbol map of a file
- `mcp__serena__find_referencing_symbols` — type-aware usages

**code-graph-mcp** (use for architectural/graph analysis):
- `mcp__code-graph__analyze_codebase` — build full code graph (call first)
- `mcp__code-graph__centrality_analysis` — PageRank hotspots
- `mcp__code-graph__dependency_graph` — module dependency visualization
- `mcp__code-graph__complexity_analysis` — high-complexity function detection

---

## Token Budget Notes

- Prefer `--json --compact` on all grepai calls
- Prefer `--toon` over `--json` when output is for reasoning (not parsing)
- Use `--compress` on repomix unless full source is needed
- Use `--partial-read` on tree-sitter-analyzer instead of reading full files
- Pipe to `head -c 8000` if a CLI output is unexpectedly large
