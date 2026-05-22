---
name: vibe
description: >
  Delegate coding tasks to cheap AI coding agents (Vibe, Pi, OpenCode) and supervise
  via git diff. Multi-harness support with reject-correct loops, contracts, parallel
  execution, and routing. Trigger: /vibe <instruction> or /delegate <harness> <instruction>.
  Also: /vibe-report, /delegate-dashboard, /delegate-chain, /delegate-batch.
license: MIT
user-invocable: true
allowed-tools:
  - bash
  - read_file
  - grep
---

# Delegate Orchestrator

## /vibe help

When the user says `/vibe help` (or `$vibe help`), print this help text directly
to the console and stop:

```
vibe — AI delegation framework

USAGE
  /vibe <instruction>                    Direct delegation (simple mode)
  /vibe <mode>: <instruction>            Inline mode (one-shot)
  /vibe help                             This help text

MODES (inline or persistent via /vibe-mode)
  simple      Direct delegation, no chain (default)
  steady      SOTA plans → MiniMax implements → GLM validates
  quick       MiniMax implements → GLM reviews
  fix         SOTA investigates → MiniMax fixes → GLM validates
  architect   SOTA plans → MiniMax implements → GLM validates
  fortress    SOTA plans → MiniMax implements → GLM tests → MiniMax security
  ironclad    Fortress + GLM final review (5 steps)
  tournament  2 MiniMax + 2 GLM race, GLM judges
  race        MiniMax vs GLM, pick the best
  docs        SOTA outlines → MiniMax writes → GLM reviews
  web         SOTA decomposes → 2 MiniMax + 2 GLM search → GLM aggregates

AGENTS                                   Model
  Orchestrator (plans, reviews, judges)  Claude / Codex (SOTA)
  Implementor / Writer                   MiniMax M2.7 (via codex -p minimax)
  Validator / Reviewer / Aggregator      GLM 5.1 (via codex -p glm)

BACKGROUND AGENTS                        Model              Interval
  /vibe-audit scan                       MiniMax M2.7       every 30m
  /vibe-research scan                    GLM 5.1            every 2h
  /vibe-reindex (knowledge update)       MiniMax M2.7       every 1h
  (configured in .delegate/scheduler.yaml)

COMMANDS
  /vibe <instruction>                    Delegate a coding task
  /vibe <mode>: <instruction>            Delegate with inline mode
  /vibe-mode <mode>                      Set persistent mode
  /vibe-mode                             Show current mode + list all
  /vibeon                                Enable auto-delegate
  /vibeoff                               Disable auto-delegate
  /vibestatus                            Show auto-mode + model status
  /vibe-model-pick <alias>               Override model
  /vibe-model-clear                      Clear model override
  /vibe-report [--since N] [--fails]     Run history report (local, no model)
  /vibe-reindex [--model <m>]            Update knowledge base (default: MiniMax)
  /vibe-audit [scan] [--model <m>]       Audit findings (default: MiniMax)
  /vibe-research [scan] [--model <m>]    Research findings (default: GLM)
  /vibe-scheduler start|stop|status      Manage background agents

EXAMPLES
  /vibe add a login page
  /vibe steady: refactor the auth module
  /vibe fix: the email validation is broken
  /vibe docs: write API documentation
  /vibe tournament: implement search
  /vibe web: latest quantization techniques for LLMs
  /vibe-mode ironclad
  /vibe-scheduler start
```

---

## /vibeon | /vibeoff | /vibestatus

Toggle auto-delegate mode — Vibe automatically handles all coding tasks without
requiring `/vibe` each time.

| Command | Action |
|---------|--------|
| `/vibeon` | `mkdir -p .delegate && touch .delegate/auto.flag` → confirm "Auto-vibe ON" |
| `/vibeoff` | `rm -f .delegate/auto.flag` → confirm "Auto-vibe OFF" |
| `/vibestatus` | report auto-mode (ON/OFF) **and** active model override |

For `/vibestatus`, run both checks and print two lines:
```
Auto-vibe: ON | OFF
Model: <alias>  (override)  OR  Model: deepseek-flash  (config default)
```

---

## /vibe-report

If the user invokes `/vibe-report`, run `.claude/vibe-skill/tools/delegate-report` with any flags
extracted from the arguments, display output verbatim, and stop.

| User says | Flag |
|-----------|------|
| "last 7 days", "7d" | `--since 7` |
| "last 30 days", "30d" | `--since 30` |
| "project foo" | `--project foo` |
| "only failures", "fails", "bugs" | `--fails` |
| (nothing) | (no flags — full report) |

