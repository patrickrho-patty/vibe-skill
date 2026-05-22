---
name: vibe-model-pick
description: "Override the delegate model for all subsequent delegations. Usage: $vibe-model-pick <alias>"
---

# $vibe-model-pick

Extract the alias from the user's arguments, then run:
`mkdir -p .delegate && echo <alias> > .delegate/model.flag`

Confirm: "Model override set to <alias> — all delegate runs will use this model until $vibe-model-clear."

If no alias provided, list available models with `pi --list-models` and ask the user to pick one.
