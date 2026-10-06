---
name: project-art-thread-handoff
description: "When ProjectD feature work finishes, send the newly required art resources to the \"ProjectD Art\" session (SendMessage) so it can record them in docs/art/ART_RESOURCES.md."
metadata:
  node_type: memory
  type: project
  originSessionId: 08652cec-13b7-48ef-866d-b76e8abb51e2
  modified: 2026-10-06T10:08:30.567Z
---

User rule (2026-10-06): once a ProjectD work item that adds/changes visuals is **completed**, hand the needed art resources to the separate **"ProjectD Art"** thread (session id `local_4eac1c1e-d961-42a2-b26b-5c6a6bee9363`, group ProjectD, cwd D:\Claude\ProjectD) via SendMessage / list_sessions so that thread records them. The Art thread owns `docs/art/ART_RESOURCES.md` and the `resources/` folder (characters/<id>/full.png + face_<expression>.png x5, monsters/<id>/..., backgrounds/); it uses ART-<CAT><3-digit>-<TYPE> IDs and wants monsters designed as personified (무스메).

(Art-thread side of this: [[project-artwork-thread]].)

**Why:** art is tracked in a dedicated thread (order -> received -> applied); the dev thread shouldn't edit those files itself, and headless iterations are told never to touch `resources/` or `docs/art/`.

**How to apply:** after a completed milestone (not each tiny commit), send one message with: what was added, the list of new art needs (id/name/family/tier/personality/colors), and the file path of the design source (INBOX.md section / DESIGN.md table). Pending handoffs as of 2026-10-06: [대형 기획 6] monster overhaul (4 families + family icons, 20 normal / 8 elite / 6 boss monsters, elite-room badge, boss crown overlay) — send when G-9 is done; F-2 new starting skills have no art needs. Don't send before completion (the design numbers are provisional until then).
