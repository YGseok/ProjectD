# STATUS.md — 인수인계 문서

> 매 이터레이션 시작 시 DESIGN.md, 이 파일, INBOX.md 순으로 읽는다.
> 매 이터레이션 종료 시 이 파일을 "다음 사람(다음 세션)"에게 인수인계하듯 갱신한다.

## 마지막 갱신

- 일시: 2026-09-02
- 작성자: AI 에이전트 (INBOX.md 신규 항목 반영: 던전 맵에 "특수 이벤트" 세 번째
  방 종류 추가 — 무료로 D8/D10/D12급 다이스를 얻는 이벤트)

## 지금 위치

- 기획(다이스 빌딩 전투 시스템)이 첫 프로토타입을 만들 수 있을 정도로 구체화됨.
  자세한 내용은 `docs/DESIGN.md`의 "확정된 세부 사항" 섹션 참고.
- **다이스 판정 로직 구현 및 검증 완료.** `res://systems/dice_bag.gd`(`DiceBag` 클래스:
  면 개수·개수를 받아 `roll()`로 합계 반환)와 `res://systems/combat_math.gd`
  (`CombatMath.calculate_damage(공격합, 방어합) = max(0, 공격합 - 방어합)`)를 추가함.
  `res://scenes/dice_test.tscn`에서 DESIGN.md 확정 수치(플레이어 공격/방어 D4x3,
  몬스터 공격 D4x2/방어 D4x1)로 300회 반복 값 범위 검증 + 데미지 공식 검증을 수행하고
  결과를 화면에 텍스트로 출력, 전부 PASS 확인 (`qa_out/dice_test.png`).
  → 다음 단계(큐 1: 다이스 물리 프리팹, 큐 2: 전투 씬)에서 이 두 스크립트를 그대로
  재사용하면 됨.
- **2D+3D 혼합 파이프라인 검증 완료.** `res://scenes/dungeon.tscn`에 SubViewportContainer +
  SubViewport(transparent_bg=true) 안에 3D 씬(Camera3D, DirectionalLight3D, WorldEnvironment,
  StaticBody3D 바닥, RigidBody3D 박스 다이스)을 넣어 2D 배경/라벨 위에 3D 물리 다이스가
  굴러 떨어지는 것을 확인함. `qa_out/dungeon.png` 참고.
  → 결론: **SubViewport 방식으로 간다.** (다른 방식 검토 불필요)
- `qa/visual_qa.gd`에 있던 사전 버그(`change_scene_to_file`을 autoload `_ready`에서 즉시
  호출하면 "Parent node is busy adding/removing children" 에러) 발견 및 수정함
  (`await get_tree().process_frame`으로 한 프레임 지연 후 호출).
- `project.godot`에 autoload/main_scene 이미 등록되어 있음 (`AUTOLOAD_SETUP.md`의 수동 설정
  단계는 이제 완료된 상태 — 새 환경에 옮길 때만 참고).
- **D4 물리 프리팹 구현 완료.** `res://dice/die_d4.tscn` (+`die_d4.gd`, `class_name DieD4`,
  `RigidBody3D` 확장): 정사면체 메시/충돌모양을 `SurfaceTool`+`ConvexPolygonShape3D`로
  코드에서 생성함 (Godot 기본 프리미티브에 정사면체가 없어서). 재질은
  `res://dice/dice_material.gd`(`class_name DiceMaterial extends Resource`: material_name,
  bounce, friction, impact_sound)로 분리하고, `res://dice/materials/plastic.tres`를
  기본값(bounce=0.3, friction=0.6)으로 꽂아둠. 충돌 시(`body_entered`, 속도 임계값 +
  쿨다운으로 스팸 방지) `AudioStreamPlayer3D.play()`를 호출하도록 배선했으나,
  **실제 사운드 에셋(.wav/.ogg)은 아직 없음** — `impact_sound`가 비어 있으면 조용히
  스킵하도록 처리해서 크래시 없이 동작함 (나중에 `plastic.tres`의 `impact_sound`만
  채우면 바로 소리가 남).
  `scenes/dungeon.tscn`의 플레이스홀더 박스 다이스를 이 `die_d4.tscn` 인스턴스로 교체함
  (`scripts/qa_shot.sh dungeon 150`으로 확인: 정사면체가 바닥에 굴러떨어져 안착,
  `qa_out/dungeon.png`).
  → 아직 없는 것: 실제 사운드 에셋, 유리/나무/철제 등 다른 재질, 다이스 여러 개 동시
  시뮬레이션(전투 씬 큐에서 다룰 예정).
- **전투 씬 1차 버전 구현 완료.** `res://scenes/combat_test.tscn` + `combat_test.gd`
  (`GAME_START=combat_test`로 QA 가능): DESIGN.md 확정 수치 그대로 하드코딩
  (플레이어 공격/방어 D4x3·HP20, 몬스터 공격 D4x2/방어 D4x1·HP10). 판정은 기존
  `DiceBag`/`CombatMath`를 그대로 재사용, 시각 다이스는 기존 `DieD4` 프리팹을 매 교환마다
  필요한 개수만큼 인스턴스해서 재사용 (새 프리팹 없음). 턴 순서는 DESIGN.md 그대로
  "내 공격턴(플레이어 공격 vs 몬스터 방어) → 몬스터 공격턴(몬스터 공격 vs 플레이어 방어)
  → 반복"이며, HP 0이 되는 쪽이 나오면 종료하고 승/패 문구를 표시.
  UI: 양쪽 HP 라벨, 현재 턴 라벨, 최근 교환 결과 로그(최대 7줄) 표시.
  → **중요한 단순화**: 물리로 굴러가는 `DieD4`는 순수 연출용이고, 실제 합계는
  `DiceBag.roll()`의 RNG로 별도 계산한다 (물리 다이스가 착지한 면을 읽어서 판정하는
  기능은 없음 — 다음 항목이나 사람 피드백에서 "다이스 눈이 실제 결과와 안 맞아 보인다"는
  지적이 나올 수 있음, 알려진 이슈 참고).
  → 다이스가 바닥 밖으로 굴러 떨어지는 문제를 QA 스크린샷에서 발견해서 고침: 바닥
  `StaticBody3D`에 보이지 않는 벽 4개(`CollisionShape3D`, 상하좌우)를 추가해 다이스가
  퍼져도 화면 밖으로 사라지지 않게 함.
  `scripts/qa_shot.sh combat_test 140`으로 첫 교환 직후 상태(HP 갱신, 로그, 다이스가
  바닥 위에 안착) 확인, `scripts/qa_shot.sh combat_test 1500`으로 전투가 끝까지
  진행되어 "승리!" 문구와 최종 HP(20/20 vs 0/10)가 정상 표시되는 것까지 확인
  (`qa_out/combat_test.png`, `qa_out/combat_test_late.png`). 크래시 없음.
- **다이스 정지 감지 구현 완료.** 기존에는 교환마다 고정 시간(2.2초)만 기다리고 결과를
  계산했으나, 이제 `combat_test.gd`가 실제로 모든 다이스의 속도를 매 물리 프레임 확인해
  임계값 이하가 일정 프레임 지속되면 정지로 판단한다 (안 멈추는 극단적 상황을 대비한
  4초 안전장치 포함). 자세한 파라미터는 "완료 기록" 참고.