---

## /vibe-model-pick | /vibe-model-clear

Override the Vibe model for all subsequent delegations without touching `~/.vibe/config.toml`.
Works via `VIBE_ACTIVE_MODEL` env var, which Vibe respects over the config file.

| Command | Action |
|---------|--------|
| `/vibe-model-pick <alias>` | `mkdir -p .delegate && echo <alias> > .delegate/model.flag` → confirm |
| `/vibe-model-clear` | `rm -f .delegate/model.flag` → confirm "back to config default" |

**Available aliases** (from `~/.vibe/config.toml`):

| Alias | Model | Provider | Notes |
|-------|-------|----------|-------|
| `deepseek-flash` | deepseek-v4-flash | DeepSeek | Default — fast, cheap |
| `mistral-medium-3.5` | mistral-vibe-cli-latest | Mistral | Stronger reasoning |
| `devstral-small` | devstral-small-latest | Mistral | Lighter Mistral model |
| `local` | devstral (llamacpp) | Local | Requires local server on :8080 |

Run the bash command, print one confirmation line showing the active model, and stop.

---

## Multi-Harness Commands

| Command | Action |
|---------|--------|
| `/vibe <instruction>` | Delegate to Vibe (default harness) |
| `/delegate <harness> <instruction>` | Delegate to specific harness (vibe, pi, opencode) |
| `/delegate-dashboard` | Show live TUI dashboard: `.claude/vibe-skill/tools/delegate-dashboard` |
| `/delegate-batch <prompt>` | Smart batch: `.claude/vibe-skill/tools/delegate-batch "$WORKDIR" "<prompt>"` |
| `/delegate-chain <chain>` | Run chain: `.claude/vibe-skill/tools/delegate-chain "$WORKDIR" ".delegate/chains/<chain>.yaml"` |
| `/delegate-route <description>` | Recommend harness: `.claude/vibe-skill/tools/delegate-router recommend "<desc>"` |

**Harness selection:** Use `/delegate-route` to check which harness is best for
a task, or pick manually. Default is `vibe` until routing data accumulates.

**Available harnesses:**

| Harness | Status | Strengths |
|---------|--------|-----------|
| `vibe` | Active | General implementation, mature adapter |
| `pi` | Stub | Pending Pi CLI investigation |
| `opencode` | Stub | Pending OpenCode CLI investigation |

---

When the user invokes `/vibe <instruction>`, the orchestrator determines the mode:

### Inline mode (one command)

The user can specify the mode directly in the `/vibe` command:

```
/vibe steady: add user authentication
/vibe fix: the login form is broken
/vibe docs: write API documentation for the routes
/vibe tournament: implement the search feature
/vibe architect: redesign the database schema
```

Format: `/vibe <mode>: <instruction>`

When a colon is present after the first word, check if the word before the colon
matches a chain file in `.claude/vibe-skill/.delegate/chains/`. If it does, use
that mode for THIS delegation only (does not change the persistent mode flag).

### Persistent mode (sticky)

```
/vibe-mode steady
/vibe add auth          ← uses steady until changed
/vibe fix the bug       ← still uses steady
```

### Mode resolution order

1. **Inline mode** — `/vibe steady: add auth` → use `steady` for this one task
2. **Persistent mode** — `cat .delegate/mode.flag` → use if set
3. **Simple mode** — no chain, direct delegation

For any mode, look for `.claude/vibe-skill/.delegate/chains/<mode>.yaml`.
If not found, warn and fall back to simple delegation.

Available modes are auto-discovered from `.claude/vibe-skill/.delegate/chains/*.yaml`.
The mode name is the filename without `.yaml`. Use `/vibe-mode` to list them.

### SOTA planning (architect mode and any chain with `sota: true` steps)

When a chain has a step with `sota: true`, that step is **skipped by the chain
script** — the orchestrator (you, Claude/Codex) handles it directly:

1. Read the step's `prompt_template`, substitute `{task}` with the user's instruction
2. Read the relevant source files to understand the current state
3. **Write a DETAILED, step-by-step plan** — not a high-level overview

**Critical: cheap models need explicit instructions.** The plan must be detailed
enough that a junior developer could follow it without asking questions. Include:

- **Exact file paths** to create or modify
- **Exact function/class names** to add, change, or remove
- **Code patterns** to follow (show a snippet if the pattern matters)
- **Step-by-step sequence** — numbered, ordered, unambiguous
- **What NOT to do** — constraints, things to leave alone
- **Verification** — how to confirm each step worked

