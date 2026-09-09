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
	lines.append("[다이스 개수 캡 검증: dice_bag.gd MAX_DICE / dice_item_pool.gd is_applicable(add_die)]")
	all_pass = _check_dice_cap(lines) and all_pass

	lines.append("")
	lines.append("[던전 맵 방 선택지 결정성 검증: dungeon_map.gd _room_options_for_index]")
	all_pass = _check_dungeon_map_room_options(lines) and all_pass

	lines.append("")
	lines.append("[스토리 이벤트 골드 클램프 검증: story_event.gd _apply_gold_delta]")
	all_pass = _check_story_event_gold_delta(lines) and all_pass

	lines.append("")
	lines.append("[몬스터 난이도 스케일링 검증: combat_test.gd _monster_config_for_room]")
	all_pass = _check_monster_config_scaling(lines) and all_pass

	lines.append("")
	lines.append("[몬스터 특이 다이스 검증: dice_bag.gd force_min_max_faces/force_fixed_value / combat_test.gd dice_gimmick]")
	all_pass = _check_monster_dice_gimmick(lines) and all_pass

	lines.append("")
	lines.append("[커스터마이징 눈금 교환 검증: customize_panel.gd _exchange_pip]")
	all_pass = _check_customize_panel_pip_exchange(lines) and all_pass

	lines.append("")
	lines.append("[다이스 인벤토리 교환 검증: customize_panel.gd _exchange_die]")
	all_pass = _check_die_inventory_exchange(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 아이템 풀 검증: event_item_pool.gd EventItemPool.random_choices]")
	all_pass = _check_event_item_pool(lines) and all_pass

	lines.append("")
	lines.append("[다이스 면 모양 대응 검증: shape_die_chip.gd ShapeDieChip.shape_sides_for_dice_sides]")
	all_pass = _check_shape_die_chip_mapping(lines) and all_pass

	lines.append("")
	lines.append("[다이스 재질 배정 검증: combat_test.gd _material_for_sides]")
	all_pass = _check_material_for_sides(lines) and all_pass

	lines.append("")
	lines.append("[상점 이중 구매 방지 검증: shop.gd _on_buy_pressed]")
	all_pass = _check_shop_double_purchase_guard(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 이중 적용 방지 검증: event.gd _on_pick_pressed]")
	all_pass = _check_event_double_pick_guard(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 눈금 획득 검증: event.gd _apply_pips]")
	all_pass = _check_event_pips_guard(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 다이스 승급 획득 검증: event.gd _apply_upgrade]")
	all_pass = _check_event_upgrade_guard(lines) and all_pass

	lines.append("")
	lines.append("[스토리 이벤트 이중 진행 방지 검증: story_event.gd _on_continue_pressed]")
	all_pass = _check_story_event_double_continue_guard(lines) and all_pass

	lines.append("")
	lines.append("[전투 방 이중 진행 방지 검증: combat_test.gd _on_next_button_pressed]")
	all_pass = _check_combat_double_next_guard(lines) and all_pass

	lines.append("")
	lines.append("[커스터마이징 이중 교환 방지 검증: customize_panel.gd _on_face_chosen]")
	all_pass = _check_customize_panel_double_face_chosen_guard(lines) and all_pass

	lines.append("")
	lines.append("[커스터마이징 다이스 인벤토리 이중 교환 방지 검증: customize_panel.gd _on_die_target_chosen]")
	all_pass = _check_customize_panel_double_die_chosen_guard(lines) and all_pass

	lines.append("")
	lines.append("[전투 승리 보상 이중 적용 방지 검증: combat_test.gd _apply_reward_choice]")
	all_pass = _check_combat_double_reward_guard(lines) and all_pass

	lines.append("")
	lines.append("[업적 시스템 검증: achievement_manager.gd AchievementManager / combat_test.gd _bag_has_d20]")
	all_pass = _check_achievement_manager(lines) and all_pass

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

	# INBOX.md 피드백(2026-09-09) "다이스 승급 이벤트에서, 면 개수가 가장 작은것
	# 교체가 아닌 획득으로 바꾼다. ... 인벤토리로 들어와서 교체하도록 한다"를 반영해
	# upgrade_die는 더 이상 apply(item, bag)로 즉시 주머니를 건드리지 않는다 —
	# apply()에 넘겨도 아무 일도 안 일어나야 하고(match에 해당 분기가 없음), 대신
	# apply_upgrade_gain(item)이 RunState.die_inventory에 새 다이스를 쌓아야 한다.
	var die_inv_backup: Array[int] = RunState.die_inventory.duplicate()
	RunState.die_inventory = []

	var untouched_upgrade_bag := DiceBag.new(4, 3)
	DiceItemPool.apply({"kind": "upgrade_die", "new_sides": 6}, untouched_upgrade_bag)
	var apply_noop_ok := untouched_upgrade_bag.max_possible() == 12  # 4+4+4, 안 바뀜
	ok = apply_noop_ok and ok
	lines.append("  apply(upgrade_die)는 더 이상 bag을 건드리지 않음: max=%d (기대 12, 변화 없음) -> %s" % [
		untouched_upgrade_bag.max_possible(), "OK" if apply_noop_ok else "FAIL"
	])

	DiceItemPool.apply_upgrade_gain({"kind": "upgrade_die", "new_sides": 6})
	var gain_ok := RunState.die_inventory == [6]
	ok = gain_ok and ok
	lines.append("  apply_upgrade_gain(upgrade_die, new_sides=6): die_inventory=%s (기대 [6]) -> %s" % [
		RunState.die_inventory, "OK" if gain_ok else "FAIL"
	])
	RunState.die_inventory = die_inv_backup

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

	# is_applicable(): upgrade_die는 이제 즉시 어느 bag에도 적용되지 않고 항상 인벤토리로
	# 획득되기만 하므로(apply_upgrade_gain), bag 상태와 무관하게 항상 true여야 한다 —
	# 예전에는 "승급 대상이 없는 bag이면 false"였지만 그 개념 자체가 사라졌다.
	var no_target_bag := DiceBag.new(6, 1)
	var no_target_applicable := DiceItemPool.is_applicable({"kind": "upgrade_die", "new_sides": 6}, no_target_bag)
	var no_target_ok := no_target_applicable == true
	ok = no_target_ok and ok
	lines.append("  is_applicable(upgrade_die, 대상 없는 bag): %s (기대 true, 항상 획득 가능) -> %s" % [no_target_applicable, "OK" if no_target_ok else "FAIL"])

	var non_upgrade_applicable := DiceItemPool.is_applicable({"kind": "add_die", "sides": 4}, no_target_bag)
	var non_upgrade_ok := non_upgrade_applicable == true
	ok = non_upgrade_ok and ok
	lines.append("  is_applicable(add_die, 가득 안 찬 bag): %s (기대 true) -> %s" % [non_upgrade_applicable, "OK" if non_upgrade_ok else "FAIL"])

	# random_choices(n, attack_bag, defense_bag): upgrade_die는 is_applicable이 항상
	# true이므로 bag 상태와 무관하게 필터링되지 않는다. add_die는 2026-09-09부터
	# DiceBag.MAX_DICE 캡이 생겨 "두 bag 모두 가득 찬" 경우에만 필터링되는데(아래
	# _check_dice_cap 참고), 여기 쓰는 bag(count=3, MAX_DICE=6)은 아직 안 가득 찼으므로
	# 이 테스트에서는 여전히 필터링 없이 전체 목록(4개)에서 그대로 뽑혀야 한다.
	var maxed_attack := DiceBag.new(6, 3)
	var maxed_defense := DiceBag.new(6, 3)
	var unfiltered_size_ok := true
	for _i in 5:
		if DiceItemPool.random_choices(4, maxed_attack, maxed_defense).size() != 4:
			unfiltered_size_ok = false
	ok = unfiltered_size_ok and ok
	lines.append("  random_choices(4, bag 상태 무관, 5회 반복): 항상 4개 반환 -> %s" % ("OK" if unfiltered_size_ok else "FAIL"))

	var fresh_attack := DiceBag.new(4, 3)
	var fresh_defense := DiceBag.new(4, 3)
	var unfiltered_choices := DiceItemPool.random_choices(2, fresh_attack, fresh_defense)
	var unfiltered_ok := unfiltered_choices.size() == 2
	ok = unfiltered_ok and ok
	lines.append("  random_choices(2, 승급대상 있음): 개수=%d (기대 2) -> %s" % [unfiltered_choices.size(), "OK" if unfiltered_ok else "FAIL"])

	# preview_effect(): 카드 UI가 버튼 옆에 보여줄 "이 주머니에 적용하면 이렇게 바뀐다"
	# 미리보기가 실제 apply() 결과와 정확히 일치해야 한다(미리보기와 실제 결과가
	# 어긋나면 플레이어를 오도하는 UI 버그가 되므로, 두 값을 직접 비교해 검증).
	var boost_preview_bag := DiceBag.new(4, 3)
	var boost_preview = DiceItemPool.preview_effect({"kind": "boost_weak_face"}, boost_preview_bag)
	var boost_preview_expected_ok: bool = boost_preview["shape_sides"] == 4 and boost_preview["before"] == 1 and boost_preview["after"] == 4
	ok = boost_preview_expected_ok and ok
	lines.append("  preview_effect(boost_weak_face): before=%d after=%d (기대 1 -> 4) -> %s" % [
		boost_preview["before"], boost_preview["after"], "OK" if boost_preview_expected_ok else "FAIL"
	])
	DiceItemPool.apply({"kind": "boost_weak_face"}, boost_preview_bag)
	var boost_preview_matches_apply := boost_preview_bag.min_possible() == 4
	ok = boost_preview_matches_apply and ok
	lines.append("  preview_effect(boost_weak_face) == apply() 실제 결과: min=%d (기대 4) -> %s" % [
		boost_preview_bag.min_possible(), "OK" if boost_preview_matches_apply else "FAIL"
	])

	var uniform_preview_bag := DiceBag.new(4, 3)
	var uniform_preview = DiceItemPool.preview_effect({"kind": "uniform_faces"}, uniform_preview_bag)
	var uniform_preview_expected_ok: bool = uniform_preview["shape_sides"] == 4 and uniform_preview["value"] == 4 and uniform_preview["face_count"] == 4
	ok = uniform_preview_expected_ok and ok
	lines.append("  preview_effect(uniform_faces): value=%d face_count=%d (기대 4, 4) -> %s" % [
		uniform_preview["value"], uniform_preview["face_count"], "OK" if uniform_preview_expected_ok else "FAIL"
	])
	DiceItemPool.apply({"kind": "uniform_faces"}, uniform_preview_bag)
	var uniform_preview_matches_apply := uniform_preview_bag.min_possible() == 6  # 다이스 0 전체 4 -> 4+1+1
	ok = uniform_preview_matches_apply and ok
	lines.append("  preview_effect(uniform_faces) == apply() 실제 결과: min=%d (기대 6) -> %s" % [
		uniform_preview_bag.min_possible(), "OK" if uniform_preview_matches_apply else "FAIL"
	])

	# preview_effect()는 bag을 바꾸지 않아야 한다(순수 조회) — 위에서 apply()를 호출하기
	# 전에 미리 계산한 값이 이미 그 자체로 이 성질에 의존하고 있지만, 명시적으로도 확인.
	var untouched_bag := DiceBag.new(4, 3)
	var before_faces := untouched_bag.dice[0].duplicate()
	DiceItemPool.preview_effect({"kind": "boost_weak_face"}, untouched_bag)
	var untouched_ok := untouched_bag.dice[0] == before_faces
	ok = untouched_ok and ok
	lines.append("  preview_effect()는 bag을 변경하지 않음: %s -> %s" % [untouched_bag.dice[0], "OK" if untouched_ok else "FAIL"])

	# add_die/upgrade_die는 카드 레벨(_build_result_die_preview)에서 이미 다루므로
	# preview_effect()는 이 종류들에 대해 null을 반환해야 한다(중복 미리보기 방지).
	var non_effect_preview = DiceItemPool.preview_effect({"kind": "add_die", "sides": 4}, untouched_bag)
	var non_effect_ok: bool = non_effect_preview == null
	ok = non_effect_ok and ok
	lines.append("  preview_effect(add_die): %s (기대 null) -> %s" % [non_effect_preview, "OK" if non_effect_ok else "FAIL"])

	return ok


