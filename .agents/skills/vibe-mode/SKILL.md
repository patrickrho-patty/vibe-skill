---
name: vibe-mode
description: Pick which delegation mode (chain) to use. Usage: $vibe-mode <mode>
---

# $vibe-mode

Set the active delegation chain for all subsequent `$vibe` or delegate tasks.

## Available modes

| Mode | Chain | What it does |
|------|-------|-------------|
| `simple` | (none) | Single delegation, no chain (default) |
| `implement` | implement.yaml | GLM plans → MiniMax implements → GLM validates |
| `bugfix` | bugfix.yaml | GLM investigates → MiniMax fixes → GLM validates |
| `multi-harness` | multi-harness-implement.yaml | MiniMax implements → GLM reviews |
| `cross-validate` | cross-validate.yaml | MiniMax and GLM both implement, pick the best |
| `defense` | defense-in-depth.yaml | GLM plans → MiniMax implements → GLM tests → MiniMax security reviews |

## Behavior

When the user says `$vibe-mode <mode>`:

1. If mode is `simple` or `clear`:
   - Run: `rm -f ~/.local/share/vibe-mode.flag`
   - Confirm: "Mode: simple (direct delegation, no chain)"

2. For any other mode, validate it exists in the table above, then:
   - Run: `echo <mode> > ~/.local/share/vibe-mode.flag`
   - Confirm: "Mode set to <mode>"

3. If no mode is provided, show current mode and list available modes.

## How it integrates

When `$vibe <task>` is invoked and `~/.local/share/vibe-mode.flag` exists,
use `delegate-chain` with the corresponding chain YAML instead of a single
`delegate` call. Pass the user's task as `DELEGATE_CHAIN_TASK`.
