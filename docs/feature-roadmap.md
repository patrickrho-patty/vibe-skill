# Feature Roadmap

Planned features for evolving vibe-skill from a single-harness Vibe delegator
into a multi-harness, self-improving delegation framework.

---

## Status Legend

| Status | Meaning |
|--------|---------|
| `planned` | Scoped, not started |
| `in-progress` | Active development |
| `done` | Shipped |
| `blocked` | Waiting on external dependency or open question |

---

## F1 — Multi-Harness Support

**Status:** `planned`

Abstract `vibe-delegate` into a generic `delegate` script with harness-specific
adapters. Support multiple coding agent CLIs beyond Vibe.

**Target delegate harnesses (cheap workers):**
- Vibe (current — Mistral)
- Pi
- OpenCode

These are the models that do the actual coding. They're cheap and disposable.
The orchestrator (Claude Code or Codex) never writes code itself — it delegates
to one of these, reviews the output, and sends corrections back (F13).

**Not in scope (for now):** Aider, Claude Code self-delegation.

**Approach:**
- Common interface: `delegate <harness> <workdir> <prompt> [options]`
- Per-harness adapter handles: invocation flags, TTY requirements, output parsing,
  token extraction, session log location
- Shared post-run pipeline: syntax check, git diff, JSONL logging
- Harness-specific quirks documented per adapter (like Vibe's TTY requirement)

**Open questions:**
- Should adapters be separate scripts (`delegate-vibe`, `delegate-pi`,
  `delegate-opencode`) or a single script with a harness argument?
- How to handle harnesses that commit automatically vs. those that don't?
- Pi and OpenCode: do they support programmatic/non-interactive mode? TTY
  requirements? Streaming JSON output? Token usage reporting? These need
  investigation before adapter work begins.

---

## F2 — Parallel Delegation

**Status:** `planned`

Send independent sub-tasks to 2-3 harnesses simultaneously, diff the results,
pick the best output.

**Approach:**
- Each harness runs in its own git worktree (isolates changes)
- All run concurrently via background processes
- After all complete, a judge evaluates the diffs

**Open questions:**
- **Who judges?** Options under consideration:
  - **(a) The orchestrating LLM (Claude/main model):** simplest, already in the
    loop, but adds cost to the expensive model. Likely the right default — the
    diff review is small (500-1500 tokens) and Claude is already doing this for
    single runs anyway. Judging 3 diffs costs ~3x the review tokens, which is
    still cheap relative to the generation cost saved.
  - **(b) A dedicated cheap judge model:** e.g. Haiku or DeepSeek for
    mechanical comparison. Risk: may miss subtle correctness issues.
  - **(c) Automated heuristics first, LLM judge as tiebreaker:** score by
    syntax pass, test pass, diff size, then only call the LLM if scores are
    close.
- How to handle partial success (harness A edited 3/4 files correctly, B got
  all 4 but introduced a bug)?
- Git worktree cleanup strategy — auto-delete losing branches?

---

## F3 — Harness-Aware Routing

**Status:** `planned`

Learn which harness/model performs best for which task type, and route
automatically.

**Approach:**
- Classify tasks by type: refactor, greenfield, test-writing, bug-fix, docs
- Track success rate per harness per task type from JSONL run log
- Build a routing table that evolves over time
- Claude picks the best harness before delegating, based on the table

**Open questions:**
- **Who routes?** Same question as F2's judge. Leading option: the orchestrating
  LLM reads the routing table and picks. The table is small (a few KB of stats),
  so the token cost is negligible. The main model already decides whether to
  delegate at all (SKILL.md Step 2) — adding "which harness" to that decision
  is natural.
- Minimum sample size before routing kicks in (cold start problem)?
- How to handle ties or new task types with no data?
- Should users be able to pin a harness for certain projects?

---

## F4 — Codex as Orchestrator

**Status:** `planned`

The project currently runs only as a Claude Code skill. Add support for Codex
CLI as an alternative orchestrator — so Codex can be the manager that delegates
to Vibe/Pi/OpenCode, not just Claude Code.

**Architecture distinction:**
```
Orchestrators (the manager — reviews, routes, writes prompts):
  - Claude Code (current)
  - Codex CLI (planned)

Delegate harnesses (the workers — write code cheaply):
  - Vibe (current)
  - Pi (planned, F1)
  - OpenCode (planned, F1)
```

The orchestrator never writes code itself. It decomposes tasks, writes
delegation prompts, reviews diffs, and sends corrections (F13). The delegate
harness does the actual coding on cheap tokens.

**Approach:**
- Port SKILL.md logic into a Codex-compatible skill/plugin format
- Adapt the delegation flow for Codex's execution model (sandboxed vs.
  unsandboxed, how it invokes bash, how it reads files)
