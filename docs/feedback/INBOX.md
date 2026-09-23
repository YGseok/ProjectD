# INBOX.md — 사용자 피드백 / 최우선 지시

이 파일은 사용자(설계자)가 AI에게 남기는 지시와 피드백을 담는다.
**매 이터레이션 시작 시 가장 먼저 읽고, 다른 무엇보다 최우선으로 반영한다.**

## 사용 규칙

- 새 지시는 "남은 이슈 (미처리)" 섹션 맨 위(가장 최근이 위)에 날짜와 함께 추가한다.
- AI가 항목을 반영했으면 지우지 말고 `[처리됨 - YYYY-MM-DD]` 를 앞에 붙여 표시하고,
  **반드시 실제로 해당 섹션("처리됨" 또는 "부분 처리됨")까지 옮긴다** — 태그만 붙이고
  "남은 이슈" 섹션에 그대로 두지 말 것. (히스토리를 남겨야 나중에 "이 결정이 왜
  이렇게 됐는지" 추적 가능. 2026-09-09에 태그만 붙고 이동을 안 해서 몇 개가 계속
  "남은 이슈"에 남아있던 사고가 있었음 — 반복하지 말 것.)
- 처리 못 하거나 애매한 항목은 `docs/STATUS.md`의 "알려진 이슈 / 막힌 것"에 사유를 남기고,
  이 파일의 항목 앞에 `[보류 - 사유]`를 붙인다.
- 세 섹션 안에서는 각각 날짜 최신순(위쪽이 최근)으로 정렬한다.
- **"처리됨" 섹션이 12개를 넘으면**, 가장 오래된 항목들을(12개가 될 때까지) 잘라서
  `docs/INBOX_ARCHIVE.md` 맨 위에 옮겨 적어라(파일 없으면 새로 만들 것). 내용을
  요약하거나 버리지 말고 그대로 옮기기만 한다 — 이 파일은 매 이터레이션 통째로 읽는
  파일이라 계속 누적되면 읽기 비용이 무한정 커진다(STATUS.md가 2026-09-07에 275KB까지
  불어나 docs/STATUS_ARCHIVE.md로 정리한 것과 같은 이유). "부분 처리됨"은 여전히
  진행 중인 항목으로 취급해 archive하지 않는다.

---

## 남은 이슈 (미처리)

(플레이해보고 느낀 점을 이 섹션에 자유롭게 적어주세요.)

## 부분 처리됨

