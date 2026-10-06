---
name: project-artwork-thread
description: "A dedicated ProjectD thread owns artwork — resource list, ordering (발주), applying art; ledger is docs/art/ART_RESOURCES.md"
metadata:
  node_type: memory
  type: project
  originSessionId: 734fa205-a0da-4b72-829b-6a591da0496f
  modified: 2026-10-06T09:49:48.663Z
---

User (2026-10-06) designated a ProjectD thread for **artwork only**: recording needed
resources, writing orders (발주서) for them, and applying delivered art into the game.

Ledger: `docs/art/ART_RESOURCES.md` (status ⬜필요/📝발주/📦입고/✅적용/➖보류, style guide,
order specs with IDs `ART-<CH|MO|BG|UI|FX><3-digit no>-<FULL|FACE|...>` using reserved
number bands per category (user wanted IDs distinguishable and scalable as roster grows;
monster roster is being expanded in the Work thread), apply log, open decisions). Layout: `resources/characters/<id>/`
(full.png = select screen, face_{neutral,happy,hurt,sad,angry}.png = combat bust cuts),
`resources/monsters/<id>/` same; `resources/_reference/` (.gdignore) = concept sheets, storage
only. Decided 2026-10-06: monsters are personified (musume); explosive main art = char004.

**Why:** User splits ProjectD work across threads by role (see also
[[project-thread-scope-pc-migration]] — that scope belongs to a different thread).

**How to apply:** In the artwork thread, keep the ledger as source of truth and update
statuses whenever art is ordered/delivered/applied. Claude can't generate images —
"발주" means writing the spec for the user to produce/commission.

**Art → Work handoff:** improvements Work should do because of applied art go into
`docs/feedback/INBOX.md` "남은 이슈" as `[미니 기획 ART-n]` entries (Work loop reads INBOX first
every iteration). ART-1 (2026-10-06): a=select-list overflow/overlap bug, b=combat face-cut
code path, c=monster art path tied to G-1 MonsterCatalog ids.