- **2026-09-01**: 큐 1 "다이스 정지 감지 구현" 완료 (알려진 이슈에 있던 항목).
  기존에는 교환마다 고정 시간(`EXCHANGE_SETTLE_TIME=2.2초`)만 기다렸는데, 이를
  실제 물리 상태 기반 감지로 교체함. `combat_test.gd`에 `_wait_for_dice_to_settle()`
  추가: 매 물리 프레임(`await get_tree().physics_frame`)마다 `dice_root`의 모든
  `RigidBody3D` 자식의 `linear_velocity`/`angular_velocity`가 각각 임계값
  (`SETTLE_LIN_THRESHOLD=0.05`, `SETTLE_ANG_THRESHOLD=0.3`) 이하인지 확인하고,
  `SETTLE_MIN_FRAMES=15` 프레임 연속으로 조건을 만족하면 정지로 판단해 진행한다.
  물리 이상 등으로 끝내 멈추지 않는 극단적 상황을 대비해 `SETTLE_MAX_WAIT=4.0초`
  초과 시 강제로 다음 단계로 진행하는 안전장치도 넣음.
  `scripts/qa_shot.sh combat_test 140` (교환 진행 중), `300` (두 번째 교환까지 정상
  진행, 다이스 착지 확인), `1500`(끝까지 진행, "승리!" 정상 표시)으로 검증 —
  크래시 없음. 실제로 이전 고정 대기(2.2초)보다 다이스가 더 빨리 멈추는 경우가
  많아서 체감 진행 속도가 빨라짐 (frame 300에서 이미 2교환 완료 — 이전에는 첫
  교환도 frame 140 시점에 막 끝나가던 것과 대조적).
- **던전 맵 허브 + 전투 후 복귀 흐름 구현 완료** (이번 이터레이션에서 검증 및
  인수인계 마무리 — 자세한 내용은 "완료 기록" 참고). `res://scenes/dungeon_map.tscn`
  (+`dungeon_map.gd`), `res://systems/run_state.gd`(autoload `RunState`)를 추가하고
  `combat_test.gd`에 승/패 후 `NextButton`을 배선해 던전 맵으로 돌아가는 흐름을 완성함.
  `project.godot`의 `run/main_scene`도 `dungeon_map.tscn`으로 변경됨.
- **던전 맵에 "런 길이" 개념 추가 완료** (이번 이터레이션, 큐 1 일부 진행 — 상점/선택지
  방 종류는 여전히 미착수). `RunState.TOTAL_ROOMS = 5`(잠정값)를 추가하고
  `is_run_complete()` 헬퍼를 넣음. `dungeon_map.gd`가 이제 "클리어한 방: N / 5"를
  보여주고, 버튼 텍스트도 "전투 방 입장 (N번째 방)"으로 다음 방 번호를 안내함.
  5방을 다 깨면 라벨이 "던전 클리어! (5 / 5 방 격파)"로 바뀌고 버튼이 "새 런 시작"으로
  바뀌어 누르면 `RunState.reset_run()` 후 같은 화면에서 0부터 다시 시작 가능. 자세한
  내용은 "완료 기록" 참고.
- **방마다 다른(더 강한) 몬스터가 나오도록 구현 완료** (이번 이터레이션, 큐 1 계속 —
  상점/선택지 방 종류는 여전히 미착수). 지금까지는 몇 번째 방이든 항상 똑같은 테스트
  몬스터(공격 2D4/방어 1D4/HP10)와만 싸웠는데, `combat_test.gd`가 이제 `RunState.rooms_cleared`
  기준으로 몬스터 구성을 계산해서 던전이 진행될수록 몬스터가 강해짐. 자세한 내용은
  "완료 기록" 참고.
- **몬스터별 이름 + 다이스 색 시각 구분 추가 완료** (큐 1 계속 —
  상점/선택지 방 종류는 여전히 미착수). 지금까지는 몇 번째 방이든 HP/공수 숫자만
  다를 뿐 "같은 몬스터"로 보였는데, `combat_test.gd`가 이제 방 번호에 따라 몬스터
  이름(슬라임/고블린/해골 전사/오크/다크 나이트 5종 순환)과 다이스 색을 부여하고,
  몬스터 쪽 다이스만 그 색으로 물들여서 플레이어 다이스(기본 흰색)와 구분되게 함.
  자세한 내용은 "완료 기록" 참고.
- **골드 + 상점 이벤트 구현 완료** (INBOX.md 신규 항목 반영, 이번 이터레이션에서
  검증 및 인수인계 마무리 — 세션 시작 시점에 이미 미커밋 상태로 작업트리에 있던 것을
  QA로 재검증하고 레이아웃 버그를 고쳐 커밋함). `RunState.gold` 추가, 전투 승리 시
  `combat_test.gd`가 골드 지급, `res://scenes/shop.gd`(+`.tscn`)에서 기존
  `DiceItemPool` 아이템 3종을 골드로 구매해 공격/방어 주머니에 적용 가능. 던전 맵에
  "전투 방" 외 "상점" 버튼이 추가되어 매 방마다 2개 선택지 중 고를 수 있음. 자세한
  내용은 "완료 기록" 참고.
- **커스터마이징 방식을 "값 더하기"에서 "값 교체(상한 있음)"로 변경 완료** (INBOX.md
  신규 지시 최우선 반영). 기존에는 면을 고르면 그 값에 고정량(+3)을 더해 상한 없이
  계속 누적되는 방식이었는데, 사용자가 "특정 값을 더하는 방식이 아닌 특정 값으로
  교체하는 방식, 4면체는 4를 넘어갈 수 없다"고 명확히 정정함. 자세한 내용은 "완료
  기록" 참고.
- **"특수 이벤트" 던전 방 추가 완료** (INBOX.md 신규 항목 반영, 이번 이터레이션). 던전
  맵의 방 선택지가 지금까지 "전투" / "상점" 2개였는데, 사용자가 요청한 "특수한
  이벤트에서는 주사위를 늘리는 이벤트를 제공한다. 다면체 주사위가 나올 수 있다"를
  반영해 "특수 이벤트" 세 번째 선택지를 추가함. `res://systems/event_item_pool.gd`
  (`EventItemPool`)에 D8/D10/D12급 아이템 3종을 정의하고(상점/보상의 D4~D6급
  `DiceItemPool`과는 별도 풀), `res://scenes/event.gd`(+`.tscn`)에서 그중 무작위
  2개를 무료로 제시해 하나를 골라 공격/방어 주머니에 즉시 적용하면 방을 소비하고
  던전 맵으로 돌아간다. 자세한 내용은 "완료 기록" 참고.
- **다이스 개조(빌드업) 아이템 시스템 첫 버전 구현 완료** (이번 이터레이션, 큐 3).
  DESIGN.md 핵심 재미 축인데 지금까지 손대지 않았던 부분. `systems/dice_bag.gd`의
  내부 표현을 "면 개수(sides)"에서 다이스별 "면 값 배열(faces)"로 바꿔서 개조를
  표현할 수 있게 했고(`add_die`/`replace_die`/`set_face_value`), 승리 후 다이스
  아이템 2종을 골라 공격/방어 주머니 중 원하는 쪽에 적용하는 보상 화면을 붙임.
  플레이어의 다이스 주머니는 이제 `combat_test.gd`가 아니라 `RunState`가 들고 있어서
  전투를 여러 번 치러도 개조 결과가 유지됨. 자세한 내용은 "완료 기록" 참고.
  → **이번 이터레이션 시작 시점에 이 작업이 커밋되지 않은 채 작업트리에 남아있었음**
  (이전 세션이 STATUS.md는 갱신했지만 `git commit`을 빼먹은 것으로 보임). 이번
  이터레이션에서 QA로 재검증 후 커밋을 완료함.
