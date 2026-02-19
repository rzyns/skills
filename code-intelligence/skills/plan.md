# Plan — Feature Planning from PRD or Brief

Use this skill when you have a product requirements document (PRD), feature brief, or written specification and need to convert it into a structured, dependency-ordered task list.

**Prerequisite**: `task-master init` has been run (`.taskmaster/` directory exists). See `skills/bootstrap.md` if not.

---

## Step 1: Write or Locate the PRD

Place your PRD in `.taskmaster/docs/`:

```bash
mkdir -p .taskmaster/docs
# Write or copy your PRD to:
# .taskmaster/docs/prd.md
```

The PRD should include: goals, user stories or requirements, constraints, and any technical notes.

---

## Step 2: Parse PRD into Tasks

```bash
# Let AI determine task count based on complexity
task-master parse-prd .taskmaster/docs/prd.md --num-tasks 0

# Or specify a target count
task-master parse-prd .taskmaster/docs/prd.md --num-tasks 15

# Append to existing tasks (for multi-PRD or phased projects)
task-master parse-prd .taskmaster/docs/feature-prd.md --append
```

This creates structured tasks in `.taskmaster/tasks/tasks.json`.

---

## Step 3: Analyze Complexity

```bash
# Score all tasks by complexity
task-master analyze-complexity

# View the report
task-master complexity-report
```

Expand high-complexity tasks into subtasks before starting implementation.

---

## Step 4: Expand Complex Tasks

```bash
# Expand a specific task into subtasks
task-master expand --id=5

# Control subtask count
task-master expand --id=5 --num=8

# Add context about your codebase
task-master expand --id=5 --prompt="We use Express.js, TypeScript, and Prisma ORM"

# Expand all pending tasks at once
task-master expand --all

# Expand with research-backed best practices (uses Perplexity)
task-master expand --id=5 --research
```

---

## Step 5: Validate Dependencies

```bash
# Check for cycles or invalid references
task-master validate-dependencies

# AI-powered repair if issues found
task-master fix-dependencies
```

---

## Step 6: Review and Adjust

```bash
# List all tasks with status
task-master list --with-subtasks

# Show a specific task
task-master show 5
task-master show 5.2   # subtask

# Add a task that was missed
task-master add-task --prompt="Add rate limiting to the auth endpoints"

# Remove a task that's not needed
task-master remove-task --id=7

# Add manual dependency (task 5 depends on task 3)
task-master add-dependency --id=5 --depends-on=3
```

---

## Step 7: Research Unknowns

Before starting implementation on uncertain areas:

```bash
# Research with fresh web data
task-master research "JWT refresh token rotation best practices TypeScript"

# Research with task context
task-master research "OAuth 2.0 PKCE implementation" --id=12,13

# Research informed by existing code files
task-master research "How to extend this auth system" \
  --files=src/auth/index.ts,src/middleware/auth.ts
```

---

## During Implementation

```bash
# Get the next task to work on (respects dependency chain)
task-master next

# Mark a task in progress
task-master set-status --id=3 --status=in-progress

# Mark done
task-master set-status --id=3 --status=done

# Mark multiple at once
task-master set-status --id=3.1,3.2,3.3 --status=done

# Add discovery notes to a subtask (non-destructive, timestamped)
task-master update-subtask --id=3.2 \
  --prompt="Rate limiting must be applied at the gateway, not handler level"

# Update future tasks when implementation diverges from plan
task-master update --from=8 \
  --prompt="We're using Redis for session storage instead of in-memory"
```

---

## Task Data Format

Tasks are stored as plain JSON — directly readable:

```bash
cat .taskmaster/tasks/tasks.json
```

```json
{
  "tasks": [
    {
      "id": 1,
      "title": "Implement authentication middleware",
      "description": "...",
      "status": "pending",
      "priority": "high",
      "dependencies": [2, 3],
      "subtasks": [
        { "id": 1, "title": "Write JWT validation logic", "status": "pending" }
      ]
    }
  ]
}
```

---

## Planning Workflow Summary

1. `task-master parse-prd prd.md` → generate tasks
2. `task-master analyze-complexity` → identify complex tasks
3. `task-master expand --all` → break down complex tasks
4. `task-master validate-dependencies` → verify ordering
5. `task-master research "<unknowns>"` → fill knowledge gaps
6. `task-master next` → start implementation
7. `task-master update-subtask` / `task-master update` → keep plan in sync with reality