- [부분 처리됨 - 2026-09-24] 2026-09-24 방패병이 수호자랑 겹치는데 빼고, 3개의
  캐릭터 아이디어를 더 내줄래? 이어서 스킬 작업까지 이터레이션으로 해주고,
  외형 프롬프트를 추가해줘. 컨셉이랑 어울리면 좋겠는데, 추가하면 좋겠는
  캐릭터는 음침 거유 캐릭터랑, 섹시하고 도발적인 캐릭터, 나머지 하나는
  적당히 비어있는 포지션에 재미요소 맞춰서 해봐.

  → **A(방패병 리스킨)/B(매혹사)/C(곡예사) 완료(2026-09-24 (140)/(141)/(142)),
  D는 1~4번 완료(2026-09-24 (143)/(144)/(145)), 5~7번 남음.**
  D-4(이번 이터레이션, (145)): `skill_pool.gd`의 `UNIQUE_SKILLS`에 매혹사
  "매혹 심화"(`charm_amplify`)/곡예사 "곡예 앙코르"(`juggle_encore`)를,
  `UPGRADE_SKILLS`에 각각의 "+" 강화판을 INBOX.md 원문 예시 그대로 추가했다
  (사람 결정 대기 없이 진행). 매혹 심화: `dice_bag.gd`의
  `apply_charm_flip(values)`에 `count: int = 1` 매개변수를 추가(기존 호출부
  호환 유지) — charm_flip이 매 턴 뒤집는 다이스 개수를 1개(기본)→2개(매혹
  심화)→3개(매혹 심화+)로 늘린다. 곡예 앙코르: `run_state.gd`의
  `advance_round()`(라운드 전환 시점)에 `skill_flags.has("juggle_encore")`
  조건으로 `DiceBag.swap_random_dice()`를 한 번 더 호출(런 시작 1회뿐이던
  juggle_swap을 라운드가 바뀔 때마다 재발동) — "+"는 같은 전환에서 2회
  호출. 둘 다 새 메커니즘 없이 기존 헬퍼(`apply_charm_flip`/
  `swap_random_dice`)만 재사용했다. `combat_test.gd`의 기존 `charm_flip`
  분기에 "+ > base > 미보유" 우선순위로 count를 계산하는 3줄만 추가해
  실전 배선을 마쳤다(spare_die/spare_die_plus와 같은 우선순위 패턴).
  `UPGRADE_SKILLS` 배열 맨 끝(인덱스 7/8)에 추가해 기존 `dice_test.gd`의
  `UPGRADE_SKILLS[6]` 하드코딩 검증이 안 깨지게 했다. `dice_test.gd`에
  캐릭터 필터(매혹사/곡예사 전용 확인)·`apply_charm_flip(count=1/2/3)`
  실제 효과·`advance_round()` 재발동 검증을 추가하고 `UPGRADE_SKILLS` 개수
  하드코딩을 7→9로 갱신, `bash scripts/qa_shot.sh dice_test` 전체 PASS.
  화면 레이아웃 변경은 없어 `scripts/qa_shot.sh character_select`로 기존
  7종 목록이 정상 로드됨만 재확인. D-5(character_select QA)/D-6(DESIGN.md
  표 갱신)/D-7(초상 확인)은 "한 이터레이션에 다 하지 말 것" 지시대로 다음
  이터레이션으로 남긴다.
  D-3(2026-09-24, (144)): `skill_pool.gd`의 `STARTING_SKILLS`에서
  기존 원형 6종 중 4개의 `character_ids`에 매혹사/곡예사를 추가했다(새 원형은
  만들지 않음, 지시대로). 매혹사(공격/방어 D4x3/D4x3, 균형형, 기믹이 공수
  양쪽에 작용)는 원문 예시 그대로 "확장"(`start_expand`, 합계 8+)/"정예"
  (`start_lean`, 합계 6 이하)에 추가 — 시작 합계가 6이라 "정예"가 런 시작부터
  바로 발동하는 상태다. 곡예사(공격/방어 D4x3/D4x2, 가볍게 움직이는 컨셉)는
  "맹공"(`start_aggro`, 공격>방어)/"수집가"(`start_hoard`, 눈금 5개 이상)에
  추가 — 시작 다이스 구성 자체가 공격(3)>방어(2)라 "맹공"이 런 시작부터
  바로 발동한다(캐릭터 컨셉과 우연히 잘 맞아 슬롯 0으로 배치). `STARTING_SKILLS`
  배열 안에서의 등장 순서가 곧 슬롯 순서라(주석 참고), 매혹사는
  [확장(슬롯0), 정예(슬롯1)], 곡예사는 [맹공(슬롯0), 수집가(슬롯1)]이 된다.
  `combat_test.gd`의 6개 조건 분기는 전부 `RunState.skill_flags`만 검사하고
  캐릭터 id를 하드코딩하지 않는 구조라 전투 배선은 코드 수정 없이 그대로
  작동한다(확인만 함). `dice_test.gd`의 `_check_starting_skills` 기대값
  맵에 enchantress/juggler 두 항목을 추가해 슬롯 순서를 검증하고,
  `bash scripts/qa_shot.sh dice_test` 전체 PASS. `qa_out/character_select_
  juggler_skills.png`(곡예사 상세 패널, `_debug_select_juggler` 훅 사용)로
  "맹공"(선택됨, 금테)/"수집가"(자물쇠, 미해금) 두 슬롯이 겹침 없이 정상
  표시됨을 확인. D-4(고유 스킬 신설)/D-5(character_select QA)/D-6(DESIGN.md
  표 갱신)/D-7(초상 확인)은 지시대로 다음 이터레이션으로 남긴다.
  D-1~2: `achievement_manager.gd`의 `DEFINITIONS`에 기존 5종과 같은 패턴으로
  `clear_enchantress`("매혹사로 첫 클리어")/`clear_juggler`("곡예사로 첫
  클리어") 업적 2종을 추가했다. `combat_test.gd`의 실제 unlock 호출부
  (`_apply_room_advance()`)는 정적 목록이 아니라 `_character_clear_
  achievement_id(RunState.character_id)`로 `"clear_%s" % char_id`를 즉석에서
  조합하는 구조라 이미 7종 전부를 자동으로 커버하고 있었음(코드 수정 불필요).
  대신 `dice_test.gd`의 회귀 검증용 하드코딩 목록 `all_clear_ids`(5종만
  있었음)에 두 id를 추가해 "업적 정의가 7종 다 있는지" 검증을 갱신했다.
  `bash scripts/qa_shot.sh dice_test` 전체 PASS. D-3(STARTING_SKILLS 배정)/
  D-4(UNIQUE_SKILLS 고유 스킬)/D-5(character_select QA)/D-6(DESIGN.md 표
  갱신)/D-7(초상 확인)은 "한 이터레이션에 다 하지 말 것" 지시대로 다음
  이터레이션으로 남긴다.
  **추가 지시(2026-09-24, 사람이 직접): A의 이름을 "침묵의 무녀"에서
  "주술사"로 바꾸고, "방어형"이라는 컨셉 표현은 빼달라고 함** — id/기믹
  (`guard_stack`)/수치는 그대로 두고 `name`을 "주술사"로, `desc`/`concept`
  문구에서 "방어형"/"인내형" 같은 방어 아키타입 표현을 빼고 저주·술식
  컨셉으로 재서술(예: "방어 다이스가 최댓값을 보일 때마다 저주 술식이
  쌓여..."). `achievement_manager.gd`의 `clear_shieldbearer` title/desc,
  `docs/DESIGN.md`의 캐릭터 표·초기 다이스 구성 절도 "주술사"로 함께
  갱신함(사람이 직접 처리, 이터레이션 커밋 아님). 아래 B/C/D 원문 설계의
  "침묵의 무녀"라는 이름은 이제 전부 "주술사"로 읽을 것 — 기믹/수치/id는
  그대로이니 D를 이어갈 이터레이션은 이 이름만 바꿔서 진행하면 된다.
  A: `character_profiles.gd`의 `id: "shieldbearer"` 항목에서 id/기믹
  (`guard_stack`)/attack_count(3)/defense_count(4)/event_die_sides(6)는
  전혀 건드리지 않고 `name`("방패병"→"침묵의 무녀")/`desc`/`concept`/
  `hair_color`/`dress_color`만 아래 지시된 문구 그대로 교체했고,
  `achievement_manager.gd`의 `clear_shieldbearer` title/desc 문구도
  갱신했다(id는 유지). `docs/DESIGN.md`도 동기화.
  B: `character_profiles.gd` PROFILES에 `id: "enchantress"`(매혹사,
  `gimmick: "charm_flip"`, 공격/방어 D4x3/D4x3) 항목을 추가하고,
  `dice_bag.gd`에 신규 `apply_charm_flip(values)`(그 턴 최저값 다이스 1개를
  최댓값으로 교체) 헬퍼를 추가, `combat_test.gd`의 `_do_exchange()`에
  런타임 분기를 걸어 플레이어 공격/방어턴마다 적용되게 배선했다(보너스
  1D20 임시 주머니에는 적용 안 되게 방어적으로 처리). `skill_icon.gd`에
  하트 모양 전용 아이콘도 추가해 자동 검증(`dice_test.gd`의
  `_check_skill_icons`)을 통과시켰다.
  C: `character_profiles.gd` PROFILES에 `id: "juggler"`(곡예사, `gimmick:
  "juggle_swap"`, 공격/방어 D4x3/D4x2) 항목을 추가하고, `dice_bag.gd`에
  신규 static `swap_random_dice(bag_a, bag_b)`(두 주머니에서 무작위
  다이스 하나씩 골라 통째로 맞바꿈) 헬퍼를 추가했다. juggle_swap은
  min_max_only류와 같은 "reset_run() 직후 1회 정적 적용" 패턴이라
  combat_test.gd가 아니라 `run_state.gd`의 `_apply_character_gimmick()`
  match 문에 분기를 걸었다(지시된 위치 그대로). `skill_icon.gd`에 교차
  화살표 아이콘도 추가해 자동 검증을 통과시켰다.
  `bash scripts/qa_shot.sh dice_test` 전체 PASS(신규 검증 포함),
  `qa_out/character_select.png`/`character_select_juggler.png`로 목록에
  새 이름/색(방패병→침묵의 무녀, 매혹사, 곡예사)이 정상 표시됨을 확인.
  D(공통 후속)는 다음 이터레이션이 이어갈 차례 — 아래 원문 설계를 그대로
  남겨둔다.
  docs/STATUS.md 완료 기록(140, 141, 142)/다음 할 일 큐 -1번 참고.

  **(기획자 결정 — 구체적 설계, [대형 기획 4] 캐릭터 로스터 개편: 방패병 리스킨 +
  신규 2종)**

  **A. 방패병 리스킨(삭제가 아니라 재사용)** — `character_profiles.gd`의
  `id: "shieldbearer"` 항목은 **id/gimmick("guard_stack")/attack_count(3)/
  defense_count(4)/event_die_sides(6)를 전부 그대로 유지**하고 `name`/`desc`/
  `concept`/`hair_color`/`dress_color`만 바꾼다 — id를 바꾸면
  `achievement_manager.gd`의 `clear_shieldbearer`, `skill_pool.gd`의
  `chain_guard`/`chain_guard_plus`(character_id: "shieldbearer"), `start_wall`/
  `start_lean`(character_ids에 "shieldbearer" 포함) 등 이미 이 id를 참조하는
  모든 곳을 다 고쳐야 해서 위험하고 불필요하다 — **겉모습(이름/설명/색)만
  "음침 거유" 컨셉으로 바꾸고 내부 id/기믹/수치는 절대 건드리지 않는다.**
  새 이름: **"침묵의 무녀"**. concept: "음침하고 말이 없는 무녀 — 방어 다이스가
  최댓값을 보여줄 때마다 수호 스택이 쌓임(기존 방패병 기믹과 완전히 동일, 이름만
  교체)." `achievement_manager.gd`의 `clear_shieldbearer` title도 "침묵의 무녀로
  첫 클리어"로 문구만 갱신(id는 유지).

  **B. 신규 캐릭터 "매혹사"** (id: `enchantress`, 섹시·도발적 컨셉) — 신규 기믹
  `charm_flip`: "그 턴에 굴린 다이스들 중 가장 낮은 값을 보인 다이스 딱 1개를
  그 다이스의 최댓값으로 바꾼다(공격턴/방어턴 모두 적용, 턴마다 1개만)." 구현:
  `dice_bag.gd`에 신규 `apply_charm_flip(values)` 헬퍼를 `apply_flat_bonus()`/
  `apply_steady_guard()`와 같은 패턴(원본 배열 안 건드리고 보정된 새 배열 반환)
  으로 추가 — `adjusted` 배열에서 `dice.size()` 범위 내 최솟값의 인덱스를 찾아
  `adjusted[i] = dice[i].size()`(그 다이스의 면 개수, 즉 최댓값)로 교체. 이건
  `steady_guard`(다크 나이트 몬스터 기믹)처럼 **런타임 매 턴 보정**이므로,
  `combat_test.gd`에서 `player_dice_gimmick == "steady_guard"`류를 체크하는
  것과 같은 위치에 `"charm_flip"` 분기를 추가해 공격/방어 양쪽 값 계산 직후
  호출한다. attack_count/defense_count: 3/3(균형형 — 매혹은 공수 어디에나
  작용하므로 몰빵 배분 불필요, 잠정값). hair_color/dress_color: 자주/붉은
  계열, 기존 5종과 안 겹치는 톤으로 잠정 배정.

  **C. 신규 캐릭터 "곡예사"** (id: `juggler`, 빈 포지션+재미요소) — 신규 기믹
  `juggle_swap`: "런 시작 시 1회, 공격 다이스 중 무작위 하나와 방어 다이스 중
  무작위 하나를 서로 맞바꾼다(다이스 객체 전체 — 면 구성/눈금까지 통째로 이동,
  개수(attack_count/defense_count)는 안 바뀜)." 이건 min_max_only/
  fixed_defense_die와 같은 **"reset_run() 직후 1회 정적 적용"** 패턴이므로,
  `run_state.gd`의 기믹 적용 match 문(`_apply_character_gimmick()`류)에
  `"juggle_swap"` 분기를 추가해 `player_attack_bag.dice`/
  `player_defense_bag.dice` 배열에서 무작위 인덱스를 하나씩 골라
  `dice[i]`끼리 교환한다(면 개수 통일된 시작 상태에서는 사실상 의미 없어
  보일 수 있지만, 다이스 개조 아이템으로 나중에 눈금/면 개수가 달라지면 이
  캐릭터는 "언제 어떤 다이스가 어느 역할로 굴러갈지 뒤섞여 있다"는 정체성이
  체감됨 — 매 전투가 아니라 런 시작 1회이므로 한 런 안에서는 고정). attack_count/
  defense_count: 3/2(가볍게 움직이는 느낌, 잠정값). hair_color/dress_color:
  알록달록한 서커스풍 — 노랑/보라 등 대비되는 톤 잠정 배정.

  **D. 공통 후속 작업** (B/C 둘 다 적용, 한 이터레이션에 다 하지 말 것):
  1. `character_profiles.gd` PROFILES에 두 항목 추가(B/C 각각 desc/concept 문구
     포함, 기존 5종과 같은 필드 구조).
  2. `achievement_manager.gd`에 `clear_enchantress`/`clear_juggler` 업적 추가
     (기존 `clear_<id>` 5종과 완전히 같은 패턴 — "최종 클리어(3라운드 전부)").
     `combat_test.gd`의 `_apply_room_advance()`에서 이 두 id도 함께 unlock되게
     기존 캐릭터별 unlock 목록에 추가.
  3. `skill_pool.gd`의 `STARTING_SKILLS`(6원형: 맹공/철벽/확장/정예/수집가/강철
     방비)에서 매혹사/곡예사에게 각 2종씩 `character_ids`를 추가 배정(새 원형을
     만들 필요 없음 — 매혹사는 공수 겸용이니 "확장"+"정예" 같은 범용 축, 곡예사는
     "수집가"+"확장"처럼 재미있게 배정해도 됨, 정확한 배정은 구현하는 사람이 컨셉에
     맞게 정해도 됨).
  4. `skill_pool.gd`의 `UNIQUE_SKILLS`/`UPGRADE_SKILLS`에 매혹사/곡예사 전용
     고유 스킬 1종씩("+" 강화판 포함) 추가 — 기존 5종처럼 "자기 기믹과 시너지"
     방향으로(예: 매혹사는 charm_flip 대상 다이스 개수를 1개->2개로 늘리는 스킬,
     곡예사는 juggle_swap을 런 시작뿐 아니라 라운드가 바뀔 때마다 재발동하는
     스킬 등 — 정확한 효과는 구현하는 사람이 기존 패턴에 맞춰 정해도 됨).
  5. `character_select.gd`/`.tscn`: 캐릭터가 5->7종이 되므로 목록(왼쪽 세로
     목록, 2단 레이아웃)이 7줄에서도 겹침 없이 스크롤/축소되는지 QA 확인 —
     레이아웃이 깨지면 그때 고칠 것(미리 큰 구조를 바꾸지 말고, 실제로 깨질 때만).
  6. `docs/DESIGN.md`의 캐릭터 표를 7종으로 갱신.
  7. `character_portrait_placeholder.gd`는 코드 수정 없이(hair_color/dress_color
     매개변수만 새로 넘기면 그대로 재사용됨) 매혹사/곡예사 placeholder 초상을
     자동으로 얻는다 — 확인만 하면 됨.
  완료 기준: A~D 전부 끝나면 이 항목을 "처리됨"으로 옮길 것. 진행 중에는 STATUS.md
  에 A/B/C/D-N 중 몇 번까지 끝났는지 남길 것.

- [부분 처리됨 - 2026-09-15] 2026-09-14 대신 해당 품목이 골드 부족인지, 이미 판매된
  품목인지는 해당 품목 상단에 보여주도록 한다.
  → "골드 부족" 부분만 처리. `code/scenes/item_card_style.gd`의 `build_card()`에
  `unaffordable` 매개변수를 추가해, 골드가 부족한 품목 카드는 배경/테두리를 어둡게
  칠하고 가격 라벨 옆에 빨간 "골드 부족" 배지를 표시(카드 "상단"의 가격 줄에 붙임 —
  아래 처리됨 항목 참고). "이미 판매된 품목" 부분은 처리 못 함 — 지금 상점 아이템은
  "판매 완료" 개념 자체가 없어(같은 카드를 골드가 있는 한 반복 구매 가능, 소모되는
  재고가 아님) 표시할 상태가 없다. 상점에 재고/1회성 구매 제한 같은 새 규칙이
  생기면 그때 이 배지 자리를 재사용할 수 있음 — 아직 그런 설계가 없어 완전히
  처리된 것은 아님. docs/STATUS.md 완료 기록(94) 참고.

- [부분 처리됨 - 2026-09-09] 2026-09-09 **[대형 기획 3] 업적 시스템 추가**. 업적을
  저장/추적/표시하는 시스템 자체를 만들고(`RunState`와 별개로 세이브 파일이나 전역
  상태에 영구 저장 — 런이 끝나도 유지), 캐릭터별 최종 보스 클리어 5종 + 추가 25종
  (합쳐서 30종) 업적을 구현할 것.
  → **시스템(저장/추적/UI) 골격 완성, 업적 콘텐츠는 12종 등록(2026-09-09
  (79)+(80)+(81)+(82)).** 세션 지침을 따라 "30종을 한 번에 넣지 말고 시스템부터"로
  진행. `code/systems/achievement_manager.gd`(`AchievementManager` Autoload)가
  `user://achievements.json`에 해금 상태를 영구 저장(RunState.reset_run()과
  무관하게 유지)하고, `unlock(id)`/`is_unlocked(id)`/`get_all_for_display()`
  API를 제공. `code/scenes/achievement_panel.gd`(`AchievementPanel`)가
  잠금/해금 카드 목록 오버레이 UI를 만들고, `character_select.tscn`의 새 "업적"
  버튼으로 연다. 등록된 업적 12종: "첫 발걸음"(원 목록 #25)/"던전 클리어"(#1)/
  "거인의 주사위"(D20 보유 승리, #6) — 이상 (79) — 에 이어 (80)에서
  "부자"(골드 100 이상 보유)/"무결점 승리"(무피해 승리)/"기사회생"(HP 2 이하로
  승리)/"오버킬"(몬스터 최대 체력 이상 데미지) 4종, (81)에서 "눈금 수집가"(눈금
  인벤토리 10개 이상)/"다이스 수집가"(다이스 인벤토리 5개 이상)/"가득 찬
  주머니"(주머니가 MAX_DICE=6에 도달) 3종, (82)에서 "단골 손님"(한 런에서 상점
  3회 이상 이용, `RunState.shop_visits` 신규 카운터)/"재질 수집가"(플라스틱/
  나무/유리/철제 4개 재질 다이스를 동시에 보유) 2종을 추가(원 목록의 정확한
  번호는 원문 미보존으로 알 수 없음). (82)로 "새 RunState 카운터만 있으면
  되는" 독립 항목은 거의 소진됐고, 남은 항목(캐릭터별 보스 클리어 5종 포함 —
  [대형 기획 1]/[대형 기획 2]가 먼저 구현돼야 트리거 지점이 생기는 것들이
  대부분)은 `DEFINITIONS`에 항목만 추가하고 해당 조건에서 `unlock(id)`만
  호출하면 되는 구조로 남겨둠 — 완전히 처리된 것은 아님. docs/STATUS.md 완료
  기록(79, 80, 81, 82)/다음 할 일 큐 13번 참고.

- [부분 처리됨 - 2026-09-09] 2026-09-09 (성장의 재미 관련 추가 답변) 이 선택지로 얼마나 강해지는지 알기 어렵다.
  최소/최대 기댓값이 있으면 좋아질텐데, 뭔가 더 있어야할 것 같다. 두 가지 방향 제안:
  1) **다이스 개수를 N개로 제한**하고, 그 고정된 풀 안에서 다이스 또는 눈금을
     "교체"하는 방식으로 성장을 표현하는 건 어떨까 (지금처럼 계속 늘어나는 방식
     대신). 2) **몇 턴 쿨타임이 있는 스킬**을 플레이어가 보유하는 건 어떨까 —
     플레이어블 캐릭터에 따라 보유 스킬이 달라지는 형태로.
  (원본: "성장의 재미가 없다. 플레이어가 상황을 인지하기 어렵고, 어떻게 해야
  얼마나 강해지는지 알기가 어렵다.")
  → 방향 1의 첫 조각만 처리(2026-09-09 (76)): `DiceBag.MAX_DICE`(=6, 시작 3개의
  2배, 잠정값) 캡을 도입해, 주머니가 캡에 도달하면 "다이스 추가" 아이템이
  `DiceItemPool.is_applicable()`로 막히고 버튼에 "주머니 가득 참 (최대 6개)"
  문구가 뜨도록 함(상점/특수 이벤트/전투 승리 보상 3곳 공통). 캡에 도달한 뒤의
  "교체" 경로는 새로 만들지 않고 기존 "다이스 승급"(면 개수 교체)/"눈금 교환"
  기능을 그대로 재사용. `dice_test` 회귀 스위트에 신규 검증 추가해 76개 항목
  전체 PASS, `qa_out/shop_maxed_bag.png`로 실제 화면에서 캡 도달 시 버튼
  비활성화가 겹침/크래시 없이 보임을 확인. 캡 수치와 "교체로 성장한다"는 감각이
  실제로 체감되는지는 사람이 캡까지 도달하며 플레이해봐야 판단 가능 — 완전히
  처리된 것은 아님. 방향 2(캐릭터별 쿨다운 스킬)는 캐릭터가 1종뿐이라 스킬
  콘텐츠 자체를 새로 기획해야 하는 더 큰 작업이라 여전히 미착수.
  docs/STATUS.md 완료 기록(76) 참고.

- [부분 처리됨 - 2026-09-09] 2026-09-09 전투의 재미가 없다. 다이스 값이 잘 안보여서 쪼이는 맛이 덜하다.
  → "다이스 값이 잘 안보인다" 부분은 아래 "체력바 추가/사이즈업" 항목과 함께 처리(교환 결과
  칩 크기 확대). "쪼이는 맛"(위기감) 자체가 충분한지는 체력바의 색 경고(아래 참고)가
  도움이 될 수 있지만 최종 판단은 사람 플레이 피드백 필요 — 완전히 처리된 것은 아님.
- [부분 처리됨 - 2026-09-03] 2026-09-03 맵 전체를 봐야할 것 같음. 첫 번째 선택지에 따라 다음 선택지가 어떻게 바뀌는지. 슬더스 맵선택 방식과 같음.
  → "맵 전체를 봐야할 것 같음" 부분만 반영. `dungeon_map.tscn`에 `MapStrip`을 추가해
  런 전체(5방)의 방 번호별 선택지(전투/상점/특수 이벤트/스토리 이벤트)를 한 줄로
  미리 보여줌(지나온 방은 "완료" 표시, 현재 방은 금색 테두리). "첫 번째 선택지에
  따라 다음 선택지가 어떻게 바뀌는지" 부분(분기형 노드 그래프)은 아직 — 지금은 방
  구성이 서로 독립적으로 결정되는 선형 구조라, 고른 선택지가 다음 방 구성에 영향을
  주지 않음. 진짜 분기는 DESIGN.md가 확정한 "일단은 선형으로" 방향을 벗어나는 큰
  구조 변경이라 사람 설계 확인 필요. docs/STATUS.md 큐 0번/완료 기록 참고.
- [부분 처리됨 - 2026-09-02] 2026-09-01 레벨 디자인된 여러 스테이지가 필요함 (일단은 선형으로 점차 강해지게 만들고, 스탭 바이 스탭으로 수평적 선택지를 넓힌다)
  → 던전 맵에 "전투 방" 외에 "상점"/"특수 이벤트" 선택지가 추가되어 방마다 최대 3개 중
  고를 수 있게 됨(수평적 선택지 확장). 방 선택지가 매번 전부 노출되는 대신 상점/특수
  이벤트는 방마다 확률적으로만 노출되도록 개선도 완료됨. 다만 방 종류 자체가 이 셋뿐이라
  순수 텍스트형/스토리형 선택지 이벤트는 여전히 없음 — 다음 할 일 큐 참고.
- 2026-09-01 전투 이후, 강화 카드를 선택한다. (강화 카드에는 주사위 눈이 있다)
  [부분 처리됨 - 2026-09-02] 카드형 비주얼은 아직 없지만, 승리 보상 화면에 다이스
  눈금 값을 보여주는 커스터마이징 선택지가 추가됨 (아래 "처리됨"의 커스터마이징 관련
  항목들 참고).
- [부분 처리됨 - 2026-09-02] 2026-09-01 던전에 입장하면, 플레이어블 캐릭터를 선택해야한다. (슬더스와 유사)
  → `scenes/character_select.tscn`(+`.gd`)을 새 main_scene으로 추가. "던전 시작"
  버튼을 누르면 새 런을 시작하고 던전 맵으로 진입하는 흐름은 완성됨. 다만 캐릭터가
  1종뿐이라 "선택"이라기보다 "확인" 화면에 가까움 — 캐릭터가 여럿 생기면 카드 여러 개
  중 고르는 형태로 확장 필요. docs/STATUS.md 완료 기록 참고.
- [부분 처리됨 - 2026-09-02] 2026-09-01 일단은 능력 없는 기본 캐릭터. 이쁘장한 여캐 하나 디자인한다.
  → 능력 차별화 없는 캐릭터 1종("견습 모험가")만 존재하도록 구현함(요청대로). 다만
  "이쁘장한 여캐 디자인"은 AI가 실제 일러스트를 그릴 수 없어서 도형 조립 플레이스홀더
  실루엣(`scenes/character_portrait_placeholder.gd`, 라벤더 단발머리 + 분홍 원피스)로
  대체함 — 최종 아트는 사람이 직접 그리거나 리소스를 구해서 교체해야 함.
- [부분 처리됨 - 2026-09-02] 2026-09-01 상대는 몬스터 무스메들이 나온다.
  → 아직 "무스메"(의인화된 미소녀) 디자인은 아님. 전투 화면에 몬스터 실루엣이
  표시되긴 하지만 뿔 달린 둥근 블롭 형태의 플레이스홀더일 뿐 — 실제 무스메
  컨셉 아트/디자인은 사람이 정하거나 기획해야 함(캐릭터 초상화와 마찬가지로
  AI는 실제 일러스트를 그릴 수 없음).

## 처리됨

- [처리됨 - 2026-09-17] 2026-09-17 다음 할 거리로, 직업별 여러 스킬을 만들고,
  시작할 때 시작 스킬을 하나 정하도록 하자. 최초에는 하나밖에 못고름. 나머지는
  전부 lock 걸려있음. 캐릭터별 업적 보상(해당 캐릭터로 라운드 클리어)하면
  해금되어, 다음 회차에서 다른 스킬을 선택할 수 있도록 선택지를 늘린다. 아직
  변경된 스킬을 보진 못했지만, 시작 스킬에 따라 게임 플레이 경험이나, 선택해야
  하는 주사위 밸류가 달라지면 좋을 듯함. 공격 덱에 투자하면 이득이라던가, 방어
  덱에 투자하면 이득이라던가, 주사위가 많아지면 좋거나, 반대로 덜 늘리면 좋거나,
  특정 재질로 바꾸면 좋거나, 눈금을 모으면 좋거나 등등...

  **(기획자 결정 — 구체적 설계, [미니 기획 E] 캐릭터별 시작 스킬 선택)**
  이건 지금 있는 "캐릭터 스킬 부여 이벤트"([미니 기획 C], 런 중 무작위로
  얻는 스킬)와는 별개의 새 레이어다 — 런 "시작 시점"에 미리 정해두는 로드아웃
  선택. 기존 skill_flags/grant() 파이프라인을 그대로 재사용하되, "언제/어떻게
  얻는지"만 다르다(무작위 이벤트가 아니라 캐릭터 선택 화면에서 확정 선택).

  1. **해금 판정은 새 저장 시스템을 만들지 않는다** — 이미 있는
     `AchievementManager.is_unlocked("clear_" + character_id)`(캐릭터별
     "최종 클리어(3라운드 전부)" 업적, 이미 `user://achievements.json`에
     영구 저장됨)를 그대로 재사용한다. "라운드 클리어"라는 원 표현은 지금
     캐릭터별 업적이 라운드1이 아니라 "최종 클리어" 기준으로만 있어서, 그
     기존 업적을 해금 트리거로 쓴다는 뜻으로 해석했다(새 "라운드1 클리어
     캐릭터별" 업적을 따로 만들지 않음 — 이미 있는 것 재사용이 더 간단하고
     사용자 의도(진행하면 해금)와도 맞음).
  2. **시작 스킬 데이터** (`code/systems/skill_pool.gd`에 신규
     `STARTING_SKILLS: Array[Dictionary]` 상수): 아래 6개 원형을, 여러
     캐릭터가 공유할 수 있게 `character_ids: Array[String]` 필드로 표시한다
     (SKILLS/UNIQUE_SKILLS와 별개 상수 — 이 스킬들은 런 중 이벤트로는 절대
     나오지 않고 오직 시작 선택으로만 얻는다는 차이가 있어 섞지 않음). 전부
     `DiceBag.apply_flat_bonus(values, 1)`(이미 있는 "결과값 +1, 상한은 면
     개수" 헬퍼, "심호흡"이 쓰는 것과 동일)를 재사용해서 조건이 참일 때만
     적용하는 방식으로 통일 — 새 다이스 연산을 만들지 않는다.
     - `start_aggro`("맹공", character_ids: [berserker, explosive]): 공격
       다이스 개수 > 방어 다이스 개수이면 공격 다이스 결과값 전체 +1.
     - `start_wall`("철벽", character_ids: [guardian, shieldbearer]): 방어
       다이스 개수 > 공격 다이스 개수이면 방어 다이스 결과값 전체 +1.
     - `start_expand`("확장", character_ids: [novice, explosive]): 공격+방어
       다이스 합계 >= 8개이면 공격/방어 다이스 결과값 전체 +1.
     - `start_lean`("정예", character_ids: [novice, shieldbearer]): 공격+방어
       다이스 합계 <= 6개(초기값과 같거나 적게 유지)이면 공격/방어 다이스
       결과값 전체 +1.
     - `start_hoard`("수집가", character_ids: [berserker]): `RunState.
       pip_inventory.size() >= 5`이면 공격 다이스 결과값 전체 +1(눈금을 안
       쓰고 모아두는 것 자체가 이득이 되게 — 인벤토리 압박과 트레이드오프).
     - `start_ironclad`("강철 방비", character_ids: [guardian]): 보유
       다이스 중 `combat_test._material_for_sides(sides)`가 철제인 것(D12/
       D20)이 1개 이상이면 방어 다이스 결과값 전체 +1.
     캐릭터별 "선택 가능한 시작 스킬 목록" = 위 배열을 `character_ids`에 그
     캐릭터 id가 포함된 것만 순서대로 필터링한 결과 — 목록의 0번째가 "슬롯
     0"(항상 해금), 1번째가 "슬롯 1"(1번의 업적 해금 시에만 선택 가능)이다.
     결과적으로: 견습 모험가=[확장, 정예], 광전사=[맹공, 수집가], 수호자=
     [철벽, 강철 방비], 폭발병=[맹공, 확장], 방패병=[철벽, 정예] — 캐릭터당
     정확히 2종.
  3. **선택 UI** (`code/scenes/character_select.gd`): 캐릭터 상세 패널에
     "시작 스킬" 선택 줄을 추가한다. 슬롯 0은 항상 카드/버튼으로 눌러 선택
     가능. 슬롯 1은 `AchievementManager.is_unlocked("clear_" + id)`가 false이면
     자물쇠 아이콘(기존 `achievement_icon.gd`류 절차적 `_draw()` 패턴 재사용
     가능)과 함께 비활성화 표시, true이면 슬롯 0과 동일하게 선택 가능해진다.
     선택 상태는 새 `RunState.chosen_starting_skill_id: String` 필드에 저장
     (캐릭터를 바꾸면 그 캐릭터의 슬롯 0으로 리셋). 아무것도 안 눌러도 슬롯
     0이 기본 선택된 것으로 취급(원 요청 "최초에는 하나밖에 못 고름"과 일치).
  4. **적용 배선**: `RunState.reset_run()`이 새 런을 만들 때
     `SkillPool.grant(chosen_starting_skill_id)`를 호출해 skill_flags에
     즉시 넣는다(런 시작부터 적용, 기존 grant()/skill_flags 파이프라인
     재사용 — 새 필드 없이 끝남). `combat_test.gd`의 `_do_exchange()`(기존
     "심호흡"/"여분" 체크와 같은 위치)에 6개 조건 분기를 추가해 각각
     `apply_flat_bonus()`를 호출한다 — 한 이터레이션에 6개를 다 하지 말고
     2~3개씩 나눠 진행할 것(예: 맹공/철벽 먼저, 그 다음 확장/정예, 마지막
     수집가/강철 방비).
  5. **UI 강조 재사용**: [미니 기획 D]에서 만든 `ItemCardStyle.build_card()`의
     `highlight` 파라미터가 있으면, 슬롯 1(업적으로 해금된 스킬)에도
     재사용해도 좋다(필수는 아님 — 해금 자체가 이미 의미 전달이 되므로).
  완료 기준: 1~4번이 끝나면 이 항목을 "처리됨"으로 옮길 것(5번은 선택). 진행
  중에는 STATUS.md에 몇 번까지 끝났는지 남길 것.

  → **전체 완료(2026-09-17, 1~4번, 5번은 선택이라 미착수).** (134)에서
  `code/systems/skill_pool.gd`에 위 6개 원형 그대로 `STARTING_SKILLS` 상수와
  `starting_skills_for_character(character_id)` 필터 헬퍼를 추가했다(2번) —
  캐릭터별 슬롯 순서(견습=[확장,정예], 광전사=[맹공,수집가], 수호자=[철벽,
  강철 방비], 폭발병=[맹공,확장], 방패병=[철벽,정예])가 위 원문과 정확히
  일치함을 `dice_test.gd`의 `_check_starting_skills`로 검증. (135)에서
  1번(해금 판정)과 3번(선택 UI)을 함께 진행 — `character_select.gd` 상세
  패널에 "시작 스킬" 섹션을 추가해 슬롯 0/1을 버튼으로 보여준다. 슬롯 0은
  항상 클릭 가능, 슬롯 1은 지시대로 `AchievementManager.is_unlocked("clear_"
  + character_id)`가 false면 신규 `code/scenes/lock_icon.gd`(`LockIcon`,
  achievement_icon.gd류 절차적 `_draw()` 패턴 재사용)로 자물쇠 아이콘을
  붙이고 `disabled=true`로 클릭 자체를 막는다(true면 슬롯 0과 동일하게 선택
  가능). 선택 상태는 지시대로 신규 `RunState.chosen_starting_skill_id:
  String`에 저장하고, 캐릭터를 바꾸면 그 캐릭터 기준으로 여전히 유효한
  (잠기지 않은) 선택인지 재검증해 아니면 슬롯 0으로 되돌린다. **(136)에서
  4번(적용 배선)을 시작 — 지시대로 6개를 한 번에 하지 않고 맹공/철벽부터
  진행.** `RunState.reset_run()`이 `skill_flags`를 비운 직후
  `chosen_starting_skill_id`가 비어있지 않으면 `SkillPool.grant(chosen_
  starting_skill_id)`를 호출하도록 배선(이제 슬롯 선택이 "던전 시작"과
  동시에 실제 skill_flags에 들어감). `combat_test.gd`의 `_do_exchange()`에
  기존 "여분"(공격턴)/"심호흡"(방어턴) 분기 바로 뒤에 "맹공"(`start_aggro`:
  공격 다이스 개수 > 방어 다이스 개수면 공격 다이스 결과값 +1)과
  "철벽"(`start_wall`: 방어 다이스 개수 > 공격 다이스 개수면 방어 다이스
  결과값 +1) 조건 분기를 추가 — 둘 다 기존 `DiceBag.apply_flat_bonus()`
  재사용, 새 다이스 연산 없음. `dice_test.gd`의 신규 `_check_starting_skill_
  combat_wiring`(reset_run 배선 자체 + 광전사/수호자 기본 구성이 각 조건을
  실제로 만족하는지 검증)으로 확인, `bash scripts/qa_shot.sh dice_test`
  전체 PASS. `qa_out/combat_test.png`로 전투 화면 크래시/겹침 없음도 확인.
  **(137)에서 이어서 "확장"(`start_expand`: 공격+방어 다이스 합계 8개
  이상)/"정예"(`start_lean`: 같은 합계 6개 이하) 2개를 배선** — 맹공/철벽과
  같은 위치·같은 헬퍼 재사용, 다만 "합계"만 보는 조건이라 공격턴/방어턴
  양쪽에 각각 대칭으로 심었다(맹공/철벽은 공격턴엔 맹공만/방어턴엔 철벽만
  필요했던 것과 차이). `dice_test.gd`에 임계값을 넘나드는 지점(다이스 추가
  전/후) 검증을 추가, `bash scripts/qa_shot.sh dice_test` 전체 PASS.
  **구현 중 발견: 방패병의 "정예" 슬롯은 방패병 기본 다이스 합계(7개)가
  이미 조건(6개 이하)을 넘어섰고 다이스를 줄이는 수단이 게임에 전혀 없어
  이론상 절대 발동하지 않는 죽은 선택지다** — docs/STATUS.md "알려진 이슈"에
  기록, 임계값/슬롯 배정을 임의로 바꾸지 않고 사람 결정을 기다림(여전히
  미해결). **(138)에서 마지막 2개("수집가"/"강철 방비")를 배선해 4번(적용
  배선) 6개 전부 완료** — "정예" 분기 바로 뒤(공격턴)에 "수집가"
  (`start_hoard`: 눈금 인벤토리 5개 이상이면 공격 다이스 결과값 +1), "정예"
  분기 바로 뒤(방어턴)에 "강철 방비"(`start_ironclad`: 철제 재질(D12/D20)
  다이스를 1개 이상 보유하면 방어 다이스 결과값 +1) 조건 분기를 추가(기존
  `DiceBag.apply_flat_bonus()` 재사용, 새 다이스 연산 없음). `dice_test.gd`에
  두 조건이 임계값을 넘나드는 지점에서 켜지고 꺼지는지 검증 추가,
  `bash scripts/qa_shot.sh dice_test` 전체 PASS. 이걸로 6종 전부
  (맹공/철벽/확장/정예/수집가/강철 방비)가 실제 전투 보너스로 이어져
  [미니 기획 E] 완료 기준(1~4번)을 전부 충족했다. docs/STATUS.md 완료
  기록(134~138) 참고.

- [처리됨 - 2026-09-17] 2026-09-17 스킬을 강화시킬 수 있는 이벤트를
  추가해줘. 강화되는 스킬은 [스킬명+] 라고 네이밍 붙여서, 기존 스킬의
  강화판임을 직관적으로 알 수 있게 한다. 좋아보여야 하니까 아이콘 테두리를
  노란 색으로 두껍게 강조하면 좋을 듯 함.

  **(기획자 결정 — 구체적 설계, [미니 기획 D] 스킬 강화 이벤트)** — **전체
  완료(1~5번, 6번은 선택이라 미착수).** 지금 캐릭터 스킬은 공용 2종("심호흡"/
  "여분")+고유 5종(캐릭터별 1개씩)이 전부 `RunState.skill_flags`에 문자열
  id로만 쌓이고 강화 개념이 없던 것을, 아래 순서로 나눠 구현했다.

  1~3번은 (128)/(129)에서 완료 — `code/systems/skill_pool.gd`에
  `UPGRADE_SKILLS`(7종 강화판 데이터) + `available_upgrade_choices(n,
  character_id)`/`grant_upgrade(base_id)`, `code/scenes/event.gd`에
  `SKILL_UPGRADE_EVENT_CHANCE`(=0.2, 잠정값)로 특수 이벤트 방이 기존 스킬
  이벤트(30%)보다 먼저 "스킬 강화" 이벤트로 분기(강화 후보 없으면 항상 기존
  이벤트로 폴백, 카드 UI는 기존 스킬 획득 카드 재사용). **4번(전투 배선)은
  네 이터레이션에 걸쳐 7종 전부 완료** — `combat_test.gd`의 `_do_exchange()`가
  "`+` > base > 없음" 우선순위로 분기한다: (130) 공용 2종 "심호흡+"(매
  방어턴마다 적용, base는 첫 방어턴만)/"여분+"(여분 다이스 2개 굴려 최댓값,
  base는 1개) → (131) 광전사/수호자 페어 "광기 심화+"/"수호 심화+"(둘 다
  base의 "1D20 두 번 굴려 최댓값"을 "세 번 굴려 최댓값"으로, 공용 로직은
  신규 `_apply_bonus_reroll()` 순수 함수로 분리) → (132) 폭발병/방패병 페어
  "연쇄 폭발+"/"연쇄 방어+"(base는 임계치만 2로 낮췄을 뿐 보너스 턴 굴림은
  그대로였는데, "+"는 임계치 2 유지한 채 보너스 턴을 광기/수호 심화와 같은
  방식으로 강화, `_apply_bonus_reroll()` 재사용) → **(133)에서 마지막 남은
  "임기응변+"(견습 모험가 전용)를 배선** — 다른 4쌍과 달리 base(임기응변)가
  이미 "넓지만 얕게"(임계치·보너스 강화 없음)였으므로, "+"는 그 축("발동
  빈도")을 마저 강화 — chain_explosion/chain_guard와 같은 방식으로 공격/방어
  두 파이프라인의 임계치를 동시에 3에서 2로 낮췄다(신규
  `player_versatile_plus_active` 플래그, `_player_explosive_threshold()`/
  `_player_guard_threshold()`가 함께 확인). 이걸로 7종 전부 배선 완료.
  **(133)에서 5번(UI 강조)도 완료** — `ItemCardStyle.build_card()`에
  `highlight: bool = false` 매개변수를 추가해 true면 카드 테두리를 등급색
  대신 두껍고(4px) 노란색(`HIGHLIGHT_BORDER`)으로 그린다. `event.gd`의
  `_setup_skill_upgrade_event()`가 자기 자신을 부를 때
  `_is_skill_upgrade_event = true`로 세팅해(QA 훅처럼 `_ready()`를 거치지
  않고 직접 호출해도 항상 정확하도록 자기 완결적으로 만듦), `_show_skill_
  offer()`가 이 플래그를 `highlight` 인자로 넘긴다 — 새 스킬 획득 카드는
  이 플래그가 false라 기존 등급색 테두리 그대로. `qa_out/event_skill_
  upgrade_highlight.png`(노란 두꺼운 테두리 확인)/`qa_out/event_skill_
  offer_normal_recheck.png`(일반 스킬 카드는 기존 얇은 초록 테두리 유지)로
  검증. `dice_test.gd`에 임기응변+ 임계치 검증((7))과 highlight 파라미터
  검증(신규 `_check_skill_upgrade_card_highlight`)을 추가, `bash scripts/
  qa_shot.sh dice_test` 전체 PASS. 6번(DeckPanel 보유 스킬 목록)은 원문이
  "선택, 급하지 않음"이라 명시한 항목이라 미착수 — 완료 기준(1~5번)은 이걸로
  전부 충족돼 이 항목을 처리됨으로 옮긴다. docs/STATUS.md 완료 기록
  (128~133) 참고.

- [처리됨 - 2026-09-17] (기획자 결정) 견습 모험가("novice") 전용 고유 스킬 설계
  확정 — "임기응변" (id: `versatile_surge`).
  → 지시된 설계 그대로 구현했다. `code/systems/skill_pool.gd`의
  `UNIQUE_SKILLS`에 `character_id: "novice"` 항목을 추가하고, `code/scenes/
  combat_test.gd`에 `player_versatile_active`(다른 4개 스킬 플래그와 동일한
  위치·패턴, `RunState.skill_flags.has("versatile_surge")`) 변수를 신설해
  공격 스택 조건(`explosive_stack" or player_frenzy_active`)과 방어 스택
  조건(`guard_stack" or player_guard_deepen_active`) 각각에 지시대로
  `or player_versatile_active`를 추가했다 — 두 조건 문자열이 `_do_exchange()`
  안에 각각 2곳(보너스 1D20 사용 판단 + 스택 적립/초기화)씩 있어 4곳 모두
  동일하게 확장, 공격/방어 두 파이프라인이 함께 열리도록 했다. 지시대로
  임계치(`EXPLOSIVE_STACK_THRESHOLD`/`GUARD_STACK_THRESHOLD`, 둘 다 3)와
  보너스 턴(1D20 한 번 굴림)은 강화하지 않았다("넓지만 얕게"). `dice_test.gd`에
  캐릭터 필터 검증(novice=true, berserker=false, 다른 4개 스킬과 같은 패턴) +
  "임기응변 보유 시에도 임계치 함수 둘 다 기본값(3) 그대로인지" 검증을 추가,
  `bash scripts/qa_shot.sh dice_test` 전체 PASS. `event.gd`의 QA 훅
  `_debug_force_skill_event_as_novice()`로 `qa_out/event_skill_offer_novice.png`
  (카드 겹침 없음)를, `qa_out/combat_test.png`로 기본 전투 정상 진행을 확인했다.
  `docs/DESIGN.md`도 갱신 — **이제 5개 캐릭터 전원의 고유 스킬이 완성됨**.
  docs/STATUS.md 완료 기록(127)/다음 할 일 큐 17번 참고.

- [처리됨 - 2026-09-16] (기획자 결정) `docs/STATUS.md` "알려진 이슈"의 "특수 이벤트
  B급(D8) 아이템 사각지대" — 해결안 (b) 확정: 안전 풀을 "C 이하", 위험 성공 풀을
  "B 이상"으로 등급 경계를 겹치게 넓힌다.
  → `code/systems/event_item_pool.gd`의 `random_safe_item()`/`random_risky_item()`
  이 각각 grade="C"만/"A"·"S"만 걸러 뽑던 것을, `SAFE_GRADES=["C","B"]`/
  `RISKY_GRADES=["B","A","S"]`로 등급 경계를 B에서 겹치게 넓혔다. 지시대로 "안전은
  C가 훨씬 흔하고 B는 드묾"/"위험 성공은 상위 등급일수록 흔함"을 균등 추첨이 아닌
  가중치 추첨(`SAFE_GRADE_WEIGHTS={C:5.0,B:1.0}`, `RISKY_GRADE_WEIGHTS=
  {B:1.0,A:2.0,S:3.0}`, 신규 `_weighted_pick()` 룰렛 휠 헬퍼)으로 구현 — 정확한
  가중치 수치는 지시대로 잠정값. `dice_test.gd`의 `_check_event_safe_risky_choice`
  검증을 20→200회로 늘리고 "B급이 두 풀 모두에서 최소 1번 목격되는지" 검사를
  추가, `bash scripts/qa_shot.sh dice_test` 전체 PASS(B급 목격 "예" 확인). 순수
  드롭률 로직 변경이라 화면 레이아웃 영향은 없음. `docs/STATUS.md` "알려진
  이슈"에서 해당 항목을 삭제했다. docs/STATUS.md 완료 기록(121) 참고.
- [처리됨 - 2026-09-16] [미니 기획 C] 캐릭터 스킬 부여 이벤트 — 전체 완료 (원본:
  2026-09-14 "캐릭터에 스킬을 부여하는 이벤트를 추가한다. 직업별 공용 이벤트 및
  고유 이벤트가 각기 있다". [미니 기획 A]/[B]/[C] 세 갈래로 구체적 수치/구조를
  확정한 2026-09-15 기획자 결정 항목도, 이걸로 세 갈래 전부 완료됐으므로 함께
  처리됨으로 옮긴다). 두 이터레이션(119/120)에 걸쳐 5단계 전부 구현했다.
  (119)에서 기존 "특수 이벤트" 방이 30% 확률(`SKILL_EVENT_CHANCE`)로 아이템
  대신 스킬 이벤트가 되는 구조(1번) + `RunState.skill_flags` 배열(2번) +
  `code/systems/skill_pool.gd`(`SkillPool`)의 공용 스킬 2종("심호흡"/"여분")
  정의를 만들었고, **(120)에서 남은 3~5번을 마무리**: `combat_test.gd`의
  `_do_exchange()`가 `RunState.skill_flags`를 읽어 "심호흡"(이번 전투 첫
  방어턴 한정 방어 다이스 결과값 +1, 다이스별 면 개수가 상한 — 신규 `DiceBag.
  apply_flat_bonus()`)과 "여분"(폭발 보너스 턴이 아닌 매 공격턴마다 여분
  다이스로 이번 공격의 최저값을 advantage 방식으로 대체 — 신규
  `combat_test._apply_spare_die()`)의 실제 전투 보너스를 적용한다(3번).
  `SkillPool.UNIQUE_SKILLS`(`character_id` 필드로 필터링)에 광전사 전용 고유
  스킬 "광기 심화"(`frenzy_deepen`)를 추가해(4번), 광전사 본인 기믹
  (min_max_only)엔 원래 없는 explosive_stack류 스택 파이프라인을 열어주고
  (`player_frenzy_active`), 보너스 턴을 "1D20 두 번 굴려 더 높은 값 채택"으로
  강화했다. UI는 새 위젯 없이 (119)가 이미 재사용해둔 `ItemCardStyle`/
  `_show_skill_offer()`를 그대로 사용(5번, 지시대로 새로 안 만듦).
  `dice_test.gd`에 `_check_skill_effects`(apply_flat_bonus 계산, UNIQUE_SKILLS
  캐릭터 필터, `_apply_spare_die()`의 확률적 검증) 추가, `bash scripts/qa_shot.sh
  dice_test` 전체 PASS. 화면은 `qa_out/event_skill_offer_v2.png`(갱신된 스킬
  설명 카드)/`qa_out/combat_test_skill_smoke.png`(스킬 미보유 기본 전투가 새
  분기 추가 후에도 정상 진행)로 확인 — 광전사+광기 심화 실제 전투 장면은
  캐릭터 선택→확률적 스킬 획득이 필요해 한 번의 qa_shot으로 결정적 재현이
  어려워 로직은 단위 테스트로, 화면은 일반 회귀만 확인했다(사람이 실제 플레이로
  체감 확인하는 게 다음 단계). 나머지 4캐릭터 전용 고유 스킬은 "광기 심화가
  실제로 잘 동작/체감되는지 확인한 뒤" 다음 이터레이션이 이어갈 차례(미착수).
  docs/STATUS.md 완료 기록(119, 120) 참고.
- [처리됨 - 2026-09-16] [미니 기획 A] 몬스터별 성격 디자인 — 전체 완료 (원본:
  2026-09-01 "몬스터별 성격 디자인은 추후 기획한다", 2026-09-01 "몬스터별
  다이스에는 특이한 특징을 부여한다. 몬스터 외형이나 특성에 어울리면 좋을 것
  같다"). 2026-09-15에 확정한 5종 성격 + 기믹 재배정을 세 이터레이션(116/117/118)에
  걸쳐 전부 구현했다. (116) `combat_test.gd`의 `MONSTER_PROFILES`에서 기존 3개
  기믹을 성격에 맞게 스왑만 함 — `fixed_value`(고정값)를 오크→해골 전사로,
  `min_max_only`(극단)를 다크 나이트→오크로 옮김(슬라임/고블린은 그대로 유지).
  (117) 다크 나이트에게는 옮길 기존 기믹이 없어 신규 기믹 `steady_guard`를 새로
  구현 — `DiceBag.apply_steady_guard(values)`가 방어 다이스 굴림 "결과값"이 면
  개수 절반(올림) 미만이면 그 값을 절반값으로 끌어올림(면 값 자체는 안 바꾸고
  결과에만 사후 개입 — fixed_value의 "항상 완전히 같은 값"과 구조적으로 다름).
  `_do_exchange()`가 플레이어 공격턴(몬스터 방어턴)에만 적용, 이름에 "[철벽]"
  태그 + 디버그 정보 줄에 문구 추가. (118) 5종 각각에 `personality`(1줄 성격
  요약) 필드를 `MONSTER_PROFILES`에 추가하고 `_monster_config_for_room()`/
  `_monster_debug_info_text()`를 거쳐 몬스터 HP바 아래 디버그 정보 줄에 "성격:
  ..."로 노출. `docs/DESIGN.md`에 "던전 몬스터 (5종)" 표(이름/성격/기믹/기믹
  효과)를 신설해 반영. "몬스터 외형이나 특성에 어울리는" 배정 근거였던 성격
  기획이 이제 실제로 존재하므로, 2026-09-09에 "완전히 처리된 것은 아님"으로
  부분 처리됐던 관련 항목도 이번에 함께 완료 처리한다(아래 참고). `dice_test.gd`에
  room0/room4 디버그 문구 검증에 성격 문구 포함 여부를 추가, `bash scripts/
  qa_shot.sh dice_test` 전체 PASS. `GAME_QA_ROOM_OVERRIDE=4`로 실제 전투(다크
  나이트)를 캡처해 성격 문구가 디버그 정보 줄에 겹침 없이 표시됨을 확인
  (`qa_out/combat_test_personality.png`). [미니 기획 C](캐릭터 스킬 이벤트)는
  이번에도 손대지 않음 — 남은 유일한 미착수 미니 기획으로 위 "남은 이슈"에
  그대로 있음. `docs/STATUS.md` 완료 기록(116, 117, 118) 참고.
- [처리됨 - 2026-09-16] [미니 기획 B] 특수 이벤트 개편 — 전체 완료 (원본:
  2026-09-14 "특수 이벤트에서 얻어지는 보상이 너무 단순", "임의의 스토리를
  부여하고 리스크/리턴을 선택하도록", "D&D 난이도 체크처럼", "직업마다 이벤트
  주사위 1개", "이벤트 주사위는 커스터마이징되면 안 될 것 같다, 로마 숫자로").
  → 2026-09-15에 확정한 권장 순서(4 -> 1 -> 2+3)를 세 이터레이션에 걸쳐
  전부 구현했다. (113) `character_profiles.gd`/`run_state.gd`에
  `event_die_sides`(전부 D6) 필드, 신규 `code/scenes/event_die_visual.gd`
  (`EventDieVisual`)로 로마 숫자 육각 칩 시각화, 캐릭터 선택 상세 패널에
  샘플 표시. (114) `event_item_pool.gd`의 `ITEMS` 5종에 1문장짜리 "flavor"
  필드를 추가하고 `item_card_style.gd`가 카드 제목 아래에 표시(다른 화면의
  DiceItemPool 카드는 영향 없음). (115) `event.gd`를 "무작위 2개 중 1개
  무료 획득"에서 "안전하게 넘어가기(확정 C급)/위험을 감수하기(이벤트
  주사위 1회 굴려 `DC = min(5, 3 + room_index/2)`와 비교, 성공 시 A/S급
  무작위 획득·실패 시 보상 없음)" 2택으로 재구성, `EventItemPool`에 등급
  필터(`items_of_grade`/`random_safe_item`/`random_risky_item`) 추가.
  기존 아이템 적용 함수(`_apply_pick`/`_apply_pips`/`_apply_upgrade`)는
  시그니처를 바꾸지 않아 `dice_test.gd`의 기존 회귀 테스트가 그대로 통과.
  `dice_test.gd`에 `_check_event_die_sides`/`_check_event_item_flavor`/
  `_check_event_safe_risky_choice` 신규 검증 추가, 회귀 스위트 전체 PASS.
  구현 중 발견한 간극: 등급 배정상 B급 아이템("다면체 주사위 획득 (D8)")이
  안전(C만)/위험 성공(A/S만) 어느 풀에도 안 걸려 이 방에서는 다시 안 나오는
  사각지대가 됨 — `docs/STATUS.md` "알려진 이슈"에 기록, 사람 결정 필요.
  [미니 기획 A](몬스터 성격)/[미니 기획 C](캐릭터 스킬 이벤트)는 이번에도
  손대지 않음 — 위 "남은 이슈"에 그대로 남아있음. `docs/STATUS.md` 완료
  기록(113, 114, 115) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 캐릭터 스킬에 아이콘을 추가한다.
  → 신규 `code/scenes/skill_icon.gd`(`SkillIcon`)가 `achievement_icon.gd`/
  `reward_icon.gd`와 같은 절차적 `_draw()` 패턴으로 캐릭터의 "보유 스킬"
  (`character_profiles.gd`의 gimmick 필드 — 지금 유일한 캐릭터별 능력)을
  유형별 도형으로 그린다: 없음=빈 원, 극단(min_max_only)=빨간 다이아몬드,
  고정 방어(fixed_defense_die)=파란 방패, 폭발 스택(explosive_stack)=주황
  별, 수호 스택(guard_stack)=회색 겹방패. category는 gimmick 문자열을 그대로
  받아 재매핑 테이블 없이 1:1 대응시켰다. `character_select.gd`의 상세
  패널("보유 스킬" 줄 왼쪽)과 `deck_panel.gd`의 캐릭터 정보 섹션("캐릭터:
  이름" 줄 왼쪽) 둘 다에 붙여, 이전에 업적 아이콘(97)에서 "붙일 대상부터
  설계 필요"로 미뤄뒀던 지점을 기존 UI 두 곳(추가 화면 없이) 재사용으로
  해결했다. `dice_test.gd`에 신규 `_check_skill_icons`(PROFILES의 모든
  gimmick 값이 `SkillIcon.CATEGORIES`에 실제로 존재하는지 대조, "업적 아이콘
  검증"과 같은 패턴)를 추가해 회귀 스위트 전체 PASS.
  `qa_out/character_select_skill_icon.png`(견습 모험가, 빈 원)/
  `qa_out/character_select_skill_icon_berserker.png`(광전사, 빨간 다이아몬드)/
  `_guardian.png`(파란 방패)/`_explosive.png`(주황 별)/`_shieldbearer.png`
  (회색 겹방패)로 5종 전부 겹침 없이 다르게 표시됨을 확인, `qa_out/
  dungeon_map_skill_icon.png`(광전사, DeckPanel 캐릭터 정보 섹션)로 두 번째
  사용처도 확인. 텍스트 설명이 유일한 "스킬"이라 아이콘도 그 다섯 가지
  기믹 계열만 표현 — 이벤트로 얻는 별도 "고유 스킬"이 생기면 새 category를
  추가해야 함(다음 할 일 큐 "캐릭터 스킬 이벤트 신설"과 연결). docs/STATUS.md
  완료 기록(112) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 커스터마이징을 어떻게 하는지 모르겠다. ux가
  헷갈림. 정리하자면, 인벤토리 및 덱 구성이 우선적으로 보여야 한다. 내 덱에
  세팅된 주사위, 내가 보유한 여분 주사위, 내가 보유한 주사위 눈금이 있어야
  한다. 전투를 제외한 세팅 상황에서 아무때나 접근하고 교체할 수 있도록 한다.
  → "전투 제외 아무 때나 접근"은 이미 되고 있었으므로, 핵심이던 "인벤토리 및
  덱 구성이 먼저 한눈에 보이는 구조"만 반영했다. `CustomizePanel`을 열면
  이제 진입 화면이 곧 허브로, 공격/방어 주머니에 세팅된 다이스(면 구성까지
  읽기 전용 칩으로 두 열 표시)/여분 다이스 인벤토리/보유 눈금을 한 화면에
  같이 보여준다. 여분 다이스 칩을 누르면 바로 자리 선택으로, 눈금 칩을 누르면
  다이스 선택 → 면 선택으로 이어져 교환된다(교환 로직 자체는 변경 없음).
  구현 중 실제 렌더링 버그(내용이 반투명 배경보다 먼저 그려져 배경 밑에
  깔리던 것)를 하나 발견해 함께 고쳤다. `dice_test.gd` 회귀 스위트 전체 PASS,
  `qa_out/customize_overview_empty.png`/`customize_overview_with_pips.png`/
  `customize_overview_with_dice.png`/`combat_test_customize_overview.png`로
  던전맵·전투 화면 양쪽에서 겹침 없이 렌더링됨을 확인. 남은 것: 실제 교환
  인터랙션(칩 클릭 체인) 자체는 이번에 바꾸지 않았음 — 허브 화면만으로 충분히
  간결해졌는지는 사람 플레이 피드백 필요. docs/STATUS.md 완료 기록(111) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 상점 입장 시, 품목 카드와 던전으로 돌아가기
  버튼이 겹치지 않아야 한다.
  → STATUS.md에 "육안 확인상 지금은 겹침 없어 보이나 모든 카드 조합에서 재확인
  필요"로 남아있던 항목. 아래(바로 다음) "이미지 키우기" 작업 중 가장 콘텐츠가
  많은 조합(골드 0으로 4개 카드 전부 "골드 부족" 배지 표시 + boost_weak_face/
  uniform_faces 카드는 버튼마다 효과 미리보기까지 붙는 상태, `shop.gd`의 2행
  그리드 `row_step=235`)으로 실제 캡처해 카드 하단과 "던전으로 돌아가기"
  버튼(y=650) 사이에 겹침이 없음을 확인했다 — 이 조합이 지금 아이템 풀(4종)
  기준 카드가 가장 길어지는 경우라 사실상 "모든 카드 조합"을 커버한다(아이템
  종류가 늘어나면 재확인 필요). `qa_out/shop_card_image_preview2.png` 참고.
  docs/STATUS.md 완료 기록(110) 참고.
- [처리됨 - 2026-09-15] 2026-09-14 보상 팝업의 설명 텍스트가 너무 길어, 잘 안읽힌다.
  이미지를 키우고 해당 이미지 위주로 설명해주어 직관성을 높힌다. / 2026-09-14 상점
  입장도 보상과 동일하게 정보를 인지하기 어렵다. 이미지를 키우고 해당 이미지 위주로
  설명해주어 직관성을 높힌다.
  → 전투 승리 보상/상점/특수 이벤트 3개 화면이 공유하는 `code/scenes/
  item_card_style.gd`(`ItemCardStyle.build_card()`)를 고쳐 두 요청을 한 번에
  반영했다(세 화면 다 같은 카드를 쓰므로). (1) 결과 다이스 면 미리보기 칩
  (`PREVIEW_CHIP_SIZE`)을 16→30px로 키워 이미지를 카드의 시각적 중심으로 만들고,
  (2) 카드 안 배치 순서를 "제목 → 설명 → 이미지"에서 "제목 → 이미지 → 설명"으로
  바꿔 이미지를 먼저 보게 했다(add_die/upgrade_die처럼 결과가 확정적인 아이템만
  이 미리보기가 있음 — boost_weak_face/uniform_faces는 화면마다 버튼 옆에 따로
  붙이는 `build_effect_preview()`를 그대로 재사용, 이쪽도 같은 칩 크기라 함께
  커짐), (3) 설명 텍스트는 글자 크기(13→11)와 최소 높이(40→22)를 줄여 이미지에
  종속되는 보조 정보로 격하시켰다(설명 문구 자체를 다시 쓰거나 요약하진 않음 —
  카드 레이아웃/배치만 바꿈).
  구현 중 두 가지를 추가로 발견·수정했다: (a) 이 변경으로 다이스 개수가 많은
  아이템(예: D20 추가, 미리보기 칩 20개)이 카드 안에서 겹치는지 확인하려고 기존
  QA 훅 `event.gd`의 `_debug_force_offer_d20()`을 썼는데, 이 훅이 "D20은
  EventItemPool.ITEMS의 마지막 항목"이라고 가정하고 있었던 게 이후 "눈금 주머니
  획득"(gain_pips) 아이템이 더 뒤에 추가되면서 깨져 있었다 — 실제로는 D20이 아니라
  gain_pips 카드가 뜨고 있었다(화면 크래시나 스크린샷 실패로는 안 드러나는 종류의
  버그). `_find_item_by_sides(sides)` 헬퍼로 kind+sides를 직접 찾도록 고쳐
  `_debug_force_offer_d20()`/`_debug_verify_d20_pickup()` 둘 다 다시 정확히 D20을
  가리키게 했다. (b) 고친 훅으로 실제 D20 카드(칩 20개, 3줄로 줄바꿈)를 캡처해
  카드 테두리/옆 카드/하단 버튼과 안 겹치는 것을 확인 — 상점의 2행 그리드(가장
  빡빡한 레이아웃, `row_step=235`)도 함께 재확인해 겹침 없음.
  `dice_test.gd` 회귀 스위트 전체 PASS(순수 UI 변경). `qa_out/
  shop_card_image_preview2.png`(상점 4종 카드, 이미지 확대+텍스트 축소)/
  `qa_out/event_card_image_preview_d20_fixed.png`(고친 훅으로 실제 D20 20칩
  카드가 겹침 없이 표시, 상점보다 여유 있는 이벤트 레이아웃까지 확인)/`qa_out/
  combat_reward_card_image_preview.png`(전투 승리 보상 화면도 함께 확인)로
  검증. 남은 것: 설명 문구 자체를 더 짧게 다시 쓰는 것(문구 내용 변경)과, 다이스
  면 개수가 많은 아이템(D12/D20)의 미리보기가 카드 폭 제약상 6-8칸마다 줄바꿈돼
  칸당 크기는 커졌어도 여전히 전투 화면의 44px 결과 칩만큼 크진 않은 점은 미해결
  — 실제로 더 커야/짧아야 하는지는 사람 플레이 피드백 필요. docs/STATUS.md 완료
  기록(110) 참고.
- [처리됨 - 2026-09-15] 2026-09-14 캐릭터 선택 화면은 외형과 이름들만 간략하게
  나오고, 패널 선택시 오른쪽에 패널을 띄워, 상세 정보를 제공한다. 내용은 캐릭터
  관련 상세 정보 및 초기 제공 주사위, 보유 스킬등이다.
  → `code/scenes/character_select.gd`/`.tscn`을 "카드 하나에 초상+이름+설명+
  선택 버튼을 전부 담아 화면을 5등분"하던 방식에서, "왼쪽에 초상+이름+선택
  버튼만 있는 좁은 목록(세로 5줄) + 오른쪽에 선택된 캐릭터의 상세 정보 고정
  패널" 2단 레이아웃으로 개편. 오른쪽 패널은 이름/설명(`concept` 필드, 신규
  추가)/시작 다이스(`attack_count`/`defense_count`에서 직접 조립: "공격 D4
  x{n} / 방어 D4 x{n}")/보유 스킬(`CharacterProfiles.gimmick_label()`, 신규
  추가 — 예: "극단 (Min/Max 전용, 중간값 없음)") 4개 줄을 카드 선택 시마다
  즉시 갱신. 기존 `desc` 필드(전체 설명 문장, `deck_panel.gd`의 캐릭터 정보
  섹션이 그대로 재사용 중)는 건드리지 않고 `concept`(시작 다이스 문구를 뺀
  순수 컨셉 설명)을 새 필드로 추가해 중복 표시를 피함 — 기존 소비처는 영향
  없음. `qa_out/character_select_detail_panel.png`(기본 선택)/
  `qa_out/character_select_detail_berserker.png`(다른 캐릭터 선택 시 패널
  갱신)/`qa_out/character_select_start_flow.png`(선택→던전 시작까지 실제
  흐름 정상)로 확인. 이 2단 레이아웃이 실제로 "간결하다"고 느껴지는지는
  최종적으로 사람 플레이 피드백 영역. docs/STATUS.md 완료 기록(108) 참고.
*(이보다 오래된 "처리됨" 항목은 `docs/INBOX_ARCHIVE.md`에 보관돼 있음 — 이 파일에는
최근 12개만 유지해 매 이터레이션 읽기 비용을 줄임. 이번 이터레이션(138)에서
"키보드로도 조작이 되도록 키매핑 및 단축키를 추가한다" 항목을 그리로
옮겼다.)*
