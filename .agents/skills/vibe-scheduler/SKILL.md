---
name: vibe-scheduler
description: "Manage continuous background agents. Usage: $vibe-scheduler <start|stop|status|run|ps|kill-all>"
---

# $vibe-scheduler

`$vibe-scheduler start` → `python3 .claude/vibe-skill/tools/delegate-scheduler start`
`$vibe-scheduler start --only audit,research` → selective daemon (only those jobs)
`$vibe-scheduler stop` → `python3 .claude/vibe-skill/tools/delegate-scheduler stop`
`$vibe-scheduler status` → `python3 .claude/vibe-skill/tools/delegate-scheduler status`
`$vibe-scheduler config` → `python3 .claude/vibe-skill/tools/delegate-scheduler config`
`$vibe-scheduler run audit` → `python3 .claude/vibe-skill/tools/delegate-scheduler run audit`
`$vibe-scheduler run research` → `python3 .claude/vibe-skill/tools/delegate-scheduler run research`
`$vibe-scheduler run audit research` → run multiple jobs one-shot
`$vibe-scheduler ps` → `python3 .claude/vibe-skill/tools/delegate-scheduler ps`
`$vibe-scheduler kill-all` → `python3 .claude/vibe-skill/tools/delegate-scheduler kill-all`

Jobs run immediately on start (no waiting for the first interval). Edit `.delegate/scheduler.yaml` to change intervals or disable jobs.