- Reuse `vibe-delegate` and the shared post-run pipeline — the delegate
  scripts don't care who called them
- Map Codex's token costs into the comparison framework (Codex-as-orchestrator
  cost vs. Claude-as-orchestrator cost)

**Open questions:**
- What is Codex's skill/plugin format? Is it similar to Claude Code's
  SKILL.md approach or completely different?
- Codex sandboxing: can it call `vibe-delegate` from within its sandbox, or
  does it need to run unsandboxed?
- Does Codex support the equivalent of `/vibeon` auto-mode (persistent state
  across turns)?
- Cost comparison: is Codex cheaper or more expensive than Claude Code as an
  orchestrator? If cheaper, it might become the default manager.

---

## F5 — Failure Memory

**Status:** `planned`

When a run fails, log the failure reason and the fix. Before the next similar
task, check: "last time this harness tried to edit this file, search_replace
failed on UTF-8 — use python str.replace instead."

**Approach:**
- `~/.local/share/delegate-failures.jsonl` — structured failure log
- Fields: file, harness, error_type, symptom, fix_applied, prompt_snippet
- Before each delegation, Claude scans recent failures for the target files
  and injects relevant warnings into the prompt
- Decay old entries (>30 days) to avoid stale advice

**Depends on:** works standalone, but most valuable combined with F3 (routing
can factor in failure history).

---

## F6 — Post-Run Learning Loop

**Status:** `planned`

When Claude fixes a harness's output, capture the delta between the harness
diff and Claude's corrected diff. Over time, this becomes signal for writing
better prompts.

**Approach:**
- After Claude manually edits post-delegation, compute diff-of-diff
- Log: original prompt, harness output diff, Claude's correction diff
- Periodically analyze patterns: "Vibe consistently forgets imports when
  adding new functions" -> auto-inject "remember to add imports" into prompts
- Store in `~/.local/share/delegate-learnings.jsonl`

**Depends on:** F5 (failure memory provides the storage pattern).

---

## F7 — AST-Level Diff Validation

**Status:** `planned`

Go beyond syntax checking — compare the AST before and after to catch semantic
issues like shadowed variables, changed function signatures, or broken call sites.

**Approach:**
- Python: `ast.parse()` before and after, compare function signatures, imports,
  class hierarchies
- JS/TS: use `tsc --noEmit` (already partial), explore tree-sitter for deeper
  analysis
- Flag: new function defined but never called (known Vibe bug), changed
  parameter count on existing function, removed export that other files import

**Open questions:**
- Scope: full AST comparison is expensive. Focus on signatures + exports only?
- Language coverage: Python and JS/TS first, others later?

---

## F8 — Rollback Checkpoints

**Status:** `planned`

Automatically snapshot the working state before each delegation. If the run
produces bad output, roll back cleanly without manual intervention.

**Approach (under evaluation):**
- **Option A — git stash:** simple but pollutes the stash stack, conflicts with
  user's own stashes
- **Option B — temporary commit on a throwaway branch:** `git checkout -b
  delegate-checkpoint-<ts>`, commit, switch back. Clean, inspectable, easy to
  delete
