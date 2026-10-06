# 아트 리소스 관리 (ART_RESOURCES.md)

> 아트워크 전담 스레드가 관리하는 문서. **필요 리소스 목록 → 발주 → 입고 → 적용** 상태를
> 한곳에서 추적한다. 게임 설계 자체는 [DESIGN.md](../DESIGN.md)가 원천이며, 캐릭터/몬스터
> 목록이 바뀌면 이 문서도 함께 갱신한다.
> 최초 작성: 2026-10-06 / 갱신: 2026-10-06 (방향 결정 4건 반영, 발주서 작성, 분류별 ID 대역 체계 도입)

## 상태 표기

| 표기 | 의미 |
|---|---|
| ⬜ 필요 | 필요하다고 확인됐지만 아직 발주 안 함 |
| 📝 발주 | 발주서(아래 "발주 명세") 작성 완료, 제작 대기/진행 중 |
| 📦 입고 | 파일이 `resources/`에 들어왔지만 게임에 아직 안 붙임 |
| ✅ 적용 | 게임 코드/씬에 연결되어 화면에서 확인됨 |
| ➖ 보류 | 지금은 절차적(코드로 그린) 표현으로 충분 — 필요해지면 다시 검토 |

## 확정된 방향 (2026-10-06 사용자 결정)

1. **화면별 컷 분리** — 캐릭터 선택 화면은 **전신**(`full.png`), 전투 화면은 **상반신 표정 컷**
   (`face_<표정>.png`). 표정 5종(`neutral/happy/hurt/sad/angry`)을 캐릭터별로 추가 발주한다.
   몬스터도 전투 중 표정이 바뀌므로(`MonsterPortraitPlaceholder.set_expression()`) 같은 규칙을 적용한다.
2. **몬스터는 의인화(무스메) 디자인.**
3. **파일 정리 규칙** — 아래 "폴더 규칙" 참고. 기존 파일은 이 규칙대로 이동 완료.
4. **설정 시트(concept)는 보관용** — 게임에 쓰지 않는다. 폭발병 메인 원화는 `char004`(현 `characters/explosive/full.png`).

## 폴더 규칙

```
resources/
  characters/<캐릭터 id>/      ← 게임에서 쓰는 파일만
    full.png                    선택 화면 전신
    face_neutral.png            전투 화면 상반신 표정 5종
    face_happy.png
    face_hurt.png
    face_sad.png
    face_angry.png
  monsters/<몬스터 id>/         ← 캐릭터와 같은 구성 (full.png + face_*.png)
  backgrounds/<씬 이름>.png
  _reference/                   ← 보관용 설정 시트/대체안. `.gdignore`가 있어 Godot가 임포트하지 않음
    characters/<캐릭터 id>/sheet_*.png, alt_*.png
```

- 캐릭터 id는 `code/systems/character_profiles.gd`의 `id`를 그대로 쓴다.
- 몬스터는 코드에 id가 없어서 이 문서에서 정함: `slime` / `goblin` / `skeleton` / `orc` / `dark_knight`.
- 정리 시 이동 내역: `char001~004.png` → `characters/{novice,berserker,guardian,explosive}/full.png`,
  `concept.png` → `_reference/characters/berserker/sheet_poses.png`,
  `concept (5).png` → `_reference/characters/guardian/sheet_poses.png`,
  `concept (2)/(3)/(4).png` → `_reference/characters/explosive/sheet_expressions.png` / `sheet_poses.png` / `alt_full.png`.

## ID 체계 (분류 + 대역)

캐릭터·몬스터가 계속 늘어나도 ID만 보고 무엇인지 알 수 있게, **분류 코드 + 대상 번호 + 리소스 종류**로 나눈다.

```
ART-<분류><대상 번호 3자리>-<종류>
예) ART-CH005-FULL  = 캐릭터 005번(주술사) 전신
    ART-MO012-FACE  = 몬스터 012번 표정 세트
```

### 분류 코드와 번호 대역

| 분류 | 의미 | 대역 | 용도 |
|---|---|---|---|
| `CH` | 캐릭터 | 001~799 | 플레이어블 캐릭터 |
| | | 800~999 | NPC (상인, 이벤트 인물 등 — 예약) |
| `MO` | 몬스터 | 001~599 | 일반 몬스터 |
| | | 600~799 | 엘리트 몬스터 (예약) |
| | | 800~999 | 보스 몬스터 (예약) |
| `BG` | 배경 | 001~099 | 메인 화면/UI 씬 배경 (선택, 상점, 맵 등) |
| | | 100~999 | 던전 지역·전투 배경 |
| `UI` | UI 아이콘/프레임 | 001~999 | 스킬·업적·보상 아이콘 등 |
| `FX` | 이펙트 | 001~999 | 다이스/전투 연출 (예약) |

