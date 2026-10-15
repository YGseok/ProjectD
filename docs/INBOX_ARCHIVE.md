# INBOX_ARCHIVE.md — INBOX.md "처리됨" 오래된 기록 아카이브

> INBOX.md가 매 이터레이션 읽는 파일이라 크기를 관리하기 위해, 오래된 "처리됨"
> 항목을 여기로 옮겼다 (2026-09-09 정리). **이 파일은 매 이터레이션 읽지 않는다** —
> 특정 결정의 예전 경위가 궁금할 때만 사람이나 AI가 필요 시 열어본다. 내용은 옮겨
> 적었을 뿐 삭제/요약하지 않았다.

---

- [처리됨 - 2026-09-29] 2026-09-29 (기획자 결정) `docs/STATUS.md` "알려진
  이슈"의 "주술사(구 방패병)의 시작 스킬 슬롯 1 '정예'(`start_lean`)가
  이론상 절대 발동하지 않는 죽은 선택지" — 제시된 3가지 해결안 중 (a) 임계값
  완화로 결정: "정예"의 조건을 "공격+방어 다이스 합계 <= 6"에서 "<= 7"로
  한 단계 늘린다.

  → **완료됨.** `code/scenes/combat_test.gd`의 `_do_exchange()` 안 "정예"
  (`start_lean`) 분기 2곳(공격턴/방어턴)의 `<= 6` 비교를 `<= 7`로 바꾸고
  로그 문구("합계 6개 이하"→"합계 7개 이하")도 갱신했다.
  `code/systems/skill_pool.gd`의 `start_lean` 항목 `description`도 "6개
  이하"→"7개 이하"로 갱신. `code/scenes/dice_test.gd`의 (d) 회귀 테스트를
  새 임계값에 맞춰 다시 썼다 — 견습 모험가 기본(합계 6, 발동)에 이어
  다이스 1개 추가(합계 7, 여전히 발동 유지)/2개 추가(합계 8, 발동 꺼짐)
  두 단계로 나눠 검증하도록 확장(기존엔 1개 추가만으로 바로 꺼지는지
  검증했는데 이제 그 지점에서는 켜져 있어야 하므로 검증 지점 자체를
  다시 설계함). `docs/DESIGN.md`의 "시작 스킬 선택([미니 기획 E])" 절
  "정예" 설명을 7개 이하로 갱신하고, 해결된 "알려진 이슈" 단락 자체를
  삭제했다. `bash scripts/qa_shot.sh dice_test` 전체 PASS(신규 (d) 검증
  포함), `scripts/qa_shot.sh combat_test`로 전투 화면 크래시/겹침 없음도
  확인(순수 조건 분기 변경이라 레이아웃 영향 없음). `docs/STATUS.md`의
  해당 "알려진 이슈" 항목도 삭제했다. docs/STATUS.md 완료 기록(최신 항목)
  참고.

