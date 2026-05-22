# Usage Guide

A practical manual for every feature in vibe-skill — the multi-harness AI coding delegation framework.

---

## Quick Start

### Install

The tools live at `~/tools/`. No install step beyond cloning the repo and ensuring the scripts are executable:

```bash
ls ~/tools/delegate            # should exist
chmod +x ~/tools/delegate*     # make executable if needed
```

### Your first delegation

```bash
# Delegate a coding task to Vibe (default harness)
/vibe "Add a health check route to app.py that returns 200 OK"

# Or call the tool directly:
~/tools/delegate vibe /path/to/project "Add a health check route to app.py that returns 200 OK"
```

### Check the result

The script prints live output and ends with a diff summary:

```
=== DELEGATE DONE [vibe] (exit: 0) ===
=== SYNTAX OK (1 check(s)) ===

=== UNCOMMITTED CHANGES ===
 app.py | 5 +++++
[log] → ~/.local/share/delegate-runs.jsonl  (4800 tokens, exit 0, 34.2s, saved ~$0.0082 vs Claude)
```

All changes are left unstaged. Review with `git diff`, then `git add` and commit manually.

---

## Core Delegation

### Basic delegation (`/vibe` or `/delegate`)

Delegates a coding task to an AI harness. The orchestrator writes a self-contained prompt, runs the harness, reviews the diff, and reports.

**Single task:**

```bash
/vibe "In fetch_data() in app.py, convert the date string to datetime.date before returning"
```

**With a specific harness:**

```bash
/delegate vibe "Add docstrings to all functions in utils.py"
/delegate pi "Fix the broken import on line 3 of auth.py"
/delegate opencode "Add error handling to the API route in routes.py"
```

**Direct script invocation:**

```bash
~/tools/delegate <harness> <workdir> "<prompt>" [max-turns] [agent] [timeout-secs]

# Examples:
~/tools/delegate vibe /path/to/project "Add a logout route" 8
~/tools/delegate vibe /path/to/project "Review the auth module for security issues" 5 code-reviewer
~/tools/delegate vibe /path/to/project "Plan the database migration approach" 5 planner
```

**Available agents:**

| Agent | Purpose |
|-------|---------|
| *(default)* | General implementation — writes code |
| `code-reviewer` | Read-only review — no file changes |
| `planner` | Creates a plan before implementation |
| `code-architect` | Architecture design, read-only |

**Max turns guidance:**

| Task size | Max turns |
|-----------|-----------|
| Read/explore only | 5 |
| Simple (1 file, obvious change) | 8 |
| Medium (2–3 files) | 12 |
| Never exceed 12 | Decompose instead |

**Tips:**
- Write prompts as imperatives: "Add X to Y" not "Can you add X?"
- Include exact file names and stack context in the prompt
- One task per prompt — "also do Y" degrades quality significantly
- For trivial 1-file changes where the location is obvious, do it directly — delegation has setup overhead

---

### Auto-mode (`/vibeon`, `/vibeoff`, `/vibestatus`)

Auto-mode makes the orchestrator automatically delegate all coding tasks without requiring `/vibe` each time.

| Command | What it does |
|---------|--------------|
| `/vibeon` | `touch ~/.local/share/vibe-auto.flag` — enables auto-delegation |
| `/vibeoff` | `rm -f ~/.local/share/vibe-auto.flag` — disables |
| `/vibestatus` | Reports auto-mode state and active model override |

**Example `/vibestatus` output:**

```
Auto-vibe: ON
Model: deepseek-flash  (config default)
```

**Gotcha:** Even with auto-mode on, questions and analysis stay with the orchestrator. Delegation only happens when the user's message implies file changes. "What does fetch_data() do?" is answered directly. "Add error handling to fetch_data()" triggers delegation.

---

### Model selection (`/vibe-model-pick`, `/vibe-model-clear`)

Override the Vibe model for all subsequent delegations without editing `~/.vibe/config.toml`. The override persists across turns via a flag file.

```bash
/vibe-model-pick deepseek-flash      # fast and cheap (default)
/vibe-model-pick mistral-medium-3.5  # stronger reasoning
/vibe-model-pick devstral-small      # lighter Mistral model
/vibe-model-pick local               # local server on :8080

/vibe-model-clear                    # back to config default
```

**Available aliases:**

| Alias | Model | Notes |
|-------|-------|-------|
| `deepseek-flash` | deepseek-v4-flash | Default — fast, cheap |
| `mistral-medium-3.5` | mistral-vibe-cli-latest | Stronger reasoning |
| `devstral-small` | devstral-small-latest | Lighter Mistral |
| `local` | devstral (llamacpp) | Requires local server on :8080 |

**How it works:** writes the alias to `~/.local/share/delegate-model.flag` (or the legacy `vibe-model.flag`). The `delegate` script reads this file and exports `VIBE_ACTIVE_MODEL` before invoking the adapter.

**Gotcha:** If the model override is not taking effect, check both flag files:
```bash
cat ~/.local/share/delegate-model.flag
cat ~/.local/share/vibe-model.flag
```

---

## Harness Adapters

### Vibe (Mistral)

