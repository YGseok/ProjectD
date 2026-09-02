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


func _init(p_sides: int = 0, p_count: int = 0) -> void:
	for i in p_count:
		add_die(p_sides)


## 주머니 전체를 굴려 눈의 합계를 반환한다 (재보충형: 매번 전체 다이스를 새로 굴림).
func roll() -> int:
	var total := 0
	for faces in dice:
		total += faces[randi_range(0, faces.size() - 1)]
	return total


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
