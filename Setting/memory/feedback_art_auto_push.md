---
name: feedback-art-auto-push
description: "In the artwork thread, commit+push finished art work to GitHub without asking; stage only art files"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 734fa205-a0da-4b72-829b-6a591da0496f
  modified: 2026-10-06T10:09:15.802Z
---

User (2026-10-06, artwork thread): "작업되는 것들은 알아서 깃허브에 올려줘" — push completed
art work (ledger updates, resource moves, art-application code) without asking first.

**Why:** User doesn't want to be asked each time; the art thread's output should land on
origin promptly.

**How to apply:** Follow CLAUDE.md push procedure (run `Setting/sync-to-repo.ps1` — needs
`powershell -ExecutionPolicy Bypass -File ...` on this PC — and include `Setting/`). Stage
**only art-thread files** (`docs/art/`, `resources/characters|monsters|backgrounds|_reference/`,
art-application code like `code/scenes/character_art.gd`); other threads (Work loop) often
have uncommitted changes in the tree — never sweep them into an art commit. Related:
[[project-artwork-thread]], [[feedback-push-after-each-iteration]].