- **다이스 "커스터마이징"(INBOX.md 최우선 반영) 구현 완료.** 지금까지 승리 보상은
  무작위 아이템 2개 중 골라 주머니에 적용하는 것뿐이었는데, INBOX.md에 사용자가
  명시적으로 요청한 "내 덱의 특정 주사위 1개의 한 면 눈금을 직접 바꿀 수 있다" +
  "중요: 사기 주사위를 만드는 재미"를 반영해 세 번째 선택지를 추가함.
  `combat_test.gd`의 보상 화면에 "커스터마이징: 다이스 눈금 직접 강화" 버튼을 추가하고,
  누르면 2단계 하위 화면(① 공격/방어 주머니의 다이스 6개 중 하나 선택 → ② 그 다이스의
  면 중 하나 선택)을 거쳐 선택한 면 값에 `FACE_BOOST_AMOUNT=3`을 더한다. 상한 없이
  반복 적용 가능하므로(승리할 때마다 같은 면을 계속 고르면) 후반에는 노골적으로 강한
  "사기 주사위"를 만들 수 있음 — 이것이 의도임. 자세한 내용은 "완료 기록" 참고.

## 다음 할 일 큐 (우선순위 순)

이 순서를 반드시 지킬 필요는 없지만, 앞 단계가 뒤 단계의 전제가 되므로 대체로 순서대로
진행하는 것을 권장한다. 한 이터레이션에 한두 개만 진행할 것.

1. **던전 맵 내용 채우기 (계속)** — "런에 끝이 있다"(`RunState.TOTAL_ROOMS=5`, 완료 시
   화면 전환), "방마다 다른(더 강한) 몬스터", ~~상점 방 종류 추가~~(완료됨 — 아래
   "완료 기록"의 "골드 + 상점 이벤트" 참고), ~~특수 이벤트 방 종류 추가~~(완료됨 —
   아래 "완료 기록"의 ""특수 이벤트" 던전 방 추가" 참고)는 추가했지만, 방 선택지가
   항상 "전투/상점/특수 이벤트" 3개 고정으로만 나열되고(무작위/기획된 조합이 아님),
   순수 "선택지(스토리성 비전투) 이벤트"는 여전히 없음. 다음 단계 후보:
   - 3개 방 선택지가 매번 전부 노출되는 대신, 방마다 일부만 무작위로 제시되거나
     순서가 섞이는 것이 "레벨 디자인"에 더 가까울 수 있음 (사람 피드백 필요).
   - 스토리/선택형 이벤트(전투도 상점도 아닌, 다이스와 무관한 텍스트 선택지 등) 방
     종류 추가 (내용은 DESIGN.md에서도 아직 미정 — 사람 지시나 INBOX.md 피드백 필요)
   - 신규 "특수 이벤트" 방의 아이템 3종(D8 추가/D12 추가/가장 작은 다이스->D10 승급)과
     등장 빈도(매 방마다 상시 노출)는 감으로 잡은 잠정값 — 실제로 플레이해보고 너무
     자주/강하게 다면체 다이스를 얻을 수 있는 건 아닌지 사람 피드백 필요.
   - 상점 가격(`shop.gd`의 `ITEM_COSTS`)과 골드 보상(`combat_test.gd`의
     `GOLD_REWARD_BASE`/`GOLD_REWARD_PER_ROOM`)은 감으로 잡은 잠정값 — 실제 플레이해보고
     너무 쉽게/어렵게 아이템을 살 수 있는 건 아닌지 사람 피드백 필요.
   - 몬스터 난이도 스케일링 공식(`combat_test.gd`의 `_monster_config_for_room()` —
     공격 2방마다 +1개, 방어 3방마다 +1개, HP 매 방 +3)은 감으로 잡은 잠정값. 실제
     플레이해보고 체감 난이도 곡선이 적당한지, 후반 방에서 다이스 개수가 늘어난
     시각적 레이아웃(안 겹치는지)이 괜찮은지 사람 피드백 필요
   - ~~몬스터별로 다른 이름/다이스 색 표시~~ → 완료됨 (이름 5종 순환 + 다이스 색 구분,
     아래 "완료 기록" 참고). 다만 다이스 "모양"은 여전히 전부 `DieD4`(정사면체)
     재사용 — 몬스터별로 다른 다이스 형태(예: 더 강한 몬스터는 D6/D8)를 쓸지는
     아직 미정 (다이스 개조 시스템 큐와도 연결될 수 있는 부분).
   - `TOTAL_ROOMS=5`는 감으로 잡은 잠정값 — 실제 플레이해보고 체감 길이가 적당한지
     사람 피드백 필요
2. **전투 씬 다듬기 / 후속 검토**
   - 지금은 사람이 실제로 플레이해봐야 판단 가능한 부분이 많음 (INBOX.md 피드백 대기):
     정지 감지 이후 교환 속도(체감 템포)가 적당한지, 다이스 개수가 늘어도 안 겹치고
     잘 보이는지, "물리 다이스 눈 ≠ 실제 판정값" 불일치가 체감상 이상한지 등.
   - 다이스 정지 감지는 구현했지만 임계값(`SETTLE_LIN_THRESHOLD`/`SETTLE_ANG_THRESHOLD`/
     `SETTLE_MIN_FRAMES`)은 감으로 잡은 초기값 — 다이스 개수가 늘어나면(아이템으로
     주머니에 다이스 추가 등) 재검증 필요.
3. **다이스 개조(빌드업) 아이템 시스템 다듬기** — 1차 버전(`systems/dice_item_pool.gd`,
   아이템 3종: 다이스 추가/승급/약한 면 강화, 전투 승리 후 2개 중 선택)과 사용자 지정
   "커스터마이징"(특정 다이스의 특정 면을 골라 1..면 개수 범위의 값으로 교체 — 이전
   이터레이션의 "+3 누적, 상한 없음" 방식에서 INBOX.md 지시로 변경됨)은 구현됨. 다음 후보:
   - 아이템 종류가 3개뿐이고 강도가 감으로 잡은 값(D4→D6 고정, 매번 최저면→최댓값)이라
     실제로 플레이해보고 밸런스가 괜찮은지 사람 피드백 필요.
   - 커스터마이징이 이제 면 개수로 상한이 걸려서(D4는 4를 못 넘음) 예전만큼 "사기
     주사위"가 쉽게 나오진 않음 — 다만 "다이스 승급"(면 개수 자체를 늘리는 아이템)과
     조합하면 승급 후 다시 커스터마이징해서 상한을 계속 올릴 수 있음. 이 조합이 실제로
     "사기 주사위 재미"를 잘 살리는지는 사람 플레이 피드백 필요.
   - INBOX.md는 "강화 카드"라는 표현을 썼는데(주사위 눈이 그려진 카드 형태 UI 이미지),
     지금 구현은 버튼 목록 형태라 시각적으로 "카드"처럼 보이지 않음. 나중에 카드형
     비주얼로 다듬을지는 사람 피드백 필요.
   - 지금은 "물리로 보이는 DieD4"가 항상 정사면체(D4) 모양인데, 아이템으로 주머니에
     D6/D8 다이스가 섞여도 시각적으로는 여전히 D4 프리팹을 재사용해서 굴러감(개수만
     늘어남) — 다이스 "모양"까지 아이템에 맞춰 바뀌게 할지는 미정 (다른 큐 항목인
     "몬스터별로 다른 다이스 형태"와도 연결됨).
   - 몬스터는 개조 대상이 아님(DESIGN.md 확정 — 몬스터 주머니는 고정), 그대로 유지.
   - 패배 시 `RunState.reset_run()`으로 다이스 개조 내역도 함께 초기화됨(런 실패 시
     빌드가 리셋되는 로그라이크 관례를 따름) — 이게 맞는 방향인지도 사람 판단 필요.
4. **사운드 에셋 실제 교체** — `res://dice/materials/plastic.tres`의 `impact_sound`가
   비어있어 배선만 되어 있고 소리는 안 남 (사람이 실제로 들어야 판단 가능한 영역).
