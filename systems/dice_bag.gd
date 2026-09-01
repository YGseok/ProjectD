class_name DiceBag
extends RefCounted
## 다이스 주머니: 같은 면 개수(sides)의 다이스 여러 개(count)를 묶어서 관리한다.
##
## DESIGN.md 규칙: "다이스 눈의 합계를 그대로 사용한다" — 족보/슬롯 배치 없음.
## 공격 주머니와 방어 주머니는 각각 이 클래스의 별도 인스턴스로 표현한다.

var sides: int
var count: int


func _init(p_sides: int, p_count: int) -> void:
	sides = p_sides
	count = p_count


## 주머니 전체를 굴려 눈의 합계를 반환한다 (재보충형: 매번 count개 전부 새로 굴림).
func roll() -> int:
	var total := 0
	for i in count:
		total += randi_range(1, sides)
	return total


func min_possible() -> int:
	return count


func max_possible() -> int:
	return count * sides