**Bad plan (too vague — cheap model will guess wrong):**
```
Add authentication to the API. Use JWT tokens. Protect the routes.
```

**Good plan (cheap model can execute precisely):**
```
1. Create src/auth/jwt.py:
   - Function `create_token(user_id: str) -> str` using PyJWT, HS256, 24h expiry
   - Function `verify_token(token: str) -> dict` returning payload or raising HTTPException(401)
   - Secret key from os.environ["JWT_SECRET"]

2. Modify src/routes/api.py:
   - Add `from src.auth.jwt import verify_token`
   - Create decorator `@require_auth` that extracts Bearer token from Authorization header
   - Apply `@require_auth` to: get_user(), update_user(), delete_user()
   - Do NOT apply to: login(), register(), health_check()

3. Modify src/routes/auth.py:
   - In login() after password verification, call create_token(user.id)
   - Return {"token": token, "user_id": user.id}

4. Verify: grep for "require_auth" in api.py — should appear 3 times
```

4. Write the plan to `.delegate/plan.md`:
   ```bash
   mkdir -p .delegate && cat > .delegate/plan.md << 'PLAN'
   [your detailed plan here]
   PLAN
   ```
5. Then run the chain: `.claude/vibe-skill/tools/delegate-chain "$WORKDIR" "<chain-yaml>"`
6. The chain reads `.delegate/plan.md` and injects it as `{plan}` into subsequent steps

The `architect` mode does exactly this: you plan in detail, MiniMax follows your
instructions precisely, GLM validates against your plan.

---

## Known Limits

Hard constraints of Mistral Vibe CLI — not config options.

### 0. macOS requires GNU coreutils
All delegate adapters use `timeout`. macOS ships without it — install via:
```bash
brew install coreutils
```

### 1. Requires a pseudo-TTY
Vibe checks for a TTY on startup. Without one (plain pipe), it hangs silently —
0 tool calls, no output, silent timeout. The `vibe-delegate` script allocates a
pseudo-TTY via `script` (Linux: `script -q -c "..." /dev/null`, macOS: `script -q /dev/null "..."`). **Never call vibe directly in a pipe.**

### 2. UTF-8 / special chars cause `search_replace` failures
Vibe's `search_replace` tool matches byte-for-byte. Accented chars, curly quotes,
or emoji in `old_string` → silent match failure, no write. Workaround: use
`python3 str.replace()` for those edits, or restructure the prompt to avoid them.

### 3. Context saturation above ~12 turns
Mistral's context fills with repeated file reads. Beyond 12 turns the model starts
looping — re-reading files it already read, not making progress. Hard cap: `--max-turns 12`.

### 4. `--output text` hides errors
`--output text` buffers everything until the run ends and suppresses intermediate
errors. Always use `--output streaming` (done automatically by `vibe-delegate`).

### 5. Code duplication bug
Vibe sometimes re-inserts a block it has already written (off-by-one in its diff
logic). Check for duplicate function definitions or repeated class bodies after
every run.

### 6. Orchestration chain has 6 independent failure points
The delegation pipeline is: `vibe CLI → pseudo-TTY (script) → Python stream parser →
TOML pricing lookup → git diff → JSON log`. Each link can fail independently:

| Link | Failure mode | Symptom |
|------|-------------|---------|
| Vibe CLI | Auth expired, update broke API | Immediate exit, no output |
| pseudo-TTY (`script`) | Platform difference (GNU vs BSD flags) | Hangs silently or garbled output |
| Stream parser | Vibe changes its JSON schema | Tool calls not detected, wrong token count |
| TOML pricing | `config.toml` missing or renamed | Falls back to Mistral Medium 3.5 rates |
| git diff | Not a git repo, or Vibe committed mid-run | Wrong file count, misleading stat |
| JSON log | `.delegate/` not writable | Silent log skip, `/vibe-report` misses the run |

When a run produces unexpected results, check these links in order from top to bottom.

### 7. Never pass source code through a bash heredoc
Passing Python/JS code inline in a bash `<< 'PYEOF'` command fails when the code
contains nested quotes, f-strings, or backslashes — Vibe's bash tool mangles the
escaping. **This is not a reason to build a workaround script** — that doubles work.

**Right approach for function replacement:**
- If code is ASCII (no accents, no emoji): use `search_replace` directly — it works.
- If content is too long for an inline prompt: ask Vibe to **write the new content**
  to a temp file with its write tool, then `search_replace` the old function using the
  file's content via `open('/tmp/new.py').read()`.