5. ~~(INBOX.md 신규) 특수 이벤트에서 다이스 개수/다면체 늘리기~~ → **완료됨** (이번
   이터레이션, 아래 "완료 기록" 참고). `systems/event_item_pool.gd` +
   `scenes/event.gd`(+`.tscn`)로 던전 맵에 "특수 이벤트" 방 추가, D8/D10/D12급
   아이템을 무료로 획득 가능. 남은 것은 등장 빈도/강도 밸런스 사람 피드백뿐 (큐 1에
   남겨둠).
6. **(INBOX.md 신규) 던전 입장 시 캐릭터 선택** — 슬레이 더 스파이어류처럼 던전 시작
   전에 플레이어블 캐릭터를 고르는 화면 필요. 사용자 지시: 일단은 능력 차별화 없는
   기본 캐릭터 1종만, "이쁘장한 여캐" 하나를 디자인. 아트 리소스(스프라이트)가 필요한
   작업이라 AI가 혼자 결정하기 어려운 부분이 큼 — 스타일/구체 디자인은 사람 확인 필요.
7. **(INBOX.md 신규) 전투 스프라이트 + 표정 연출** — 전투 화면에 플레이어/몬스터
   스프라이트를 표시하고, 공방 교환 시 웃음/찡그림, 승리 시 기뻐함, 패배 시 슬픔/분노
   표정으로 바뀌는 연출 필요. 몬스터는 "몬스터 무스메" 컨셉. 캐릭터 선택(큐 6)과 함께
   아트 파이프라인이 먼저 필요함 (지금은 다이스 색으로만 몬스터를 구분 중).
8. **(INBOX.md 신규) 몬스터별 성격 디자인** — 사용자가 "추후 기획, 할 일 거리에 저장"
   이라고 명시. 지금 `MONSTER_PROFILES`(`combat_test.gd`)는 이름/다이스 색만 있고
   성격/말투 등은 없음 — 나중에 기획 문서(DESIGN.md)에 먼저 구체화된 뒤 반영해야 함.
9. **(INBOX.md 신규) 몬스터별 다이스 특이 특징** — 몬스터 외형/특성에 어울리는 다이스
   기믹(예: 특정 면 확률 조작, 특수 효과 등)을 부여하자는 아이디어. 지금 몬스터는 전부
   "표준 D4 다이스 개수만 다른" 동일 구조라 실제 개성은 없음. 구체 기믹은 아직 미정 —
   사람 지시나 몬스터 성격 기획(큐 8)이 먼저 필요할 수 있음.
10. ~~(INBOX.md 신규) 골드 + 상점 이벤트~~ → **완료됨** (이번 이터레이션, 아래 "완료
    기록" 참고). `RunState.gold`, 전투 승리 골드 지급, `scenes/shop.gd` 구현.
    남은 것은 가격/보상 밸런스 사람 피드백뿐 (큐 1에 남겨둠).
11. **(INBOX.md 신규, 부분 완료) 레벨 디자인된 여러 스테이지** — "일단은 선형으로
    점차 강해지게, 스텝 바이 스텝으로 수평적 선택지를 넓힌다"는 방향 확인. 던전 맵이
    이제 "전투 방" / "상점" / "특수 이벤트" 세 선택지를 보여주는 것까지는 완료(아래
    "완료 기록" 참고). 다만 선택지가 항상 이 3개로 고정 노출되고, 방 종류 자체도 이
    셋뿐이라 실제 "레벨 디자인"이라 부를 만큼 다양한 분기는 아직 아님 — 다음 단계로 방마다 후보를
    무작위/기획된 조합으로 바꾸거나 세 번째 방 종류(비전투 이벤트 등)를 추가하는 것을
    검토. 큐 1(던전 맵 내용 채우기)과 병합해서 진행하는 것을 권장.
12. **(INBOX.md 신규 2026-09-02) 다이스 눈을 이미지로 표시** — 지금 커스터마이징
    화면(큐 3)은 면 값을 전부 텍스트 버튼("면 1: 현재값 2" 등)으로만 보여주는데,
    사용자는 "주사위가 펼쳐진 평면도" 또는 "면을 하나하나 뜯어서 나열한 형태"의 이미지로
    보여주길 원함. 목적은 "이 주사위를 어떻게 개조하면 어떤 주사위가 완성될지"를
    시각적으로 예상할 수 있게 하는 것. 아트 에셋(면 이미지 또는 절차적 드로잉)과 UI
    레이아웃 설계가 필요한 작업이라 다음 이터레이션에서 접근 방식(예: 정육면체 전개도
    스타일 vs 단순 나열된 사각형 각 면에 숫자, Godot에서 Control/Polygon2D로 코드 생성할지
    스프라이트로 만들지)부터 사람과 정해야 할 수 있음. 미착수.

## 완료 기록

- **2026-09-02**: INBOX.md 신규 항목 반영 — "특수한 이벤트에서는 주사위를 늘리는
  이벤트를 제공한다. 다면체 주사위가 나올 수 있다"를 던전 맵의 세 번째 방 종류로 구현.
  - `systems/event_item_pool.gd`(신규, `class_name EventItemPool`): 상점/전투 보상이
    쓰는 `DiceItemPool`(D4~D6급)과는 별도로, D8 추가 / D12 추가 / 가장 작은 다이스를
    D10으로 승급하는 3개 아이템을 정의. item dict 형식(`kind`/`sides`/`new_sides`)이
    `DiceItemPool`과 동일하므로 적용 로직은 새로 만들지 않고 `DiceItemPool.apply()`를
    그대로 재사용함.
  - `scenes/event.gd`(신규) + `scenes/event.tscn`(신규): `shop.gd`와 비슷한 레이아웃이지만
    골드를 쓰지 않음 — `EventItemPool.random_choices(2)`로 2개를 무작위 제시하고,
    "공격/방어 주머니에 적용" 버튼을 누르면 그 즉시 `DiceItemPool.apply()`로 반영,
    `RunState.rooms_cleared`를 1 늘리고 `dungeon_map.tscn`으로 돌아감 (다른 하나를
    고를 기회 없이 바로 확정 — 전투 승리 보상과 달리 "뒤로" 단계 없음, 상점처럼 별도
    "나가기" 버튼도 없이 선택 즉시 방을 나가는 구조).
  - `scenes/dungeon_map.gd`/`.tscn`: `EnterEventButton` 추가(offset_top 460~510,
    기존 상점 버튼 바로 아래). `_update_labels()`가 진행 중이면 "특수 이벤트 입장
    (N번째 방)" 텍스트로 다음 방 번호를 안내하고, 런 완료 시(`is_run_complete()`)
    상점 버튼과 함께 숨김.
  - QA 검증: `scripts/qa_shot.sh dungeon_map 30`으로 3개 버튼이 안 겹치고 정상 표시됨
    확인(`qa_out/dungeon_map.png`). `scripts/qa_shot.sh event 30`으로 이벤트 방
    자체가 크래시 없이 로드되고 아이템 2개(이름/설명/버튼)가 정상 레이아웃으로 표시됨
    확인(`qa_out/event.png`). QA 전용 래퍼 `_debug_pick_first_for_attack()`을 추가해
    `scripts/qa_shot.sh event 30 qa_out/event_picked.png _debug_pick_first_for_attack`로
    "선택 -> 적용 -> 방 소비 -> 던전 맵 복귀" 흐름 전체를 검증: 결과 스크린샷에서
    "클리어한 방: 1 / 5"와 세 버튼 모두 "2번째 방"으로 정상 갱신됨을 확인
    (`qa_out/event_picked.png`). `scripts/qa_shot.sh combat_test 140`,
    `scripts/qa_shot.sh shop 30`으로 기존 씬 회귀 없음 재확인. 크래시 없음.
  - 다루지 않은 것: 아이템 강도/등장 빈도 밸런스(사람 피드백 필요), 방 선택지가
    항상 3개 고정으로 나열되는 구조를 무작위/기획된 조합으로 바꾸는 것(다음 할 일
    큐 1번), 순수 텍스트형 선택지 이벤트(전투/다이스와 무관한 이벤트)는 여전히 미착수.
- **2026-09-02**: INBOX.md 최우선 반영 — 커스터마이징 방식을 "값 더하기(+3, 상한
  없음)"에서 "값 교체(1..면 개수, 상한 있음)"로 변경. 사용자가 "주사위 눈으로
  커스터마이징 할때는 특정 값을 더하는 방식이 아닌, 특정 값으로 교체하는 방식.
  (4면체는 4를 넘어갈 수 없다)"고 명확히 지시함.
  - `scenes/combat_test.gd`: 기존 2단계(다이스 선택 → 면 선택, 클릭 즉시 +3 적용)를
    3단계로 변경: 다이스 선택(`_show_customize_picker`, 변경 없음) → 면 선택
    (`_show_face_picker`, 이제 클릭해도 값이 바로 안 바뀌고 다음 단계로만 이동 —
    버튼 문구도 "면 N: 현재값 -> 현재값+3"에서 "면 N: 현재값 V"로 단순화) → 값 선택
    (신규 `_show_value_picker`: 1부터 `faces.size()`까지 버튼을 나열하고, 현재 값과
    같은 버튼은 `disabled=true` + "[현재] N"으로 표시해 무의미한 재선택을 막음. 고르면
    `_on_face_value_chosen`이 `DiceBag.set_face_value()`로 직접 교체, 로그에도
    "-> N(으)로 교체"라고 남김).
  - 상한을 다이스의 "면 개수"(`faces.size()`)로 둔 이유: DiceBag 내부적으로 다이스는
    "면 개수"라는 별도 필드가 없고 면 값 배열 자체가 다이스를 표현하므로(예: D4는
    faces가 길이 4인 배열), "그 다이스가 표준 다이스일 때 가질 수 있는 최댓값"은 곧
    배열 길이와 같다. "다이스 승급" 아이템으로 면 개수 자체가 늘면(D4->D6 등) 이
    상한도 자동으로 함께 올라간다.
  - 기존 `FACE_BOOST_AMOUNT` 상수와 관련 QA 디버그 훅(`_on_face_boosted`)은 제거하고
    `_debug_open_face_picker`(면 선택 화면용)에 더해 `_debug_open_value_picker`(값
    선택 화면용)를 신규 추가함.
  - QA 검증: `scripts/qa_shot.sh combat_test 900 ... _show_customize_picker`로 1단계
    (다이스 목록) 회귀 없음 확인. `... _debug_open_face_picker`로 2단계(면 4개, 값
    미리보기 없이 "현재값 N"만 표시) 확인. `... _debug_open_value_picker`로 3단계
    (D4라서 값 1~4 버튼, 현재값 1은 비활성화된 "[현재] 1"로 표시, 최대 4로 정상 상한)
    확인. `scripts/qa_shot.sh dice_test 60`으로 `DiceItemPool`/`DiceBag` 관련 기존
    검증 스위트 회귀 없음(PASS) 재확인. 크래시 없음.
  - 다루지 않은 것: INBOX.md의 또 다른 신규 항목("주사위 눈을 이미지로 표시")은 별도
    작업이라 이번에 다루지 않음 — 다음 할 일 큐 12번에 추가함.