- [처리됨 - 2026-09-24] 2026-09-24 방패병이 수호자랑 겹치는데 빼고, 3개의
  캐릭터 아이디어를 더 내줄래? 이어서 스킬 작업까지 이터레이션으로 해주고,
  외형 프롬프트를 추가해줘. 컨셉이랑 어울리면 좋겠는데, 추가하면 좋겠는
  캐릭터는 음침 거유 캐릭터랑, 섹시하고 도발적인 캐릭터, 나머지 하나는
  적당히 비어있는 포지션에 재미요소 맞춰서 해봐.

  → **전체 완료(2026-09-24, A/B/C/D 1~7번).** A(방패병→주술사 리스킨)/
  B(매혹사)/C(곡예사)는 (140)/(141)/(142), D-1~2(업적)/D-3(시작 스킬
  배정)/D-4(고유 스킬)는 (143)/(144)/(145), **마지막 D-5~7은 (146)에서
  완료** — D-5(`scripts/qa_shot.sh character_select`로 `qa_out/
  character_select.png`/`character_select_juggler.png` 재확인, 7종
  목록·상세 패널 겹침/잘림 없음), D-6(`docs/DESIGN.md`의 "플레이어블
  캐릭터" 표를 5종→7종으로 갱신, 매혹사/곡예사 행 추가), D-7
  (`character_portrait_placeholder.gd`가 `set_palette()`로 색만 받는
  범용 구조라 코드 수정 없이 매혹사/곡예사 초상을 자동으로 얻음을 확인).
  이걸로 [대형 기획 4] 완료 기준(A~D 전부)을 전부 충족해 이 항목을
  "처리됨"으로 옮긴다. docs/STATUS.md 완료 기록(146) 참고.
  D-4(2026-09-24, (145)): `skill_pool.gd`의 `UNIQUE_SKILLS`에 매혹사
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
  **추가(2026-09-28, (147))**: 미뤄뒀던 6번도 마저 완료했다 — `DeckPanel`에
  "보유 스킬" 섹션을 추가해 `RunState.skill_flags`를 이름으로 풀어 나열한다
  (`SkillPool.find_skill()` 신규, 네 스킬 상수 전체에서 id로 이름 조회).
  docs/STATUS.md 완료 기록(147) 참고.

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
  이번에도 손대지 않음 — 남은 유일한 미착수 미니 기획으로 당시 "남은 이슈"에
  그대로 있었음. `docs/STATUS.md` 완료 기록(116, 117, 118) 참고.

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

- [처리됨 - 2026-09-15] 2026-09-14 키보드로도 조작이 되도록 키매핑 및 단축키를
  추가한다. / 2026-09-14 단축키가 필요한 버튼이면, 어떤 단축키를 눌러야하는지 버튼에도
  표시한다.
  → 신규 `code/scenes/keyboard_shortcuts.gd`(`KeyboardShortcuts`, 씬 상태 없는 순수
  유틸리티)로 "화면에 보이는 선택지 버튼 목록에 숫자 1~9 키를 순서대로 배정 +
  버튼 텍스트 맨 앞에 "[n] " 접두어로 표시" 패턴을 만들고, 던전 맵/스토리 이벤트/
  특수 이벤트/캐릭터 선택/상점/전투(combat_test.gd, 버튼 구성이 시간에 따라
  바뀌어 `_rebuild_shortcuts()`로 재배정)/업적 패널(achievement_panel.gd, "닫기"
  버튼 하나) 7개 화면 전부에 적용해 **7/7화면으로 완료**됐다(2026-09-15
  (102)~(107), 자세한 구현/검증 내용은 각 화면별로 `docs/STATUS.md` 완료
  기록의 (102)/(103)/(104)/(105)/(106)/(107) 참고 — 특히 (105)에서 "씬을 바꾸는
  버튼에 단축키를 배정하면 크래시하는" 실제 버그를 발견해 5개 화면 모두 수정한
  경위가 별도 항목으로 아래에 있음). 마지막 (107)의 업적 패널은 스스로 씬을
  바꾸지 않는 패널이라 그 크래시 위험 자체가 없었고, 실제 숫자 키 "1" 입력으로
  패널이 크래시 없이 닫히는 것까지 `qa_out/character_select_achv_key_close.png`로
  확인했다. `_unhandled_input()`이 숫자 키를 받으면 그 순서의 버튼이 실제로
  클릭됐을 때와 동일한 `pressed` 시그널을 발생시킨다(클릭과 다른 경로를 타지
  않음). 커스터마이징/업적 패널이 열려있을 때는 뒤에 가려진 버튼이 함께 눌리지
  않도록 숫자 키를 무시한다. `dice_test.gd`에 순수 함수 검증(`apply_hints`
  재적용 시 접두어 누적 방지, `digit_index`의 눌림/뗌/비숫자 키 판별, `try_press`의
  비활성·범위 밖 버튼 무시)을 추가해 회귀 스위트 전체 PASS. **"전체 조작을
  키보드로도, 단축키 있는 버튼엔 표시도"라는 원 요청 전체가 이제 완료됨.**

- [처리됨 - 2026-09-15] (INBOX.md 요청이 아니라, 키보드 단축키 항목을 이어서 상점
  화면에 적용하다가 QA로 직접 재현·발견한 크래시 버그) 키보드 단축키가 씬을 바꾸는
  버튼(방 입장/상점 나가기/스토리 이벤트 "계속"/특수 이벤트 아이템 획득/던전
  시작)에 배정됐을 때, 숫자 키를 눌러 그 버튼을 누르면 `_unhandled_input()`의
  `KeyboardShortcuts.try_press(...)` 호출이 버튼의 `pressed` 콜백을 동기 실행해
  `change_scene_to_file()`이 그 자리에서 씬을 바꾸고, 그 직후 같은 함수의
  `get_viewport()`가 이미 트리에서 빠져나간 노드에서 호출되어 null을 반환 →
  `null.set_input_as_handled()` 호출로 스크립트 크래시가 나는 버그.
  → shop.gd에 신규 QA 훅 `_debug_press_shortcut_leave()`(8번 키로 "던전으로
  돌아가기" 버튼을 실제로 눌러보는 검증)를 추가해 실행하다가 실제로 재현·발견함
  (`SCRIPT ERROR: Cannot call method 'set_input_as_handled' on a null value.`).
  원인은 "버튼을 누르기 *전에* 뷰포트를 미리 받아두지 않고, 누른 *뒤에* 새로
  `get_viewport()`를 호출한 것" — 고치는 방법은 `get_viewport()` 호출을
  `try_press()` 앞으로 옮겨 노드가 아직 트리 안에 있을 때 참조를 받아두고,
  버튼을 누른 뒤에는 그 미리 받아둔 참조로 `set_input_as_handled()`를 부르는
  것(Viewport 객체 자체는 씬 전환과 무관하게 계속 살아있으므로 미리 받아둔
  참조는 씬이 바뀐 뒤에도 유효함). 이 패턴이 `_unhandled_input()`을 쓰는 5개
  화면(dungeon_map/shop/event/story_event/character_select) 전부에 동일하게
  복사돼 있었으므로(이전 이터레이션 102~104에서 커스터마이징/업적 패널처럼
  "씬을 안 바꾸는" 버튼만 실제 키 입력으로 검증했고, 씬을 바꾸는 버튼은
  이번이 처음으로 실제 키 입력 경로로 검증된 것), 5개 파일 모두 같은 방식으로
  수정했다. 던전 맵에도 신규 QA 훅 `_debug_press_shortcut_2()`(2번째 방으로
  강제 이동 후 2번 키로 상점 입장을 눌러보는 검증)를 추가해 방 입장 버튼
  경로에서도 크래시가 재현되지 않음을 `qa_out/dungeon_map_kb_key2.png`(정상적으로
  상점 화면으로 전환됨)로 확인. `dice_test.gd` 회귀 스위트 전체 PASS(순수 입력
  처리 순서 변경이라 로직 영향 없음). **이 버그는 실제 플레이에서도 재현
  가능했을 것으로 추정** — QA 훅이 아니라 사람이 직접 숫자 키로 상점을 나가거나
  방에 입장했다면 언제든 이 크래시를 겪었을 것(이전 이터레이션들은 씬 전환
  버튼을 실제 키 입력으로 검증한 적이 없어 발견되지 않았음). docs/STATUS.md
  완료 기록(105) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 캐릭터 정보 및 보유 스킬을 상시 볼 수 있도록 한다.
  → 새 버튼/패널을 따로 만들지 않고, 이미 "전투 제외 화면(던전맵/상점/특수 이벤트/
  스토리 이벤트)에서는 상시 표시, 전투 중에는 토글 한 번으로 열람"이라는 정확히
  요청된 동작을 하고 있던 `DeckPanel`(`code/scenes/deck_panel.gd`)을 재사용 —
  `_add_character_section()`을 신설해 덱 정보 위에 "캐릭터: <이름>" + 설명(기믹
  포함) 섹션을 추가했다. `CharacterProfiles.get_profile(RunState.character_id)`의
  `desc` 필드(캐릭터 선택 화면과 동일 텍스트)를 그대로 재사용해 두 화면 설명이
  어긋나지 않게 함. "보유 스킬"은 지금 `character_profiles.gd`의 기믹 설명 텍스트가
  유일한 캐릭터별 능력이라 그걸 그대로 보여준다 — 이벤트로 얻는 별도 "고유 스킬"
  시스템 자체는 여전히 없음(DESIGN.md에 이미 명시됨, "캐릭터 스킬 이벤트 신설"
  항목과 연결). 새 레이아웃 공간을 확보할 필요가 없어 기존 DeckPanel 사용처
  5개 화면(dungeon_map/shop/event/story_event/combat_test) 전부에 자동으로
  반영됨. `_signature()`에 `character_id`를 포함시켜 캐릭터가 바뀌면 패널도 다시
  그려지게 함. 이 세션 환경의 QA 스크린샷 폭 잘림(1280→1028px) 때문에 패널이 항상
  화면 오른쪽 끝(x>=980)에서 잘려 보이는 문제가 있어, `dungeon_map.gd`/
  `combat_test.gd`에 각각 `_debug_move_deck_panel_left()`류 QA 전용 훅을 추가해
  패널을 왼쪽으로 옮긴 뒤 캡처 — `qa_out/dungeon_map_char_info_left.png`(견습
  모험가, 정상)/`qa_out/dungeon_map_char_info_berserker.png`(광전사, 5줄 설명
  텍스트로 가장 긺 — 그래도 패널 안에 겹침 없이 다 들어감)/
  `qa_out/combat_test_charinfo_left.png`(전투 화면 토글 패널)로 확인. `dice_test.gd`
  회귀 스위트 전체 PASS(순수 UI 추가라 로직 영향 없음). docs/STATUS.md 완료 기록
  (101) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 현재 게임에 적용된 캐릭터를 확인해볼 수 있도록,
  캐릭터 관련 내용을 디자인md에 기술한다. 시작 스킬, 시작 주사위, 고유 스킬(이벤트에
  따라 추가), 필요에 따라 각종 정보들이 있을 것 같다. (기획자인 나에게 전달하는 용도)
  → `docs/DESIGN.md`에 "현재 구현 콘텐츠 (기획자 참고용)" 섹션을 신설, 그 아래
  "플레이어블 캐릭터 (5종)" 표를 추가해 `code/systems/character_profiles.gd`의
  `PROFILES`를 코드를 열지 않고도 볼 수 있게 옮겨 적었다(id/이름/컨셉/시작 다이스
  개수/시작 기믹). "시작 스킬"/"고유 스킬(이벤트로 획득)"은 실제로 아직 존재하지
  않는 시스템이라(캐릭터 차별화가 "시작 다이스 개수 배분"과 "시작 시 1회 적용되는
  다이스 기믹" 두 가지뿐) 표 아래에 "아직 없음"이라고 명시하고, 관련 미착수 항목
  ("캐릭터 스킬 이벤트 신설")을 가리키도록 적었다 — 없는 것을 있는 것처럼 꾸며
  적지 않음. 순수 문서화 작업이라 코드/씬 변경 없음. docs/STATUS.md 완료 기록
  (99) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 현재 게임에 적용된 이벤트를 확인해볼 수 있도록,
  특수 이벤트 관련 내용을 디자인md에 기술한다. 어떤 대상에게 나오는 이벤트인지,
  출력되는 내러티브(문구)는 어떤 것인지, 보상은 무엇인지, 필요에 따라 각종 정보들이
  있을 것 같다. (기획자인 나에게 전달하는 용도)
  → 같은 신설 섹션에 "던전 방 이벤트 콘텐츠" 하위로 "특수 이벤트"(`event.gd` +
  `event_item_pool.gd`, 아이템 5종 표 — 이름/효과/등급)와 "스토리 이벤트"
  (`story_event.gd` + `story_event_pool.gd`, 시나리오 8종 표 — 제목/내러티브/
  선택지 A·B와 각각의 확률·수치)를 둘 다 정리했다("특수 이벤트"라는 단어가
  실제 코드에서는 "다이스 아이템을 주는 방"(내러티브 없음)과 "텍스트
  선택지"(내러티브 있음) 두 개로 나뉘어 있어 요청한 정보(대상/내러티브/보상)가
  이 두 방 종류에 걸쳐 있음 — 둘 다 기술해 누락 없게 함). 특수 이벤트 쪽은
  실제로 "내러티브 문구가 아직 없다"는 현재 한계를 그대로 적었다(사실과 다르게
  꾸미지 않음, 관련 미착수 항목 "특수 이벤트 개편"을 가리킴). 순수 문서화
  작업이라 코드/씬 변경 없음. docs/STATUS.md 완료 기록(99) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 캐릭터별 현재 개성 및 스타일에 맞추어 시작
  주사위를 다르게 한다.
  → `code/systems/character_profiles.gd`의 `PROFILES` 5종 각각에
  `attack_count`/`defense_count` 필드를 추가해 시작 공격/방어 다이스 "개수"
  배분을 캐릭터 기믹 방향에 맞게 차별화(면 개수는 5종 전부 D4로 동일 유지):
  견습 모험가(기본값) 3/3, 광전사(극단형·공격 몰빵) 4/2, 수호자(안정형·방어
  몰빵) 2/4, 폭발병(공격 스택을 더 자주 쌓게) 4/3, 방패병(방어 스택을 더
  자주 쌓게) 3/4. `code/systems/run_state.gd`의 `reset_run()`이
  `DiceBag.new(4, 3)` 하드코딩 대신 이 필드로 주머니 크기를 정하도록 수정.
  캐릭터 카드 desc 텍스트에도 "시작 다이스: 공격 D4xN / 방어 D4xN" 문구를
  덧붙여 캐릭터 선택 화면에서 바로 차이를 알 수 있게 함. `dice_test.gd`에
  5종 전부의 시작 다이스 개수 검증을 신규 추가해 회귀 스위트 전체 PASS.
  `docs/DESIGN.md`의 "초기 다이스 구성" 절도 캐릭터별 배분표로 갱신.
  `qa_out/character_select_dice_desc.png`(카드 desc에 시작 다이스 문구가
  겹침 없이 표시)/`qa_out/dungeon_map_berserker_deck.png`(광전사로 실제 런
  시작 → 덱 패널에 공격 4줄/방어 2줄)로 확인. 배분 수치가 실제로 캐릭터
  개성 체감에 도움이 되는지/밸런스가 한쪽으로 쏠리진 않았는지는 사람 플레이
  피드백 필요. docs/STATUS.md 완료 기록(98) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 업적에 유형별 아이콘을 추가한다. 예를 들어
  골드 보유 업적이면 금화가 쌓인 아이콘. 다이스 관련이면 다이스 모양 아이콘.
  → 신규 `code/scenes/achievement_icon.gd`(`AchievementIcon`)가 category 9종
  (start/milestone/dice/gold/combat/pip/bag/shop/material)을 `reward_icon.gd`와
  같은 절차적 `_draw()` 패턴으로 그린다. `code/systems/achievement_manager.gd`의
  `DEFINITIONS` 12종 각각에 유형에 맞는 "icon" 필드를 배정(골드 관련 업적=gold,
  다이스 관련 업적=dice 등)하고, `achievement_panel.gd`의 `_make_row()`가 제목
  왼쪽에 36x36 아이콘을 붙인다(잠긴 업적은 아이콘도 반투명하게 흐림).
  `dice_test.gd`에 신규 검증 `_check_achievement_icons` 추가해 회귀 스위트
  전체 PASS. `qa_out/achievement_panel_icons.png`/`qa_out/
  achievement_panel_icons_bottom.png`(스크롤 상/하단)로 9종 아이콘 전부
  겹침 없이 표시됨을 확인. 같은 "아이콘 추가 2건" 중 캐릭터 스킬 아이콘은
  여전히 미착수(스킬 콘텐츠가 텍스트뿐이라 아이콘을 붙일 대상부터 설계
  필요) — "남은 이슈"에 별도 줄로 남아있음. docs/STATUS.md 완료 기록(97) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 보상 팝업의 밸류에 따라 보상 등급을 나눈다.
  보상 등급은 잠정적으로 S A B C. 4단계로 구분하여 이름붙인다. / 보상 카드에
  보상 등급을 표시하고, 보상 등급에 따라 녹색<파란색<보라색<노란색 색상을
  테두리 및 타이틀 텍스트에 적용한다.
  → `code/systems/dice_item_pool.gd`(4종)/`code/systems/event_item_pool.gd`
  (5종)의 아이템 딕셔너리에 "grade"(S/A/B/C) 필드를 추가(면 개수/효과 범위
  기준 잠정 배정 — 다이스 추가 D4=C/약한 면 강화=C/눈금 획득=C, 다이스 승급
  D6=B/모든 면 통일=B/D8 추가=B, D12 추가=A/D10 승급=A, D20 추가=S).
  `code/scenes/item_card_style.gd`에 `GRADE_COLORS`(C=초록/B=파랑/A=보라/
  S=노랑)와 `grade_color()`를 추가하고, `build_card()`가 카드 테두리·타이틀
  색을 등급색으로 칠하고 타이틀 옆에 등급 배지를 붙이도록 수정. 골드 부족
  카드도 배지만은 원래 등급색을 유지. `dice_test.gd`에 신규 검증
  `_check_item_grades` 추가해 회귀 스위트 전체 PASS. `qa_out/shop_grades.png`/
  `qa_out/event_grades.png`/`qa_out/combat_reward_grades.png`로 3개 화면 확인.
  이 항목의 "이미지를 키우고 이미지 위주로 설명" 부분은 별도 줄로 여전히
  "남은 이슈"에 남아있음(카드 레이아웃을 다시 짜야 하는 더 큰 작업이라 분리
  처리). docs/STATUS.md 완료 기록(96) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 전투 시, 몬스터 hp바 하단에 해당 몬스터에 대한
  스킬/전투 정보를 알려준다. 이는 개발용으로 추후 제거되거나 정보를 간소화시킬 수 있다.
  → `combat_test.gd`에 순수 함수 `_monster_debug_info_text(config)`를 추가해, 몬스터
  config(공격/방어 다이스 개수·면 개수, 기믹 종류/값, 보스 여부)를 사람이 읽을 수 있는
  문구로 변환한다(예: "[QA] 공격 2D4 · 방어 1D4" + 기믹이 있으면 "기믹: 분노 스택
  (공격 최댓값 3회 -> 다음 공격 1D20)" 등 + 보스면 "[보스] 공격+2 / 방어+1 / HP x2
  강화됨"). `combat_test.tscn`에 신규 `MonsterDebugInfoLabel`을 몬스터 HP 막대 바로
  아래에 배치하고(다이스 3D 뷰포트보다 트리상 나중에 두어 다이스 위에 항상 그려지게
  함), `_ready()`에서 텍스트를 1회 채운다. "개발용, 나중에 제거/간소화 가능"이라는
  요청대로 함수 하나 + 라벨 노드 하나로 최소한으로 구현 — 나중에 필요 없어지면
  `_ready()`의 호출 한 줄과 라벨 노드만 지우면 된다. `dice_test.gd` 신규 검증
  (`_check_monster_debug_info_text`, 기믹 없음/분노 스택/고정값/극단+보스 4개 방
  케이스) 추가해 회귀 스위트 전체 PASS. `qa_out/combat_test_monster_debug_info2.png`
  (고블린, 2줄)/`qa_out/combat_test_monster_debug_boss2.png`(다크 나이트, 3줄, 보스
  강화 줄까지 겹침 없이 표시)로 확인. docs/STATUS.md 완료 기록(95) 참고.
- [처리됨 - 2026-09-15] 2026-09-14 상점 품목에서 골드 부족이라는 버튼이 너무 많이
  나온다. 골드 부족 버튼 대신, 선택 불가능한 품목은 패널 색상을 다르게 하여,
  비활성된 선택지임을 알려주는게 좋을 듯 하다.
  → `code/scenes/item_card_style.gd`의 `build_card()`에 `unaffordable: bool` 매개변수를
  추가. true면 카드 배경/테두리를 어둡게(`CARD_BG_UNAFFORDABLE`/
  `CARD_BORDER_UNAFFORDABLE`) 칠하고, 가격 라벨과 같은 줄에 빨간 "골드 부족" 배지
  하나만 붙인다(버튼마다 "골드 부족" 텍스트를 반복하던 것 대신 카드당 한 번).
  `code/scenes/shop.gd`가 골드 비교 결과(`afford`)를 이 매개변수로 넘기고, 버튼
  텍스트는 이제 항상 정상 동작 문구("공격 주머니에 구매" 등)만 쓰고 골드 부족 시엔
  `disabled=true`로만 비활성화한다(주머니가 가득 차서 애초에 적용 불가능한 경우의
  `unavailable_reason` 문구는 그대로 유지 — 이건 "골드 부족"과 다른 사유라 남겨둠).
  구현 중 "골드 부족" 배지를 별도 줄로 추가하면 카드 자연 높이가 늘어나 2행
  그리드에서 아래 행 카드 상단과 겹치는 실제 회귀를 스크린샷으로 발견해, 가격
  라벨과 같은 HBoxContainer 줄에 배지를 붙이는 방식으로 고쳐 높이 증가를 없앴다.
  QA 검증용 0-인자 디버그 훅 `_debug_show_partial_gold()`(골드 12로 맞춰 4개 카드 중
  1개만 구매 가능하게 만듦) 신규 추가. `qa_out/shop_after_nogold2.png`(골드 0, 카드
  4개 모두 어둡게+배지, 겹침 없음)/`qa_out/shop_partial_gold.png`(골드 12, "약한 면
  강화" 카드만 밝은 테두리+정상 버튼, 나머지 3개는 어둡게+배지)로 확인.
  `dice_test.gd` 회귀 스위트 전체 PASS(순수 UI 변경이라 영향 없음). docs/STATUS.md
  완료 기록(94) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 골드가 없는데 골드 소모하는 선택지가 나오면,
  해당 선택지를 비활성화 시켜 반대쪽 선택지만 선택하도록 유도한다.
  → 상점 "구매" 버튼은 이전부터 이미 골드가 부족하면 `disabled=true`로 눌리지
  않았음(로직 자체는 기존에 있었음) — 다만 버튼 텍스트가 전부 "골드 부족"이라
  비활성 상태가 잘 안 드러났던 것을 위 항목에서 카드 색/배지로 시각적으로
  뚜렷하게 보강함. 스토리 이벤트(2택 선택지)는 애초에 "골드가 있어야 고를 수
  있는 선택지"라는 개념 자체가 없음(둘 다 항상 선택 가능, 결과로 골드가
  증감할 뿐이고 손실은 0 밑으로 안 내려가게 클램프됨) — 그래서 이쪽은 적용
  대상이 아님. docs/STATUS.md 완료 기록(94) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 상점은 현재 5개의 방 기준, 2번째 4번째 방에만
  추가한다.
  → `dungeon_map.gd`의 `_room_options_for_index(idx)`에서 상점 노출 판정을
  `rng.randf() < SHOP_CHANCE`(60% 확률 노출)에서 `SHOP_FIXED_ROOM_INDICES.has(idx)`
  (=[1, 3], 0부터 세므로 "2번째/4번째 방")로 바꿔 고정 노출로 변경. event/story는
  기존 확률 노출 그대로 유지. 라운드 마지막 방(5번째, idx=4)은 기존처럼 보스 전투만
  가능(상점 노출 대상 아님, 큐 16 라운드 진행 버그 수정과 무관하게 그대로 유지).
  신규 QA 훅 `_debug_show_room2()`/`_debug_show_room3()`(0-인자 래퍼)로 idx=1(상점
  있어야 함)/idx=2(상점 없어야 함)를 각각 직접 만들어
  `qa_out/dungeon_map_room2_shop.png`(상점 버튼 노출, "2번째 방" 표기)/
  `qa_out/dungeon_map_room3_noshop.png`(상점 버튼 없음)로 확인, 기본 진입(1번째 방)도
  `qa_out/dungeon_map_room1_shopfix.png`로 상점 없음을 재확인 — MapStrip 미리보기의
  방 타입 칩도 같은 함수를 공유하므로 2/4번째 방에만 "상점" 칩이 자동으로 반영됨.
  `dice_test.gd` 회귀 스위트 전체 PASS(결정성 검증은 값 자체가 아니라 "같은 idx는
  항상 같은 결과"만 확인하는 구조라 고정 노출로 바뀌어도 그대로 통과). 상점 위치를
  2/4번째로 고정한 것이 실제로 밸런스상 적당한지(너무 이르거나 늦은 건 아닌지)는
  여전히 사람 플레이 피드백 영역. docs/STATUS.md 완료 기록(93) 참고.
- [처리됨 - 2026-09-15] 2026-09-14 던전 맵에서 각 보상 아이콘이 무엇을 의미하는지
  아이콘 텍스트 또는 범례가 필요할 것 같다.
  → `dungeon_map.gd`에 `_setup_reward_legend()`를 추가해, 골드 라벨 오른쪽 빈 공간에
  RewardIcon(골드/눈금/다이스 3종) + 텍스트 라벨을 한 줄로 고정 표시하는 범례를 붙였다.
  방마다 바뀌는 게 아니라 "아이콘 자체의 뜻"이라 `_ready()`에서 한 번만 만들고 이후
  갱신 불필요. `qa_out/dungeon_map.png`로 골드 라벨/MapStrip과 겹치지 않고 표시됨을
  확인. docs/STATUS.md 완료 기록(92) 참고.

- [처리됨 - 2026-09-15] 2026-09-14 상점 입장 버튼 하단에 보유 골드량을 표시해준다.
  해당 선택지가 의미가 없음을 보여줘야 한다.
  → `dungeon_map.gd`에 `_shop_gold_label`을 추가해 "상점 입장" 버튼 바로 아래에 보유
  골드를 상시 표시한다. 상점 최저가 품목(`shop.gd`의 `boost_weak_face`=10골드,
  `MIN_SHOP_ITEM_COST`로 복제)조차 못 살 만큼 골드가 부족하면 "(구매 가능한 품목
  없음)" 문구 + 붉은색으로 그 선택지가 지금 의미 없음을 미리 알린다. 상점 버튼은
  방마다 노출 여부/순서가 바뀌어 위치가 고정이 아니므로, `_layout_visible_buttons()`
  에서 다른 버튼들과 함께 매번 위치를 다시 계산하고, 상점 버튼이 있을 때만 다음
  버튼과의 간격을 22px 늘려(`SHOP_GOLD_LABEL_GAP`) 라벨이 겹치지 않게 했다(버튼
  5개 + 라벨까지 있는 최악의 경우도 계산상 화면 높이 720 안에 들어옴, 확인 완료).
  `qa_out/dungeon_map.png`(0골드, 경고 문구)/`qa_out/dungeon_map_room2.png`(4개
  버튼 + 상점 라벨, 겹침 없음)/`qa_out/dungeon_map_boss_room.png`(상점이 없는 방에서
  라벨도 함께 숨겨짐)로 확인. `dice_test.gd` 회귀 스위트 영향 없음(순수 UI, 로직
  변경 없음). docs/STATUS.md 완료 기록(92) 참고.

- [처리됨 - 2026-09-14] 2026-09-14 던전 맵 1/3 라운드, 방 0/5 상태에서
  커스터마이징 팝업을 띄웠는데, 전투 방 입장 보상 아이콘이 팝업 창을 뚫고
  나온다.
  → 실제 버그로 확인, 수정 완료. `dungeon_map.gd`의 `_setup_reward_icons()`가
  방 선택 버튼 옆 보상 아이콘 줄을 `add_child()`로 런타임에 추가하는데, 이
  호출이 `dungeon_map.tscn`에서 씬 파일상 마지막 자식인 `CustomizePanel`보다
  늦게(= 트리상 뒤에) 실행되어, 그 아이콘들이 팝업보다 나중에 그려져(= 위에
  보여) 팝업의 90% 불투명 배경을 뚫고 나온 것처럼 보였다.
  `code/scenes/customize_panel.gd`의 `open()`에 `move_to_front()`를 추가해,
  패널이 열릴 때마다 스스로를 부모의 마지막 자식으로 옮겨(= 항상 최상단에
  그려지도록) 고침. 이 스크립트는 `dungeon_map`/`shop`/`event`/`story_event`/
  `combat_test` 5개 화면에서 공용으로 쓰여 다섯 곳 모두에 동일하게 적용됨.
  `git stash`로 수정 전/후 상태를 같은 조건(`scripts/qa_shot.sh dungeon_map 30
  <out> _debug_open_customize`)에서 각각 스크린샷으로 찍어 대조 — 수정 전에는
  "전투 방 입장" 버튼 줄의 금화/다이스/눈금 아이콘 3개가 팝업 위에 원래
  밝기 그대로 떠 있었고, 수정 후에는 다른 UI 요소들처럼 팝업 배경에 가려
  희미하게만 비침을 확인했다. docs/STATUS.md 완료 기록(91) 참고.

- [처리됨 - 2026-09-14] 2026-09-14 방 다섯개 클리어 하고, 새 런으로 돌게 되는데,
  라운드가 진행되어야 한다.
  → 실제 버그로 확인, 수정 완료. 라운드 마지막 방(보스 방, `rooms_cleared ==
  TOTAL_ROOMS - 1`)에도 다른 방과 똑같이 상점/특수 이벤트/스토리 이벤트가
  확률 노출되고 있었는데, 이 세 씬(`shop.gd`/`event.gd`/`story_event.gd`)은
  전투와 무관하게 `RunState.rooms_cleared += 1`만 할 뿐 보스나
  `RunState.advance_round()`를 전혀 모르는 구조였다 — 그래서 마지막 방에서
  전투 대신 이들 중 하나를 고르면 보스를 만나지 않고도 런이 "클리어" 상태가
  되어 `round_index`가 1에 머문 채 "새 런 시작"(`RunState.reset_run()`)으로
  이어지는 게 보고된 증상의 원인이었다. `code/scenes/dungeon_map.gd`의
  `_room_options_for_index(idx)`에서 `idx == RunState.TOTAL_ROOMS - 1`이면
  상점/특수 이벤트/스토리 이벤트를 전부 노출하지 않도록 고쳐, 라운드 마지막
  방은 전투만 가능하게(보스를 반드시 거쳐야 라운드가 넘어가게) 강제함.
  `dice_test.gd`의 기존 방 선택지 결정성 검증을 이 예외 케이스까지 포함하도록
  갱신해 회귀 스위트 전체 PASS, `qa_out/dungeon_map_boss_room_combat_only.png`
  (`_debug_show_boss_room()` 경로, 5번째 방에 "전투" 선택지만 노출)로 실제
  화면 확인. docs/STATUS.md 완료 기록(90) 참고.

- [처리됨 - 2026-09-10] 2026-09-09 **[대형 기획 2] 던전 마지막에 보스급
  몬스터, 3라운드(던전) 클리어해야 최종 클리어**. 지금은 던전(런) 하나에 5방이고
  끝나면 "던전 클리어!" 화면으로 끝나는데, 이를 "라운드"로 재정의: 각 라운드
  (던전) 마지막 방은 지금의 일반 전투 방보다 강한 "보스" 전투로 바꾸고, 보스를
  이기면 다음 라운드(새 던전 맵)로 넘어감. 3라운드(3개 던전)를 전부 클리어해야
  진짜 "최종 클리어"(게임 승리 엔딩). 보스는 일반 몬스터보다 HP/공격/방어가
  눈에 띄게 높거나, 위 캐릭터 기믹처럼 몬스터도 특이 기믹을 가질 수 있음(라운드가
  올라갈수록 더 강한/복잡한 보스). `RunState`에 현재 라운드 번호, 라운드 3개
  클리어 여부 등을 추가해야 할 것으로 보임.
  → **3/3 조각 전부 완료.** 첫 조각(2026-09-09 (83)): 라운드 반복 구조 없이,
  런의 마지막 방(room_index == `RunState.TOTAL_ROOMS - 1`)의 몬스터만 "보스"로
  취급해 스탯을 강화(공격 다이스 +2개/방어 다이스 +1개/최대 HP ×2, 이름 끝에
  "[보스]" 태그). `combat_test.gd`의 `_monster_config_for_room()`에서 판정.
  두 번째 조각(2026-09-09 (87)): `RunState`에 `round_index`/`TOTAL_ROUNDS`
  (=3)/`is_last_round()`/`advance_round()`를 추가(순수 데이터 계층). 세 번째
  조각(2026-09-10 (88)): 보스 처치 시 새 던전 맵(다음 라운드)으로 재진입하도록
  배선 — `combat_test.gd`의 `_apply_room_advance()`가 보스 방 승리 + 마지막
  라운드가 아닐 때 `RunState.advance_round()`를 호출(골드/다이스 주머니/
  인벤토리는 유지, `rooms_cleared`만 리셋), 곧이어 dungeon_map으로 전환되면
  자동으로 새 라운드의 1번째 방으로 이어짐(별도의 "다음 라운드로" 확인 화면
  없이 승리 -> 다음 버튼 -> 새 라운드 맵으로 한 번에 연결). 방 개수가 갑자기
  줄어드는 이유를 알 수 있도록 던전 맵에 "라운드 N/3" 표시도 추가. **마지막
  조각(2026-09-10 (89)):** 3라운드 전부 클리어 시 지금의 "던전 클리어!"
  문구를 `dungeon_map.gd`의 `_update_labels()`에서 `RunState.is_last_round()`로
  다시 나눠 "게임 클리어! 총 3라운드 완주 (마지막 라운드 %d / %d 방 격파)"
  전용 문구로 교체. `dice_test.gd` 신규 검증(83, 87, 88 각 조각 추가분) 전체
  PASS, `qa_out/combat_test_boss_room4.png`(보스 스탯 강화)/
  `qa_out/dungeon_map_round2.png`(라운드 2/3 재진입)/
  `qa_out/dungeon_map_final_clear.png`(게임 클리어! 문구)로 3개 핵심 화면
  전부 겹침 없이 표시됨을 확인. **여전히 사람 판단 필요**: 라운드가 올라갈수록
  몬스터/보스가 더 강해져야 하는지(INBOX.md 원문이 언급했던 부분)는 미반영 —
  지금은 라운드 2/3도 라운드 1과 완전히 같은 room_index 기반 스케일링을
  재사용. 보스 강화폭(+2/+1/×2)이 적당한지도 사람 플레이 피드백 필요.
  docs/STATUS.md 완료 기록(83, 87, 88, 89) 참고.

- [처리됨 - 2026-09-09] 2026-09-09 **[대형 기획 1] 플레이어블 캐릭터 4종
  추가 (총 5종 중 선택 입장)**. 아이디어는 몬스터 다이스 특이 기믹
  (`code/systems`의 min/max 전용, 고정값 다이스, 분노 스택→D20 등)에서
  착안해서 만들 것 — 즉 각 캐릭터가 전투에 들어갈 때 자기 다이스 풀에 특이
  기믹 하나(또는 조합)를 갖고 시작하는 방식으로 캐릭터 개성을 표현. 예시로
  참고할 것: 극단형(다이스가 min/max만 나옴, 하이리스크), 안정형(다이스
  하나가 항상 고정값), 폭발형(특정 값이 나올 때마다 스택이 쌓여 임계치에서
  강한 한 방). 구체적 캐릭터 5종의 기믹 배정과 이름/컨셉은 AI가 제안해도
  되고, 사람이 정해도 됨. 캐릭터 선택 화면(`character_select.tscn`)도 카드
  1개 "확인" 형태에서 5개 카드 중 1개를 고르는 형태로 바꿔야 함.
  → **5/5종 완료(2026-09-09 (84)+(85)+(86))**: 캐릭터 선택 화면을 카드 여러 개 중
  하나를 고르는 UI로 확장 완료(`character_select.gd`/`.tscn`, 카드 폭이
  캐릭터 수에 맞춰 동적으로 줄어들어 5종이 돼도 화면 밖으로 안 잘림 — 4종째로
  늘었을 때 실제로 화면이 잘리는 회귀가 있었고 (85)에서 고침). 신규
  `code/systems/character_profiles.gd`에 극단형("광전사" —
  `DiceBag.force_min_max_faces()`를 공격+방어 둘 다에 적용)/안정형("수호자"
  — 신규 `DiceBag.force_fixed_value_for_die()`로 방어 다이스 "하나만" 고정값,
  예시 문구가 "다이스 하나"라고 명시한 것을 그대로 반영해 몬스터 "오크"의
  주머니 전체 고정과 구분)/폭발형("폭발병" — 몬스터 "고블린"의 분노 스택
  (anger_stack)과 완전히 같은 구조를 플레이어 공격턴에 적용, `combat_test.gd`의
  `player_dice_gimmick`/`player_explosive_stacks`/`player_explosive_pending`
  전투 중 상태로 구현. 공격 다이스가 최댓값 면을 3번 보여주면 다음 공격 한
  턴만 1D20)을 등록, 기존 "견습 모험가"(기믹 없음)와 합쳐 4종. 마지막 다섯
  번째는 인내형("방패병" — 폭발병과 완전히 대칭 구조로, 방어 다이스가 최댓값
  면을 3번 보여주면 다음 방어 한 턴만 1D20으로 굴려 굳건해짐 — INBOX.md 원
  예시 3개가 전부 구현된 뒤 AI가 다섯 번째 컨셉으로 제안·구현, (86))를 등록해
  5종 완성. 광전사/수호자는 `RunState.reset_run(character_id)`가 선택된
  캐릭터의 기믹을 새 주머니에 정적으로 적용하고, 패배 후 재시작처럼 인자 없이
  부르는 기존 호출부는 직전 캐릭터를 유지함. 폭발병/방패병은 둘 다 정적 다이스
  개조가 없어(턴 상태 추적 방식이라) `run_state.gd`의 적용 로직에는 안 걸리고
  `combat_test.gd`가 직접 처리 — 덱 패널에는 표준 다이스 그대로 보이고 전투
  로그에서만 효과가 드러남. 초상화는 기존 `character_portrait_placeholder.gd`를
  색만 다르게 재사용(`set_palette()` — 새로 그리지 않음, 지시대로 도형 조립
  플레이스홀더 유지). docs/STATUS.md 완료 기록(84, 85, 86) 참고. 남은 것은
  5종 전체의 강화폭/체감 밸런스에 대한 사람 플레이 피드백뿐.

- [처리됨 - 2026-09-09] 2026-09-09 (몬스터별 다이스 특이 특징 관련 방향/예시)
  대략적인 방향/예시:
  - 주사위 값 x가 고정 데미지로 들어간다 (굴리지 않고 항상 같은 값).
  - 모든 주사위 눈이 min과 max로만 이루어져 있다 (중간값 없음, 하이리스크/로우리스크).
  - 주사위 x가 나올 때마다 "분노 스택"이 쌓여서, 몇 개 이상 쌓이면 다음 턴에
    20면체 주사위를 돌린다.
  → 예시 3개 전부 구현 완료(작은 단위로 나눠 순차 처리, 2026-09-09 (75)/(77)/(78)).
  "모든 주사위 눈이 min과 max로만 이루어져 있다"는 `DiceBag.force_min_max_faces()`
  (면 값을 절반은 최솟값·절반은 최댓값으로 강제)로 구현해 `combat_test.gd`
  `MONSTER_PROFILES`의 "다크 나이트"(room_index=4)에 `dice_gimmick: "min_max_only"`로
  시범 적용(이름에 "[극단]" 표시). "주사위 값 x가 고정 데미지로 들어간다"는
  `DiceBag.force_fixed_value(value)`(다이스의 모든 면 값을 하나로 통일 — 어느 면이
  뽑히든 결과가 항상 같아지므로 "굴리지 않고 고정값"과 동일한 효과, 별도 상태 추적
  불필요)로 구현해 "오크"(room_index=3)에 `dice_gimmick: "fixed_value"`로 시범
  적용(값은 면 개수 평균 반올림, D6은 4 — 이름에 "[고정값 4]" 표시). "주사위 x가
  나올 때마다 분노 스택이 쌓여서 몇 개 이상이면 다음 턴에 20면체를 돌린다"는
  `DiceBag.count_max_rolls(values)`(x를 "그 다이스의 최댓값 면"으로 해석) +
  `combat_test.gd`의 전투 중 상태(`monster_anger_stacks`/`monster_anger_pending`,
  씬이 끝나면 함께 사라짐)로 구현해 "고블린"(room_index=1)에
  `dice_gimmick: "anger_stack"`으로 시범 적용(3스택에 다음 공격 한 턴만 1D20,
  이름에 "[분노]" 표시). 어떤 몬스터가 각 특징을 가져야 하는지는 몬스터 성격
  기획(아래 항목, 여전히 미착수)이 먼저 정해져야 확정할 수 있어 "고블린"/"다크
  나이트"/"오크" 셋 다 근거 없는 임시 배정 — 성격 기획이 나오면 재배정 가능.
  `dice_test.gd` 회귀 검증(`force_min_max_faces`/`force_fixed_value`/
  `count_max_rolls` 각각의 면 구성·반복 굴림·room1/room3/room4/room0 config 상호
  독립성 대조) 추가로 82개 항목 전체 PASS,
  `qa_out/combat_test_dark_knight_gimmick.png`(room4, "다크 나이트 [극단]"),
  `qa_out/combat_test_orc_gimmick.png`(room3, "오크 [고정값 4]", 교환 결과 칩이 둘 다
  "4"만 표시), `qa_out/combat_test_anger_dice.png`(room1, "고블린 [분노]", 분노
  발동 시 D20 다이스 + 로그 문구)로 실제 전투 화면 겹침 없음을 확인.
  docs/STATUS.md 완료 기록(75, 77, 78) 참고.

- [처리됨 - 2026-09-09] 2026-09-09 다이스 승급 이벤트에서, 면 개수가 가장 작은것 교체가
  아닌 획득으로 바꾼다. 눈금 획득 또는 다이스 승급시, 인벤토리로 들어와서 교체하도록
  한다.
  → `RunState.die_inventory`(pip_inventory와 같은 패턴의 정수 "면 개수" 목록)를 신규
  추가. "다이스 승급" 아이템(kind=upgrade_die, 상점/특수 이벤트/전투 승리 보상 3곳
  공통)이 더 이상 `DiceItemPool.apply()`로 즉시 어느 주머니의 가장 작은 다이스를
  자동으로 골라 교체하지 않고, `apply_upgrade_gain()`으로 인벤토리에 새 다이스를
  쌓기만 함(3곳 모두 attack/defense 버튼 대신 단일 "획득" 버튼으로 UI도 변경).
  `CustomizePanel`(눈금 교환과 같은 오버레이)에 새 "다이스 인벤토리" 흐름을 추가 —
  기존 1단계(눈금 선택) 화면에 "다이스 인벤토리 (N개)" 버튼을 붙여 진입, 인벤토리
  다이스 선택 → 넣을 자리(공격/방어 주머니의 다이스 슬롯) 선택 → 즉시 교환(밀려난
  기존 다이스는 면 개수만 인벤토리로 복귀). 실제 승급이 되는 자리(면 개수가 더 작은
  자리)만 선택 가능하도록 막아 의도치 않은 다운그레이드도 방지함. `dice_test` 회귀
  스위트에 신규 검증 4종(apply_upgrade_gain, is_applicable 항상 true로 변경, 다이스
  인벤토리 교환 로직, 이중 실행 방지) 추가해 전체 68개 항목 PASS. `qa_out/
  shop_upgrade_die.png`/`event_upgrade_die.png`/`customize_die_inventory.png`/
  `customize_die_target.png`로 4개 화면 전부 겹침/크래시 없이 정상 표시됨을 확인.
  docs/STATUS.md 완료 기록(73) 참고.

- [처리됨 - 2026-09-09] 2026-09-09 눈금 이벤트가 잘 안뜨는 것 같다. 눈금은 주사위 교체보다 벨류가 낮으므로, 눈금 여러개 획득하는 이벤트를 넣어 이벤트간 밸런스를 맞춘다.
  → 원인 확인: 지금까지 "특수 이벤트" 방(`EventItemPool`)은 D8/D12/D20 획득, D10 대승급
  4종 다이스 아이템만 제공했고 눈금(pip)을 주는 항목이 아예 없었음(눈금은 전투 승리
  보상 1개뿐 — "잘 안 뜨는 게 아니라 애초에 이 이벤트에는 없었음"). `EventItemPool.ITEMS`에
  "눈금 주머니 획득"(`kind: gain_pips`, 3~5개를 한 번에 `RunState.pip_inventory`로 추가)
  아이템을 5번째로 추가. 공격/방어 주머니를 고르는 기존 아이템들과 달리 대상 주머니가
  없어서, `event.gd`에 `_on_pick_pips()`/`_apply_pips()`를 별도로 만들고 카드에는
  "눈금 획득" 버튼 하나만 표시하도록 분기함(기존 이중 실행 방지 `_picked` 플래그는
  그대로 공유). `dice_test` 회귀 스위트에 새 검증(아이템 존재, 개수 범위, 이중 실행
  방지) 추가, `qa_out/event_pips.png`로 카드 레이아웃 확인. 등장 확률(4종 중 1개,
  무작위 2개 노출)이나 3~5개 수치가 적당한지는 사람 피드백 필요(밸런스 수치 자체는
  "기능 개발 끝난 뒤 마지막에" 튜닝하기로 확인된 사항이라 우선순위 아님).

- [처리됨 - 2026-09-09] 2026-09-09 전투에서 이미지로 보여지는 부분이 덜한데, 주사위값 사이즈업. 체력바 추가 등 정보를 텍스트보다 이미지로 표현하는게 좋을 듯 하다.
  → `combat_test.tscn`에 플레이어/몬스터 HP 막대(배경+채움 ColorRect 2장씩)를 HP
  라벨 바로 아래에 추가. `combat_test.gd`의 `_update_hp_bar()`가 매 교환마다 hp/max_hp
  비율로 채움 너비를 줄이고, 비율 50% 초과=초록/25~50%=주황/25% 이하=빨강으로 색까지
  바꿔 위기감을 시각적으로 드러냄. 교환 결과 다이스 값 칩(`ShapeDieChip`)도 34px ->
  44px로 키움(라벨 폰트는 칩 크기에 비례해 자동으로 커짐). `qa_out/combat_test_hpbars.png`로
  겹침/크래시 없이 정상 표시됨을 확인(몬스터 HP 3/10 상태에서 주황색 막대 정상 표시).
  `dice_test` 회귀 스위트 56개 항목 전체 PASS. docs/STATUS.md 완료 기록(69) 참고.
- [처리됨 - 2026-09-09] 2026-09-09 (STATUS.md 큐 관련 답변) 진짜 분기형 던전 맵
  (선택에 따라 다음 방 구성이 달라지는 노드 그래프)은 만들지 않는다 — 지금의 선형
  구조를 유지한다. 다만 던전 맵에서 방 선택지(전투/상점/특수 이벤트/스토리 이벤트)를
  고를 때, 각 선택지가 어떤 리스크인지는 보이지만 어떤 리턴(보상)을 주는지는 미리
  알기 어렵다 — 선택지마다 예상 보상/효과를 미리 알려주는 표시를 추가한다. 텍스트
  보다 도형/기호/이미지(예: 골드면 동전 아이콘, 눈금 획득이면 눈금 칩, 다이스 승급이면
  주사위 모양 아이콘 등)로 표현할 것.
  → "분기형 맵을 만들지 않는다"는 결정 자체는 반영(더 이상 검토 대상 아님, docs/
  STATUS.md 큐 0번 관련 문구도 갱신함). "선택지마다 예상 보상/효과 아이콘 표시"도
  2026-09-09 (72)에 완료 — `code/scenes/reward_icon.gd`(`RewardIcon`)로 골드(동전
  원)/눈금(점 1개 주사위 면)/다이스(점 3개 주사위 면) 3종 카테고리를 도형으로 그려
  방 선택 버튼 옆과 MapStrip 방 타입 칩에 표시. 실제 수치/상점 판매 품목까지는
  아니고 "카테고리"만 보여줌. docs/STATUS.md 완료 기록(72) 참고.

- [처리됨 - 2026-09-09] 2026-09-09 던전 선택 화면에서 커스터마이징:눈금 교환 ui/ux를
  인지하기 어렵다. 내가 어떤 상태인지, 여기서 무엇을 어떻게 할 수 있는지 알 수 있어야
  한다.
  → `code/scenes/customize_panel.gd`의 3단계(눈금 선택 → 다이스 선택 → 면 선택)
  화면 각각에 "(1/3)", "(2/3)", "(3/3)" 단계 번호를 제목에 명시하고, 제목 아래
  회색 안내 문구를 한 줄씩 추가함 — 1단계는 "보유 눈금 N개 중 무엇을 고르는지 +
  다음에 뭘 하는지", 2단계는 "고른 눈금을 어디에 넣을지 + 아래 숫자가 각 다이스의
  현재 면 구성이라는 것(금색=최댓값)", 3단계는 "면을 고르면 즉시 어떤 값으로
  바뀌는지 + 밀려난 값이 인벤토리로 돌아온다는 것"을 문장으로 알려줌. 인벤토리가
  비어 "다음 단계로 못 가는" 상태에서도 "왜 못 가는지" 문구를 별도로 보여주도록
  분리함. 작업 중 부수적으로 발견한 버그(Label에 autowrap_mode보다 size를 먼저
  설정하면 Godot이 줄바꿈 전 전체 텍스트 폭으로 size를 고정해버려 2단계 안내
  문구가 패널 밖으로 흘러넘치던 문제)도 속성 설정 순서를 바꿔 함께 고침.
  `qa_out/customize_step1_empty.png`/`customize_step1_pips.png`/
  `customize_step2_die.png`/`customize_step3_face.png`로 3단계 전부 겹침/오버플로우
  없이 정상 표시됨을 확인. `dice_test` 회귀 스위트(로직 변경 없음, 순수 UI 텍스트/
  레이아웃) 전체 PASS. "인지하기 쉬워졌는지" 자체는 사람이 실제로 플레이해보고
  판단해야 하는 영역 — 여전히 어렵다면 3단계 흐름 자체를 더 줄이는 등 추가 조치가
  필요할 수 있음. docs/STATUS.md 완료 기록(71) 참고.
- [처리됨 - 2026-09-09] 2026-09-09 (STATUS.md 큐 관련 답변) 밸런스 수치(확률/골드 보상/
  상점 가격/난이도 곡선 등)는 전부 임의값으로 그대로 둔다. 밸런스 조정은 기능 개발이
  모두 끝난 뒤 마지막에 진행할 최종 작업이므로, 지금 단계에서 밸런스 수치 자체를
  다듬는 작업은 우선순위가 아니다.
  → 확인함. 앞으로의 이터레이션에서 확률/가격/HP 등 순수 수치 튜닝 작업은 보류하고
  기능/UX 작업을 우선함(단, "눈금 여러 개 획득 이벤트 추가"처럼 수치가 아니라
  콘텐츠 자체가 없는 항목은 별개로 취급 — docs/STATUS.md 큐 0-A 참고).
- [처리됨 - 2026-09-09] 2026-09-09 (STATUS.md 큐 관련 답변) 덱 상시 표시가 토글 방식인
  것은 충분하다 — 레이아웃을 바꿔가며 완전한 상시 노출로 만들 필요 없음.
  → 확인함. combat_test의 "덱 보기" 토글 방식을 그대로 유지, docs/STATUS.md 큐 0번의
  해당 항목을 완료로 확정.
- [처리됨 - 2026-09-09] 2026-09-09 전투 후 던전으로 돌아가기 버튼을 다음 버튼으로
  텍스트 교체한다.
  → `code/scenes/combat_test.gd`의 승리 시 `next_button.text`를 "던전으로 돌아가기"에서
  "다음"으로 교체(`combat_test.tscn`의 기본 텍스트도 동기화). docs/STATUS.md 완료
  기록(68) 참고.
- [처리됨 - 2026-09-09] 2026-09-09 덱보기 토글창 오픈 시, 기존 깔려있는 다른 ui나
  이미지보다 상단에 위치해야 한다.
  → `code/scenes/combat_test.tscn`의 `DeckPanel`에 `z_index=10`을 줘서, 보상 카드나
  다이스 결과 칩처럼 나중에 add_child()로 추가되는 다른 UI보다 항상 위에 그려지도록
  함. docs/STATUS.md 완료 기록(68) 참고.
- [처리됨 - 2026-09-09] 2026-09-09 결과 화면이 나왔을 때, 덱 보기 토글이 열려있다면
  닫힌다. 덱보기 토글 또는 결과 선택지의 위치를 조정해서, 각각의 정보를 한 눈에 볼 수
  있도록 하되, 겹치지 않도록 한다.
  → `combat_test.gd`가 전투 결과(승리/패배) 화면을 띄우는 시점에 덱 패널이 열려
  있으면 자동으로 닫도록 함. 또한 보상 카드/버튼 영역의 x 범위를 980px(DeckPanel
  왼쪽 끝) 앞에서 끝나도록 좁혀서(카드 폭 400→380, 카드 x좌표 [200,640]→[160,560],
  배경 프레임 폭 1000→820), 덱 패널을 다시 열어도 겹치지 않게 함. QA 디버그 훅
  `_debug_show_reward_with_deck_open()`으로 `qa_out/combat_test_reward_deck_
  overlap.png` 스크린샷 검증 완료. docs/STATUS.md 완료 기록(68) 참고.
- [처리됨 - 2026-09-03] 2026-09-03 커스터마이징은 전투 중에는 불가능해야 한다.
  → 이전 이터레이션이 "어디서든 커스터마이징 가능"을 위해 `combat_test.tscn`에도
  전투 중 언제든 여닫을 수 있는 "커스터마이징" 토글 버튼을 붙였는데, 사용자가 그
  방향을 되돌려 전투 중에는 접근 자체가 불가능해야 한다고 명확히 지시함(이전에
  [보류]로 남아있던 "재현 안 됨" 조사 항목을 사용자가 이 문장으로 다시 정정 — 애초에
  "안 열려야 하는데 열린다"는 버그 신고가 아니라 "안 열려야 한다"는 요구사항이었음).
  `code/scenes/combat_test.gd`의 `CustomizeToggleButton`을 `battle_over`가 true가
  되기 전까지 숨기도록 바꿈(`_ready()`에서 `visible=false`로 시작, `_do_exchange()`가
  승/패를 확정짓는 시점에 `customize_toggle_button.visible = battle_over`로 동기화).
  버튼을 숨기는 것만으로는 QA/코드에서 시그널을 직접 발생시키는 경로까지 막지 못해서,
  `pressed` 핸들러도 `_on_customize_toggle_pressed()`로 분리해 `battle_over`가 아니면
  아무 일도 하지 않도록 이중으로 막음. 승리 보상 화면 안의 "커스터마이징: 눈금 교환"
  버튼(전투가 끝난 뒤에만 뜸)과 던전맵/상점/특수 이벤트/스토리 이벤트 4개 화면의
  상시 커스터마이징은 전투 중이 아니므로 그대로 유지됨. QA로 battle_over=false일 때
  버튼이 안 보이고, 강제로 pressed 시그널을 발생시켜도 패널이 열리지 않는 것(콘솔
  검증)과, 전투가 끝난 뒤에는 버튼이 다시 보이고 정상적으로 열리는 것(스크린샷)을
  확인. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-03] 2026-09-03 주사위 눈금 바꾸는 방법을 인지하기 어렵다. 인벤토리 창에 눈금이 쌓이고, 해당 눈금과 주사위 눈금이 교환되는 형태여야할 것 같다.
  → `RunState.pip_inventory`(정수 "눈금" 배열)를 추가해 전투 승리 보상으로 눈금
  1개(잠정 범위 1..4+방번호, `combat_test.gd`의 `PIP_REWARD_*`)를 쌓는다.
  `code/scenes/customize_panel.gd`의 상호작용 모델을 기존 "다이스 선택 → 면 선택 →
  1..면개수 범위에서 원하는 값 자유 입력"에서 요청하신 "눈금 선택 → 적용할 다이스 선택
  → 면 선택 → 즉시 교환"으로 완전히 바꿈. 교환 시 밀려난 기존 면 값은 인벤토리로
  돌아와(사라지지 않음) 계속 다른 다이스에 쓸 수 있고, 다이스의 면 개수를 넘는 눈금은
  그 다이스의 면 개수로 잘려 적용된다(기존 "값 교체, 상한 있음" 규칙 유지).
  `combat_test.gd`의 승리 보상 화면 안에 있던 자체 다이스/면/값 선택 체인은 제거하고
  공용 `CustomizePanel` 오버레이를 그대로 열도록 통합함(5개 화면 모두 동일 로직).
  QA로 검증: 빈 인벤토리 안내 문구, 눈금-면 교환 로직(콘솔 검증, 밀려난 값이
  인벤토리로 정확히 돌아옴), 면 선택 화면에서 적용될 값이 금색으로 강조 표시,
  전투 승리 보상 흐름과의 연동(패널 닫으면 다음 버튼 복귀) 전부 확인. 골드/눈금
  보상량은 감으로 잡은 잠정값 — 실제 플레이해보고 밸런스가 적당한지 사람 피드백 필요.
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-03(완료)] 2026-09-03 선택지 등에서 내 덱을 항상 볼 수 있고, 커스터마이징도 가능해야할 것 같다.
  → "항상 볼 수 있고" 부분은 `code/scenes/deck_panel.gd`(`DeckPanel`)를 던전맵/상점/
  특수 이벤트/스토리 이벤트/전투(토글) 5개 화면에 붙여 반영됨. "커스터마이징도
  가능해야" 부분도 새 `code/scenes/customize_panel.gd`(`CustomizePanel`)를 던전맵에
  먼저 붙인 뒤(이전 이터레이션), 이번 이터레이션에 shop/event/story_event/combat_test
  4개 화면에도 마저 붙여 5개 화면 전부에서 언제든 열 수 있게 함(combat_test는
  "덱 보기"와 나란한 토글 버튼). docs/STATUS.md 큐 0번/완료 기록 참고.
- [처리됨 - 2026-09-03] 2026-09-03 내 공격 덱과 방어 덱이 어떤 눈금을 보유한 주사위들인지 항상 떠있으면 좋을 것 같다. (전투 중에도, 선택지 중에도)
  → 새 `code/scenes/deck_panel.gd`(`DeckPanel`)를 던전맵/상점/특수 이벤트/스토리
  이벤트 4개 화면 우측에 붙여 공격/방어 주머니의 다이스별 면 구성을 상시 표시.
  **"전투 중에도"도 반영 완료** (2026-09-03 이후 이터레이션) — `combat_test.tscn`은
  화면이 이미 다이스 뷰포트/초상화/로그로 꽉 차 있어 다른 4개 화면처럼 "상시 표시"는
  어려워서, 대신 우측 상단 "덱 보기" 토글 버튼으로 여닫는 오버레이 패널로 구현함
  (완전한 상시 노출은 아니지만 전투 중 언제든 클릭 한 번으로 확인 가능).
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-03] 2026-09-03 전투 시 어떤 주사위에서 어떤 값이 나왔는지, 이미지로 보이면 좋을 것 같다. (세모 안에 숫자 4, 세모 안에 숫자 3, 세모 안에 숫자 2, 네모 안에 숫자 5 등등) (사면체는 세모, 육면체는 네모..)
  → `systems/dice_bag.gd`에 `roll_detailed()`(다이스별 개별 결과 배열)를 추가하고,
  새 `scenes/shape_die_chip.gd`(`ShapeDieChip`)로 다이스 면 모양(D4/D8/D20=삼각형,
  D6=사각형, D10=연꼴 근사=사각형, D12=오각형)에 맞는 아이콘 안에 값을 표시. 전투
  중 매 교환마다 공격/방어 양쪽 다이스 결과를 화면 하단에 이 칩으로 나열함.
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-03] 2026-09-03 주사위 커스터마이징 등, 해당 주사위에서 최고 값을 보유한 상태일때는 다른 눈금과 다른 색상으로 표시해줘야 한다. (명확하게 MAX값임을 알도록 하기 위해)
  → 커스터마이징 3단계(다이스 미리보기 / 면 선택 / 값 선택) 모두에서 그 다이스의
  면 개수(=낼 수 있는 절대 최댓값)와 같은 값의 칩/버튼을 금색 배경+테두리로 강조하도록
  `_make_face_chip()`/`_style_die_face_button()`에 `is_max` 파라미터 추가.
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-02 프로젝트D 폴더가 개발하면서 많이 늘어났는데 정리하자. ProjectD가 루트폴더가 되서, 루트폴더에서는 간결하게 보고싶음. 내가 보면서 피드백해야하는 폴더(docs, qa_out), 리소스가 모여있는 폴더, 코드가 모여있는 폴더로 정리하면 될듯. 분류가 애매하면 Util 폴더를 만들어 몰아담되, 최대한 폴더를 루트에서는 많이 담고싶지 않음. 게임 실행기가 있다면, 루트 폴더에 넣어서 폴더 열면 바로 뭘 하면 될지 알수있게끔 하자.
  → 루트를 `docs/`(기획+피드백), `qa_out/`(스크린샷 산출물), `code/`(스크립트/씬),
  `resources/`(재질 등 리소스), `Util/loop/`(반복 루프 하네스), `scripts/`(QA 실행기,
  루트에 그대로 유지 — 아래 이유 참고), `project.godot` 로 재편했다. `scripts/qa_shot.sh`
  만 예외적으로 루트에 남긴 이유: `.claude/settings.json`의 자동 승인 허용 목록이
  `scripts/qa_shot.sh` 경로를 그대로 참조하고 있어(무인 반복 루프가 이 스크립트를
  사람 개입 없이 실행해야 함), 다른 코드처럼 옮기면 매번 수동 승인이 필요해져 루프가
  멈춘다 — 동시에 "폴더를 열면 뭘 해야 할지 바로 안다"는 요구사항도 이 배치로 충족됨.
  이동 후 `.tscn`/`.gd`의 `res://` 경로, `project.godot`의 autoload/main_scene 경로,
  `.gitignore`, 문서(`docs/AUTOLOAD_SETUP.md`, `Util/loop/loop.sh`, `Util/loop/README.md`)의
  경로 참조를 전부 새 위치에 맞게 수정. `docs/STATUS.md` 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-02 INBOX.md 이 부분을 정리하자. 남은 이슈, 부분 처리됨 이슈, 처리됨 이슈를 분류해서 정리할 것.
  → 이 파일을 "남은 이슈 (미처리)" / "부분 처리됨" / "처리됨" 세 섹션으로 재구성함
  (기존에는 날짜 역순 단일 목록이었음). 각 섹션 안에서는 여전히 최신 항목이 위로
  오도록 정렬. 항목 내용/이력은 그대로 보존하고 분류만 다시 함.