- Never write a Python script whose sole job is to call `str.replace()` on another
  Python file — that is always unnecessary complexity.

---

## Step 1 — Detect workdir

1. `git rev-parse --show-toplevel` in the current directory.
2. If ambiguous or no git repo → ask with `AskUserQuestion`.

---

## Step 2 — Decompose the task

**Critical rule**: Vibe is optimized for **atomic, focused tasks**.
Its system prompt literally says "Most tasks need <150 words."

**First: did the user explicitly specify a mode?**

If the user typed `/vibe <mode>: <instruction>` with an explicit mode prefix,
**ALWAYS delegate. No gate. No filtering.** The user chose a mode — respect it.
`/vibe fix: validate & investigate R6.1` → run the fix chain. Period.

**If NO mode was specified** (`/vibe <instruction>` without a mode prefix),
then apply this filter — is it a coding task?

Delegates are coding agents — they read files and write code. They cannot answer
questions, explain concepts, or have conversations. Don't delegate:

| NOT delegatable | Handle directly |
|-----------------|----------------|
| Questions ("what does this function do?") | Answer from context |
| Explanations ("explain the auth flow") | Explain directly |
| Conversations ("what should we build?") | Discuss directly |
| Git operations (commit, push, branch) | Run directly |

Only delegate when the task produces **file changes** — new code, modified code,
documentation edits, config updates.

**For auto-vibe mode (`/vibeon`):** This filter applies only when no explicit
mode is given. Questions and conversations stay with the orchestrator.

**Then: is it worth delegating?**

`delegate` has real orchestration overhead (pseudo-TTY allocation, stream parser,
pricing lookup, git diff, JSON log). For trivial changes the setup cost exceeds the
savings. Apply this filter:

| Signal | Action |
|--------|--------|
| 1 file, ≤ ~10 lines to change, location already known | **Do it directly** — don't delegate |
| 1 file, logic non-trivial OR location unclear | Delegate — exploration + edit in one run |
| 2–3 files, single objective | Delegate |
| >3 files OR multi-step logic OR migrations | Delegate, broken into sub-tasks |

The sweet spot is **medium to heavy tasks** where Vibe's internal file reads and multi-turn
exploration would otherwise burn significant Claude context.

**Evaluate complexity before launching:**

| Size | Definition | Max turns | Approach |
|------|-----------|-----------|----------|
| **Trivial** | 1 file, change is obvious and located | — | **Skip delegation — edit directly** |
| **Simple** | 1 file, non-trivial logic or unknown location | 5–8 | 1 vibe call |
| **Medium** | 2–3 related files, 1 objective | 8–12 | 1 structured vibe call |
| **Complex** | >3 files OR business logic OR DB migrations | — | **Break into sub-tasks** |

**Decomposition for complex tasks:**
```
Sub-task 1: Explore / read relevant files (read-only, 5 turns)
Sub-task 2: Implement change A in file X (8 turns)
Sub-task 3: Implement change B in file Y (8 turns)
Sub-task 4: Verify / test (5 turns)
```
→ Check git diff between each sub-task before launching the next.

---

## Step 3 — Write the Vibe prompt

Vibe has no context from the parent conversation. The prompt must be **self-contained**.

**Structure of a good Vibe prompt:**
```
Stack: Python/Flask, SQLAlchemy, SQLite
Key files: app.py (routes + fetch), models.py (Entry)

TASK: [one single thing to do, stated as an imperative]

CONSTRAINTS:
- [what must not break]
- [expected format if relevant]

VERIFY: grep for "def function_name" in file.py and confirm it exists.
```

**Formulation rules:**
- One task per prompt — never "also do X and Y"
- Name the exact files to modify
- Include a grep-based verification criterion (not a file re-read)
- Language: English (better Mistral performance)

> ⚠️ **Shell safety**: if the prompt contains UTF-8 accented chars, emojis,
> `:` in Python/YAML code, or typographic apostrophes — the vibe-delegate script
> passes them safely via a temp file (`printf %q`). Never interpolate such a prompt
> directly into a bash heredoc.

**Verification — always use grep, not file re-read:**
```
VERIFY: grep for "def extract_labels" in app.py and confirm it exists.
```
A grep is reliable. A file re-read may miss content outside the read window.

**Examples:**

❌ Bad (too vague, too large):
```
Fix the API, add a signal classifier, update the UI with colored badges
```

✅ Good (atomic, verifiable):
```
Stack: Python/Flask. File: app.py

TASK: In fetch_data(), convert the date string (format "YYYY-MM-DD")
to datetime.date before returning, and convert id to str.

VERIFY: grep for "datetime.date" in app.py and confirm it appears in fetch_data.
```