## INBOX.md 2026-09-09 "성장의 재미가 없다" 피드백 방향 1(다이스 개수를 계속 늘리는
## 대신 고정 풀 안에서 교체)의 첫 조각인 DiceBag.MAX_DICE 캡이 실제로 add_die류
## 아이템을 막는지 검증한다. is_full()/is_applicable()/apply()가 서로 어긋나면
## "버튼은 비활성화됐는데 apply는 조용히 통과함" 같은 불일치가 생길 수 있어 셋을
## 함께 확인한다.
func _check_dice_cap(lines: PackedStringArray) -> bool:
	var ok := true

	var not_full_bag := DiceBag.new(4, 3)
	var not_full_ok := not_full_bag.is_full() == false
	ok = not_full_ok and ok
	lines.append("  is_full(count=3, MAX=%d): %s (기대 false) -> %s" % [
		DiceBag.MAX_DICE, not_full_bag.is_full(), "OK" if not_full_ok else "FAIL"
	])

	var full_bag := DiceBag.new(4, DiceBag.MAX_DICE)
	var full_ok := full_bag.is_full() == true
	ok = full_ok and ok
	lines.append("  is_full(count=%d, MAX=%d): %s (기대 true) -> %s" % [
		DiceBag.MAX_DICE, DiceBag.MAX_DICE, full_bag.is_full(), "OK" if full_ok else "FAIL"
	])

	var add_item := {"kind": "add_die", "sides": 4}
	var applicable_when_full := DiceItemPool.is_applicable(add_item, full_bag)
	var applicable_ok := applicable_when_full == false
	ok = applicable_ok and ok
	lines.append("  is_applicable(add_die, 가득 찬 bag): %s (기대 false) -> %s" % [
		applicable_when_full, "OK" if applicable_ok else "FAIL"
	])

	DiceItemPool.apply(add_item, full_bag)
	var apply_noop_ok := full_bag.count == DiceBag.MAX_DICE
	ok = apply_noop_ok and ok
	lines.append("  apply(add_die, 가득 찬 bag)은 아무 일도 안 함: count=%d (기대 %d, 변화 없음) -> %s" % [
		full_bag.count, DiceBag.MAX_DICE, "OK" if apply_noop_ok else "FAIL"
	])

	var reason := DiceItemPool.unavailable_reason(add_item)
	var reason_ok := reason.find("가득") >= 0
	ok = reason_ok and ok
	lines.append("  unavailable_reason(add_die): \"%s\" (기대 '가득 참' 문구 포함) -> %s" % [
		reason, "OK" if reason_ok else "FAIL"
	])

	var upgrade_reason := DiceItemPool.unavailable_reason({"kind": "upgrade_die"})
	var upgrade_reason_ok := upgrade_reason == "승급 대상 없음"
	ok = upgrade_reason_ok and ok
	lines.append("  unavailable_reason(upgrade_die): \"%s\" (기대 '승급 대상 없음') -> %s" % [
		upgrade_reason, "OK" if upgrade_reason_ok else "FAIL"
	])

	# 양쪽 주머니 모두 캡에 도달하면 random_choices()가 add_die를 후보에서 제외해야
	# 한다(대체 후보 3개(upgrade_die/boost_weak_face/uniform_faces)로 충분하므로
	# 2026-09-07 도입 폴백 없이 바로 필터링됨).
	var maxed_attack := DiceBag.new(4, DiceBag.MAX_DICE)
	var maxed_defense := DiceBag.new(4, DiceBag.MAX_DICE)
	var choices := DiceItemPool.random_choices(3, maxed_attack, maxed_defense)
	var excludes_add_die := true
	for c in choices:
		if c.get("kind", "") == "add_die":
			excludes_add_die = false
	ok = excludes_add_die and ok
	lines.append("  random_choices(3, 양쪽 캡 도달): add_die 후보 제외됨=%s -> %s" % [
		excludes_add_die, "OK" if excludes_add_die else "FAIL"
	])

	return ok