- **Option C — git worktree:** run delegation in an isolated worktree, only
  merge results into main tree if quality checks pass. Cleanest isolation but
  more complex setup

Leading option: **B or C.** Stash is too fragile for automated use.

**Auto-rollback triggers:**
- Syntax errors detected
- Test suite fails (requires F8-adjacent test runner integration)
- Confidence score below threshold (if scoring is implemented)
- User rejects in interactive review

---

## F9 — Duplicate / Regression Detector

**Status:** `planned`

Automated post-run hook that catches Vibe's known code-duplication bug and
similar regressions, instead of relying on manual review.

**Approach:**
- After each run, scan modified files for:
  - Duplicate function/class definitions (same name appears twice)
  - Repeated code blocks (>5 identical consecutive lines)
  - Merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
  - Reverted imports (compare import block before/after)
- Report as `[DUP]` warnings in the run output
- Auto-fix obvious cases (exact duplicate block removal)

---

## F10 — Smart Batching

**Status:** `planned`

For bulk tasks like "add docstrings to all functions," group work intelligently
instead of launching N separate runs.

**Approach:**
- Detect batch-style prompts: "all files," "every function," "each route"
- Group targets by file (1 run per file, not 1 run per function)
- Estimate total cost before starting, warn if expensive
- Run file-groups sequentially (shared git state) or in parallel via worktrees

**Open questions:**
- Maximum batch size per run before quality degrades?
- How to handle partial batch failure (3/5 files done, 2 failed)?

---

## F11 — Delegation Chains

**Status:** `planned`

Define multi-step workflows where each step's output feeds the next. Roles:
planner, implementor, validator, reviewer.

**Approach:**
- Define chains as structured config (YAML or TOML):
  ```yaml
  chain: add-feature
  steps:
    - role: planner
      agent: code-architect
      turns: 5
      output: plan
    - role: implementor
      agent: default
      turns: 12
      input: plan
    - role: validator
      harness: codex  # can mix harnesses
      turns: 5
      task: "review the diff and run tests"
    - role: reviewer
      agent: code-reviewer
      turns: 3
  ```
- Each step gets the previous step's output as context
- Chain aborts if any step fails (with rollback per F8)
- Pre-built chains for common workflows: `steady`, `quick`, `fix`, `race`, `fortress`, `ironclad`

**Open questions:**
- YAML vs. TOML vs. just hardcoded chain templates?
- Should chains be project-specific (`.vibe/chains/`) or global?
- Can steps run on different harnesses within the same chain?

---

## F12 — Live Dashboard

**Status:** `planned`

Real-time visibility into active delegations, costs, and trends. Replace
after-the-fact `delegate-report` with a live view.

**Approach:**
- TUI option: terminal dashboard (e.g., using Python `rich` or `textual`)
  showing active runs, token burn, success streaks
- Web option: lightweight local server (Flask/FastAPI) serving a single-page
  dashboard
- Data source: tail `delegate-runs.jsonl` + poll active process status
- Key metrics: active runs, cost today, cost this week, failure rate trend,
  tokens saved vs. Claude-equivalent, per-project breakdown

**Open questions:**
- TUI vs. web vs. both?
- How to detect "active run" — PID file? Process name scan?

---

## F13 — Reject-and-Correct Loop

**Status:** `planned`

Instead of Claude fixing harness mistakes with its own (expensive) tokens, send
the work back to the harness with specific correction instructions. Claude's
role becomes reviewer only — it identifies what's wrong but never writes the fix.

**Current behavior (wasteful):**
```
Vibe produces code with broken import
  → Claude reviews diff, spots the bug
  → Claude edits the file itself (expensive tokens)
  → or Claude rewrites the entire prompt and re-runs from scratch (wasted run)
```

**Target behavior:**
```
Vibe produces code with broken import
  → Claude reviews diff, spots the bug
  → Claude sends correction prompt back to Vibe:
    "The import on line 3 is wrong. Change `from utils import foo`
     to `from app.utils import foo`. Do not touch anything else."
  → Vibe fixes it in 1-2 turns (cheap tokens)
  → Claude re-reviews the new diff
```

