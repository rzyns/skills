# rzyns/skills

Agent skills for [Claude Code](https://claude.ai/code) and other AI coding assistants.

## Install

```bash
npx skills add rzyns/skills
```

Install a specific skill:

```bash
npx skills add rzyns/skills --skill='code-intelligence'
```

## Skills

### `code-intelligence`

CLI-first code intelligence for TypeScript/JavaScript codebases. Provides on-demand access to semantic search, symbol indexing, blast-radius impact analysis, feature planning, and code quality auditing — using a CLI-first architecture that avoids loading MCP tool schemas until needed (~75% token reduction).

**Tools**: grepai, repomix, flyto-index, task-master, tree-sitter-analyzer, find-and-grep, eslint, Serena (MCP), code-graph-mcp (MCP)

**Use when**: navigating an unfamiliar codebase, searching for code by meaning, assessing blast radius before a refactor, planning features from a PRD, or auditing code quality.

## Structure

```
skills/
└── code-intelligence/
    ├── SKILL.md              # Main skill definition
    ├── references/           # Sub-skill reference files
    │   ├── bootstrap.md      # Tool installation and index setup
    │   ├── explore.md        # Orient on an unknown codebase
    │   ├── search.md         # Find code by meaning, name, or pattern
    │   ├── impact.md         # Blast-radius analysis before changes
    │   ├── plan.md           # Feature planning from PRDs
    │   ├── quality.md        # Code quality auditing
    │   └── tool-flags.md     # Verified CLI flag reference
    └── scripts/
        └── check-bootstrap.sh  # Bootstrap verification script
```
