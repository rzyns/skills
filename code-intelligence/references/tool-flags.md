# Tool Flags — Verified Reference

All flags verified against locally installed tool versions. Load this file when unsure of a specific flag before running a command.

---

## grepai

```
grepai search <query>
  -j, --json          JSON output (for parsing)
  -t, --toon          TOON output (token-efficient, for reasoning)
  -c, --compact       Omit content from output (requires --json or --toon)
  -n, --limit N       Max results (default: 10)
      --workspace W   Cross-workspace search (workspace name)
      --project P     Filter to specific project (repeatable; requires --workspace)

grepai trace callers <symbol>   [--json] [--toon]
grepai trace callees <symbol>   [--json] [--toon]
grepai trace graph   <symbol>   [--depth N] [--json] [--toon]

grepai init
  -p, --provider openai|ollama|lmstudio
  -b, --backend  gob|postgres|qdrant
      --yes      Use defaults without prompting

grepai watch
      --background        Run as background daemon
      --status            Check if daemon is running
      --stop              Stop the daemon
      --log-dir PATH      Custom log directory
      --workspace W       Multi-project mode
```

**IMPORTANT**: `--compact` requires `--json` or `--toon` — it cannot be used alone.

---

## repomix

```
repomix [directories...]
  --stdout                   Write to stdout instead of file
  --compress                 Extract signatures only (Tree-sitter; ~70% fewer tokens)
  --remove-comments          Strip all code comments
  --parsable-style           Escape special chars for valid XML/Markdown output
  --no-files                 Metadata only — no file contents
  --include "<patterns>"     Comma-separated glob patterns: "src/**/*.ts,*.md"
  --style xml|markdown|json|plain   Output format (default: xml)
  -o, --output FILE          Output file path
  --no-file-summary          Omit file summary section
  --no-directory-structure   Omit directory tree
  --token-count-tree [N]     Show file tree with token counts (optional threshold)
  --quiet                    Suppress all output except errors
```

**NOTE**: `--include` takes a comma-separated string (unlike `find-and-grep` which is space-separated).

---

## flyto-index

```
flyto-index init [path]
  --name NAME        Project name (default: directory name)
  --no-gitignore     Do not add .flyto/ to .gitignore
  --index            Run indexer immediately after init

flyto-index scan <path>
  --full             Full rebuild (use on first scan; subsequent scans are incremental)
  --name NAME        Project name override

flyto-index impact <symbol_id> --path PATH
  --depth N          Max analysis depth (default: 3)
  # symbol_id: plain name (e.g. "useAuth") or full ID (project:path:type:name)

flyto-index check [path]
  --threshold high|medium|low   Fail when risk >= this level (default: high)
  --json                        Structured JSON output
  --base REF                    Git ref to compare against

flyto-index status [path]    [--json]
flyto-index brief  [path]
flyto-index describe <file_path> [--summary TEXT] [--path PATH]
  # Omit --summary to READ; include it to WRITE a description
```

**Directory**: All commands create/read from `.flyto/` (NOT `.flyto-index/`).

---

## task-master

```
task-master init

task-master parse-prd --input=<file> [--num-tasks N] [--append] [-r/--research]
  # Default: 10 tasks. No "auto" mode — omit flag to use default.

task-master list [status|all] [--with-subtasks] [--json] [-c/--compact]
  [--ready] [--blocking] [--all-tags] [-w/--watch]

task-master show <id>         # e.g. "5" or "5.2" for subtask
task-master next              # Next task respecting dependency chain

task-master set-status <id> <status>    # positional (preferred)
task-master set-status --id=<id> --status=<status>   # flag form
  # statuses: pending, in-progress, done, review, deferred, cancelled, blocked
  # id supports comma-separated: "3.1,3.2,3.3"

task-master add-task    --prompt="<text>" [--dependencies=<ids>] [--priority=<p>]
task-master remove-task --id=<id> [-y]
task-master update      --from=<id> --prompt="<context>"
task-master update-subtask --id=<parentId.subtaskId> --prompt="<context>"

task-master expand --id=<id> [-n/--num N] [-r/--research] [-p/--prompt TEXT]
task-master expand --all      [--force] [--research]

task-master analyze-complexity [-o/--output FILE] [-t/--threshold N] [-r/--research]
task-master complexity-report  [-f/--file FILE]

task-master validate-dependencies
task-master fix-dependencies
task-master add-dependency    --id=<id> --depends-on=<id>
task-master remove-dependency --id=<id> --depends-on=<id>

task-master research "<prompt>" [-i/--id <ids>] [-f/--files <paths>]
  [-c/--context TEXT] [-d/--detail low|medium|high] [--save-to <id>]
  # --id and --files accept comma-separated values
```

---

## uv run tree-sitter-analyzer

```
uv run tree-sitter-analyzer <file_path>
  # file_path is a SINGLE FILE (relative path) — directories not supported

  --summary              File stats: line count, element count
  --table full|compact|csv|json|toon   Full element table
  --advanced             Complexity metrics per function
  --json                 JSON output (alias: --output-format json)
  --toon                 TOON output (alias: --output-format toon)

  --query-key <key>      Query by type: "methods", "class", "imports", etc.
  --filter "name=X"      Filter results (e.g. "name=handleLogin", "public=true")
  --list-queries         Show all available query keys

  --partial-read         Enable partial file reading
  --start-line N         Start line (requires --partial-read)
  --end-line N           End line (requires --partial-read)
```

**IMPORTANT**: Accepts only a single file path, NOT a directory.

---

## uv run find-and-grep

```
uv run find-and-grep --roots <root1> [root2 ...] --query <pattern>
  # --roots takes SPACE-SEPARATED values (NOT comma-separated)

  --extensions <ext1> [ext2 ...]   File extensions to search (SPACE-SEPARATED)
  --output-format json|text|toon   Output format (default: json)
  --pattern PATTERN                Regex pattern (alternative to --query)
  --glob                           Treat query as glob pattern
  --case smart|insensitive|sensitive
  --depth N                        Max directory depth
  --context-before N               Lines before match
  --context-after N                Lines after match
  --max-count N                    Max matches per file
  --exclude <pattern>              Exclude file patterns
  --fixed-strings                  Literal string matching (no regex)
  --word                           Whole-word matching
```

**CRITICAL**: Both `--roots` and `--extensions` are space-separated:
```bash
# CORRECT
uv run find-and-grep --roots src packages libs --query "class.*Service" --extensions ts js
# WRONG (comma-separated — treated as single argument)
uv run find-and-grep --roots src,packages,libs --query "class.*Service" --extensions ts,js
```

---

## eslint (ESLint 9)

```
eslint <paths>
  --format json|stylish|...    Output format (default: stylish)
  --quiet                      Errors only (suppress warnings)
  --fix                        Auto-fix fixable issues in place
  --fix-dry-run                Preview fixes without writing (--format json)
  --max-warnings N             Exit non-zero if warnings exceed N
  --rule '{"rule": "error"}'   Inline rule (JSON format — NOT YAML "rule: error")
  -o, --output-file FILE       Write output to file

# ESLint 9 removals:
#   --ignore-pattern  REMOVED → use ignores in eslint.config.js instead:
#     export default [{ ignores: ["**/*.test.ts", "**/*.spec.ts"] }]
#   "compact" formatter  NOT built-in → use "stylish" or install eslint-formatter-compact
```