- **2026-09-02**: 이전 세션이 미커밋 상태로 작업트리에 남긴 "골드 + 상점 이벤트"
  (INBOX.md "승리하면 골드를 주며, 상점 이벤트에서 사용할 수 있다")를 QA로 검증하고
  레이아웃 버그를 고쳐 커밋함.
  - 구현 내용(세션 시작 시점에 이미 존재): `systems/run_state.gd`에 `gold: int` 추가.
    `scenes/combat_test.gd`가 몬스터 처치 시 `GOLD_REWARD_BASE=8 +
    GOLD_REWARD_PER_ROOM=2 * RunState.rooms_cleared` 만큼 골드를 지급하고 로그에 남김.
    `scenes/shop.gd`(+`.tscn`)는 기존 `DiceItemPool.ITEMS` 3종을 그대로 재사용해
    `ITEM_COSTS`(15/20/10 골드, 잠정값)로 가격을 매기고, 골드가 모자라면 버튼이
    "골드 부족"으로 비활성화됨. 구매 시 `RunState.gold`를 차감하고 선택한 주머니
    (공격/방어)에 `DiceItemPool.apply()`. `scenes/dungeon_map.gd`에 "상점 입장" 버튼과
    골드 라벨이 추가되어 매 방마다 "전투 방" / "상점" 중 고를 수 있음 (상점도 방
    하나를 소비 — 나갈 때 `rooms_cleared` 증가).
  - 이번 이터레이션에서 QA로 확인한 것: `scripts/qa_shot.sh dungeon_map`으로 골드
    라벨/상점 버튼 정상 표시 확인. `scripts/qa_shot.sh shop`으로 골드 0일 때 3개
    아이템 전부 "골드 부족"으로 비활성화되는 것 확인. `RunState.reset_run()`의 기본
    골드를 임시로 100으로 바꾸고 `shop.gd`의 QA 전용 훅 `_debug_buy_first_for_attack`을
    호출해 실제 구매(85골드로 감소, 버튼 재활성화)까지 확인한 뒤 기본값을 즉시 0으로
    되돌림. `scripts/qa_shot.sh combat_test 900`으로 승리 시 골드 획득 로그가 표시되는
    것도 확인.
  - **이번 이터레이션에서 고친 버그**: 승리 후 로그에 "골드 획득: +N" 줄이 추가되면서
    로그 줄 수(`MAX_LOG_LINES=7`)가 화면 세로 크기(720px)를 넘어가 마지막 1~2줄이
    화면 밖으로 잘려 안 보이는 문제를 발견함 (골드 획득 로그가 항상 마지막 줄이라 매번
    안 보였음). `combat_test.tscn`에서 `DiceViewportContainer`를 40px 줄이고
    (bottom 540->500), `NextButton`/`LogLabel`을 그만큼 위로 당겨(LogLabel
    top 598->556, bottom 715->720) 로그 영역을 넓히고, `MAX_LOG_LINES`도 7->6으로
    줄여 6줄이 전부 화면 안에 들어오도록 수정. `scripts/qa_shot.sh combat_test 900`으로
    "골드 획득: +8 (보유 8)" 줄이 화면 안에 완전히 보이는 것 확인, `140`(초반 프레임)으로
    다이스 뷰포트가 줄어든 크기에서도 정상 표시되는 것 재확인.
  - 다루지 않은 것: 가격/보상 밸런스(사람 피드백 필요, 다음 할 일 큐 1번), 상점 UI를
    카드형 등으로 다듬는 것.
- **2026-09-02**: 이전 이터레이션에서 미커밋 상태로 남아있던 "다이스 개조(빌드업)
  아이템 시스템 첫 버전"(`systems/dice_item_pool.gd`, `dice_bag.gd`의 faces 배열화,
  `run_state.gd`의 플레이어 주머니 보관, `combat_test.gd`의 보상 화면)을 QA로 재검증
  (`scripts/qa_shot.sh combat_test 900`으로 승리 보상 화면이 정상 표시되는지 확인)한
  뒤 커밋함. 세션 시작 시점에 `git status`에 이미 이 변경들이 스테이징 안 된 상태로
  있었음 — 코드 자체는 정상 동작했으나 이전 세션이 커밋을 빼먹은 것으로 보임.