The primary harness. Runs Mistral's Vibe CLI to do the actual coding.

**How it works:** The adapter allocates a pseudo-TTY via `script` (macOS: `script -q /dev/null "..."`, Linux: `script -q -c "..." /dev/null`), streams JSON output, parses tool calls, and extracts token counts from Mistral's session log.

**TTY requirement:** Vibe checks for a TTY on startup. Without one it hangs silently — 0 tool calls, no output, then times out. The delegate adapter handles this automatically. Never call Vibe directly in a pipe.

**Known quirks:**

| Issue | Cause | Fix |
|-------|-------|-----|
| `search_replace [FAIL]` | Accented chars or emoji in match string | Use `python3 str.replace()` for UTF-8 content |
| Duplicated code at end of file | Off-by-one in Vibe's diff logic | Read diff, delete duplicate manually |
| Context loops above ~12 turns | Mistral context fills up | Hard cap at 12 turns — decompose the task |
| Merge conflict markers left in file | `search_replace` on previously edited files | `grep -n "=======" file` after any run |

---

### Pi (earendil-works)

**Status:** Stub adapter — interface defined, full implementation pending Pi CLI investigation.

**Install:**
```bash
npm i -g @earendil-works/pi-coding-agent
```

**How it works (planned):** `pi --mode json -p "prompt"`

---

### OpenCode (opencode-ai)

**Status:** Stub adapter — interface defined, full implementation pending OpenCode CLI investigation.

**Install:** https://opencode.ai/docs/

**How it works (planned):** `opencode run --format json --dir <dir> --dangerously-skip-permissions "prompt"`

---

## Quality Gates

Every delegation automatically runs these after the harness exits.

### Syntax checking (automatic)

Runs language-specific syntax checks on every modified file. No configuration needed.

| Language | Tool |
|----------|------|
| Python | `python3 -m py_compile` |
| JavaScript/Node | `node --check` |
| Ruby | `ruby -c` |
| Bash | `bash -n` |
| PHP | `php -l` |
| JSON | `python3 json.load()` |
| Go | `go vet ./...` |
| Rust | `cargo check --quiet` |
| TypeScript | `tsc --noEmit --skipLibCheck` |

**Example output:**

```
=== SYNTAX OK (2 check(s)) ===
```

or:

```
=== SYNTAX ERRORS: 1 in 2 check(s) — fix before committing ===
  [SYNTAX ERROR] app.py: SyntaxError: invalid syntax (app.py, line 42)
```

**Gotcha:** Fix syntax errors before committing. If the harness produced a syntax error, the rollback checkpoint is preserved for easy recovery.

---

### AST validation

Deeper semantic validation beyond syntax — catches shadowed variables, changed function signatures, undefined functions.

```bash
~/tools/delegate-ast-check /path/to/project
```

Run manually after any run that modifies core logic files.

---

### Duplicate detection (automatic)

Runs automatically after every delegation. Catches Vibe's known code-duplication bug: same function defined twice, repeated blocks, merge conflict markers, reverted imports.

```bash
# Run manually:
~/tools/delegate-check-duplicates /path/to/project
```

**Example output:**

```
[DUP] app.py: function 'fetch_data' defined at lines 42 and 87
[DUP] routes.py: merge conflict markers detected (line 15)
```

---

### Delegation contracts

Machine-verifiable pre/post conditions. Pre-conditions block delegation if they fail. Post-conditions trigger auto-correction if they fail.

**Creating a contracts file:**

```bash
mkdir -p /path/to/project/.delegate
cat > /path/to/project/.delegate/contracts.yaml << 'EOF'
contract:
  pre:
    - "grep -q 'def fetch_data' app.py"
    - "python3 -m py_compile app.py"
  post:
    - "grep -q 'datetime.date' app.py"
    - "python3 -m py_compile app.py"
    - "python3 -m pytest tests/test_app.py -x -q"
  timeout: 30
EOF
```

**Running contracts manually:**

```bash
~/tools/delegate-contracts pre /path/to/project
~/tools/delegate-contracts post /path/to/project

# With a custom contract file:
~/tools/delegate-contracts pre /path/to/project /path/to/custom-contracts.yaml
```

**Example output:**

```
=== CONTRACT PRE (2 checks) ===
  [PASS] grep -q 'def fetch_data' app.py
  [PASS] python3 -m py_compile app.py
=== CONTRACT PRE PASSED (2/2) ===
```

**Automation levels:**

| Level | Behavior |
|-------|----------|
| No contracts | Orchestrator reviews every diff manually |
| Contracts defined | Mechanical checks run first; orchestrator reviews only if all pass |
| Contracts + `/vibeon` | Fully automated for routine tasks |

**Gotcha:** Contracts run automatically when `.delegate/contracts.yaml` exists. Failed pre-conditions abort the run entirely. Failed post-conditions trigger a correction round.

---

## Rollback & Correction

### Rollback checkpoints

A throwaway git branch is created before every delegation. If the result is bad, roll back cleanly.