- 대상 번호는 **한 번 부여하면 바꾸거나 재사용하지 않는다**(캐릭터가 삭제돼도 번호는 비워둠).
- 새 대상은 해당 대역에서 비어 있는 다음 번호를 받는다. 대역이 부족해지면 4자리로 확장한다.
- 엘리트/보스 대역은 게임에 그런 구분이 생길 때 사용. 지금의 "강화 ○○"/마지막 방 "보스"는
  같은 몬스터의 수치 강화판이라 일반 대역 번호를 그대로 쓴다.

### 리소스 종류 코드

| 종류 | 의미 | 파일 |
|---|---|---|
| `FULL` | 전신 일러스트 1장 | `full.png` |
| `FACE` | 상반신 표정 세트 (5장 1세트) | `face_{neutral,happy,hurt,sad,angry}.png` |
| `BG` | 배경 1장 (BG 분류 전용) | `backgrounds/<이름>.png` |
| (추가 예정) | SD, 스킬 컷인 등 필요해지면 여기에 추가 | |

### 번호 배정표

| ID 번호 | 코드 id | 이름 |
|---|---|---|
| CH001 | `novice` | 견습 모험가 |
| CH002 | `berserker` | 광전사 |
| CH003 | `guardian` | 수호자 |
| CH004 | `explosive` | 폭발병 |
| CH005 | `shieldbearer` | 주술사 |
| CH006 | `enchantress` | 매혹사 |
| CH007 | `juggler` | 곡예사 |
| MO001 | `slime` | 슬라임 |
| MO002 | `goblin` | 고블린 |
| MO003 | `skeleton` | 해골 전사 |
| MO004 | `orc` | 오크 |
| MO005 | `dark_knight` | 다크 나이트 |

몬스터는 Work 스레드에서 종류를 늘리는 중(2026-10-06 요청) — 추가되면 MO006부터 이어서 배정한다.

---

## 1. 아트 스타일 기준 (입고된 원화 기준으로 정리)

입고된 전신 원화 4장에서 공통으로 보이는 특징을 이후 발주 기준으로 삼는다.

- **화풍**: 애니메이션풍 2D, 평면 셀 셰이딩, 외곽선과 면이 살짝 각진(픽셀아트 느낌의) 처리.
  은은한 그라데이션은 있지만 사실적 질감은 피함.
- **구도**: 전신, 배경 투명(PNG 알파), 캔버스 **1181×1332** (세로형).
- **공통 모티프**: 캐릭터마다 **자기 테마 색 주사위**를 손에 들거나 몸에 지님(빛나는 효과 포함 가능).
  → 다이스 빌딩 게임이라는 정체성을 캐릭터 단위에서 보여줌. 몬스터 포함 모든 신규 발주에 필수.
- **소품 톤**: 갈색 가죽 벨트/장갑, 금색 버클, 다이아몬드형 장식이 반복됨.
- **색**: 캐릭터 고유색(아래 표의 머리/의상 색)을 1차 색으로 하고 나머지는 갈색·크림 계열로 받침.

## 2. 필요 리소스 목록

### 2-1. 플레이어블 캐릭터 (7종) — 정의: `code/systems/character_profiles.gd`

참고 색은 현재 플레이스홀더의 `hair_color` / `dress_color` 값(Hex 변환).

| id | 이름 | 참고 색 (머리 / 의상) | 전신 `full.png` | 표정 5종 `face_*.png` |
|---|---|---|---|---|
| `novice` | 견습 모험가 | `#C79EDB` / `#EB8CA8` | ✅ 적용 | 📝 ART-CH001-FACE |
| `berserker` | 광전사 | `#D94033` / `#591A1A` | ✅ 적용 | 📝 ART-CH002-FACE |
| `guardian` | 수호자 | `#668CD9` / `#40668C` | ✅ 적용 | 📝 ART-CH003-FACE |
| `explosive` | 폭발병 | `#F28C26` / `#802E0D` | ✅ 적용 | 📝 ART-CH004-FACE |
| `shieldbearer` | 주술사 | `#1F1429` / `#2E0A1A` | 📝 ART-CH005-FULL | 📝 ART-CH005-FACE (ART-CH005-FULL 입고 후) |
| `enchantress` | 매혹사 | `#BF2673` / `#8C0D40` | 📝 ART-CH006-FULL | 📝 ART-CH006-FACE (ART-CH006-FULL 입고 후) |
| `juggler` | 곡예사 | `#F2D940` / `#8026BF` | 📝 ART-CH007-FULL | 📝 ART-CH007-FACE (ART-CH007-FULL 입고 후) |