**Approach:**
- After diff review, Claude classifies the result:
  - `accept` — changes look good, done
  - `reject-correct` — specific fixable issues, send back with instructions
  - `reject-retry` — fundamentally wrong approach, full re-run with new prompt
  - `reject-abort` — unfixable by harness, escalate to user
- Correction prompt is minimal: just the error and the fix, not a full task
  re-statement. Keeps the harness's follow-up turn cheap.
- Max 2 correction rounds before falling back to `reject-retry` or `reject-abort`

**Harness support:**
| Harness | Follow-up support | Mechanism |
|---------|-------------------|-----------|
| Vibe | Yes | `--continue` flag resumes the session |
| Codex | TBD | Investigate continuation support |
| Aider | Yes | Multi-turn by default |
| OpenCode | TBD | Investigate |

**Key constraint:** Claude must NEVER fix code itself during a delegation flow.
Its only allowed actions are:
1. Review the diff
2. Write a correction prompt (text only)
3. Send the correction back to the harness
4. Accept or escalate to the user

This preserves the core economic model — all code generation happens on cheap
delegate tokens, Claude only spends tokens on review and prompt-writing.

**JSONL logging additions:**
- `correction_rounds`: number of reject-correct cycles (0 = accepted first try)
- `correction_prompts`: array of correction prompts sent (for learning loop F6)
- `final_disposition`: `accepted` | `corrected` | `retried` | `aborted`

**Depends on:** F1 (multi-harness, to know which harnesses support continuation).
Strongly complements F5 (failure memory) and F6 (learning loop) — correction
patterns become training signal for better initial prompts.

---

## F14 — Context Distillation

**Status:** `planned`

Auto-generate a compressed project brief — architecture, key files, conventions,
data structures — and inject it into every delegation prompt. Eliminates Claude
spending tokens re-discovering the same project structure on every task.

**Current behavior (repetitive):**
```
User: /vibe add a logout route

Claude reads app.py, models.py, routes/...
Claude writes prompt:
  "Stack: Python/Flask, SQLAlchemy, SQLite
   Key files: app.py (routes + fetch), models.py (Entry), ...
   TASK: add a logout route..."

User: /vibe add a search bar

Claude reads app.py, models.py, routes/... AGAIN
Claude writes prompt:
  "Stack: Python/Flask, SQLAlchemy, SQLite
   Key files: app.py (routes + fetch), models.py (Entry), ...
   TASK: add a search bar..."
```

Every delegation starts with Claude re-reading files to figure out the same
context it already figured out last time. That's wasted Claude tokens.

**Target behavior:**
```
First run (or after significant changes):
  → Claude generates .delegate/project-brief.md
  → Brief contains: stack, key files, data models, conventions, gotchas

Every subsequent delegation:
  → Claude reads the brief (~200-400 tokens) instead of the codebase
  → Injects it as the header of every prompt automatically
  → Only re-reads actual source files when the task requires it
```

**Brief structure:**
```markdown
# Project Brief — myapp
Stack: Python 3.11, Flask 3.x, SQLAlchemy 2.x, SQLite
Entry point: app.py
Routes: app.py (all routes inline)
Models: models.py (User, Entry, Tag)
Templates: templates/ (Jinja2)
Static: static/ (style.css, app.js)
DB schema: User(id, email, pw_hash), Entry(id, user_id, title, body, created)
Conventions: snake_case, no blueprints, imports at top of app.py
Gotchas: date fields are strings not datetime, id is int not UUID
```

**Approach:**
- Generate on first `/vibe` run in a project, or on explicit `/vibe-index`
- Store at `.delegate/project-brief.md` (in project, not home dir)
- Invalidate when key files change (hash check on entry point, models, config)
- Claude reads the brief instead of scanning the codebase for context
- Brief is injected as the first block of every harness prompt

