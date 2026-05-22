# Codex Orchestrator — Delegation Instructions

This file contains orchestration instructions for **Codex CLI acting as the orchestrator**.
The delegates (Vibe, Pi, OpenCode) are invoked via `.claude/vibe-skill/tools/delegate`, which is
harness-agnostic. Codex itself does not code — it decomposes, delegates, supervises,
and reports.

---

## Interaction Model

Codex does not use slash commands. Instead, interpret user intent directly:

| User says | Action |
|-----------|--------|
| "delegate X to vibe" | Run Step 1–7 below with harness=vibe |
| "delegate X to pi" | Run Step 1–7 below with harness=pi |
| "delegate X to opencode" | Run Step 1–7 below with harness=opencode |
| "show me the delegate report" | Run `.claude/vibe-skill/tools/delegate-report` |
| "show failures" | Run `.claude/vibe-skill/tools/delegate-report --fails` |
| "show dashboard" | Run `.claude/vibe-skill/tools/delegate-dashboard` |
| "turn on auto-delegate" | `mkdir -p .delegate && touch .delegate/auto.flag` |
| "turn off auto-delegate" | `rm -f .delegate/auto.flag` |
| "set model to X" | `mkdir -p .delegate && echo X > .delegate/model.flag` |
| "clear model override" | `rm -f .delegate/model.flag` |

---

## Sandbox Notes (Codex-specific)

Codex runs in a sandboxed environment. The following apply:

- **Filesystem access**: `.claude/vibe-skill/tools/delegate` and adapters require read/write/exec access
  to `.claude/vibe-skill/tools/` and the project's `.delegate/` directory. Ensure these paths are
  accessible before delegating.
- **Network**: delegate scripts invoke external APIs (Vibe, Pi, OpenCode) — network must
  be allowed.
- **Git**: the delegate scripts run `git diff` and `git rev-parse` inside the workdir.
  Codex must not run `git commit` during delegation — delegates never commit.
- **pseudo-TTY**: Vibe requires a pseudo-TTY (allocated internally by `vibe-delegate`/
  the `vibe` adapter). Codex should not invoke Vibe directly in a pipe.
- **Model flag**: `.delegate/model.flag` — read by `delegate` to override
  the active model. Codex reads/writes this file directly.
- **Run log**: `.delegate/runs.jsonl` — appended by every `delegate` run (per-project).
  Codex can read this for status; never modify it directly.

---

## Step 1 — Detect Workdir

```bash
git rev-parse --show-toplevel
```

If the working directory is not a git repo or is ambiguous, ask the user for the
absolute path before proceeding.

---

## Step 2 — Decompose the Task

**Critical rule**: delegates are optimized for **atomic, focused tasks**.

**Decide whether to delegate at all:**

| Signal | Action |
|--------|--------|
| 1 file, ≤ ~10 lines to change, location already known | Do it directly — don't delegate |
| 1 file, logic non-trivial OR location unclear | Delegate |
| 2–3 files, single objective | Delegate |
| >3 files OR multi-step logic OR migrations | Delegate, broken into sub-tasks |

**Task size table:**

| Size | Definition | Max turns | Approach |
|------|-----------|-----------|----------|
| Trivial | 1 file, change is obvious and located | — | Skip delegation — edit directly |
| Simple | 1 file, non-trivial logic or unknown location | 5–8 | 1 delegate call |
| Medium | 2–3 related files, 1 objective | 8–12 | 1 structured delegate call |
| Complex | >3 files OR business logic OR DB migrations | — | Break into sub-tasks |

**Decomposition for complex tasks:**
```
Sub-task 1: Explore / read relevant files (read-only, 5 turns)
Sub-task 2: Implement change A in file X (8 turns)
Sub-task 3: Implement change B in file Y (8 turns)
Sub-task 4: Verify / test (5 turns)
```
Check `git diff` between each sub-task before launching the next.

---

## Step 3 — Write the Delegate Prompt

Delegates have no context from the parent conversation. The prompt must be
**self-contained**.

**Structure:**
```
Stack: <language/framework>
Key files: <file> (<role>), <file> (<role>)

TASK: [one single thing to do, stated as an imperative]

CONSTRAINTS:
- [what must not break]
- [expected format if relevant]

VERIFY: grep for "def function_name" in file.py and confirm it exists.
```

**Rules:**
- One task per prompt — never "also do X and Y"
- Name the exact files to modify
- Include a grep-based verification criterion (not a file re-read)
- Write in English (better model performance across all harnesses)

**Shell safety**: if the prompt contains UTF-8 accented chars, emojis, `:` in
Python/YAML code, or typographic apostrophes — `delegate` passes them via a temp file
automatically. Never interpolate such a prompt directly into a bash heredoc.

**Examples:**

Bad (too vague, too large):
```
Fix the API, add a signal classifier, update the UI with colored badges
```

