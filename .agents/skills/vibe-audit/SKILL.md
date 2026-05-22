---
name: vibe-audit
description: "Show audit findings or trigger a scan. Usage: $vibe-audit [scan] [--model <model>]"
---

# $vibe-audit

`$vibe-audit scan` → `python3 .claude/vibe-skill/tools/delegate-audit scan .`
`$vibe-audit scan --model glm/glm-5.1` → use GLM instead of default MiniMax
`$vibe-audit` → `python3 .claude/vibe-skill/tools/delegate-audit list .`

If the user specifies `--model`, pass it through:
`python3 .claude/vibe-skill/tools/delegate-audit scan . --model <model>`

For each finding: fix it, dismiss it (`delegate-audit dismiss . <id>`), or skip.
