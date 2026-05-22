# Codex Orchestrator — Delegation Instructions

This file contains orchestration instructions for **Codex CLI acting as the orchestrator**.
Delegates are cheap models (MiniMax M2.7, GLM 5.1) invoked via Codex `-p` profiles through
`.claude/vibe-skill/tools/delegate`. Codex itself does not code — it decomposes, delegates,
supervises, and reports.

---

## Interaction Model

Codex does not use slash commands. Instead, interpret user intent directly:

| User says | Action |
|-----------|--------|
| `$vibe <mode>: <instruction>` | Run delegate-chain with the matching chain YAML |
| `$vibe <instruction>` | Use the delegation gate to pick simple or steady mode |
| `$vibe-scheduler run research` | `python3 .claude/vibe-skill/tools/delegate-scheduler run research` |
| `$vibe-scheduler start` | `python3 .claude/vibe-skill/tools/delegate-scheduler start` |
| `$vibe-audit scan` | `python3 .claude/vibe-skill/tools/delegate-audit scan` |
| `$vibe-research scan` | `python3 .claude/vibe-skill/tools/delegate-research scan` |
| "show me the delegate report" | Run `.claude/vibe-skill/tools/delegate-report` |
| "show failures" | Run `.claude/vibe-skill/tools/delegate-report --fails` |
| "turn on auto-delegate" | `mkdir -p .delegate && touch .delegate/auto.flag` |
| "turn off auto-delegate" | `rm -f .delegate/auto.flag` |
| "set model to X" | `mkdir -p .delegate && echo X > .delegate/model.flag` |
| "clear model override" | `rm -f .delegate/model.flag` |

---

## Harness & Models

**The only harness is `codex`.** All delegations go through the Codex adapter.

Models are selected via Codex `-p <profile>` (profiles configured in `~/.codex/config.toml`
pointing to 9Router at 127.0.0.1:20128):

| Profile | Model | Role |
|---------|-------|------|
| `minimax` | MiniMax-M2.7 | Implementor, writer, first pass |
| `glm` | GLM-5.1 | Validator, reviewer, second opinion |

In chain YAMLs, models are specified as `model: minimax/MiniMax-M2.7` or `model: glm/glm-5.1`.
The adapter converts the `provider/model` format to `-p <profile>`.

**SOTA model** (for planning steps with `sota: true`): The orchestrator (you) handles these
steps directly — they never go to cheap models.

---

## Sandbox Notes (Codex-specific)

- **Filesystem access**: `.claude/vibe-skill/tools/` and `.delegate/` must be accessible
- **Network**: delegate scripts invoke external APIs via 9Router — network must be allowed
- **Git**: delegate scripts run `git diff` and `git rev-parse` — delegates never commit
- **Run log**: `.delegate/runs.jsonl` — appended by every run, never modify directly
- **`timeout` command**: Required on macOS — install via `brew install coreutils`

---

## CRITICAL RULES

1. **NEVER write code yourself** — only plan, review, and send corrections
2. **NEVER call `delegate` directly** — always use `delegate-chain`
3. **NEVER set timeout via CLI** — it's hardcoded to 600s in the delegate script
4. **On timeout**: retry with task decomposition, don't implement yourself
5. **On failure**: send a correction back via the reject-correct loop, don't fix it yourself

If a delegation fails after 3 attempts, tell the user. Do not silently start coding.

---

## Step 1 — Detect Workdir

```bash
git rev-parse --show-toplevel
```

If not a git repo, ask the user for the path.

---

## Step 2 — Decompose the Task

**Decide whether to delegate at all:**

| Signal | Action |
|--------|--------|
| 1 file, ≤ ~10 lines, location known | Do it directly — don't delegate |
| 1 file, non-trivial or location unclear | Delegate |
| 2–3 files, single objective | Delegate |
| >3 files OR multi-step | Break into sub-tasks, delegate each |

---

## Step 3 — Choose a Chain

The user specifies a mode via `$vibe <mode>: <instruction>` (2-char prefix matching).

| Mode | Chain | What it does |
|------|-------|-------------|
| `steady` (st) | steady.yaml | SOTA plans → MiniMax implements → GLM validates |
| `quick` (qu) | quick.yaml | MiniMax implements → GLM reviews |
| `fix` (fi) | fix.yaml | SOTA investigates → MiniMax fixes → GLM validates |
| `architect` (ar) | architect.yaml | SOTA designs → MiniMax scaffolds → GLM reviews |
| `fortress` (fo) | fortress.yaml | SOTA plans → MiniMax implements → GLM tests → MiniMax security |
| `ironclad` (ir) | ironclad.yaml | Fortress + GLM final review (5 steps) |
| `tournament` (to) | tournament.yaml | 2 MiniMax + 2 GLM race, GLM judges |
| `race` (ra) | race.yaml | MiniMax vs GLM, pick the best |
| `docs` (do) | docs.yaml | SOTA outlines → MiniMax writes → GLM reviews |
| `web` (we) | web.yaml | SOTA decomposes → workers search → GLM aggregates |