- [처리됨 - 2026-09-07] 2026-09-02 주사위 눈을 보여주는 방식을 텍스트가 아닌 이미지로 보여주도록 한다. 주사위가 펼쳐진 평면도 또는 면을 하나하나 뜯어서 나열한 형태로 보여주면 어떨까? 궁극적으로 하고싶은건 유저가 어떤 주사위의 어느 부분을 개조해야 이득이 될지. 완성하면 어떤 주사위가 될지 예상할 수 있게끔 하는 것.
  → "면을 하나하나 뜯어서 나열한 형태"로 구현 (전개도 방식 대신). `combat_test.gd`의
  커스터마이징 3단계(다이스 목록 → 면 목록 → 값 목록) 전부를 텍스트 버튼에서 주사위
  눈 모양 사각 칩(둥근 테두리 정사각형 + 큰 숫자)으로 교체. 다이스 목록 단계에서는
  각 다이스 옆에 전체 면 구성을 작은 칩으로 미리 보여줘서 "이 다이스가 지금 어떤
  모양인지" 한눈에 파악 가능. **2026-09-07 추가 반영**: 승리 보상/상점/특수 이벤트
  카드(`ItemCardStyle`)에도 결과 다이스가 확정적인 아이템(다이스 추가/승급)에 한해
  `ShapeDieChip` 면 미리보기를 넣어, "카드"에도 "완성하면 어떤 주사위가 될지" 예상
  가능하게 함 — 이전에는 카드 안에 다이스 면 이미지가 없어 텍스트 설명에만 의존했음.
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-02 주사위 눈으로 커스터마이징 할때는 특정 값을 더하는 방식이 아닌, 특정 값으로 교체하는 방식. (4면체는 4를 넘어갈 수 없다)
  → `combat_test.gd`의 커스터마이징 흐름을 3단계로 바꿈: 주사위 선택 → 면 선택 →
  값 선택(1..면 개수 범위에서 직접 골라 그 값으로 교체, 상한은 그 다이스의 면 개수).
  기존 `FACE_BOOST_AMOUNT`(+3 누적) 방식은 제거함. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 주사위 눈으로 주사위를 커스터마이징 할 수 있다.