**Open questions:**
- How deep to index? Just top-level structure, or also function signatures?
- Should the brief include example data shapes (API response payloads, DB rows)?
- Gitignore `.delegate/` or commit it for team sharing?

---

## F15 — Delegation Contracts (Pre/Post Conditions)

**Status:** `planned`

Define machine-verifiable conditions for each delegation. If pre-conditions
fail, don't launch. If post-conditions fail, auto-trigger reject-correct (F13).
Removes Claude from mechanical pass/fail decisions entirely.

**Example:**
```yaml
contract:
  pre:
    - "grep -q 'def fetch_data' app.py"
    - "python3 -m py_compile app.py"
  post:
    - "grep -q 'datetime.date' app.py"
    - "python3 -m py_compile app.py"
    - "python3 -m pytest tests/test_app.py -x -q"
  timeout: 30  # seconds for each check
```

**Approach:**
- Contracts can be defined three ways:
  - **Inline:** Claude generates them from the task description before delegating
  - **Per-project defaults:** `.delegate/contracts.yaml` with common checks
    (e.g., always run `pytest` post, always check syntax)
  - **Per-chain step:** embedded in delegation chain config (F11)
- Pre-condition failure → don't launch, report to user why
- Post-condition failure → auto reject-correct (F13) with the failing check's
  output as the correction context
- All post-conditions pass → auto accept, no Claude review needed

**Key insight:** this is what makes the system scalable. Right now Claude reviews
every diff — that's a bottleneck. With contracts, mechanical correctness is
verified automatically. Claude only reviews when contracts pass but the change
needs semantic judgment (architecture, naming, edge cases).

**Automation levels:**
| Level | Claude involvement | When to use |
|-------|-------------------|-------------|
| **Manual** | Claude reviews every diff | Current behavior, default |
| **Semi-auto** | Contracts check first, Claude reviews if pass | Most tasks |
| **Full-auto** | Contracts only, no Claude review | Routine/low-risk tasks |

**JSONL logging additions:**
- `contract_pre_pass`: bool
- `contract_post_pass`: bool
- `contract_checks`: array of {check, passed, output}
- `auto_accepted`: bool (true if accepted without Claude review)

**Depends on:** F13 (reject-correct) for the auto-correction loop.
Strongly complements F11 (chains) — each chain step gets its own contract.

---

## F16 — Delegation Replay

**Status:** `planned`

Record the full harness session — every tool call, file read, edit, and decision
— in a replayable format. When something goes wrong, step through exactly where
the harness went off track.

**Current visibility:**
```
  [read]  app.py
  [tool]  search_replace [OK] ...
  [vibe]  Done.
=== VIBE DONE (exit: 0) ===
```

You see *that* it read a file and *that* a replace succeeded, but not *what* it
read, *what* it replaced, or *why* it chose to. When it goes wrong, you're
guessing.

**Target visibility:**
```
$ delegate-replay ~/.local/share/delegate-sessions/2026-05-22T14:30:00Z.jsonl

Turn 1/8:
  [think] "I need to find the fetch_data function in app.py"
  [read]  app.py:40-80
          | def fetch_data():
          |     date_str = row['date']
          |     return {'date': date_str, 'id': row['id']}
  [think] "I need to convert date_str to datetime.date and id to str"

Turn 2/8:
  [edit]  app.py:42-43
          - date_str = row['date']
          - return {'date': date_str, 'id': row['id']}
          + date_obj = datetime.date.fromisoformat(row['date'])
          + return {'date': date_obj, 'id': str(row['id'])}
  [result] search_replace OK

Turn 3/8:
  [think] "I should verify the import exists"
  [read]  app.py:1-10        ← HERE: read imports but didn't add datetime
  ...
```

**Approach:**
- Capture the full JSON stream from `--output streaming` before the Python
  parser compresses it — write raw events to a session file
- Store at `~/.local/share/delegate-sessions/<timestamp>.jsonl`
- One file per run, linked to the run entry in `delegate-runs.jsonl` via
  a `session_file` field