```bash
# Create manually (delegate does this automatically):
~/tools/delegate-rollback create /path/to/project
# → prints: delegate-checkpoint-1748000000

# Roll back to checkpoint (undoes all changes since checkpoint):
~/tools/delegate-rollback rollback /path/to/project delegate-checkpoint-1748000000

# Accept changes and clean up checkpoint:
~/tools/delegate-rollback accept /path/to/project delegate-checkpoint-1748000000

# Clean up stale checkpoints older than 1 hour:
~/tools/delegate-rollback cleanup /path/to/project
```

**How it works:** `create` runs `git branch delegate-checkpoint-<timestamp>` at the current HEAD. `rollback` runs `git reset --hard <checkpoint-sha>`. On a successful run with no syntax errors, the checkpoint is auto-deleted. On failure, it's preserved and the path is printed.

**Gotcha:** Checkpoints are git branches — they show up in `git branch`. Use `cleanup` periodically to remove stale ones.

---

### Reject-and-correct loop

When the harness output has fixable issues, send a targeted correction back rather than re-running from scratch. Max 2 correction rounds before escalating.

**How it works:**

1. Delegate runs and produces a diff
2. Orchestrator identifies a specific error
3. Correction prompt is written to `.delegate/correction-prompt.txt`
4. On the next delegate invocation, the correction is picked up and run with 3 turns

**Writing a correction:**

```bash
~/tools/delegate-reject /path/to/project "The import on line 3 is wrong. Change 'from utils import foo' to 'from app.utils import foo'. Do not touch anything else."
```

**Then re-run the original delegation** — the correction file is picked up automatically:

```bash
~/tools/delegate vibe /path/to/project "<original prompt>"
```

**Example output with correction:**

```
=== CORRECTION ROUND 1/2 ===
Correction: The import on line 3 is wrong...
=== CORRECTION APPLIED ===
```

**Tips:**
- Keep correction prompts minimal — just the error and the fix, not a full task restatement
- After 2 failed corrections, escalate to the user rather than fixing it yourself
- The orchestrator should never write code itself during a delegation flow — corrections only

---

## Context & Intelligence

### Context distillation

Analyzes a project and generates `.delegate/project-brief.md` — a compressed summary of the stack, key files, data models, conventions, and gotchas. Injected automatically into every delegation prompt.

```bash
~/tools/delegate-distill /path/to/project
# → generates .delegate/project-brief.md
# → updates .gitignore to exclude .delegate/
```

**Example brief output:**

```markdown
# Project Brief — myapp
# Generated: 2026-05-22T14:30:00Z | Regenerate: delegate-distill /path/to/myapp

## Stack
Flask (Python)
Entry: app.py
Package: pip (requirements.txt)

## Key Files
- app.py — entry point — app.py
- models.py — model/schema
- routes/auth.py — route/handler

## Data Models
- User: id, email, pw_hash
- Entry: id, user_id, title, body

## Conventions
- Naming: snake_case
- Structure: flat
- Linting: none detected

## Gotchas
- no test files detected
```

**How invalidation works:** The brief stores hashes of the manifest file, entry point, and model files. If none of those have changed, re-running `delegate-distill` prints "Brief is current, no changes" and exits.

**Tip:** Run `delegate-distill` once per project. Re-run only after significant structural changes (new models, new routes, package changes).

---

### Failure memory

Records failures and their fixes. Before each delegation, relevant warnings are injected into the prompt automatically.

```bash
# Record a failure:
~/tools/delegate-failures record /path/to/project vibe search_replace_fail \
  "UTF-8 content caused match failure" \
  "used python3 str.replace() instead" \
  app.py

# Query relevant failures before a delegation:
~/tools/delegate-failures query /path/to/project app.py models.py

# Remove entries older than 30 days:
~/tools/delegate-failures prune
```

**Example query output:**

```
[failure-memory] 2 relevant warning(s) for this delegation:
  ⚠ search_replace_fail in app.py: UTF-8 content caused match failure
    Fix: used python3 str.replace() instead
  ⚠ duplicate_code: Vibe re-inserted fetch_data() after a prior run
    Fix: grep for duplicates before committing
```

**Storage:** `~/.local/share/delegate-failures.jsonl`. Entries auto-expire after 30 days on `prune`.

**Gotcha:** Harness-wide failures (no file specified) are always shown, regardless of which files you're modifying.

---

### Learning loop

Captures patterns from correction rounds (when the harness output needed fixing) and generates prompt improvement suggestions.

```bash
# Record a learning (called after a correction round):
~/tools/delegate-learnings record /path/to/project vibe \
  "Add error handling to routes" \
  /tmp/correction.diff

# Analyze correction patterns:
~/tools/delegate-learnings analyze --harness vibe --since 7

# Get prompt improvement suggestions:
~/tools/delegate-learnings suggest vibe
```

**Example `analyze` output:**

```
=== LEARNING ANALYSIS (12 corrections, last 7 days) ===

Corrections by harness:
  vibe: 12

Correction types:
  missing_import: 5 (42%)
  duplicate_removal: 3 (25%)
  minor_fix: 2 (17%)
  conflict_resolution: 2 (17%)

Most corrected files:
  app.py: 4 corrections
  auth.py: 3 corrections
```

**Example `suggest` output:**

