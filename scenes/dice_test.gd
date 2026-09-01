extends Node2D
## systems/dice_bag.gd, systems/combat_math.gd 값 검증용 테스트 씬.
## 시각 요소 없이 로직만 맞는지 확인하는 단계라, 결과를 화면에 텍스트로 찍어
## scripts/qa_shot.sh 스크린샷으로 확인할 수 있게 한다.

@onready var result_label: Label = $ResultLabel


func _ready() -> void:
	var lines: PackedStringArray = []
	var all_pass := true

	# DESIGN.md 확정 수치: 플레이어 공격/방어 D4x3, 몬스터 공격 D4x2 / 방어 D4x1
	var player_attack := DiceBag.new(4, 3)
	var player_defense := DiceBag.new(4, 3)
	var monster_attack := DiceBag.new(4, 2)
	var monster_defense := DiceBag.new(4, 1)

	lines.append("[다이스 주머니 굴림 샘플 (5회)]")
	for i in 5:
		var atk := player_attack.roll()
		var mdef := monster_defense.roll()
		var dmg := CombatMath.calculate_damage(atk, mdef)
		lines.append("  플레이어 공격 D4x3=%d vs 몬스터 방어 D4x1=%d -> 데미지=%d" % [atk, mdef, dmg])

	lines.append("")
	lines.append("[값 범위 검증 (300회 반복)]")
	all_pass = _check_range("player_attack D4x3", player_attack, 3, 12, lines) and all_pass
	all_pass = _check_range("player_defense D4x3", player_defense, 3, 12, lines) and all_pass
	all_pass = _check_range("monster_attack D4x2", monster_attack, 2, 8, lines) and all_pass
	all_pass = _check_range("monster_defense D4x1", monster_defense, 1, 4, lines) and all_pass

	lines.append("")
	lines.append("[데미지 공식 검증: max(0, 공격 - 방어)]")
	all_pass = _check_damage(10, 3, 7, lines) and all_pass
	all_pass = _check_damage(3, 10, 0, lines) and all_pass
	all_pass = _check_damage(5, 5, 0, lines) and all_pass

	lines.append("")
	lines.append("결과: %s" % ("PASS" if all_pass else "FAIL"))

	var text := "\n".join(lines)
	print(text)
	result_label.text = text


func _check_range(label: String, bag: DiceBag, expect_min: int, expect_max: int, lines: PackedStringArray) -> bool:
	var actual_min := 999999
	var actual_max := -999999
	for i in 300:
		var v := bag.roll()
		actual_min = min(actual_min, v)
		actual_max = max(actual_max, v)
	var ok := actual_min >= expect_min and actual_max <= expect_max
	lines.append("  %s: 관측범위=[%d,%d] 기대범위=[%d,%d] -> %s" % [
		label, actual_min, actual_max, expect_min, expect_max, "OK" if ok else "FAIL"
	])
	return ok


func _check_damage(attack: int, defense: int, expected: int, lines: PackedStringArray) -> bool:
	var actual := CombatMath.calculate_damage(attack, defense)
	var ok := actual == expected
	lines.append("  공격=%d 방어=%d -> 데미지=%d (기대=%d) -> %s" % [
		attack, defense, actual, expected, "OK" if ok else "FAIL"
	])
	return ok
