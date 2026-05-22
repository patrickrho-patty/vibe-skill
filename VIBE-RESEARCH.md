---
name: vibe-research
description: Show research findings or trigger a scan. Usage: /vibe-research [scan]
license: MIT
user-invocable: true
allowed-tools:
  - bash
---

# /vibe-research

If the user says `/vibe-research scan`:
```bash
python3 .claude/vibe-skill/tools/delegate-research scan .
```

If the user says `/vibe-research` (no args):
```bash
python3 .claude/vibe-skill/tools/delegate-research list .
```

After listing findings, for each finding the orchestrator should decide:
- **Apply**: implement the suggestion, then `python3 .claude/vibe-skill/tools/delegate-research apply . <id>`
- **Dismiss**: `python3 .claude/vibe-skill/tools/delegate-research dismiss . <id>`
- **Skip**: leave for later
