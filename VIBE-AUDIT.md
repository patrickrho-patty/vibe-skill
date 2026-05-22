---
name: vibe-audit
description: Show audit findings or trigger a scan. Usage: /vibe-audit [scan]
license: MIT
user-invocable: true
allowed-tools:
  - bash
---

# /vibe-audit

If the user says `/vibe-audit scan`:
```bash
python3 .claude/vibe-skill/tools/delegate-audit scan .
```

If the user says `/vibe-audit` (no args):
```bash
python3 .claude/vibe-skill/tools/delegate-audit list .
```

After listing findings, for each finding the orchestrator should decide:
- **Fix**: delegate the fix, then `python3 .claude/vibe-skill/tools/delegate-audit resolve . <id>`
- **Dismiss**: `python3 .claude/vibe-skill/tools/delegate-audit dismiss . <id>`
- **Skip**: leave for later
