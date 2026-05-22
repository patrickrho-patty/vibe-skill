---
name: vibe-mode
description: Pick which delegation mode (chain) to use. Usage: $vibe-mode <mode>
---

# $vibe-mode

Set the active delegation chain for all subsequent `$vibe` or delegate tasks.

## Behavior

When the user says `$vibe-mode <mode>`:

1. **Discover available modes** by listing chain files:
   ```bash
   ls .claude/vibe-skill/.delegate/chains/*.yaml 2>/dev/null | sed 's|.*/||;s|\.yaml$||'
   ```
   Each `.yaml` file is a mode. The name is the filename without `.yaml`.

2. If mode is `simple` or `clear`:
   - Run: `rm -f ~/.local/share/vibe-mode.flag`
   - Confirm: "Mode: simple (direct delegation, no chain)"

3. If mode matches a chain file:
   - Run: `echo <mode> > ~/.local/share/vibe-mode.flag`
   - Read the description: `grep '^description:' .claude/vibe-skill/.delegate/chains/<mode>.yaml`
   - Confirm: "Mode set to <mode> — <description>"

4. If mode does NOT match any chain file:
   - Print: "No mode called '<mode>'. Available modes:"
   - List all available modes plus `simple`
   - Do NOT set the flag

5. If no mode is provided, show current mode and list all available.

## How it integrates

When `$vibe <task>` is invoked and `~/.local/share/vibe-mode.flag` exists,
use `delegate-chain` with the matching chain YAML. If the chain file was
deleted, warn and fall back to simple mode.