### 2-2. 몬스터 (의인화) — 정의: `code/scenes/combat_test.gd` `MONSTER_PROFILES`

현재 5종(MO001~005). Work 스레드에서 몬스터 종류를 늘리는 중이라, 추가되면 MO006부터 배정해 이 표에 행을 추가한다.

| id | 이름 | 성격 / 기믹 | 참고 색 | 전신 `full.png` | 표정 5종 `face_*.png` |
|---|---|---|---|---|---|
| `slime` | 슬라임 | 무기력하고 단순함 / 없음 | `#59D966` | 📝 ART-MO001-FULL | 📝 ART-MO001-FACE |
| `goblin` | 고블린 | 성급하고 화를 잘 냄 / 분노 스택 | `#BF8C40` | 📝 ART-MO002-FULL | 📝 ART-MO002-FACE |
| `skeleton` | 해골 전사 | 감정 없는 병사 / 고정값 | `#D9D9CC` | 📝 ART-MO003-FULL | 📝 ART-MO003-FACE |
| `orc` | 오크 | 저돌적, 전부 아니면 전무 / 극단 | `#4D8C4D` | 📝 ART-MO004-FULL | 📝 ART-MO004-FACE |
| `dark_knight` | 다크 나이트 | 차갑고 노련한 기사 / 철벽 방어 | `#8C40BF` | 📝 ART-MO005-FULL | 📝 ART-MO005-FACE |

- 몬스터 전신은 지금 화면에 쓰이는 곳이 없지만(전투는 표정 컷 사용), 표정 컷을 그릴 기준 디자인이자
  추후 도감/보스 연출용으로 먼저 발주한다.
- "강화 ○○"(6번째 방 이후 재사용)과 마지막 방 "보스"는 같은 몬스터의 수치 강화판이라 별도
  일러스트 없이 색조/크기/오라 효과로 구분한다(➖ 보류).

### 2-3. 배경 (씬별) — `resources/backgrounds/`

| 씬 | 파일 | 상태 |
|---|---|---|
| 전투 | `code/scenes/combat_test.tscn` | ⬜ 필요 |
| 캐릭터 선택 | `code/scenes/character_select.tscn` | ⬜ 필요 (우선순위 낮음) |
| 던전 맵 | `code/scenes/dungeon_map.tscn` | ⬜ 필요 (우선순위 낮음) |
| 상점 | `code/scenes/shop.tscn` | ⬜ 필요 (우선순위 낮음) |
| 특수 이벤트 / 스토리 이벤트 | `event.tscn` / `story_event.tscn` | ⬜ 필요 (우선순위 낮음) |

### 2-4. UI 아이콘 / 다이스 — 현재 전부 절차적으로 그림

| 항목 | 현재 구현 | 상태 |
|---|---|---|
| 스킬 아이콘 | `code/scenes/skill_icon.gd` | ➖ 보류 |
| 업적 아이콘 | `code/scenes/achievement_icon.gd` | ➖ 보류 |
| 보상 아이콘 | `code/scenes/reward_icon.gd` | ➖ 보류 |
| 잠금 아이콘 | `code/scenes/lock_icon.gd` | ➖ 보류 |
| 다이스 결과 칩 / 이벤트 다이스 | `face_chip_style.gd`, `shape_die_chip.gd`, `event_die_visual.gd` | ➖ 보류 |
| 3D 굴림 다이스 + 재질 | `code/dice/`, `resources/materials/*.tres` | ➖ 보류 |

캐릭터 원화가 들어간 뒤 아이콘만 화풍이 동떨어져 보이면 그때 발주를 검토한다.

---

## 3. 발주 명세 (발주서)

### 공통 규격

**전신 (`full.png`)**
- 1181×1332 PNG, 배경 투명. 1장 "아트 스타일 기준" 준수(입고된 `characters/*/full.png`와 같은 톤).
- 테마 색 주사위를 반드시 포함.