```
=== PROMPT SUGGESTIONS FOR VIBE ===

Based on recent correction patterns, add these to your prompts:

  [42% of corrections] CONSTRAINT: After adding any new function call, verify the import exists at the top of the file.
  [25% of corrections] CONSTRAINT: Before writing any function, grep the file to confirm it doesn't already exist.
```

**Storage:** `~/.local/share/delegate-learnings.jsonl`

---

### Harness routing

Analyzes run history to recommend which harness performs best for a given task type. Requires at least 3 runs per harness/task-type combination before giving recommendations (cold start defaults to `vibe`).

```bash
# Classify a task description into a type:
~/tools/delegate-router classify "add a login page"
# → greenfield

# Recommend the best harness:
~/tools/delegate-router recommend "fix the auth bug"
# Task type: bugfix
# Recommended harness: vibe
#
# Reasoning:
#   vibe: 85% success, avg $0.008, avg 45s (7 runs) *
#   pi: insufficient data (1 run)
#   opencode: no data

# Show the full routing table (last 30 days):
~/tools/delegate-router table --since 30

# Or with custom time window:
~/tools/delegate-router table --since 7
```

**Example routing table:**

```
            vibe                    pi
            runs  ok%  cost  dur   runs  ok%  cost  dur
----------------------------------------------------------------------------
greenfield     5  80% .008   45s      0    -     -     -
bugfix         7  85% .007   42s      1    -     -     -
docs           3 100% .004   28s      0    -     -     -
```

**Task types recognized:** `refactor`, `bugfix`, `test`, `docs`, `greenfield`, `modification`, `removal`, `frontend`, `api`, `database`, `general`

**Gotcha:** Routing is based on keyword matching in the task description. "fix the broken login" → `bugfix`. "add a login page" → `greenfield`. When in doubt, use `classify` first to see what type the router assigns.

---

## Advanced Features

### Parallel delegation

Runs multiple independent tasks simultaneously, each in its own git worktree. Tasks that share files are automatically detected and run sequentially within their group.

```bash
# Create a tasks file (one task per line, format: <prompt> | <files>):
cat > /tmp/tasks.txt << 'EOF'
Add logout route | auth.py,routes.py
Add search bar | search.py
Add dark mode CSS | static/style.css
EOF

~/tools/delegate-parallel /path/to/project /tmp/tasks.txt vibe
```

**Example output:**

```
=== PARALLEL DELEGATION ===
Tasks   : 3
Harness : vibe
Workdir : /path/to/project
===========================

Parallel groups: 3
  Group task-1: independent
  Group task-2: independent
  Group task-3: independent

Dispatched group task-1 (PID 12345) in worktree /tmp/delegate-parallel-12345/task-1
...

Waiting for 3 group(s)...
  Group task-1: completed (PID 12345)
  Group task-2: completed (PID 12346)
  Group task-3: completed (PID 12347)

=== MERGING RESULTS ===
  Group task-1: merged successfully
  Group task-2: merged successfully
  Group task-3: merged successfully

=== PARALLEL COMPLETE — all 3 group(s) merged ===
```

**How file conflict detection works:** If two tasks list the same file, they're grouped and run sequentially in the same worktree. Independent tasks run in parallel as background processes.

**Gotcha:** Each task uses default settings (10 turns, 180s timeout). Large tasks may need individual tuning — run them with `/vibe` directly instead.

---

### Smart batching

For bulk tasks like "add docstrings to all functions," groups files intelligently and runs one delegation per batch (up to 3 files per batch). Estimates cost before starting.

```bash
~/tools/delegate-batch /path/to/project "add docstrings to all functions in src/" vibe
```

**Example output:**

```
=== SMART BATCH DELEGATION ===
Workdir : /path/to/project
Harness : vibe
Prompt  : add docstrings to all functions in src/...

Found 9 target file(s):
  src/auth.py
  src/models.py
  src/routes.py
  ... and 6 more

Batches: 3 (max 3 files each)
Estimated cost: ~$0.0270
========================================

--- Batch 1/3: src/auth.py, src/models.py, src/routes.py ---
...

=== BATCH COMPLETE ===
Succeeded: 3/3
```

**Tip:** Use batching for uniform bulk operations — docstrings, type hints, logging statements. Not suited for tasks that require cross-file context (use a chain instead).

---

### Delegation chains

Multi-step workflows where each step's output feeds the next. Select a chain with `/vibe-mode` (or `$vibe-mode` in Codex):

```
/vibe-mode steady      — SOTA plans → MiniMax implements → GLM validates
/vibe-mode quick       — MiniMax implements → GLM reviews (no SOTA planning)
/vibe-mode fix         — SOTA investigates → MiniMax fixes → GLM validates
/vibe-mode race        — two models compete (no SOTA planning)
/vibe-mode fortress    — SOTA plans → implement → test → security
/vibe-mode ironclad    — fortress + final review (5 steps)
/vibe-mode architect   — SOTA plans → implement → validate
/vibe-mode tournament  — 4 workers race, GLM judges
/vibe-mode simple      — direct delegation, no chain
```