---

## Step 4 — Launch Delegation

```bash
.claude/vibe-skill/tools/delegate <harness> "<workdir>" "<prompt>" [max-turns] [agent] [timeout-secs]
```

| Argument       | Default  | Notes                                           |
|----------------|----------|-------------------------------------------------|
| `harness`      | `vibe`   | Which coding agent: vibe, pi, opencode          |
| `workdir`      | —        | Absolute path, must exist                       |
| `prompt`       | —        | Self-contained task description                 |
| `max-turns`    | `10`     | Turn limit — hard cap at 12, never more         |
| `agent`        | *(none)* | See agent table below                           |
| `timeout-secs` | `600`    | Wall-clock kill timer (10 minutes)              |

The script automatically: creates a rollback checkpoint, injects the project brief
(if `.delegate/project-brief.md` exists), runs pre-contracts, allocates a pseudo-TTY
(vibe-specific), runs post-contracts, checks for duplicates, and logs to JSONL.

**Backward compat:** `.claude/vibe-skill/tools/vibe-delegate` still works (shim to `delegate vibe`).

**Available agents:**

| Agent | Use |
|-------|-----|
| *(default)* | General implementation |
| `code-reviewer` | Review only, no changes |
| `planner` | Planning before implementing |
| `code-architect` | Architecture design, read-only |

**Recommended max turns:**
- Read/explore: `5`
- Simple change (1 file): `8`
- Medium change (2–3 files): `12`
- Never exceed `12` — decompose instead

**Background launch:**
```bash
.claude/vibe-skill/tools/vibe-delegate "<workdir>" "<prompt>" 10 > /tmp/vibe_out.txt 2>&1 &
# Monitor with: tail -f /tmp/vibe_out.txt
```

---

## Step 5 — Supervise in real time

The script prints live:
```
=== VIBE START ===
Workdir : /path/to/project
Agent   : default
Turns   : 10
Timeout : 180s
Prompt  : Stack: Python/Flask. File: app.py ...
===================
  [read]  app.py
  [tool]  file: app.py
  [tool]  search_replace [OK] ...
  [vibe]  Done. Converted date to datetime.date in fetch_data().
Tool calls: 5
Delegate tokens (run): 4,800  (last turn: 4,600+200)  |  cost ~$0.0086
Claude Sonnet 4.6 eq: same tokens would cost ~$0.0168  (ratio x2.0)
=== VIBE DONE (exit: 0) ===
=== SYNTAX OK (1 check(s)) ===

=== UNCOMMITTED CHANGES ===
 app.py | 4 ++--
[log] → .delegate/runs.jsonl  (4800 tokens, exit 0, 34.2s)
```

**Vibe never commits.** All changes are left unstaged — `git checkout .` reverts everything if needed.

**Red flags to act on immediately:**

| Flag | Meaning | Action |
|------|---------|--------|
| `[WARN]` | Vibe encountered an error | Read the error, fix manually |
| `[tool]  search_replace [FAIL]` | UTF-8 match failure | Edit manually with Python `str.replace()` |
| `exit: 1` or non-zero | Vibe failed / did not complete verification | Read diff, correct prompt |
| No `[tool]  file:` lines | Vibe read but wrote nothing | Prompt was too vague or task already done |
| `=== SYNTAX ERRORS ===` | Post-run syntax check failed | **Fix before committing** |
| Same file read 5+ times | Vibe is looping — run likely lost | Abort, check diff, try again |

**Known bugs and workarounds:**

