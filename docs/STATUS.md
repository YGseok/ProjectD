# STATUS.md — 인수인계 문서

> 매 이터레이션 시작 시 DESIGN.md, 이 파일, INBOX.md 순으로 읽는다.
> 매 이터레이션 종료 시 이 파일을 "다음 사람(다음 세션)"에게 인수인계하듯 갱신한다.

## 마지막 갱신

- 일시: 2026-09-01
- 작성자: AI 에이전트 (큐: 다이스 판정 로직(순수 GDScript) 구현 완료)

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
- 지금 다이스는 박스(정육면체) 모형 + 플레이스홀더 흰색 재질일 뿐, 실제 D4/재질별 사운드는
  아직 없음 (큐 1, 2에서 다룸).

## 다음 할 일 큐 (우선순위 순)

이 순서를 반드시 지킬 필요는 없지만, 앞 단계가 뒤 단계의 전제가 되므로 대체로 순서대로
진행하는 것을 권장한다. 한 이터레이션에 한두 개만 진행할 것.

1. **다이스 하나의 물리 프리팹 (재질: 플라스틱)**
   - `res://dice/die_d4.tscn`: RigidBody3D + 충돌 시 사운드(플라스틱 재질) 재생.
   - 바닥에 떨어지고, 굴러가고, 서로 부딪히면 소리가 나는지 확인.
   - (사운드 에셋이 없다면 임시 플레이스홀더 사운드로 우선 배선만 맞추고, 나중에 교체)
   - 지금 `scenes/dungeon.tscn`에 있는 박스 다이스는 스파이크용 플레이스홀더이므로,
     이 작업에서 정식 D4 프리팹으로 교체/재사용할 것.

2. **전투 씬 1차 버전 (플레이어 vs 테스트 몬스터)**
   - DESIGN.md 수치 그대로 하드코딩해서 시작:
     플레이어 공격 D4x3 / 방어 D4x3 / HP 20, 몬스터 공격 D4x2 / 방어 D4x1 / HP 10.
   - 턴 순서: 내 공격턴 → 몬스터 공격턴(내 방어턴) → 반복, HP 0이면 종료.
   - 최소 UI: 양쪽 HP 표시, 현재 턴 표시, 굴린 다이스 합계 표시.
   - 판정 로직은 이미 있는 `res://systems/dice_bag.gd`(`DiceBag`)와
     `res://systems/combat_math.gd`(`CombatMath.calculate_damage`)를 그대로 재사용할 것
     (새로 만들지 말 것).
   - `GAME_START=dungeon` (또는 별도 씬 이름으로 분리 — 예: `combat_test`)으로
     시각 QA 가능하게 연결.

3. **위 2개가 안정되면 이후 큐 항목을 이 파일에 추가** (상점/이벤트, 방 이동, 아트 등).

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

## 알려진 이슈 / 막힌 것

- 물리 시뮬레이션 특성상 다이스가 멈추는 시점이 매번 달라짐 → `GAME_QA_FRAME`을
  고정값으로 쓰면 다이스가 아직 구르는 중일 수 있음. 이번 스파이크는 경험적으로
  frame=150 (기본값 60이 아님, `qa_shot.sh dungeon 150`으로 호출)이면 충분히 멈춘
  상태를 잡을 수 있었음. 다이스 개수가 늘어나면(전투 씬에서는 여러 개가 동시에 굴러감)
  더 늘려야 할 수 있음. "정지 감지" 방식은 아직 미구현 — 큐 2번(전투 씬) 진행 시 필요성
  재평가할 것.
- `res://scenes/dungeon.tscn`은 지금 스파이크/전투 테스트용 단일 씬으로 쓰고 있음.
  실제 던전 방 이동 등 본게임 구조가 생기면 이름/역할을 다시 정리해야 함 (큐 3번 이후).

---
*이 파일 갱신을 건너뛰면 다음 세션은 아무 기억 없이 처음부터 다시 파악해야 한다.
반드시 "무엇을 했고, 무엇이 남았고, 어디서 막혔는지"를 남길 것.*
