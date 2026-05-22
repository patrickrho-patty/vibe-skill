---
name: vibe-scheduler
description: Manage the continuous background agents. Usage: /vibe-scheduler <start|stop|status>
license: MIT
user-invocable: true
allowed-tools:
  - bash
---

# /vibe-scheduler

| Command | Action |
|---------|--------|
| `/vibe-scheduler start` | `python3 .claude/vibe-skill/tools/delegate-scheduler start .` |
| `/vibe-scheduler stop` | `python3 .claude/vibe-skill/tools/delegate-scheduler stop .` |
| `/vibe-scheduler status` | `python3 .claude/vibe-skill/tools/delegate-scheduler status .` |
| `/vibe-scheduler config` | `python3 .claude/vibe-skill/tools/delegate-scheduler config .` |

The scheduler runs audit, research, and knowledge update agents on intervals
defined in `.delegate/scheduler.yaml`. Edit that file to change intervals or
disable jobs (set interval to 0).