| Bug | Cause | Fix |
|-----|-------|-----|
| `search_replace failed` | UTF-8/emoji chars in `old_string` | Edit with `python3 str.replace()` — only needed for actual UTF-8, not plain Python code |
| Duplicated code at end of file | Vibe re-inserts an already-present block | Read diff, delete duplicate manually |
| Variable declared twice | Same — Vibe doesn't check scope | Grep the variable before relaunching |
| Truncated prompt | Special chars in inline prompt | Script uses temp file — should be fixed |
| Wrote a Python helper just to replace code | Misdiagnosed search_replace limit — plain Python code works fine | Use search_replace directly for ASCII code; write_file only if the new content is too long for the prompt |
| Passed code via bash heredoc | Nested quotes break in Vibe's bash execution | Never put source code in a heredoc; use write_file tool instead |
| **Merge conflict markers left in code** | Vibe uses search_replace on files with prior edits, leaves `=======` markers | After any run touching edited files, grep: `grep -n "=======" file`. Fix with `python3 str.replace()` |
| **D3 `source`/`target` field conflict** | Vibe names edge fields `source`/`target` which D3 forceLink hijacks internally | Use `from`/`to` for custom edge fields. Map explicitly: `edges.map(e => ({...e, source: e.from, target: e.to}))` before passing to forceLink |
| **D3 tick handler overwritten** | Vibe registers custom force as `simulation.on('tick', fn)` — D3 overwrites previous listener with same name | Use `.force('name', fn)` not tick handlers for custom forces |
| **Function defined but never called** | Vibe writes helper functions (e.g. `renderX()`) but omits the call in init sequence | After every frontend run, grep new functions and verify they're called: `grep -n "^function " file.html` |
| **Large file timeout (>300 lines)** | Vibe hits the 360s wall generating a large single file | Break into sub-tasks: CSS → HTML structure → JS logic. Never ask for >200 lines in one prompt |
| **PM2 env vars not loading** | `pm2 start "bash -c 'source ~/.vibe/.env && ...'"` — quotes in .env break export | Use a wrapper script: `printf '#!/bin/bash\nset -a; source ~/.vibe/.env; set +a\npython3 ...\n' > /tmp/run.sh && pm2 start /tmp/run.sh` |
| **LLM batch fallback flood** | Large batches (50 items) return wrong count → entire batch falls back to catch-all | Use batches ≤20 items. On count mismatch: pad/truncate instead of full fallback |

**If exit non-zero:** do not relaunch immediately. Read the diff, understand what was done, fix the prompt.

---

## Step 6 — Review and Correct (Reject-Correct Loop)

**Critical rule: the orchestrator NEVER writes code itself during delegation.**
Its only actions are: review the diff, write correction prompts, send back to harness.

**On timeout:** If a delegation times out, DO NOT implement the task yourself.
Instead:
1. Check if the delegate made partial progress (`git diff --stat`)
2. If partial progress: send a correction to finish the remaining work
3. If no progress: retry with a simpler decomposition or longer timeout
4. NEVER say "I'll implement it directly" — that defeats the entire purpose

After the delegate finishes, classify the result:

| Disposition | Action |
|-------------|--------|
| `accept` | Changes look correct → done |
| `reject-correct` | Specific fixable issues → send correction back to harness |
| `reject-retry` | Fundamentally wrong approach → full re-run with new prompt |
| `reject-abort` | Unfixable by harness → escalate to user |

**To send a correction back:**
```bash
.claude/vibe-skill/tools/delegate-reject "$WORKDIR" "The import on line 3 is wrong. Change from utils import foo to from app.utils import foo. Do not touch anything else."
```
Then re-run `.claude/vibe-skill/tools/delegate <harness> "$WORKDIR" "<original-prompt>"` — the
correction file is picked up automatically (max 2 correction rounds).

**Rollback if needed:**
```bash
.claude/vibe-skill/tools/delegate-rollback rollback "$WORKDIR" "<checkpoint-branch>"
```

- **Max 2 correction rounds** before escalating to `reject-retry` or `reject-abort`.
- Between rounds, **read the git diff** to avoid doubling partial work.
- If all correction rounds fail, escalate to the user — do NOT fix it yourself.
- Record failures: `.claude/vibe-skill/tools/delegate-failures record "$WORKDIR" vibe <error_type> "<symptom>" "<fix>"`

## Step 6b — Log manual completion (legacy)

When the orchestrator must log manual work (should be rare with reject-correct):

```bash
python3 -c "
import json, datetime, subprocess, os

workdir = subprocess.run(['git','rev-parse','--show-toplevel'], capture_output=True, text=True).stdout.strip() or os.getcwd()
project = os.path.basename(workdir.rstrip('/'))

stat = subprocess.run(['git','-C',workdir,'diff','--stat'], capture_output=True, text=True).stdout
lines_added = sum(
    int(l.split('+')[1].split()[0])
    for l in stat.splitlines()
    if '|' in l and '+' in l
) if stat else 0
files_changed = len([l for l in stat.splitlines() if '|' in l])

tokens_out = lines_added * 10
tokens_in  = lines_added * 40
cost = (tokens_in * 3.0 + tokens_out * 15.0) / 1_000_000

entry = {
    'ts': datetime.datetime.utcnow().isoformat() + 'Z',
    'delegate': 'claude-manual',
    'workdir': workdir, 'project': project,
    'exit_code': 0, 'files_changed': files_changed,
    'tokens_in': tokens_in, 'tokens_out': tokens_out,
    'tokens_total': tokens_in + tokens_out,
    'cost_usd': round(cost, 6), 'cost_estimated': True,
    'lines_added': lines_added,
}
log = os.path.join(workdir, '.delegate', 'runs.jsonl')
with open(log, 'a') as f:
    f.write(json.dumps(entry) + '\n')
print(f'[log] claude-manual → {project}  ~{lines_added} lines added  est. cost \${cost:.4f}')
"
```

