---
name: feedback-art-no-paid-api
description: User doesn't want to spend money on art generation — use ChatGPT subscription UI + Claude post-processing, not the paid OpenAI API
metadata:
  type: feedback
---

User (2026-10-14): "돈은 쓰고싶지 않음" — after learning the OpenAI image API is pay-as-you-go
(their API account had no credit; key was set as env OPENAI_API_KEY, old leaked key revoked).

**Why:** No spending on art generation.

**How to apply:** Default art-generation route is free: Claude writes job + `tools/artgen/prompt.sh`
output (prompt + reference images to attach) → user generates in ChatGPT UI and drops the file in
`tools/artgen/inbox/` → Claude runs `ingest.sh` (auto flat-bg removal), reviews, adopts, QA, ledger,
push. Don't run `artgen.sh` (paid API) unless the user explicitly asks again. Related:
[[project-artwork-thread]].
