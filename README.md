<!-- Suggested GitHub topics: claude-code, llm-tools, mistral, gemini-cli, ai-coding, shell, developer-tools, vibe-coding -->

# vibe-skill

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg) ![Shell](https://img.shields.io/badge/language-Shell-green.svg) ![GitHub stars](https://img.shields.io/github/stars/pcx-wave/vibe-skill?style=social) ![Claude Code skill](https://img.shields.io/badge/-Claude%20Code%20skill-CC785C)

**Claude orchestrates. Cheap coding agents do the heavy lifting. You review the diff, save tokens, costs, and avoid hitting limits.**

> **This is a fork.** The [original vibe-skill](https://github.com/pcx-wave/vibe-skill) delegates to Vibe only. This fork extends it into a **multi-harness delegation framework** with 16 new features. Everything below this box is new.

---

### What's New in This Fork

<table>
<tr>
<td width="50%" valign="top">

**Multi-Harness Support**
Route tasks to **Vibe**, **Pi**, or **OpenCode** — not just Mistral. Each harness has its own adapter. Use `/delegate <harness> <instruction>` or let the router pick for you.

**Reject-and-Correct Loop**
The orchestrator **never writes code itself**. When a delegate makes a mistake, Claude sends a correction prompt *back* to the cheap model instead of fixing it with expensive tokens. Max 2 rounds, then escalate.

**Rollback Checkpoints**
Every delegation auto-creates a git branch checkpoint. If things go wrong, one command rolls back — including any commits the delegate created.

**Delegation Contracts**
Define pre/post conditions in `.delegate/contracts.yaml`. Pre-checks block bad delegations before they start. Post-checks auto-trigger corrections when results fail.

**Parallel Delegation**
Run independent tasks simultaneously, each in its own git worktree. File overlap is detected before dispatch — conflicting tasks run sequentially, everything else runs in parallel.

**Multi-Step Chains**
Define workflows like `planner -> implementor -> validator` in YAML. Each step can use a **different harness and model** — e.g., Pi (MiniMax) implements, Pi (GLM) reviews, Claude validates.

</td>
<td width="50%" valign="top">

**Harness-Aware Routing**
The system learns which harness performs best for which task type (refactor, bugfix, greenfield, etc.) from your run history and recommends the optimal one.

**Context Distillation**
Auto-generates a compressed project brief (stack, key files, data models, conventions) so Claude doesn't waste tokens re-reading the same codebase every delegation.

**Failure Memory + Learning Loop**
Records *why* delegations fail and *how* they were fixed. Before the next similar task, relevant warnings are injected into the prompt automatically.

**AST Validation + Duplicate Detection**
Goes beyond syntax checks — catches changed function signatures, functions defined but never called, duplicate definitions, merge conflict markers, and reverted imports.

**Smart Batching**
For bulk tasks like "add docstrings to all functions," auto-groups by file and runs batches within the harness turn limit.

**Session Replay**
Full session recording. When something goes wrong, step through the delegate's tool calls turn-by-turn to see exactly where it went off track.

**Live Dashboard**
TUI dashboard showing active runs, cost burn rate, success streaks, per-harness stats, and 7-day failure trends. Uses `rich` with plain-text fallback.

**Codex Orchestrator**
Codex CLI can be the manager too — same delegate scripts, different orchestrator. Install to `.codex/AGENTS.md` in your project.

</td>
</tr>
</table>

> **Full usage guide:** [`docs/usage-guide.md`](docs/usage-guide.md) | **Feature roadmap:** [`docs/feature-roadmap.md`](docs/feature-roadmap.md)

---

Claude sees only ~500–1500 tokens per run regardless of how many file reads the delegate performs internally — massive savings on exploratory and implementation tasks.

Supports **Vibe (Mistral), Pi (earendil-works), and OpenCode** as delegate harnesses. Vibe works natively with Mistral models (capable and significantly cheaper than Claude), but can also be configured to use any other provider/model such as DeepSeek.

Summary:
1. User types `/vibe <instruction>` or `/delegate <harness> <instruction>` in Claude Code
2. Claude decomposes the task and writes a prompt
3. `delegate` routes to the right harness adapter and runs the coding agent
4. The delegate reports tool calls, token counts, and `git diff --stat`
5. Claude reviews the diff and summarizes the result — sending corrections back to the harness if needed

---

## Why

**Cost savings** — The delegate's file reads and edits consume cheap harness tokens (or whatever model you configure), not Claude tokens:

| Scenario | Claude Sonnet 4.6 | Mistral Medium 3.5 | DeepSeek V4 Flash |
|----------|-------------------|--------------------|-------------------|
| Simple 1-file tweak (800 tokens) | ~$0.004 | ~$0.002 | ~$0.0001 |
| 6-read implementation task (4,800 tokens) | ~$0.023 | ~$0.012 | ~$0.0008 |
| Complex multi-file refactor (12,000 tokens) | ~$0.058 | ~$0.029 | ~$0.002 |

> Costs based on official pricing (May 2026): Claude $3/$15 per M tokens, Mistral Medium 3.5 $1.50/$7.50, DeepSeek V4 Flash $0.14/$0.28. Assumes ~85% input / 15% output, typical for coding tasks. Claude orchestration overhead: ~500 tokens per run (negligible).

> **Le Chat Pro users:** Mistral Vibe is included in the [Le Chat Pro](https://mistral.ai/pricing) subscription (~$18/mo). Mistral does not publicly document the exact usage limits, but community reports suggest ~1–1.5B tokens/month are included. Within that allowance every delegation costs $0 in API fees — cheaper than any paid model.

### Real-world stats (254 runs, May 2026)

**Cost savings observed over 10 days across 57M tokens delegated:**

| | Amount |
|---|---|
| Actually paid (sub prorated + deepseek) | **$10.35** |
| Same workload pay-as-you-go | $46.61 |
| Same workload on Claude Sonnet | $179.91 |
| Saved vs Claude | **$169.56 (17.4× cheaper)** |

**Should you subscribe to Mistral Pro, or just use DeepSeek?**

DeepSeek alone ($0.14/M blended) is cheaper than the Mistral Pro subscription (~$18/mo) until you hit **~131M tokens/month**:

```
tokens/month  │ DeepSeek only │ Mistral Pro sub │ Verdict
──────────────┼───────────────┼─────────────────┼──────────────────────────
  50M         │  $7.03        │  $18.36         │ DeepSeek cheaper
  84M (now)   │  $11.80       │  $18.36         │ DeepSeek cheaper
 131M         │  $18.41       │  $18.36         │ ← break-even
 200M         │  $28.10       │  $18.36         │ Mistral Pro worth it
 500M         │  $70.25       │  $18.36         │ Mistral Pro worth it
```

Above 131M tokens/month, subscribe to Mistral Pro and use it until the quota (~1B–1.5B tokens) is exhausted — then fall back to DeepSeek. Never let Mistral roll into pay-as-you-go ($1.52/M blended — 10× more expensive than DeepSeek).

**Reliability (deepseek-flash, 178 runs):**

| Failure type | Rate | Root cause |
|---|---|---|
| `sr_fail` (search/replace miss) | 19% of runs | Model reconstructs SEARCH block from memory instead of exact file bytes |
| `empty` (wrote nothing) | 12% of runs | Vague prompt or task already done; model stops without writing |
| `warn` (non-fatal) | 21% of runs | Usually harmless; check `[WARN]` lines in output |
| Hard failure (exit error) | 1.7% of runs | — |

Mitigation: grep for the exact target before constructing the SEARCH block; phrase prompts as imperative verbs with an explicit file target.

**Context window protection** — On long coding sessions, every file read, function body, and debug loop burns Claude's context. Delegating keeps that budget free. Claude enters the task, hands off, and comes back only to review the result — no context bleed from the harness's internal turns.

**Built-in quality gate** — Claude doesn't just fire and forget. After each run, Claude reads the `git diff`, checks for syntax errors, and summarizes what changed before reporting back to you. You get a second pair of eyes on every delegation without lifting a finger.

---

## Prerequisites

- [Mistral Vibe](https://vibe.mistral.ai/) CLI installed and authenticated (`vibe --version`) — required for the `vibe` harness
- [Pi](https://earendil.works) CLI — optional, for the `pi` harness
- [OpenCode](https://opencode.ai) CLI — optional, for the `opencode` harness
- [Claude Code](https://claude.ai/code) with skills enabled
- `script` command available (GNU/Linux or BSD/macOS variant)
- `timeout` command available; on macOS install GNU coreutils for `gtimeout` (or ensure your chosen `timeout` fallback is set up)
- `python3` and optionally `node` for syntax checks
- A git repository to work in

---

## Installation

```bash
git clone https://github.com/pcx-wave/vibe-skill.git && cd vibe-skill && \
mkdir -p ~/tools \
  ~/.claude/skills/vibe \
  ~/.claude/skills/vibeon \
  ~/.claude/skills/vibeoff \
  ~/.claude/skills/vibestatus \
  ~/.claude/skills/vibe-model-pick \
  ~/.claude/skills/vibe-model-clear \
  ~/.claude/skills/vibe-report && \
ln -sf "$(pwd)/tools/delegate"              ~/tools/delegate && \
ln -sf "$(pwd)/tools/vibe-delegate"         ~/tools/vibe-delegate && \
ln -sf "$(pwd)/tools/delegate-report"       ~/tools/delegate-report && \
ln -sf "$(pwd)/tools/delegate-rollback"     ~/tools/delegate-rollback && \
ln -sf "$(pwd)/tools/delegate-reject"       ~/tools/delegate-reject && \
ln -sf "$(pwd)/tools/delegate-contracts"    ~/tools/delegate-contracts && \
ln -sf "$(pwd)/tools/delegate-distill"      ~/tools/delegate-distill && \
ln -sf "$(pwd)/tools/delegate-failures"     ~/tools/delegate-failures && \
ln -sf "$(pwd)/tools/delegate-learnings"    ~/tools/delegate-learnings && \
ln -sf "$(pwd)/tools/delegate-router"       ~/tools/delegate-router && \
ln -sf "$(pwd)/tools/delegate-parallel"     ~/tools/delegate-parallel && \
ln -sf "$(pwd)/tools/delegate-ast-check"    ~/tools/delegate-ast-check && \
ln -sf "$(pwd)/tools/delegate-check-duplicates" ~/tools/delegate-check-duplicates && \
ln -sf "$(pwd)/tools/delegate-batch"        ~/tools/delegate-batch && \
ln -sf "$(pwd)/tools/delegate-chain"        ~/tools/delegate-chain && \
ln -sf "$(pwd)/tools/delegate-replay"       ~/tools/delegate-replay && \
ln -sf "$(pwd)/tools/delegate-dashboard"    ~/tools/delegate-dashboard && \
chmod +x ~/tools/delegate ~/tools/vibe-delegate ~/tools/delegate-report && \
ln -sf "$(pwd)/SKILL.md"           ~/.claude/skills/vibe/SKILL.md && \
ln -sf "$(pwd)/VIBEON.md"          ~/.claude/skills/vibeon/SKILL.md && \
ln -sf "$(pwd)/VIBEOFF.md"         ~/.claude/skills/vibeoff/SKILL.md && \
ln -sf "$(pwd)/VIBESTATUS.md"      ~/.claude/skills/vibestatus/SKILL.md && \
ln -sf "$(pwd)/VIBE-MODEL-PICK.md" ~/.claude/skills/vibe-model-pick/SKILL.md && \
ln -sf "$(pwd)/VIBE-MODEL-CLEAR.md" ~/.claude/skills/vibe-model-clear/SKILL.md && \
ln -sf "$(pwd)/VIBE-REPORT.md"     ~/.claude/skills/vibe-report/SKILL.md
```

### Step-by-step

```bash
# 1. Clone this repo
git clone https://github.com/pcx-wave/vibe-skill.git
cd vibe-skill

# 2. Install core scripts (symlinks — stay in sync with git pull)
mkdir -p ~/tools
ln -sf "$(pwd)/tools/delegate"           ~/tools/delegate
ln -sf "$(pwd)/tools/vibe-delegate"      ~/tools/vibe-delegate   # backward-compat shim
ln -sf "$(pwd)/tools/delegate-report"    ~/tools/delegate-report
chmod +x ~/tools/delegate ~/tools/vibe-delegate ~/tools/delegate-report

# 3. Install advanced tools (optional but recommended)
ln -sf "$(pwd)/tools/delegate-rollback"          ~/tools/delegate-rollback
ln -sf "$(pwd)/tools/delegate-reject"            ~/tools/delegate-reject
ln -sf "$(pwd)/tools/delegate-contracts"         ~/tools/delegate-contracts
ln -sf "$(pwd)/tools/delegate-distill"           ~/tools/delegate-distill
ln -sf "$(pwd)/tools/delegate-failures"          ~/tools/delegate-failures
ln -sf "$(pwd)/tools/delegate-learnings"         ~/tools/delegate-learnings
ln -sf "$(pwd)/tools/delegate-router"            ~/tools/delegate-router
ln -sf "$(pwd)/tools/delegate-parallel"          ~/tools/delegate-parallel
ln -sf "$(pwd)/tools/delegate-ast-check"         ~/tools/delegate-ast-check
ln -sf "$(pwd)/tools/delegate-check-duplicates"  ~/tools/delegate-check-duplicates
ln -sf "$(pwd)/tools/delegate-batch"             ~/tools/delegate-batch
ln -sf "$(pwd)/tools/delegate-chain"             ~/tools/delegate-chain
ln -sf "$(pwd)/tools/delegate-replay"            ~/tools/delegate-replay
ln -sf "$(pwd)/tools/delegate-dashboard"         ~/tools/delegate-dashboard

# 4. Install skills for Claude Code
mkdir -p ~/.claude/skills/vibe ~/.claude/skills/vibeon ~/.claude/skills/vibeoff \
         ~/.claude/skills/vibestatus ~/.claude/skills/vibe-model-pick \
         ~/.claude/skills/vibe-model-clear ~/.claude/skills/vibe-report
ln -sf "$(pwd)/SKILL.md"            ~/.claude/skills/vibe/SKILL.md
ln -sf "$(pwd)/VIBEON.md"           ~/.claude/skills/vibeon/SKILL.md
ln -sf "$(pwd)/VIBEOFF.md"          ~/.claude/skills/vibeoff/SKILL.md
ln -sf "$(pwd)/VIBESTATUS.md"       ~/.claude/skills/vibestatus/SKILL.md
ln -sf "$(pwd)/VIBE-MODEL-PICK.md"  ~/.claude/skills/vibe-model-pick/SKILL.md
ln -sf "$(pwd)/VIBE-MODEL-CLEAR.md" ~/.claude/skills/vibe-model-clear/SKILL.md
ln -sf "$(pwd)/VIBE-REPORT.md"      ~/.claude/skills/vibe-report/SKILL.md

# 5. (Optional) Enable auto-mode — Claude delegates all code tasks automatically
#    without requiring /vibe each time. Toggle with /vibeon and /vibeoff.
grep -q "vibe auto-mode" ~/.claude/CLAUDE.md 2>/dev/null || cat >> ~/.claude/CLAUDE.md << 'EOF'

# vibe auto-mode
At the start of every user request that involves writing, editing, or fixing code:
1. Run `test -f ~/.local/share/vibe-auto.flag` (silent, no output to user).
2. If the flag exists → automatically invoke the `vibe` skill exactly as if the user had typed `/vibe <their full instruction>`. Do NOT ask first, do NOT explain — just delegate.
3. If the flag is absent → proceed normally.

The flag is toggled by `/vibeon` and `/vibeoff`.
EOF
```

Verify with `~/tools/delegate vibe /tmp "Say hello in one sentence." 3`

### Updating

Because both installs use symlinks, a `git pull` is all you need:

```bash
cd ~/vibe-skill && git pull
```

All tools and skills update automatically — no re-copy needed.

> **Migrating from a previous `cp`-based install?** Replace the copies with symlinks:
> ```bash
> cd ~/vibe-skill
> ln -sf "$(pwd)/tools/delegate" ~/tools/delegate
> ln -sf "$(pwd)/tools/vibe-delegate" ~/tools/vibe-delegate
> ln -sf "$(pwd)/SKILL.md" ~/.claude/skills/vibe/SKILL.md
> ```

---

## Usage

### Basic delegation

In a Claude Code session, delegate to the default harness (Vibe):

```
/vibe add a dark mode toggle to the settings page
```

```
/vibe the login form is not validating the email field — fix it
```

```
/vibe add pagination to the GET /posts route, 20 items per page
```

### Multi-harness delegation

Use `/delegate` to specify a harness explicitly:

```
/delegate vibe add pagination to the GET /posts route
/delegate pi refactor the auth middleware into its own module
/delegate opencode add docstrings to all public functions in utils.py
```

Claude decomposes the task, writes the prompt, supervises execution, and reports the diff. If the output has fixable issues, Claude sends a correction back to the harness (reject-correct loop) rather than writing the fix itself.

### Advanced commands

```
/delegate-dashboard     — live TUI showing active runs, cost, and trends
/delegate-batch <task>  — smart batching for bulk tasks ("add docstrings to all functions")
/delegate-chain <chain> — multi-step workflow (planner → implementor → validator)
/delegate-route <desc>  — recommend best harness based on run history
```

### Model selection

By default, Vibe uses whatever `active_model` is set in `~/.vibe/config.toml`. You can override it per-session without touching that file:

```
/vibe-model-pick              — interactive menu built from your config.toml models
/vibe-model-pick devstral-small  — switch directly by alias
/vibe-model-clear             — remove the override, return to config default
/vibestatus                   — shows both auto-mode state and active model override
```

The override is stored in `~/.local/share/vibe-model.flag` and is picked up by `delegate` on every run. It persists across sessions until you clear it.

### Vibe-auto mode

For frictionless delegation, enable auto-mode once in your Claude Code session:

```
/vibeon      — every code request is automatically delegated to Vibe, no /vibe prefix needed
/vibeoff     — return to normal Claude behaviour
/vibestatus  — auto-mode state + active model override
```

With `vibeon` active, just talk to Claude normally:

```
add pagination to the /posts route
fix the broken email validation
refactor the auth middleware into its own module
```

Claude intercepts any request that involves writing, editing, or fixing code and delegates it to Vibe transparently. Pure questions and conversations still go directly to Claude — only code tasks are delegated.

---

## Terminal output

Sample output from a real run:

```
=== VIBE START ===
Workdir : /path/to/project
Agent   : default
Model   : (config default)
Turns   : 10
Timeout : 180s
Prompt  : Stack: Python/Flask. File: app.py ...
===================
  [read]  app.py
  [tool]  file: app.py
  [tool]  search_replace [OK] ...
  [vibe]  Done. Converted date to datetime.date in fetch_data().
Tool calls: 5  |  warns: 0  |  sr_fails: 0
Model               : deepseek-flash
Delegate tokens (run): 4,800  (last turn: 4,600+200)  |  cost ~$0.0007
Claude Sonnet 4.6 eq: same tokens would cost ~$0.0168  (ratio x24.0)
=== VIBE DONE (exit: 0) ===
=== SYNTAX OK (1 file(s) checked) ===

=== UNCOMMITTED CHANGES ===
 app.py | 4 ++--
[log] → ~/.local/share/delegate-runs.jsonl  (4800 tokens, exit 0, 34.2s, saved ~$0.0161 vs Claude)
```

---

## Architecture

```
Claude Code  /  Codex CLI
  └─ /vibe <instruction>  OR  /delegate <harness> <instruction>
       └─ SKILL.md / CODEX-SKILL.md logic
            └─ ~/tools/delegate <harness> <workdir> <prompt> [turns] [agent] [timeout]
                 ├─ delegate-rollback: git branch checkpoint (pre-run)
                 ├─ delegate-distill: inject .delegate/project-brief.md
                 ├─ delegate-contracts: run pre-conditions
                 │
                 ├─ tools/adapters/vibe     → script pseudo-TTY + vibe --output streaming
                 ├─ tools/adapters/pi       → pi --mode json -p "prompt"
                 └─ tools/adapters/opencode → opencode run --format json --dir <workdir> --dangerously-skip-permissions "prompt"
                 │
                 └─ shared post-run pipeline (all harnesses):
                      ├─ delegate-contracts: run post-conditions
                      ├─ delegate-check-duplicates: catch known harness bugs
                      ├─ delegate-ast-check: semantic validation
                      ├─ syntax checks (.py, .js)
                      ├─ git diff --stat
                      └─ JSONL log → ~/.local/share/delegate-runs.jsonl
```

**Reject-correct loop** — if the diff has fixable issues, Claude sends a correction back to the harness (max 2 rounds) rather than writing the fix itself. All code generation stays on cheap delegate tokens.

**Orchestrator vs harness distinction:**

| Role | Tools |
|------|-------|
| Orchestrators (review, route, write prompts) | Claude Code, Codex CLI |
| Delegate harnesses (write code cheaply) | Vibe (Mistral), Pi, OpenCode |

---

## Tools Reference

All tools live in `~/tools/` (symlinked from the repo's `tools/` directory).

| Tool | Purpose |
|------|---------|
| `delegate` | Generic delegation entry point: `delegate <harness> <workdir> <prompt> [turns] [agent] [timeout]` |
| `vibe-delegate` | Backward-compat shim — calls `delegate vibe "$@"` |
| `adapters/vibe` | Vibe harness adapter (pseudo-TTY, JSON stream parser, token extraction) |
| `adapters/pi` | Pi harness adapter: `pi --mode json -p "prompt"` |
| `adapters/opencode` | OpenCode adapter: `opencode run --format json --dir <workdir> --dangerously-skip-permissions "prompt"` |
| `delegate-rollback` | Git branch checkpoints: auto-created before each run, auto-cleaned on success, preserved on failure |
| `delegate-reject` | Write a correction prompt for the reject-correct loop |
| `delegate-correct` | Send a correction directly to the harness |
| `delegate-contracts` | Run pre/post conditions from `.delegate/contracts.yaml` |
| `delegate-distill` | Generate `.delegate/project-brief.md` for context injection |
| `delegate-failures` | Failure memory — record and query past failures |
| `delegate-learnings` | Learning loop — capture correction patterns, suggest prompt improvements |
| `delegate-router` | Recommend best harness based on run history and task type |
| `delegate-parallel` | Run tasks in parallel via git worktrees |
| `delegate-ast-check` | AST-level semantic validation (shadowed vars, broken signatures, unused exports) |
| `delegate-check-duplicates` | Detect duplicate function definitions and known harness regressions |
| `delegate-batch` | Smart batching — groups bulk tasks by file |
| `delegate-chain` | Multi-step delegation workflows: `delegate-chain <workdir> <chain.yaml>` |
| `delegate-replay` | Step-by-step replay of recorded sessions for debugging |
| `delegate-dashboard` | Live TUI dashboard (requires `rich`; falls back to plain text) |
| `delegate-report` | Historical token/cost/failure report across all runs |

---

## Feature Overview

### Multi-harness support

Three delegate harnesses, same post-run pipeline:

| Harness | Status | Invocation |
|---------|--------|-----------|
| `vibe` | Active | Mistral Vibe CLI via pseudo-TTY, `--output streaming` |
| `pi` | Stub | `pi --mode json -p "prompt"` |
| `opencode` | Stub | `opencode run --format json --dir <workdir> --dangerously-skip-permissions "prompt"` |

### Rollback checkpoints

`delegate-rollback` creates a git branch checkpoint before each delegation. On success it cleans up automatically. On failure the branch is preserved — `delegate-rollback rollback <workdir> <branch>` restores the previous state.

### Reject-and-correct loop

The orchestrator never writes code itself. After reviewing the diff it classifies:
- `accept` — changes look correct, done
- `reject-correct` — specific fixable issue, sent back to harness via `delegate-reject`
- `reject-retry` — wrong approach, full re-run with new prompt
- `reject-abort` — unfixable, escalate to user

Max 2 correction rounds before escalating. All code generation stays on cheap delegate tokens.

### Delegation contracts

`.delegate/contracts.yaml` defines pre/post conditions per project. Pre-conditions block delegation if they fail. Post-conditions auto-trigger reject-correct if they fail, allowing fully mechanical acceptance for routine tasks.

### Context distillation

`delegate-distill` generates `.delegate/project-brief.md` — stack, key files, data models, conventions. Auto-injected into every delegation prompt so Claude stops re-reading the same project structure on every task.

### Failure memory + learning loop

`delegate-failures` records structured failure events (file, harness, error type, symptom, fix). Injected as warnings before similar future delegations. `delegate-learnings` captures correction patterns from reject-correct cycles and suggests prompt improvements over time.

### Parallel delegation

`delegate-parallel` runs independent sub-tasks concurrently in separate git worktrees. Each harness runs in isolation; results are merged after all complete.

### Harness-aware routing

`delegate-router` builds a routing table from `delegate-runs.jsonl` — success rates per harness per task type. Use `/delegate-route <description>` to get a recommendation before delegating manually, or let the system suggest the best harness automatically.

### AST validation + duplicate detector

`delegate-ast-check` compares AST before and after: function signatures, imports, class hierarchies. `delegate-check-duplicates` catches Vibe's known code-duplication bug and merge conflict markers.

### Smart batching

`delegate-batch` detects bulk-style prompts ("add docstrings to all functions") and groups work by file — 1 delegation per file instead of 1 per function. Estimates total cost before starting.

### Delegation chains

`delegate-chain` runs multi-step workflows defined in `.delegate/chains/*.yaml`. Pre-built chains: `implement`, `bugfix`. Each step passes its output to the next; chains abort on failure and roll back.

### Session replay

`delegate-replay` renders a full step-by-step playback of a recorded session — what the harness read, what it changed, and why — for debugging failures and refining prompts.

### Live dashboard

`delegate-dashboard` shows a real-time TUI view of active runs, token burn, cost today/this week, failure rate trend, and per-project breakdown. Falls back to plain text if `rich` is unavailable.

### Codex orchestrator

`CODEX-SKILL.md` ports the orchestration logic so Codex CLI can act as the manager — decomposing tasks, delegating to Vibe/Pi/OpenCode, and reviewing diffs — with the same economic model as Claude Code.

Install into your project (does NOT overwrite existing `AGENTS.md`):
```bash
mkdir -p <project>/.codex
cp CODEX-SKILL.md <project>/.codex/AGENTS.md
```
Codex walks from repo root to CWD and concatenates all `AGENTS.md` files it finds — `.codex/AGENTS.md` is appended, never replaces the root one.

---

## Shell vs Python split

`vibe-delegate` started as pure shell. Python is embedded in four places where shell falls short:

| What | Why Python |
|------|-----------|
| JSON stream parser (live output) | Vibe emits a JSON stream; shell can't reliably parse it line by line without race conditions |
| Token count + cost calculation | Reads `~/.vibe/config.toml` (TOML parsing), looks up per-model pricing, handles float arithmetic |
| Syntax check (`py_compile`) | stdlib module — one line, no dependencies |
| Run log writer | Builds a structured JSON entry with multiple computed fields; shell heredoc+`jq` would be fragile |

`delegate-report` is fully Python: it aggregates, sorts, and formats tabular data across hundreds of log entries — the kind of work where shell pipelines become unmaintainable.

---

## Reporting

Every run is logged to `~/.local/share/delegate-runs.jsonl` with tokens, cost, model, harness, and failure details. Query it with:

```bash
~/tools/delegate-report                  # full report (all time)
~/tools/delegate-report --since 7        # last 7 days
~/tools/delegate-report --project myapp  # filter by project
~/tools/delegate-report --fails          # failures and issues only
```

Or from Claude Code: `/vibe-report [args]`

---

## Examples

- `examples/good-prompts.md` — prompt patterns that reliably work
- `examples/anti-patterns.md` — what fails and why, with fixes

---

## Sister project

A parallel delegate using **Gemini CLI** is available at [pcx-wave/gemini-skill](https://github.com/pcx-wave/gemini-skill). Same orchestration pattern, same run log format — different model and trade-offs. Both write to the same `delegate-runs.jsonl`, making runs comparable across delegates.

---

## Feedback

See [`docs/feedback-claude-sonnet.md`](docs/feedback-claude-sonnet.md) for original feedback from Claude after hours of practice that drove the iterations on `vibe-delegate` — real bugs hit, root causes, and the fixes applied.

---

## License

MIT