Good (atomic, verifiable):
```
Stack: Python/Flask. File: app.py

TASK: In fetch_data(), convert the date string (format "YYYY-MM-DD")
to datetime.date before returning, and convert id to str.

VERIFY: grep for "datetime.date" in app.py and confirm it appears in fetch_data.
```

---

## Step 4 — Launch the Delegate

```bash
.claude/vibe-skill/tools/delegate <harness> "<workdir>" "<prompt>" [max-turns] [agent] [timeout-secs]
```

| Argument | Default | Notes |
|----------|---------|-------|
| `harness` | — | `vibe`, `pi`, or `opencode` |
| `workdir` | — | Absolute path, must exist |
| `prompt` | — | Self-contained task description |
| `max-turns` | `10` | Hard cap at 12 for Vibe, never more |
| `agent` | *(none)* | See agent table below |
| `timeout-secs` | `180` | Wall-clock kill timer |

**Available agents (Vibe):**

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
- Never exceed `12` for Vibe — decompose instead

**Model override** (applies to all harnesses):
```bash
# Set override
mkdir -p .delegate && echo <alias> > .delegate/model.flag

# Clear override
rm -f .delegate/model.flag
```

**Available Vibe model aliases** (from `~/.vibe/config.toml`):

| Alias | Model | Provider | Notes |
|-------|-------|----------|-------|
| `deepseek-flash` | deepseek-v4-flash | DeepSeek | Default — fast, cheap |
| `mistral-medium-3.5` | mistral-vibe-cli-latest | Mistral | Stronger reasoning |
| `devstral-small` | devstral-small-latest | Mistral | Lighter Mistral model |
| `local` | devstral (llamacpp) | Local | Requires local server on :8080 |

---

## Step 5 — Supervise in Real Time

The delegate script prints live output:
```
=== DELEGATE START ===
Harness : vibe
Workdir : /path/to/project
Agent   : default
Turns   : 10
Timeout : 180s
Prompt  : Stack: Python/Flask. File: app.py ...
======================
  [read]  app.py
  [tool]  file: app.py
  [tool]  search_replace [OK] ...
  [vibe]  Done. Converted date to datetime.date in fetch_data().
Tool calls: 5
Delegate tokens (run): 4,800  (last turn: 4,600+200)  |  cost ~$0.0086
Claude equivalent: same tokens would cost ~$0.0168  (ratio x2.0)
=== DELEGATE DONE (exit: 0) ===
=== SYNTAX OK (1 check(s)) ===

=== UNCOMMITTED CHANGES ===
 app.py | 4 ++--
[log] → .delegate/runs.jsonl  (4800 tokens, exit 0, 34.2s)
```

**Delegates never commit.** All changes are left unstaged.

**Red flags to act on immediately:**

| Flag | Meaning | Action |
|------|---------|--------|
| `[WARN]` | Delegate encountered an error | Read the error, fix manually |
| `search_replace [FAIL]` | UTF-8 match failure | Edit manually with Python `str.replace()` |
| `exit: 1` or non-zero | Delegate failed | Read diff, correct prompt |
| No `[tool]  file:` lines | Wrote nothing | Prompt too vague or task already done |
| `=== SYNTAX ERRORS ===` | Syntax check failed | Fix before committing |
| Same file read 5+ times | Delegate is looping | Abort, check diff, try again |

**Known bugs and workarounds (Vibe-specific):**

| Bug | Cause | Fix |
|-----|-------|-----|
| `search_replace failed` | UTF-8/emoji chars in `old_string` | Edit with `python3 str.replace()` |
| Duplicated code at end of file | Vibe re-inserts an already-present block | Read diff, delete duplicate manually |
| Variable declared twice | Same — Vibe doesn't check scope | Grep the variable before relaunching |
| Merge conflict markers left in code | Vibe search_replace on previously edited files | After any run: `grep -n "=======" file` |
| D3 `source`/`target` field conflict | Vibe names edge fields D3 hijacks internally | Use `from`/`to` for custom edge fields |
| D3 tick handler overwritten | Vibe uses `.on('tick', fn)` — D3 overwrites | Use `.force('name', fn)` not tick handlers |
| Function defined but never called | Vibe writes helpers but omits the call | After every frontend run, grep new functions |
| Large file timeout (>300 lines) | Vibe hits wall generating large single file | Break into sub-tasks: CSS → HTML → JS |
| PM2 env vars not loading | Quotes in .env break export | Use a wrapper script with `set -a; source` |
| LLM batch fallback flood | Large batches return wrong count | Use batches ≤20 items |

---

## Step 6 — Iteration

- **Max 3 attempts** per sub-task before escalating to the user.
- Between attempts, **read the git diff** to avoid doubling partial work.
- If the delegate completed ≥50% and crashed: finish the rest manually.

### Log Manual Completion

