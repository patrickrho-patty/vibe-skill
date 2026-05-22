---
name: vibe-research
description: "Show research findings or trigger a scan. Usage: $vibe-research [scan] [--model <model>]"
---

# $vibe-research

`$vibe-research scan` → `python3 .claude/vibe-skill/tools/delegate-research scan .`
`$vibe-research scan --model minimax/MiniMax-M2.7` → use MiniMax instead of default GLM
`$vibe-research` → `python3 .claude/vibe-skill/tools/delegate-research list .`

If the user specifies `--model`, pass it through:
`python3 .claude/vibe-skill/tools/delegate-research scan . --model <model>`

For each finding: apply it, dismiss it (`delegate-research dismiss . <id>`), or skip.