Run from anywhere inside the project. Token estimate: output ≈ lines_added × 10, input ≈ lines_added × 40 (context reading). Flagged `cost_estimated: true` in the log.

---

## Step 7 — Report to the user

```
✓ Vibe finished — <1-line summary>

Files modified:
  - path/to/file.ext (+X / -Y lines)

[If problem]:
⚠ <description> — completing manually / relaunching?

Ready to commit?
```

---

## Orchestration rules

- **Decompose before delegating** — an oversized prompt is guaranteed to fail.
- **Streaming always** — `--output text` hides errors and blocks until the end.
- **Check diff between sub-tasks** — never launch the next one blind.
- **Don't code instead of Vibe** unless Vibe completed ≥50% and crashed.
- **Max 12 turns per call** — beyond that, Mistral context saturates.
- **VERIFY with grep, not file re-read** — `grep -n "def foo" file.py` is reliable.
- **UTF-8 / emoji in the prompt** → the script handles it via temp file, but test with a short prompt first.
- **After any run that touches imports: grep the import line** — sequential runs can revert each other's import changes. Always run `grep "^from X import" file.py` before the next sub-task.
- **search_replace [OK] ≠ correct change** — Vibe may report OK even if the match was on unintended content. Always grep the specific changed line, not just check syntax.
- **Provide data structure context** — Vibe writes against what it knows. If a route accesses a DB payload, include the exact field paths (`payload['produit']['nom']`) in the prompt, not just "extract the name".
- **Reuse existing assets** — for UI tasks, tell Vibe to link existing CSS/JS files rather than generating new styles. "Use `/static/style.css` and CSS class `bar-row`" is always better than "generate a dark theme".

---

## Token economics

Vibe's internal turns (repeated file reads, etc.) consume **Mistral tokens**,
not Claude tokens. Claude only receives the compressed final output (~500–1500 tokens/run).

For a task with 6 reads of an 800-line file: ~4800 tokens on Mistral's side, 0 on Claude's.
**Real advantage** on exploratory tasks. Neutral or slightly negative if Vibe fails and
generates long error output that comes back into Claude's context.

**Approximate pricing (Mistral Codestral):**
- ~$1.5/M input tokens, ~$7.5/M output tokens
- Claude Sonnet 4.6: ~$3/M input, ~$15/M output
- Typical ratio: ~2x cheaper per token than Claude, plus 0 Claude tokens on orchestration overhead

Real token counts and cost are printed after every run and appended to the run log.

---

## Run Log

Every run appends one JSON entry to `.delegate/runs.jsonl` in the project directory.

**Fields logged:**

| Field           | Type    | Description                                          |
|-----------------|---------|------------------------------------------------------|
| `ts`            | string  | ISO 8601 UTC timestamp                               |
| `delegate`      | string  | `"vibe"`                                             |
| `workdir`       | string  | Absolute project path                                |
| `project`       | string  | `basename(workdir)`                                  |
| `prompt_words`  | int     | Word count of the prompt (complexity proxy)          |
| `agent`         | string  | Agent used (`"default"`, `"code-reviewer"`, etc.)   |
| `max_turns`     | int     | Configured `--max-turns` value                       |
| `timeout_secs`  | int     | Configured timeout in seconds                        |
| `exit_code`     | int     | 0=success · 124=timeout · other=error                |
| `timed_out`     | bool    | `true` if `exit_code == 124`                         |
| `tool_calls`    | int     | Total tool invocations made by Vibe                  |
| `files_changed` | int     | Files modified (git diff count)                      |
| `syntax_errors` | int     | Python/JS syntax errors detected post-run            |
| `duration_secs` | float   | Total wall-clock duration                            |
| `tokens_in`     | int     | Prompt tokens (from Mistral session log)             |
| `tokens_out`    | int     | Completion tokens                                    |
| `tokens_total`  | int     | Total tokens                                         |
| `cost_usd`            | float   | Estimated delegate cost in USD                       |
| `cost_claude_eq`      | float   | Claude Sonnet 4.6 equivalent cost for same tokens    |
| `model`               | string  | Active model alias from `config.active_model` (e.g. `"deepseek-flash"`, `"mistral-medium"`) |
| `warn_count`          | int     | Number of `[WARN]` events during the run             |
| `search_replace_fails`| int     | Number of `search_replace [FAIL]` events             |
| `wrote_nothing`       | bool    | `true` if Vibe ran ≥3 tool calls but changed 0 files |

