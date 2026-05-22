---
name: vibe-reindex
description: "Update the project knowledge base. Usage: $vibe-reindex [--model <model>]"
---

# $vibe-reindex

If `.delegate/knowledge.md` does not exist, run init (SOTA writes first version):
`python3 .claude/vibe-skill/tools/delegate-knowledge init .`

If it exists, run update:
`python3 .claude/vibe-skill/tools/delegate-knowledge update .`

If the user specifies `--model`, set the env var before running:
`DELEGATE_KNOWLEDGE_MODEL=<model> python3 .claude/vibe-skill/tools/delegate-knowledge update .`