## dungeon_map.gd의 _room_options_for_index(idx)는 방마다 상점/특수 이벤트/스토리
## 이벤트의 노출 여부와 표시 순서를 결정하는데, _roll_room_choices()(실제 진행)와
## _make_map_node()(MapStrip 미리보기) 둘 다 이 함수 하나를 그대로 호출해 값을 얻는
## 설계라 "같은 idx는 항상 같은 결과"라는 결정성이 깨지면 미리보기와 실제 버튼이
## 어긋난다(2026-09-08 순서 섞기 추가 당시 스크린샷으로만 확인했고 자동 회귀 테스트가
## 없었던 간극). 씬에 add_child하지 않고 스크립트만 인스턴스화해서 확인한다 —
## _room_options_for_index()는 @onready 변수를 쓰지 않아 _ready() 없이도 안전하게
## 호출 가능.
func _check_dungeon_map_room_options(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/dungeon_map.gd")
	var map = script.new()

	var first = map._room_options_for_index(3)
	# map은 Node2D 기반이라(dungeon_map.gd) RefCounted가 아니므로, 씬 트리에 추가하지
	# 않고 검증용으로만 쓰고 나면 직접 free()해야 한다 (안 그러면 QA 로그에
	# "ObjectDB instances leaked" 경고가 남는다).
	var second = map._room_options_for_index(3)
	var deterministic_ok: bool = first.shop == second.shop and first.event == second.event \
		and first.story == second.story and first.order == second.order
	ok = deterministic_ok and ok
	lines.append("  _room_options_for_index(3) 반복 호출 결정성(노출 여부+순서 동일): %s -> %s" % [
		deterministic_ok, "OK" if deterministic_ok else "FAIL"
	])

	# order는 노출 여부(shop/event/story 각각 true/false)와 무관하게 항상 세 종류를
	# 정확히 한 번씩만 담은 순열이어야 한다 — 버튼 레이아웃(_layout_visible_buttons)과
	# 칩 나열(_make_map_node)이 둘 다 "for t in opts.order: if opts[t]: ..."로
	# 순회하므로, order 자체에 값이 빠지거나 중복되면 노출된 방 선택지 하나가 화면에서
	# 통째로 안 보이거나(버튼 없음) 중복 렌더링될 수 있다.
	var order_valid := true
	for idx in range(10):
		var opts = map._room_options_for_index(idx)
		var sorted_order: Array = opts.order.duplicate()
		sorted_order.sort()
		if sorted_order != ["event", "shop", "story"]:
			order_valid = false
	ok = order_valid and ok
	lines.append("  order가 항상 shop/event/story 순열임(idx 0..9 확인): %s -> %s" % [
		order_valid, "OK" if order_valid else "FAIL"
	])

	map.free()
	return ok


## story_event.gd의 _apply_gold_delta(delta)는 RunState.gold를 0 밑으로 안 내려가게
## 클램프하고, 결과 문구가 요청한 delta가 아니라 실제로 변한 양(actual_delta)을 쓰도록
## 2026-09-09 (26)에 고쳐졌다 — 그때는 QA 스크린샷으로만 확인하고 자동 회귀 테스트가
## 없었던 간극을 메운다. RunState.gold는 전역 상태라 테스트 전후로 원래 값을 복원해
## 이 테스트가 다른 검증에 영향을 주지 않게 한다.
func _check_story_event_gold_delta(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/story_event.gd")
	var story = script.new()
	var gold_backup := RunState.gold

	# 손실 폭(10)이 보유 골드(3)보다 큰 엣지 케이스: 실제로는 3만 잃고 0이 되어야 하며,
	# actual_delta도 -10이 아니라 -3이어야 한다(수정 전 버그는 여기서 -10을 그대로 표시).
	RunState.gold = 3
	var clamped_delta: int = story._apply_gold_delta(-10)
	var clamp_ok := clamped_delta == -3 and RunState.gold == 0
	ok = clamp_ok and ok
	lines.append("  _apply_gold_delta(-10) (보유 3): actual_delta=%d gold=%d (기대 -3, 0) -> %s" % [
		clamped_delta, RunState.gold, "OK" if clamp_ok else "FAIL"
	])

	# 클램프가 발동하지 않는 일반적인 경우(골드가 충분하거나 획득)에는 actual_delta가
	# 요청한 delta와 완전히 같아야 한다(회귀 없음 확인).
	RunState.gold = 20
	var normal_delta: int = story._apply_gold_delta(-10)
	var normal_ok := normal_delta == -10 and RunState.gold == 10
	ok = normal_ok and ok
	lines.append("  _apply_gold_delta(-10) (보유 20): actual_delta=%d gold=%d (기대 -10, 10) -> %s" % [
		normal_delta, RunState.gold, "OK" if normal_ok else "FAIL"
	])

	var gain_delta: int = story._apply_gold_delta(15)
	var gain_ok := gain_delta == 15 and RunState.gold == 25
	ok = gain_ok and ok
	lines.append("  _apply_gold_delta(15) (보유 10): actual_delta=%d gold=%d (기대 15, 25) -> %s" % [
		gain_delta, RunState.gold, "OK" if gain_ok else "FAIL"
	])

	story.free()
	RunState.gold = gold_backup
	return ok


## combat_test.gd의 _monster_config_for_room(room_index)/_monster_dice_sides_for_room()는
## "던전이 진행될수록 몬스터가 강해진다"는 난이도 곡선(공격 다이스 2방마다 +1개, 방어
## 다이스 3방마다 +1개, HP 매 방 +3, 다이스 면 개수는 0-1방 D4 -> 2-3방 D6 -> 4방부터
## D8, 이름은 MONSTER_PROFILES를 5개 주기로 순환하며 한 바퀴 돌 때마다 "강화 " 접두어가
## 누적)인데, 지금까지 room4까지의 물리적 배치(벽 밖 이탈 없음)만 스크린샷으로 검증됐을
## 뿐 공식 자체가 의도한 값을 내는지는 자동 회귀 테스트가 없었다. 두 함수 모두 @onready
## 변수나 다른 인스턴스 상태를 쓰지 않는 순수 함수라 add_child 없이 안전하게 호출 가능
## (dungeon_map.gd/story_event.gd 검증과 같은 패턴).
func _check_monster_config_scaling(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	# room_index=0: DESIGN.md 확정값(공격 2D4/방어 1D4/HP10)과 정확히 일치해야 한다.
	var room0 = combat._monster_config_for_room(0)
	var room0_ok: bool = room0["attack_count"] == 2 and room0["defense_count"] == 1 \
		and room0["max_hp"] == 10 and room0["dice_sides"] == 4 and room0["name"] == "슬라임"
	ok = room0_ok and ok
	lines.append("  room0: 공격=%d 방어=%d hp=%d sides=%d name=%s (기대 2,1,10,4,슬라임) -> %s" % [
		room0["attack_count"], room0["defense_count"], room0["max_hp"], room0["dice_sides"], room0["name"],
		"OK" if room0_ok else "FAIL"
	])

	# 공식 자체를 room_index 0..6에서 직접 재계산해 대조(경계값 0/1/2/3/4/5/6 전부 확인).
	var formula_ok := true
	for idx in range(7):
		var cfg = combat._monster_config_for_room(idx)
		var expected_attack := 2 + int(idx / 2.0)
		var expected_defense := 1 + int(idx / 3.0)
		var expected_hp := 10 + idx * 3
		var expected_sides := 8 if idx >= 4 else (6 if idx >= 2 else 4)
		if cfg["attack_count"] != expected_attack or cfg["defense_count"] != expected_defense \
			or cfg["max_hp"] != expected_hp or cfg["dice_sides"] != expected_sides:
			formula_ok = false
	ok = formula_ok and ok
	lines.append("  room 0..6 스케일링 공식 일치(공격/방어/hp/면개수): %s -> %s" % [
		formula_ok, "OK" if formula_ok else "FAIL"
	])

	# 이름 순환: MONSTER_PROFILES 5개를 다 돌면(room_index=5) "강화 " 접두어가 1번,
	# 두 바퀴(room_index=10)면 2번 누적돼야 한다.
	var cycle1 = combat._monster_config_for_room(5)
	var cycle2 = combat._monster_config_for_room(10)
	var cycle_ok: bool = cycle1["name"] == "강화 슬라임" and cycle2["name"] == "강화 강화 슬라임"
	ok = cycle_ok and ok
	lines.append("  이름 순환(room5, room10): %s, %s (기대 강화 슬라임, 강화 강화 슬라임) -> %s" % [
		cycle1["name"], cycle2["name"], "OK" if cycle_ok else "FAIL"
	])

	combat.free()
	return ok


## dice_bag.gd의 force_min_max_faces()/force_fixed_value()/count_max_rolls()는 INBOX.md
## 피드백(2026-09-09, "몬스터별 다이스 특이 특징" 예시 3개: "모든 주사위 눈이 min과
## max로만 이루어져 있다" / "주사위 값 x가 고정 데미지로 들어간다" / "주사위 x가 나올
## 때마다 분노 스택이 쌓여서 몇 개 이상이면 다음 턴에 20면체를 돌린다")를 구현한 것이다.
## combat_test.gd는 force_min_max_faces()를 "다크 나이트"(MONSTER_PROFILES 5번째,
## dice_gimmick="min_max_only", room_index=4)에, force_fixed_value()를 "오크"(4번째,
## dice_gimmick="fixed_value", room_index=3)에, count_max_rolls() 기반 분노 스택 집계를
## "고블린"(2번째, dice_gimmick="anger_stack", room_index=1)에 각각 시범 적용한다 —
## 서로 다른 방에서만 켜지고, 다른 방(예: room0 슬라임)은 그대로 표준 다이스여야 한다.
## min_max_only는 300회 반복 굴림으로 중간값이 단 한 번도 안 나오는지, fixed_value는
## 매번 지정한 값만 나오는지까지 직접 확인한다. anger_stack의 "다음 턴 D20 전환"
## 자체(monster_anger_pending 소비, _do_exchange())는 @onready 씬 노드가 필요해 이
## 함수에서는 순수 로직(count_max_rolls, config 배정)만 확인하고, 실제 전투 진행은
## qa_out 스크린샷으로 별도 검증한다.
func _check_monster_dice_gimmick(lines: PackedStringArray) -> bool:
	var ok := true

	# count_max_rolls(): D6x3 표준 주머니에서 각 다이스가 "자신의 최댓값 면(6)"을
	# 보여줬는지 센다 — 몬스터별 굴림 결과가 아니라 임의로 만든 values로 직접 확인.
	var cm_bag := DiceBag.new(6, 3)
	var cm_hits := cm_bag.count_max_rolls([6, 3, 6])
	var cm_ok: bool = cm_hits == 2
	ok = cm_ok and ok
	lines.append("  count_max_rolls(D6x3, [6,3,6]): hits=%d (기대 2) -> %s" % [
		cm_hits, "OK" if cm_ok else "FAIL"
	])
	var cm_none_hits := cm_bag.count_max_rolls([1, 2, 5])
	var cm_none_ok: bool = cm_none_hits == 0
	ok = cm_none_ok and ok
	lines.append("  count_max_rolls(D6x3, [1,2,5]): hits=%d (기대 0) -> %s" % [
		cm_none_hits, "OK" if cm_none_ok else "FAIL"
	])

	# force_min_max_faces(): D6x1의 면 값이 [1,1,1,6,6,6]처럼 절반은 min(1)/절반은
	# max(6)로만 구성돼야 한다(중간값 2~5 제거). min_possible/max_possible은 원래 다이스와
	# 동일(1, 6)해야 하지만, 실제 굴림 결과에는 중간값이 전혀 나오지 않아야 한다.
	var gimmick_bag := DiceBag.new(6, 1)
	gimmick_bag.force_min_max_faces()
	var faces_ok := true
	for v in gimmick_bag.dice[0]:
		if v != 1 and v != 6:
			faces_ok = false
	var range_ok := gimmick_bag.min_possible() == 1 and gimmick_bag.max_possible() == 6
	ok = faces_ok and range_ok and ok
	lines.append("  force_min_max_faces(D6x1): faces=%s min=%d max=%d (기대 1/6만, min=1 max=6) -> %s" % [
		gimmick_bag.dice[0], gimmick_bag.min_possible(), gimmick_bag.max_possible(),
		"OK" if (faces_ok and range_ok) else "FAIL"
	])

	var no_middle_ok := true
	for _i in 300:
		var v := gimmick_bag.roll()
		if v != 1 and v != 6:
			no_middle_ok = false
	ok = no_middle_ok and ok
	lines.append("  300회 굴림 중 중간값(2~5) 등장 여부: 없음=%s (기대 true) -> %s" % [
		no_middle_ok, "OK" if no_middle_ok else "FAIL"
	])

	# combat_test.gd _monster_config_for_room(): room4(다크 나이트)만 gimmick이 켜지고
	# 이름에 "[극단]"이 붙어야 하며, room0(슬라임)은 영향받지 않아야 한다.
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	var room4_config = combat._monster_config_for_room(4)
	var room4_ok: bool = room4_config["dice_gimmick"] == "min_max_only" and room4_config["name"] == "다크 나이트 [극단]"
	ok = room4_ok and ok
	lines.append("  room4 config: dice_gimmick=%s name=%s (기대 min_max_only, '다크 나이트 [극단]') -> %s" % [
		room4_config["dice_gimmick"], room4_config["name"], "OK" if room4_ok else "FAIL"
	])
	var room0_config = combat._monster_config_for_room(0)
	var room0_unaffected_ok: bool = room0_config["dice_gimmick"] == "" and room0_config["name"] == "슬라임"
	ok = room0_unaffected_ok and ok
	lines.append("  room0 config(영향 없어야 함): dice_gimmick=%s name=%s (기대 빈 문자열, 슬라임) -> %s" % [
		room0_config["dice_gimmick"], room0_config["name"], "OK" if room0_unaffected_ok else "FAIL"
	])

	# force_fixed_value(): D6x1의 모든 면이 지정한 값(4) 하나로 통일돼야 하고, 몇 번을
	# 굴려도 항상 그 값만 나와야 한다("굴리지 않고 항상 같은 값"과 동일한 효과).
	var fixed_bag := DiceBag.new(6, 1)
	fixed_bag.force_fixed_value(4)
	var fixed_faces_ok := true
	for v in fixed_bag.dice[0]:
		if v != 4:
			fixed_faces_ok = false
	ok = fixed_faces_ok and ok
	lines.append("  force_fixed_value(D6x1, 4): faces=%s (기대 전부 4) -> %s" % [
		fixed_bag.dice[0], "OK" if fixed_faces_ok else "FAIL"
	])
	var always_same_ok := true
	for _i in 50:
		if fixed_bag.roll() != 4:
			always_same_ok = false
	ok = always_same_ok and ok
	lines.append("  50회 굴림이 항상 4인지: %s (기대 true) -> %s" % [
		always_same_ok, "OK" if always_same_ok else "FAIL"
	])

	# combat_test.gd _monster_config_for_room(): room3(오크, D6)만 fixed_value gimmick이
	# 켜지고 이름에 "[고정값 4]"가 붙어야 한다(D6 -> ceil(7/2)=4). min_max_only(room4)와
	# 서로 영향 없이 독립적으로 동작해야 함.
	var room3_config = combat._monster_config_for_room(3)
	var room3_ok: bool = room3_config["dice_gimmick"] == "fixed_value" \
		and room3_config["dice_gimmick_value"] == 4 \
		and room3_config["name"] == "오크 [고정값 4]"
	ok = room3_ok and ok
	lines.append("  room3 config: dice_gimmick=%s value=%d name=%s (기대 fixed_value/4/'오크 [고정값 4]') -> %s" % [
		room3_config["dice_gimmick"], room3_config["dice_gimmick_value"], room3_config["name"],
		"OK" if room3_ok else "FAIL"
	])

	# room1(고블린)만 anger_stack gimmick이 켜지고 이름에 "[분노]"가 붙어야 하며, room0/3/4와
	# 서로 영향 없이 독립적으로 동작해야 한다.
	var room1_config = combat._monster_config_for_room(1)
	var room1_ok: bool = room1_config["dice_gimmick"] == "anger_stack" and room1_config["name"] == "고블린 [분노]"
	ok = room1_ok and ok
	lines.append("  room1 config: dice_gimmick=%s name=%s (기대 anger_stack, '고블린 [분노]') -> %s" % [
		room1_config["dice_gimmick"], room1_config["name"], "OK" if room1_ok else "FAIL"
	])
	combat.free()

	return ok


## customize_panel.gd의 _exchange_pip(bag, die_index, face_index, pip_index)는 INBOX.md
## 피드백(2026-09-03)으로 "눈금 자유 입력"에서 "인벤토리 눈금 <-> 다이스 면 교환"으로
## 상호작용 모델 자체가 바뀐 핵심 로직인데, 지금까지 스크린샷 + 콘솔 확인으로만 검증되고
## 자동 회귀 테스트가 없었다. Control이지만 @onready 노드를 건드리지 않는 순수 함수라
## dungeon_map.gd/story_event.gd 검증과 같은 패턴(add_child 없이 인스턴스화 후 free())으로
## 안전하게 확인 가능. RunState.pip_inventory는 전역 상태라 테스트 전후로 복원한다.
func _check_customize_panel_pip_exchange(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/customize_panel.gd")
	var panel = script.new()
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()

	# 일반 케이스: D6 다이스의 0번째 면(표준값 1)을 눈금 4와 교환. 면이 4로 바뀌고,
	# 밀려난 옛 값(1)이 인벤토리로 돌아와야 한다(사라지지 않음).
	var bag := DiceBag.new(6, 1)
	RunState.pip_inventory = [4]
	panel._exchange_pip(bag, 0, 0, 0)
	var normal_ok: bool = bag.dice[0][0] == 4 and RunState.pip_inventory == [1]
	ok = normal_ok and ok
	lines.append("  D6 면[0](1) <-> 눈금 4: face=%d inventory=%s (기대 4, [1]) -> %s" % [
		bag.dice[0][0], RunState.pip_inventory, "OK" if normal_ok else "FAIL"
	])

	# 상한 클램프: D4 다이스에 눈금 10을 넣으면 면 개수(4)로 잘려 적용돼야 한다.
	var clamp_bag := DiceBag.new(4, 1)
	RunState.pip_inventory = [10]
	panel._exchange_pip(clamp_bag, 0, 0, 0)
	var clamp_ok: bool = clamp_bag.dice[0][0] == 4 and RunState.pip_inventory == [1]
	ok = clamp_ok and ok
	lines.append("  D4 면[0](1) <-> 눈금 10(상한 클램프): face=%d inventory=%s (기대 4, [1]) -> %s" % [
		clamp_bag.dice[0][0], RunState.pip_inventory, "OK" if clamp_ok else "FAIL"
	])

	# 인벤토리에 눈금이 여럿일 때: pip_index로 고른 것만 소모되고, 밀려난 값은 배열
	# 끝에 추가되며, 나머지 눈금은 그대로 유지돼야 한다(개수 보존: 하나 빠지고 하나 참).
	var multi_bag := DiceBag.new(6, 1)
	RunState.pip_inventory = [2, 5, 9]
	panel._exchange_pip(multi_bag, 0, 2, 1)
	var multi_ok: bool = multi_bag.dice[0][2] == 5 and RunState.pip_inventory == [2, 9, 3]
	ok = multi_ok and ok
	lines.append("  눈금 여럿 중 index=1(5)만 소모, 밀려난 값(3)은 끝에 추가: face=%d inventory=%s (기대 5, [2, 9, 3]) -> %s" % [
		multi_bag.dice[0][2], RunState.pip_inventory, "OK" if multi_ok else "FAIL"
	])

	panel.free()
	RunState.pip_inventory = pip_backup
	return ok


## customize_panel.gd의 _exchange_die(bag, die_index, inv_index)는 INBOX.md 피드백
## (2026-09-09) "다이스 승급 이벤트에서, 면 개수가 가장 작은것 교체가 아닌 획득으로
## 바꾼다. 눈금 획득 또는 다이스 승급시, 인벤토리로 들어와서 교체하도록 한다"로 새로
## 생긴 로직이다 — _exchange_pip과 대칭 구조(인벤토리 항목과 bag 슬롯을 맞바꾸고,
## 밀려난 쪽은 인벤토리로 돌아옴)라 같은 패턴으로 검증한다.
func _check_die_inventory_exchange(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/customize_panel.gd")
	var panel = script.new()
	var die_backup: Array[int] = RunState.die_inventory.duplicate()

	# 일반 케이스: D4 다이스 1개를 인벤토리의 D8과 교환. bag의 다이스가 8면체로
	# 바뀌고, 밀려난 옛 면 개수(4)가 인벤토리로 돌아와야 한다(사라지지 않음).
	var bag := DiceBag.new(4, 1)
	RunState.die_inventory = [8]
	panel._exchange_die(bag, 0, 0)
	var normal_ok: bool = bag.dice[0].size() == 8 and RunState.die_inventory == [4]
	ok = normal_ok and ok
	lines.append("  D4 다이스 <-> 인벤토리 D8: 결과 면개수=%d inventory=%s (기대 8, [4]) -> %s" % [
		bag.dice[0].size(), RunState.die_inventory, "OK" if normal_ok else "FAIL"
	])

	# 인벤토리에 다이스가 여럿일 때: inv_index로 고른 것만 소모되고, 밀려난 값은 배열
	# 끝에 추가되며, 나머지는 그대로 유지돼야 한다(개수 보존: 하나 빠지고 하나 참).
	var multi_bag := DiceBag.new(6, 2)
	RunState.die_inventory = [8, 10, 12]
	panel._exchange_die(multi_bag, 1, 1)
	var multi_ok: bool = multi_bag.dice[1].size() == 10 and RunState.die_inventory == [8, 12, 6]
	ok = multi_ok and ok
	lines.append("  다이스 여럿 중 index=1(D10)만 소모, 밀려난 D6은 끝에 추가: 결과=%d inventory=%s (기대 10, [8, 12, 6]) -> %s" % [
		multi_bag.dice[1].size(), RunState.die_inventory, "OK" if multi_ok else "FAIL"
	])

	# _has_upgrade_target(new_sides): 양쪽 주머니 모두 new_sides보다 작은 다이스가
	# 없으면 false를 반환해야 한다(승급 자리 없음 안내 문구를 보여줄지 판단하는 근거).
	var attack_backup: DiceBag = RunState.player_attack_bag
	var defense_backup: DiceBag = RunState.player_defense_bag
	RunState.player_attack_bag = DiceBag.new(8, 1)
	RunState.player_defense_bag = DiceBag.new(10, 1)
	var no_target: bool = not panel._has_upgrade_target(6)
	var has_target: bool = panel._has_upgrade_target(12)
	ok = no_target and has_target and ok
	lines.append("  _has_upgrade_target: D8/D10뿐일 때 D6=자리없음(%s, 기대 true), D12=자리있음(%s, 기대 true) -> %s" % [
		no_target, has_target, "OK" if (no_target and has_target) else "FAIL"
	])
	RunState.player_attack_bag = attack_backup
	RunState.player_defense_bag = defense_backup

	panel.free()
	RunState.die_inventory = die_backup
	return ok


## event_item_pool.gd의 EventItemPool.random_choices(n, attack_bag, defense_bag)는
## dice_item_pool.gd의 DiceItemPool.random_choices()와 거의 동일한 필터링/폴백 로직을
## 별도로 복제해서 갖고 있는데(공유 함수가 아니라 각자 구현), 위 "다이스 아이템 풀 검증"
## 섹션이 DiceItemPool 쪽은 15개 넘는 항목으로 촘촘히 검증해온 것과 달리 EventItemPool
## 쪽은 지금까지 자동 회귀 테스트가 하나도 없었다 — event.gd(특수 이벤트 방)가 실제
## 플레이 경로에서 이 함수를 그대로 호출하므로 검증 공백이었다. EventItemPool.ITEMS
## 5종 전부 DiceItemPool.is_applicable()이 이제 항상 true를 반환하므로(2026-09-09,
## "다이스 승급"류가 즉시 적용 대신 인벤토리 획득으로 바뀜) 필터링 대상 자체가 없다.
func _check_event_item_pool(lines: PackedStringArray) -> bool:
	var ok := true

	var basic_choices := EventItemPool.random_choices(2)
	var basic_ok := basic_choices.size() == 2
	ok = basic_ok and ok
	lines.append("  random_choices(2, 필터 없음): 개수=%d (기대 2) -> %s" % [basic_choices.size(), "OK" if basic_ok else "FAIL"])

	# DiceItemPool.is_applicable()이 이제 항상 true를 반환하므로(2026-09-09, "다이스
	# 승급"류가 즉시 적용 대신 인벤토리 획득으로 바뀌어 "대상 없음" 개념이 사라짐),
	# 어떤 bag 상태를 넘겨도 필터링 없이 요청한 개수(5종 중 5개까지)가 그대로 나와야
	# 한다 — 예전에는 "승급 대상 없는 bag"이면 upgrade_die가 제외됐었다.
	var maxed_attack := DiceBag.new(10, 3)
	var maxed_defense := DiceBag.new(10, 3)
	var unfiltered_size_ok := true
	for _i in 5:
		if EventItemPool.random_choices(5, maxed_attack, maxed_defense).size() != 5:
			unfiltered_size_ok = false
	ok = unfiltered_size_ok and ok
	lines.append("  random_choices(5, bag 상태 무관, 5회 반복): 항상 5개(전체) 반환 -> %s" % ("OK" if unfiltered_size_ok else "FAIL"))

	var fresh_attack := DiceBag.new(4, 3)
	var fresh_defense := DiceBag.new(4, 3)
	var unfiltered_choices := EventItemPool.random_choices(2, fresh_attack, fresh_defense)
	var unfiltered_ok := unfiltered_choices.size() == 2
	ok = unfiltered_ok and ok
	lines.append("  random_choices(2, 승급대상 있음): 개수=%d (기대 2) -> %s" % [unfiltered_choices.size(), "OK" if unfiltered_ok else "FAIL"])

	return ok


## shape_die_chip.gd의 ShapeDieChip.shape_sides_for_dice_sides(sides)는 "다이스 면
## 개수 -> 칩에 그릴 모양의 변 개수"를 정하는 순수 함수로, INBOX.md 피드백(2026-09-03,
## "사면체는 세모, 육면체는 네모")과 die_d4.gd가 실제로 만드는 지오메트리(D4/D8/D20=
## 삼각형 면, D6=사각형, D10=연꼴 근사(사각형), D12=오각형)를 그대로 따르도록 설계된
## 대응표다. 전투 화면(combat_test.gd)의 다이스 결과 칩이 이 함수 하나로 모양을
## 정하는데, 지금까지 스크린샷으로만 육안 확인됐을 뿐 자동 회귀 테스트가 없었다 —
## 이 대응이 틀어지면(예: 나중에 다른 면 개수를 추가하다가 실수로 매핑이 깨져도)
## "칩 색이 좀 다르게 생겼다" 정도로만 보여서 스크린샷 눈으로도 놓치기 쉽다.
func _check_shape_die_chip_mapping(lines: PackedStringArray) -> bool:
	var ok := true
	var expected := {4: 3, 6: 4, 8: 3, 10: 4, 12: 5, 20: 3}
	for sides in expected.keys():
		var actual := ShapeDieChip.shape_sides_for_dice_sides(sides)
		var expected_shape: int = expected[sides]
		var pair_ok := actual == expected_shape
		ok = pair_ok and ok
		lines.append("  D%d -> 모양 변=%d (기대 %d) -> %s" % [sides, actual, expected_shape, "OK" if pair_ok else "FAIL"])
	return ok


## combat_test.gd의 _material_for_sides(sides)는 "다이스 면 개수 -> 재질" 잠정 배정표
## (DESIGN.md/die_d4.gd 클래스 주석에 문서화된 D4/D6=plastic, D8=wood, D10=glass,
## D12·D20=metal)를 코드로 구현한 순수 정적 함수다. 전투 화면의 다이스 스폰
## (_spawn_dice_for_bag 등)이 이 함수 하나로 모든 다이스의 재질(물리 bounce/friction +
## 시각 색 + 충돌음)을 정하는데, 지금까지 `qa_out/combat_test_material_swatch.png`
## 스크린샷으로만 육안 확인됐을 뿐 dice_test.gd에는 대응 테스트가 없었다. shape_die_chip.gd
## 매핑과 같은 종류의 위험(표가 깨지면 "색이 좀 다르게 보인다" 정도로만 드러나 스크린샷
## 눈으로도 놓치기 쉬움)이 있는 간극이라 같은 패턴으로 메운다.
func _check_material_for_sides(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/combat_test.gd")
	# null이면 die_d4.tscn 기본값(plastic)을 그대로 쓰는 설계이므로, 기대값은 "그 다이스가
	# 최종적으로 갖게 될 재질 이름"으로 표현한다(4/6은 null -> plastic).
	var expected := {4: "plastic", 6: "plastic", 8: "wood", 10: "glass", 12: "metal", 20: "metal"}
	for sides in expected.keys():
		var mat = script._material_for_sides(sides)
		var actual_name: String = mat.material_name if mat != null else "plastic"
		var expected_name: String = expected[sides]
		var pair_ok := actual_name == expected_name
		ok = pair_ok and ok
		lines.append("  D%d -> 재질=%s (기대 %s) -> %s" % [sides, actual_name, expected_name, "OK" if pair_ok else "FAIL"])
	return ok


## shop.gd의 _on_buy_pressed(item, cost, target)는 골드가 부족하면(RunState.gold < cost)
## 아무 것도 하지 않고 return하는 가드를 갖고 있다 — 버튼이 이미 disabled=true로
## 막아주지만, 이터레이션 44가 "핸들러 자체도 재검증해 이중 차감이 불가능함"을 코드
## 정독으로만 확인하고 자동 회귀 테스트로 남기지 않았던 간극을 메운다. shop.gd는
## @onready 노드(gold_label 등)를 쓰므로 다른 검증들처럼 script.new()만으로는 안전하지
## 않아, 실제 shop.tscn을 인스턴스화해 이 노드(dice_test)의 자식으로 잠깐 붙였다가
## (그래야 _ready()가 실행되어 @onready 변수가 채워짐) 검증 후 다시 떼어내고 free()한다.
func _check_shop_double_purchase_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var gold_backup := RunState.gold
	var attack_bag_backup := RunState.player_attack_bag

	RunState.player_attack_bag = DiceBag.new(4, 3)
	var item: Dictionary = DiceItemPool.ITEMS[0]  # "add_die" (sides=4)
	var cost: int = 15  # shop.gd ITEM_COSTS["add_die"]
	RunState.gold = cost

	var shop_scene := load("res://code/scenes/shop.tscn")
	var shop = shop_scene.instantiate()
	add_child(shop)

	var count_before: int = RunState.player_attack_bag.count
	shop._on_buy_pressed(item, cost, "attack")
	var first_ok: bool = RunState.gold == 0 and RunState.player_attack_bag.count == count_before + 1
	ok = first_ok and ok
	lines.append("  1차 구매(골드=비용=%d): gold=%d count=%d (기대 0, %d) -> %s" % [
		cost, RunState.gold, RunState.player_attack_bag.count, count_before + 1, "OK" if first_ok else "FAIL"
	])

	# 골드가 이미 0인 상태에서 핸들러를 다시 호출해도(더블클릭 등으로 disabled 가드를
	# 우회하는 상황을 가정) 골드가 음수로 내려가거나 아이템이 중복 적용돼선 안 된다.
	shop._on_buy_pressed(item, cost, "attack")
	var guard_ok: bool = RunState.gold == 0 and RunState.player_attack_bag.count == count_before + 1
	ok = guard_ok and ok
	lines.append("  2차 구매 재시도(골드 부족): gold=%d count=%d (기대 0, %d, 변화 없음) -> %s" % [
		RunState.gold, RunState.player_attack_bag.count, count_before + 1, "OK" if guard_ok else "FAIL"
	])

	remove_child(shop)
	shop.free()
	RunState.gold = gold_backup
	RunState.player_attack_bag = attack_bag_backup
	return ok


## event.gd의 _apply_pick(item, target)는 shop.gd와 같은 이유(이터레이션 45)로 이중
## 적용을 막는 가드(_picked 플래그)를 갖는다 — 다만 상점과 달리 무료라서 "골드 부족"
## 같은 자연 재검증 수단이 없어 이번 이터레이션에 새로 추가됨. _on_pick_pressed는 씬
## 전환(change_scene_to_file)까지 포함하므로 직접 호출하면 QA 중인 dice_test 씬 자체가
## 바뀌어버려, 씬 전환과 분리된 _apply_pick()을 대신 호출해 부작용 없이 가드만 검증한다.
## shop 검증과 같은 패턴(실제 event.tscn 인스턴스화 후 add_child/remove_child)을 쓴다.
func _check_event_double_pick_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared
	var attack_bag_backup := RunState.player_attack_bag

	RunState.player_attack_bag = DiceBag.new(4, 3)
	var item: Dictionary = EventItemPool.ITEMS[0]

	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	var rooms_before: int = RunState.rooms_cleared
	var count_before: int = RunState.player_attack_bag.count
	var first_applied: bool = event_node._apply_pick(item, "attack")
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1 and RunState.player_attack_bag.count == count_before + 1
	ok = first_ok and ok
	lines.append("  1차 적용: applied=%s rooms=%d count=%d (기대 true, %d, %d) -> %s" % [
		first_applied, RunState.rooms_cleared, RunState.player_attack_bag.count, rooms_before + 1, count_before + 1, "OK" if first_ok else "FAIL"
	])

	# 버튼 더블클릭 등으로 같은 프레임에 핸들러가 다시 불려도(가드 우회 가정) 방을
	# 두 번 클리어 처리하거나 아이템을 중복 적용해선 안 된다.
	var second_applied: bool = event_node._apply_pick(item, "attack")
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1 and RunState.player_attack_bag.count == count_before + 1
	ok = guard_ok and ok
	lines.append("  2차 적용 재시도(이미 픽함): applied=%s rooms=%d count=%d (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.rooms_cleared, RunState.player_attack_bag.count, "OK" if guard_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()
	RunState.rooms_cleared = rooms_backup
	RunState.player_attack_bag = attack_bag_backup
	return ok


## event.gd의 새 "눈금 주머니 획득"(gain_pips) 아이템 — INBOX.md 피드백(2026-09-09,
## "눈금 이벤트가 잘 안뜨는 것 같다. 눈금 여러개 획득하는 이벤트를 넣어 밸런스를
## 맞춘다")에 따라 추가됨. _apply_pips(item)가 (1) pip_min..pip_max 범위 개수만큼
## RunState.pip_inventory에 실제로 값을 쌓고 (2) _apply_pick과 동일한 _picked 가드로
## 이중 실행을 막는지 확인한다(같은 인스턴스화/정리 패턴을 재사용).
func _check_event_pips_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()

	RunState.pip_inventory = []
	var pip_item: Dictionary = {}
	for it in EventItemPool.ITEMS:
		if it["kind"] == "gain_pips":
			pip_item = it
			break
	var item_found := pip_item.size() > 0
	ok = item_found and ok
	lines.append("  EventItemPool에 gain_pips 아이템 존재 -> %s" % ("OK" if item_found else "FAIL"))

	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = event_node._apply_pips(pip_item)
	var gained: int = RunState.pip_inventory.size()
	var count_ok := gained >= int(pip_item["pip_min"]) and gained <= int(pip_item["pip_max"])
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1 and count_ok
	ok = first_ok and ok
	lines.append("  1차 적용: applied=%s rooms=%d 획득개수=%d (기대 true, %d, [%d,%d] 범위) -> %s" % [
		first_applied, RunState.rooms_cleared, gained, rooms_before + 1,
		pip_item["pip_min"], pip_item["pip_max"], "OK" if first_ok else "FAIL"
	])

	# 더블클릭 등으로 같은 프레임에 핸들러가 다시 불려도(가드 우회 가정) 눈금이
	# 중복으로 더 쌓이거나 방을 두 번 클리어 처리해선 안 된다.
	var second_applied: bool = event_node._apply_pips(pip_item)
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1 and RunState.pip_inventory.size() == gained
	ok = guard_ok and ok
	lines.append("  2차 적용 재시도(이미 픽함): applied=%s rooms=%d 획득개수=%d (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.rooms_cleared, RunState.pip_inventory.size(), "OK" if guard_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()
	RunState.rooms_cleared = rooms_backup
	RunState.pip_inventory = pip_backup
	return ok


## event.gd의 "다이스 대승급 (-> D10)" 아이템(kind=upgrade_die) — INBOX.md 피드백
## (2026-09-09) "다이스 승급 이벤트에서, 면 개수가 가장 작은것 교체가 아닌 획득으로
## 바꾼다"에 따라 즉시 적용 대신 인벤토리 획득으로 바뀜. _apply_upgrade(item)가 (1)
## RunState.die_inventory에 new_sides를 실제로 쌓고 (2) _apply_pick/_apply_pips와
## 동일한 _picked 가드로 이중 실행을 막는지 확인한다(같은 인스턴스화/정리 패턴 재사용).
func _check_event_upgrade_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared
	var die_backup: Array[int] = RunState.die_inventory.duplicate()

	RunState.die_inventory = []
	var upgrade_item: Dictionary = {}
	for it in EventItemPool.ITEMS:
		if it["kind"] == "upgrade_die":
			upgrade_item = it
			break
	var item_found := upgrade_item.size() > 0
	ok = item_found and ok
	lines.append("  EventItemPool에 upgrade_die 아이템 존재 -> %s" % ("OK" if item_found else "FAIL"))

	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = event_node._apply_upgrade(upgrade_item)
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1 and RunState.die_inventory == [upgrade_item["new_sides"]]
	ok = first_ok and ok
	lines.append("  1차 적용: applied=%s rooms=%d die_inventory=%s (기대 true, %d, [%d]) -> %s" % [
		first_applied, RunState.rooms_cleared, RunState.die_inventory, rooms_before + 1, upgrade_item["new_sides"], "OK" if first_ok else "FAIL"
	])

	# 더블클릭 등으로 같은 프레임에 핸들러가 다시 불려도(가드 우회 가정) 다이스가
	# 중복으로 더 쌓이거나 방을 두 번 클리어 처리해선 안 된다.
	var second_applied: bool = event_node._apply_upgrade(upgrade_item)
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1 and RunState.die_inventory == [upgrade_item["new_sides"]]
	ok = guard_ok and ok
	lines.append("  2차 적용 재시도(이미 픽함): applied=%s rooms=%d die_inventory=%s (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.rooms_cleared, RunState.die_inventory, "OK" if guard_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()
	RunState.rooms_cleared = rooms_backup
	RunState.die_inventory = die_backup
	return ok


## story_event.gd/combat_test.gd에도 event.gd와 같은 이중 실행 취약점이 있었다
## (이터레이션 47): ContinueButton/NextButton 둘 다 change_scene_to_file() 호출이
## 그 프레임 안에서 즉시 씬을 바꾸지 않아, 더블클릭 시 rooms_cleared가 2 증가(방 스킵)할
## 수 있었다. 두 _apply_*() 함수 모두 @onready 노드를 건드리지 않는 순수 상태 변경
## 로직이라(씬 전환은 각각의 _on_*_pressed()로 분리됨), shop.gd/event.gd처럼
## instantiate()+add_child()할 필요 없이 스크립트만 new()해서(트리에 안 넣으므로
## _ready()가 실행되지 않음) 가드를 검증할 수 있다.
func _check_story_event_double_continue_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared

	var story_script := load("res://code/scenes/story_event.gd")
	var story = story_script.new()

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = story._apply_continue()
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1
	ok = first_ok and ok
	lines.append("  1차 진행: applied=%s rooms=%d (기대 true, %d) -> %s" % [
		first_applied, RunState.rooms_cleared, rooms_before + 1, "OK" if first_ok else "FAIL"
	])

	var second_applied: bool = story._apply_continue()
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1
	ok = guard_ok and ok
	lines.append("  2차 진행 재시도(이미 진행함): applied=%s rooms=%d (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.rooms_cleared, "OK" if guard_ok else "FAIL"
	])

	story.free()
	RunState.rooms_cleared = rooms_backup
	return ok


func _check_combat_double_next_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared

	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()
	combat.player_won = true

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = combat._apply_room_advance()
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1
	ok = first_ok and ok
	lines.append("  1차 진행(승리): applied=%s rooms=%d (기대 true, %d) -> %s" % [
		first_applied, RunState.rooms_cleared, rooms_before + 1, "OK" if first_ok else "FAIL"
	])

	var second_applied: bool = combat._apply_room_advance()
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1
	ok = guard_ok and ok
	lines.append("  2차 진행 재시도(이미 진행함): applied=%s rooms=%d (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.rooms_cleared, "OK" if guard_ok else "FAIL"
	])

	combat.free()
	RunState.rooms_cleared = rooms_backup
	return ok


## combat_test.gd의 승리 보상 화면(_on_reward_chosen/_on_reward_skipped)도 같은 클래스의
## 이중 실행 취약점을 갖고 있었다(이터레이션 68) — _clear_reward_ui()의 queue_free()가
## 그 프레임 끝까지 카드/버튼을 실제로 지우지 않아, 더블클릭 시 같은 아이템이
## DiceItemPool.apply()로 두 번 적용될 수 있었다. rooms_advance/story_continue와 같은
## 패턴으로 상태 변경(_apply_reward_choice/_apply_reward_skip)을 UI(_on_reward_*)에서
## 분리해 script.new()만으로 가드를 검증한다.
func _check_combat_double_reward_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var attack_bag_backup := RunState.player_attack_bag

	RunState.player_attack_bag = DiceBag.new(4, 3)
	var item: Dictionary = DiceItemPool.ITEMS[0]  # "add_die"

	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()

	var count_before: int = RunState.player_attack_bag.count
	var first_applied: bool = combat._apply_reward_choice(item, "attack")
	var first_ok: bool = first_applied and RunState.player_attack_bag.count == count_before + 1
	ok = first_ok and ok
	lines.append("  1차 보상 적용: applied=%s count=%d (기대 true, %d) -> %s" % [
		first_applied, RunState.player_attack_bag.count, count_before + 1, "OK" if first_ok else "FAIL"
	])

	var second_applied: bool = combat._apply_reward_choice(item, "attack")
	var guard_ok: bool = not second_applied and RunState.player_attack_bag.count == count_before + 1
	ok = guard_ok and ok
	lines.append("  2차 보상 재시도(이미 결정함): applied=%s count=%d (기대 false, 변화 없음) -> %s" % [
		second_applied, RunState.player_attack_bag.count, "OK" if guard_ok else "FAIL"
	])

	var skip_after_choice: bool = combat._apply_reward_skip()
	var skip_guard_ok := not skip_after_choice
	ok = skip_guard_ok and ok
	lines.append("  선택 후 건너뛰기 재시도(같은 플래그 공유): applied=%s (기대 false) -> %s" % [
		skip_after_choice, "OK" if skip_guard_ok else "FAIL"
	])

	combat.free()

	var combat2_script := load("res://code/scenes/combat_test.gd")
	var combat2 = combat2_script.new()
	var first_skip: bool = combat2._apply_reward_skip()
	var second_skip: bool = combat2._apply_reward_skip()
	var skip_ok := first_skip and not second_skip
	ok = skip_ok and ok
	lines.append("  건너뛰기 단독 이중 실행: first=%s second=%s (기대 true, false) -> %s" % [
		first_skip, second_skip, "OK" if skip_ok else "FAIL"
	])
	combat2.free()

	RunState.player_attack_bag = attack_bag_backup
	return ok


## achievement_manager.gd(AchievementManager Autoload)의 저장/해금/조회 API와
## combat_test.gd의 _bag_has_d20(win_with_d20 업적 판정용 헬퍼)를 검증한다.
## _debug_reset_for_qa()로 시작/끝에 저장 파일을 초기화해 이 테스트가 실제 플레이
## 상태나 다른 QA 실행 결과와 섞이지 않게 한다.
func _check_achievement_manager(lines: PackedStringArray) -> bool:
	var ok := true

	AchievementManager._debug_reset_for_qa()

	var unknown_result: bool = AchievementManager.unlock("no_such_id")
	var unknown_ok := not unknown_result
	ok = unknown_ok and ok
	lines.append("  정의되지 않은 id 해금 시도: result=%s (기대 false) -> %s" % [
		unknown_result, "OK" if unknown_ok else "FAIL"
	])

	var before_unlock: bool = AchievementManager.is_unlocked("first_run_start")
	var before_ok := not before_unlock
	ok = before_ok and ok
	lines.append("  초기화 직후 is_unlocked(first_run_start): %s (기대 false) -> %s" % [
		before_unlock, "OK" if before_ok else "FAIL"
	])

	var first_unlock: bool = AchievementManager.unlock("first_run_start")
	var first_ok := first_unlock and AchievementManager.is_unlocked("first_run_start")
	ok = first_ok and ok
	lines.append("  최초 해금: unlock()=%s is_unlocked()=%s (기대 true, true) -> %s" % [
		first_unlock, AchievementManager.is_unlocked("first_run_start"), "OK" if first_ok else "FAIL"
	])

	var second_unlock: bool = AchievementManager.unlock("first_run_start")
	var idempotent_ok := not second_unlock
	ok = idempotent_ok and ok
	lines.append("  같은 id 재해금 시도(멱등성): result=%s (기대 false, 중복 저장 방지) -> %s" % [
		second_unlock, "OK" if idempotent_ok else "FAIL"
	])

	var display: Array = AchievementManager.get_all_for_display()
	var display_ok := display.size() == AchievementManager.DEFINITIONS.size()
	for e in display:
		if e.id == "first_run_start":
			display_ok = display_ok and e.unlocked
		else:
			display_ok = display_ok and not e.unlocked
	ok = display_ok and ok
	lines.append("  get_all_for_display(): 항목 %d개, first_run_start만 unlocked=true -> %s" % [
		display.size(), "OK" if display_ok else "FAIL"
	])

	AchievementManager._debug_reset_for_qa()

	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()

	var bag_with_d20 := DiceBag.new(4, 3)
	bag_with_d20.add_die(20)
	var has_d20: bool = combat._bag_has_d20(bag_with_d20)
	var has_d20_ok := has_d20
	ok = has_d20_ok and ok
	lines.append("  _bag_has_d20(D4x3 + D20 1개): %s (기대 true) -> %s" % [
		has_d20, "OK" if has_d20_ok else "FAIL"
	])

	var bag_without_d20 := DiceBag.new(4, 3)
	var no_d20: bool = combat._bag_has_d20(bag_without_d20)
	var no_d20_ok := not no_d20
	ok = no_d20_ok and ok
	lines.append("  _bag_has_d20(D4x3만): %s (기대 false) -> %s" % [
		no_d20, "OK" if no_d20_ok else "FAIL"
	])

	var flawless_true: bool = combat._is_flawless_win(combat.PLAYER_MAX_HP)
	var flawless_false: bool = combat._is_flawless_win(combat.PLAYER_MAX_HP - 1)
	var flawless_ok := flawless_true and not flawless_false
	ok = flawless_ok and ok
	lines.append("  _is_flawless_win(만피/만피-1): %s/%s (기대 true/false) -> %s" % [
		flawless_true, flawless_false, "OK" if flawless_ok else "FAIL"
	])

	var comeback_true: bool = combat._is_comeback_win(combat.COMEBACK_HP_THRESHOLD)
	var comeback_false: bool = combat._is_comeback_win(combat.COMEBACK_HP_THRESHOLD + 1)
	var comeback_ok := comeback_true and not comeback_false
	ok = comeback_ok and ok
	lines.append("  _is_comeback_win(임계치/임계치+1): %s/%s (기대 true/false) -> %s" % [
		comeback_true, comeback_false, "OK" if comeback_ok else "FAIL"
	])

	var overkill_true: bool = combat._is_overkill_win(10, 10)
	var overkill_false: bool = combat._is_overkill_win(9, 10)
	var overkill_ok := overkill_true and not overkill_false
	ok = overkill_ok and ok
	lines.append("  _is_overkill_win(데미지==최대체력/미만): %s/%s (기대 true/false) -> %s" % [
		overkill_true, overkill_false, "OK" if overkill_ok else "FAIL"
	])

	combat.free()

	AchievementManager._debug_reset_for_qa()
	var def_count_ok: bool = AchievementManager.DEFINITIONS.size() >= 7
	ok = def_count_ok and ok
	lines.append("  DEFINITIONS 개수 >= 7 (신규 4종 포함): %d -> %s" % [
		AchievementManager.DEFINITIONS.size(), "OK" if def_count_ok else "FAIL"
	])
	var new_ids := ["gold_100", "flawless_win", "comeback_win", "overkill_win"]
	var new_ids_ok := true
	for id in new_ids:
		new_ids_ok = new_ids_ok and AchievementManager.DEFINITIONS.has(id) and not AchievementManager.is_unlocked(id)
	ok = new_ids_ok and ok
	lines.append("  신규 업적 4종 정의 존재 + 초기 미해금: %s -> %s" % [
		new_ids_ok, "OK" if new_ids_ok else "FAIL"
	])

	return ok


## customize_panel.gd의 _on_face_chosen(bag, die_index, face_index, pip_index)는
## _show_face_picker()가 만든 면 버튼의 pressed 핸들러다. _clear_ui()가 쓰는
## queue_free()는 그 프레임이 끝나야 실제로 노드를 지우므로, 같은 버튼이 더블클릭 등
## 같은 프레임에 두 번 눌리면 이미 한 번 밀려난 pip_index/오염된 face 값을 가진 채로
## _exchange_pip()가 다시 실행돼 인벤토리를 조용히 오염시킬 수 있었다(이터레이션 48,
## event.gd/story_event.gd/combat_test.gd와 같은 클래스의 버그). _face_chosen_locked
## 플래그로 막았는지 확인한다. @onready 노드가 없는 순수 Control이라(트리 안 넣어도
## add_child가 동작) story_event/combat_test와 같은 script.new() 패턴으로 검증한다.
func _check_customize_panel_double_face_chosen_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()

	var script := load("res://code/scenes/customize_panel.gd")
	var panel = script.new()

	var bag := DiceBag.new(6, 1)
	RunState.pip_inventory = [4, 9]
	panel._show_face_picker(bag, 0, 0)

	panel._on_face_chosen(bag, 0, 0, 0)
	var first_ok: bool = bag.dice[0][0] == 4 and RunState.pip_inventory == [9, 1]
	ok = first_ok and ok
	lines.append("  1차 교환: face=%d inventory=%s (기대 4, [9, 1]) -> %s" % [
		bag.dice[0][0], RunState.pip_inventory, "OK" if first_ok else "FAIL"
	])

	# 같은 프레임에 같은 버튼이 다시 눌려도(더블클릭 가정), 이미 교환이 끝난 뒤라
	# 아무 일도 일어나선 안 된다 — 인벤토리가 더 오염되거나 면 값이 다시 바뀌면 안 됨.
	panel._on_face_chosen(bag, 0, 0, 0)
	var guard_ok: bool = bag.dice[0][0] == 4 and RunState.pip_inventory == [9, 1]
	ok = guard_ok and ok
	lines.append("  2차 교환 재시도(이미 교환함): face=%d inventory=%s (기대 변화 없음) -> %s" % [
		bag.dice[0][0], RunState.pip_inventory, "OK" if guard_ok else "FAIL"
	])

	panel.free()
	RunState.pip_inventory = pip_backup
	return ok


## customize_panel.gd의 _on_die_target_chosen(bag, die_index, inv_index)는
## _on_face_chosen과 같은 이유(이터레이션 48과 같은 클래스의 버그)로 _die_chosen_locked
## 플래그를 갖는다 — 같은 프레임에 같은 버튼이 두 번 눌려도 die_inventory가 조용히
## 오염되지 않아야 한다.
func _check_customize_panel_double_die_chosen_guard(lines: PackedStringArray) -> bool:
	var ok := true
	var die_backup: Array[int] = RunState.die_inventory.duplicate()

	var script := load("res://code/scenes/customize_panel.gd")
	var panel = script.new()

	var bag := DiceBag.new(4, 1)
	RunState.die_inventory = [8, 10]
	panel._show_die_target_picker(0)

	panel._on_die_target_chosen(bag, 0, 0)
	var first_ok: bool = bag.dice[0].size() == 8 and RunState.die_inventory == [10, 4]
	ok = first_ok and ok
	lines.append("  1차 교환: 면개수=%d inventory=%s (기대 8, [10, 4]) -> %s" % [
		bag.dice[0].size(), RunState.die_inventory, "OK" if first_ok else "FAIL"
	])

	# 같은 프레임에 같은 버튼이 다시 눌려도(더블클릭 가정), 이미 교환이 끝난 뒤라
	# 아무 일도 일어나선 안 된다.
	panel._on_die_target_chosen(bag, 0, 0)
	var guard_ok: bool = bag.dice[0].size() == 8 and RunState.die_inventory == [10, 4]
	ok = guard_ok and ok
	lines.append("  2차 교환 재시도(이미 교환함): 면개수=%d inventory=%s (기대 변화 없음) -> %s" % [
		bag.dice[0].size(), RunState.die_inventory, "OK" if guard_ok else "FAIL"
	])

	panel.free()
	RunState.die_inventory = die_backup
	return ok
