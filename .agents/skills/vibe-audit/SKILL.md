---
name: vibe-audit
description: "Show audit findings or trigger a scan. Usage: $vibe-audit [scan]"
---

# $vibe-audit

`$vibe-audit scan` → `python3 .claude/vibe-skill/tools/delegate-audit scan .`
`$vibe-audit` → `python3 .claude/vibe-skill/tools/delegate-audit list .`

For each finding: fix it, dismiss it (`delegate-audit dismiss . <id>`), or skip.
