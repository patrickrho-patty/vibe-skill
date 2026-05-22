---
name: vibe-research-intake
description: "SOTA reviews open research findings and takes action on each. Usage: $vibe-research-intake"
---

# $vibe-research-intake

This is a SOTA-only command. You (the orchestrator) review each open research finding and take action.

## Step 1 — List pending findings

```bash
python3 .claude/vibe-skill/tools/delegate-research-intake pending
```

This shows both new open findings AND deferred findings that are due for review.

## Step 2 — For EACH finding, decide and act

Read the finding carefully. Then choose ONE action:

| Action | When to use |
|--------|-------------|
| `fix` | The research revealed a bug — fix it (delegate to cheap model if needed) |
| `refactor` | Code should be restructured to align with the research |
| `improve` | Implement the improvement the research suggests |
| `doc` | Write a doc or plan for a future improvement (not actionable now) |
| `ack` | Useful context, no code change needed — you learned something |
| `dismiss` | Not relevant, not accurate, already addressed, or low value |
| `defer` | Valid but not actionable NOW — revisit later (requires --review-by) |

**For fix/refactor/improve**: Actually do the work FIRST (delegate via `$vibe` chain), THEN graduate.
**For doc**: Write the doc or plan, THEN graduate.
**For ack/dismiss**: Graduate immediately with your reasoning.
**For defer**: Explain why it's not actionable now and when to revisit.

## Step 3 — Graduate each finding

After taking action, record what you did:

```bash
python3 .claude/vibe-skill/tools/delegate-research-intake graduate <id> \
  --action <fix|refactor|doc|improve|ack|dismiss|defer> \
  --detail "Describe exactly what you did or why you chose this action" \
  --comment "Any additional notes" \
  --model "gpt-5.5"
```

For defer, include --review-by:

```bash
python3 .claude/vibe-skill/tools/delegate-research-intake graduate <id> \
  --action defer \
  --detail "Valid hardening suggestion but not relevant to current R8 rescue path" \
  --review-by "2026-06-15" \
  --model "gpt-5.5"
```

The --review-by can be a date ("2026-06-15") or a condition ("after R8 ships", "next sprint").
Deferred findings automatically show up in `pending` when their review date arrives.

## Step 4 — Summary

After processing all findings:

```bash
python3 .claude/vibe-skill/tools/delegate-research-intake summary
```

To see all deferred findings (including not-yet-due):

```bash
python3 .claude/vibe-skill/tools/delegate-research-intake deferred
```

## Rules

- Process ALL pending findings in one session — do not leave any unreviewed
- Be honest — dismiss findings that are wrong, defer ones that aren't timely
- For `defer`: be specific about WHEN and WHY to revisit
- For `ack`: explain what you learned and why no action is needed
- For `dismiss`: explain why (helps the research agent improve)
- Always pass `--model` with your model name for audit trail
