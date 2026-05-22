---
name: vibe-reindex
description: Update the project knowledge base. Usage: /vibe-reindex
license: MIT
user-invocable: true
allowed-tools:
  - bash
---

# /vibe-reindex

Update the codebase knowledge base at `.delegate/knowledge.md`.

If `.delegate/knowledge.md` does not exist yet, run init (SOTA writes the initial version):
```bash
python3 .claude/vibe-skill/tools/delegate-knowledge init .
```

If it already exists, run update (cheap model rewrites based on current code):
```bash
python3 .claude/vibe-skill/tools/delegate-knowledge update .
```

Confirm with the knowledge.md contents after update.