All chains use `harness: codex` with profiles `minimax` (MiniMax-M2.7) and `glm` (glm-5.1). All chains with a planning step use `sota: true` — the orchestrator (Claude/Codex) analyzes the codebase, writes a detailed plan to `.delegate/plan.md`, and passes it to the cheap implementation model.

```bash
# Use a pre-built chain with DELEGATE_CHAIN_TASK env var:
DELEGATE_CHAIN_TASK="add user authentication" \
  ~/tools/delegate-chain /path/to/project .delegate/chains/steady.yaml

# Or pass the task as an argument:
~/tools/delegate-chain /path/to/project .delegate/chains/fix.yaml codex "fix the broken login redirect"
```

**Available built-in chains:**

| Chain file | Steps |
|------------|-------|
| `.delegate/chains/steady.yaml` | SOTA plan → MiniMax implement → GLM validate |
| `.delegate/chains/quick.yaml` | MiniMax implement → GLM review |
| `.delegate/chains/fix.yaml` | SOTA investigate → MiniMax fix → GLM validate |
| `.delegate/chains/race.yaml` | two models compete on same task |
| `.delegate/chains/fortress.yaml` | SOTA plan → implement → test → security |
| `.delegate/chains/ironclad.yaml` | SOTA plan → implement → test → security → final review |
| `.delegate/chains/architect.yaml` | SOTA plan → MiniMax implement → GLM validate |
| `.delegate/chains/tournament.yaml` | 4 workers race (2 MiniMax + 2 GLM), GLM judges |

**Example chain file format:**

```yaml
name: steady
description: Think first, then build, then check
harness: codex

steps:
  - role: planner
    agent: code-architect
    turns: 5
    prompt_template: "Plan the implementation for: {task}"

  - role: implementor
    agent: default
    turns: 12
    prompt_template: "Implement the following: {task}"

  - role: validator
    agent: code-reviewer
    turns: 5
    prompt_template: "Review the implementation for: {task}"
```

**Example output:**

```
############################################################
# DELEGATE CHAIN: steady
# Task          : add user authentication
# Steps         : 3
############################################################

============================================================
CHAIN STEP 1/3: planner
  Agent  : code-architect
  Turns  : 5
...

============================================================
CHAIN SUMMARY: steady
  Total duration : 187.3s
  Status         : SUCCESS

  Step              Exit    Duration
  ----------------  ----  ----------
  planner             OK       52.1s
  implementor         OK      108.7s
  validator           OK       26.5s
============================================================
```

**Gotcha:** Each step gets the git diff stat from the previous step as context. If a step fails, the chain aborts and reports which step failed.

---

### Session replay

Records and replays the full harness session — every tool call, file read, edit decision — for debugging failed runs.

```bash
# Replay a session file:
~/tools/delegate-replay ~/.local/share/delegate-sessions/2026-05-22T14-30-00Z.jsonl

# Jump to a specific turn:
~/tools/delegate-replay <session-file> --turn 3

# Show only error-related events:
~/tools/delegate-replay <session-file> --errors
```

**Example replay output:**

```
=== REPLAY: /home/user/.local/share/delegate-sessions/2026-05-22T14-30-00Z.jsonl (24 events) ===

Turn 1:
  [think] I need to find the fetch_data function in app.py

  [read]  app.py

Turn 2:
  [think] I need to convert date_str to datetime.date and id to str

  [edit]  search_replace [OK]
          - date_str = row['date']
          + date_obj = datetime.date.fromisoformat(row['date'])
```

**Session files** are stored at `~/.local/share/delegate-sessions/<timestamp>.jsonl` and linked from the run log via the `session_file` field.

**Tip:** Use `--errors` to jump straight to the turn where things went wrong, then use `--turn N` to inspect that turn in detail.

---

### SOTA Planning (architect mode)

All chains that include a planning step use `sota: true`. The orchestrator (Claude/Codex) handles planning, writes a detailed plan to `.delegate/plan.md`, and the downstream cheap models follow it exactly.

```bash
# Set architect mode
/vibe-mode architect

# Now when you say:
/vibe add user authentication with JWT

# Claude/Codex:
# 1. Analyzes the codebase
# 2. Writes a detailed plan to .delegate/plan.md
# 3. Runs delegate-chain with architect.yaml
# 4. MiniMax follows the plan exactly
# 5. GLM validates against the plan
```

The `steady`, `fix`, `fortress`, `ironclad`, and `architect` chains all include SOTA planning steps. The `quick`, `race`, and `tournament` chains do not.

---

### Knowledge Base

Auto-injected project context that travels with every delegation prompt. SOTA writes the first version for accuracy; subsequent updates use a cheap model.

```bash
# Initialize (SOTA writes the first version — important for accuracy)
python3 .claude/vibe-skill/tools/delegate-knowledge init .

# Update (cheap model rewrites based on current code)
python3 .claude/vibe-skill/tools/delegate-knowledge update .

# Or use the slash command:
/vibe-reindex

# View current knowledge:
python3 .claude/vibe-skill/tools/delegate-knowledge show .
```

The knowledge base is stored at `.delegate/knowledge.md` and auto-injected into every delegation prompt. After 5 delegations without a knowledge update, the system prints a staleness reminder.