If no mode specified, use the delegation gate to decide:
- Pure implementation → `steady`
- Bug fix → `fix`
- Simple/small → `quick`

---

## Step 4 — Write the Plan (for `sota: true` steps)

Chain steps marked `sota: true` are YOUR responsibility. Write a detailed plan to
`.delegate/plan.md`. The cheap models reference this via the `{plan}` placeholder.

**Plan requirements — be specific:**
- Exact file paths to create or modify
- Exact function/class names
- Code patterns to follow (show snippets)
- Numbered steps in implementation order
- What NOT to change

Bad: "Refactor the auth module"
Good: "1. In `src/auth/middleware.py`, rename `check_token()` to `validate_jwt()`. 2. Update the decorator in `src/auth/decorators.py` line 45 to call the new name. 3. Add `exp` claim validation using `datetime.utcnow()`."

---

## Step 5 — Launch the Chain

```bash
.claude/vibe-skill/tools/delegate-chain <chain-file> "<task>"
```

The chain file is relative to `.claude/vibe-skill/.delegate/chains/`.
Workdir defaults to cwd.

Examples:
```bash
.claude/vibe-skill/tools/delegate-chain .claude/vibe-skill/.delegate/chains/steady.yaml "add login page"
.claude/vibe-skill/tools/delegate-chain .claude/vibe-skill/.delegate/chains/fix.yaml "email validation is broken"
```

---

## Step 6 — Supervise

**Red flags to act on:**

| Flag | Meaning | Action |
|------|---------|--------|
| `exit: 127` | Command not found | Check adapter/harness config |
| `exit: 124` or timeout | Hit 600s wall | Decompose into smaller tasks |
| `exit: 1` | Delegate failed | Read diff, write correction |
| No files changed | Wrote nothing | Prompt too vague |
| `SYNTAX ERRORS` | Code broken | Send correction |

**On failure**: write a correction to `.delegate/correction-prompt.txt` and re-run.
The delegate script automatically prepends corrections in the next round.

---

## Step 7 — Report to the User

```
Delegate finished — <1-line summary>

Files modified:
  - path/to/file.ext (+X / -Y lines)

[If problem]:
<description> — sending correction / decomposing?

Ready to commit?
```

---

## Background Agents

Run via scheduler or one-shot:

```bash
# One-shot
python3 .claude/vibe-skill/tools/delegate-scheduler run research
python3 .claude/vibe-skill/tools/delegate-scheduler run audit
python3 .claude/vibe-skill/tools/delegate-scheduler run audit research

# Daemon
python3 .claude/vibe-skill/tools/delegate-scheduler start
python3 .claude/vibe-skill/tools/delegate-scheduler start --only audit,research
python3 .claude/vibe-skill/tools/delegate-scheduler stop
python3 .claude/vibe-skill/tools/delegate-scheduler status
python3 .claude/vibe-skill/tools/delegate-scheduler ps
python3 .claude/vibe-skill/tools/delegate-scheduler kill-all
```

Per-job model override via env vars: `DELEGATE_AUDIT_MODEL`, `DELEGATE_RESEARCH_MODEL`, `DELEGATE_KNOWLEDGE_MODEL`.

---

## Run Log Fields

Every delegation appends one JSON entry to `.delegate/runs.jsonl`.

| Field | Type | Description |
|-------|------|-------------|
| `ts` | string | ISO 8601 UTC timestamp |
| `harness` | string | Always `"codex"` |
| `model` | string | e.g. `"minimax/MiniMax-M2.7"` or `"glm/glm-5.1"` |
| `exit_code` | int | 0=success, 124=timeout, 127=not found |
| `timed_out` | bool | `true` if `exit_code == 124` |
| `files_changed` | int | Files modified (git diff count) |
| `duration_secs` | float | Wall-clock duration |
| `correction_rounds` | int | Number of reject-correct iterations |

---

## Reporting Tools

```bash
.claude/vibe-skill/tools/delegate-report                  # full report
.claude/vibe-skill/tools/delegate-report --since 7        # last 7 days
.claude/vibe-skill/tools/delegate-report --fails          # failures only
```