- Replay tool: `delegate-replay <session-file>` renders a human-readable
  step-by-step with syntax-highlighted diffs
- Optional: `--turn N` to jump to a specific turn, `--errors` to show only
  turns with issues

**Use cases:**
- **Debugging failures:** see exactly which turn went wrong and why
- **Building failure memory (F5):** pinpoint the exact decision that caused
  the failure, not just "it failed"
- **Learning loop (F6):** compare harness reasoning with Claude's corrections
- **Harness comparison (F2):** replay two harnesses side-by-side on the same
  task to understand their different strategies
- **Prompt refinement:** see how the harness interpreted your prompt — was the
  task description ambiguous?

**Storage considerations:**
- Full sessions are larger than compressed summaries (~10-50KB per run vs.
  ~1KB for the JSONL log entry)
- Auto-prune sessions older than 30 days (configurable)
- Keep sessions for failed runs longer (90 days) since those are most valuable

**Depends on:** works standalone. Enhances F5, F6, F2.

---

## Implementation Priority

Suggested order based on dependencies and impact:

| Phase | Features | Rationale |
|-------|----------|-----------|
| **Phase 1** | F1 (multi-harness), F4 (Codex), F14 (context distillation) | Foundation — harness abstraction + stop re-reading the same project every time |
| **Phase 2** | F8 (rollback), F9 (duplicate detector), F13 (reject-correct), F16 (replay) | Safety net + cost discipline + debuggability before scaling up |
| **Phase 3** | F5 (failure memory), F6 (learning loop), F15 (contracts) | Self-improvement + automated acceptance |
| **Phase 4** | F2 (parallel), F3 (routing) | Requires multi-harness + enough run data |
| **Phase 5** | F7 (AST validation), F10 (batching) | Quality + efficiency refinements |
| **Phase 6** | F11 (chains), F12 (dashboard) | Workflow + observability |

---

## Open Design Decisions

### Who judges / who routes? (F2, F3)

The orchestrating LLM (Claude) is the leading candidate for both judging
parallel outputs and routing tasks to harnesses. Rationale:

- Already in the loop — no new infrastructure
- Diff review is cheap (~500-1500 tokens per diff, even 3x is manageable)
- Has full task context that a standalone judge would lack
- Routing table is small enough to fit in a prompt

Alternative: use automated heuristics (test pass, syntax, diff size) as a
first pass, escalate to LLM only for close calls. This hybrid approach would
minimize cost while preserving judgment quality.

### SKILL.md Step 6 rewrite (F13)

The current Step 6 says "If Vibe completed >=50% and crashed: finish the rest
manually rather than relaunching." F13 inverts this — Claude should never finish
manually. Instead: reject-correct back to the harness, or escalate to the user.
Step 6 will need a rewrite when F13 ships.

### Rollback mechanism (F8)

Git stash is too fragile. Leaning toward throwaway branch or worktree
isolation. Decision deferred until F1 reveals how different harnesses interact
with git state.

---

## Future: Session Isolation (Multi-Terminal Support)

**Status:** `planned` (not yet needed)

When multiple terminals run delegations against the same project simultaneously,
per-session state (plan.md, correction-prompt.txt, flag files) can conflict.

**Approach:** Each `delegate` invocation gets a `DELEGATE_SESSION_ID` (env var,
generated on first run in that terminal). Per-session state moves to
`.delegate/sessions/<id>/`:

```
.delegate/
  sessions/
    a1b2c3d4/          ← terminal 1
      plan.md
      correction-prompt.txt
      auto.flag / model.flag / mode.flag
    e5f6g7h8/          ← terminal 2
      ...
  runs.jsonl           ← shared (file-locked)
  knowledge.md         ← shared (read-only during runs)
  audit-findings.jsonl ← shared (file-locked)
  chains/              ← shared (read-only configs)
```

Shared read-only state stays at top level. Only mutable per-run state gets
session-scoped. Build this when multi-terminal usage becomes common.
