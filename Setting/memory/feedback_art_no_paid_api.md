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

**Preferred (least user effort, 2026-10-14):** Claude drives the user's ChatGPT via Claude in Chrome
in the ChatGPT thread **"Project D - Claude"** (already briefed: Claude writes requests, GPT draws,
7 existing characters attached as style refs). Ask the user once per batch before sending prompts
and saving images. Save generated image via page JS (fetch blob → <a download>) to ~/Downloads, then
mv into tools/artgen/inbox/ and run ingest.sh. Find the composer with `find` ("하단 메인 입력창") —
coordinate clicks miss when the window resizes; another contenteditable holds a user draft
("[최우선 지시 — 기존 캐릭터 화풍 고정]…") — never touch it. GPT often fakes transparency with a
checkerboard; postprocess removes it. User wants re-requests when style/anatomy/dice are off.

**Learned 2026-10-15:** "Project D - Claude" once failed to load ("이 ChatGPT 대화를 불러올 수
없습니다") — cause was the usage limit, see below. I made a new chat as a workaround and the user objected:
**NEVER create a new ChatGPT thread — ALL art work happens in "Project D - Claude"** (deleted the stray one,
kept its image). If that thread won't load, check usage / ask the user. Send key Return only after
attachments finish uploading (else nothing sends; click the send button). UI kit tricks that worked:
draw state sheets (5 button states in one image) then `tools/artgen/sheet_split.gd`; mono icons are
cleanest as BLACK silhouettes on WHITE then inverted to white+alpha (white-on-transparent came out noisy).

**Usage check (user asked to do this often, 2026-10-15):** ChatGPT shows "사용량 N% 남음 / 5시간 / HH:MM에 초기화"
at the bottom-left of the sidebar. Read it (JS: find leaf text matching /사용량/ in nav/aside, print its block)
**before each generation batch and whenever generation stalls or a chat fails to load** — when it's low
(<~10%), stop and tell the user the reset time instead of retrying. Never click "크레딧 추가"/"업그레이드".
Stalls + "대화를 불러올 수 없습니다" on 2026-10-15 were caused by the limit (3% left), not thread size.
