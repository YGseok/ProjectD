# STATUS.md — 인수인계 문서

> 매 이터레이션 시작 시 DESIGN.md, 이 파일, INBOX.md 순으로 읽는다.
> 매 이터레이션 종료 시 이 파일을 "다음 사람(다음 세션)"에게 인수인계하듯 갱신한다.

## 마지막 갱신

- 일시: 2026-09-01
- 작성자: AI 에이전트 (큐 1: 전투 씬 1차 버전(플레이어 vs 테스트 몬스터) 구현 완료)

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

## 다음 할 일 큐 (우선순위 순)

이 순서를 반드시 지킬 필요는 없지만, 앞 단계가 뒤 단계의 전제가 되므로 대체로 순서대로
진행하는 것을 권장한다. 한 이터레이션에 한두 개만 진행할 것.

1. **전투 씬 다듬기 / 후속 검토**
   - 지금은 사람이 실제로 플레이해봐야 판단 가능한 부분이 많음 (INBOX.md 피드백 대기):
     교환당 대기시간(2.2초+0.8초)이 적당한지, 다이스 개수가 늘어도 안 겹치고 잘 보이는지,
     "물리 다이스 눈 ≠ 실제 판정값" 불일치가 체감상 이상한지 등.
   - 다이스 "정지 감지" 여전히 미구현 (고정 시간 대기 방식). 다이스 개수가 더 늘어나는
     다음 단계(예: 아이템으로 다이스 추가) 전에 재검토 필요.
   - 승/패 이후 화면이 멈춘 채로 끝남 (재시작/다음 방 이동 없음) — 던전 루프와 연결되면
     처리 필요.
2. **상점/이벤트, 방 이동 등 던전 루프 연결** — 지금은 전투 단독 테스트 씬만 있음.
3. **다이스 개조(빌드업) 아이템 시스템** — DESIGN.md의 핵심 재미 축이지만 아직 손대지 않음.
4. **사운드 에셋 실제 교체** — `res://dice/materials/plastic.tres`의 `impact_sound`가
   비어있어 배선만 되어 있고 소리는 안 남 (사람이 실제로 들어야 판단 가능한 영역).

## 완료 기록

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

## 알려진 이슈 / 막힌 것

- 물리 시뮬레이션 특성상 다이스가 멈추는 시점이 매번 달라짐 → `GAME_QA_FRAME`을
  고정값으로 쓰면 다이스가 아직 구르는 중일 수 있음. `combat_test.gd`는 이 문제를
  "정지 감지" 대신 교환마다 고정 시간(`EXCHANGE_SETTLE_TIME=2.2초`) 대기로 우회함.
  다이스 개수가 더 늘어나면(아이템으로 주머니에 다이스 추가 등) 이 값을 늘리거나
  실제 정지 감지(예: `linear_velocity`/`angular_velocity`가 임계값 이하로 N프레임
  유지되면 정지로 판단)를 구현해야 할 수 있음. 아직 미구현.
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
- 전투가 끝나면(승/패) 화면이 그 상태로 멈춘 채 끝남. 재시작이나 다음 화면으로의
  전환은 아직 없음 (던전 루프가 생기기 전까지는 우선순위 낮음).

---
*이 파일 갱신을 건너뛰면 다음 세션은 아무 기억 없이 처음부터 다시 파악해야 한다.
반드시 "무엇을 했고, 무엇이 남았고, 어디서 막혔는지"를 남길 것.*