When you finish a task manually (after delegate failures), run this immediately:

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
    'harness': 'codex-manual',
    'workdir': workdir, 'project': project,
    'exit_code': 0, 'files_changed': files_changed,
    'tokens_in': tokens_in, 'tokens_out': tokens_out,
    'tokens_total': tokens_in + tokens_out,
    'cost_usd': round(cost, 6), 'cost_estimated': True,
    'lines_added': lines_added,
}
log = os.path.expanduser('.delegate/runs.jsonl')
with open(log, 'a') as f:
    f.write(json.dumps(entry) + '\n')
print(f'[log] codex-manual → {project}  ~{lines_added} lines added  est. cost \${cost:.4f}')
"
```

---

## Step 7 — Report to the User

```
Delegate finished — <1-line summary>

Files modified:
  - path/to/file.ext (+X / -Y lines)

[If problem]:
<description> — completing manually / relaunching?

Ready to commit?
```

---

## Orchestration Rules

- **Decompose before delegating** — an oversized prompt is guaranteed to fail.
- **Streaming always** — never use `--output text`; it hides errors.
- **Check diff between sub-tasks** — never launch the next one blind.
- **Don't code instead of the delegate** unless it completed ≥50% and crashed.
- **Max 12 turns per Vibe call** — beyond that, context saturates.
- **VERIFY with grep, not file re-read** — `grep -n "def foo" file.py` is reliable.
- **After any run that touches imports: grep the import line** — sequential runs can
  revert each other's import changes.
- **search_replace [OK] ≠ correct change** — always grep the specific changed line.
- **Provide data structure context** — include exact field paths, not just "extract the name".
- **Reuse existing assets** — for UI tasks, tell the delegate to link existing CSS/JS files.

---

## Token Economics

Delegates consume their own provider's tokens (Mistral, Grok, etc.), not Codex tokens.
Codex only receives the compressed final output (~500–1500 tokens/run).

**Approximate pricing:**
- Vibe/Codestral: ~$1.5/M input, ~$7.5/M output
- Claude Sonnet 4.6: ~$3/M input, ~$15/M output
- Typical ratio: ~2x cheaper per token than Claude

Real token counts and cost are printed after every run and appended to:
`.delegate/runs.jsonl`

---

## Run Log Fields

Every `.claude/vibe-skill/tools/delegate` run appends one JSON entry to
`.delegate/runs.jsonl`.

| Field | Type | Description |
|-------|------|-------------|
| `ts` | string | ISO 8601 UTC timestamp |
| `harness` | string | `"vibe"`, `"pi"`, `"opencode"`, etc. |
| `workdir` | string | Absolute project path |
| `project` | string | `basename(workdir)` |
| `prompt_words` | int | Word count of the prompt |
| `agent` | string | Agent used |
| `max_turns` | int | Configured turn limit |
| `timeout_secs` | int | Configured timeout |
| `exit_code` | int | 0=success, 124=timeout, other=error |
| `timed_out` | bool | `true` if `exit_code == 124` |
| `tool_calls` | int | Total tool invocations |
| `files_changed` | int | Files modified (git diff count) |
| `syntax_errors` | int | Syntax errors detected post-run |
| `duration_secs` | float | Total wall-clock duration |
| `tokens_in` | int | Prompt tokens |
| `tokens_out` | int | Completion tokens |
| `tokens_total` | int | Total tokens |
| `cost_usd` | float | Estimated delegate cost in USD |
| `cost_claude_eq` | float | Claude Sonnet 4.6 equivalent cost |
| `model` | string | Active model alias |
| `warn_count` | int | Number of `[WARN]` events |
| `search_replace_fails` | int | Number of `search_replace [FAIL]` events |
| `wrote_nothing` | bool | `true` if ≥3 tool calls but 0 files changed |

---

## Reporting Tools

```bash
.claude/vibe-skill/tools/delegate-report                  # full report (all time)
.claude/vibe-skill/tools/delegate-report --since 7        # last 7 days
.claude/vibe-skill/tools/delegate-report --project myapp  # filter by project
.claude/vibe-skill/tools/delegate-report --fails          # failures and issues only

.claude/vibe-skill/tools/delegate-dashboard               # one-shot dashboard (plain text or rich TUI)
.claude/vibe-skill/tools/delegate-dashboard --refresh 10  # auto-refresh every 10 seconds
.claude/vibe-skill/tools/delegate-dashboard --project foo # filter by project
```

**Raw jq queries:**
```bash
# Success rate
jq -r '.exit_code' .delegate/runs.jsonl | sort | uniq -c

# Total cost vs Claude equivalent
jq -r '[.cost_usd, .cost_claude_eq] | @tsv' .delegate/runs.jsonl \
  | awk '{c+=$1; e+=$2} END {printf "Spent: $%.4f  Claude eq: $%.4f  Saved: $%.4f\n", c, e, e-c}'

# Per-harness breakdown
jq -r '.harness' .delegate/runs.jsonl | sort | uniq -c | sort -rn
```
