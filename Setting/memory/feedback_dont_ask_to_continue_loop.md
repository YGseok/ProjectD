---
name: feedback-dont-ask-to-continue-loop
description: "When running ProjectD loop iterations back-to-back at the user's request, don't ask \"continue?\" after each one — keep going until told to stop."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 08652cec-13b7-48ef-866d-b76e8abb51e2
  modified: 2026-09-09T09:46:31.286Z
---

When the user has asked to run loop iterations continuously (e.g. "이터레이션 계속 돌려줘" or "멈추고 싶으면 말할게" / any phrasing establishing "keep going is the default, I'll interrupt if I want to stop"), do not end each iteration's report with a question like "계속 진행할까요?" — just report the result and immediately kick off the next iteration. Only pause and ask when something actually needs the user's judgment: an error, a repeated no-op streak, an ambiguous design fork, or the user explicitly saying to stop.

**Why**: caught in the act on 2026-09-09 — the user had explicitly set "continue by default, I'll say when to stop," and the very next turn still ended with an unnecessary "계속 진행할까요?" The cause was a default habit (treating task completion as a natural checkpoint to invite redirection) overriding an explicit standing instruction. This wastes a round-trip and contradicts what was just agreed.

**How to apply**: in an established "just keep running iterations" mode, end each report with a plain statement of what's happening next ("iter_N 시작했습니다"), not a question. Save the check-ins for genuine decision points.