**Report script — `.claude/vibe-skill/tools/delegate-report`:**

```bash
.claude/vibe-skill/tools/delegate-report                  # full report (all time)
.claude/vibe-skill/tools/delegate-report --since 7        # last 7 days
.claude/vibe-skill/tools/delegate-report --project myapp  # filter by project
.claude/vibe-skill/tools/delegate-report --fails          # failures and issues only
```

Or via Claude Code: `/vibe-report [args]`

**Raw jq queries:**
```bash
# Success rate
jq -r '.exit_code' .delegate/runs.jsonl | sort | uniq -c

# Total cost vs Claude equivalent
jq -r '[.cost_usd, .cost_claude_eq] | @tsv' .delegate/runs.jsonl \
  | awk '{c+=$1; e+=$2} END {printf "Spent: $%.4f  Claude eq: $%.4f  Saved: $%.4f\n", c, e, e-c}'

# Runs with search_replace failures
jq 'select(.search_replace_fails > 0)' .delegate/runs.jsonl
```

---

## Additional JSONL Fields (new)

| Field                 | Type    | Description                                          |
|-----------------------|---------|------------------------------------------------------|
| `harness`             | string  | Which harness was used (vibe, pi, opencode)          |
| `checkpoint`          | string  | Rollback checkpoint branch name                      |
| `correction_rounds`   | int     | Number of reject-correct cycles (0 = accepted first) |
| `final_disposition`   | string  | `accepted`, `corrected`, `correction_failed`         |
| `contract_post_pass`  | bool    | Whether post-condition contracts passed              |
| `session_file`        | string  | Path to replay session file (F16)                    |

---

## Tools Reference

| Tool | Purpose |
|------|---------|
| `.claude/vibe-skill/tools/delegate` | Generic delegation entry point |
| `.claude/vibe-skill/tools/adapters/vibe` | Vibe harness adapter |
| `.claude/vibe-skill/tools/adapters/pi` | Pi adapter (stub) |
| `.claude/vibe-skill/tools/adapters/opencode` | OpenCode adapter (stub) |
| `.claude/vibe-skill/tools/delegate-rollback` | Git branch checkpoint management |
| `.claude/vibe-skill/tools/delegate-reject` | Write correction prompt for reject-correct |
| `.claude/vibe-skill/tools/delegate-correct` | Send correction to harness directly |
| `.claude/vibe-skill/tools/delegate-contracts` | Run pre/post condition checks |
| `.claude/vibe-skill/tools/delegate-check-duplicates` | Detect duplicate code and regressions |
| `.claude/vibe-skill/tools/delegate-ast-check` | AST-level semantic validation |
| `.claude/vibe-skill/tools/delegate-failures` | Failure memory — record and query |
| `.claude/vibe-skill/tools/delegate-learnings` | Learning loop — capture correction patterns |
| `.claude/vibe-skill/tools/delegate-router` | Recommend harness based on run history |
| `.claude/vibe-skill/tools/delegate-parallel` | Run tasks in parallel via git worktrees |
| `.claude/vibe-skill/tools/delegate-batch` | Smart batching for bulk tasks |
| `.claude/vibe-skill/tools/delegate-chain` | Multi-step delegation workflows |
| `.claude/vibe-skill/tools/delegate-replay` | Replay recorded delegation sessions |
| `.claude/vibe-skill/tools/delegate-dashboard` | Live TUI dashboard |
| `.claude/vibe-skill/tools/delegate-distill` | Generate project brief for context injection |
| `.claude/vibe-skill/tools/delegate-report` | Historical token/cost/failure report |
| `.claude/vibe-skill/tools/vibe-delegate` | Backward-compat shim → `delegate vibe` |

---

## See Also

- Codex orchestrator support: see `CODEX-SKILL.md`
- Pre-built delegation chains: `.delegate/chains/implement.yaml`, `.delegate/chains/bugfix.yaml`
- A sister delegate using Gemini CLI exists: [gemini-skill](https://github.com/pcx-wave/gemini-skill).
  Both write to the same `delegate-runs.jsonl` log, making runs comparable across delegates.