**상반신 표정 컷 (`face_*.png`, 표정 5종 1세트)**
- 768×768 PNG, 배경 투명. 머리 위 여백 약 10%, 가슴 아래에서 자름.
- **5장 모두 캔버스 안 머리·몸 위치를 동일하게 고정**한다(표정과 손 정도만 바뀜) — 전투 중
  표정을 바꿔 끼울 때 그림이 튀지 않게 하기 위함.
- 시선 방향: **플레이어 캐릭터는 화면 오른쪽**(왼쪽에 서서 몬스터를 봄), **몬스터는 화면 왼쪽**을 본다.
- 의상/소품은 해당 캐릭터의 `full.png`와 일치시킨다.
- 표정별로 게임에서 쓰이는 상황:

| 파일 | 표정 | 게임 상황 (`combat_test.gd`) |
|---|---|---|
| `face_neutral.png` | 평상시 | 대기, 피해 0으로 막았을 때 |
| `face_happy.png` | 웃음/득의양양 | 내 공격이 들어감, 전투 승리 |
| `face_hurt.png` | 찡그림/아픔 | 피해를 받음 |
| `face_sad.png` | 슬픔/풀죽음 | 전투 패배 |
| `face_angry.png` | 분노/억울 | 전투 패배(분노 버전), 포기 |

### 발주서 템플릿 (새 발주용)

```
[발주 ID] ART-<분류><번호>-<종류> (위 "ID 체계" 참고)
대상: (캐릭터/몬스터/배경 이름, id)
용도: (어느 화면 어디에 쓰이는지)
규격 / 파일명: (공통 규격 참조 + 저장 경로)
컨셉: (성격/기믹을 외형으로 어떻게 보여줄지)
색: (주색 Hex)
필수 소품: 테마 색 주사위 + (고유 소품)
참고 이미지: (기존 원화/시트 경로)
```

### 3-1. 캐릭터 전신 (신규 3종)

**[ART-CH005-FULL] 주술사 (`shieldbearer`) 전신**
- 용도: 캐릭터 선택 화면 / 저장: `resources/characters/shieldbearer/full.png`
- 컨셉: 음침하고 말이 없는 주술사. 방어 다이스가 최댓값을 보일 때마다 저주 술식이 쌓이고,
  3번 쌓이면 방어가 1D20으로 터진다 → 몸 주위에 술식 문양(원형 마법진 조각) 3개가 떠 있는 구도.
- 외형: 거의 검정에 가까운 보랏빛 흑발(눈을 살짝 가리는 앞머리), 검붉은 와인색 후드 로브,
  저주 부적·붕대 감은 손, 낮은 시선과 무표정.
- 색: 머리 `#1F1429` / 의상 `#2E0A1A`, 포인트 색으로 독한 보라 빛(술식).
- 필수 소품: 보랏빛 연기를 내는 **저주 문양이 새겨진 주사위**(손바닥 위에 띄움).
- 참고: `resources/characters/guardian/full.png`(같은 방어형 캐릭터, 대비되게 어둡고 가볍게).

**[ART-CH006-FULL] 매혹사 (`enchantress`) 전신**
- 용도: 캐릭터 선택 화면 / 저장: `resources/characters/enchantress/full.png`
- 컨셉: 섹시하고 도발적인 매혹사. 매 턴 가장 낮게 나온 주사위 하나를 홀려서 최댓값으로 뒤집는다
  → 손끝에서 나온 분홍 마력 실이 주사위를 감아 1이 6으로 바뀌는 순간을 표현.
- 외형: 마젠타 롱헤어, 진홍색 드레스(트임 있는 이브닝 드레스풍), 하트·입술 모티프 장신구,
  한쪽 눈 윙크나 입꼬리만 올린 여유로운 미소.
- 색: 머리 `#BF2673` / 의상 `#8C0D40`, 포인트 핑크 빛.
- 필수 소품: 분홍 빛에 감긴 **주사위**(1면에서 6면으로 넘어가는 중).
- 참고: `resources/characters/novice/full.png`의 소품 톤.

**[ART-CH007-FULL] 곡예사 (`juggler`) 전신**
- 용도: 캐릭터 선택 화면 / 저장: `resources/characters/juggler/full.png`
- 컨셉: 알록달록한 서커스 곡예사. 런 시작 시 공격 주사위와 방어 주사위를 하나씩 맞바꾼다
  → **빨간 주사위(공격)와 파란 주사위(방어)를 공중에서 교차 저글링**하는 포즈.
