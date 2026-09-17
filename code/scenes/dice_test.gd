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
	lines.append("[몬스터 디버그 정보 문구 검증: combat_test.gd _monster_debug_info_text]")
	all_pass = _check_monster_debug_info_text(lines) and all_pass

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
	lines.append("[보상 등급 검증: item_card_style.gd ItemCardStyle.grade_color + 아이템 grade 필드]")
	all_pass = _check_item_grades(lines) and all_pass

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
	lines.append("[보스 방 라운드 진행 검증: combat_test.gd _apply_room_advance / RunState.advance_round]")
	all_pass = _check_combat_boss_round_advance(lines) and all_pass

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
	lines.append("[업적 유형별 아이콘 검증: achievement_manager.gd DEFINITIONS.icon / achievement_icon.gd AchievementIcon]")
	all_pass = _check_achievement_icons(lines) and all_pass

	lines.append("")
	lines.append("[라운드/캐릭터 클리어 업적 검증: combat_test.gd _apply_room_advance / _unlock_round_clear_achievements]")
	all_pass = _check_round_clear_achievements(lines) and all_pass

	lines.append("")
	lines.append("[플레이어블 캐릭터 검증: character_profiles.gd CharacterProfiles / run_state.gd RunState._apply_character_gimmick]")
	all_pass = _check_character_profiles(lines) and all_pass

	lines.append("")
	lines.append("[캐릭터 스킬 아이콘 검증: character_profiles.gd PROFILES.gimmick / skill_icon.gd SkillIcon]")
	all_pass = _check_skill_icons(lines) and all_pass

	lines.append("")
	lines.append("[이벤트 주사위 필드 검증: character_profiles.gd PROFILES.event_die_sides / run_state.gd RunState.event_die_sides / event_die_visual.gd EventDieVisual]")
	all_pass = _check_event_die_sides(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 상황 문구 검증: event_item_pool.gd EventItemPool.ITEMS.flavor / item_card_style.gd ItemCardStyle.build_card]")
	all_pass = _check_event_item_flavor(lines) and all_pass

	lines.append("")
	lines.append("[특수 이벤트 안전/위험 선택 + DC 난이도 체크 검증: event.gd difficulty_for_room / _resolve_risky / _apply_fail, event_item_pool.gd random_safe_item / random_risky_item]")
	all_pass = _check_event_safe_risky_choice(lines) and all_pass

	lines.append("")
	lines.append("[패배 업적 검증: combat_test.gd _unlock_defeat_achievement / achievement_manager.gd \"first_defeat\"]")
	all_pass = _check_defeat_achievement(lines) and all_pass

	lines.append("")
	lines.append("[라운드 진행 검증: run_state.gd RunState.round_index / advance_round / is_last_round]")
	all_pass = _check_round_progress(lines) and all_pass

	lines.append("")
	lines.append("[키보드 단축키 검증: keyboard_shortcuts.gd KeyboardShortcuts]")
	all_pass = _check_keyboard_shortcuts(lines) and all_pass

	lines.append("")
	lines.append("[캐릭터 스킬 이벤트 구조 검증: skill_pool.gd SkillPool / event.gd _setup_skill_event / RunState.skill_flags]")
	all_pass = _check_skill_event_structure(lines) and all_pass

	lines.append("")
	lines.append("[캐릭터 스킬 실제 효과 검증: dice_bag.gd apply_flat_bonus / skill_pool.gd UNIQUE_SKILLS / combat_test.gd _apply_spare_die+player_frenzy_active]")
	all_pass = _check_skill_effects(lines) and all_pass

	lines.append("")
	lines.append("[스킬 강화판 검증: skill_pool.gd UPGRADE_SKILLS / available_upgrade_choices / grant_upgrade]")
	all_pass = _check_upgrade_skill_pool(lines) and all_pass

	lines.append("")
	lines.append("[스킬 강화 이벤트 구조 검증: event.gd _setup_skill_upgrade_event / SKILL_UPGRADE_EVENT_CHANCE 폴백]")
	all_pass = _check_skill_upgrade_event_structure(lines) and all_pass

	lines.append("")
	lines.append("[스킬 강화 카드 강조 검증: item_card_style.gd build_card() highlight 파라미터]")
	all_pass = _check_skill_upgrade_card_highlight(lines) and all_pass

	lines.append("")
	lines.append("[시작 스킬 후보 검증: skill_pool.gd SkillPool.STARTING_SKILLS / starting_skills_for_character]")
	all_pass = _check_starting_skills(lines) and all_pass

	lines.append("")
	lines.append("[시작 스킬 선택 UI 검증: character_select.gd 슬롯 0/1 + 잠금 상태]")
	all_pass = _check_starting_skill_selection_ui(lines) and all_pass

	lines.append("")
	lines.append("[시작 스킬 적용 배선 검증: run_state.gd reset_run() -> SkillPool.grant() / combat_test.gd 조건부 apply_flat_bonus]")
	all_pass = _check_starting_skill_combat_wiring(lines) and all_pass

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
	# 통째로 안 보이거나(버튼 없음) 중복 렌더링될 수 있다. 단, 라운드 마지막 방
	# (idx == TOTAL_ROOMS - 1, 보스 방)은 2026-09-14 버그 수정으로 전투만 가능하도록
	# 강제되어 shop/event/story가 전부 false + order가 빈 배열인 것이 의도된 예외다.
	var order_valid := true
	for idx in range(10):
		var opts = map._room_options_for_index(idx)
		if idx == RunState.TOTAL_ROOMS - 1:
			if opts.shop or opts.event or opts.story or not opts.order.is_empty():
				order_valid = false
			continue
		var sorted_order: Array = opts.order.duplicate()
		sorted_order.sort()
		if sorted_order != ["event", "shop", "story"]:
			order_valid = false
	ok = order_valid and ok
	lines.append("  order가 항상 shop/event/story 순열임(idx 0..9, 보스 방 idx=%d는 예외로 3종 전부 미노출 확인): %s -> %s" % [
		RunState.TOTAL_ROOMS - 1, order_valid, "OK" if order_valid else "FAIL"
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
	# room_index == RunState.TOTAL_ROOMS - 1(지금은 4)은 "보스" 보정(공격+2/방어+1/HP*2)이
	# 추가로 붙으므로 그 방만 별도로 기대값을 조정한다.
	var formula_ok := true
	for idx in range(7):
		var cfg = combat._monster_config_for_room(idx)
		var expected_attack := 2 + int(idx / 2.0)
		var expected_defense := 1 + int(idx / 3.0)
		var expected_hp := 10 + idx * 3
		var expected_sides := 8 if idx >= 4 else (6 if idx >= 2 else 4)
		if idx == RunState.TOTAL_ROOMS - 1:
			expected_attack += 2
			expected_defense += 1
			expected_hp *= 2
		if cfg["attack_count"] != expected_attack or cfg["defense_count"] != expected_defense \
			or cfg["max_hp"] != expected_hp or cfg["dice_sides"] != expected_sides:
			formula_ok = false
	ok = formula_ok and ok
	lines.append("  room 0..6 스케일링 공식 일치(공격/방어/hp/면개수, 보스방 보정 포함): %s -> %s" % [
		formula_ok, "OK" if formula_ok else "FAIL"
	])

	# 보스(room_index == TOTAL_ROOMS-1 == 4)만 is_boss=true + 이름에 "[보스]"가 붙어야
	# 하고, 다른 방(room0/room3)은 영향받지 않아야 한다.
	var boss_cfg = combat._monster_config_for_room(RunState.TOTAL_ROOMS - 1)
	var non_boss_cfg = combat._monster_config_for_room(0)
	var boss_ok: bool = boss_cfg["is_boss"] == true and boss_cfg["name"].ends_with("[보스]") \
		and non_boss_cfg["is_boss"] == false and not non_boss_cfg["name"].ends_with("[보스]")
	ok = boss_ok and ok
	lines.append("  보스 방(room%d) is_boss/이름 태그, room0 영향 없음: boss=%s name=%s room0=%s -> %s" % [
		RunState.TOTAL_ROOMS - 1, boss_cfg["is_boss"], boss_cfg["name"], non_boss_cfg["is_boss"],
		"OK" if boss_ok else "FAIL"
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


## combat_test.gd의 _monster_debug_info_text(config)는 INBOX.md 피드백(2026-09-14)
## "전투 시, 몬스터 hp바 하단에 해당 몬스터에 대한 스킬/전투 정보를 알려준다"를 구현한
## 순수 함수 — _monster_config_for_room()이 만든 config dict만 받아 텍스트를 만들고
## 인스턴스 상태(다이스 굴림 등)를 쓰지 않으므로 다이스를 실제로 굴리지 않고도 검증
## 가능(_check_monster_config_scaling과 같은 패턴).
func _check_monster_debug_info_text(lines: PackedStringArray) -> bool:
	var ok := true
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	# room0(슬라임, 기믹 없음): 공격/방어 다이스 구성 + 성격 문구가 나오고 기믹/보스 줄은
	# 없어야 한다 ([미니 기획 A]-3, 2026-09-16으로 personality 필드가 추가됨).
	var room0_text: String = combat._monster_debug_info_text(combat._monster_config_for_room(0))
	var room0_ok: bool = room0_text.contains("공격 2D4") and room0_text.contains("방어 1D4") \
		and room0_text.contains("성격: 무기력하고 단순함") \
		and not room0_text.contains("기믹") and not room0_text.contains("보스")
	ok = room0_ok and ok
	lines.append("  room0(슬라임, 기믹 없음): %s -> %s" % [
		room0_text.replace("\n", " / "), "OK" if room0_ok else "FAIL"
	])

	# room1(고블린, anger_stack): 분노 스택 임계치/굴림 면 수가 문구에 그대로 드러나야 한다.
	var room1_text: String = combat._monster_debug_info_text(combat._monster_config_for_room(1))
	var room1_ok: bool = room1_text.contains("분노 스택") \
		and room1_text.contains(str(combat.ANGER_STACK_THRESHOLD)) \
		and room1_text.contains("1D%d" % combat.ANGER_DICE_SIDES)
	ok = room1_ok and ok
	lines.append("  room1(고블린, anger_stack): %s -> %s" % [
		room1_text.replace("\n", " / "), "OK" if room1_ok else "FAIL"
	])

	# room2(해골 전사, fixed_value): 고정값 자체가 문구에 그대로 드러나야 한다
	# (2026-09-16 [미니 기획 A]-1로 "오크"에서 옮겨짐).
	var room2_config = combat._monster_config_for_room(2)
	var room2_text: String = combat._monster_debug_info_text(room2_config)
	var room2_ok: bool = room2_text.contains("고정값") \
		and room2_text.contains(str(room2_config["dice_gimmick_value"]))
	ok = room2_ok and ok
	lines.append("  room2(해골 전사, fixed_value=%d): %s -> %s" % [
		room2_config["dice_gimmick_value"], room2_text.replace("\n", " / "), "OK" if room2_ok else "FAIL"
	])

	# room3(오크, min_max_only): 극단 기믹 문구가 드러나야 한다
	# (2026-09-16 [미니 기획 A]-1로 "다크 나이트"에서 옮겨짐).
	var room3_text: String = combat._monster_debug_info_text(combat._monster_config_for_room(3))
	var room3_ok: bool = room3_text.contains("극단")
	ok = room3_ok and ok
	lines.append("  room3(오크, min_max_only): %s -> %s" % [
		room3_text.replace("\n", " / "), "OK" if room3_ok else "FAIL"
	])

	# room4(다크 나이트, steady_guard + 보스, [미니 기획 A]-2로 2026-09-16 구현): 하한선
	# 값(D8 -> ceil(8/2)=4)과 보스 강화 문구가 둘 다 있어야 한다.
	var room4_config: Dictionary = combat._monster_config_for_room(RunState.TOTAL_ROOMS - 1)
	var room4_text: String = combat._monster_debug_info_text(room4_config)
	var room4_ok: bool = room4_text.contains("보스") and room4_text.contains("철벽") \
		and room4_text.contains(str(room4_config["dice_gimmick_value"])) \
		and room4_text.contains("성격: 차갑고 노련하며 방어에서 흔들리지 않는 기사")
	ok = room4_ok and ok
	lines.append("  room4(다크 나이트, steady_guard=%d + 보스): %s -> %s" % [
		room4_config["dice_gimmick_value"], room4_text.replace("\n", " / "), "OK" if room4_ok else "FAIL"
	])

	combat.free()
	return ok


## dice_bag.gd의 force_min_max_faces()/force_fixed_value()/count_max_rolls()는 INBOX.md
## 피드백(2026-09-09, "몬스터별 다이스 특이 특징" 예시 3개: "모든 주사위 눈이 min과
## max로만 이루어져 있다" / "주사위 값 x가 고정 데미지로 들어간다" / "주사위 x가 나올
## 때마다 분노 스택이 쌓여서 몇 개 이상이면 다음 턴에 20면체를 돌린다")를 구현한 것이다.
## combat_test.gd는 2026-09-16 [미니 기획 A]-1(몬스터 성격 기획)로 재배정된 뒤
## force_min_max_faces()를 "오크"(MONSTER_PROFILES 4번째, dice_gimmick="min_max_only",
## room_index=3)에, force_fixed_value()를 "해골 전사"(3번째, dice_gimmick="fixed_value",
## room_index=2)에, count_max_rolls() 기반 분노 스택 집계를 "고블린"(2번째,
## dice_gimmick="anger_stack", room_index=1)에 각각 적용한다. [미니 기획 A]-2(2026-09-16,
## 별도 이터레이션)로 "다크 나이트"(5번째, dice_gimmick="steady_guard", room_index=4)에
## apply_steady_guard() 기반 방어 결과 하한선 보정이 배정됐다 — 서로 다른 방에서만
## 켜지고, 다른 방(예: room0 슬라임)은 그대로 표준 다이스여야 한다.
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

	# combat_test.gd _monster_config_for_room(): 2026-09-16 [미니 기획 A]-1로 min_max_only가
	# "다크 나이트"에서 "오크"(room3)로 옮겨졌다 — room3만 gimmick이 켜지고 이름에 "[극단]"이
	# 붙어야 하며, room0(슬라임)은 영향받지 않아야 한다. room4(다크 나이트)는 [미니 기획 A]-2
	# (2026-09-16, 별도 이터레이션)로 steady_guard가 배정돼 이름에 "[철벽]"이 붙고,
	# "보스" 방(room_index == RunState.TOTAL_ROOMS-1)이라 그 뒤에 "[보스]"까지 이어 붙는다.
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	var room3_minmax_config = combat._monster_config_for_room(3)
	var room3_minmax_ok: bool = room3_minmax_config["dice_gimmick"] == "min_max_only" and room3_minmax_config["name"] == "오크 [극단]"
	ok = room3_minmax_ok and ok
	lines.append("  room3 config: dice_gimmick=%s name=%s (기대 min_max_only, '오크 [극단]') -> %s" % [
		room3_minmax_config["dice_gimmick"], room3_minmax_config["name"], "OK" if room3_minmax_ok else "FAIL"
	])
	var room4_config = combat._monster_config_for_room(4)
	var room4_ok: bool = room4_config["dice_gimmick"] == "steady_guard" \
		and room4_config["dice_gimmick_value"] == 4 \
		and room4_config["name"] == "다크 나이트 [철벽] [보스]"
	ok = room4_ok and ok
	lines.append("  room4 config: dice_gimmick=%s value=%d name=%s (기대 steady_guard/4/'다크 나이트 [철벽] [보스]') -> %s" % [
		room4_config["dice_gimmick"], room4_config["dice_gimmick_value"], room4_config["name"],
		"OK" if room4_ok else "FAIL"
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

	# apply_steady_guard() ([미니 기획 A]-2, "다크 나이트"): D6x3 주머니에서 하한선은
	# ceil(6/2.0)=3 — 이 값 미만(1,2)은 3으로 끌어올려지고, 그 이상(3,4,5,6)은 그대로
	# 유지돼야 한다. 면 값 자체(dice 배열)는 건드리지 않고 굴림 "결과값"만 보정하는지도
	# 함께 확인(force_fixed_value처럼 faces를 바꿔버리면 이후 다른 굴림까지 영향을 주므로).
	var guard_bag := DiceBag.new(6, 3)
	var guard_input := [1, 2, 3]
	var guard_adjusted: Array = guard_bag.apply_steady_guard(guard_input)
	var guard_floor_ok: bool = guard_adjusted == [3, 3, 3]
	ok = guard_floor_ok and ok
	lines.append("  apply_steady_guard(D6x3, [1,2,3]): adjusted=%s (기대 [3,3,3]) -> %s" % [
		guard_adjusted, "OK" if guard_floor_ok else "FAIL"
	])
	var guard_high_input := [4, 5, 6]
	var guard_high_adjusted: Array = guard_bag.apply_steady_guard(guard_high_input)
	var guard_high_ok: bool = guard_high_adjusted == [4, 5, 6]
	ok = guard_high_ok and ok
	lines.append("  apply_steady_guard(D6x3, [4,5,6], 하한선 이상은 그대로): adjusted=%s (기대 [4,5,6]) -> %s" % [
		guard_high_adjusted, "OK" if guard_high_ok else "FAIL"
	])
	var guard_faces_untouched_ok: bool = guard_bag.dice[0][0] == 1
	ok = guard_faces_untouched_ok and ok
	lines.append("  apply_steady_guard 호출 후 면 값 자체는 안 바뀜: dice[0][0]=%d (기대 1) -> %s" % [
		guard_bag.dice[0][0], "OK" if guard_faces_untouched_ok else "FAIL"
	])

	# combat_test.gd _monster_config_for_room(): 2026-09-16 [미니 기획 A]-1로 fixed_value가
	# "오크"에서 "해골 전사"(room2)로 옮겨졌다 — room2(해골 전사, D6)만 fixed_value gimmick이
	# 켜지고 이름에 "[고정값 4]"가 붙어야 한다(D6 -> ceil(7/2)=4). min_max_only(room3)와
	# 서로 영향 없이 독립적으로 동작해야 함.
	var room2_config = combat._monster_config_for_room(2)
	var room2_ok: bool = room2_config["dice_gimmick"] == "fixed_value" \
		and room2_config["dice_gimmick_value"] == 4 \
		and room2_config["name"] == "해골 전사 [고정값 4]"
	ok = room2_ok and ok
	lines.append("  room2 config: dice_gimmick=%s value=%d name=%s (기대 fixed_value/4/'해골 전사 [고정값 4]') -> %s" % [
		room2_config["dice_gimmick"], room2_config["dice_gimmick_value"], room2_config["name"],
		"OK" if room2_ok else "FAIL"
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


## INBOX.md(2026-09-14) "보상 팝업의 밸류에 따라 등급(S/A/B/C)을 나누고, 카드에 등급을
## 표시하며 녹색<파랑<보라<노랑 색을 테두리/타이틀에 적용" 반영분 검증.
## (1) DiceItemPool/EventItemPool의 모든 아이템이 유효한 grade(S/A/B/C)를 갖는지,
## (2) ItemCardStyle.grade_color()가 등급 4개마다 서로 다른 색을 반환하는지(색이 겹치면
## "가치 상승"이 눈으로 구별 안 되므로), (3) 알 수 없는/누락된 grade는 C색으로 안전하게
## 폴백하는지 확인한다.
func _check_item_grades(lines: PackedStringArray) -> bool:
	var ok := true
	var valid_grades := ["S", "A", "B", "C"]

	for item in DiceItemPool.ITEMS:
		var grade: String = item.get("grade", "")
		var pair_ok := valid_grades.has(grade)
		ok = pair_ok and ok
		lines.append("  DiceItemPool \"%s\" grade=%s -> %s" % [item["name"], grade, "OK" if pair_ok else "FAIL"])

	for item in EventItemPool.ITEMS:
		var grade: String = item.get("grade", "")
		var pair_ok := valid_grades.has(grade)
		ok = pair_ok and ok
		lines.append("  EventItemPool \"%s\" grade=%s -> %s" % [item["name"], grade, "OK" if pair_ok else "FAIL"])

	var seen_colors: Array[Color] = []
	var distinct_ok := true
	for grade in valid_grades:
		var color := ItemCardStyle.grade_color(grade)
		if seen_colors.has(color):
			distinct_ok = false
		seen_colors.append(color)
	ok = distinct_ok and ok
	lines.append("  등급 4종 색상 서로 구별됨 -> %s" % ("OK" if distinct_ok else "FAIL"))

	var fallback_ok := ItemCardStyle.grade_color("?") == ItemCardStyle.grade_color("C")
	ok = fallback_ok and ok
	lines.append("  알 수 없는 등급 -> C색 폴백 -> %s" % ("OK" if fallback_ok else "FAIL"))

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


## INBOX.md [미니 기획 B] 2~3번(2026-09-16, "선택지를 안전하게 넘어가기/위험을
## 감수하기 2개로 통일" + "이벤트 다이스로 DC 난이도 체크") 검증. (1)
## event.gd.difficulty_for_room()이 DESIGN.md 공식(min(5, 3 + room_index/2))대로
## 방 0~1=DC3, 2~3=DC4, 4 이상=DC5를 내는지. (2) [기획자 결정 - 2026-09-16, B급(D8)
## 사각지대 해결안 (b)] EventItemPool.random_safe_item()이 C/B급만(B는 가중치가 낮아
## 드물게), random_risky_item()이 B/A/S급만(B는 가중치가 낮아 드물게) 반환하고, 두 풀
## 모두에서 B급이 실제로 뽑힐 수 있는지(사각지대가 없는지). (3) "위험을 감수하기"를
## RNG 없이 결정적으로 강제(_debug_force_risky_success/failure)했을 때 성공하면 아이템
## 카드(_row_ui)가 뜨고 실패하면 실패 문구+계속 버튼만 뜨는지. (4) 실패 후 "계속"
## (_apply_fail)이 _apply_pick/_apply_pips/_apply_upgrade와 동일한 이중 실행 가드를
## 갖는지(같은 _picked 플래그 재사용).
func _check_event_safe_risky_choice(lines: PackedStringArray) -> bool:
	var ok := true
	var event_script := load("res://code/scenes/event.gd")

	var dc0: int = event_script.difficulty_for_room(0)
	var dc1: int = event_script.difficulty_for_room(1)
	var dc2: int = event_script.difficulty_for_room(2)
	var dc3: int = event_script.difficulty_for_room(3)
	var dc4: int = event_script.difficulty_for_room(4)
	var dc10: int = event_script.difficulty_for_room(10)
	var dc_ok := dc0 == 3 and dc1 == 3 and dc2 == 4 and dc3 == 4 and dc4 == 5 and dc10 == 5
	ok = dc_ok and ok
	lines.append("  difficulty_for_room(0/1/2/3/4/10)=%d/%d/%d/%d/%d/%d(기대 3/3/4/4/5/5) -> %s" % [
		dc0, dc1, dc2, dc3, dc4, dc10, "OK" if dc_ok else "FAIL"
	])

	## [기획자 결정 - 2026-09-16] B급(D8) 사각지대 해결안 (b) 검증: 안전 풀은 C/B만,
	## 위험 성공 풀은 B/A/S만 나와야 하고(등급 범위 자체는 여전히 좁힘), B급은 두 풀
	## 모두에서 뽑힐 수 있어야 한다(가중치가 낮아 드물 뿐 불가능하지 않아야 함).
	var safe_grades_ok := true
	var safe_saw_b := false
	for i in 200:
		var g_safe: String = EventItemPool.random_safe_item().get("grade", "")
		if g_safe != "C" and g_safe != "B":
			safe_grades_ok = false
		if g_safe == "B":
			safe_saw_b = true
	ok = safe_grades_ok and ok
	ok = safe_saw_b and ok
	lines.append("  random_safe_item() 200회 전부 grade=C/B, B급 목격 -> %s (B 목격: %s)" % [
		"OK" if safe_grades_ok else "FAIL", "예" if safe_saw_b else "아니오"
	])

	var risky_grades_ok := true
	var risky_saw_b := false
	for i in 200:
		var g: String = EventItemPool.random_risky_item().get("grade", "")
		if g != "B" and g != "A" and g != "S":
			risky_grades_ok = false
		if g == "B":
			risky_saw_b = true
	ok = risky_grades_ok and ok
	ok = risky_saw_b and ok
	lines.append("  random_risky_item() 200회 전부 grade=B/A/S, B급 목격 -> %s (B 목격: %s)" % [
		"OK" if risky_grades_ok else "FAIL", "예" if risky_saw_b else "아니오"
	])

	var rooms_backup := RunState.rooms_cleared
	RunState.rooms_cleared = 0

	AchievementManager._debug_reset_for_qa()
	var event_scene := load("res://code/scenes/event.tscn")
	var success_node = event_scene.instantiate()
	add_child(success_node)
	success_node._debug_force_risky_success()
	var success_card_ok: bool = success_node._row_ui.size() == 1
	ok = success_card_ok and ok
	lines.append("  위험 감수 강제 성공 -> 아이템 카드 표시(_row_ui.size()==1) -> %s" % ("OK" if success_card_ok else "FAIL"))
	var risk_taker_unlocked_ok: bool = AchievementManager.is_unlocked("risk_taker")
	ok = risk_taker_unlocked_ok and ok
	lines.append("  위험 감수 강제 성공 -> \"risk_taker\" 업적 해금 -> %s" % ("OK" if risk_taker_unlocked_ok else "FAIL"))
	remove_child(success_node)
	success_node.free()

	AchievementManager._debug_reset_for_qa()
	var fail_node = event_scene.instantiate()
	add_child(fail_node)
	fail_node._debug_force_risky_failure()
	var fail_ui_ok: bool = fail_node.fail_label.visible and fail_node.continue_button.visible and fail_node._row_ui.is_empty()
	ok = fail_ui_ok and ok
	lines.append("  위험 감수 강제 실패 -> 실패 문구+계속 버튼 표시, 아이템 카드 없음 -> %s" % ("OK" if fail_ui_ok else "FAIL"))
	var risk_taker_not_unlocked_ok: bool = not AchievementManager.is_unlocked("risk_taker")
	ok = risk_taker_not_unlocked_ok and ok
	lines.append("  위험 감수 강제 실패 -> \"risk_taker\" 업적 미해금 -> %s" % ("OK" if risk_taker_not_unlocked_ok else "FAIL"))

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = fail_node._apply_fail()
	var first_ok: bool = first_applied and RunState.rooms_cleared == rooms_before + 1
	ok = first_ok and ok
	lines.append("  실패 후 계속(1차): applied=%s rooms=%d(기대 %d) -> %s" % [
		first_applied, RunState.rooms_cleared, rooms_before + 1, "OK" if first_ok else "FAIL"
	])
	var second_applied: bool = fail_node._apply_fail()
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1
	ok = guard_ok and ok
	lines.append("  실패 후 계속(2차, 이중 실행 가드): applied=%s rooms=%d(변화 없어야 함) -> %s" % [
		second_applied, RunState.rooms_cleared, "OK" if guard_ok else "FAIL"
	])
	remove_child(fail_node)
	fail_node.free()

	AchievementManager._debug_reset_for_qa()
	RunState.rooms_cleared = rooms_backup
	return ok


## STATUS.md 큐 13 후속: combat_test.gd의 패배 분기(player_hp <= 0)가 지금까지 unlock()
## 호출이 하나도 없던 유일한 결과 분기였다 — 승리 쪽(win_with_d20/flawless/comeback/
## overkill/gold_100)과 대칭을 맞춰 "first_defeat"를 추가했다. _check_round_clear_
## achievements()와 같은 패턴으로, 물리 코루틴 없이 _unlock_defeat_achievement()를 직접
## 호출해 검증한다.
func _check_defeat_achievement(lines: PackedStringArray) -> bool:
	var ok := true

	AchievementManager._debug_reset_for_qa()
	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()
	var unlocked_before := AchievementManager.is_unlocked("first_defeat")
	combat._unlock_defeat_achievement()
	var unlocked_after := AchievementManager.is_unlocked("first_defeat")
	var check_ok := (not unlocked_before) and unlocked_after
	ok = check_ok and ok
	lines.append("  _unlock_defeat_achievement() 호출 전/후: first_defeat=%s/%s(기대 false/true) -> %s" % [
		unlocked_before, unlocked_after, "OK" if check_ok else "FAIL"
	])
	combat.free()

	AchievementManager._debug_reset_for_qa()
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


## [대형 기획 2] 조각 (b) 검증: combat_test.gd _apply_room_advance()가 보스 방 승리
## (monster_is_boss=true) + 마지막 라운드가 아닐 때만 RunState.advance_round()를 실제로
## 불러 라운드를 넘기는지 확인한다. 일반 방 승리(monster_is_boss=false)나 이미 마지막
## 라운드인 경우는 round_index가 그대로여야 한다(advance_round() 자체의 가드는
## _check_round_progress()가 이미 검증하므로, 여기서는 _apply_room_advance()가 그 가드를
## 우회하지 않고 올바른 조건에서만 호출하는지가 초점).
func _check_combat_boss_round_advance(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index

	var combat_script := load("res://code/scenes/combat_test.gd")

	RunState.round_index = 1
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat1 = combat_script.new()
	combat1.player_won = true
	combat1.monster_is_boss = false
	combat1._apply_room_advance()
	var case1_ok := RunState.rooms_cleared == RunState.TOTAL_ROOMS and RunState.round_index == 1
	ok = case1_ok and ok
	lines.append("  일반 방 승리(보스 아님): rooms=%d round=%d (기대 %d, 1) -> %s" % [
		RunState.rooms_cleared, RunState.round_index, RunState.TOTAL_ROOMS, "OK" if case1_ok else "FAIL"
	])
	combat1.free()

	RunState.round_index = 1
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat2 = combat_script.new()
	combat2.player_won = true
	combat2.monster_is_boss = true
	combat2._apply_room_advance()
	var case2_ok := RunState.round_index == 2 and RunState.rooms_cleared == 0
	ok = case2_ok and ok
	lines.append("  보스 방 승리(1라운드 -> 2라운드): rooms=%d round=%d (기대 0, 2) -> %s" % [
		RunState.rooms_cleared, RunState.round_index, "OK" if case2_ok else "FAIL"
	])
	combat2.free()

	RunState.round_index = RunState.TOTAL_ROUNDS
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat3 = combat_script.new()
	combat3.player_won = true
	combat3.monster_is_boss = true
	combat3._apply_room_advance()
	var case3_ok := RunState.round_index == RunState.TOTAL_ROUNDS and RunState.rooms_cleared == RunState.TOTAL_ROOMS
	ok = case3_ok and ok
	lines.append("  보스 방 승리(마지막 라운드, 최종 클리어): rooms=%d round=%d (기대 %d, %d) -> %s" % [
		RunState.rooms_cleared, RunState.round_index, RunState.TOTAL_ROOMS, RunState.TOTAL_ROUNDS, "OK" if case3_ok else "FAIL"
	])
	combat3.free()

	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	return ok


## STATUS.md 큐 13 검증: combat_test.gd의 _apply_room_advance()가 보스를 잡은 시점에
## 라운드 1/2/최종(라운드 3) 클리어 업적과, 최종 클리어일 때는 지금 플레이 중인
## 캐릭터 전용 "clear_<id>" 업적까지 정확히 unlock하는지 확인한다. 이 작업 중 발견한
## 버그(예전에는 dungeon_map.gd가 RunState.is_run_complete() 기준으로 "round1_clear"를
## 판정해, advance_round()가 매 라운드 즉시 rooms_cleared를 0으로 되돌리는 바람에 실제로는
## "최종 라운드까지 전부 클리어"할 때만 불렸던 것)의 회귀를 막기 위한 케이스다.
func _check_round_clear_achievements(lines: PackedStringArray) -> bool:
	var ok := true
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	var character_backup := RunState.character_id

	AchievementManager._debug_reset_for_qa()
	var combat_script := load("res://code/scenes/combat_test.gd")

	# 라운드 1 보스 클리어 -> "round1_clear"만 해금, round2_clear/game_clear는 아직 아님.
	RunState.round_index = 1
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat1 = combat_script.new()
	combat1.player_won = true
	combat1.monster_is_boss = true
	combat1._apply_room_advance()
	var round1_ok := AchievementManager.is_unlocked("round1_clear")
	var round1_no_overreach_ok := (not AchievementManager.is_unlocked("round2_clear")
		and not AchievementManager.is_unlocked("game_clear"))
	ok = round1_ok and round1_no_overreach_ok and ok
	lines.append("  라운드 1 보스 클리어: round1_clear=%s(기대 true) round2/game_clear=%s(기대 둘 다 false) -> %s" % [
		AchievementManager.is_unlocked("round1_clear"),
		[AchievementManager.is_unlocked("round2_clear"), AchievementManager.is_unlocked("game_clear")],
		"OK" if (round1_ok and round1_no_overreach_ok) else "FAIL"
	])
	combat1.free()

	# 라운드 2 보스 클리어 -> "round2_clear" 추가 해금, game_clear는 아직 아님.
	RunState.round_index = 2
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat2 = combat_script.new()
	combat2.player_won = true
	combat2.monster_is_boss = true
	combat2._apply_room_advance()
	var round2_ok := AchievementManager.is_unlocked("round2_clear")
	var round2_no_overreach_ok := not AchievementManager.is_unlocked("game_clear")
	ok = round2_ok and round2_no_overreach_ok and ok
	lines.append("  라운드 2 보스 클리어: round2_clear=%s(기대 true) game_clear=%s(기대 false) -> %s" % [
		AchievementManager.is_unlocked("round2_clear"), AchievementManager.is_unlocked("game_clear"),
		"OK" if (round2_ok and round2_no_overreach_ok) else "FAIL"
	])
	combat2.free()

	# 마지막 라운드(TOTAL_ROUNDS) 보스 클리어 -> "game_clear" + 캐릭터 전용
	# "clear_<character_id>"까지 해금(광전사로 검증).
	RunState.character_id = "berserker"
	RunState.round_index = RunState.TOTAL_ROUNDS
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat3 = combat_script.new()
	combat3.player_won = true
	combat3.monster_is_boss = true
	combat3._apply_room_advance()
	var game_clear_ok := AchievementManager.is_unlocked("game_clear")
	var char_clear_ok := AchievementManager.is_unlocked("clear_berserker")
	var other_char_not_unlocked_ok := not AchievementManager.is_unlocked("clear_guardian")
	ok = game_clear_ok and char_clear_ok and other_char_not_unlocked_ok and ok
	lines.append("  마지막 라운드 보스 클리어(광전사): game_clear=%s clear_berserker=%s(기대 둘 다 true) clear_guardian=%s(기대 false) -> %s" % [
		game_clear_ok, char_clear_ok, AchievementManager.is_unlocked("clear_guardian"),
		"OK" if (game_clear_ok and char_clear_ok and other_char_not_unlocked_ok) else "FAIL"
	])
	combat3.free()

	# 일반 방 승리(monster_is_boss=false)는 어떤 라운드 클리어 업적도 건드리지 않아야 한다.
	AchievementManager._debug_reset_for_qa()
	RunState.round_index = 1
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat4 = combat_script.new()
	combat4.player_won = true
	combat4.monster_is_boss = false
	combat4._apply_room_advance()
	var no_boss_no_unlock_ok := (not AchievementManager.is_unlocked("round1_clear")
		and not AchievementManager.is_unlocked("game_clear"))
	ok = no_boss_no_unlock_ok and ok
	lines.append("  일반 방 승리(보스 아님): 라운드 클리어 업적 전부 미해금=%s(기대 true) -> %s" % [
		no_boss_no_unlock_ok, "OK" if no_boss_no_unlock_ok else "FAIL"
	])
	combat4.free()

	var all_clear_ids := ["clear_novice", "clear_berserker", "clear_guardian", "clear_explosive", "clear_shieldbearer"]
	var all_ids_defined_ok := true
	for id in all_clear_ids:
		all_ids_defined_ok = all_ids_defined_ok and AchievementManager.DEFINITIONS.has(id)
	ok = all_ids_defined_ok and ok
	lines.append("  캐릭터 5종 전부 \"clear_<id>\" 업적 정의 존재: %s -> %s" % [
		all_ids_defined_ok, "OK" if all_ids_defined_ok else "FAIL"
	])

	AchievementManager._debug_reset_for_qa()
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	RunState.character_id = character_backup
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

	var map_script := load("res://code/scenes/dungeon_map.gd")
	var dmap = map_script.new()

	var pip_true: bool = dmap._is_pip_hoarder(dmap.PIP_HOARDER_THRESHOLD)
	var pip_false: bool = dmap._is_pip_hoarder(dmap.PIP_HOARDER_THRESHOLD - 1)
	var pip_ok := pip_true and not pip_false
	ok = pip_ok and ok
	lines.append("  _is_pip_hoarder(임계치/임계치-1): %s/%s (기대 true/false) -> %s" % [
		pip_true, pip_false, "OK" if pip_ok else "FAIL"
	])

	var die_true: bool = dmap._is_die_hoarder(dmap.DIE_HOARDER_THRESHOLD)
	var die_false: bool = dmap._is_die_hoarder(dmap.DIE_HOARDER_THRESHOLD - 1)
	var die_ok := die_true and not die_false
	ok = die_ok and ok
	lines.append("  _is_die_hoarder(임계치/임계치-1): %s/%s (기대 true/false) -> %s" % [
		die_true, die_false, "OK" if die_ok else "FAIL"
	])

	var full_bag := DiceBag.new(4, DiceBag.MAX_DICE)
	var not_full_bag := DiceBag.new(4, 3)
	var maxed_true: bool = dmap._is_bag_maxed(full_bag)
	var maxed_false: bool = dmap._is_bag_maxed(not_full_bag)
	var maxed_ok := maxed_true and not maxed_false
	ok = maxed_ok and ok
	lines.append("  _is_bag_maxed(가득/안 가득): %s/%s (기대 true/false) -> %s" % [
		maxed_true, maxed_false, "OK" if maxed_ok else "FAIL"
	])

	var shop_regular_true: bool = dmap._is_shop_regular(dmap.SHOP_REGULAR_THRESHOLD)
	var shop_regular_false: bool = dmap._is_shop_regular(dmap.SHOP_REGULAR_THRESHOLD - 1)
	var shop_regular_ok := shop_regular_true and not shop_regular_false
	ok = shop_regular_ok and ok
	lines.append("  _is_shop_regular(임계치/임계치-1): %s/%s (기대 true/false) -> %s" % [
		shop_regular_true, shop_regular_false, "OK" if shop_regular_ok else "FAIL"
	])

	var mixed_attack := DiceBag.new(4, 1)
	mixed_attack.add_die(8)
	var mixed_defense := DiceBag.new(10, 1)
	mixed_defense.add_die(20)
	var collector_true: bool = dmap._is_material_collector(mixed_attack, mixed_defense)
	var uniform_bag := DiceBag.new(4, 2)
	var collector_false: bool = dmap._is_material_collector(uniform_bag, uniform_bag)
	var collector_ok := collector_true and not collector_false
	ok = collector_ok and ok
	lines.append("  _is_material_collector(4종 혼합/D4만): %s/%s (기대 true/false) -> %s" % [
		collector_true, collector_false, "OK" if collector_ok else "FAIL"
	])

	dmap.free()

	var hoard_ids := ["pip_hoarder", "die_hoarder", "bag_maxed", "shop_regular", "material_collector"]
	var hoard_ids_ok := true
	for id in hoard_ids:
		hoard_ids_ok = hoard_ids_ok and AchievementManager.DEFINITIONS.has(id) and not AchievementManager.is_unlocked(id)
	ok = hoard_ids_ok and ok
	lines.append("  신규 업적 5종(수집가/가득 찬 주머니/단골 손님/재질 수집가) 정의 존재 + 초기 미해금: %s -> %s" % [
		hoard_ids_ok, "OK" if hoard_ids_ok else "FAIL"
	])

	return ok


## INBOX.md 2026-09-14 "업적에 유형별 아이콘을 추가한다"로 achievement_manager.gd
## DEFINITIONS에 추가한 "icon" 필드가 achievement_icon.gd(AchievementIcon)가 실제로
## 그릴 수 있는 category(CATEGORIES)와 전부 일치하는지 검증한다 — 오타나 리네임으로
## 둘이 어긋나면 화면에서 빈 아이콘(match의 `_: pass`)으로만 조용히 실패하므로,
## _check_item_grades(등급-색 대조)와 같은 패턴으로 문자열 일치를 사전에 잡는다.
func _check_achievement_icons(lines: PackedStringArray) -> bool:
	var ok := true

	for id in AchievementManager.DEFINITIONS.keys():
		var def: Dictionary = AchievementManager.DEFINITIONS[id]
		var icon: String = def.get("icon", "")
		var icon_ok := AchievementIcon.CATEGORIES.has(icon)
		ok = icon_ok and ok
		lines.append("  \"%s\" icon=%s -> %s" % [id, icon, "OK" if icon_ok else "FAIL"])

	var fallback_ok: bool = AchievementManager.get_all_for_display()[0].icon != ""
	ok = fallback_ok and ok
	lines.append("  get_all_for_display() icon 필드 채워짐 -> %s" % ("OK" if fallback_ok else "FAIL"))

	return ok


## INBOX.md 2026-09-14 "캐릭터 스킬에 아이콘을 추가한다"로 추가한 skill_icon.gd
## (SkillIcon)가 character_profiles.gd PROFILES의 모든 gimmick 값을 실제로 그릴 수
## 있는지 검증한다 — _check_achievement_icons와 같은 패턴(오타/리네임으로 둘이
## 어긋나면 화면에서 빈 아이콘으로만 조용히 실패하므로 사전에 문자열 일치를 잡음).
func _check_skill_icons(lines: PackedStringArray) -> bool:
	var ok := true

	for profile in CharacterProfiles.PROFILES:
		var gimmick: String = profile.get("gimmick", "")
		var icon_ok := SkillIcon.CATEGORIES.has(gimmick)
		ok = icon_ok and ok
		lines.append("  \"%s\" gimmick=%s -> %s" % [profile["id"], gimmick, "OK" if icon_ok else "FAIL"])

	return ok


## INBOX.md 2026-09-15 [미니 기획 B]-4 검증. (1) PROFILES 5종 전부 event_die_sides
## 필드가 있고 지금은 전부 6이어야 함(DESIGN.md 확정대로 아직 캐릭터별 차등 없음).
## (2) RunState.reset_run(id)가 이 필드를 event_die_sides로 그대로 복사하는지.
## (3) EventDieVisual._to_roman()이 1~6을 I~VI로, 표 밖 값은 숫자 폴백으로 바꾸는지.
func _check_event_die_sides(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup: String = RunState.character_id

	for profile in CharacterProfiles.PROFILES:
		var sides: int = int(profile.get("event_die_sides", -1))
		var sides_ok := sides == 6
		ok = sides_ok and ok
		lines.append("  \"%s\" event_die_sides=%d(기대 6) -> %s" % [profile["id"], sides, "OK" if sides_ok else "FAIL"])

	RunState.reset_run("berserker")
	var run_state_ok: bool = RunState.event_die_sides == 6
	ok = run_state_ok and ok
	lines.append("  reset_run(berserker) 후 RunState.event_die_sides=%d(기대 6) -> %s" % [
		RunState.event_die_sides, "OK" if run_state_ok else "FAIL"
	])
	RunState.reset_run(character_backup)

	var visual := EventDieVisual.new()
	var roman_ok: bool = (
		visual._to_roman(1) == "I" and visual._to_roman(4) == "IV" and visual._to_roman(6) == "VI"
	)
	ok = roman_ok and ok
	lines.append("  EventDieVisual._to_roman(1/4/6)=%s/%s/%s(기대 I/IV/VI) -> %s" % [
		visual._to_roman(1), visual._to_roman(4), visual._to_roman(6), "OK" if roman_ok else "FAIL"
	])
	var fallback_ok: bool = visual._to_roman(99) == "99"
	ok = fallback_ok and ok
	lines.append("  EventDieVisual._to_roman(99)=%s(기대 표 밖이라 숫자 폴백 \"99\") -> %s" % [
		visual._to_roman(99), "OK" if fallback_ok else "FAIL"
	])

	return ok


## EventItemPool.ITEMS 전부가 "flavor"(상황 설명 문구, 2026-09-16 [미니 기획 B] 1번)를
## 빈 문자열 아니게 갖고 있는지, item_card_style.gd의 build_card()가 그 필드가 있을 때
## 카드에 실제로 Label을 추가하는지(없을 땐 추가 안 함 — DiceItemPool 카드에 영향 없어야
## 함)를 확인한다. _check_item_grades와 같은 패턴.
func _check_event_item_flavor(lines: PackedStringArray) -> bool:
	var ok := true
	for item in EventItemPool.ITEMS:
		var flavor: String = item.get("flavor", "")
		var has_flavor := flavor != ""
		ok = has_flavor and ok
		lines.append("  EventItemPool \"%s\" flavor 존재 -> %s" % [item["name"], "OK" if has_flavor else "FAIL"])

	# gain_pips 아이템(다이스 미리보기 칩이 없는 가장 단순한 카드)으로 검증 — 결과 다이스
	# 미리보기 노드(ShapeDieChip)를 트리 밖에서 만들었다가 곧장 free()하면 리소스 정리
	# 타이밍이 꼬여 "1 resources still in use at exit" 경고가 나는 걸 이번에 직접 겪어서,
	# 미리보기가 없는 아이템으로 바꾸고 add_child()/queue_free()로 정상적인 트리 생명주기를
	# 따르도록 했다.
	var pip_item: Dictionary = {}
	for it in EventItemPool.ITEMS:
		if it["kind"] == "gain_pips":
			pip_item = it
			break

	var with_flavor := ItemCardStyle.build_card(pip_item)
	add_child(with_flavor["card"])
	var with_flavor_vbox: VBoxContainer = with_flavor["vbox"]
	var with_flavor_found := false
	for child in with_flavor_vbox.get_children():
		if child is Label and child.text == pip_item["flavor"]:
			with_flavor_found = true
	ok = with_flavor_found and ok
	lines.append("  flavor 있는 아이템 -> 카드에 flavor Label 추가됨 -> %s" % ("OK" if with_flavor_found else "FAIL"))
	with_flavor["card"].queue_free()

	var no_flavor_item: Dictionary = DiceItemPool.ITEMS[0]
	var without_flavor := ItemCardStyle.build_card(no_flavor_item)
	add_child(without_flavor["card"])
	var without_flavor_vbox: VBoxContainer = without_flavor["vbox"]
	var without_flavor_found := false
	for child in without_flavor_vbox.get_children():
		if child is Label and child.get_theme_color("font_color") == ItemCardStyle.FLAVOR_COLOR:
			without_flavor_found = true
	var no_flavor_ok := not without_flavor_found
	ok = no_flavor_ok and ok
	lines.append("  flavor 없는 아이템(DiceItemPool) -> 카드에 flavor Label 없음 -> %s" % ("OK" if no_flavor_ok else "FAIL"))
	without_flavor["card"].queue_free()

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


## [대형 기획 1] 플레이어블 캐릭터 검증. character_profiles.gd의 CharacterProfiles와,
## run_state.gd RunState.reset_run()이 새 주머니에 캐릭터별 시작 기믹을 실제로
## 적용하는지 확인한다. RunState는 Autoload라 이 테스트가 상태를 바꾸고 나면 반드시
## "novice"(기본값)로 되돌려 다른 테스트/QA에 영향을 주지 않게 한다.
func _check_character_profiles(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup: String = RunState.character_id

	# get_profile(): 정의된 id는 해당 기믹을, 빈 문자열/미정의 id는 PROFILES[0](기믹 없음)로
	# 폴백해야 한다 — 캐릭터 선택 없이 reset_run()을 그냥 부르는 기존 호출부들이 항상
	# 유효한 프로필을 얻기 위한 안전장치.
	var berserker_ok: bool = CharacterProfiles.get_profile("berserker")["gimmick"] == "min_max_only"
	ok = berserker_ok and ok
	lines.append("  get_profile(berserker).gimmick=%s (기대 min_max_only) -> %s" % [
		CharacterProfiles.get_profile("berserker")["gimmick"], "OK" if berserker_ok else "FAIL"
	])
	var guardian_ok: bool = CharacterProfiles.get_profile("guardian")["gimmick"] == "fixed_defense_die"
	ok = guardian_ok and ok
	lines.append("  get_profile(guardian).gimmick=%s (기대 fixed_defense_die) -> %s" % [
		CharacterProfiles.get_profile("guardian")["gimmick"], "OK" if guardian_ok else "FAIL"
	])
	var explosive_ok: bool = CharacterProfiles.get_profile("explosive")["gimmick"] == "explosive_stack"
	ok = explosive_ok and ok
	lines.append("  get_profile(explosive).gimmick=%s (기대 explosive_stack) -> %s" % [
		CharacterProfiles.get_profile("explosive")["gimmick"], "OK" if explosive_ok else "FAIL"
	])
	var shieldbearer_ok: bool = CharacterProfiles.get_profile("shieldbearer")["gimmick"] == "guard_stack"
	ok = shieldbearer_ok and ok
	lines.append("  get_profile(shieldbearer).gimmick=%s (기대 guard_stack) -> %s" % [
		CharacterProfiles.get_profile("shieldbearer")["gimmick"], "OK" if shieldbearer_ok else "FAIL"
	])
	var fallback_empty_ok: bool = CharacterProfiles.get_profile("")["id"] == CharacterProfiles.PROFILES[0]["id"]
	var fallback_unknown_ok: bool = CharacterProfiles.get_profile("no_such_id")["id"] == CharacterProfiles.PROFILES[0]["id"]
	ok = fallback_empty_ok and fallback_unknown_ok and ok
	lines.append("  get_profile('')/get_profile(no_such_id) 폴백=PROFILES[0] -> %s" % [
		"OK" if (fallback_empty_ok and fallback_unknown_ok) else "FAIL"
	])

	# RunState.reset_run("berserker"): 공격/방어 다이스 둘 다 force_min_max_faces() 효과로
	# 모든 면이 min(1) 또는 max(4)만이어야 한다(중간값 2/3 없음).
	RunState.reset_run("berserker")
	var id_ok: bool = RunState.character_id == "berserker"
	var faces_no_middle_ok := true
	for faces in RunState.player_attack_bag.dice:
		for v in faces:
			if v != 1 and v != 4:
				faces_no_middle_ok = false
	for faces in RunState.player_defense_bag.dice:
		for v in faces:
			if v != 1 and v != 4:
				faces_no_middle_ok = false
	ok = id_ok and faces_no_middle_ok and ok
	lines.append("  reset_run(berserker): character_id=%s 공격/방어 면 전부 1/4만=%s -> %s" % [
		RunState.character_id, faces_no_middle_ok, "OK" if (id_ok and faces_no_middle_ok) else "FAIL"
	])

	# INBOX.md 2026-09-14 "캐릭터별 시작 주사위를 다르게 한다" — 각 캐릭터의 시작
	# 공격/방어 다이스 개수가 character_profiles.gd의 attack_count/defense_count와
	# 일치해야 한다(광전사=공격4/방어2, novice/기본값=3/3과 달라야 차별화가 된 것).
	var berserker_count_ok: bool = (
		RunState.player_attack_bag.count == 4 and RunState.player_defense_bag.count == 2
	)
	ok = berserker_count_ok and ok
	lines.append("  reset_run(berserker) 시작 다이스 개수: 공격=%d(기대 4) 방어=%d(기대 2) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if berserker_count_ok else "FAIL"
	])

	# RunState.reset_run("guardian"): 방어 다이스 0번째만 고정값(3)이고, 나머지(1,2번째)는
	# 표준 D4([1,2,3,4])로 그대로 남아 있어야 한다("다이스 하나만" 고정 — 전체가 아님).
	RunState.reset_run("guardian")
	var guardian_id_ok: bool = RunState.character_id == "guardian"
	var expected_value := CharacterProfiles.fixed_defense_die_value(4)
	var die0_fixed_ok := true
	for v in RunState.player_defense_bag.dice[0]:
		if v != expected_value:
			die0_fixed_ok = false
	var other_dice_standard_ok: bool = (
		RunState.player_defense_bag.dice[1] == PackedInt32Array([1, 2, 3, 4])
		and RunState.player_defense_bag.dice[2] == PackedInt32Array([1, 2, 3, 4])
	)
	var attack_bag_unaffected_ok: bool = RunState.player_attack_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
	ok = guardian_id_ok and die0_fixed_ok and other_dice_standard_ok and attack_bag_unaffected_ok and ok
	lines.append("  reset_run(guardian): 방어다이스0=%s(기대 전부 %d) 방어다이스1/2=표준유지 공격다이스=영향없음 -> %s" % [
		RunState.player_defense_bag.dice[0], expected_value,
		"OK" if (guardian_id_ok and die0_fixed_ok and other_dice_standard_ok and attack_bag_unaffected_ok) else "FAIL"
	])
	var guardian_count_ok: bool = (
		RunState.player_attack_bag.count == 2 and RunState.player_defense_bag.count == 4
	)
	ok = guardian_count_ok and ok
	lines.append("  reset_run(guardian) 시작 다이스 개수: 공격=%d(기대 2) 방어=%d(기대 4) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if guardian_count_ok else "FAIL"
	])

	# reset_run()을 인자 없이 부르면(패배 후 재시작 등 기존 호출부와 동일한 사용법)
	# 직전에 고른 캐릭터(guardian)를 유지한 채 새 주머니에 기믹을 다시 적용해야 한다.
	RunState.reset_run()
	var keep_character_ok: bool = RunState.character_id == "guardian"
	var reapplied_ok := true
	for v in RunState.player_defense_bag.dice[0]:
		if v != expected_value:
			reapplied_ok = false
	ok = keep_character_ok and reapplied_ok and ok
	lines.append("  reset_run() 인자 없음: character_id 유지=%s 새 주머니에도 기믹 재적용=%s -> %s" % [
		keep_character_ok, reapplied_ok, "OK" if (keep_character_ok and reapplied_ok) else "FAIL"
	])

	# "폭발병"(explosive_stack)은 정적 다이스 개조가 없는 기믹(character_profiles.gd 클래스
	# 주석 참고) — reset_run()이 만든 새 주머니는 다른 기믹 없는 캐릭터와 마찬가지로 표준
	# D4x3 그대로여야 한다. 실제 스택 추적/D20 전환은 combat_test.gd의 인스턴스 상태라
	# @onready 씬 노드가 필요해 여기서는(anger_stack과 같은 이유로) 검증하지 않고
	# _debug_show_explosive_dice()로 화면에서 육안 확인한다(아래 QA 참고).
	RunState.reset_run("explosive")
	var explosive_id_ok: bool = RunState.character_id == "explosive"
	var explosive_bags_standard_ok: bool = (
		RunState.player_attack_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
		and RunState.player_defense_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
	)
	ok = explosive_id_ok and explosive_bags_standard_ok and ok
	lines.append("  reset_run(explosive): character_id=%s 공격/방어 주머니 표준 유지(정적 개조 없음)=%s -> %s" % [
		RunState.character_id, explosive_bags_standard_ok, "OK" if (explosive_id_ok and explosive_bags_standard_ok) else "FAIL"
	])
	var explosive_count_ok: bool = (
		RunState.player_attack_bag.count == 4 and RunState.player_defense_bag.count == 3
	)
	ok = explosive_count_ok and ok
	lines.append("  reset_run(explosive) 시작 다이스 개수: 공격=%d(기대 4) 방어=%d(기대 3) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if explosive_count_ok else "FAIL"
	])

	# "방패병"(guard_stack)도 explosive_stack과 마찬가지로 정적 다이스 개조가 없는
	# 기믹 — reset_run()이 만든 새 주머니는 표준 D4x3 그대로여야 한다(같은 이유로 실제
	# 스택 추적/D20 전환은 여기서 검증하지 않고 _debug_show_guard_dice()로 육안 확인).
	RunState.reset_run("shieldbearer")
	var shieldbearer_id_ok: bool = RunState.character_id == "shieldbearer"
	var shieldbearer_bags_standard_ok: bool = (
		RunState.player_attack_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
		and RunState.player_defense_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
	)
	ok = shieldbearer_id_ok and shieldbearer_bags_standard_ok and ok
	lines.append("  reset_run(shieldbearer): character_id=%s 공격/방어 주머니 표준 유지(정적 개조 없음)=%s -> %s" % [
		RunState.character_id, shieldbearer_bags_standard_ok, "OK" if (shieldbearer_id_ok and shieldbearer_bags_standard_ok) else "FAIL"
	])
	var shieldbearer_count_ok: bool = (
		RunState.player_attack_bag.count == 3 and RunState.player_defense_bag.count == 4
	)
	ok = shieldbearer_count_ok and ok
	lines.append("  reset_run(shieldbearer) 시작 다이스 개수: 공격=%d(기대 3) 방어=%d(기대 4) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if shieldbearer_count_ok else "FAIL"
	])

	# novice(빈 문자열/미정의 id 포함)는 기존과 같이 표준 3/3을 유지해야 한다(회귀 방지 —
	# attack_count/defense_count 필드가 없는 프로필에도 reset_run()의 profile.get() 폴백이
	# 여전히 3/3을 주는지 확인).
	RunState.reset_run("novice")
	var novice_count_ok: bool = (
		RunState.player_attack_bag.count == 3 and RunState.player_defense_bag.count == 3
	)
	ok = novice_count_ok and ok
	lines.append("  reset_run(novice) 시작 다이스 개수: 공격=%d(기대 3) 방어=%d(기대 3) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if novice_count_ok else "FAIL"
	])

	RunState.reset_run(character_backup)
	return ok


## [대형 기획 2] (a) 조각 검증. round_index/TOTAL_ROUNDS/advance_round()/is_last_round()가
## 아직 어느 화면에서도 쓰이지 않는(다음 조각 (b)가 배선할) 순수 데이터 계층이라, 여기서
## RunState를 직접 조작해 로직만 확인한다. RunState는 Autoload라 끝나면 reset_run()으로
## 원상복구한다.
func _check_round_progress(lines: PackedStringArray) -> bool:
	var ok := true

	# reset_run()은 항상 round_index를 1로 되돌려야 한다(새 런은 항상 라운드 1부터).
	RunState.round_index = 2
	RunState.reset_run()
	var reset_ok: bool = RunState.round_index == 1
	ok = reset_ok and ok
	lines.append("  reset_run(): round_index=%d(기대 1) -> %s" % [RunState.round_index, "OK" if reset_ok else "FAIL"])

	# advance_round()는 round_index를 올리고 rooms_cleared만 0으로 되돌리며, 골드/다이스
	# 주머니(빌드)는 그대로 유지해야 한다(라운드가 바뀌어도 빌드가 이어진다는 설계).
	RunState.rooms_cleared = RunState.TOTAL_ROOMS
	RunState.gold = 77
	var attack_bag_before := RunState.player_attack_bag
	RunState.advance_round()
	var advance_ok: bool = (
		RunState.round_index == 2
		and RunState.rooms_cleared == 0
		and RunState.gold == 77
		and RunState.player_attack_bag == attack_bag_before
	)
	ok = advance_ok and ok
	lines.append("  advance_round(): round_index=%d(기대 2) rooms_cleared=%d(기대 0) gold=%d(기대 77 유지) 주머니 유지=%s -> %s" % [
		RunState.round_index, RunState.rooms_cleared, RunState.gold,
		RunState.player_attack_bag == attack_bag_before, "OK" if advance_ok else "FAIL"
	])

	# is_last_round()는 round_index가 TOTAL_ROUNDS(3)에 도달했을 때만 true.
	var not_last_ok: bool = not RunState.is_last_round()
	RunState.round_index = RunState.TOTAL_ROUNDS
	var is_last_ok: bool = RunState.is_last_round()
	ok = not_last_ok and is_last_ok and ok
	lines.append("  is_last_round(): round_index=2일 때=%s(기대 false) round_index=%d일 때=%s(기대 true) -> %s" % [
		not not_last_ok, RunState.TOTAL_ROUNDS, is_last_ok, "OK" if (not_last_ok and is_last_ok) else "FAIL"
	])

	# 마지막 라운드에서 advance_round()를 불러도 아무 일도 하지 않아야 한다(더 진행할
	# 라운드가 없으므로 — 최종 클리어는 (c) 조각이 다룰 별도 분기).
	RunState.advance_round()
	var no_op_ok: bool = RunState.round_index == RunState.TOTAL_ROUNDS
	ok = no_op_ok and ok
	lines.append("  advance_round() 마지막 라운드에서 호출: round_index=%d(기대 %d, 변화 없음) -> %s" % [
		RunState.round_index, RunState.TOTAL_ROUNDS, "OK" if no_op_ok else "FAIL"
	])

	RunState.reset_run()
	return ok


## KeyboardShortcuts(신규, INBOX.md 2026-09-14 "키보드 단축키" 요청 첫 조각)의 세 가지
## 순수 동작을 검증한다: (1) 버튼 텍스트에 "[n] " 접두어를 순서대로 붙이는지, (2) 같은
## 버튼 목록에 다시 적용해도 접두어가 누적되지 않는지(화면이 재구성될 때마다 매번 다시
## 부르는 dungeon_map.gd/story_event.gd 사용 패턴을 그대로 검증), (3) 숫자 키 입력을
## 인덱스로 바르게 변환하고, 안 보이거나 비활성화된 버튼은 누르지 않는지.
func _check_keyboard_shortcuts(lines: PackedStringArray) -> bool:
	var ok := true

	var b1 := Button.new()
	b1.text = "전투 방 입장 (1번째 방)"
	var b2 := Button.new()
	b2.text = "상점 입장 (1번째 방)"
	var buttons: Array[Button] = [b1, b2]

	KeyboardShortcuts.apply_hints(buttons)
	var hint_ok: bool = b1.text == "[1] 전투 방 입장 (1번째 방)" and b2.text == "[2] 상점 입장 (1번째 방)"
	ok = hint_ok and ok
	lines.append("  apply_hints(): b1='%s' b2='%s' -> %s" % [b1.text, b2.text, "OK" if hint_ok else "FAIL"])

	# 방 번호가 바뀌어 텍스트가 다시 설정된 뒤 같은 버튼 목록에 apply_hints를 또 부르는
	# 상황(dungeon_map.gd의 _update_labels()가 매번 하는 것과 동일) — 접두어가
	# "[1] [1] ..." 식으로 쌓이면 안 된다.
	b1.text = "전투 방 입장 (2번째 방)"
	KeyboardShortcuts.apply_hints(buttons)
	var no_stack_ok: bool = b1.text == "[1] 전투 방 입장 (2번째 방)"
	ok = no_stack_ok and ok
	lines.append("  apply_hints() 재적용 시 누적 방지: b1='%s' -> %s" % [b1.text, "OK" if no_stack_ok else "FAIL"])

	var key1 := InputEventKey.new()
	key1.pressed = true
	key1.keycode = KEY_1
	var idx1 := KeyboardShortcuts.digit_index(key1)
	var digit_ok: bool = idx1 == 0
	lines.append("  digit_index(KEY_1 눌림): idx=%d(기대 0) -> %s" % [idx1, "OK" if digit_ok else "FAIL"])

	var key1_release := InputEventKey.new()
	key1_release.pressed = false
	key1_release.keycode = KEY_1
	var idx_release := KeyboardShortcuts.digit_index(key1_release)
	var release_ok: bool = idx_release == -1
	lines.append("  digit_index(KEY_1 뗌): idx=%d(기대 -1, 눌림만 인정) -> %s" % [idx_release, "OK" if release_ok else "FAIL"])

	var key_a := InputEventKey.new()
	key_a.pressed = true
	key_a.keycode = KEY_A
	var idx_a := KeyboardShortcuts.digit_index(key_a)
	var non_digit_ok: bool = idx_a == -1
	lines.append("  digit_index(KEY_A 눌림): idx=%d(기대 -1) -> %s" % [idx_a, "OK" if non_digit_ok else "FAIL"])

	# try_press: 보이고 활성화된 버튼만 눌려야 한다.
	var pressed_count := {"b1": 0, "b2": 0}
	b1.pressed.connect(func(): pressed_count["b1"] += 1)
	b2.pressed.connect(func(): pressed_count["b2"] += 1)
	b2.disabled = true
	var press_b1_ok: bool = KeyboardShortcuts.try_press(buttons, 0) and pressed_count["b1"] == 1
	var press_b2_blocked_ok: bool = not KeyboardShortcuts.try_press(buttons, 1) and pressed_count["b2"] == 0
	ok = digit_ok and release_ok and non_digit_ok and press_b1_ok and press_b2_blocked_ok and ok
	lines.append("  try_press(): 활성 버튼 누름=%s(기대 true, 1회 호출) 비활성 버튼 무시=%s(기대 true, 0회 호출) -> %s" % [
		press_b1_ok, press_b2_blocked_ok, "OK" if (press_b1_ok and press_b2_blocked_ok) else "FAIL"
	])

	var out_of_range_ok: bool = not KeyboardShortcuts.try_press(buttons, 5)
	ok = out_of_range_ok and ok
	lines.append("  try_press() 범위 밖 인덱스: %s(기대 false) -> %s" % [not out_of_range_ok, "OK" if out_of_range_ok else "FAIL"])

	b1.queue_free()
	b2.queue_free()
	return ok


## [미니 기획 C]-1/2(INBOX.md, 2026-09-16) 검증. (1) SkillPool.SKILLS에 최소 2종이
## 정의돼 있는지, (2) available_choices()가 이미 RunState.skill_flags에 있는 id를
## 후보에서 제외하는지, (3) grant()가 중복 없이 추가하는지, (4) 실제 event.tscn을
## 인스턴스화해 _setup_skill_event()/_apply_skill_pick()이 카드 표시·방 진행·이중
## 실행 가드까지 정상 동작하는지(_apply_pick/_apply_pips/_apply_upgrade와 같은
## 패턴의 이중 실행 가드 검증).
func _check_skill_event_structure(lines: PackedStringArray) -> bool:
	var ok := true
	var flags_backup: Array[String] = RunState.skill_flags.duplicate()
	var rooms_backup := RunState.rooms_cleared

	var skills_defined_ok: bool = SkillPool.SKILLS.size() >= 2
	ok = skills_defined_ok and ok
	lines.append("  SkillPool.SKILLS 개수=%d(기대 2 이상) -> %s" % [
		SkillPool.SKILLS.size(), "OK" if skills_defined_ok else "FAIL"
	])

	RunState.skill_flags = []
	var full_choices := SkillPool.available_choices(SkillPool.SKILLS.size())
	var full_choices_ok: bool = full_choices.size() == SkillPool.SKILLS.size()
	ok = full_choices_ok and ok
	lines.append("  스킬 미보유 상태 available_choices(전체)=%d(기대 %d) -> %s" % [
		full_choices.size(), SkillPool.SKILLS.size(), "OK" if full_choices_ok else "FAIL"
	])

	var first_id: String = SkillPool.SKILLS[0]["id"]
	SkillPool.grant(first_id)
	var grant_ok: bool = RunState.skill_flags.has(first_id) and RunState.skill_flags.count(first_id) == 1
	ok = grant_ok and ok
	lines.append("  grant('%s') 후 skill_flags=%s -> %s" % [first_id, RunState.skill_flags, "OK" if grant_ok else "FAIL"])

	SkillPool.grant(first_id)
	var grant_dedup_ok: bool = RunState.skill_flags.count(first_id) == 1
	ok = grant_dedup_ok and ok
	lines.append("  grant('%s') 재호출(중복) 후 개수=%d(기대 1) -> %s" % [
		first_id, RunState.skill_flags.count(first_id), "OK" if grant_dedup_ok else "FAIL"
	])

	var remaining_choices := SkillPool.available_choices(SkillPool.SKILLS.size())
	var still_offers_owned := false
	for s in remaining_choices:
		if s["id"] == first_id:
			still_offers_owned = true
	var exclude_owned_ok: bool = not still_offers_owned
	ok = exclude_owned_ok and ok
	lines.append("  이미 보유한 스킬은 후보에서 제외 -> %s" % ("OK" if exclude_owned_ok else "FAIL"))

	# 실제 event.tscn을 인스턴스화해 스킬 이벤트 화면 구성 + 픽업 가드까지 확인한다
	# (event.gd _apply_pick/_apply_pips/_apply_upgrade와 같은 검증 패턴).
	RunState.skill_flags = []
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	var candidate: Dictionary = SkillPool.SKILLS[0]
	var offer: Array[Dictionary] = [candidate]
	event_node._setup_skill_event(offer)
	var offer_ok: bool = event_node._row_ui.size() == 1
	ok = offer_ok and ok
	lines.append("  _setup_skill_event() 카드 1장 표시: row_ui=%d(기대 1) -> %s" % [
		event_node._row_ui.size(), "OK" if offer_ok else "FAIL"
	])

	var rooms_before: int = RunState.rooms_cleared
	var first_applied: bool = event_node._apply_skill_pick(candidate)
	var pick_ok: bool = (
		first_applied
		and RunState.skill_flags.has(candidate["id"])
		and RunState.rooms_cleared == rooms_before + 1
	)
	ok = pick_ok and ok
	lines.append("  _apply_skill_pick() 1차: applied=%s skill_flags=%s rooms=%d(기대 %d) -> %s" % [
		first_applied, RunState.skill_flags, RunState.rooms_cleared, rooms_before + 1, "OK" if pick_ok else "FAIL"
	])

	var second_applied: bool = event_node._apply_skill_pick(candidate)
	var guard_ok: bool = not second_applied and RunState.rooms_cleared == rooms_before + 1
	ok = guard_ok and ok
	lines.append("  _apply_skill_pick() 2차(이미 픽함): applied=%s rooms=%d(변화 없음 기대) -> %s" % [
		second_applied, RunState.rooms_cleared, "OK" if guard_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()
	RunState.skill_flags = flags_backup
	RunState.rooms_cleared = rooms_backup
	return ok


## [미니 기획 C]-3/4(INBOX.md, 2026-09-16) 실제 전투 효과 배선 검증. combat_test.gd의
## _do_exchange()는 물리 다이스/뷰포트에 의존해 직접 호출하기 어려우므로(다른
## _check_combat_* 테스트들처럼 물리 의존 없는 순수 헬퍼만 골라 검증), 여기서는
## (1) DiceBag.apply_flat_bonus()(심호흡의 계산식), (2) SkillPool.UNIQUE_SKILLS
## 캐릭터 필터(광기 심화가 광전사에게만 제시되는지), (3) combat_test.gd._apply_spare_die()
## (여분의 "가장 낮은 값을 여분 다이스로 대체" 로직)를 각각 검증한다.
func _check_skill_effects(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 심호흡: apply_flat_bonus는 값 +1을 하되 그 다이스 면 개수(sides)를 상한으로 한다.
	var breath_bag := DiceBag.new(4, 3)
	var breath_before: Array = [1, 3, 4]
	var breath_after: Array = breath_bag.apply_flat_bonus(breath_before, 1)
	var breath_ok: bool = breath_after == [2, 4, 4]
	ok = breath_ok and ok
	lines.append("  DiceBag.apply_flat_bonus([1,3,4], +1) on D4x3 = %s (기대 [2,4,4], 4는 상한 유지) -> %s" % [
		breath_after, "OK" if breath_ok else "FAIL"
	])

	# (2) 광기 심화(frenzy_deepen)는 광전사(berserker) 전용 후보로만 제시되고, 다른
	# 캐릭터나 character_id 미지정 호출에는 섞이지 않는다.
	var flags_backup: Array[String] = RunState.skill_flags.duplicate()
	RunState.skill_flags = []
	var berserker_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "berserker")
	var berserker_has_frenzy := false
	for s in berserker_choices:
		if s["id"] == "frenzy_deepen":
			berserker_has_frenzy = true
	var novice_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "novice")
	var novice_has_frenzy := false
	for s in novice_choices:
		if s["id"] == "frenzy_deepen":
			novice_has_frenzy = true
	var no_char_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size())
	var no_char_has_frenzy := false
	for s in no_char_choices:
		if s["id"] == "frenzy_deepen":
			no_char_has_frenzy = true
	var frenzy_filter_ok: bool = berserker_has_frenzy and not novice_has_frenzy and not no_char_has_frenzy
	ok = frenzy_filter_ok and ok
	lines.append("  '광기 심화' 캐릭터 필터: berserker=%s novice=%s 미지정=%s (기대 true/false/false) -> %s" % [
		berserker_has_frenzy, novice_has_frenzy, no_char_has_frenzy, "OK" if frenzy_filter_ok else "FAIL"
	])

	# (2b) 수호 심화(guard_deepen)는 frenzy_deepen과 대칭으로 수호자(guardian) 전용
	# 후보로만 제시된다.
	var guardian_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "guardian")
	var guardian_has_guard_deepen := false
	for s in guardian_choices:
		if s["id"] == "guard_deepen":
			guardian_has_guard_deepen = true
	var berserker_has_guard_deepen := false
	for s in berserker_choices:
		if s["id"] == "guard_deepen":
			berserker_has_guard_deepen = true
	var guard_deepen_filter_ok: bool = guardian_has_guard_deepen and not berserker_has_guard_deepen
	ok = guard_deepen_filter_ok and ok
	lines.append("  '수호 심화' 캐릭터 필터: guardian=%s berserker=%s (기대 true/false) -> %s" % [
		guardian_has_guard_deepen, berserker_has_guard_deepen, "OK" if guard_deepen_filter_ok else "FAIL"
	])

	# (2c) 연쇄 폭발(chain_explosion)은 폭발병(explosive) 전용 후보로만 제시된다.
	var explosive_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "explosive")
	var explosive_has_chain := false
	for s in explosive_choices:
		if s["id"] == "chain_explosion":
			explosive_has_chain = true
	var berserker_has_chain := false
	for s in berserker_choices:
		if s["id"] == "chain_explosion":
			berserker_has_chain = true
	var chain_explosion_filter_ok: bool = explosive_has_chain and not berserker_has_chain
	ok = chain_explosion_filter_ok and ok
	lines.append("  '연쇄 폭발' 캐릭터 필터: explosive=%s berserker=%s (기대 true/false) -> %s" % [
		explosive_has_chain, berserker_has_chain, "OK" if chain_explosion_filter_ok else "FAIL"
	])
	# (2d) 연쇄 방어(chain_guard)는 chain_explosion과 대칭으로 방패병(shieldbearer)
	# 전용 후보로만 제시된다.
	var shieldbearer_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "shieldbearer")
	var shieldbearer_has_chain_guard := false
	for s in shieldbearer_choices:
		if s["id"] == "chain_guard":
			shieldbearer_has_chain_guard = true
	var explosive_has_chain_guard := false
	for s in explosive_choices:
		if s["id"] == "chain_guard":
			explosive_has_chain_guard = true
	var chain_guard_filter_ok: bool = shieldbearer_has_chain_guard and not explosive_has_chain_guard
	ok = chain_guard_filter_ok and ok
	lines.append("  '연쇄 방어' 캐릭터 필터: shieldbearer=%s explosive=%s (기대 true/false) -> %s" % [
		shieldbearer_has_chain_guard, explosive_has_chain_guard, "OK" if chain_guard_filter_ok else "FAIL"
	])
	# (2e) 임기응변(versatile_surge)은 chain_guard와 마찬가지로 견습 모험가(novice)
	# 전용 후보로만 제시된다(novice_choices는 위 (2)에서 이미 뽑아둔 것을 재사용).
	var novice_has_versatile := false
	for s in novice_choices:
		if s["id"] == "versatile_surge":
			novice_has_versatile = true
	var berserker_has_versatile := false
	for s in berserker_choices:
		if s["id"] == "versatile_surge":
			berserker_has_versatile = true
	var versatile_filter_ok: bool = novice_has_versatile and not berserker_has_versatile
	ok = versatile_filter_ok and ok
	lines.append("  '임기응변' 캐릭터 필터: novice=%s berserker=%s (기대 true/false) -> %s" % [
		novice_has_versatile, berserker_has_versatile, "OK" if versatile_filter_ok else "FAIL"
	])
	RunState.skill_flags = flags_backup

	# (3) 여분: _apply_spare_die()는 항상 가장 낮은 값이 있던 자리만 바꾸고(다른 자리는
	# 그대로), 결과값이 원래 값보다 낮아지는 일은 없다. 여분 다이스가 D4라 여러 번
	# 시도하면 최소 한 번은 원래 최저값(1)보다 높은 값으로 대체돼야 한다(확률적 검증,
	# _check_range()가 쓰는 "여러 번 굴려 범위 확인" 패턴과 동일).
	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()
	var spare_bag := DiceBag.new(4, 3)
	var untouched_ok := true
	var never_decreased_ok := true
	var replaced_at_least_once := false
	for i in 60:
		var values: Array = [1, 4, 2]
		var adjusted: Array = combat._apply_spare_die(spare_bag, values)
		if adjusted[1] != 4 or adjusted[2] != 2:
			untouched_ok = false
		if adjusted[0] < 1 or adjusted[0] > 4:
			never_decreased_ok = false
		if adjusted[0] > 1:
			replaced_at_least_once = true
	var spare_ok: bool = untouched_ok and never_decreased_ok and replaced_at_least_once
	ok = spare_ok and ok
	lines.append("  _apply_spare_die(): 최저값 자리만 변경=%s 범위[1,4] 유지=%s 최소 1회 대체 관측=%s -> %s" % [
		untouched_ok, never_decreased_ok, replaced_at_least_once, "OK" if spare_ok else "FAIL"
	])

	# (3b) "여분+"([미니 기획 D]-4): count=2로 호출해도 같은 규칙(최저값 자리만 변경,
	# 범위 유지)을 지키고, 다이스 2개 중 최댓값을 쓰므로 count=1보다 대체될 확률이 더
	# 높아야 한다(엄밀한 분포 검증은 아니고, 60회 표본에서 대체 횟수가 count=1보다
	# 작지 않은지만 확인 — 물리 의존 없는 순수 확률 비교).
	var plus_untouched_ok := true
	var plus_never_out_of_range_ok := true
	var plus_replace_count := 0
	var base_replace_count := 0
	for i in 60:
		var values: Array = [1, 4, 2]
		var plus_adjusted: Array = combat._apply_spare_die(spare_bag, values, 2)
		if plus_adjusted[1] != 4 or plus_adjusted[2] != 2:
			plus_untouched_ok = false
		if plus_adjusted[0] < 1 or plus_adjusted[0] > 4:
			plus_never_out_of_range_ok = false
		if plus_adjusted[0] > 1:
			plus_replace_count += 1
		var base_adjusted: Array = combat._apply_spare_die(spare_bag, values, 1)
		if base_adjusted[0] > 1:
			base_replace_count += 1
	var spare_plus_ok: bool = plus_untouched_ok and plus_never_out_of_range_ok and plus_replace_count >= base_replace_count
	ok = spare_plus_ok and ok
	lines.append("  _apply_spare_die(count=2, '여분+'): 최저값 자리만 변경=%s 범위[1,4] 유지=%s 대체 횟수(2개 굴림=%d >= 1개 굴림=%d)=%s -> %s" % [
		plus_untouched_ok, plus_never_out_of_range_ok, plus_replace_count, base_replace_count, plus_replace_count >= base_replace_count, "OK" if spare_plus_ok else "FAIL"
	])

	# (3c) "광기 심화"/"수호 심화"(및 "+" 강화판) 공용 헬퍼 _apply_bonus_reroll(): 결과값은
	# 절대 원래 값보다 낮아지지 않고(최댓값만 채택), values[0] 외 다른 자리는 건드리지
	# 않는다. extra_rolls=2("+"강화판, 총 3번 굴림)는 extra_rolls=1(base, 총 2번 굴림)보다
	# 대체(더 높은 값 채택) 확률이 낮지 않아야 한다(_apply_spare_die (3b)와 같은 확률
	# 비교 패턴, 물리 의존 없는 순수 함수라 단위 테스트 가능).
	var reroll_bag := DiceBag.new(20, 1)
	var reroll_untouched_ok := true
	var reroll_never_decreased_ok := true
	var base_reroll_replace_count := 0
	var plus_reroll_replace_count := 0
	for i in 80:
		var values: Array = [5, 99]
		var base_result: Array = combat._apply_bonus_reroll(reroll_bag, values, 1)
		if base_result[1] != 99:
			reroll_untouched_ok = false
		if base_result[0] < 5:
			reroll_never_decreased_ok = false
		if base_result[0] > 5:
			base_reroll_replace_count += 1
		var plus_result: Array = combat._apply_bonus_reroll(reroll_bag, values, 2)
		if plus_result[1] != 99:
			reroll_untouched_ok = false
		if plus_result[0] < 5:
			reroll_never_decreased_ok = false
		if plus_result[0] > 5:
			plus_reroll_replace_count += 1
	var bonus_reroll_ok: bool = reroll_untouched_ok and reroll_never_decreased_ok and plus_reroll_replace_count >= base_reroll_replace_count
	ok = bonus_reroll_ok and ok
	lines.append("  _apply_bonus_reroll(): values[1] 불변=%s 절대 감소 없음=%s 대체 횟수(3번 굴림=%d >= 2번 굴림=%d)=%s -> %s" % [
		reroll_untouched_ok, reroll_never_decreased_ok, plus_reroll_replace_count, base_reroll_replace_count, plus_reroll_replace_count >= base_reroll_replace_count, "OK" if bonus_reroll_ok else "FAIL"
	])

	# (4) 연쇄 폭발(chain_explosion)의 실제 효과: _player_explosive_threshold()가
	# 미보유 시 EXPLOSIVE_STACK_THRESHOLD(3), 보유 시 2를 반환하는지.
	var threshold_default: int = combat._player_explosive_threshold()
	combat.player_chain_explosion_active = true
	var threshold_with_skill: int = combat._player_explosive_threshold()
	var chain_threshold_ok: bool = threshold_default == combat.EXPLOSIVE_STACK_THRESHOLD and threshold_with_skill == 2
	ok = chain_threshold_ok and ok
	lines.append("  _player_explosive_threshold(): 미보유=%d(기대 %d) 보유=%d(기대 2) -> %s" % [
		threshold_default, combat.EXPLOSIVE_STACK_THRESHOLD, threshold_with_skill, "OK" if chain_threshold_ok else "FAIL"
	])

	# (5) 연쇄 방어(chain_guard)의 실제 효과: _player_guard_threshold()가 미보유 시
	# GUARD_STACK_THRESHOLD(3), 보유 시 2를 반환하는지. (4)와 완전히 대칭 검증.
	var guard_threshold_default: int = combat._player_guard_threshold()
	combat.player_chain_guard_active = true
	var guard_threshold_with_skill: int = combat._player_guard_threshold()
	var chain_guard_threshold_ok: bool = guard_threshold_default == combat.GUARD_STACK_THRESHOLD and guard_threshold_with_skill == 2
	ok = chain_guard_threshold_ok and ok
	lines.append("  _player_guard_threshold(): 미보유=%d(기대 %d) 보유=%d(기대 2) -> %s" % [
		guard_threshold_default, combat.GUARD_STACK_THRESHOLD, guard_threshold_with_skill, "OK" if chain_guard_threshold_ok else "FAIL"
	])

	# (6) 임기응변(versatile_surge)은 chain_explosion/chain_guard와 달리 임계치를 낮추지
	# 않는다("넓지만 얕게", INBOX.md 2026-09-17 기획자 결정) — player_chain_explosion_active/
	# player_chain_guard_active를 다시 false로 되돌린 뒤 player_versatile_active만 켜도
	# 두 임계치 함수 모두 기본값(3) 그대로여야 한다.
	combat.player_chain_explosion_active = false
	combat.player_chain_guard_active = false
	combat.player_versatile_active = true
	var versatile_explosive_threshold: int = combat._player_explosive_threshold()
	var versatile_guard_threshold: int = combat._player_guard_threshold()
	var versatile_threshold_ok: bool = versatile_explosive_threshold == combat.EXPLOSIVE_STACK_THRESHOLD and versatile_guard_threshold == combat.GUARD_STACK_THRESHOLD
	ok = versatile_threshold_ok and ok
	lines.append("  임기응변 보유 시 임계치 불변: 공격=%d 방어=%d (기대 둘 다 %d) -> %s" % [
		versatile_explosive_threshold, versatile_guard_threshold, combat.EXPLOSIVE_STACK_THRESHOLD, "OK" if versatile_threshold_ok else "FAIL"
	])

	# (7) "임기응변+"([미니 기획 D]-4, 견습 모험가 전용 강화판): base(versatile_surge)와
	# 달리 chain_explosion/chain_guard와 같은 방식으로 두 임계치를 모두 2로 낮춘다.
	combat.player_versatile_active = true
	combat.player_versatile_plus_active = true
	var versatile_plus_explosive_threshold: int = combat._player_explosive_threshold()
	var versatile_plus_guard_threshold: int = combat._player_guard_threshold()
	var versatile_plus_threshold_ok: bool = versatile_plus_explosive_threshold == 2 and versatile_plus_guard_threshold == 2
	ok = versatile_plus_threshold_ok and ok
	lines.append("  임기응변+ 보유 시 임계치: 공격=%d 방어=%d (기대 둘 다 2) -> %s" % [
		versatile_plus_explosive_threshold, versatile_plus_guard_threshold, "OK" if versatile_plus_threshold_ok else "FAIL"
	])
	combat.free()

	return ok


## [미니 기획 D]-1/2 검증: UPGRADE_SKILLS 데이터 형태(7종, "upgrades" 필드가 실제
## SKILLS/UNIQUE_SKILLS id를 가리키는지)와 available_upgrade_choices()/grant_upgrade()의
## 필터링 동작(base 미보유 시 후보 제외, "+" 이미 보유 시 후보 제외, character_id 필터,
## grant_upgrade가 올바른 "+"id를 추가하는지)을 검증한다.
func _check_upgrade_skill_pool(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) UPGRADE_SKILLS는 7종(SKILLS 2 + UNIQUE_SKILLS 5)이고, 각 "upgrades" 필드가
	# 실제 존재하는 base id를 가리키며, 이름은 전부 "<base 이름>+" 형태다.
	var base_ids: Array = []
	for s in SkillPool.SKILLS:
		base_ids.append(s["id"])
	for s in SkillPool.UNIQUE_SKILLS:
		base_ids.append(s["id"])
	var count_ok: bool = SkillPool.UPGRADE_SKILLS.size() == 7
	var all_upgrades_valid := true
	var all_names_plus := true
	for s in SkillPool.UPGRADE_SKILLS:
		if not base_ids.has(s["upgrades"]):
			all_upgrades_valid = false
		if not String(s["name"]).ends_with("+"):
			all_names_plus = false
	var data_ok: bool = count_ok and all_upgrades_valid and all_names_plus
	ok = data_ok and ok
	lines.append("  UPGRADE_SKILLS 데이터: 개수=%d(기대 7) upgrades 필드 전부 유효=%s 이름 전부 '+'로 끝남=%s -> %s" % [
		SkillPool.UPGRADE_SKILLS.size(), all_upgrades_valid, all_names_plus, "OK" if data_ok else "FAIL"
	])

	# (2) available_upgrade_choices(): base를 보유하지 않으면 후보에 안 나오고, base를
	# 보유하면 나오고, "+"까지 보유하면 다시 안 나온다(deep_breath 계열로 검증, 공용
	# 스킬이라 character_id 무관).
	var flags_backup: Array[String] = RunState.skill_flags.duplicate()

	RunState.skill_flags = []
	var no_base_choices := SkillPool.available_upgrade_choices(10)
	var no_base_has_breath_plus := false
	for s in no_base_choices:
		if s["id"] == "deep_breath_plus":
			no_base_has_breath_plus = true

	RunState.skill_flags = ["deep_breath"]
	var with_base_choices := SkillPool.available_upgrade_choices(10)
	var with_base_has_breath_plus := false
	for s in with_base_choices:
		if s["id"] == "deep_breath_plus":
			with_base_has_breath_plus = true

	RunState.skill_flags = ["deep_breath", "deep_breath_plus"]
	var with_plus_choices := SkillPool.available_upgrade_choices(10)
	var with_plus_still_has_breath_plus := false
	for s in with_plus_choices:
		if s["id"] == "deep_breath_plus":
			with_plus_still_has_breath_plus = true

	var breath_upgrade_flow_ok: bool = (not no_base_has_breath_plus) and with_base_has_breath_plus and (not with_plus_still_has_breath_plus)
	ok = breath_upgrade_flow_ok and ok
	lines.append("  '심호흡+' 후보 흐름: base 미보유=%s base 보유=%s +까지 보유=%s (기대 false/true/false) -> %s" % [
		no_base_has_breath_plus, with_base_has_breath_plus, with_plus_still_has_breath_plus, "OK" if breath_upgrade_flow_ok else "FAIL"
	])

	# (3) character_id 필터: '광기 심화+'는 frenzy_deepen을 보유한 berserker에게만
	# 제시되고, 같은 조건이라도 다른 character_id로 물으면 제시되지 않는다.
	RunState.skill_flags = ["frenzy_deepen"]
	var berserker_upgrade_choices := SkillPool.available_upgrade_choices(10, "berserker")
	var berserker_has_frenzy_plus := false
	for s in berserker_upgrade_choices:
		if s["id"] == "frenzy_deepen_plus":
			berserker_has_frenzy_plus = true
	var guardian_upgrade_choices := SkillPool.available_upgrade_choices(10, "guardian")
	var guardian_has_frenzy_plus := false
	for s in guardian_upgrade_choices:
		if s["id"] == "frenzy_deepen_plus":
			guardian_has_frenzy_plus = true
	var frenzy_plus_filter_ok: bool = berserker_has_frenzy_plus and not guardian_has_frenzy_plus
	ok = frenzy_plus_filter_ok and ok
	lines.append("  '광기 심화+' 캐릭터 필터: berserker=%s guardian=%s (기대 true/false) -> %s" % [
		berserker_has_frenzy_plus, guardian_has_frenzy_plus, "OK" if frenzy_plus_filter_ok else "FAIL"
	])

	# (4) grant_upgrade(base_id): base_id에 대응하는 "+"id를 skill_flags에 추가하고,
	# 대응하는 강화판이 없는 id(예: 존재하지 않는 스킬)를 넘기면 아무 것도 추가하지 않는다.
	RunState.skill_flags = ["chain_explosion"]
	SkillPool.grant_upgrade("chain_explosion")
	var grant_added_plus: bool = RunState.skill_flags.has("chain_explosion_plus")
	var flags_len_after_valid_grant: int = RunState.skill_flags.size()
	SkillPool.grant_upgrade("chain_explosion")
	var grant_no_dup: bool = RunState.skill_flags.size() == flags_len_after_valid_grant
	SkillPool.grant_upgrade("no_such_skill")
	var grant_noop_on_unknown: bool = RunState.skill_flags.size() == flags_len_after_valid_grant
	var grant_ok: bool = grant_added_plus and grant_no_dup and grant_noop_on_unknown
	ok = grant_ok and ok
	lines.append("  grant_upgrade(): '+' 추가=%s 중복 방지=%s 미지정 id 무시=%s -> %s" % [
		grant_added_plus, grant_no_dup, grant_noop_on_unknown, "OK" if grant_ok else "FAIL"
	])

	RunState.skill_flags = flags_backup
	return ok


## [미니 기획 D]-3 검증: 실제 event.tscn을 인스턴스화해 (1) 강화 후보가 있을 때
## _setup_skill_upgrade_event()가 카드를 정상 표시하고 _apply_skill_pick()으로 "+"id가
## skill_flags에 실제로 추가되는지(이중 실행 가드 포함, _check_skill_event_structure와
## 같은 패턴), (2) 강화 후보가 하나도 없으면 _ready()가 항상 폴백해 _is_skill_upgrade_event가
## false로 남는지(기획자 지시 "강화 가능한 스킬이 하나도 없으면 반드시 기존 이벤트로
## 대체" 검증)를 확인한다.
func _check_skill_upgrade_event_structure(lines: PackedStringArray) -> bool:
	var ok := true
	var flags_backup: Array[String] = RunState.skill_flags.duplicate()
	var character_backup: String = RunState.character_id
	var rooms_backup := RunState.rooms_cleared

	# (1) 강화 후보가 있는 상태: "임기응변"을 보유한 견습 모험가에게 "임기응변+" 카드를
	# 강제로 띄우고, 실제로 픽업까지 진행되는지 확인한다.
	RunState.character_id = "novice"
	RunState.skill_flags = ["versatile_surge"]
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	var candidate: Dictionary = SkillPool.UPGRADE_SKILLS[6]
	var candidate_id_ok: bool = candidate["id"] == "versatile_surge_plus"
	ok = candidate_id_ok and ok
	lines.append("  UPGRADE_SKILLS[6]=%s(기대 versatile_surge_plus) -> %s" % [
		candidate.get("id", ""), "OK" if candidate_id_ok else "FAIL"
	])

	var offer: Array[Dictionary] = [candidate]
	event_node._setup_skill_upgrade_event(offer)
	var offer_ok: bool = event_node._row_ui.size() == 1
	ok = offer_ok and ok
	lines.append("  _setup_skill_upgrade_event() 카드 1장 표시: row_ui=%d(기대 1) -> %s" % [
		event_node._row_ui.size(), "OK" if offer_ok else "FAIL"
	])

	var rooms_before: int = RunState.rooms_cleared
	var applied: bool = event_node._apply_skill_pick(candidate)
	var pick_ok: bool = (
		applied
		and RunState.skill_flags.has("versatile_surge_plus")
		and RunState.rooms_cleared == rooms_before + 1
	)
	ok = pick_ok and ok
	lines.append("  _apply_skill_pick('임기응변+') 후 skill_flags=%s rooms=%d(기대 %d) -> %s" % [
		RunState.skill_flags, RunState.rooms_cleared, rooms_before + 1, "OK" if pick_ok else "FAIL"
	])

	var reapplied: bool = event_node._apply_skill_pick(candidate)
	var guard_ok: bool = not reapplied and RunState.rooms_cleared == rooms_before + 1
	ok = guard_ok and ok
	lines.append("  _apply_skill_pick() 2차(이미 픽함): applied=%s rooms=%d(변화 없음 기대) -> %s" % [
		reapplied, RunState.rooms_cleared, "OK" if guard_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()

	# (2) 강화 후보가 하나도 없는 상태(스킬을 아직 하나도 안 얻음): _ready()가 확률과
	# 무관하게 항상 폴백해 _is_skill_upgrade_event가 false로 남아야 한다.
	RunState.character_id = "novice"
	RunState.skill_flags = []
	var fallback_node = event_scene.instantiate()
	add_child(fallback_node)
	var fallback_ok: bool = fallback_node._is_skill_upgrade_event == false
	ok = fallback_ok and ok
	lines.append("  강화 후보 없음 -> _is_skill_upgrade_event=%s(기대 false) -> %s" % [
		fallback_node._is_skill_upgrade_event, "OK" if fallback_ok else "FAIL"
	])
	remove_child(fallback_node)
	fallback_node.free()

	RunState.skill_flags = flags_backup
	RunState.character_id = character_backup
	RunState.rooms_cleared = rooms_backup
	return ok


## [미니 기획 D]-5 검증: item_card_style.gd build_card()의 highlight 파라미터가 실제로
## 테두리 색/두께를 바꾸는지 확인한다. highlight=false는 기존처럼 등급색(gcolor)+2px,
## highlight=true는 HIGHLIGHT_BORDER(노란색)+HIGHLIGHT_BORDER_WIDTH(4px)여야 한다.
func _check_skill_upgrade_card_highlight(lines: PackedStringArray) -> bool:
	var ok := true
	var sample_skill: Dictionary = SkillPool.SKILLS[0]

	var normal_built := ItemCardStyle.build_card(sample_skill)
	add_child(normal_built["card"])
	var normal_style: StyleBoxFlat = normal_built["card"].get_theme_stylebox("panel")
	var normal_ok: bool = (
		normal_style.border_color == ItemCardStyle.grade_color(sample_skill.get("grade", ItemCardStyle.DEFAULT_GRADE))
		and normal_style.border_width_left == 2
	)
	ok = normal_ok and ok
	lines.append("  highlight=false: border_color=등급색=%s border_width=%d(기대 2) -> %s" % [
		normal_style.border_color == ItemCardStyle.grade_color(sample_skill.get("grade", ItemCardStyle.DEFAULT_GRADE)),
		normal_style.border_width_left, "OK" if normal_ok else "FAIL"
	])
	normal_built["card"].queue_free()

	var highlighted_built := ItemCardStyle.build_card(sample_skill, "", false, true)
	add_child(highlighted_built["card"])
	var highlighted_style: StyleBoxFlat = highlighted_built["card"].get_theme_stylebox("panel")
	var highlight_ok: bool = (
		highlighted_style.border_color == ItemCardStyle.HIGHLIGHT_BORDER
		and highlighted_style.border_width_left == ItemCardStyle.HIGHLIGHT_BORDER_WIDTH
	)
	ok = highlight_ok and ok
	lines.append("  highlight=true: border_color=%s(기대 HIGHLIGHT_BORDER) border_width=%d(기대 %d) -> %s" % [
		highlighted_style.border_color, highlighted_style.border_width_left, ItemCardStyle.HIGHLIGHT_BORDER_WIDTH,
		"OK" if highlight_ok else "FAIL"
	])
	highlighted_built["card"].queue_free()

	return ok


## [미니 기획 E]-2 검증(INBOX.md 2026-09-17 기획자 결정): STARTING_SKILLS 6종이 모두
## 전투 배선 없이도 검증 가능한 순수 데이터/필터 로직이므로, 기획서가 명시한
## "캐릭터별 선택 가능한 시작 스킬 목록"(슬롯 0/1 순서 포함)이 starting_skills_for_
## character()로 정확히 재현되는지 확인한다.
func _check_starting_skills(lines: PackedStringArray) -> bool:
	var ok := true

	var expected := {
		"novice": ["start_expand", "start_lean"],
		"berserker": ["start_aggro", "start_hoard"],
		"guardian": ["start_wall", "start_ironclad"],
		"explosive": ["start_aggro", "start_expand"],
		"shieldbearer": ["start_wall", "start_lean"],
	}
	for character_id in expected.keys():
		var choices := SkillPool.starting_skills_for_character(character_id)
		var ids: Array = []
		for s in choices:
			ids.append(s["id"])
		var expected_ids: Array = expected[character_id]
		var char_ok: bool = ids == expected_ids
		ok = char_ok and ok
		lines.append("  %s 시작 스킬 슬롯 순서: %s (기대 %s) -> %s" % [
			character_id, ids, expected_ids, "OK" if char_ok else "FAIL"
		])

	var unknown_choices := SkillPool.starting_skills_for_character("unknown_character")
	var unknown_ok: bool = unknown_choices.is_empty()
	ok = unknown_ok and ok
	lines.append("  알 수 없는 캐릭터 id는 빈 목록 -> %s" % ("OK" if unknown_ok else "FAIL"))

	return ok


## [미니 기획 E]-3 검증(INBOX.md 2026-09-17 기획자 결정): character_select.gd의 시작
## 스킬 슬롯 UI가 (a) 기본 선택은 항상 슬롯 0, (b) 슬롯 1은 "clear_<character_id>"
## 업적 미해금 시 버튼 자체가 disabled(클릭 경로 자체가 막힘, 스타일만 다른 게
## 아님)인지, (c) 해금되면 실제로 슬롯 1을 고를 수 있는지, (d) 캐릭터를 바꿨을 때
## 이전에 고른 스킬 id가 새 캐릭터에서 잠긴 슬롯을 가리키면 슬롯 0으로 되돌아가는지
## (start_expand가 견습 모험가의 슬롯 0이자 폭발병의 슬롯 1이라는 교차 사례로 검증)를
## 확인한다. shop.gd 검증(이터레이션 45)과 같은 패턴으로 실제 character_select.tscn을
## 인스턴스화해 add_child로 트리에 넣은 뒤 실제 메서드를 호출한다.
func _check_starting_skill_selection_ui(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id

	AchievementManager._debug_reset_for_qa()

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	# (a) 견습 모험가를 고르면 잠긴 업적 없이도 슬롯 0("확장", start_expand)이
	# 기본 선택되어야 한다.
	node._on_card_selected("novice")
	var default_ok: bool = RunState.chosen_starting_skill_id == "start_expand"
	ok = default_ok and ok
	lines.append("  견습 모험가 기본 선택: chosen=%s (기대 start_expand) -> %s" % [
		RunState.chosen_starting_skill_id, "OK" if default_ok else "FAIL"
	])

	# (b) 슬롯 1("정예", start_lean)은 clear_novice 업적이 없으면 버튼이 disabled여야
	# 한다(스타일만 잠긴 게 아니라 pressed 시그널 자체가 연결 안 됨 -> 클릭 경로 차단).
	var slot0_button: Button = node._starting_skill_container.get_child(0)
	var slot1_button: Button = node._starting_skill_container.get_child(1)
	var locked_ok: bool = not slot0_button.disabled and slot1_button.disabled
	ok = locked_ok and ok
	lines.append("  업적 미해금 상태: 슬롯0 disabled=%s(기대 false) 슬롯1 disabled=%s(기대 true) -> %s" % [
		slot0_button.disabled, slot1_button.disabled, "OK" if locked_ok else "FAIL"
	])

	# (c) clear_novice를 해금하고 다시 선택하면 슬롯 1이 클릭 가능해지고, 실제로
	# 골랐을 때 chosen_starting_skill_id가 바뀐다.
	AchievementManager.unlock("clear_novice")
	node._on_card_selected("novice")
	var slot1_after_unlock: Button = node._starting_skill_container.get_child(1)
	var unlocked_ok: bool = not slot1_after_unlock.disabled
	ok = unlocked_ok and ok
	lines.append("  clear_novice 해금 후: 슬롯1 disabled=%s(기대 false) -> %s" % [
		slot1_after_unlock.disabled, "OK" if unlocked_ok else "FAIL"
	])
	node._on_starting_skill_selected("start_lean")
	var pick_slot1_ok: bool = RunState.chosen_starting_skill_id == "start_lean"
	ok = pick_slot1_ok and ok
	lines.append("  해금된 슬롯1 선택: chosen=%s (기대 start_lean) -> %s" % [
		RunState.chosen_starting_skill_id, "OK" if pick_slot1_ok else "FAIL"
	])

	# (d) 교차 사례: start_expand는 견습 모험가의 슬롯 0(항상 해금)이자 폭발병의
	# 슬롯 1(clear_explosive 필요)이다. chosen을 start_expand로 맞춰둔 뒤 clear_explosive
	# 없이 폭발병으로 바꾸면, 같은 id라도 폭발병 기준으로는 잠긴 슬롯이므로 슬롯 0
	# (start_aggro)으로 되돌아가야 한다.
	node._on_card_selected("novice")
	node._on_starting_skill_selected("start_expand")
	node._on_card_selected("explosive")
	var cross_lock_ok: bool = RunState.chosen_starting_skill_id == "start_aggro"
	ok = cross_lock_ok and ok
	lines.append("  교차 잠금(견습 슬롯0=폭발병 슬롯1인 start_expand) 전환: chosen=%s (기대 start_aggro) -> %s" % [
		RunState.chosen_starting_skill_id, "OK" if cross_lock_ok else "FAIL"
	])

	remove_child(node)
	node.free()
	AchievementManager._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	return ok


## [미니 기획 E]-4 검증(INBOX.md 2026-09-17 기획자 결정, 적용 배선): 지금까지의 1~3번
## 검증은 데이터/UI뿐이라 선택해도 실제 skill_flags에는 전혀 반영되지 않았다. 이 함수는
## RunState.reset_run()이 chosen_starting_skill_id를 실제로 SkillPool.grant()에 넘기는지
## (character_select.gd가 "던전 시작" 직전에 하는 것과 같은 순서 — chosen을 먼저 정하고
## reset_run()을 호출) 확인한다. combat_test.gd의 "맹공"/"철벽" 조건부 apply_flat_bonus는
## deep_breath와 마찬가지로 _do_exchange() 안에 인라인돼 있어(별도 순수 함수로 분리돼
## 있지 않음) 물리 시뮬레이션 없이 단위 테스트할 수 없다 — 대신 아래에서 두 캐릭터의
## 기본 다이스 구성(광전사=공격4/방어2, 수호자=공격2/방어4)이 각 스킬의 발동 조건과
## 실제로 맞아떨어지는지(설계 의도대로 "그 캐릭터 기본 상태에서 발동 가능"인지)를
## 확인하고, 실전투 크래시 여부는 qa_shot.sh 스크린샷으로 별도 확인한다.
func _check_starting_skill_combat_wiring(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id

	# (a) chosen_starting_skill_id가 설정된 채 reset_run()을 부르면, 새 런의 skill_flags에
	# 그 id가 즉시 들어가야 한다(전투 시작 전부터 적용 — character_select.gd와 동일 순서).
	RunState.chosen_starting_skill_id = "start_aggro"
	RunState.reset_run("berserker")
	var granted_ok: bool = RunState.skill_flags.has("start_aggro")
	ok = granted_ok and ok
	lines.append("  reset_run() 중 chosen_starting_skill_id 부여: berserker+start_aggro -> skill_flags=%s (start_aggro 포함 기대) -> %s" % [
		RunState.skill_flags, "OK" if granted_ok else "FAIL"
	])

	# (b) chosen_starting_skill_id가 비어있으면(예: 시작 화면을 거치지 않은 호출부) 아무
	# 것도 부여하지 않고 크래시도 없어야 한다.
	RunState.chosen_starting_skill_id = ""
	RunState.reset_run("novice")
	var empty_ok: bool = RunState.skill_flags.is_empty()
	ok = empty_ok and ok
	lines.append("  chosen_starting_skill_id 비어있을 때: skill_flags=%s (빈 배열 기대) -> %s" % [
		RunState.skill_flags, "OK" if empty_ok else "FAIL"
	])

	# (c) "맹공"(공격 개수 > 방어 개수) 발동 조건은 광전사 기본 구성(공격4/방어2)에서
	# 참이어야 하고, "철벽"(방어 개수 > 공격 개수)은 수호자 기본 구성(공격2/방어4)에서
	# 참이어야 한다 — combat_test.gd의 인라인 조건과 동일한 비교식으로 재확인한다.
	RunState.chosen_starting_skill_id = "start_aggro"
	RunState.reset_run("berserker")
	var aggro_condition_ok: bool = RunState.player_attack_bag.dice.size() > RunState.player_defense_bag.dice.size()
	ok = aggro_condition_ok and ok
	lines.append("  '맹공' 발동 조건(광전사 기본): 공격=%d 방어=%d (공격>방어 기대) -> %s" % [
		RunState.player_attack_bag.dice.size(), RunState.player_defense_bag.dice.size(), "OK" if aggro_condition_ok else "FAIL"
	])

	RunState.chosen_starting_skill_id = "start_wall"
	RunState.reset_run("guardian")
	var wall_condition_ok: bool = RunState.player_defense_bag.dice.size() > RunState.player_attack_bag.dice.size()
	ok = wall_condition_ok and ok
	lines.append("  '철벽' 발동 조건(수호자 기본): 공격=%d 방어=%d (방어>공격 기대) -> %s" % [
		RunState.player_attack_bag.dice.size(), RunState.player_defense_bag.dice.size(), "OK" if wall_condition_ok else "FAIL"
	])

	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	return ok
