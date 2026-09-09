class_name DiceBag
extends RefCounted
## 다이스 주머니: 개별 다이스(각각 "면 값 배열"을 가짐) 여러 개를 묶어서 관리한다.
##
## DESIGN.md 규칙: "다이스 눈의 합계를 그대로 사용한다" — 족보/슬롯 배치 없음.
## 공격 주머니와 방어 주머니는 각각 이 클래스의 별도 인스턴스로 표현한다.
##
## 다이스 개조(빌드업, DESIGN.md "빌드업" 섹션) 지원을 위해 "면 개수(sides)"만이 아니라
## 다이스별 "면 값 배열(faces)"을 저장한다. 기본 생성 시에는 1..sides 값의 표준
## 다이스지만, set_face_value()로 특정 면의 값을 올리거나(예: 1을 6으로), replace_die()로
## 다이스 자체를 다른 면 개수로 교체하거나(6면체 -> 8면체), add_die()로 새 다이스를
## 주머니에 추가할 수 있다.

var dice: Array[PackedInt32Array] = []

## INBOX.md 2026-09-09 "성장의 재미가 없다" 피드백 방향 1: 다이스 개수를 계속 늘리는
## 대신 고정된 풀 안에서 다이스/눈금을 교체하는 방식으로 성장을 표현한다. 그 전제로
## "주머니 하나에 다이스가 몇 개까지 들어갈 수 있는지" 상한이 필요함 — 시작 3개(공격/
## 방어 각각 D4x3, DESIGN.md)의 2배인 6개로 잠정 설정. 정확한 캡 수치가 적당한지는
## 사람이 실제로 5방 런을 플레이해보고 판단해야 하는 영역(밸런스 수치라 임의값으로
## 둔다는 기존 합의를 따름).
const MAX_DICE := 6


func _init(p_sides: int = 0, p_count: int = 0) -> void:
	for i in p_count:
		add_die(p_sides)


## 주머니가 캡(MAX_DICE)에 도달해 더 이상 다이스를 추가할 수 없는지 확인한다.
func is_full() -> bool:
	return dice.size() >= MAX_DICE


## 주머니 전체를 굴려 눈의 합계를 반환한다 (재보충형: 매번 전체 다이스를 새로 굴림).
func roll() -> int:
	var total := 0
	for v in roll_detailed():
		total += v
	return total


## roll()과 동일하게 주머니 전체를 굴리되, 합계 대신 다이스별 개별 결과값을
## dice와 같은 순서의 배열로 반환한다. 전투 UI에서 "어떤 다이스가 어떤 값을
## 냈는지"를 시각적으로 보여주기 위해 추가함(INBOX.md 2026-09-03 피드백).
func roll_detailed() -> Array:
	var values: Array = []
	for faces in dice:
		values.append(faces[randi_range(0, faces.size() - 1)])
	return values


## 새 다이스를 주머니에 추가한다 (면 값은 1..sides 표준 구성).
func add_die(sides: int) -> void:
	var faces := PackedInt32Array()
	for f in range(1, sides + 1):
		faces.append(f)
	dice.append(faces)


## die_index번째 다이스를 다른 면 개수(new_sides)의 표준 다이스로 통째로 교체한다.
func replace_die(die_index: int, new_sides: int) -> void:
	var faces := PackedInt32Array()
	for f in range(1, new_sides + 1):
		faces.append(f)
	dice[die_index] = faces


## die_index번째 다이스의 face_index번째 면 값을 value로 바꾼다.
func set_face_value(die_index: int, face_index: int, value: int) -> void:
	dice[die_index][face_index] = value


## 몬스터 특이 다이스 특징(INBOX.md 2026-09-09 예시: "모든 주사위 눈이 min과 max로만
## 이루어져 있다 — 중간값 없음, 하이리스크/로우리스크") 구현. 각 다이스의 면 개수는
## 그대로 두고, 면 값만 절반은 최솟값(1)·절반은 최댓값(sides)으로 강제해 중간값을
## 없앤다(면 개수가 홀수면 최댓값 쪽에 하나 더 배정). 굴림 결과가 평균값 근처로
## 몰리지 않고 항상 둘 중 하나로 크게 갈려서, 같은 기댓값이라도 "무난함"이 없는
## 성향을 만든다.
func force_min_max_faces() -> void:
	for d in dice.size():
		var faces := dice[d]
		var n := faces.size()
		if n == 0:
			continue
		var min_v: int = faces[0]
		var max_v: int = faces[0]
		for v in faces:
			min_v = min(min_v, v)
			max_v = max(max_v, v)
		var min_count := n / 2
		for i in n:
			dice[d][i] = min_v if i < min_count else max_v


## 몬스터 특이 다이스 특징(INBOX.md 2026-09-09 예시: "주사위 값 x가 고정 데미지로
## 들어간다 — 굴리지 않고 항상 같은 값"). 각 다이스의 면 개수는 그대로 두고 모든 면 값을
## value로 통일한다 — roll_detailed()가 randi_range로 면 "인덱스"를 고르는 기존 구조를
## 그대로 두어도, 모든 인덱스가 같은 값이면 결과적으로 "굴리지 않고 항상 같은 값"과
## 동일한 효과를 낸다(별도 상태/플래그 추가 없이 기존 API 조합만으로 구현 가능 —
## force_min_max_faces()와 같은 접근).
func force_fixed_value(value: int) -> void:
	for d in dice.size():
		for i in dice[d].size():
			dice[d][i] = value


var count: int:
	get:
		return dice.size()


func min_possible() -> int:
	var total := 0
	for faces in dice:
		var m: int = faces[0]
		for v in faces:
			m = min(m, v)
		total += m
	return total


func max_possible() -> int:
	var total := 0
	for faces in dice:
		var m: int = faces[0]
		for v in faces:
			m = max(m, v)
		total += m
	return total