---

### Background Audit

Read-only scan of all project files for security, quality, and correctness concerns. Results are stored and can be acted on at any time.

```bash
# Scan all files (read-only, finds concerns)
/vibe-audit scan

# Show findings
/vibe-audit

# Or directly:
python3 .claude/vibe-skill/tools/delegate-audit scan .
python3 .claude/vibe-skill/tools/delegate-audit list .
python3 .claude/vibe-skill/tools/delegate-audit stats .

# Act on findings:
python3 .claude/vibe-skill/tools/delegate-audit resolve . <finding-id>
python3 .claude/vibe-skill/tools/delegate-audit dismiss . <finding-id>
python3 .claude/vibe-skill/tools/delegate-audit prune .
```

Findings are stored at `.delegate/audit-findings.jsonl`. Use `resolve` after fixing an issue, `dismiss` to permanently ignore a false positive, and `prune` to remove resolved/dismissed entries.

---

### Continuous Research

Deep web research using JINA for arxiv papers, CVE advisories, and best practices relevant to the project's stack.

```bash
# Deep web research (uses JINA for arxiv, CVEs, best practices)
/vibe-research scan

# Show findings with sources
/vibe-research

# Or directly:
python3 .claude/vibe-skill/tools/delegate-research scan .
python3 .claude/vibe-skill/tools/delegate-research list .
python3 .claude/vibe-skill/tools/delegate-research apply . <finding-id>
python3 .claude/vibe-skill/tools/delegate-research dismiss . <finding-id>
```

Findings are stored at `.delegate/research-findings.jsonl`. Use `apply` to act on a finding (delegates implementation to the chain), `dismiss` to mark as not applicable.

---

### Scheduler

Runs audit, research, and knowledge-update agents on a recurring schedule in the background.

```bash
# Start continuous agents (audit every 30m, research every 2h, knowledge every 1h)
/vibe-scheduler start

# Check status
/vibe-scheduler status

# Stop
/vibe-scheduler stop

# View/edit config:
cat .delegate/scheduler.yaml
```

Default `.delegate/scheduler.yaml`:

```yaml
# Scheduler configuration — how often each agent runs (in minutes)
# Set interval to 0 to disable a job

audit:
  interval: 30
  model: minimax/MiniMax-M2.7

research:
  interval: 120
  model: glm/glm-5.1

knowledge_update:
  interval: 60
  model: minimax/MiniMax-M2.7
```

Edit `interval` values to tune frequency. Set `interval: 0` to disable a job entirely.

---

### Parallel Workers (tournament mode)

Four workers implement the same task independently in parallel git worktrees. GLM judges all four diffs and merges the winner.

```bash
/vibe-mode tournament
/vibe add a search feature

# What happens:
# 1. 4 workers (2 MiniMax, 2 GLM) race in parallel git worktrees
# 2. Each implements the same task independently
# 3. GLM 5.1 judges all 4 diffs, picks the winner
# 4. Winner's code is merged, losers discarded
```

**tournament.yaml format:**

```yaml
name: tournament
description: 4 models race on implementation, GLM judges the winner

steps:
  - role: implementor
    turns: 0
    prompt_template: "Implement: {task}\n\nWrite clean, working code. Follow existing conventions."
    parallel:
      workers:
        - harness: codex
          model: minimax/MiniMax-M2.7
        - harness: codex
          model: minimax/MiniMax-M2.7
        - harness: codex
          model: glm/glm-5.1
        - harness: codex
          model: glm/glm-5.1
      judge:
        harness: codex
        model: glm/glm-5.1
```

To create a custom parallel chain, use the same `parallel.workers` / `parallel.judge` structure in any chain YAML file.

---

### Codex as delegate harness

Codex can serve two distinct roles in the delegation pipeline:

**Orchestrator role:** Codex runs the show — reads user intent, writes delegation prompts, calls `$vibe`/`$delegate`, reviews diffs, runs corrections. Use `CODEX-SKILL.md` (installed at `.codex/AGENTS.md`) to give Codex its orchestration instructions.

**Delegate role:** The `tools/adapters/codex` adapter calls `codex exec` with named model profiles (`minimax`, `glm`). When a chain step specifies `harness: codex`, the adapter is invoked with the appropriate `model` profile, which maps to a Codex exec target.

This means the same `delegate-chain` script works whether Claude Code or Codex is the top-level orchestrator — the chain steps always delegate down to `codex exec` with cheap models.

---

## Monitoring & Reporting

### Live dashboard

Shows a point-in-time summary of all delegation activity.

```bash
~/tools/delegate-dashboard                    # one-shot snapshot
~/tools/delegate-dashboard --refresh 10       # auto-refresh every 10s
~/tools/delegate-dashboard --project myapp    # filter by project name
```

**Example output:**

```
============================================================
  DELEGATE DASHBOARD
  2026-05-22 14:30:00 UTC
============================================================

  SUMMARY
  Total runs:        47
  Success rate:      89%
  Total cost:        $0.3821
  Claude equivalent: $0.7644
  Total saved:       $0.3823
```

---

### Run reports

