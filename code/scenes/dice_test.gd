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
	lines.append("[던전 맵 방 선택지 결정성 검증: dungeon_map.gd _room_options_for_index]")
	all_pass = _check_dungeon_map_room_options(lines) and all_pass

	lines.append("")
	lines.append("[스토리 이벤트 골드 클램프 검증: story_event.gd _apply_gold_delta]")
	all_pass = _check_story_event_gold_delta(lines) and all_pass

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

	# is_applicable(): UI가 이 결과로 버튼을 비활성화해 위 회귀 버그와 같은 상황(승급
	# 대상 없는 아이템을 헛되이 제시하는 것)을 애초에 막는다. 대상이 없는/있는 두
	# 케이스 모두 확인.
	var no_target_bag := DiceBag.new(6, 1)
	var no_target_applicable := DiceItemPool.is_applicable({"kind": "upgrade_die", "new_sides": 6}, no_target_bag)
	var no_target_ok := no_target_applicable == false
	ok = no_target_ok and ok
	lines.append("  is_applicable(upgrade_die, 대상 없음): %s (기대 false) -> %s" % [no_target_applicable, "OK" if no_target_ok else "FAIL"])

	var has_target_bag := DiceBag.new(4, 1)
	var has_target_applicable := DiceItemPool.is_applicable({"kind": "upgrade_die", "new_sides": 6}, has_target_bag)
	var has_target_ok := has_target_applicable == true
	ok = has_target_ok and ok
	lines.append("  is_applicable(upgrade_die, 대상 있음): %s (기대 true) -> %s" % [has_target_applicable, "OK" if has_target_ok else "FAIL"])

	var non_upgrade_applicable := DiceItemPool.is_applicable({"kind": "add_die", "sides": 4}, no_target_bag)
	var non_upgrade_ok := non_upgrade_applicable == true
	ok = non_upgrade_ok and ok
	lines.append("  is_applicable(add_die, 항상 적용 가능): %s (기대 true) -> %s" % [non_upgrade_applicable, "OK" if non_upgrade_ok else "FAIL"])

	# random_choices(n, attack_bag, defense_bag): 두 주머니 모두 승급 대상이 없으면
	# (여기서는 공격/방어 둘 다 D6x3, upgrade_die new_sides=6) 그 아이템 자체를 후보에서
	# 제외해야 한다 — 안 그러면 보상 2개 중 하나가 양쪽 버튼 다 비활성화된 채로 뽑혀
	# 슬롯 하나가 통째로 낭비된다(이번 이터레이션에서 고친 부분). n=2(적용 가능한 3개 중
	# 2개 요청, 필터링 조건 3>=2 충족)로 셔플 결과와 무관하게 upgrade_die가 절대 안
	# 뽑히는지 여러 번 반복해 확인한다.
	var maxed_attack := DiceBag.new(6, 3)
	var maxed_defense := DiceBag.new(6, 3)
	var filtered_has_upgrade := false
	for _i in 20: # 셔플이라 한 번만 확인하면 우연히 안 뽑힐 수 있어 반복 확인
		var picks := DiceItemPool.random_choices(2, maxed_attack, maxed_defense)
		for it in picks:
			if it["kind"] == "upgrade_die":
				filtered_has_upgrade = true
	var filtered_ok := not filtered_has_upgrade
	ok = filtered_ok and ok
	lines.append("  random_choices(2, 양쪽 승급대상 없음, 20회 반복): upgrade_die포함=%s (기대 false) -> %s" % [
		filtered_has_upgrade, "OK" if filtered_ok else "FAIL"
	])

	# n(4)이 필터링 후 남는 후보(3개)보다 많으면, 요청한 개수보다 적게 주는 대신
	# 안전하게 필터링 이전 전체 목록(4개, upgrade_die 포함)으로 돌아가야 한다 —
	# "선택지가 아예 부족해지는 것"이 "가끔 비활성화된 아이템이 섞이는 것"보다 더
	# 나쁜 실패 모드이기 때문.
	var fallback_choices := DiceItemPool.random_choices(4, maxed_attack, maxed_defense)
	var fallback_ok := fallback_choices.size() == 4
	ok = fallback_ok and ok
	lines.append("  random_choices(4, 적용가능 3개뿐): 개수=%d (기대 4, 부족하면 필터링 이전으로 폴백) -> %s" % [
		fallback_choices.size(), "OK" if fallback_ok else "FAIL"
	])

	# 정상 케이스(승급 대상 있음)에서는 필터링이 아무것도 제외하지 않아 기존과 동일하게
	# 동작해야 한다(하위 호환 확인).
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