- **2026-09-02**: INBOX.md 최우선 반영 — 다이스 "커스터마이징"(특정 다이스의 특정
  면을 직접 골라 강화) 기능 구현.
  - `scenes/combat_test.gd`: 승리 보상 화면에 세 번째 선택지 "커스터마이징: 다이스
    눈금 직접 강화" 버튼을 추가. 누르면 `_show_customize_picker()`(1단계: 공격/방어
    주머니의 다이스 목록을 버튼으로 나열, 각 버튼에 현재 면 값 배열을 `[1, 2, 3, 4]`
    형태로 표시) → `_show_face_picker()`(2단계: 고른 다이스의 면들을 버튼으로 나열,
    `"면 N: 현재값 -> 현재값+3"` 형태로 미리보기 표시) 순서로 진행하고, 면을 클릭하면
    `DiceBag.set_face_value()`로 즉시 반영. 각 단계에 "뒤로" 버튼으로 이전 단계 복귀 가능.
  - 기존에 매번 새로 `DiceItemPool.random_choices(2)`를 호출하던 것을 `_reward_items`
    인스턴스 변수에 저장해두고 재사용하도록 바꿈 (커스터마이징 화면에서 "뒤로"로
    최초 보상 화면에 돌아왔을 때 아이템 2개가 바뀌어 보이지 않게 하기 위함).
  - `FACE_BOOST_AMOUNT := 3`, 상한 없음 — INBOX.md의 "중요: 사기 주사위를 만드는
    재미가 있도록 한다"를 반영해 반복 적용 시 계속 누적되게 의도적으로 설계함
    (밸런스 적정성은 사람 피드백 필요, 다음 할 일 큐 3번 참고).
  - QA 검증용으로 `qa/visual_qa.gd`에 `GAME_QA_CALL`(선택) 환경변수를 추가하고
    `scripts/qa_shot.sh`에 4번째 인자로 노출함 — 캡처 직전 현재 씬에서 인자 없는
    메서드를 직접 호출해서, 클릭을 흉내낼 수 없는 자동 QA로도 버튼 뒤의 하위 화면을
    스크린샷으로 확인할 수 있게 하는 범용 기능(이 씬 전용이 아님, 다른 다단계 UI에도
    재사용 가능). `combat_test.gd`에 QA 전용 인자 없는 래퍼 `_debug_open_face_picker()`
    (내부적으로 `_show_face_picker(RunState.player_attack_bag, 0)` 호출)도 추가함.
  - QA 검증: `scripts/qa_shot.sh combat_test 900 qa_out/combat_test_reward.png` —
    보상 화면에 새 "커스터마이징" 버튼 정상 표시 확인. `... _show_customize_picker`로
    1단계(다이스 6개 목록, 면 값 정상 표시) 확인. `... _debug_open_face_picker`로
    2단계(면 4개 버튼, "면 N: 값 -> 값+3" 정상 표시) 확인. `scripts/qa_shot.sh
    dungeon_map 30`으로 회귀 없음 재확인. 크래시 없음.
  - 다루지 않은 것: INBOX.md의 "강화 카드" 표현이 시사하는 카드형 비주얼(지금은 버튼
    목록), 커스터마이징 적용 빈도/강도 밸런스, 나머지 INBOX 항목들(캐릭터 선택,
    몬스터 스프라이트/표정, 골드/상점, 몬스터 성격/다이스 특징, 다단계 스테이지
    분기) — 전부 다음 할 일 큐에 번호를 붙여 남겨둠.

- **2026-09-01**: 큐 "다이스 판정 로직 (순수 GDScript)" 완료.
  - `res://systems/dice_bag.gd`: `class_name DiceBag`, `_init(sides, count)` + `roll()`
    (매번 count개 전부 새로 굴려 합계 반환 — DESIGN.md의 "재보충형" 규칙 반영).
    `min_possible()` / `max_possible()` 헬퍼도 추가.
  - `res://systems/combat_math.gd`: `class_name CombatMath`,
    `calculate_damage(attack_total, defense_total) = max(0, attack_total - defense_total)`.
  - `res://scenes/dice_test.tscn` + `dice_test.gd`: 시각 요소는 최소화하고, DESIGN.md
    확정 수치(플레이어 공격/방어 D4x3, 몬스터 공격 D4x2/방어 D4x1)로 300회 반복
    값 범위 검증(min/max가 이론적 범위 안에 있는지)과 데미지 공식 3가지 케이스
    (일반/역전/동률)를 검증해 화면에 텍스트로 출력.
    `scripts/qa_shot.sh dice_test 60`으로 스크린샷 확인, 전부 "OK"/"PASS"
    (`qa_out/dice_test.png`). `class_name`으로 선언했기 때문에 다른 씬에서
    `DiceBag.new(...)` / `CombatMath.calculate_damage(...)`로 바로 재사용 가능
    (autoload나 별도 preload 불필요).
- **2026-09-01**: 큐 1번 "2D+3D 혼합 파이프라인 검증" 완료.
  - `scenes/dungeon.tscn`을 SubViewportContainer(2D) + SubViewport(3D, transparent_bg=true)
    구조로 재작성. 3D 쪽에 Camera3D, DirectionalLight3D, WorldEnvironment(ambient light),
    StaticBody3D 바닥, RigidBody3D 박스 다이스(초기 위치/속도로 굴러떨어지게 설정)를 배치.
  - `scripts/qa_shot.sh dungeon 150` 으로 스크린샷 검증: 2D 배경/라벨 위에 3D 다이스가
    바닥에 굴러 떨어져 안착한 모습이 정상 합성됨 (`qa_out/dungeon.png`).
  - `qa/visual_qa.gd`의 사전 버그 수정: autoload `_ready`에서 `change_scene_to_file`을
    즉시 호출하면 엔진이 메인 씬을 트리에 추가하는 중이라 "Parent node is busy
    adding/removing children" 에러가 발생함. `await get_tree().process_frame`으로
    한 프레임 지연 후 호출하도록 수정 (기존에는 에러가 나도 스크린샷 저장 자체는
    성공했지만, 잠재적으로 더 복잡한 씬에서는 문제가 될 수 있어 근본 수정).
- **2026-09-01**: 큐 1번 "다이스 하나의 물리 프리팹 (재질: 플라스틱)" 완료.
  - `res://dice/die_d4.gd`(`class_name DieD4 extends RigidBody3D`): 정사면체 정점 4개를
    정의하고 `SurfaceTool`로 메시(면별 flat normal)를, `ConvexPolygonShape3D`로 충돌
    모양을 코드에서 생성 (`_build_mesh_and_collision()`). Godot 기본 Mesh 프리미티브에는
    정사면체가 없어서 코드 생성 방식을 택함.
  - `res://dice/dice_material.gd`(`class_name DiceMaterial extends Resource`):
    material_name/bounce/friction/impact_sound 필드. `res://dice/materials/plastic.tres`를
    기본 재질(bounce=0.3, friction=0.6)로 추가. `_apply_material()`에서 `PhysicsMaterial`을
    만들어 `physics_material_override`에 꽂음.
  - 충돌 사운드 배선: `body_entered` 시그널(`contact_monitor=true`) + 충돌 속도 임계값
    (0.5) + 쿨다운(0.08초)으로 스팸 방지 후 `AudioStreamPlayer3D.play()` 호출.
    **impact_sound가 비어 있으면(현재 plastic.tres가 그 상태) 조용히 스킵** — 사운드
    에셋이 아직 없어서 "배선만" 맞춘 상태 (STATUS.md 이전 큐 설명 그대로).
  - `res://dice/die_d4.tscn`으로 프리팹화하고, `scenes/dungeon.tscn`의 플레이스홀더
    박스 다이스를 이 프리팹 인스턴스로 교체.
  - `scripts/qa_shot.sh dungeon 150` 실행 결과 크래시/에러 없이 스크린샷 저장 성공,
    화면에서 정사면체(뾰족한 삼각뿔) 모양 다이스가 바닥에 굴러떨어져 안착한 모습 확인
    (`qa_out/dungeon.png`).