Historical token/cost/failure report from the run log.

```bash
~/tools/delegate-report                       # full report (all time)
~/tools/delegate-report --since 7             # last 7 days
~/tools/delegate-report --project myapp       # filter by project
~/tools/delegate-report --fails               # failures only (with benchmark table)
```

Or via Claude Code:
```bash
/vibe-report
/vibe-report last 7 days
/vibe-report project myapp
/vibe-report only failures
```

**Example full report output:**

```
========================================================
  DELEGATE REPORT  2026-05-01 → 2026-05-22
========================================================
  Runs          : 47  (ok: 42, failed: 5, timeout: 1)
  Success rate  :  89%
  Avg duration  : 41.2s
  Tokens total  : 224,800
  Delegate cost : $0.3821
  Claude equiv  : $0.7644
  Saved         : $0.3823  (50% cheaper than Claude)
  --- bugs/warns ---
  Warnings      : 3
  SR failures   : 2
  Syntax errors : 1
  Wrote nothing : 1  (prompt too vague or task already done)

BY MODEL
Model               Runs  OK%    Tokens    Cost  Claude eq  Saved%  Warns  SR fails
------------------------------------------------------------------------------------
deepseek-flash        40   90%  192,000  $0.32     $0.65     51%      2        1
mistral-medium-3.5     7   86%   32,800  $0.06     $0.11     45%      1        1

BY PROJECT
Project          Runs  OK%     Cost   Saved  Warns  SR fails
--------------------------------------------------------------------
myapp              28   89%  $0.2140  $0.2280      2        2
api-service        19   89%  $0.1681  $0.1543      1        0
```

---

### Raw JSONL queries

The run log at `~/.local/share/delegate-runs.jsonl` supports direct `jq` queries.

```bash
# Success rate:
jq -r '.exit_code' ~/.local/share/delegate-runs.jsonl | sort | uniq -c

# Total cost vs Claude equivalent:
jq -r '[.cost_usd, .cost_claude_eq] | @tsv' ~/.local/share/delegate-runs.jsonl \
  | awk '{c+=$1; e+=$2} END {printf "Spent: $%.4f  Claude eq: $%.4f  Saved: $%.4f\n", c, e, e-c}'

# Runs with search_replace failures:
jq 'select(.search_replace_fails > 0)' ~/.local/share/delegate-runs.jsonl

# Most recent run:
tail -1 ~/.local/share/delegate-runs.jsonl | jq .

# Average duration by model:
jq -r '[.model, .duration_secs] | @tsv' ~/.local/share/delegate-runs.jsonl \
  | awk '{sum[$1]+=$2; n[$1]++} END {for (m in sum) printf "%s: %.1fs avg\n", m, sum[m]/n[m]}'
```

**Key fields in the run log:**

| Field | Description |
|-------|-------------|
| `ts` | ISO 8601 UTC timestamp |
| `harness` | `vibe`, `pi`, or `opencode` |
| `project` | `basename(workdir)` |
| `exit_code` | 0=success · 124=timeout · other=error |
| `tokens_total` | Total Mistral tokens consumed |
| `cost_usd` | Actual delegate cost |
| `cost_claude_eq` | What the same tokens would cost on Claude Sonnet 4.6 |
| `warn_count` | Non-fatal `[WARN]` events during run |
| `search_replace_fails` | Count of `search_replace [FAIL]` events |
| `wrote_nothing` | True if harness ran 3+ tool calls but changed 0 files |
| `correction_rounds` | Reject-correct cycles (0 = accepted first try) |
| `final_disposition` | `accepted`, `corrected`, or `correction_failed` |
| `contract_post_pass` | Whether post-condition contracts passed |
| `session_file` | Path to replay session file |
| `checkpoint` | Rollback checkpoint branch name |

---

## Tools Reference

All scripts live at `tools/` (symlinked to `~/tools/` on install). The full list:

| Tool | Purpose |
|------|---------|
| `delegate` | Core delegation — invokes a harness adapter |
| `delegate-chain` | Multi-step chains (steady, fix, architect, tournament, etc.) |
| `delegate-parallel` | Parallel tasks across independent git worktrees |
| `delegate-batch` | Smart batching for bulk uniform operations |
| `delegate-knowledge` | Project knowledge base — init, update, show |
| `delegate-audit` | Background code audit — scan, list, stats, resolve, dismiss, prune |
| `delegate-research` | Continuous web research — scan, list, apply, dismiss |
| `delegate-scheduler` | Runs audit/research/knowledge on a cron schedule |
| `delegate-distill` | Context distillation — generates `.delegate/project-brief.md` |
| `delegate-failures` | Failure memory — record, query, prune |
| `delegate-learnings` | Learning loop — record, analyze, suggest |
| `delegate-router` | Harness routing — classify, recommend, table |
| `delegate-contracts` | Pre/post condition contracts — pre, post |
| `delegate-rollback` | Checkpoint management — create, rollback, accept, cleanup |
| `delegate-reject` | Write a correction prompt for a rejection loop |
| `delegate-replay` | Replay a session file for debugging |
| `delegate-dashboard` | Live activity dashboard |
| `delegate-report` | Historical token/cost/failure report |
| `delegate-ast-check` | Deep AST validation beyond syntax |
| `delegate-check-duplicates` | Duplicate code detection |
| `vibe-delegate` | Vibe-specific delegation wrapper |

