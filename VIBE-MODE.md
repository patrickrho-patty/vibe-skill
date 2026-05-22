---
name: vibe-mode
description: Pick which delegation mode (chain) to use for all subsequent tasks. Usage: /vibe-mode <mode>
license: MIT
user-invocable: true
allowed-tools:
  - bash
---

# /vibe-mode

Set the active delegation chain for all subsequent `/vibe` or `/delegate` tasks.

## Behavior

When the user says `/vibe-mode <mode>`:

1. **Discover available modes** by listing chain files:
   ```bash
   ls .claude/vibe-skill/.delegate/chains/*.yaml 2>/dev/null | sed 's|.*/||;s|\.yaml$||'
   ```
   Each `.yaml` file in `.delegate/chains/` is a mode. The mode name is the
   filename without the extension (e.g., `implement.yaml` → mode `implement`,
   `multi-harness-implement.yaml` → mode `multi-harness-implement`).

2. If mode is `simple` or `clear`:
   - Run: `rm -f ~/.local/share/vibe-mode.flag`
   - Confirm: "Mode: simple (direct delegation, no chain)"

3. If mode matches a chain file:
   - Run: `echo <mode> > ~/.local/share/vibe-mode.flag`
   - To show what the chain does, read the `description:` line from the YAML:
     ```bash
     grep '^description:' .claude/vibe-skill/.delegate/chains/<mode>.yaml
     ```
   - Confirm: "Mode set to <mode> — <description>"

4. If mode does NOT match any chain file:
   - Print: "No mode called '<mode>'. Available modes:"
   - List all available modes (from step 1) plus `simple`
   - Do NOT set the flag

5. If no mode is provided, show current mode and list all available:
   - Current: `cat ~/.local/share/vibe-mode.flag 2>/dev/null || echo "simple"`
   - List all chain files as above

## How it integrates

When `/vibe <task>` is invoked and `~/.local/share/vibe-mode.flag` exists:

- Read the mode name from the flag file
- Look for `.claude/vibe-skill/.delegate/chains/<mode>.yaml`
- If found: run `delegate-chain` with that YAML, passing `DELEGATE_CHAIN_TASK`
- If not found (chain was deleted): warn and fall back to simple mode

When the flag is absent or set to `simple`, delegation works as before (single
call to `delegate`).

The mode persists across sessions until cleared with `/vibe-mode simple`.