- 외형: 노란 머리(양갈래나 높은 포니테일), 보라색 곡예사 의상에 다이아몬드(할리퀸) 패턴,
  방울 달린 모자나 리본, 한 발로 균형을 잡는 경쾌한 자세.
- 색: 머리 `#F2D940` / 의상 `#8026BF`, 패턴에 빨강·파랑·초록 섞음.
- 필수 소품: 공중에 떠 있는 **주사위 여러 개**(빨강/파랑 각 1개 이상).

### 3-2. 캐릭터 표정 세트 (7종 × 5장)

공통 규격의 "상반신 표정 컷"을 따른다. 저장: `resources/characters/<id>/face_{neutral,happy,hurt,sad,angry}.png`

| 발주 ID | 대상 | 참고 이미지 | 성격 반영 포인트 |
|---|---|---|---|
| ART-CH001-FACE | 견습 모험가 `novice` | `characters/novice/full.png` | 밝고 순한 신참. happy는 해맑게, angry는 볼 부풀린 억울함 |
| ART-CH002-FACE | 광전사 `berserker` | `characters/berserker/full.png`, `_reference/characters/berserker/sheet_poses.png`(하단 얼굴 컷 참고) | 늘 이빨 드러낸 웃음. hurt도 웃음기 섞인 찡그림, angry는 포효 |
| ART-CH003-FACE | 수호자 `guardian` | `characters/guardian/full.png`, `_reference/characters/guardian/sheet_poses.png`(표정 모음 참고) | 침착·절제. 표정 폭이 작고 hurt는 이 악문 정도 |
| ART-CH004-FACE | 폭발병 `explosive` | `characters/explosive/full.png`, `_reference/characters/explosive/sheet_expressions.png`(화풍 참고) | 장난스럽고 시끄러움. 송곳니, 별 눈. 기존 표정 시트는 구성이 달라 **5종을 새로 맞춰** 그림 |
| ART-CH005-FACE | 주술사 `shieldbearer` | ART-CH005-FULL 결과물 | 과묵. 표정 변화는 눈빛·입꼬리 위주, happy는 섬뜩한 미소 |
| ART-CH006-FACE | 매혹사 `enchantress` | ART-CH006-FULL 결과물 | 여유·도발. hurt조차 우아하게, angry는 차갑게 노려봄 |
| ART-CH007-FACE | 곡예사 `juggler` | ART-CH007-FULL 결과물 | 과장된 광대 리액션. 표정 폭 가장 크게 |

### 3-3. 몬스터 전신 (의인화 5종)

공통: 1181×1332 PNG 배경 투명, 저장 `resources/monsters/<id>/full.png`. 원형 몬스터의 특징(색·
신체 부위·무기)을 한눈에 알아볼 수 있게 남기고, 플레이어 캐릭터들과 같은 화풍의 여캐로 의인화.
기믹을 주사위 소품으로 보여준다.

**[ART-MO001-FULL] 슬라임 (`slime`)** — 반투명 녹색 젤리 몸(머리카락·옷 끝이 흘러내림), 졸린 눈, 축 처진 자세.
몸 안에 **삼켜진 주사위**가 비쳐 보임. 색 `#59D966`. 가장 약한 첫 몬스터라 귀엽고 만만한 인상.

**[ART-MO002-FULL] 고블린 (`goblin`)** — 작은 키, 뾰족 귀, 황갈색 피부·누더기 가죽옷, 날 선 송곳니, 이 갈며 화난 얼굴,
투박한 단검. 분노 스택 표현으로 **최댓값이 빨갛게 달아오른 주사위**와 머리 위 분노 마크. 색 `#BF8C40`.

**[ART-MO003-FULL] 해골 전사 (`skeleton`)** — 창백한 피부, 갈비뼈·두개골 모양 뼈 갑옷, 녹슨 장검과 둥근 방패,
차렷 자세의 무표정한 병사. 고정값 표현으로 **모든 면에 같은 눈만 새겨진 주사위**. 색 `#D9D9CC`.

**[ART-MO004-FULL] 오크 (`orc`)** — 녹색 피부, 아래 엄니, 근육질 장신, 거대한 가시 몽둥이, 저돌적인 돌진 자세.
극단 표현으로 **1면과 6면만 있는 흑백 반반 주사위**. 색 `#4D8C4D`.