---

## Codex Integration

Codex can act as the orchestrator instead of Claude Code — it delegates to the same harnesses (`vibe`, `pi`, `opencode`, `codex`) using the same `~/tools/delegate` scripts.

The delegation scripts are orchestrator-agnostic. The `delegate-runs.jsonl` log is shared, so `/vibe-report` and `delegate-dashboard` show runs from both Claude Code and Codex sessions.

**Codex dual role:** Codex can be both orchestrator AND delegate:
- As **orchestrator**: runs the show via `$vibe`/`$delegate` commands, reads user intent, writes delegation prompts, reviews diffs
- As **delegate**: the `tools/adapters/codex` adapter calls `codex exec` with named model profiles (`minimax` → MiniMax-M2.7, `glm` → GLM-5.1), enabling chains where Claude/Codex orchestrates cheap Codex delegates

### Installation

Install into your project's `.codex/` directory — does NOT overwrite any existing `AGENTS.md`:

```bash
mkdir -p <project>/.codex
cp ~/projects/vibe-skill/CODEX-SKILL.md <project>/.codex/AGENTS.md
```

Codex walks from repo root to CWD and concatenates all `AGENTS.md` files, so `.codex/AGENTS.md` is appended to the root one.

See `CODEX-SKILL.md` for the full Codex-specific invocation format.

---

## Troubleshooting

### Common issues

**"vibe hangs silently, no output"**
→ TTY issue. The delegate adapter handles this automatically via `script`. If calling Vibe directly, you're missing the TTY allocation. Always go through `~/tools/delegate`.

**"`search_replace [FAIL]`"**
→ The match string contains UTF-8 characters (accented chars, curly quotes, emoji) that don't match byte-for-byte. Edit manually with `python3 str.replace()`. This only applies to actual non-ASCII content — plain Python code works fine with `search_replace`.

**"pi/opencode not found"**
→ Install the CLI first. Pi: `npm i -g @earendil-works/pi-coding-agent`. OpenCode: https://opencode.ai/docs/

**"Model override not working"**
→ Check both flag files: `cat ~/.local/share/delegate-model.flag` and `cat ~/.local/share/vibe-model.flag`. The `delegate` script checks `delegate-model.flag` first, then falls back to `vibe-model.flag`.

**"Wrote nothing" in report**
→ The harness ran tool calls but changed no files. Usually means the prompt was too vague, or the task was already done. Check `git status` to confirm the state, then rephrase as a clear imperative.

**"D3 source/target field conflict"**
→ Vibe names edge fields `source`/`target` which D3's forceLink hijacks. Use `from`/`to` for custom edge fields and map explicitly: `edges.map(e => ({...e, source: e.from, target: e.to}))` before passing to forceLink.

**"Function defined but never called"**
→ Vibe writes helper functions but forgets to call them. After every frontend run, grep for new functions: `grep -n "^function " file.html` and verify each is called.

**Merge conflict markers left in code**
→ After any run touching previously-edited files: `grep -n "=======" file.py`. Fix with `python3 str.replace()`.

**Large file timeout (>300 lines)**
→ Break into sub-tasks: CSS → HTML structure → JS logic. Never ask for >200 lines of output in one prompt.

---

### Debug checklist

1. **Check the last run log entry:**
   ```bash
   tail -1 ~/.local/share/delegate-runs.jsonl | jq .
   ```

2. **Look at what the harness did:**
   ```bash
   ~/tools/delegate-replay <session-file-from-log>
   ~/tools/delegate-replay <session-file> --errors
   ```

3. **Check failure memory:**
   ```bash
   ~/tools/delegate-failures query /path/to/project app.py
   ```

4. **Check if contracts blocked or failed:**
   ```bash
   ~/tools/delegate-contracts post /path/to/project
   ```

5. **Roll back if needed:**
   ```bash
   # Find the checkpoint from the log:
   tail -1 ~/.local/share/delegate-runs.jsonl | jq -r .checkpoint
   # Roll back:
   ~/tools/delegate-rollback rollback /path/to/project <checkpoint>
   ```

6. **Run the failure report:**
   ```bash
   ~/tools/delegate-report --fails
   ```

### Orchestration pipeline failure points

When a run produces unexpected results, check these links in order:

| Link | Failure mode | Symptom |
|------|-------------|---------|
| Vibe CLI | Auth expired, update broke API | Immediate exit, no output |
| pseudo-TTY (`script`) | Platform difference (GNU vs BSD flags) | Hangs silently or garbled output |
| Stream parser | Vibe changes its JSON schema | Tool calls not detected, wrong token count |
| TOML pricing | `config.toml` missing or renamed | Falls back to Mistral Medium 3.5 rates |
| git diff | Not a git repo, or Vibe committed mid-run | Wrong file count, misleading stat |
| JSON log | `~/.local/share/` not writable | Silent log skip, `/vibe-report` misses the run |
