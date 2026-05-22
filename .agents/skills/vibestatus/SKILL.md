---
name: vibestatus
description: Show auto-delegate mode status (ON/OFF) and active model override.
---

# $vibestatus

Run both checks and print two lines:

```
Auto-vibe: ON | OFF
Model: <alias>  (override)  OR  Model: <config default>
```

- Auto-vibe: `test -f .delegate/auto.flag && echo ON || echo OFF`
- Model override: `cat .delegate/model.flag 2>/dev/null || echo "(config default)"`