- [처리됨 - 2026-09-02] 2026-09-01 커스터마이징 하면, 내 덱의 특정 주사위 1개의 한 면 눈금을 바꿀 수 있다.
  → `combat_test.gd` 승리 보상 화면의 "커스터마이징: 다이스 눈금 직접 강화" 버튼으로
  구현. 다이스 선택 → 면 선택 → 그 면 값 +3. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 중요 : 사기 주사위를 만드는 재미가 있도록 한다
  → 면 값 상승에 상한을 두지 않아 반복 강화 시 계속 누적되게 함. 실제로 "사기" 체감이
  적당한지(너무 쉽거나 어렵지 않은지)는 사람이 플레이해보고 추가 피드백 필요.
- [처리됨 - 2026-09-02] 2026-09-01 특수한 이벤트에서는 주사위를 늘리는 이벤트를 제공한다. 다면체 주사위가 나올 수 있다.
  → 던전 맵에 "특수 이벤트" 세 번째 선택지 추가. `scenes/event.gd`(+`.tscn`)에서
  `systems/event_item_pool.gd`(EventItemPool)의 D8/D10/D12급 아이템 중 무료로 하나를
  골라 공격/방어 주머니에 즉시 적용. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 전투에서는 나와 상대 스프라이트가 표시된다.
  → `combat_test.tscn`에 `PlayerPortrait`(기존 캐릭터 선택 화면과 같은 플레이스홀더
  실루엣)와 `MonsterPortrait`(신규 — 뿔 달린 블롭 실루엣, 몬스터별 색 반영) 추가.
  화면 좌우 여백(다이스 뷰포트 바깥)에 배치. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 공방을 주고받을 때는, 웃거나 찡그린다.
  → 매 교환마다 공격한 쪽은 "happy"(웃음), 데미지를 받은 쪽은 "hurt"(찡그림,
  데미지 0이면 표정 변화 없음)로 표정이 바뀜. docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 승리할 때는, 즐거워한다.
  → 승리 시 플레이어 "happy", 몬스터 "sad". docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 패배할 때는, 슬퍼하거나 분노한다.
  → 패배 시 플레이어 "angry" 또는 "sad" 중 무작위, 몬스터 "happy".
  docs/STATUS.md 완료 기록 참고.
- [처리됨 - 2026-09-02] 2026-09-01 승리하면 골드를 주며, 스테이지 대신 상점 이벤트를 갔을 때, 사용할 수 있다.
  → `RunState.gold` 추가, 전투 승리 시 `combat_test.gd`가 골드 지급, `scenes/shop.gd`
  (+`.tscn`)에서 골드로 기존 다이스 아이템(`DiceItemPool` 3종)을 구매해 공격/방어
  주머니에 적용 가능. 가격/보상량은 잠정값 — 사람 피드백 필요. docs/STATUS.md 완료
  기록 참고.
