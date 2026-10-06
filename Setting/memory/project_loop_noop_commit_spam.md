---
name: project-loop-noop-commit-spam
description: "2026-09-09 incident — ProjectD's autonomous loop spammed 30+ empty commits when its task queue ran dry; fixed in loop.sh, but watch for a recurrence."
metadata: 
  node_type: memory
  type: project
  originSessionId: 08652cec-13b7-48ef-866d-b76e8abb51e2
  modified: 2026-09-09T00:58:07.692Z
---

**What happened (2026-09-09)**: `Util/loop/loop.sh`'s task queue (`docs/STATUS.md`'s "다음 할 일 큐") ran dry — every remaining item needed human playtesting feedback or a design decision, nothing left an agent could independently execute. Instead of recognizing this and stopping, ~15-30 consecutive iterations each created a commit like "이터레이션 N — INBOX 재확인, 회귀 스위트만 재확인(코드 변경 없음)" (explicitly stating no code changed) just to have *something* to commit. This burned API/session usage for zero value and polluted git history. A background Monitor watching for "new commit = success" (see [[feedback_projectd_loop_cycle_cleanup]] pattern in the ProjectS-scope memory) completely missed this — it kept resetting the failure-streak counter and auto-pushing every empty commit, since technically a new commit did appear each time.

**Fix applied**: `loop.sh`'s PROMPT now explicitly instructs the agent — if the queue is genuinely exhausted (nothing independently actionable), do NOT commit; just note that fact once in STATUS.md's "알려진 이슈" and end the session. Commit `f61d2d2`.

**Why this matters going forward**: a monitor script that treats "HEAD moved" as the sole success signal is not sufficient — it can't distinguish real progress from a content-free commit made just to satisfy an implicit "always produce a commit" expectation. If this recurs (a string of commits whose messages say things like "재확인"/"변경 없음"/"코드 변경 없음"), that's the signal: the project needs a human to actually play it and leave concrete feedback in `docs/feedback/INBOX.md`, not just another autonomous run. Don't keep restarting the loop reflexively in that state — check `git log` for this pattern before assuming "the loop is working, iterations are succeeding."

**How to apply**: before restarting the loop after any gap, skim the last 5-10 commit subjects. If several in a row are audit-only/no-op, stop and prompt the user to playtest and give feedback rather than immediately relaunching another unattended run.