- **2026-09-01**: 큐 "던전 맵 허브 + 전투 후 복귀 흐름" 검증 및 인수인계 완료.
  (구현 자체는 세션 시작 시점에 이미 커밋되지 않은 상태로 작업트리에 존재했음 — 이번
  이터레이션에서 내용을 읽고 실제로 동작하는지 QA로 검증한 뒤 인수인계 문서화 및 커밋을
  완료함.)
  - `res://scenes/dungeon_map.gd`(+`.tscn`): "클리어한 방: N" 라벨과 "전투 방 입장"
    버튼 하나로 구성된 최소 던전 허브. 버튼을 누르면 `combat_test.tscn`으로 전환.
  - `res://systems/run_state.gd`: autoload `RunState` (`rooms_cleared: int`,
    `reset_run()`). 씬 전환 사이에도 값이 유지되도록 `project.godot`에 autoload로 등록.
  - `combat_test.gd`: 승/패 판정 직후 `NextButton`을 표시(`player_won`이면
    "던전으로 돌아가기", 지면 "처음부터 다시")하고, 누르면 승리 시
    `RunState.rooms_cleared += 1`, 패배 시 `RunState.reset_run()` 후 양쪽 다
    `dungeon_map.tscn`으로 전환. 다이스 뷰포트 높이를 살짝 줄이고 로그 위치를 내려서
    버튼이 들어갈 공간을 확보(레이아웃 조정).
  - `project.godot`: `run/main_scene`을 `dungeon_map.tscn`으로 변경.
  - QA 검증: `scripts/qa_shot.sh dungeon_map 30` — 던전 맵이 정상 로드되고 레이아웃
    안 깨짐 확인 (`qa_out/dungeon_map.png`). `scripts/qa_shot.sh combat_test 900` —
    전투가 끝까지 진행되어 "승리!" 문구, 최종 HP(20/20 vs 0/10), 로그, "던전으로
    돌아가기" 버튼이 모두 정상 표시됨 확인 (`qa_out/combat_test_endcheck.png`).
    또한 `scripts/qa_shot.sh combat_test 1500` 실행 중(실제 창이 뜬 상태로 약 25초간
    유지되는 동안) 우발적으로 버튼이 클릭되어 실제로 `dungeon_map`으로 정상 전환되고
    `RunState.rooms_cleared`가 1로 증가한 화면까지 확인됨 — 즉 클릭 → 씬 전환 →
    상태 유지 배선이 실제로 동작함을 우연히 재확인. 크래시 없음.

- **2026-09-01**: 큐 1 "던전 맵 내용 채우기"의 일부(런 길이/완료 화면)를 완료.
  - `res://systems/run_state.gd`: `const TOTAL_ROOMS := 5`(잠정값, DESIGN.md에는
    "미정"으로 남아있는 값이라 코드 주석에도 잠정임을 명시함), `is_run_complete()`
    헬퍼 추가 (`rooms_cleared >= TOTAL_ROOMS`).
  - `res://scenes/dungeon_map.gd`: `_update_labels()`가 `is_run_complete()`에 따라
    분기 — 진행 중이면 "클리어한 방: N / 5" + 버튼 "전투 방 입장 (N+1번째 방)",
    완료면 "던전 클리어! (5 / 5 방 격파)" + 버튼 "새 런 시작". 버튼 핸들러
    (`_on_button_pressed`, 기존 `_on_enter_combat_pressed`에서 이름 변경)도 상태에
    따라 전투 씬 전환 또는 `RunState.reset_run()` 후 같은 화면 갱신으로 분기.
  - `res://scenes/dungeon_map.tscn`: 버튼 폭이 좁아서(200px) "전투 방 입장
    (N번째 방)"처럼 길어진 텍스트가 잘릴 수 있어 340px로 넓힘 (offset_left
    540→470, offset_right 740→810).
  - QA 검증: `scripts/qa_shot.sh dungeon_map 30`으로 초기 상태("클리어한 방: 0 / 5",
    버튼 "전투 방 입장 (1번째 방)") 확인 (`qa_out/dungeon_map.png`, 텍스트 안 잘림).
    완료 화면은 `run_state.gd`의 `rooms_cleared` 기본값을 임시로 5로 바꿔
    `scripts/qa_shot.sh dungeon_map 30 qa_out/dungeon_map_complete.png`로 확인 후
    ("던전 클리어! (5 / 5 방 격파)" + "새 런 시작" 버튼 정상 표시,
    `qa_out/dungeon_map_complete.png`) 즉시 기본값을 0으로 되돌리고 재확인함.
    `scripts/qa_shot.sh combat_test 900`으로 전투 흐름(승리 후 `NextButton`)도
    회귀 없음을 재확인. 크래시 없음.
  - 상점/선택지 방, 방마다 다른 몬스터 등은 이번에 다루지 않음 (다음 할 일 큐 참고).

- **2026-09-01**: 큐 1 "던전 맵 내용 채우기"의 일부(방마다 다른 몬스터)를 완료.
  - `res://scenes/combat_test.gd`: 몬스터 HP/공격 주머니/방어 주머니를 상수로 하드코딩하던
    것을 `_monster_config_for_room(room_index)` 함수로 바꿈. `room_index`는
    `RunState.rooms_cleared`를 그대로 사용 (몇 번째 방인지). 공식(잠정값, DESIGN.md에
    "미정"으로 명시): `attack_count = 2 + floor(room_index / 2)`,
    `defense_count = 1 + floor(room_index / 3)`, `max_hp = 10 + room_index * 3`.
    `room_index=0`(1번째 방)일 때 공격 2D4/방어 1D4/HP10으로, DESIGN.md에 확정된
    첫 몬스터 수치와 정확히 일치하도록 만들어 기존 검증(첫 방 전투)이 깨지지 않게 함.
    `monster_hp`/`monster_max_hp`는 이제 `_ready()`에서 계산되는 변수로 바뀜
    (기존 `const MONSTER_MAX_HP := 10`은 제거).
  - QA 검증: `scripts/qa_shot.sh combat_test 140` — 기본 상태(`RunState.rooms_cleared=0`,
    즉 1번째 방)에서 몬스터 HP가 여전히 10으로 표시되고 전투가 정상 진행됨을 확인
    (`qa_out/combat_test.png`, 회귀 없음). `RunState.rooms_cleared` 기본값을 임시로
    4(5번째 방)로 바꿔 `scripts/qa_shot.sh combat_test 140 qa_out/combat_test_room5.png`로
    확인 — 몬스터 HP가 22(=10+4*3)로 정상 표시되고, 로그에 찍힌 "몬스터 방어 4"가 방어
    주사위 2개(1+floor(4/3)=2)로 낼 수 있는 값 범위(2~8) 안에 있음을 확인. 확인 직후
    기본값을 다시 0으로 되돌리고 `scripts/qa_shot.sh dungeon_map 30`으로 던전 맵
    회귀도 재확인. 크래시 없음.
  - 다루지 않은 것: 몬스터별 시각적 구분(모양/색/이름), 난이도 곡선이 실제로 적당한지
    사람 판단, 상점/선택지 방 종류 (다음 할 일 큐 참고).

