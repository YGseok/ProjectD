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
	lines.append("[다이스 개조 검증: add_die / replace_die / set_face_value]")
	all_pass = _check_dice_modifiers(lines) and all_pass

	lines.append("")
	lines.append("[다이스 아이템 풀 검증: DiceItemPool.apply]")
	all_pass = _check_item_pool(lines) and all_pass

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


func _check_dice_modifiers(lines: PackedStringArray) -> bool:
	var ok := true

	# D4x3 (min=3,max=12) -> add_die(4)로 D4 1개 추가 -> min=4,max=16
	var bag := DiceBag.new(4, 3)
	bag.add_die(4)
	var add_ok := bag.count == 4 and bag.min_possible() == 4 and bag.max_possible() == 16
	ok = add_ok and ok
	lines.append("  add_die: count=%d min=%d max=%d (기대 count=4 min=4 max=16) -> %s" % [
		bag.count, bag.min_possible(), bag.max_possible(), "OK" if add_ok else "FAIL"
	])

	# 다이스 4개(D4x4) 중 0번을 D6으로 교체 -> min=4(1*4), max=18(6+4+4+4)
	bag.replace_die(0, 6)
	var replace_ok := bag.min_possible() == 4 and bag.max_possible() == 18
	ok = replace_ok and ok
	lines.append("  replace_die(0, 6): min=%d max=%d (기대 min=4 max=18) -> %s" % [
		bag.min_possible(), bag.max_possible(), "OK" if replace_ok else "FAIL"
	])

	# 다이스 1번(D4)의 0번째 면(값 1)을 4로 강화 -> 그 면 값 자체가 바뀌었는지 확인
	bag.set_face_value(1, 0, 4)
	var face_ok := bag.dice[1][0] == 4
	ok = face_ok and ok
	lines.append("  set_face_value(1,0,4): dice[1]의 0번째 면=%d (기대 4) -> %s" % [
		bag.dice[1][0], "OK" if face_ok else "FAIL"
	])

	return ok


func _check_item_pool(lines: PackedStringArray) -> bool:
	var ok := true

	var choices := DiceItemPool.random_choices(2)
	var choices_ok := choices.size() == 2
	ok = choices_ok and ok
	lines.append("  random_choices(2)개수=%d (기대 2) -> %s" % [choices.size(), "OK" if choices_ok else "FAIL"])

	var add_bag := DiceBag.new(4, 3)
	DiceItemPool.apply({"kind": "add_die", "sides": 4}, add_bag)
	var add_item_ok := add_bag.count == 4
	ok = add_item_ok and ok
	lines.append("  apply(add_die): count=%d (기대 4) -> %s" % [add_bag.count, "OK" if add_item_ok else "FAIL"])

	var upgrade_bag := DiceBag.new(4, 3)
	DiceItemPool.apply({"kind": "upgrade_die", "new_sides": 6}, upgrade_bag)
	var upgrade_ok := upgrade_bag.max_possible() == 14  # 6 + 4 + 4
	ok = upgrade_ok and ok
	lines.append("  apply(upgrade_die): max=%d (기대 14) -> %s" % [upgrade_bag.max_possible(), "OK" if upgrade_ok else "FAIL"])

	var boost_bag := DiceBag.new(4, 3)
	DiceItemPool.apply({"kind": "boost_weak_face"}, boost_bag)
	var boost_ok := boost_bag.min_possible() == 4  # 다이스 0의 최저면(1)이 최댓값(4)으로 올라감 -> 2+1+1
	ok = boost_ok and ok
	lines.append("  apply(boost_weak_face): min=%d (기대 4) -> %s" % [boost_bag.min_possible(), "OK" if boost_ok else "FAIL"])

	var uniform_bag := DiceBag.new(4, 3)
	DiceItemPool.apply({"kind": "uniform_faces"}, uniform_bag)
	var uniform_ok := uniform_bag.min_possible() == 6  # 다이스 0의 모든 면이 최댓값(4)으로 맞춰짐 -> 4+1+1
	ok = uniform_ok and ok
	lines.append("  apply(uniform_faces): min=%d (기대 6) -> %s" % [uniform_bag.min_possible(), "OK" if uniform_ok else "FAIL"])

	# 버그 회귀 테스트: 이미 모든 다이스가 new_sides 이상이면(승급할 대상이 없으면)
	# upgrade_die가 아무 것도 건드리지 않아야 한다. 예전 코드는 이 경우에도 가장 작은
	# 다이스를 골라 replace_die()해버려서, 면 개수는 그대로인데 커스터마이징으로 올려둔
	# 면 값(여기서는 99로 표시)이 표준값(1..6)으로 조용히 리셋되는 버그가 있었다.
	var no_downgrade_bag := DiceBag.new(6, 1)
	no_downgrade_bag.set_face_value(0, 0, 99)
	DiceItemPool.apply({"kind": "upgrade_die", "new_sides": 6}, no_downgrade_bag)
	var no_downgrade_ok := no_downgrade_bag.dice[0][0] == 99
	ok = no_downgrade_ok and ok
	lines.append("  apply(upgrade_die, 승급 대상 없음): face=%d (기대 99, 리셋 안 됨) -> %s" % [no_downgrade_bag.dice[0][0], "OK" if no_downgrade_ok else "FAIL"])

	return ok