**[ART-MO005-FULL] 다크 나이트 (`dark_knight`)** — 보랏빛 흑색 판금 갑옷, 투구는 옆구리에 끼고 차가운 눈빛,
대형 카이트 실드. 철벽 방어 표현으로 **방패 문장에 박힌 주사위**(수호자 방패와 대칭되는 어두운 버전).
색 `#8C40BF`. 5종 중 가장 강한 인상(보스로도 자주 등장).

### 3-4. 몬스터 표정 세트 (5종 × 5장)

공통 규격의 "상반신 표정 컷"(시선은 화면 왼쪽). 저장: `resources/monsters/<id>/face_{neutral,happy,hurt,sad,angry}.png`.
각 몬스터 전신(ART-MO001~005-FULL) 입고 후 진행.

| 발주 ID | 대상 | 성격 반영 포인트 |
|---|---|---|
| ART-MO001-FACE | 슬라임 | 표정이 흐물흐물, hurt는 몸이 찌그러짐 |
| ART-MO002-FACE | 고블린 | 기본이 화난 얼굴, angry는 폭발 직전 |
| ART-MO003-FACE | 해골 전사 | 거의 무표정 — 눈빛·입 모양만 미세하게 |
| ART-MO004-FACE | 오크 | 크게 웃거나 크게 화냄, 중간이 없음 |
| ART-MO005-FACE | 다크 나이트 | 냉정, happy도 비웃음 정도 |

### 발주 이력

| 발주 ID | 대상 | 발주일 | 상태 | 입고 파일 |
|---|---|---|---|---|
| ART-CH001~004-FULL | 견습 모험가 / 광전사 / 수호자 / 폭발병 전신 + 설정 시트 (발주 전 사전 입고) | — | ✅ 적용 | `characters/{novice,berserker,guardian,explosive}/full.png`, `_reference/` |
| ART-CH005~007-FULL | 주술사 / 매혹사 / 곡예사 전신 | 2026-10-06 | 📝 발주 | |
| ART-CH001~004-FACE | 기존 4종 표정 세트 | 2026-10-06 | 📝 발주 | |
| ART-CH005~007-FACE | 신규 3종 표정 세트 | 2026-10-06 | 📝 발주 (전신 입고 후 착수) | |
| ART-MO001~005-FULL | 몬스터 5종 전신 (의인화) | 2026-10-06 | 📝 발주 | |
| ART-MO001~005-FACE | 몬스터 5종 표정 세트 | 2026-10-06 | 📝 발주 (전신 입고 후 착수) | |

---

## 4. 적용 계획 / 기록

### 적용 지점

| 리소스 | 코드 위치 | 현재 |
|---|---|---|
| 캐릭터 `full.png` | `character_select.gd` (카드 목록 + 상세 패널) | `CharacterPortraitPlaceholder` (도형 + 색) |
| 캐릭터 `face_*.png` | `combat_test.gd` `$PlayerPortrait` (`set_expression()` 호출 지점 그대로 사용) | `CharacterPortraitPlaceholder` |
| 몬스터 `face_*.png` | `combat_test.gd` `$MonsterPortrait` | `MonsterPortraitPlaceholder` |

### 적용 방식

- 경로는 폴더 규칙으로 자동 결정(`res://resources/characters/<id>/full.png`, `.../face_<expr>.png`)하고,
  **파일이 있으면 원화를, 없으면 기존 플레이스홀더를** 그린다 → 일부만 입고된 상태에서도 화면이 깨지지 않음.
- 전투 화면은 표정 컷 5장 중 하나라도 없으면 그 캐릭터는 플레이스홀더 유지(표정 일부만 원화로 섞이지 않게).
- 원화는 고해상도라 카드/전투 화면 크기에 맞게 축소 표시(Godot 임포트 설정에서 밉맵/필터 확인).
- 적용 후 `scripts/qa_shot.sh character_select` / `combat_test`로 스크린샷 확인.

### 적용 기록

| 날짜 | 리소스 | 적용 위치 | 확인 스크린샷 |
|---|---|---|---|
| 2026-10-06 | ART-CH001~004-FULL (견습 모험가/광전사/수호자/폭발병 전신) | 캐릭터 선택 화면 — 목록 카드 썸네일(상반신 크롭) + 상세 패널 전신. 원화 없는 캐릭터는 플레이스홀더 유지 (`code/scenes/character_art.gd`) | `qa_out/art_character_select.png`, `qa_out/art_character_select_juggler.png` |

---

## 5. 결정 필요 (사용자 확인 대기)

- (현재 없음 — 2026-10-06 4건 모두 결정, 상단 "확정된 방향" 참고)