- **2026-09-01**: 큐 1 "던전 맵 내용 채우기"의 일부(몬스터별 이름/다이스 색)를 완료.
  - `res://dice/die_d4.gd`(`DieD4`)에 `@export var color_override: Color = Color(0,0,0,0)`
    추가. `_build_mesh_and_collision()`에서 메시를 만든 직후 `color_override.a > 0`이면
    `StandardMaterial3D(albedo_color=color_override)`를 만들어 `_mesh_instance.material_override`에
    꽂는다 (알파 0이면 기존처럼 기본 흰색 계열 그대로 — 플레이어 다이스는 이 상태를 유지).
    인스턴스 생성 후 `add_child()`로 씬 트리에 넣기 *전에* `color_override`를 먼저
    설정해야 `_ready()`에서 값을 읽어 반영됨 (순서 중요).
  - `res://scenes/combat_test.gd`: `MONSTER_PROFILES` 상수 배열 추가 (이름 5종:
    슬라임/고블린/해골 전사/오크/다크 나이트 + 각각 다이스 색). `_monster_config_for_room()`이
    이제 `room_index % MONSTER_PROFILES.size()`로 프로필을 고르고, 배열을 다 돌면
    (`TOTAL_ROOMS=5`인 지금은 room_index가 0~4라서 실제로는 발생 안 하지만, 나중에
    `TOTAL_ROOMS`가 늘어날 경우를 대비) 이름 앞에 "강화 "를 순환 횟수만큼 붙임.
    반환 dict에 `name`/`color` 필드 추가, `monster_name`/`monster_color` 변수에 저장.
  - `_do_exchange()`에서 어느 쪽이 "몬스터의 주머니"인지 판별해(공격턴이면 방어 다이스가
    몬스터 것, 방어턴이면 공격 다이스가 몬스터 것) `_spawn_dice()`에 몬스터 색 또는
    기본값(알파 0, 즉 무색)을 넘기도록 수정. 플레이어 다이스는 항상 기본 흰색 유지.
  - `_update_labels()`의 몬스터 HP 텍스트를 `"몬스터 HP: ..."` 고정 문자열에서
    `"%s HP: ..." % monster_name`으로 변경.
  - QA 검증: `scripts/qa_shot.sh combat_test 140` — 기본 상태(1번째 방, "슬라임")에서
    "슬라임 HP: 5 / 10"처럼 이름이 정상 표시되고, 몬스터 방어 다이스(오른쪽)만 초록색으로
    물든 것 확인 (`qa_out/combat_test.png`). `run_state.gd`의 `rooms_cleared` 기본값을
    임시로 4(5번째 방)로 바꿔 `scripts/qa_shot.sh combat_test 140 qa_out/combat_test_room5.png`
    실행 — "다크 나이트 HP: 15 / 22"로 이름/색(보라)이 정상 반영되고 라벨 폭(340px,
    우측 정렬)에 텍스트가 잘리지 않음을 확인. 확인 직후 기본값을 0으로 되돌리고
    `scripts/qa_shot.sh combat_test 140`, `scripts/qa_shot.sh dungeon_map 30`으로
    회귀 없음 재확인 (몬스터 이름/색 원상복구, 던전 맵 "0 / 5" 정상). 크래시 없음.
  - 다루지 않은 것: 몬스터별로 다른 다이스 "모양"(현재는 전부 D4 정사면체), 상점/선택지
    방 종류, 난이도 곡선이 실제로 적당한지 사람 판단 (다음 할 일 큐 참고).

## 알려진 이슈 / 막힌 것

- **`qa_customize_shot.sh`라는 잡파일이 프로젝트 루트에 untracked 상태로 남아있음.**
  이번 이터레이션에서 QA 목적으로 임시로 만들었다가 삭제하려 했으나, 이 세션의 실행
  환경(샌드박스)이 `rm`/`Remove-Item` 등 삭제 명령 자체를 차단해서 지우지 못했음
  (커밋에는 포함하지 않았으므로 git 이력에는 안 남음). 사람이 직접 파일 탐색기나
  터미널로 지워도 무방함 — 코드에서 참조하는 곳 없음.
- `loop/loop.sh`가 이번 세션 시작 시점 대비 수정되어 있었음(`ITER_TIMEOUT` 관련
  타임아웃 처리 추가) — AI가 만든 변경이 아니라 세션을 반복 실행하는 외부 루프
  하네스 자체의 변경으로 보임. 이번 커밋 범위에서 제외함 (AI 작업 범위 밖).
- 물리 시뮬레이션 특성상 다이스가 멈추는 시점이 매번 달라짐 → `GAME_QA_FRAME`을
  고정값으로 쓰면 다이스가 아직 구르는 중일 수 있음 (QA 스크린샷 자체는 여전히 고정
  프레임에 찍으므로, 어느 시점을 찍든 "게임 진행 중인 어느 한 순간"을 보게 될 뿐 —
  게임 로직 자체는 정지 감지로 실제 정지 후 진행하므로 문제 없음). 정지 감지는
  구현 완료(`combat_test.gd`의 `_wait_for_dice_to_settle()`), 임계값은 초기값이라
  다이스 개수가 늘어나면 재검증 필요 (위 큐 1 참고).
- **물리 다이스의 착지 면과 실제 판정값이 무관함.** `combat_test.gd`는 화면에 굴러가는
  `DieD4`를 순수 연출로만 쓰고, 실제 공격/방어 합계는 `DiceBag.roll()`의 RNG로 별도
  계산한다 (물리 다이스가 어느 면으로 착지했는지 읽는 기능이 없음 — D4 정사면체는
  "위를 향한 면"이 모호해서 판독 자체가 까다로움). 플레이어가 보기에 "다이스 눈이랑
  로그의 숫자가 안 맞는다"고 느낄 수 있음. 사람이 실제로 플레이해보고 위화감이 있는지
  INBOX.md에 남겨줘야 판단 가능한 영역.
- `res://scenes/dungeon.tscn`은 2D+3D 파이프라인 검증용 스파이크 씬으로 남아있고,
  `res://scenes/combat_test.tscn`이 새로 전투 전용 씬으로 분리됨. 던전 방 이동 등
  본게임 구조가 생기면 두 씬의 이름/역할을 정리해야 함.
- D4 충돌 사운드는 배선만 되어 있고 실제 재생되는 소리가 없음 (`plastic.tres`의
  `impact_sound`가 비어 있음). 플레이스홀더든 실제 에셋이든 `.wav`/`.ogg` 파일을 구해서
  `res://dice/materials/plastic.tres`의 `impact_sound`에 채워 넣으면 바로 재생됨
  (`die_d4.gd` 쪽 코드 수정 불필요). 사람이 실제로 들어봐야 하는 부분이라 사운드
  손맛 자체는 사람 판단(INBOX.md) 영역으로 넘어갈 가능성이 큼.
- ~~전투가 끝나면(승/패) 화면이 그 상태로 멈춘 채 끝남~~ → 해결됨. 승/패 후
  `NextButton`으로 `dungeon_map.tscn`으로 돌아갈 수 있음 (위 완료 기록 참고).
- `scripts/qa_shot.sh`는 `--headless`를 쓰지 않고 실제 창을 띄운다. `GAME_QA_FRAME`을
  크게 잡아(예: 1500) 창이 화면에 오래(수십 초) 떠 있으면, 그동안 마우스가 실제로
  클릭 가능한 버튼 위에 있을 경우 우발적으로 클릭되어 씬이 전환될 수 있음 (이번
  이터레이션에서 실제로 겪음 — 다만 결과적으로 버튼 동작 검증에는 도움이 됐음).
  QA 목적이라면 필요한 최소 프레임만 쓰는 것이 안전.
- ~~던전 맵에는 아직 "전투 방" 하나만 있고 반복 재입장만 가능함~~ → 부분 해결됨.
  이제 "전투 방" / "상점" 2개 선택지가 있음. 비전투 선택지 이벤트, 3번째 이상의 방
  종류는 여전히 미구현 (다음 할 일 큐 1, 11번 참고).

---
*이 파일 갱신을 건너뛰면 다음 세션은 아무 기억 없이 처음부터 다시 파악해야 한다.
반드시 "무엇을 했고, 무엇이 남았고, 어디서 막혔는지"를 남길 것.*
