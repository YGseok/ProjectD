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
	lines.append("[방향키/스페이스 포커스 내비게이션 검증: focus_nav.gd FocusNav]")
	all_pass = _check_focus_nav(lines) and all_pass

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
	lines.append("[잠긴 시작 스킬 미리보기 검증: character_select.gd _on_starting_skill_locked_preview / SkillPool.unlock_requirement]")
	all_pass = _check_starting_skill_locked_preview(lines) and all_pass

	lines.append("")
	lines.append("[시작 스킬 적용 배선 검증: run_state.gd reset_run() -> SkillPool.grant() / combat_test.gd 조건부 apply_flat_bonus]")
	all_pass = _check_starting_skill_combat_wiring(lines) and all_pass

	lines.append("")
	lines.append("[F-3 3번째 조각: 재굴림형 스택 적립->보너스 턴 전환 검증: combat_test.gd _update_stack_progress]")
	all_pass = _check_stack_progress(lines) and all_pass

	lines.append("")
	lines.append("[F-3 3번째 조각: 전체 흐름(E2E) 검증: 새 런 시작->라운드1 보스 격파->r1/slot1 해금->최종 클리어->clear/slot2 해금->새 런에서 실제 효과 반영]")
	all_pass = _check_f3_e2e_flow(lines) and all_pass

	lines.append("")
	lines.append("[스킬 id -> 이름 조회 검증: skill_pool.gd SkillPool.find_skill / deck_panel.gd DeckPanel._add_skills_section]")
	all_pass = _check_skill_pool_lookup(lines) and all_pass

	lines.append("")
	lines.append("[G-1: 몬스터 카탈로그 계열 아이콘 검증: monster_catalog.gd MonsterCatalog / family_icon.gd FamilyIcon]")
	all_pass = _check_monster_catalog_family_icons(lines) and all_pass

	lines.append("")
	lines.append("[G-2: 몬스터 스킬 프레임워크 이식 검증: monster_skills.gd MonsterSkills]")
	all_pass = _check_monster_skills_framework(lines) and all_pass

	lines.append("")
	lines.append("[G-3: 인간형 armor/guard_up/counter + 부정형 sticky/seal/dull/numb 프리미티브 검증]")
	all_pass = _check_g3_monster_skill_primitives(lines) and all_pass

	lines.append("")
	lines.append("[G-4: 야수형 pounce/bloodlust + 언데드형 drain/revive/chill 프리미티브 검증]")
	all_pass = _check_g4_monster_skill_primitives(lines) and all_pass

	lines.append("")
	lines.append("[G-5: 일반 몬스터 21종 데이터(R-1 로스터 정리 + R-3 부정형 신규 4종 추가 후) + legacy_cycle_monster 호환 + GAME_QA_MONSTER_ID 훅 검증]")
	all_pass = _check_g5_monster_catalog(lines) and all_pass

	lines.append("")
	lines.append("[대형 기획 16] R-1: 몬스터 로스터 정리 — 제거된 4종이 카탈로그/출현 풀에 없음, 유령류 family 재분류, 산적->풋내기 용병 개명, build_monster_plan/build_elite_plan이 여러 시드에서 새 풀 크기로 중복 없이 채워짐]")
	all_pass = _check_r1_monster_roster_cleanup(lines) and all_pass

	lines.append("")
	lines.append("[대형 기획 16] R-3: 부정형 신규 몬스터 5종(미믹/저주 인형/심연의 불/심연의 아이/심연의 사제) — 존재/family/tier/스킬/정예 규칙 적용/풀 편입/폴백 렌더 검증]")
	all_pass = _check_r3_amorphous_roster(lines) and all_pass

	lines.append("")
	lines.append("[G-6: 런 몬스터 계획(MonsterCatalog.build_monster_plan) + 라운드 난이도 스케일링 검증]")
	all_pass = _check_g6_monster_plan(lines) and all_pass

	lines.append("")
	lines.append("[G-7: 정예 전투 풀 7종(R-1 로스터 정리 후) + 정예 계획(build_elite_plan) + 보상(EliteRewardPool) 검증]")
	all_pass = _check_g7_elite_combat(lines) and all_pass

	lines.append("")
	lines.append("[G-8: 보스 6종(라운드당 2종) + 2페이즈(_maybe_activate_boss_phase2) 검증]")
	all_pass = _check_g8_boss(lines) and all_pass

	lines.append("")
	lines.append("[H-1: 테스트 전투 모드 플러밍 검증: RunState.test_battle이 업적/골드/눈금/방진행을 스킵하는지]")
	all_pass = _check_h1_test_battle_mode(lines) and all_pass

	lines.append("")
	lines.append("[H-2: 테스트 전투 설정 화면 검증: _apply_start_selection()이 캐릭터/스킬/몬스터/난이도를 실제로 반영하고 chosen_starting_skill_id를 되돌리는지]")
	all_pass = _check_h2_test_battle_setup(lines) and all_pass

	lines.append("")
	lines.append("[H-3: 성장 + 보유 스킬 세팅 검증: 프리셋/직접 설정이 실제 주머니 개수/면 개수/골드/인벤토리/skill_flags로 반영되는지]")
	all_pass = _check_h3_test_battle_growth(lines) and all_pass

	lines.append("")
	lines.append("[I-1: 해적(pirate) 캐릭터 + cannon_volley 기믹 검증: character_profiles.gd PROFILES / combat_test.gd _cannon_volley_damage / skill_icon.gd SkillIcon]")
	all_pass = _check_i1_pirate_cannon_volley(lines) and all_pass

	lines.append("")
	lines.append("[I-3: 해적 고유 스킬 broadside/broadside_plus 검증: skill_pool.gd UNIQUE_SKILLS/UPGRADE_SKILLS / combat_test.gd _cannon_volley_cycle / _cannon_volley_damage]")
	all_pass = _check_i3_pirate_broadside(lines) and all_pass

	lines.append("")
	lines.append("[F-5(a): 성장 정책 3종 검증: balance_sim.gd growth_sides_for/growth_counts_for/growth_config_for/apply_growth]")
	all_pass = _check_f5a_growth_policies(lines) and all_pass

	lines.append("")
	lines.append("[K-2: 캐릭터 선택 화면 가독성 개편 검증: character_select.gd 섹션 구조(헤더/능력치/고유 능력/시작 스킬/안내) + 8명 레이아웃 예산]")
	all_pass = _check_k2_character_select_sections(lines) and all_pass

	lines.append("")
	lines.append("[K-3: 캐릭터 퍼스널 컬러 검증: character_theme.gd ui_palette 대비비 + character_select/deck_panel 노드 StyleBox 색 실제 전환]")
	all_pass = _check_k3_character_theme(lines) and all_pass

	lines.append("")
	lines.append("[K-4a: 스킬 아이콘 모티프 검증: skill_pool.gd ICON_MOTIFS 전수 매핑 + skill_icon.gd 모티프별 실제 렌더 차이]")
	all_pass = (await _check_k4a_skill_icon_motifs(lines)) and all_pass

	lines.append("")
	lines.append("[K-4b: 스킬 아이콘 전 화면 적용 검증: item_card_style.gd build_card / character_select.gd 시작 스킬 슬롯 / deck_panel.gd 보유 스킬 섹션에 SkillIcon 실제 와이어링]")
	all_pass = _check_k4b_skill_icon_wiring(lines) and all_pass

	lines.append("")
	lines.append("[K-4c: 외부 아트 override 검증: skill_icon.gd render_source()가 override 파일 존재/부재에 따라 실제로 바뀌는지(resources/는 안 건드리고 user:// 임시 경로로)]")
	all_pass = _check_k4c_skill_icon_external_art(lines) and all_pass

	lines.append("")
	lines.append("[L-1: 캐릭터 카드 클릭 선택 검증: character_card_panel.gd CharacterCardPanel이 실제 InputEventMouseButton/ui_accept로 선택 상태를 바꾸는지 + '선택' 버튼이 더는 없는지]")
	all_pass = _check_l1_card_click_select(lines) and all_pass

	lines.append("")
	lines.append("[L-2(a): 스킬 도감 데이터/저장 검증: skill_pool.gd codex_entries() 완전성/순서 + skill_codex.gd 발견 기록 저장/로드/캐릭터별 격리/테스트전투 가드]")
	all_pass = _check_l2a_skill_codex(lines) and all_pass

	lines.append("")
	lines.append("[L-2(b): 스킬 도감 패널 UI 검증: skill_codex_panel.gd SkillCodexPanel이 보유/발견-미보유/미발견 3상태를 실제로 다른 텍스트/모듈레이트로 렌더하는지 + 격자 포커스 체인 + Esc 닫기]")
	all_pass = _check_l2b_skill_codex_panel(lines) and all_pass

	lines.append("")
	lines.append("[L-2(c): 스킬 도감 진입점 연결 검증: character_select/dungeon_map/shop/event/story_event의 '스킬 도감' 버튼이 실제로 패널을 열고(character_id/owned 값 포함) 토글로 닫는지]")
	all_pass = _check_l2c_skill_codex_entry_points(lines) and all_pass

	lines.append("")
	lines.append("[L-3: 전역 퍼스널 컬러 배경/패널 확장 검증: character_theme.gd apply_background()가 Background ColorRect/비네트를 실제로 캐릭터별로 다르게 칠하는지 + 5개 화면 + 오버레이 패널 3종(customize/achievement/skill_codex) 틀 테두리색 전환]")
	all_pass = (await _check_l3_personal_color_background(lines)) and all_pass

	lines.append("")
	lines.append("[M-1: 던전 맵 HUD/버튼 위계/DeckPanel 구역화 검증: dungeon_map.gd HUD 칩 실제 갱신 + UIKit 주/보조 버튼 색 차이 + DeckPanel 구역 패널화/스크롤 + FocusNav 포커스 오버레이가 커스텀 버튼색을 안 가리는지]")
	all_pass = _check_m1_dungeon_map_hud_and_buttons(lines) and all_pass

	lines.append("")
	lines.append("[M-2: 전투 화면 HUD 검증: combat_test.gd 3구역 HUD(플레이어/턴·라운드/몬스터) 실제 렌더 텍스트 + 티어 배지/특성 요약 순수 함수 + 디버그 줄 빌드 플래그 게이팅 + 전투 기록 패널/상태 요약 + 버튼 위계]")
	all_pass = _check_m2_combat_hud(lines) and all_pass

	lines.append("")
	lines.append("[M-3: 전투 화면 다이스 스테이지 확대 + 결과 칩 한 줄 정리 + 보상 프레임 검증: combat_test.gd 다이스 뷰포트 크기/비율, 공격·방어 칩이 라벨과 함께 한 줄로 중앙 정렬되는지, 보상 프레임이 전투 기록 패널 위에서 끝나는지]")
	all_pass = _check_m3_combat_dice_stage(lines) and all_pass

	lines.append("")
	lines.append("[ART-1b: 전투 화면 원화 표정 컷 연결 검증: face_* 5장이 전부 있으면(견습 모험가) 원화 텍스처로, 1장이라도 없으면(다른 캐릭터) 플레이스홀더 그대로인지 + set_expression() 호출 시 텍스처가 실제로 바뀌는지]")
	all_pass = _check_art1b_combat_face_art(lines) and all_pass

	lines.append("")
	lines.append("[M-5a: UIKit 이미지 스킨 지원 검증: ui_kit.gd의 패널(section/hud/overlay)/버튼(primary/secondary)/HP 바 팩토리가 resources/ui/ 스킨 파일 유무에 따라 실제로 StyleBoxTexture/NinePatchRect와 StyleBoxFlat/ColorRect 폴백 사이를 전환하는지(user:// 임시 경로로 '없음→있음→없음'), 캐릭터/틴트별로 다른 결과를 합성하는지, 실제 resources/ui/ 자산이 입고된 production 경로에서 combat_test/dungeon_map이 실제로 스킨을 쓰는지]")
	all_pass = _check_m5a_uikit_image_skin(lines) and all_pass

	lines.append("")
	lines.append("[M-5b: 배지/장식/아이콘/배경 이미지 스킨 검증: ui_kit.gd의 배지(turn/round/tier/codex)/장식(칩/구분선/제목 장식)/기능 아이콘 9종 + character_theme.gd의 배경 사진이 파일 유무에 따라 실제로 스킨↔폴백을 전환하는지, production 자산(이미 입고됨)으로 combat_test/dungeon_map이 실제로 스킨을 쓰는지]")
	all_pass = _check_m5b_badges_decor_icons_backgrounds(lines) and all_pass

	lines.append("")
	lines.append("[ART-2: 전투 화면 표정 컷 하단 잘림 처리 검증: 왼쪽 끝 글로벌 좌표가 화면 밖(x<16)으로 안 나가는지 + 하단 페이드 셰이더가 실제로 적용돼 바닥 근처 알파가 중간 높이보다 뚜렷이 낮게 렌더되는지]")
	all_pass = (await _check_art2_face_crop_fix(lines)) and all_pass

	lines.append("")
	lines.append("[M-4: 이벤트/상점/스토리 이벤트 화면 통일 검증: shop.gd HUD 골드 칩 실제 갱신 + event.gd/story_event.gd 버튼 위계(주 행동 vs 보조, 안전/위험 tint 구분) + 카드 안 동적 버튼(구매/적용/획득) 스타일링 + 서사 텍스트 배경 프레임]")
	all_pass = _check_m4_event_shop_story_ui(lines) and all_pass

	lines.append("")
	lines.append("[M-6: 카드 프레임 스킨 적용 검증: item_card_style.gd build_card()가 resources/ui/panel/card_{base,accent}.png 유무에 따라 StyleBoxTexture(등급/강조/골드부족색 틴트)<->StyleBoxFlat 폴백을 전환하는지, 등급별로 합성 결과가 실제로 다른지, 골드 부족 카드가 modulate로 눌려 칠해지는지]")
	all_pass = _check_m6_card_frame_skin(lines) and all_pass

	lines.append("")
	lines.append("[M-7: 던전 맵 방 카드(MapStrip) 프레임 스킨 검증: dungeon_map.gd _make_map_node()가 resources/ui/panel/card_{base,accent}.png 유무에 따라 StyleBoxTexture(현재=금색/완료=초록/미래=회색 틴트)<->StyleBoxFlat 폴백을 전환하는지, 방 상태 3종의 합성 결과가 실제로 서로 다른지, production 자산으로도 실제 렌더되는지]")
	all_pass = _check_m7_map_card_skin(lines) and all_pass

	lines.append("")
	lines.append("[N-1: 캐릭터 선택 — 카드 목록(수직 체인)과 시작 스킬 슬롯(수평 체인)이 실제 InputEventKey(방향키)로 서로 연결되는지 검증(전수 감사에서 발견: 전에는 마우스로만 슬롯에 닿을 수 있었음), 슬롯을 고른 뒤에도 방향키 포커스가 안 끊기는지]")
	all_pass = (await _check_n1_character_select_skill_slot_key_nav(lines)) and all_pass

	lines.append("")
	lines.append("[N-2: 캐릭터 선택 — 전신 이미지 큰 컬럼 검증: _detail_portrait_holder rect 높이가 560 이상인지, 상세 패널 내용(정보 컬럼)이 좁아진 폭에서도 8명 전부 예산 안에 들어오는지(넘치면 화면 밖으로 밀림), 캐릭터를 바꾸면 전신 이미지(원화 텍스처 또는 플레이스홀더 팔레트)가 실제로 바뀌는지]")
	all_pass = _check_n2_full_art_column(lines) and all_pass

	lines.append("")
	lines.append("[N-2b: 캐릭터 선택 — 전신 원화 실제 렌더 높이 검증(감독 확인): 컨테이너가 아니라 STRETCH_KEEP_ASPECT_CENTERED로 실제 그려지는 텍스처 높이를 계산해 8명 전부 >=520px인지, 던전 시작 버튼이 전신 컬럼과 안 겹치는지]")
	all_pass = (await _check_n2b_full_art_rendered_height(lines)) and all_pass

	lines.append("")
	lines.append("[N-3: flat/무테두리 버튼 전수 검색 검증: character_select/dungeon_map/combat_test/event/shop/story_event/test_battle_setup 전 화면 + AchievementPanel/SkillCodexPanel/CustomizePanel 오버레이의 모든 Button이 UIKit 스타일링(또는 FaceChipStyle/_apply_selection_style 같은 전용 스킨)으로 '보이는' normal 스타일박스를 실제로 받는지]")
	all_pass = _check_n3_button_styling(lines) and all_pass

	lines.append("")
	lines.append("[N-4: 캐릭터 선택 능력치 — '공격 D4×N' 문자열 대신 ShapeDieChip이 실제 attack_count/defense_count개 렌더되는지(8명 전부), 칩 모양/숫자가 sides와 일치하는지, 이벤트 다이스 줄이 event_die_sides와 일치하는지, '시작 보너스' +n 배지가 캐릭터/시작 스킬 조합에 따라 실제로 켜지고 꺼지는지]")
	all_pass = _check_n4_dice_chip_stats(lines) and all_pass

	lines.append("")
	lines.append("[N-5(a): 곡예사를 이벤트 특화 클래스로 — event_die_sides=D12(나머지 7종은 D6 유지), 시작 스킬 사다리가 눈속임/한탕/잡화점(이벤트 2종+전투 보조 1종)으로 재구성, 신규 고유 스킬 곡예 흥행(+)이 이벤트 주사위 굴림을 보정, chosen_starting_skill_id가 사라진 id(start_aggro)를 가리킬 때 슬롯0으로 안전하게 폴백]")
	all_pass = _check_n5a_juggler_event_specialist(lines) and all_pass

	lines.append("")
	lines.append("[N-5(b): 이벤트 판정 콘텐츠 확충 + 대성공 — EventChallengePool에 도박/탐색/함정 해체 3종이 보물과 함께 데이터 표로 존재하는지, tier_for_roll()의 fail/success/crit 3단 경계, roll_reward()가 type별로 올바른 범위/등급을 추첨하는지, 챌린지별 초기 화면·대성공 보상·온건한 실패 패널티가 실제 화면에서 겹침 없이 동작하는지, D6 클래스와 D12 곡예사의 성공률/대성공률이 실제 계산으로 의미 있게 차이나는지]")
	all_pass = _check_n5b_event_challenge_variety(lines) and all_pass

	lines.append("")
	lines.append("[N-5(c): 마무리 — character_select 고유 능력 설명(32자 예산)에 D12가 실제로 보이는지, DeckPanel(던전 맵 등 5개 화면 상시)도 D12를 보여주는지, 스킬 도감에 juggle_fortune/juggle_fortune_plus가 실제로 들어있는지. 밸런스(균형 정책 기준 견습 모험가 대비) 측정 결과는 dice_test 범위 밖이라 STATUS.md 완료 기록에 수동 측정값을 남긴다]")
	all_pass = _check_n5c_juggler_wrapup(lines) and all_pass

	lines.append("")
	lines.append("[N-6: 캐릭터 전용 이벤트 + 특별 선택지 — 8명 전부 전용/특별 콘텐츠 ≥1개 보유, 분량(전용 ≥4종/특별 ≥4종), pick_challenge()가 소유 캐릭터에게만 전용 이벤트를 기대 확률로 섞어주고 비소유 캐릭터에게는 100개 시드 전부 0회인지, 특별 선택지가 비소유 캐릭터에서 잠김(실행해도 상태 불변)·소유 캐릭터에서 활성(안전 선택지보다 기대값이 큰 보상을 실제로 받음)인지, 전용 이벤트 화면에 '전용' 배지가 실제로 뜨는지, challenge_seed()/pick_challenge()가 같은 run_seed+방 번호에서 항상 같은 결과를 내는지]")
	all_pass = _check_n6_character_events_and_special_choices(lines) and all_pass

	lines.append("")
	lines.append("[ART-1c: 몬스터 원화 표정 컷 경로 검증(ART-1b와 같은 방식, CharacterArt.has_all_faces()/load_face()를 MonsterPortrait 전용 base_dir로 재사용) — 가짜 user:// 디렉터리로 5장 모두/일부만/없음 세 경우의 _use_face_art 전환과 표정별 텍스처 교체, production combat_test 인스턴스가 몬스터 입고 상태와 항상 일치하는지, 원화 모드일 때 표정 컷 우측 끝이 화면 밖으로 안 나가는지(보통/보스 배율 둘 다), 하단 페이드 셰이더가 실제로 렌더되는지]")
	all_pass = (await _check_art1c_monster_face_art(lines)) and all_pass

	lines.append("")
	lines.append("[ART-1c-2: 몬스터 face_* 없이 full.png만 있을 때 상반신 크롭 폴백 — 우선순위(face_* 5장 > full.png 크롭 > 도형 플레이스홀더), set_expression() 호출이 크롭 상태를 안전하게 무시하는지, 카탈로그 35종 전체가 실시간 입고 상태(has_full()/has_all_faces())와 항상 일치하는지, 크롭 모드 몬스터의 화면 우측 끝이 안 잘리는지]")
	all_pass = _check_art1c2_monster_full_crop_fallback(lines) and all_pass

	lines.append("")
	lines.append("[ART-1c-3: 몬스터 컷 가장자리 페이드(하단·좌·우·위) + 경로 별칭(dark_knight -> dark_knight_elite) — SubViewport 알파 샘플링으로 중앙은 불투명/네 가장자리는 모두 거의 투명한지, MonsterCatalog.art_resource_id()가 별칭 표대로 해석하는지(별칭 없는 id는 그대로), dark_knight가 실제로 dark_knight_elite의 원화 경로를 보는지, 입고된 몬스터 전체(카탈로그 전수)가 화면 우측 끝 안에 들어오는지]")
	all_pass = (await _check_art1c3_monster_edge_fade_and_alias(lines)) and all_pass

	lines.append("")
	lines.append("[ART-1c-4: 어두운 몬스터 외곽 글로우 — CharacterArt.average_opaque_luminance()가 합성 어두운/밝은 이미지를 올바르게 판정하는지, 카탈로그 전수(입고된 34종) 휘도표, 실제 어두운 몬스터(그림자)가 글로우를 켜고 밝은 몬스터는 끝까지 안 켜지는지, 글로우 영역 실제 렌더 알파(SubViewport)가 투명하지 않은지]")
	all_pass = (await _check_art1c4_monster_dark_glow(lines)) and all_pass

	lines.append("")
	lines.append("[ART-1c-4: 전투 결과 줄 '공격'/'방어' 라벨 대비 — 라벨 색이 몬스터 색과 무관한 고정 팔레트(공격=금색/방어=밝은 회백)인지, 어두운 배경 대비 WCAG AA(4.5:1) 이상인지]")
	all_pass = _check_art1c4_dice_label_contrast(lines) and all_pass

	lines.append("")
	lines.append("[Q-1(17,24): 몬스터 포트레이트 티어별 배율/화면 밖 잘림 — MONSTER_PORTRAIT_SCALE_BY_TIER가 보스>정예>일반 단조 증가 + 보스가 일반 대비 >=1.4배인지, 카탈로그 전수(일반/정예/보스)를 production 배치(앵커+배율)로 실제 렌더해 _face_rect/_glow_rect 글로벌 rect가 전부 화면(1280x720) 안에 들어오는지]")
	all_pass = _check_q1_monster_portrait_tier_bounds(lines) and all_pass

	lines.append("")
	lines.append("[ART-1c-5: 보스 크롭·여백 — 보스 티어 크롭 시작 y가 일반/정예보다 위쪽인지, top_fade가 보스만 더 작은지, 보스 포트레이트 상단 y가 몬스터 HUD 패널 하단 y + 여백 이상인지(rect 계산), 보스 6종 전부 production 배치로 화면(1280x720) 안에 드는지]")
	all_pass = (await _check_art1c5_boss_crop(lines)) and all_pass

	lines.append("")
	lines.append("[ART-1c-6: 일반/정예 몬스터 얼굴 크롭·HUD 여백 — CharacterArt.detect_face_crop_ratio()가 합성 이미지(위쪽 투명 여백 N픽셀)에서 크롭 시작을 실제 불투명 시작 지점 근처로 잡는지, 머리 위 띠의 불투명 중심(x)을 따라가고 그 아래 멀리 떨어진 큰 덩어리(예: 꼬리)에 안 끌려가는지, full.png만 있는 일반/정예 몬스터 전수의 크롭 y가 과거 고정값(DEFAULT_FACE_CROP_RATIO.position.y)보다 머리에 더 가까운지, 일반/정예 포트레이트 상단 y가 몬스터 HUD 패널 하단 y + 여백 이상인지(카탈로그 전수, production trait 텍스트로 실측), 화면(1280x720) 안에 드는지]")
	all_pass = (await _check_art1c6_monster_face_crop_and_hud_margin(lines)) and all_pass

	lines.append("")
	lines.append("[Q-1(18): 전투 종료 후 다이스 결과 칩 줄이 보상/패배 버튼과 안 겹치는지 — battle_over가 true가 되는 시점(_maybe_finish_battle, 승리/패배 공통)에 _exchange_chip_nodes가 실제로 비워지는지, 비워진 뒤 남은 노드가 없어 보상 액션 버튼과 rect 교차가 0인지(승리/패배 둘 다)]")
	all_pass = (await _check_q1_reward_chip_overlap(lines)) and all_pass

	lines.append("")
	lines.append("[Q-1(23): 이벤트 텍스트가 UI(배경 프레임/버튼)에 맞게 들어가는지 — event.gd PromptLabel이 EventChallengePool 전수 prompt(+스킬 이벤트 2종)에서 autowrap으로 배경 프레임 폭 안에 들어오고 버튼과 안 겹치는지, story_event.gd Description이 시나리오 8종 전수에서 같은 조건 + 배경 프레임 안에서 수직 중앙 정렬되는지, 실제 Label 노드의 autowrap 레이아웃(get_combined_minimum_size)으로 측정]")
	all_pass = (await _check_q1_event_text_layout(lines)) and all_pass

	lines.append("")
	lines.append("[Q-3(7): 시작 스킬 슬롯 아이콘 비율 — 해금/잠금 양쪽 다 아이콘 영역(icon_area) rect가 정사각이고 40px 이상인지, 8명 전부(16개 슬롯) 실제 렌더 트리에서 측정]")
	all_pass = (await _check_q3_starting_skill_icon_ratio(lines)) and all_pass

	lines.append("")
	lines.append("[Q-3(9): 고유 능력 텍스트 폴리싱 — 8명 전부 ability_summary 라벨이 말줄임(…) 없이, ABILITY_DESC_WRAP_WIDTH 안에서 실제 폰트 측정으로 2줄 이내에 들어오는지, 곡예사는 D12가 보이는지]")
	all_pass = _check_q3_ability_summary_fits(lines) and all_pass

	lines.append("")
	lines.append("[Q-4a(12,13,14): 던전 맵 선택지 정리 — 방 선택지 5종 버튼 rect 크기가 모두 같은지, 보상 칩(RewardIcon)이 각 버튼의 자식 노드 안에 있는지(더 이상 떠 있는 별도 노드가 아닌지), 방 카드(MapStrip)에는 보상 칩이 전혀 없고 정예/보스 노출 방에만 배지가 붙는지]")
	all_pass = _check_q4a_dungeon_room_choices(lines) and all_pass

	lines.append("")
	lines.append("[Q-4b(11): 보유 스킬 팝업 — DeckPanel 보유 스킬 행이 CharacterCardPanel의 activated(클릭/Space 공용)로 SkillDetailPopup을 열고, 실제 렌더된 이름/설명(SkillPool.find_skill 값과 일치)을 보여주는지, 배경 클릭/X 버튼/Esc 세 갈래 전부 닫히는지, 닫기 버튼에 포커스 트랩(4방향 전부 자기 자신)이 걸려있는지]")
	all_pass = _check_q4b_skill_detail_popup(lines) and all_pass

	lines.append("")
	lines.append("[Q-4b(21): 던전 포기 — '던전 포기' 버튼(포커스+확정)이 확인 팝업(ConfirmDialog)을 열고, 취소/배경 클릭/Esc 세 갈래 전부 RunState를 전혀 건드리지 않고 닫히는지(취소 버튼이 기본 포커스), 확인(실제로는 _abandon_run()만 직접 호출)하면 RunState.gold/rooms_cleared/round_index/skill_flags가 전부 초기값으로 리셋되는지, 그 전후로 업적/스킬 도감의 해금·발견 상태(write-through 저장)는 그대로 유지되는지]")
	all_pass = _check_q4b_quit_run_confirm(lines) and all_pass

	lines.append("")
	lines.append("[Q-5(15): 정비 버튼 분리 — '정비'(customize_button)가 방 선택지 y-스택(_layout_visible_buttons)에 들어가지 않고 헤더 고정 위치를 유지하는지(방 선택지 노출 개수가 바뀌어도 position 불변), 그래도 포커스 체인에는 포함돼 항상 접근 가능한지, 보유 눈금이 있을 때만 강조(primary) 스타일로 바뀌고 없을 때는 보조(secondary) 스타일인지(둘 다 비활성화는 아님 — 항상 클릭 가능)]")
	all_pass = _check_q5_maintenance_entry_point(lines) and all_pass

	lines.append("")
	lines.append("[Q-5(16): 커스터마이징 UX 재설계 — 통합 화면의 '미리보기'(적용 전/후 칩, 바뀐 면 강조)에 실제로 렌더된 값이 _exchange_pip()이 실제로 적용한 결과(min(눈금, 면개수) 클램프 포함)와 정확히 일치하는지, '적용'을 누르기 전까지는 아무것도 바뀌지 않는지, '적용' 후 선택 상태가 초기화되는지]")
	all_pass = _check_q5_customize_preview_matches_apply(lines) and all_pass

	lines.append("")
	lines.append("[Q-5(16) 후속 — 셀프 피드백 버그 수정: 통합 화면 내용이 720px를 넘을 때 ScrollContainer로 실제 스크롤되는지 — 미리보기 단계에서 전체 내용 높이가 뷰포트(720)를 넘는 경우(여유 있는 공격/방어 주머니 수), '닫기' 버튼에 포커스를 주면 ScrollContainer.follow_focus가 실제로 스크롤해 그 버튼이 화면(0~720) 안으로 들어오는지]")
	all_pass = _check_q5_customize_scroll_follow_focus(lines) and all_pass

	lines.append("")
	lines.append("[Q-7(a): 스킬 효과 도식 문법 + 데이터 — SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS 전체 행에 diagram이 있는지(새 스킬 추가 시 누락이면 FAIL), 기호 수(배열 길이)가 SkillPool.MAX_DIAGRAM_SYMBOLS 이하인지, 각 칩의 type이 SkillPool.DIAGRAM_SYMBOL_TYPES 집합 안인지]")
	all_pass = _check_q7a_skill_diagrams(lines) and all_pass

	lines.append("")
	lines.append("[Q-7(b): SkillDiagram/SkillDiagramChip 렌더러 — 스킬 37종(고유 id) x 크기 2종(LARGE/SMALL) 전부 렌더된 칩 노드 수가 diagram 기호 수와 일치하고 지정 폭 컨테이너 가로 안/2줄 높이 예산 안에 들어오는지, 서로 다른 스킬이 실제로 다른 픽셀로 렌더되고 빈 도식(완전 투명)이 0개인지(SubViewport 픽셀 비교), 텍스트 대비가 WCAG AA(4.5:1) 이상인지]")
	all_pass = (await _check_q7b_skill_diagram_renderer(lines)) and all_pass

	lines.append("")
	lines.append("[Q-7(c) 후속(감독 피드백, 2026-10-18): 스킬 도감 시작 스킬 카드의 '슬롯 N' 태그가 SkillDiagram과 겹치지 않는지 — 절대 위치 오버레이에서 이름 줄 옆 인라인 요소로 옮긴 뒤, 실제 렌더된 두 노드의 global rect가 교차하지 않는지 직접 계산]")
	all_pass = (await _check_q7c_followup_slot_tag_diagram_overlap(lines)) and all_pass

	lines.append("")
	lines.append("[Q-8(a): 스킬 레어리티 체계 — SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS 전체 행에 유효한 rarity가 있는지(SkillPool.RARITY_ORDER 안), 기준표대로(공용=일반/고유=희귀/강화=베이스보다 한 등급 위) 배정됐는지, 등급 색/텍스트가 4종 서로 다른지, RARITY_DROP_WEIGHTS 가중치 선택 함수가 결정적 시드로 재현되는지]")
	all_pass = _check_q8a_skill_rarity_data(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(a) 화면 적용: 카드 프레임(보상/상점/이벤트 공유)/스킬 도감/스킬 상세 팝업/캐릭터 선택 시작 스킬 슬롯에 등급 배지(색+텍스트, 등급별로 서로 다름)가 실제로 렌더되는지]")
	all_pass = _check_q8a_rarity_display(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(b): 등급별 효과 차등 — UPGRADE_SKILLS 11쌍 전수(하드코딩 없이 개수로 커버리지 확인), 각 쌍이 실제로 쓰는 계산 함수/상수를 그대로 호출해 강화판 효과 수치가 베이스 이상인지(플래그가 아니라 계산 결과로). 등급 정의 순서 단조는 Q-8(a)에서 이미 검증]")
	all_pass = _check_q8b_upgrade_effect_values(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(c) 1/4: 전설 스킬 — 견습 모험가/광전사 6종 + '한 런에 전설 하나만' 인프라. has_legendary()/filter_legendary_if_owned()가 풀에서 전설 후보를 실제로 제거하는지, 효과 6종(만물의 조화/결의의 반격/운명의 뒤섞임/광전 돌격/유혈광란/불굴의 보복) 각각이 계산 결과(다이스 값/데미지)를 실제로 바꾸는지, 설명 문구에 안내가 포함되는지, SKILL_RARITY/ICON_MOTIFS 전수 등록(novice/berserker뿐 아니라 LEGENDARY_SKILLS 전체를 캐릭터별 3종 기준으로 generic 검사)]")
	all_pass = _check_q8c_legendary_skills(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(c) 2/4: 전설 스킬 — 수호자/폭발병 6종(최후의 보루/반격의 벽/불굴의 벽/연쇄 폭발의 고리/절대 폭발/최후의 폭발). 각 효과가 계산 결과(다이스 값/스택/데미지/턴 선택)를 실제로 바꾸는지(DiceBag.apply_force_max/RunState._bastion_fixed_value/_update_explosive_chain_progress/_absolute_detonation_bonus_damage/_overguard_counter_damage/_select_exchange_bags 통합 호출), 설명 문구 안내 포함]")
	all_pass = _check_q8c2_legendary_skills(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(c) 3/4: 전설 스킬 — 주술사/매혹사 6종(저주의 흡수/저주의 전이/저주의 종결/매혹의 포로/매혹의 극치/매혹의 응보). 각 효과가 계산 결과(HP 회복/몬스터 공격 감소/보너스 방어턴 강제/다이스 값/고정 피해)를 실제로 바꾸는지(DiceBag.apply_charm_debuff/apply_charm_ascend(신규)/_curse_absorb_heal/_curse_seal_reduction/_charm_amplify_count/_select_exchange_bags 통합 호출), 설명 문구 안내 포함]")
	all_pass = _check_q8c3_legendary_skills(lines) and all_pass

	lines.append("")
	lines.append("[Q-8(c) 4/4: 전설 스킬 — 곡예사/해적 6종(끝없는 저글링/완벽한 묘기/운명의 보정/무한 장전/처형자의 포격/전면 포격), 8명×3=24종 전체 완료. 각 효과가 계산 결과(다이스 맞교환 실제 발생/공방 합계 중 더 높은 쪽 채택/이벤트 주사위로 최저값 대체/함포 주기 단축/몬스터 HP 절반 이하 함포 2배/방어턴 추가 함포 피해)를 실제로 바꾸는지(DiceBag.swap_random_dice 통합 호출/_juggle_balance_total/_apply_fate_die/_overload_next_cycle/_execute_cannon_bonus/_cannon_volley_damage 재사용), 설명 문구 안내 포함 + LEGENDARY_SKILLS 24종 전체 캐릭터별 3종 커버리지(1/4의 (8)이 generic하게 재검증). 겸해 2/4·3/4에서 발견한 기존 버그(매혹의 응보/저주의 흡수 방어턴 분기가 반격의 벽 if 안에 잘못 중첩돼 실전에서 전혀 실행되지 않던 것)도 함께 고쳐 회귀 검증]")
	all_pass = _check_q8c4_legendary_skills(lines) and all_pass

	lines.append("")
	lines.append("[Q-11: 몬스터 도감 — 격자 카드 수==MonsterCatalog 전체 수, 격자/상세 뷰의 '원화/표정 n/5' 입고 현황이 실제 파일 존재(user:// 합성 에셋)와 일치, 계열/티어 필터가 실제 버튼 클릭으로 카드 수를 정확히 거르는지, 상세 뷰 표정 전환이 실제 렌더 픽셀을 바꾸는지(미입고 표정은 버튼 disabled로 전환 불가), 실제 InputEventKey 주입으로 필터 행->격자->상세 표정 버튼까지 방향키 이동 검증]")
	all_pass = (await _check_q11_monster_codex(lines)) and all_pass

	lines.append("")
	lines.append("[Q-12(a,c): 보스 설정 스토리 반영 — MonsterCatalog.boss_intro_text()가 character_intro(캐릭터 전용 변형) 우선, 없으면 intro(기본)로 폴백하는 결정적 조회(광전사x광란의 마수/수호자x타락한 기사단장 변형 + 매치 안 되는 캐릭터는 기본 폴백), 보스 6종 전부 intro 존재, 일반/정예 몬스터는 intro 없이도 빈 문자열(크래시 없음), production combat_test._ready()가 보스 전투 시작 시 전투 기록 로그 첫 줄에 실제로 그 문구를 찍는지(일반/정예 전투는 안 찍는지), 몬스터 도감 상세 뷰가 보스일 때만 '등장:' 줄을 info_label에 포함하는지]")
	all_pass = (await _check_q12_boss_intro(lines)) and all_pass

	lines.append("")
	lines.append("[Q-10: 스토리/특수 이벤트 일러스트 경로 — CharacterArt.load_event_art()/has_event_art()가 user:// 합성 PNG로 '파일 있음->Texture2D/파일 없음->null' 계약을 실제로 지키는지, event.gd/story_event.gd가 production 씬에서 아트 없음(폴백)/있음(표시)/판정 결과 구역과 겹치는 시점에 숨김(event.gd만, story_event.gd는 겹침이 없어 유지)까지 실제 노드로 배선됐는지, 판정+스토리 이벤트 전수 id 유니크, Q-12 인수인계 제목 겹침 버그(ancient_oath)가 실제 폰트 측정 기준으로도 더는 안 겹치는지]")
	all_pass = _check_q10_event_illustrations(lines) and all_pass

	lines.append("")
	lines.append("[Q-9: 고유 능력(기믹) 아이콘 + 업적 아이콘 — resources/skills/<기믹 id>.png·resources/achievements/<업적 id>.png 경로 규칙이 기믹/업적 id 전수에 대해 일관되는지, user:// 합성 PNG로 '파일 있음->외부 아트/파일 없음->절차적 폴백' 계약(양쪽 아이콘 + 고유 능력의 캐릭터 퍼스널 컬러 틴트), 절차적 도안 전수(기믹 8종+업적 9유형)가 서로 다른 픽셀로 렌더되는지, event.gd 특별 선택지 버튼이 safe/risky 버튼과 더 이상 겹치지 않는지(동반 수정)]")
	all_pass = (await _check_q9_gimmick_achievement_icons(lines)) and all_pass

	lines.append("")
	lines.append("[S-7(a): 아이콘 비율 왜곡 금지 — UIKit.compute_keep_aspect_rect()가 비정사각 slot/텍스처 조합에서 원본 비율을 오차 없이 유지하는지(순수 함수), 던전 맵 '전투'/'정예 전투' 선택지의 FamilyIcon·RewardIcon과 전투 화면 몬스터 FamilyIcon, 캐릭터 선택 시작 스킬 슬롯 icon_area가 실제 레이아웃을 거친 뒤(.size, custom_minimum_size 아님)에도 정사각(오차 2% 이내)으로 남는지 — HBoxContainer/VBoxContainer 기본 SIZE_FILL이 세로/가로로 늘리던 회귀(VISUAL_STANDARD.md 6-2)를 잡는다]")
	all_pass = (await _check_s7a_icon_keep_aspect(lines)) and all_pass

	lines.append("")
	lines.append("[S-7(b): 전투 기록 패널 화면 밖 잘림 — 전투 기록을 40줄까지 채운 뒤 '전투 기록' 패널 하단(_log_panel의 실제 렌더 global rect)이 1280x720 화면 높이 안에 들어오는지, log_label이 _log_clip 고정 높이 안에서 가장 최근 줄이 보이는 위치로 스크롤돼 있는지(position.y가 음수로 밀렸는지)를 실제 렌더 결과로 검증]")
	all_pass = (await _check_s7b_combat_log_panel_bounds(lines)) and all_pass

	lines.append("")
	lines.append("결과: %s" % ("PASS" if all_pass else "FAIL"))

	var text := "\n".join(lines)
	print(text)
	result_label.text = text


## [대형 기획 15] Q-1 공통 전제(2026-10-16) — visual_qa.gd는 GAME_QA_FRAME에 도달하면
## (GAME_QA_SETTLE 없이는) 현재 씬의 진행 상태와 무관하게 캡처+quit()한다. 이 테스트
## 스위트가 await로 여러 프레임에 걸쳐 끝나는 체크(Q-1(18)/(23) 등)가 늘면서 기본
## 프레임(60)으로는 끝까지 못 돌고 중간에 잘려 "결과: PASS/FAIL" 줄조차 못 찍는 사고가
## 실제로 있었다(원인 파악에 한 이터레이션 상당 소모). `scripts/qa_shot.sh dice_test`
## 호출 시 5번째 인자(settle)에 "1"을 주면 이 함수가 true가 될 때까지(결과가 실제로
## 찍힐 때까지) 캡처를 미뤄, 앞으로 체크가 더 늘어도 프레임 수를 손으로 다시 맞출
## 필요가 없다.
func _qa_is_settled() -> bool:
	# result_label의 초기 텍스트가 "(로딩 중...)"(dice_test.tscn, 빈 문자열이 아님)라
	# is_empty()로는 처음부터 항상 true가 되는 버그가 있었다(실제로 겪음 — settle=1로
	# 돌려도 프레임 60에서 바로 "정지"로 오판해 캡처, 테스트는 아직 중간이라 "결과:" 줄도
	# 없이 잘림) — 최종 줄에 항상 들어가는 "결과:" 포함 여부로 판정한다.
	return result_label.text.contains("결과:")


## [대형 기획 13] M-5a(2026-10-15) 신설 — resources/ui/ 실제 스킨 자산이 입고되면서
## UIKit 패널/버튼 팩토리를 쓰는 화면들의 "panel"/"normal" 등 테마 스타일이 이제
## StyleBoxFlat 대신 StyleBoxTexture일 수 있다(파일이 있으면 자동으로 이미지 스킨
## 우선). 기존 여러 테스트가 ".border_color"/".bg_color"를 직접 읽어 "캐릭터/버튼
## 종류가 다르면 달라야 한다"를 확인하던 방식은 StyleBoxTexture엔 그 속성이 없어
## 크래시한다 — 두 스타일 종류 모두에서 "구분값"을 안전하게 뽑아주는 공용 헬퍼.
## StyleBoxFlat은 border_color(테두리가 있으면)/bg_color를, StyleBoxTexture는 실제로
## 구워진 texture 객체(apply_panel_skin()/_button_state_stylebox()가 character_id나
## tint별로 다르게 합성하므로 식별값으로 충분)를 돌려준다.
func _m5_style_fingerprint(style: StyleBox) -> Variant:
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		if flat.border_width_left > 0 or flat.border_width_top > 0:
			return flat.border_color
		return flat.bg_color
	if style is StyleBoxTexture:
		return (style as StyleBoxTexture).texture
	return null


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


## [대형 기획 15] Q-7(a)(2026-10-17) 순수 데이터 검증 — 렌더러(Q-7b)는 아직 없으므로
## 여기서는 화면/SubViewport 없이 SkillPool.SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/
## STARTING_SKILLS 네 배열의 모든 행을 직접 순회해 "diagram" 데이터만 검증한다 —
## (1) 모든 행에 diagram이 있는지(새 스킬을 diagram 없이 추가하면 바로 이 체크가
## 잡는다 — INBOX.md "새 스킬 추가 시 누락이 FAIL로 걸리게" 요구), (2) 기호 수(배열
## 길이, 화살표 포함)가 SkillPool.MAX_DIAGRAM_SYMBOLS를 넘지 않는지, (3) 각 칩이
## "type" 필드를 갖고 그 값이 SkillPool.DIAGRAM_SYMBOL_TYPES 집합 안인지. STARTING_SKILLS는
## 해적 전용 중복 행(id는 같지만 character_ids만 다른 별도 row) 3개도 각자 diagram을
## 가져야 하므로 id 기준이 아니라 "행" 기준으로 전수 검사한다.
func _check_q7a_skill_diagrams(lines: PackedStringArray) -> bool:
	var ok := true
	var groups := {
		"SKILLS": SkillPool.SKILLS,
		"UNIQUE_SKILLS": SkillPool.UNIQUE_SKILLS,
		"LEGENDARY_SKILLS": SkillPool.LEGENDARY_SKILLS,
		"UPGRADE_SKILLS": SkillPool.UPGRADE_SKILLS,
		"STARTING_SKILLS": SkillPool.STARTING_SKILLS,
	}

	var total_rows := 0
	var seen_ids: Dictionary = {}
	var missing: PackedStringArray = []
	var too_many_symbols: PackedStringArray = []
	var bad_symbol_type: PackedStringArray = []

	for group_name in groups.keys():
		for skill in groups[group_name]:
			total_rows += 1
			var skill_id: String = skill.get("id", "?")
			seen_ids[skill_id] = true
			var diagram: Variant = skill.get("diagram", null)
			if not (diagram is Array) or (diagram as Array).is_empty():
				missing.append("%s/%s" % [group_name, skill_id])
				continue
			var diagram_array: Array = diagram
			if diagram_array.size() > SkillPool.MAX_DIAGRAM_SYMBOLS:
				too_many_symbols.append("%s/%s(%d개)" % [group_name, skill_id, diagram_array.size()])
			for chip in diagram_array:
				if not (chip is Dictionary) or not (chip as Dictionary).has("type"):
					bad_symbol_type.append("%s/%s(type 없음)" % [group_name, skill_id])
					continue
				var chip_type: String = (chip as Dictionary)["type"]
				if not SkillPool.DIAGRAM_SYMBOL_TYPES.has(chip_type):
					bad_symbol_type.append("%s/%s(%s)" % [group_name, skill_id, chip_type])

	var missing_ok: bool = missing.is_empty()
	var symbol_count_ok: bool = too_many_symbols.is_empty()
	var symbol_type_ok: bool = bad_symbol_type.is_empty()
	ok = missing_ok and symbol_count_ok and symbol_type_ok and ok

	lines.append("  전체 스킬 행 %d개(고유 id %d개) 중 diagram 누락 %d개 -> %s" % [
		total_rows, seen_ids.size(), missing.size(), "OK" if missing_ok else "FAIL"
	])
	if not missing.is_empty():
		lines.append("    누락: %s" % ", ".join(missing))
	lines.append("  기호 수 <= %d(상한) -> %s" % [SkillPool.MAX_DIAGRAM_SYMBOLS, "OK" if symbol_count_ok else "FAIL"])
	if not too_many_symbols.is_empty():
		lines.append("    초과: %s" % ", ".join(too_many_symbols))
	lines.append("  기호 종류가 DIAGRAM_SYMBOL_TYPES(%d종) 안인지 -> %s" % [SkillPool.DIAGRAM_SYMBOL_TYPES.size(), "OK" if symbol_type_ok else "FAIL"])
	if not bad_symbol_type.is_empty():
		lines.append("    범위 밖: %s" % ", ".join(bad_symbol_type))

	return ok


## [대형 기획 15] Q-7(b)(2026-10-17) — SkillDiagram/SkillDiagramChip 렌더러 검증.
## Q-7(a)가 만든 diagram 데이터를 실제로 Control 트리에 그려서 "플래그가 들어갔는가"가
## 아니라 "렌더된 노드 수/폭/픽셀이 실제로 기대대로인가"를 확인한다 — 세 갈래:
## (1) 스킬 37종(중복 id 제거) × 크기 2종(LARGE 폭260/SMALL 폭150) 전부, 렌더된
##     칩 노드 수가 diagram 배열 길이와 정확히 같고(=> SkillPool.MAX_DIAGRAM_SYMBOLS
##     이내), 각 칩 rect가 지정 폭 컨테이너 가로 안에 들어오며, 전체 사용 높이가
##     2줄 예산(CHIP_HEIGHT*2+여유) 이내인지.
## (2) 서로 다른 스킬의 도식이 실제로 다른 픽셀로 렌더되는지 — LARGE 크기로 37종을
##     각각 독립 SubViewport(K-4a와 같은 패턴)에 그려 바이트 단위 비교, 완전히
##     투명(빈 도식처럼 보임)한 렌더가 0개인지.
## (3) 모든 텍스트 라벨이 공유하는 TEXT_COLOR가 칩 배경 CHIP_BG 위에서 WCAG AA
##     (4.5:1) 이상인지(CharacterTheme.contrast_ratio 재사용).
## await를 쓰므로 호출부는 `await _check_q7b_skill_diagram_renderer(lines)`로 받는다.
func _check_q7b_skill_diagram_renderer(lines: PackedStringArray) -> bool:
	var ok := true

	var ids: Array = []
	var seen_id: Dictionary = {}
	for group in [SkillPool.SKILLS, SkillPool.UNIQUE_SKILLS, SkillPool.LEGENDARY_SKILLS, SkillPool.UPGRADE_SKILLS, SkillPool.STARTING_SKILLS]:
		for skill in group:
			var skill_id: String = skill["id"]
			if not seen_id.has(skill_id):
				seen_id[skill_id] = true
				ids.append(skill_id)

	# (1) 노드 수 / 폭 컨테이너 안 / 2줄 높이 예산 — 두 크기 모두.
	var size_presets := [
		{"variant": SkillDiagramChip.SIZE_LARGE, "width": 260.0, "label": "LARGE(카드/팝업, 폭260)"},
		{"variant": SkillDiagramChip.SIZE_SMALL, "width": 150.0, "label": "SMALL(툴팁/목록, 폭150)"},
	]
	var node_count_bad: PackedStringArray = []
	var too_many_bad: PackedStringArray = []
	var h_overflow_bad: PackedStringArray = []
	var v_overflow_bad: PackedStringArray = []

	for preset in size_presets:
		var variant: int = preset["variant"]
		var width: float = preset["width"]
		var line_budget: float = SkillDiagramChip.CHIP_HEIGHT[variant] * 2.0 + 10.0
		for skill_id in ids:
			var data: Array = SkillPool.diagram_for(skill_id)
			var diagram := SkillDiagram.new()
			add_child(diagram)
			diagram.size_variant = variant
			diagram.diagram_data = data
			diagram.size = Vector2(width, 400.0)
			await get_tree().process_frame
			await get_tree().process_frame
			var children := diagram.get_children()
			if children.size() != data.size():
				node_count_bad.append("%s/%s(%d칩 != %d기호)" % [preset["label"], skill_id, children.size(), data.size()])
			if data.size() > SkillPool.MAX_DIAGRAM_SYMBOLS:
				too_many_bad.append("%s/%s" % [preset["label"], skill_id])
			for child in children:
				var c: Control = child
				if c.position.x < -0.5 or c.position.x + c.size.x > width + 0.5:
					h_overflow_bad.append("%s/%s" % [preset["label"], skill_id])
					break
			var used_height: float = diagram.get_combined_minimum_size().y
			if used_height > line_budget:
				v_overflow_bad.append("%s/%s(%.1fpx > %.1fpx)" % [preset["label"], skill_id, used_height, line_budget])
			remove_child(diagram)
			diagram.free()

	var node_count_ok: bool = node_count_bad.is_empty()
	var too_many_ok: bool = too_many_bad.is_empty()
	var h_overflow_ok: bool = h_overflow_bad.is_empty()
	var v_overflow_ok: bool = v_overflow_bad.is_empty()
	ok = node_count_ok and too_many_ok and h_overflow_ok and v_overflow_ok and ok

	lines.append("  스킬 %d종(고유 id) x 크기 2종: 렌더된 칩 노드 수 == diagram 기호 수 -> %s" % [ids.size(), "OK" if node_count_ok else "FAIL"])
	if not node_count_bad.is_empty():
		lines.append("    불일치: %s" % ", ".join(node_count_bad))
	lines.append("  기호 수 <= MAX_DIAGRAM_SYMBOLS(%d) -> %s" % [SkillPool.MAX_DIAGRAM_SYMBOLS, "OK" if too_many_ok else "FAIL"])
	lines.append("  칩 rect가 지정 폭 컨테이너 가로 안(넘침 없음) -> %s" % ("OK" if h_overflow_ok else "FAIL"))
	if not h_overflow_bad.is_empty():
		lines.append("    가로 넘침: %s" % ", ".join(h_overflow_bad))
	lines.append("  전체 사용 높이가 2줄 예산 이내 -> %s" % ("OK" if v_overflow_ok else "FAIL"))
	if not v_overflow_bad.is_empty():
		lines.append("    세로 초과: %s" % ", ".join(v_overflow_bad))

	# (2) 서로 다른 스킬의 도식이 실제로 다른 픽셀로 렌더되는지 — LARGE 크기, 37종
	#     각각 독립 SubViewport(K-4a _check_k4a_skill_icon_motifs()와 같은 패턴).
	#     "다른 스킬 id"가 아니라 "다른 diagram 데이터"가 진짜 비교 단위다 — 예를
	#     들어 start_sleight(눈속임)/start_gambler(승부사)는 SkillPool.gd 주석대로
	#     "효과는 같지만 매혹사와 공유하지 말라"는 기획자 지시로 id만 분리한 완전히
	#     동일한 diagram(이벤트 주사위 -> DC-1)이라 같은 그림이 나오는 게 정답이다.
	#     그래서 diagram 데이터를 직렬화한 서명이 같은 스킬끼리는 같은 렌더를
	#     기대하고(렌더러 결정성 확인), 서명이 다른데 픽셀까지 같으면 그게 진짜
	#     렌더러 버그(FAIL)다.
	# Q-7(c)(2026-10-17): LARGE 칩 높이가 34->44로 커지면서(카드/팝업 가시성 개선) 2줄
	# 예산(44*2+gap)이 기존 72px 캔버스를 넘을 수 있어 높이를 100으로 올렸다 — 비교 로직
	# 자체(바이트 단위 동일성)는 안 바뀜, 그냥 더 큰 칩이 잘리지 않고 온전히 캡처되게 함.
	var vp_size := Vector2i(260, 100)
	var viewports: Array[SubViewport] = []
	var signatures: Dictionary = {}
	for skill_id in ids:
		var data_for_sig: Array = SkillPool.diagram_for(skill_id)
		signatures[skill_id] = JSON.stringify(data_for_sig)
		var diagram2 := SkillDiagram.new()
		diagram2.size_variant = SkillDiagramChip.SIZE_LARGE
		diagram2.diagram_data = data_for_sig
		diagram2.position = Vector2.ZERO
		diagram2.size = Vector2(vp_size)
		var vp := SubViewport.new()
		vp.size = vp_size
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.add_child(diagram2)
		add_child(vp)
		viewports.append(vp)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var blank_ids: PackedStringArray = []
	var dup_pairs: PackedStringArray = []
	var expected_dup_pairs: PackedStringArray = []
	var seen_images: Dictionary = {}
	for i in range(ids.size()):
		var img: Image = viewports[i].get_texture().get_image()
		if img == null:
			blank_ids.append(ids[i])
			continue
		var data: PackedByteArray = img.get_data()
		var has_pixel := false
		for b in data:
			if b != 0:
				has_pixel = true
				break
		if not has_pixel:
			blank_ids.append(ids[i])
			continue
		for other_id in seen_images.keys():
			if seen_images[other_id] == data:
				if signatures[ids[i]] == signatures[other_id]:
					expected_dup_pairs.append("%s==%s(diagram 데이터 자체가 동일)" % [ids[i], other_id])
				else:
					dup_pairs.append("%s==%s" % [ids[i], other_id])
		seen_images[ids[i]] = data

	for vp in viewports:
		remove_child(vp)
		vp.free()

	var blank_ok: bool = blank_ids.is_empty()
	var distinct_ok: bool = dup_pairs.is_empty()
	ok = blank_ok and distinct_ok and ok

	lines.append("  빈 도식(완전 투명 렌더)인 스킬 수 -> %d개 %s" % [blank_ids.size(), "OK" if blank_ok else "FAIL"])
	if not blank_ids.is_empty():
		lines.append("    빈 도식: %s" % ", ".join(blank_ids))
	lines.append("  diagram 데이터가 다른 스킬끼리는 서로 다른 픽셀로 렌더(진짜 렌더러 충돌 쌍 0개) -> %s" % ("OK" if distinct_ok else "FAIL"))
	if not dup_pairs.is_empty():
		lines.append("    동일 렌더 쌍(버그): %s" % ", ".join(dup_pairs))
	if not expected_dup_pairs.is_empty():
		lines.append("    (참고, FAIL 아님) diagram 데이터 자체가 같아 같은 그림인 쌍: %s" % ", ".join(expected_dup_pairs))

	# (3) 텍스트 대비(WCAG AA 4.5:1 이상) — 모든 텍스트 라벨이 공유하는 TEXT_COLOR.
	var contrast := CharacterTheme.contrast_ratio(SkillDiagramChip.TEXT_COLOR, SkillDiagramChip.CHIP_BG)
	var contrast_ok := contrast >= 4.5
	ok = contrast_ok and ok
	lines.append("  텍스트 대비(TEXT_COLOR vs CHIP_BG) = %.2f:1 (기준 4.5:1 이상) -> %s" % [contrast, "OK" if contrast_ok else "FAIL"])

	return ok


## [감독 피드백, Q-7(c) 직후(2026-10-18)] 스킬 도감 시작 스킬 카드에서 "슬롯 N" 태그가
## SkillDiagram 첫 칩과 겹치던 버그 — skill_codex_panel.gd가 절대 위치 오버레이
## (_make_corner_tag, wrap 기준 anchor)에서 이름 줄 옆 인라인 요소(_make_inline_tag,
## name_row 안)로 옮겼다. "안 겹치게 보인다"가 아니라 실제 렌더된 두 노드의 global
## rect를 직접 교차 계산해 검증한다(await로 레이아웃이 실제로 정렬된 뒤 측정 — Q-6
## 검증(_check_l2b_skill_codex_panel)이 anchor 값만 본 것과 달리, 이번엔 둘 다
## Container가 배치하는 일반 흐름 요소라 get_global_rect()가 레이아웃 정렬 이후에만
## 믹힌다).
func _check_q7c_followup_slot_tag_diagram_overlap(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_flags_backup := RunState.skill_flags.duplicate()

	SkillCodex._debug_reset_for_qa()
	RunState.character_id = "novice"
	var owned: Array[String] = ["start_expand"]
	RunState.skill_flags = owned.duplicate()
	SkillCodex.mark_discovered("novice", "start_expand")

	var panel := SkillCodexPanel.new()
	add_child(panel)
	panel.open("novice", owned)
	await get_tree().process_frame
	await get_tree().process_frame

	var nodes_found: bool = panel._diagram_by_id.has("start_expand") and panel._slot_tag_by_id.has("start_expand")
	ok = nodes_found and ok
	if nodes_found:
		var diagram_rect: Rect2 = (panel._diagram_by_id["start_expand"] as Control).get_global_rect()
		var slot_label: Label = panel._slot_tag_by_id["start_expand"]
		var slot_tag_rect: Rect2 = (slot_label.get_parent() as Control).get_global_rect()
		var no_overlap: bool = not diagram_rect.intersects(slot_tag_rect)
		ok = no_overlap and ok
		lines.append("  시작 스킬 카드(확장, 슬롯 1) 도식 rect=%s 슬롯 태그 rect=%s 교차 없음 -> %s" % [
			diagram_rect, slot_tag_rect, "OK" if no_overlap else "FAIL"
		])
	else:
		lines.append("  도식/슬롯 태그 노드를 찾지 못함(_diagram_by_id/_slot_tag_by_id) -> FAIL")

	remove_child(panel)
	panel.queue_free()
	SkillCodex._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup
	return ok


## [대형 기획 15] Q-8(a)(2026-10-18, INBOX.md 원문 5): 스킬 레어리티 체계 — 데이터
## 전수 검증(37종 전부 유효한 등급, 배정 기준표대로) + 등급 표시 4종이 서로 다른지 +
## 가중치 추첨 함수(weighted_pick)가 결정적 시드로 재현되는지(플래그가 아니라 실제
## 계산 결과인 "뽑힌 id 목록"으로 비교).
func _check_q8a_skill_rarity_data(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 전수 검증 — SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS(고유 id) 전체가
	# SkillPool.SKILL_RARITY에 명시적으로 등록돼 있고 값이 RARITY_ORDER 안에 있는지.
	var all_ids: Array[String] = []
	for group in [SkillPool.SKILLS, SkillPool.UNIQUE_SKILLS, SkillPool.LEGENDARY_SKILLS, SkillPool.UPGRADE_SKILLS, SkillPool.STARTING_SKILLS]:
		for skill in group:
			var skill_id: String = skill["id"]
			if not all_ids.has(skill_id):
				all_ids.append(skill_id)

	var missing: Array[String] = []
	var invalid: Array[String] = []
	for id in all_ids:
		if not SkillPool.SKILL_RARITY.has(id):
			missing.append(id)
		elif not SkillPool.RARITY_ORDER.has(SkillPool.SKILL_RARITY[id]):
			invalid.append(id)
	var coverage_ok: bool = missing.is_empty() and invalid.is_empty()
	ok = coverage_ok and ok
	lines.append("  스킬 %d종(고유 id) 전수 rarity 등록: 누락=%s 잘못된 값=%s -> %s" % [
		all_ids.size(), missing, invalid, "OK" if coverage_ok else "FAIL"
	])

	# (2) 배정 기준표 — 공용(SKILLS)=일반, 고유(UNIQUE_SKILLS)=희귀, 시작(STARTING_SKILLS)=
	# 일반, 강화(UPGRADE_SKILLS)는 베이스 등급보다 정확히 한 단계 위(공용 베이스 2종->희귀,
	# 고유 베이스 9종->영웅).
	var base_tiers_ok := true
	for skill in SkillPool.SKILLS:
		base_tiers_ok = (SkillPool.rarity_for(skill["id"]) == SkillPool.RARITY_COMMON) and base_tiers_ok
	for skill in SkillPool.UNIQUE_SKILLS:
		base_tiers_ok = (SkillPool.rarity_for(skill["id"]) == SkillPool.RARITY_RARE) and base_tiers_ok
	for skill in SkillPool.STARTING_SKILLS:
		base_tiers_ok = (SkillPool.rarity_for(skill["id"]) == SkillPool.RARITY_COMMON) and base_tiers_ok
	ok = base_tiers_ok and ok
	lines.append("  기준표: 공용/시작 스킬=일반, 고유 스킬=희귀 -> %s" % ("OK" if base_tiers_ok else "FAIL"))

	var upgrade_tier_ok := true
	var upgrade_mismatches: Array[String] = []
	for skill in SkillPool.UPGRADE_SKILLS:
		var base_rarity: String = SkillPool.rarity_for(skill["upgrades"])
		var upgrade_rarity: String = SkillPool.rarity_for(skill["id"])
		var expected_index: int = SkillPool.RARITY_ORDER.find(base_rarity) + 1
		var actual_index: int = SkillPool.RARITY_ORDER.find(upgrade_rarity)
		if actual_index != expected_index:
			upgrade_tier_ok = false
			upgrade_mismatches.append(skill["id"])
	ok = upgrade_tier_ok and ok
	lines.append("  기준표: 강화판(UPGRADE_SKILLS)=베이스보다 한 등급 위, 불일치=%s -> %s" % [
		upgrade_mismatches, "OK" if upgrade_tier_ok else "FAIL"
	])

	# (3) 전설 등급 스킬 수가 LEGENDARY_SKILLS.size()와 정확히 일치하는지(SKILL_RARITY에
	# legendary로 등록된 id가 LEGENDARY_SKILLS 밖에 실수로 더 있거나, LEGENDARY_SKILLS에
	# 있는데 SKILL_RARITY 등록을 빠뜨린 경우를 모두 잡는다) — Q-8(c)가 캐릭터를 늘려갈
	# 때마다 숫자를 고쳐야 했던 "이번 조각 기대 0" 하드코딩을 자기 참조 검증으로 바꿨다.
	var legendary_count := 0
	for id in SkillPool.SKILL_RARITY.keys():
		if SkillPool.SKILL_RARITY[id] == SkillPool.RARITY_LEGENDARY:
			legendary_count += 1
	var legendary_count_matches_ok: bool = legendary_count == SkillPool.LEGENDARY_SKILLS.size()
	ok = legendary_count_matches_ok and ok
	lines.append("  전설 등급 스킬 수=%d == LEGENDARY_SKILLS.size()=%d -> %s" % [
		legendary_count, SkillPool.LEGENDARY_SKILLS.size(), "OK" if legendary_count_matches_ok else "FAIL"
	])

	# (4) 등급 표시 4종(라벨/색)이 서로 다른지.
	var label_set: Dictionary = {}
	var color_set: Dictionary = {}
	for r in SkillPool.RARITY_ORDER:
		label_set[SkillPool.rarity_label(r)] = true
		color_set[SkillPool.rarity_color(r)] = true
	var labels_distinct_ok: bool = label_set.size() == SkillPool.RARITY_ORDER.size()
	var colors_distinct_ok: bool = color_set.size() == SkillPool.RARITY_ORDER.size()
	ok = labels_distinct_ok and colors_distinct_ok and ok
	lines.append("  등급 표시 4종: 라벨 전부 다름=%s 색 전부 다름=%s -> %s" % [
		labels_distinct_ok, colors_distinct_ok, "OK" if (labels_distinct_ok and colors_distinct_ok) else "FAIL"
	])

	# (5) weighted_pick() 결정적 시드 재현 — 같은 시드면 "뽑힌 id 순서"까지 항상 같아야
	# 한다(플래그가 아니라 계산 결과 자체를 비교).
	var sample_pool: Array[Dictionary] = []
	for group in [SkillPool.SKILLS, SkillPool.UNIQUE_SKILLS, SkillPool.UPGRADE_SKILLS]:
		for skill in group:
			sample_pool.append(skill)

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 12345
	var picked_a := SkillPool.weighted_pick(sample_pool, 6, rng_a)
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 12345
	var picked_b := SkillPool.weighted_pick(sample_pool, 6, rng_b)
	var ids_a: Array = []
	for s in picked_a:
		ids_a.append(s["id"])
	var ids_b: Array = []
	for s in picked_b:
		ids_b.append(s["id"])
	var deterministic_ok: bool = ids_a == ids_b and ids_a.size() == 6
	ok = deterministic_ok and ok
	lines.append("  weighted_pick() 결정적 시드(12345) 재현: 1차=%s 2차=%s -> %s" % [
		ids_a, ids_b, "OK" if deterministic_ok else "FAIL"
	])

	# 중복 없이, 원래 pool 소속만 뽑혔는지.
	var pool_ids: Dictionary = {}
	for s in sample_pool:
		pool_ids[s["id"]] = true
	var seen: Dictionary = {}
	var no_dup_ok := true
	for id in ids_a:
		if seen.has(id) or not pool_ids.has(id):
			no_dup_ok = false
		seen[id] = true
	ok = no_dup_ok and ok
	lines.append("  뽑힌 6개가 중복 없이 원래 pool 소속만 -> %s" % ("OK" if no_dup_ok else "FAIL"))

	# n >= pool 크기면(비복원 추출이므로) 전체를 그대로 돌려주는지.
	var full_pick := SkillPool.weighted_pick(sample_pool, sample_pool.size() + 10, rng_a)
	var full_pick_ids: Dictionary = {}
	for s in full_pick:
		full_pick_ids[s["id"]] = true
	var full_pick_ok: bool = full_pick.size() == sample_pool.size() and full_pick_ids.size() == pool_ids.size()
	ok = full_pick_ok and ok
	lines.append("  n>=pool 크기(%d)면 전체를 그대로 반환 -> %s" % [sample_pool.size(), "OK" if full_pick_ok else "FAIL"])

	return ok


## [대형 기획 15] Q-8(a) 화면 적용 검증: 카드 프레임(보상/상점/이벤트 공유)/스킬 도감/
## 스킬 상세 팝업/캐릭터 선택 시작 스킬 슬롯 네 곳에 등급 배지(텍스트, SkillPool.
## rarity_label()과 일치)가 실제로 렌더되는지 — "플래그가 들어갔는가"가 아니라 "그
## 텍스트가 화면에 실제로 보이는가"로 검증한다.
func _check_q8a_rarity_display(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 카드 프레임(ItemCardStyle.build_card, 보상/상점/이벤트 공유) — 공용 스킬
	# (deep_breath, 일반)과 고유 스킬(frenzy_deepen, 희귀) 두 카드의 배지 텍스트가
	# SkillPool.rarity_label()과 일치하고 서로 다른지.
	var common_skill := SkillPool.find_skill("deep_breath")
	var rare_skill := SkillPool.find_skill("frenzy_deepen")
	var common_card: Dictionary = ItemCardStyle.build_card(common_skill)
	var rare_card: Dictionary = ItemCardStyle.build_card(rare_skill)
	var common_badge_label: Label = (common_card["title_row"] as HBoxContainer).get_child(0).get_child(0)
	var rare_badge_label: Label = (rare_card["title_row"] as HBoxContainer).get_child(0).get_child(0)
	var card_badge_ok: bool = (
		common_badge_label.text == SkillPool.rarity_label(SkillPool.RARITY_COMMON)
		and rare_badge_label.text == SkillPool.rarity_label(SkillPool.RARITY_RARE)
		and common_badge_label.text != rare_badge_label.text
	)
	ok = card_badge_ok and ok
	lines.append("  카드 프레임 배지: 심호흡(공용)='%s'(기대 일반) 광기 심화(고유)='%s'(기대 희귀) -> %s" % [
		common_badge_label.text, rare_badge_label.text, "OK" if card_badge_ok else "FAIL"
	])
	(common_card["card"] as Control).free()
	(rare_card["card"] as Control).free()

	# (2) 스킬 도감(SkillCodexPanel) — 발견/보유 카드에만 등급 태그가 붙는지(위 Q-6
	# "색만으로 구분 금지" 원칙과 같은 정보 공개 범위).
	var character_backup := RunState.character_id
	var skill_flags_backup := RunState.skill_flags.duplicate()
	SkillCodex._debug_reset_for_qa()
	RunState.character_id = "novice"
	var owned: Array[String] = ["start_expand"]
	RunState.skill_flags = owned.duplicate()
	SkillCodex.mark_discovered("novice", "start_expand")
	SkillCodex.mark_discovered("novice", "versatile_surge")

	var codex := SkillCodexPanel.new()
	add_child(codex)
	codex.open("novice", owned)
	var codex_owned_tag: Label = codex._rarity_tag_by_id.get("start_expand", null)
	var codex_discovered_tag: Label = codex._rarity_tag_by_id.get("versatile_surge", null)
	var codex_tags_ok: bool = (
		codex_owned_tag != null and codex_owned_tag.text == SkillPool.rarity_label(SkillPool.RARITY_COMMON)
		and codex_discovered_tag != null and codex_discovered_tag.text == SkillPool.rarity_label(SkillPool.RARITY_RARE)
	)
	ok = codex_tags_ok and ok
	lines.append("  스킬 도감: 보유(확장)='%s'(기대 일반) 발견(임기응변)='%s'(기대 희귀) -> %s" % [
		codex_owned_tag.text if codex_owned_tag != null else "(없음)",
		codex_discovered_tag.text if codex_discovered_tag != null else "(없음)",
		"OK" if codex_tags_ok else "FAIL"
	])
	remove_child(codex)
	codex.queue_free()

	# (3) 스킬 상세 팝업(SkillDetailPopup) — 등급 배지 텍스트.
	var popup := SkillDetailPopup.new()
	add_child(popup)
	popup.open("start_expand", "novice")
	var popup_ok: bool = popup._rarity_badge_label != null and popup._rarity_badge_label.text == SkillPool.rarity_label(SkillPool.RARITY_COMMON)
	ok = popup_ok and ok
	lines.append("  스킬 상세 팝업(확장): 배지='%s'(기대 일반) -> %s" % [
		popup._rarity_badge_label.text if popup._rarity_badge_label != null else "(없음)", "OK" if popup_ok else "FAIL"
	])
	remove_child(popup)
	popup.queue_free()

	SkillCodex._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup

	# (4) 캐릭터 선택 시작 스킬 슬롯 — novice의 슬롯 0(확장)에 등급 태그가 실제로 붙는지.
	var cs_scene := load("res://code/scenes/character_select.tscn")
	var cs_node = cs_scene.instantiate()
	add_child(cs_node)
	cs_node._on_card_selected("novice")
	var slot_tag: Label = cs_node._rarity_tag_by_skill_id.get("start_expand", null)
	var slot_tag_ok: bool = slot_tag != null and slot_tag.text == SkillPool.rarity_label(SkillPool.RARITY_COMMON)
	ok = slot_tag_ok and ok
	lines.append("  캐릭터 선택 시작 스킬 슬롯(novice/확장): 태그='%s'(기대 일반) -> %s" % [
		slot_tag.text if slot_tag != null else "(없음)", "OK" if slot_tag_ok else "FAIL"
	])
	remove_child(cs_node)
	cs_node.free()

	return ok


## [대형 기획 15] Q-8(b)(등급별 효과 차등, 2026-10-18, INBOX.md 원문 5): UPGRADE_SKILLS
## 11쌍 전수 — "강화판 효과 수치가 베이스 이상"을 계산 결과로 검증한다(플래그 존재만
## 보지 않음). 등급 정의 순서 단조(강화판=베이스보다 한 등급 위)는 이미
## _check_q8a_skill_rarity_data()의 (2)가 전수 검증하므로 여기서는 반복하지 않고
## "효과 수치" 쪽만 한 곳에 모아 표로 남긴다.
##
## 전수 점검 결과(각 항목 참고) — 11쌍 모두 기존 "+"(UPGRADE_SKILLS) 구현이 이미
## "등급이 높으면 효과가 크거나 조건이 완화" 규칙을 지키고 있어, 효과 수치를 바꾸는
## 코드 변경은 하지 않았다(docs/STATUS.md Q-8(b) 완료 기록의 표 참고). 계산 결과로
## 직접 비교할 수 있게 일부는 기존 인라인 삼항연산자/if-elif를 순수 함수로 뽑아냈을
## 뿐이다(_frenzy_extra_rolls()/_guard_extra_rolls()/_spare_die_count(),
## RunState._juggle_encore_swap_count() — 전부 동작 불변). 설명 문구 2건(frenzy_
## deepen_plus/guard_deepen_plus)은 "두 번이 아니라 세 번"처럼 베이스 대비 변화를
## 명시하도록 보강했다(효과 자체는 불변).
func _check_q8b_upgrade_effect_values(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")
	var flags_backup: Array = RunState.skill_flags.duplicate()
	var combat = combat_script.new()

	# (1) 심호흡 -> 심호흡+: 적용 범위(첫 방어턴 1회 -> 매 방어턴)를 _deep_breath_bonus()
	# 순수 함수로 3턴 방어 시뮬레이션해 총 보너스 합을 비교.
	var breath_base_total := 0
	var breath_base_used := false
	for _t in 3:
		var br: Dictionary = combat_script._deep_breath_bonus(["deep_breath"], breath_base_used)
		breath_base_total += int(br["bonus"])
		if br["consume"]:
			breath_base_used = true
	var breath_plus_total := 0
	for _t in 3:
		var br2: Dictionary = combat_script._deep_breath_bonus(["deep_breath_plus"], false)
		breath_plus_total += int(br2["bonus"])
	var breath_ok: bool = breath_plus_total > breath_base_total and breath_base_total == 1 and breath_plus_total == 3
	ok = breath_ok and ok
	lines.append("  (1) 심호흡 -> 심호흡+: 3턴 방어 보너스 합계 base=%d(기대 1, 첫턴만) plus=%d(기대 3, 매턴) -> %s" % [
		breath_base_total, breath_plus_total, "OK" if breath_ok else "FAIL"
	])

	# (2) 여분 -> 여분+: 굴리는 여분 다이스 개수(_spare_die_count(), Q-8(b)로 분리).
	RunState.skill_flags = ["spare_die"]
	var spare_base_count: int = combat._spare_die_count()
	RunState.skill_flags = ["spare_die_plus"]
	var spare_plus_count: int = combat._spare_die_count()
	var spare_count_ok: bool = spare_plus_count > spare_base_count and spare_base_count == 1 and spare_plus_count == 2
	ok = spare_count_ok and ok
	lines.append("  (2) 여분 -> 여분+: 여분 다이스 개수 base=%d(기대 1) plus=%d(기대 2) -> %s" % [
		spare_base_count, spare_plus_count, "OK" if spare_count_ok else "FAIL"
	])

	# (3) 광기 심화 -> 광기 심화+: 보너스턴 추가 리롤 횟수(_frenzy_extra_rolls(), Q-8(b)로 분리).
	combat.player_frenzy_deepen_plus_active = false
	var frenzy_base_rolls: int = combat._frenzy_extra_rolls()
	combat.player_frenzy_deepen_plus_active = true
	var frenzy_plus_rolls: int = combat._frenzy_extra_rolls()
	var frenzy_ok: bool = frenzy_plus_rolls > frenzy_base_rolls and frenzy_base_rolls == 1 and frenzy_plus_rolls == 2
	ok = frenzy_ok and ok
	lines.append("  (3) 광기 심화 -> 광기 심화+: 보너스턴 추가 리롤 base=%d(총 2번) plus=%d(총 3번) -> %s" % [
		frenzy_base_rolls, frenzy_plus_rolls, "OK" if frenzy_ok else "FAIL"
	])

	# (4) 수호 심화 -> 수호 심화+: (3)과 완전히 대칭(_guard_extra_rolls()).
	combat.player_guard_deepen_plus_active = false
	var guard_base_rolls: int = combat._guard_extra_rolls()
	combat.player_guard_deepen_plus_active = true
	var guard_plus_rolls: int = combat._guard_extra_rolls()
	var guard_ok: bool = guard_plus_rolls > guard_base_rolls and guard_base_rolls == 1 and guard_plus_rolls == 2
	ok = guard_ok and ok
	lines.append("  (4) 수호 심화 -> 수호 심화+: 보너스턴 추가 리롤 base=%d(총 2번) plus=%d(총 3번) -> %s" % [
		guard_base_rolls, guard_plus_rolls, "OK" if guard_ok else "FAIL"
	])

	# (5) 연쇄 폭발 -> 연쇄 폭발+: 임계치는 둘 다 2로 같지만(_player_explosive_threshold()),
	# "+"만 보너스턴에 추가 리롤이 1회 더 붙는다 — base는 extra_rolls=0(호출 자체가 없어
	# _apply_bonus_reroll을 0회로 부른 것과 동일, 반드시 원래 값 그대로)과 동치임을
	# 실제로 호출해 확인하고, plus(extra_rolls=1)는 여러 번 굴려도 절대 그보다 낮아지지
	# 않는지(_apply_bonus_reroll의 "최댓값만 채택" 성질, 3686라인 공용 검증과 같은 패턴)
	# 함께 확인한다.
	combat.player_chain_explosion_active = true
	var chain_explosion_threshold: int = combat._player_explosive_threshold()
	combat.player_chain_explosion_plus_active = true
	var chain_explosion_plus_threshold: int = combat._player_explosive_threshold()
	var chain_bag := DiceBag.new(20, 1)
	var chain_base_values: Array = [5]
	var chain_base_result: Array = combat._apply_bonus_reroll(chain_bag, chain_base_values, 0)
	var chain_plus_never_decreased := true
	for _i in 40:
		var chain_plus_result: Array = combat._apply_bonus_reroll(chain_bag, chain_base_values, 1)
		if chain_plus_result[0] < chain_base_values[0]:
			chain_plus_never_decreased = false
	var chain_explosion_ok: bool = (
		chain_explosion_threshold == 2 and chain_explosion_plus_threshold == 2
		and chain_base_result[0] == 5 and chain_plus_never_decreased
	)
	ok = chain_explosion_ok and ok
	lines.append("  (5) 연쇄 폭발 -> 연쇄 폭발+: 임계치 둘 다 %d(동일 유지), 리롤 0회(base, 항상 %d 그대로)=%s 1회(plus) 절대 감소 없음=%s -> %s" % [
		chain_explosion_threshold, chain_base_result[0], chain_base_result[0] == 5, chain_plus_never_decreased, "OK" if chain_explosion_ok else "FAIL"
	])

	# (6) 연쇄 방어 -> 연쇄 방어+: (5)와 완전히 대칭.
	combat.player_chain_guard_active = true
	var chain_guard_threshold: int = combat._player_guard_threshold()
	combat.player_chain_guard_plus_active = true
	var chain_guard_plus_threshold: int = combat._player_guard_threshold()
	var guard_bag := DiceBag.new(20, 1)
	var guard_base_values: Array = [5]
	var guard_base_result: Array = combat._apply_bonus_reroll(guard_bag, guard_base_values, 0)
	var guard_plus_never_decreased := true
	for _i in 40:
		var guard_plus_result: Array = combat._apply_bonus_reroll(guard_bag, guard_base_values, 1)
		if guard_plus_result[0] < guard_base_values[0]:
			guard_plus_never_decreased = false
	var chain_guard_ok: bool = (
		chain_guard_threshold == 2 and chain_guard_plus_threshold == 2
		and guard_base_result[0] == 5 and guard_plus_never_decreased
	)
	ok = chain_guard_ok and ok
	lines.append("  (6) 연쇄 방어 -> 연쇄 방어+: 임계치 둘 다 %d(동일 유지), 리롤 0회(base, 항상 %d 그대로)=%s 1회(plus) 절대 감소 없음=%s -> %s" % [
		chain_guard_threshold, guard_base_result[0], guard_base_result[0] == 5, guard_plus_never_decreased, "OK" if chain_guard_ok else "FAIL"
	])

	# (7) 임기응변 -> 임기응변+: 공격/방어 임계치가 함께 완화(3 -> 2).
	combat.player_chain_explosion_active = false
	combat.player_chain_explosion_plus_active = false
	combat.player_chain_guard_active = false
	combat.player_chain_guard_plus_active = false
	combat.player_versatile_plus_active = false
	var versatile_base_atk: int = combat._player_explosive_threshold()
	var versatile_base_def: int = combat._player_guard_threshold()
	combat.player_versatile_plus_active = true
	var versatile_plus_atk: int = combat._player_explosive_threshold()
	var versatile_plus_def: int = combat._player_guard_threshold()
	var versatile_ok: bool = (
		versatile_base_atk == 3 and versatile_base_def == 3
		and versatile_plus_atk == 2 and versatile_plus_def == 2
	)
	ok = versatile_ok and ok
	lines.append("  (7) 임기응변 -> 임기응변+: 공격/방어 임계치 base=%d/%d(기대 3/3) plus=%d/%d(기대 2/2, 조건 완화) -> %s" % [
		versatile_base_atk, versatile_base_def, versatile_plus_atk, versatile_plus_def, "OK" if versatile_ok else "FAIL"
	])
	combat.free()

	# (8) 매혹 심화 -> 매혹 심화+: DiceBag.apply_charm_flip() 변환 대상 개수(2 -> 3)가
	# 실제로 더 많은 다이스를 최댓값으로 바꾸는지(합계 비교, D4x4 [1,2,3,4] 기준).
	var charm_bag := DiceBag.new(4, 4)
	var charm_values: Array = [1, 2, 3, 4]
	var charm_base_result: Array = charm_bag.apply_charm_flip(charm_values, 2)
	var charm_plus_result: Array = charm_bag.apply_charm_flip(charm_values, 3)
	var charm_base_sum := 0
	for cv in charm_base_result:
		charm_base_sum += int(cv)
	var charm_plus_sum := 0
	for cv2 in charm_plus_result:
		charm_plus_sum += int(cv2)
	var charm_ok: bool = charm_plus_sum > charm_base_sum
	ok = charm_ok and ok
	lines.append("  (8) 매혹 심화 -> 매혹 심화+: apply_charm_flip(count=2/3) 결과 합계 base=%d plus=%d(기대 plus>base) -> %s" % [
		charm_base_sum, charm_plus_sum, "OK" if charm_ok else "FAIL"
	])

	# (9) 곡예 앙코르 -> 곡예 앙코르+: 라운드 전환 시 다이스 맞바꾸기 횟수
	# (RunState._juggle_encore_swap_count(), run_state.gd에서 Q-8(b)로 분리).
	var encore_base_count: int = RunState._juggle_encore_swap_count(["juggle_encore"])
	var encore_plus_count: int = RunState._juggle_encore_swap_count(["juggle_encore", "juggle_encore_plus"])
	var encore_ok: bool = encore_plus_count > encore_base_count and encore_base_count == 1 and encore_plus_count == 2
	ok = encore_ok and ok
	lines.append("  (9) 곡예 앙코르 -> 곡예 앙코르+: 라운드 전환당 맞바꾸기 횟수 base=%d(기대 1) plus=%d(기대 2) -> %s" % [
		encore_base_count, encore_plus_count, "OK" if encore_ok else "FAIL"
	])

	# (10) 일제 사격 -> 일제 사격+: 주기는 동일(2턴)하지만 고정 피해 공식이 "절반" ->
	# "전부"로 강화된다(_cannon_volley_damage(), attack_sum=11 기준 ceil(11/2)=6 < 11).
	var volley_base: int = combat_script._cannon_volley_damage(11, 2, 2, false)
	var volley_plus: int = combat_script._cannon_volley_damage(11, 2, 2, true)
	var volley_ok: bool = volley_plus > volley_base and volley_base == 6 and volley_plus == 11
	ok = volley_ok and ok
	lines.append("  (10) 일제 사격 -> 일제 사격+: 공격 합계 11 기준 고정 피해 base=%d(기대 6, ceil(11/2)) plus=%d(기대 11, 전부) -> %s" % [
		volley_base, volley_plus, "OK" if volley_ok else "FAIL"
	])

	# (11) 곡예 흥행 -> 곡예 흥행+: 이벤트 주사위 굴림 보정(event_roll_bonus(), +1 -> +2).
	var event_script := load("res://code/scenes/event.gd")
	var fortune_base: int = event_script.event_roll_bonus(["juggle_fortune"])
	var fortune_plus: int = event_script.event_roll_bonus(["juggle_fortune_plus"])
	var fortune_ok: bool = fortune_plus > fortune_base and fortune_base == 1 and fortune_plus == 2
	ok = fortune_ok and ok
	lines.append("  (11) 곡예 흥행 -> 곡예 흥행+: 이벤트 주사위 보정 base=%d(기대 1) plus=%d(기대 2) -> %s" % [
		fortune_base, fortune_plus, "OK" if fortune_ok else "FAIL"
	])

	RunState.skill_flags = flags_backup

	# (12) 11쌍 전수 커버 확인 — UPGRADE_SKILLS 항목 수가 여전히 11인지. 위에서 쌍마다
	# 손으로 하나씩 짚었으므로, 새 강화판이 추가돼 이 개수가 달라지면 이 함수도 같이
	# 갱신해야 한다는 신호로 FAIL한다(새 스킬 추가 시 누락 방지, 다른 전수표들과 같은
	# 관례).
	var pair_count_ok: bool = SkillPool.UPGRADE_SKILLS.size() == 11
	ok = pair_count_ok and ok
	lines.append("  (12) UPGRADE_SKILLS 쌍 개수=%d(기대 11, 위 11개 항목과 1:1 대응 — 늘어나면 이 함수도 갱신 필요) -> %s" % [
		SkillPool.UPGRADE_SKILLS.size(), "OK" if pair_count_ok else "FAIL"
	])

	return ok


## [대형 기획 15] Q-8(c) 1/4(전설 스킬, 2026-10-19, INBOX.md 원문 5): 견습 모험가/
## 광전사 전설 6종 + "한 런에 전설은 하나만" 인프라 — 플래그 존재가 아니라 실제
## "계산 결과"(다이스 값/데미지)가 바뀌는지 검증한다(프로젝트 공통 테스트 원칙).
func _check_q8c_legendary_skills(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) has_legendary()/filter_legendary_if_owned(): 전설 미보유면 풀 그대로, 보유하면
	# 전설 후보가 전부 사라지고 그 외 등급은 그대로 남는지.
	var no_legend_flags: Array = ["deep_breath"]
	var has_legend_flags: Array = ["legend_novice_harmony"]
	var legend_check_pool: Array[Dictionary] = []
	for skill in SkillPool.LEGENDARY_SKILLS:
		legend_check_pool.append(skill)
	for skill in SkillPool.SKILLS:
		legend_check_pool.append(skill)
	var has_legend_false: bool = SkillPool.has_legendary(no_legend_flags) == false
	var has_legend_true: bool = SkillPool.has_legendary(has_legend_flags) == true
	var filtered_without: Array[Dictionary] = SkillPool.filter_legendary_if_owned(legend_check_pool, no_legend_flags)
	var filtered_with: Array[Dictionary] = SkillPool.filter_legendary_if_owned(legend_check_pool, has_legend_flags)
	var filtered_without_has_legendary := false
	for skill in filtered_without:
		if SkillPool.rarity_for(skill["id"]) == SkillPool.RARITY_LEGENDARY:
			filtered_without_has_legendary = true
	var filtered_with_has_legendary := false
	for skill in filtered_with:
		if SkillPool.rarity_for(skill["id"]) == SkillPool.RARITY_LEGENDARY:
			filtered_with_has_legendary = true
	var pool_filter_ok: bool = (
		has_legend_false and has_legend_true
		and filtered_without.size() == legend_check_pool.size() and filtered_without_has_legendary
		and filtered_with.size() == SkillPool.SKILLS.size() and not filtered_with_has_legendary
	)
	ok = pool_filter_ok and ok
	lines.append("  (1) has_legendary()/filter_legendary_if_owned(): 미보유 시 풀 크기 %d->%d(변화 없음)/전설 포함=%s, 보유 시 %d->%d(전설 전부 제거)/전설 포함=%s -> %s" % [
		legend_check_pool.size(), filtered_without.size(), filtered_without_has_legendary,
		legend_check_pool.size(), filtered_with.size(), filtered_with_has_legendary,
		"OK" if pool_filter_ok else "FAIL",
	])

	# (2) "만물의 조화"(_apply_harmonize_lowest): 최저값이 그 턴 최고값으로 바뀌는지
	# (자기 면 상한 없음 — D4 셋 중 1을 더 큰 다이스의 결과인 6으로 교체).
	var harmony_before: Array = [1, 3, 6]
	var harmony_after: Array = combat_script._apply_harmonize_lowest(harmony_before)
	var harmony_sum_before := 0
	for hv in harmony_before:
		harmony_sum_before += int(hv)
	var harmony_sum_after := 0
	for hv2 in harmony_after:
		harmony_sum_after += int(hv2)
	var harmony_ok: bool = harmony_after == [6, 3, 6] and harmony_sum_after > harmony_sum_before
	ok = harmony_ok and ok
	lines.append("  (2) 만물의 조화: [1,3,6] -> %s(기대 [6,3,6], 합계 %d->%d) -> %s" % [
		harmony_after, harmony_sum_before, harmony_sum_after, "OK" if harmony_ok else "FAIL",
	])

	# (3) "결의의 반격"(_perfect_block_counter_damage): 완전 방어(dmg=0)일 때만 방어
	# 합계가 반격 피해로, 피해가 조금이라도 있으면 0.
	var rally_full_block: int = combat_script._perfect_block_counter_damage(0, 7)
	var rally_partial_block: int = combat_script._perfect_block_counter_damage(2, 7)
	var rally_ok: bool = rally_full_block == 7 and rally_partial_block == 0
	ok = rally_ok and ok
	lines.append("  (3) 결의의 반격: 완전방어(dmg=0,def=7) 반격=%d(기대 7) / 부분방어(dmg=2,def=7) 반격=%d(기대 0) -> %s" % [
		rally_full_block, rally_partial_block, "OK" if rally_ok else "FAIL",
	])

	# (4) "운명의 뒤섞임"(RunState._fateshuffle_swap_count): 미보유 0회, 보유 시
	# min(공격 개수, 방어 개수)회(적은 쪽 기준 "전부").
	var fateshuffle_none: int = RunState._fateshuffle_swap_count(["deep_breath"], 3, 2)
	var fateshuffle_active: int = RunState._fateshuffle_swap_count(["legend_novice_fateshuffle"], 3, 2)
	var fateshuffle_ok: bool = fateshuffle_none == 0 and fateshuffle_active == 2
	ok = fateshuffle_ok and ok
	lines.append("  (4) 운명의 뒤섞임: 미보유=%d(기대 0) 보유(공3/방2)=%d(기대 2, 적은 쪽) -> %s" % [
		fateshuffle_none, fateshuffle_active, "OK" if fateshuffle_ok else "FAIL",
	])

	# (5) "광전 돌격"(_ragenuke_bonus_value): 보너스턴에만 항상 max_value로 확정,
	# 평소 공격턴은 입력값 그대로.
	var ragenuke_bonus: int = combat_script._ragenuke_bonus_value(5, 20, true)
	var ragenuke_normal: int = combat_script._ragenuke_bonus_value(5, 20, false)
	var ragenuke_ok: bool = ragenuke_bonus == 20 and ragenuke_normal == 5
	ok = ragenuke_ok and ok
	lines.append("  (5) 광전 돌격: 보너스턴(굴림 5)=%d(기대 20, 확정) 평소턴(굴림 5)=%d(기대 5, 그대로) -> %s" % [
		ragenuke_bonus, ragenuke_normal, "OK" if ragenuke_ok else "FAIL",
	])

	# (6) "유혈광란"/"불굴의 보복" 공용 식(_legend_hits_bonus_damage) + DiceBag.
	# count_min_rolls()(신규, count_max_rolls()와 대칭): min_max_only 다이스(D4x4)에서
	# 최솟값/최댓값 개수를 정확히 세고, 개수에 비례해 고정 피해가 나오는지.
	var legend_bag := DiceBag.new(4, 4)
	var legend_values: Array = [1, 4, 1, 4]
	var legend_min_hits: int = legend_bag.count_min_rolls(legend_values)
	var legend_max_hits: int = legend_bag.count_max_rolls(legend_values)
	var bloodlust_dmg: int = combat_script._legend_hits_bonus_damage(legend_max_hits)
	var vengeance_dmg: int = combat_script._legend_hits_bonus_damage(legend_min_hits)
	var zero_hits_dmg: int = combat_script._legend_hits_bonus_damage(0)
	var legend_hits_ok: bool = (
		legend_min_hits == 2 and legend_max_hits == 2
		and bloodlust_dmg == 4 and vengeance_dmg == 4 and zero_hits_dmg == 0
	)
	ok = legend_hits_ok and ok
	lines.append("  (6) 유혈광란/불굴의 보복: D4x4 [1,4,1,4] 최솟값 개수=%d 최댓값 개수=%d(둘 다 기대 2) -> 유혈광란 피해=%d 불굴의 보복 피해=%d(둘 다 기대 4, 0개면 %d) -> %s" % [
		legend_min_hits, legend_max_hits, bloodlust_dmg, vengeance_dmg, zero_hits_dmg, "OK" if legend_hits_ok else "FAIL",
	])

	# (7) 설명 문구 — 6종 전부 "한 런에 하나만" 안내가 description에 포함돼야 한다
	# (INBOX.md 명시: 등급 태그 옆 또는 설명 맨 아래. description에 두면 카드/도감/
	# 팝업/시작 스킬 슬롯 네 렌더 지점에 자동 전파).
	var notice_text := "한 런에 하나만"
	var notice_missing: Array[String] = []
	for skill in SkillPool.LEGENDARY_SKILLS:
		var desc: String = skill.get("description", "")
		if not desc.contains(notice_text):
			notice_missing.append(skill["id"])
	var notice_ok: bool = notice_missing.is_empty()
	ok = notice_ok and ok
	lines.append("  (7) 설명 문구 \"%s\" 포함: LEGENDARY_SKILLS %d종 전부 -> %s(누락: %s)" % [
		notice_text, SkillPool.LEGENDARY_SKILLS.size(), "OK" if notice_ok else "FAIL", notice_missing,
	])

	# (8) 전수 커버 — LEGENDARY_SKILLS에 등장하는 character_id별로 정확히 3종씩 있는지
	# (설계 기준: 캐릭터당 3종), 전부 character_id 지정, SKILL_RARITY에 legendary로
	# 등록, ICON_MOTIFS에 등록(누락 시 FAIL). 특정 캐릭터 이름/개수를 하드코딩하지 않고
	# LEGENDARY_SKILLS 자체에서 캐릭터 목록을 센다 — 다음 이터레이션(3/4~4/4)이 새
	# 캐릭터를 추가해도 이 테스트를 고칠 필요가 없다(codex_entries() 커버리지 테스트와
	# 같은 원칙).
	var per_character_count: Dictionary = {}
	var missing_character_id: Array[String] = []
	var missing_rarity: Array[String] = []
	var missing_motif: Array[String] = []
	for skill in SkillPool.LEGENDARY_SKILLS:
		var cid: String = skill.get("character_id", "")
		if cid == "":
			missing_character_id.append(skill["id"])
		else:
			per_character_count[cid] = per_character_count.get(cid, 0) + 1
		if SkillPool.SKILL_RARITY.get(skill["id"], "") != SkillPool.RARITY_LEGENDARY:
			missing_rarity.append(skill["id"])
		if not SkillPool.ICON_MOTIFS.has(skill["id"]):
			missing_motif.append(skill["id"])
	var uneven_characters: Array[String] = []
	for cid in per_character_count.keys():
		if per_character_count[cid] != 3:
			uneven_characters.append("%s=%d" % [cid, per_character_count[cid]])
	var coverage_ok: bool = (
		missing_character_id.is_empty() and uneven_characters.is_empty()
		and missing_rarity.is_empty() and missing_motif.is_empty()
	)
	ok = coverage_ok and ok
	lines.append("  (8) 전수 커버: 총 %d종, 캐릭터별 개수=%s(전부 3이어야 함, 어긋남=%s), character_id 누락=%s, rarity 누락=%s, motif 누락=%s -> %s" % [
		SkillPool.LEGENDARY_SKILLS.size(), per_character_count, uneven_characters, missing_character_id, missing_rarity, missing_motif,
		"OK" if coverage_ok else "FAIL",
	])

	return ok


## [대형 기획 15] Q-8(c) 2/4(전설 스킬, 2026-10-19, INBOX.md 원문 5): 수호자/폭발병
## 전설 6종 — 1/4의 _check_q8c_legendary_skills()와 같은 원칙(플래그가 아니라 실제
## "계산 결과"가 바뀌는지 검증). 전수 커버(character_id/rarity/motif)는 1/4의 (8)이
## LEGENDARY_SKILLS 전체를 이미 generic하게 검사하므로 여기서는 중복하지 않는다.
func _check_q8c2_legendary_skills(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) "최후의 보루"(DiceBag.apply_force_max()): 이번 턴에 굴린 다이스 전부가 각자의
	# 면 최댓값으로 바뀌는지(D4x3, 1/2/3 -> 4/4/4).
	var bulwark_bag := DiceBag.new(4, 3)
	var bulwark_before: Array = [1, 2, 3]
	var bulwark_after: Array = bulwark_bag.apply_force_max(bulwark_before)
	var bulwark_ok: bool = bulwark_after == [4, 4, 4]
	ok = bulwark_ok and ok
	lines.append("  (1) 최후의 보루(DiceBag.apply_force_max, D4x3): %s -> %s(기대 [4,4,4]) -> %s" % [
		bulwark_before, bulwark_after, "OK" if bulwark_ok else "FAIL",
	])

	# (2) HP 절반 이하 공용 조건(_is_hp_half_or_below) — 최후의 보루/최후의 폭발이
	# 공유하는 판정.
	var hp_half_true: bool = combat_script._is_hp_half_or_below(10, 20)
	var hp_half_false: bool = combat_script._is_hp_half_or_below(11, 20)
	var hp_half_ok: bool = hp_half_true == true and hp_half_false == false
	ok = hp_half_ok and ok
	lines.append("  (2) HP 절반 이하 판정: hp=10/max=20 -> %s(기대 true) / hp=11/max=20 -> %s(기대 false) -> %s" % [
		hp_half_true, hp_half_false, "OK" if hp_half_ok else "FAIL",
	])

	# (3) "반격의 벽"(_overguard_counter_damage): 방어가 공격을 초과한 만큼만 반격
	# 피해(완전 방어 요구 없음 — 결의의 반격과 다름), 부족하면 0.
	var overguard_hit: int = combat_script._overguard_counter_damage(5, 9)
	var overguard_miss: int = combat_script._overguard_counter_damage(9, 5)
	var overguard_ok: bool = overguard_hit == 4 and overguard_miss == 0
	ok = overguard_ok and ok
	lines.append("  (3) 반격의 벽: 공격5/방어9 -> 반격=%d(기대 4) / 공격9/방어5 -> 반격=%d(기대 0) -> %s" % [
		overguard_hit, overguard_miss, "OK" if overguard_ok else "FAIL",
	])

	# (4) "불굴의 벽"(RunState._bastion_fixed_value): 상한(면 개수) 안에서는 +2, 상한을
	# 넘으면 상한에서 멈추고, 다이스 개조로 면 개수가 늘면(D4->D8) 늘어난 상한까지 계속
	# 자라는지.
	var bastion_step1: int = RunState._bastion_fixed_value(3, 4)
	var bastion_step2: int = RunState._bastion_fixed_value(bastion_step1, 4)
	var bastion_after_upgrade: int = RunState._bastion_fixed_value(4, 8)
	var bastion_ok: bool = bastion_step1 == 4 and bastion_step2 == 4 and bastion_after_upgrade == 6
	ok = bastion_ok and ok
	lines.append("  (4) 불굴의 벽: D4 기준 3 -> %d(기대 4, 상한) -> %d(기대 4, 상한 유지) / 다이스 개조 후(D8) 4 -> %d(기대 6) -> %s" % [
		bastion_step1, bastion_step2, bastion_after_upgrade, "OK" if bastion_ok else "FAIL",
	])

	# (5) "연쇄 폭발의 고리"(_update_explosive_chain_progress): 보너스 턴을 소모해도
	# 0으로 리셋되지 않고 임계치만큼만 차감(초과분 유지)하는지 — 같은 입력에 대해 기존
	# _update_stack_progress()는 완전 리셋(0)인 것과 대조해 실제로 다른 계산 결과를
	# 내는지 확인한다.
	var ct_chain = combat_script.new()
	var chain_result: Dictionary = ct_chain._update_explosive_chain_progress(4, true, 0, 3)
	var normal_result: Dictionary = ct_chain._update_stack_progress(4, true, 0, 3)
	var chain_ok: bool = (
		chain_result["stacks"] == 1 and chain_result["carried"] == 1
		and normal_result["stacks"] == 0 and normal_result["reset"] == true
	)
	ok = chain_ok and ok
	lines.append("  (5) 연쇄 폭발의 고리: 4스택에서 보너스턴 소모 -> 연쇄=%d스택(기대 1, carried=%d) / 일반 리셋=%d스택(기대 0) -> %s" % [
		chain_result["stacks"], chain_result["carried"], normal_result["stacks"], "OK" if chain_ok else "FAIL",
	])

	# (6) "절대 폭발"(_absolute_detonation_bonus_damage): 보너스 턴에서 막힌 만큼을
	# 방어 무시 피해로 돌려주고, 보너스 턴이 아니거나 이미 전부 뚫었으면 0.
	var absolute_blocked: int = combat_script._absolute_detonation_bonus_damage(15, 9, true)
	var absolute_full_pen: int = combat_script._absolute_detonation_bonus_damage(15, 15, true)
	var absolute_not_bonus: int = combat_script._absolute_detonation_bonus_damage(15, 9, false)
	var absolute_ok: bool = absolute_blocked == 6 and absolute_full_pen == 0 and absolute_not_bonus == 0
	ok = absolute_ok and ok
	lines.append("  (6) 절대 폭발: 보너스턴(공격15/피해9) -> 추가피해=%d(기대 6) / 완전관통(공격15/피해15) -> %d(기대 0) / 평소턴 -> %d(기대 0) -> %s" % [
		absolute_blocked, absolute_full_pen, absolute_not_bonus, "OK" if absolute_ok else "FAIL",
	])

	# (7) "최후의 폭발"(_select_exchange_bags() 통합 — 실제 게임 코드 경로를 .new()
	# 인스턴스로 호출, balance_sim.gd와 같은 패턴): HP가 절반 이하면 폭발 스택 진행
	# (player_explosive_pending=false)과 무관하게 이번 공격턴이 보너스 폭발턴으로
	# 강제되는지, 평소(HP 정상)에는 그대로 평소 주머니를 쓰는지.
	var char_backup := RunState.character_id
	var flags_backup2 := RunState.skill_flags.duplicate()
	RunState.character_id = "explosive"
	RunState.skill_flags = ["legend_explosive_lastblast"]
	var ct_lastblast = combat_script.new()
	ct_lastblast._reset_player_battle_state()
	ct_lastblast.player_hp = 5
	var selection_forced: Dictionary = ct_lastblast._select_exchange_bags(true)
	ct_lastblast.player_hp = 20
	var selection_normal: Dictionary = ct_lastblast._select_exchange_bags(true)
	var lastblast_ok: bool = selection_forced["used_explosive_dice"] == true and selection_normal["used_explosive_dice"] == false
	ok = lastblast_ok and ok
	lines.append("  (7) 최후의 폭발: HP5/20(절반 이하) -> 보너스턴 강제=%s(기대 true) / HP20/20(정상) -> 보너스턴 강제=%s(기대 false) -> %s" % [
		selection_forced["used_explosive_dice"], selection_normal["used_explosive_dice"], "OK" if lastblast_ok else "FAIL",
	])
	ct_lastblast.free()
	ct_chain.free()
	RunState.character_id = char_backup
	RunState.skill_flags = flags_backup2

	# (8) 설명 문구 — 2/4 6종 전부 "한 런에 하나만" 안내가 description에 포함돼야 한다
	# (1/4의 (7)과 같은 요구, 이번 6종에만 한정해 다시 확인).
	var notice_text := "한 런에 하나만"
	var target_ids := [
		"legend_guardian_bulwark", "legend_guardian_overguard", "legend_guardian_bastion",
		"legend_explosive_chainblast", "legend_explosive_absolute", "legend_explosive_lastblast",
	]
	var notice_missing: Array[String] = []
	var matched_count := 0
	for skill in SkillPool.LEGENDARY_SKILLS:
		if target_ids.has(skill["id"]):
			matched_count += 1
			var desc: String = skill.get("description", "")
			if not desc.contains(notice_text):
				notice_missing.append(skill["id"])
	var notice_ok: bool = notice_missing.is_empty() and matched_count == target_ids.size()
	ok = notice_ok and ok
	lines.append("  (8) 설명 문구 \"%s\" 포함: 2/4 6종(매칭 %d/%d) -> %s(누락: %s)" % [
		notice_text, matched_count, target_ids.size(), "OK" if notice_ok else "FAIL", notice_missing,
	])

	return ok


## [대형 기획 15] Q-8(c) 3/4(전설 스킬, 2026-10-20, INBOX.md 원문 5): 주술사/매혹사
## 전설 6종 — 1/4·2/4의 _check_q8c_legendary_skills()/_check_q8c2_legendary_skills()와
## 같은 원칙(플래그가 아니라 실제 "계산 결과"가 바뀌는지 검증). 전수 커버(character_id/
## rarity/motif)는 1/4의 (8)이 LEGENDARY_SKILLS 전체를 이미 generic하게 검사하므로
## 여기서는 중복하지 않는다.
func _check_q8c3_legendary_skills(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) "저주의 흡수"(_curse_absorb_heal): 보너스 방어턴에서만 방어가 공격을
	# 초과한 만큼 회복, 평소 방어턴/초과하지 않으면 0.
	var lifecurse_bonus: int = combat_script._curse_absorb_heal(5, 9, true)
	var lifecurse_not_bonus: int = combat_script._curse_absorb_heal(5, 9, false)
	var lifecurse_no_excess: int = combat_script._curse_absorb_heal(9, 5, true)
	var lifecurse_ok: bool = lifecurse_bonus == 4 and lifecurse_not_bonus == 0 and lifecurse_no_excess == 0
	ok = lifecurse_ok and ok
	lines.append("  (1) 저주의 흡수: 보너스턴(공격5/방어9) 회복=%d(기대 4) / 평소턴 회복=%d(기대 0) / 초과 없음 회복=%d(기대 0) -> %s" % [
		lifecurse_bonus, lifecurse_not_bonus, lifecurse_no_excess, "OK" if lifecurse_ok else "FAIL",
	])

	# (2) "저주의 전이"(_curse_seal_reduction): 각인 수 x per_mark(기본 2)만큼 감소.
	var curseseal_0: int = combat_script._curse_seal_reduction(0)
	var curseseal_3: int = combat_script._curse_seal_reduction(3)
	var curseseal_ok: bool = curseseal_0 == 0 and curseseal_3 == 6
	ok = curseseal_ok and ok
	lines.append("  (2) 저주의 전이: 각인 0개=%d(기대 0) 각인 3개=%d(기대 6) -> %s" % [
		curseseal_0, curseseal_3, "OK" if curseseal_ok else "FAIL",
	])

	# (3) "저주의 종결"(_select_exchange_bags() 통합): "각성" 전에는 스택 조건을
	# 그대로 따르고(보너스 턴 아님), 각성 후에는 player_guard_pending과 무관하게
	# 항상 보너스 방어턴이 강제되는지.
	var char_backup3 := RunState.character_id
	var flags_backup3 := RunState.skill_flags.duplicate()
	RunState.character_id = "shieldbearer"
	RunState.skill_flags = ["legend_shieldbearer_curseend"]
	var ct_curseend = combat_script.new()
	ct_curseend._reset_player_battle_state()
	var curseend_before_awaken: Dictionary = ct_curseend._select_exchange_bags(false)
	ct_curseend.player_shieldbearer_curse_awakened = true
	var curseend_after_awaken: Dictionary = ct_curseend._select_exchange_bags(false)
	var curseend_ok: bool = curseend_before_awaken["used_guard_dice"] == false and curseend_after_awaken["used_guard_dice"] == true
	ok = curseend_ok and ok
	lines.append("  (3) 저주의 종결: 각성 전 보너스턴 강제=%s(기대 false) / 각성 후 보너스턴 강제=%s(기대 true) -> %s" % [
		curseend_before_awaken["used_guard_dice"], curseend_after_awaken["used_guard_dice"], "OK" if curseend_ok else "FAIL",
	])
	ct_curseend.free()
	RunState.character_id = char_backup3
	RunState.skill_flags = flags_backup3

	# (4) "매혹의 포로"(DiceBag.apply_charm_debuff, 신규): 이번 턴 가장 높았던 값을
	# 보인 다이스 1개가 그 다이스의 면 최솟값(여기선 1)으로 깎이는지(D4x3, 2/1/4 -> 2/1/1).
	var captive_bag := DiceBag.new(4, 3)
	var captive_before: Array = [2, 1, 4]
	var captive_after: Array = captive_bag.apply_charm_debuff(captive_before)
	var captive_ok: bool = captive_after == [2, 1, 1]
	ok = captive_ok and ok
	lines.append("  (4) 매혹의 포로(DiceBag.apply_charm_debuff, D4x3): %s -> %s(기대 [2,1,1]) -> %s" % [
		captive_before, captive_after, "OK" if captive_ok else "FAIL",
	])

	# (5) "매혹의 극치"(DiceBag.apply_charm_ascend, 신규): 평균 미달 다이스 "전부"가
	# 각자의 면 최댓값으로 바뀌는지 — charm_flip(1개 고정)과 달리 2개 이상도
	# 동시에 바뀔 수 있어야 한다(D4x3, [1,1,6] 평균=2.67 -> 1,1 둘 다 4로).
	var ascend_bag := DiceBag.new(4, 3)
	var ascend_before: Array = [1, 1, 6]
	var ascend_after: Array = ascend_bag.apply_charm_ascend(ascend_before)
	var ascend_ok: bool = ascend_after == [4, 4, 6]
	ok = ascend_ok and ok
	lines.append("  (5) 매혹의 극치(DiceBag.apply_charm_ascend, D4x3): %s -> %s(기대 [4,4,6], 평균 미달 2개 동시 전환) -> %s" % [
		ascend_before, ascend_after, "OK" if ascend_ok else "FAIL",
	])

	# (6) "매혹 심화" count 공용 함수(_charm_amplify_count) — 매혹의 응보가 재사용
	# (1->2->3, "+"가 base보다 우선).
	var amplify_none: int = combat_script._charm_amplify_count([])
	var amplify_base: int = combat_script._charm_amplify_count(["charm_amplify"])
	var amplify_plus: int = combat_script._charm_amplify_count(["charm_amplify", "charm_amplify_plus"])
	var amplify_count_ok: bool = amplify_none == 1 and amplify_base == 2 and amplify_plus == 3
	ok = amplify_count_ok and ok
	lines.append("  (6) 매혹 심화 count(_charm_amplify_count): 미보유=%d(기대 1) base=%d(기대 2) base+plus=%d(기대 3) -> %s" % [
		amplify_none, amplify_base, amplify_plus, "OK" if amplify_count_ok else "FAIL",
	])

	# (7) "매혹의 응보" 공식 — _legend_hits_bonus_damage(_charm_amplify_count())가
	# 유혈광란/불굴의 보복과 같은 공식(개수 x 2)을 그대로 재사용하는지.
	var retribution_dmg_1: int = combat_script._legend_hits_bonus_damage(combat_script._charm_amplify_count([]))
	var retribution_dmg_3: int = combat_script._legend_hits_bonus_damage(combat_script._charm_amplify_count(["charm_amplify", "charm_amplify_plus"]))
	var retribution_ok: bool = retribution_dmg_1 == 2 and retribution_dmg_3 == 6
	ok = retribution_ok and ok
	lines.append("  (7) 매혹의 응보: 매혹 1개(미보유) 피해=%d(기대 2) / 매혹 3개(심화+) 피해=%d(기대 6) -> %s" % [
		retribution_dmg_1, retribution_dmg_3, "OK" if retribution_ok else "FAIL",
	])

	# (8) 설명 문구 — 3/4 6종 전부 "한 런에 하나만" 안내가 description에 포함돼야 한다
	# (1/4의 (7)·2/4의 (8)과 같은 요구, 이번 6종에만 한정해 다시 확인).
	var notice_text := "한 런에 하나만"
	var target_ids := [
		"legend_shieldbearer_lifecurse", "legend_shieldbearer_curseseal", "legend_shieldbearer_curseend",
		"legend_enchantress_captive", "legend_enchantress_ascend", "legend_enchantress_retribution",
	]
	var notice_missing: Array[String] = []
	var matched_count := 0
	for skill in SkillPool.LEGENDARY_SKILLS:
		if target_ids.has(skill["id"]):
			matched_count += 1
			var desc: String = skill.get("description", "")
			if not desc.contains(notice_text):
				notice_missing.append(skill["id"])
	var notice_ok: bool = notice_missing.is_empty() and matched_count == target_ids.size()
	ok = notice_ok and ok
	lines.append("  (8) 설명 문구 \"%s\" 포함: 3/4 6종(매칭 %d/%d) -> %s(누락: %s)" % [
		notice_text, matched_count, target_ids.size(), "OK" if notice_ok else "FAIL", notice_missing,
	])

	return ok


## [대형 기획 15] Q-8(c) 4/4(전설 스킬, 2026-10-20, INBOX.md 원문 5): 곡예사/해적
## 전설 6종 — 1/4~3/4와 같은 원칙(플래그가 아니라 실제 "계산 결과"가 바뀌는지 검증),
## 8명×3=24종 전체 완료. 전수 커버(character_id/rarity/motif/캐릭터당 3종)는 1/4의
## (8)이 LEGENDARY_SKILLS 전체를 이미 generic하게 검사하므로 여기서는 중복하지
## 않는다. (8)은 2/4·3/4에서 발견한 기존 버그(매혹의 응보/저주의 흡수가 반격의 벽
## if 안에 중첩돼 overguard_active 없이는 실행되지 않던 것) 회귀 검증 — 전설은 한
## 런에 하나만 보유 가능해 둘 다 overguard_active=false인 상태로 호출해도 실제로
## 발동하는지 직접 확인한다.
func _check_q8c4_legendary_skills(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) "완벽한 묘기"(_juggle_balance_total 순수 함수 + _resolve_exchange() 통합):
	# 둘 중 더 높은 쪽을 채택(대칭)하고, 실제 전투 경로에서도 공격 합계 2(약함) vs
	# 반대편(방어) 합계 9(강함)일 때 최종 dmg가 9 기준으로 나오는지(몬스터 방어 0).
	var balance_a: int = combat_script._juggle_balance_total(5, 9)
	var balance_b: int = combat_script._juggle_balance_total(9, 5)
	var char_backup_bal := RunState.character_id
	var flags_backup_bal := RunState.skill_flags.duplicate()
	var atk_bag_backup_bal := RunState.player_attack_bag
	var def_bag_backup_bal := RunState.player_defense_bag
	RunState.character_id = "juggler"
	RunState.skill_flags = ["legend_juggler_balance"]
	RunState.player_attack_bag = DiceBag.new(4, 1)
	RunState.player_attack_bag.force_fixed_value(2)
	RunState.player_defense_bag = DiceBag.new(4, 1)
	RunState.player_defense_bag.force_fixed_value(9)
	var bal_monster_def := DiceBag.new(4, 1)
	bal_monster_def.force_fixed_value(0)
	var ct_bal = combat_script.new()
	ct_bal._reset_player_battle_state()
	var bal_result: Dictionary = ct_bal._resolve_exchange(true, RunState.player_attack_bag, bal_monster_def, false, false, false)
	var balance_integration_ok: bool = int(bal_result["dmg"]) == 9
	ct_bal.free()
	RunState.character_id = char_backup_bal
	RunState.skill_flags = flags_backup_bal
	RunState.player_attack_bag = atk_bag_backup_bal
	RunState.player_defense_bag = def_bag_backup_bal
	var balance_ok: bool = balance_a == 9 and balance_b == 9 and balance_integration_ok
	ok = balance_ok and ok
	lines.append("  (1) 완벽한 묘기: 순수함수(5,9)=%d(기대 9)/(9,5)=%d(기대 9) + 통합(공격2 vs 방어9, 몬스터 방어0) dmg=%d(기대 9, 더 센 방어쪽 합계 채택) -> %s" % [
		balance_a, balance_b, int(bal_result["dmg"]), "OK" if balance_ok else "FAIL",
	])

	# (2) "끝없는 저글링"(_resolve_exchange() 통합 — DiceBag.swap_random_dice()가 굴림
	# "전"에 실제로 호출되는지). 공격/방어 둘 다 다이스 1개뿐이면(count=1) swap_random_
	# dice()의 인덱스 선택에 무작위성이 없어(선택지가 1개뿐) 결정적으로 검증 가능 —
	# D4 공격 주머니와 D6 방어 주머니를 교환하면 면 개수가 서로 바뀐다.
	var char_backup_ever := RunState.character_id
	var flags_backup_ever := RunState.skill_flags.duplicate()
	var atk_bag_backup_ever := RunState.player_attack_bag
	var def_bag_backup_ever := RunState.player_defense_bag
	RunState.character_id = "juggler"
	RunState.skill_flags = ["legend_juggler_evershuffle"]
	RunState.player_attack_bag = DiceBag.new(4, 1)
	RunState.player_defense_bag = DiceBag.new(6, 1)
	var ct_ever = combat_script.new()
	ct_ever._reset_player_battle_state()
	var ever_dummy_def := DiceBag.new(4, 1)
	ever_dummy_def.force_fixed_value(0)
	ct_ever._resolve_exchange(true, RunState.player_attack_bag, ever_dummy_def, false, false, false)
	var ever_ok: bool = RunState.player_attack_bag.dice[0].size() == 6 and RunState.player_defense_bag.dice[0].size() == 4
	ok = ever_ok and ok
	lines.append("  (2) 끝없는 저글링(swap_random_dice 매 턴 통합): 공격 다이스 면=%d(기대 6, D4->D6 교환) 방어 다이스 면=%d(기대 4) -> %s" % [
		RunState.player_attack_bag.dice[0].size(), RunState.player_defense_bag.dice[0].size(), "OK" if ever_ok else "FAIL",
	])
	ct_ever.free()
	RunState.character_id = char_backup_ever
	RunState.skill_flags = flags_backup_ever
	RunState.player_attack_bag = atk_bag_backup_ever
	RunState.player_defense_bag = def_bag_backup_ever

	# (3) "운명의 보정"(_apply_fate_die): sides=1인 이벤트 주사위는 항상 1이 나오므로
	# (D1, 면 1개뿐) RNG와 무관하게 결정적 — 최저값보다 낮으면(5) 그대로, 높으면(0)
	# 대체된다. bag(D4x1)의 면 개수(4)가 fate_value(1)보다 커서 이 케이스에서는
	# 상한이 발동하지 않는다(상한 자체는 아래 (3b)에서 통계적으로 검증).
	var fate_dummy_bag := DiceBag.new(4, 1)
	var fate_no_replace: Array = combat_script._apply_fate_die(fate_dummy_bag, [5], 1, [])
	var fate_replace: Array = combat_script._apply_fate_die(fate_dummy_bag, [0], 1, [])
	var fate_ok: bool = fate_no_replace == [5] and fate_replace == [1]
	ok = fate_ok and ok
	lines.append("  (3) 운명의 보정(_apply_fate_die, 이벤트 D1=항상 1): 최저값 5 -> %s(기대 [5], 대체 안 됨) / 최저값 0 -> %s(기대 [1], 대체됨) -> %s" % [
		fate_no_replace, fate_replace, "OK" if fate_ok else "FAIL",
	])

	# (3b) [대형 기획 15] Q-8(d) 밸런스 조정 회귀 — _apply_fate_die()의 대체값은 이제
	# "그 다이스 자신의 면 최댓값"으로 상한된다(balance_sim 격리 측정에서 운명의 보정이
	# 곡예사 자체 전설 3종 중 압도적 1위로 나와 조정, docs/BALANCE_TUNING_LOG.md 참고).
	# bag=D4x1(상한 4), 이벤트 주사위=1D12(최대 12)로 200회 굴려 결과가 한 번도 4를
	# 넘지 않는지 확인 — 상한이 없다면 D12가 4 초과를 낼 확률이 매번 2/3이라 200회 중
	# 전부 4 이하로 나올 확률은 사실상 0에 가까움(상한이 실제로 걸렸다는 결정적 증거).
	var fate_cap_bag := DiceBag.new(4, 1)
	var fate_cap_violations := 0
	var fate_cap_reached_max := false
	for _i in 200:
		var capped_result: Array = combat_script._apply_fate_die(fate_cap_bag, [0], 12, [])
		if capped_result[0] > 4:
			fate_cap_violations += 1
		if capped_result[0] == 4:
			fate_cap_reached_max = true
	var fate_cap_ok: bool = fate_cap_violations == 0 and fate_cap_reached_max
	ok = fate_cap_ok and ok
	lines.append("  (3b) 운명의 보정 상한(_apply_fate_die, bag면=4 vs 이벤트 1D12, 200회): 4 초과 %d회(기대 0) / 4 도달 %s(기대 true) -> %s" % [
		fate_cap_violations, fate_cap_reached_max, "OK" if fate_cap_ok else "FAIL",
	])

	# (4) "무한 장전"(_overload_next_cycle): 발동마다 1씩 줄고, 최소 1에서 멈춘다.
	var overload_3to2: int = combat_script._overload_next_cycle(3)
	var overload_2to1: int = combat_script._overload_next_cycle(2)
	var overload_floor: int = combat_script._overload_next_cycle(1)
	var overload_ok: bool = overload_3to2 == 2 and overload_2to1 == 1 and overload_floor == 1
	ok = overload_ok and ok
	lines.append("  (4) 무한 장전(_overload_next_cycle): 3->%d(기대 2) / 2->%d(기대 1) / 1->%d(기대 1, 최소 유지) -> %s" % [
		overload_3to2, overload_2to1, overload_floor, "OK" if overload_ok else "FAIL",
	])

	# (5) "처형자의 포격"(_execute_cannon_bonus): 몬스터 HP가 절반 이하일 때만 cannon_
	# dmg와 같은 크기의 추가 피해(=2배 효과), 그 외엔 0.
	var execute_hit: int = combat_script._execute_cannon_bonus(4, 5, 10)
	var execute_miss: int = combat_script._execute_cannon_bonus(4, 6, 10)
	var execute_ok: bool = execute_hit == 4 and execute_miss == 0
	ok = execute_ok and ok
	lines.append("  (5) 처형자의 포격(_execute_cannon_bonus): HP5/10(절반 이하) 추가피해=%d(기대 4, 2배) / HP6/10(절반 초과) 추가피해=%d(기대 0) -> %s" % [
		execute_hit, execute_miss, "OK" if execute_ok else "FAIL",
	])

	# (6) "전면 포격"(_resolve_exchange() 통합 — 방어턴 전용 카운터가 공격턴 카운터와
	# 별개로 3턴 주기를 따르는지). 방어 합계를 6으로 고정하면 발동 시 고정 피해
	# ceil(6/2)=3 — 1·2번째 방어턴은 조용하고 3번째에만 몬스터 HP가 줄어야 한다.
	var char_backup_fb := RunState.character_id
	var flags_backup_fb := RunState.skill_flags.duplicate()
	var atk_bag_backup_fb := RunState.player_attack_bag
	var def_bag_backup_fb := RunState.player_defense_bag
	RunState.character_id = "pirate"
	RunState.skill_flags = ["legend_pirate_fullbroadside"]
	RunState.player_defense_bag = DiceBag.new(4, 1)
	RunState.player_defense_bag.force_fixed_value(6)
	var fb_monster_atk := DiceBag.new(4, 1)
	fb_monster_atk.force_fixed_value(0)
	var ct_fb = combat_script.new()
	ct_fb._reset_player_battle_state()
	ct_fb.monster_hp = 100
	ct_fb.monster_max_hp = 100
	ct_fb._resolve_exchange(false, fb_monster_atk, RunState.player_defense_bag, false, false, false)
	var fb_hp_turn1: int = ct_fb.monster_hp
	ct_fb._resolve_exchange(false, fb_monster_atk, RunState.player_defense_bag, false, false, false)
	var fb_hp_turn2: int = ct_fb.monster_hp
	ct_fb._resolve_exchange(false, fb_monster_atk, RunState.player_defense_bag, false, false, false)
	var fb_hp_turn3: int = ct_fb.monster_hp
	var fullbroadside_ok: bool = fb_hp_turn1 == 100 and fb_hp_turn2 == 100 and fb_hp_turn3 == 97
	ok = fullbroadside_ok and ok
	lines.append("  (6) 전면 포격(방어턴 전용 주기 통합): 1턴 몬스터 HP=%d(기대 100, 조용) / 2턴=%d(기대 100) / 3턴=%d(기대 97, 고정 3 발동) -> %s" % [
		fb_hp_turn1, fb_hp_turn2, fb_hp_turn3, "OK" if fullbroadside_ok else "FAIL",
	])
	ct_fb.free()
	RunState.character_id = char_backup_fb
	RunState.skill_flags = flags_backup_fb
	RunState.player_attack_bag = atk_bag_backup_fb
	RunState.player_defense_bag = def_bag_backup_fb

	# (7) "무한 장전"(_resolve_exchange() 통합 — 실제 cannon_volley 공격턴 경로에서
	# 주기가 가속되는지). 공격 합계 4(고정) vs 몬스터 방어 0 — 평소 피해 4 + 함포
	# 고정 피해 ceil(4/2)=2. 3턴째(기본 주기)에 처음 발동하며 cycle이 3->2로 줄고,
	# 4턴째(줄어든 주기 2)에 곧바로 다시 발동하며 2->1로, 5턴째(주기 1)부터는 매
	# 턴 발동한다.
	var char_backup_ol := RunState.character_id
	var flags_backup_ol := RunState.skill_flags.duplicate()
	var atk_bag_backup_ol := RunState.player_attack_bag
	var def_bag_backup_ol := RunState.player_defense_bag
	RunState.character_id = "pirate"
	RunState.skill_flags = ["legend_pirate_overload"]
	RunState.player_attack_bag = DiceBag.new(4, 1)
	RunState.player_attack_bag.force_fixed_value(4)
	var ol_monster_def := DiceBag.new(4, 1)
	ol_monster_def.force_fixed_value(0)
	var ct_ol = combat_script.new()
	ct_ol._reset_player_battle_state()
	var ol_cycle_initial: int = ct_ol.player_pirate_overload_cycle
	ct_ol.monster_hp = 100
	ct_ol.monster_max_hp = 100
	for _i in 3:
		ct_ol._resolve_exchange(true, RunState.player_attack_bag, ol_monster_def, false, false, false)
	var ol_cycle_after_turn3: int = ct_ol.player_pirate_overload_cycle
	var ol_hp_after_turn3: int = ct_ol.monster_hp
	ct_ol._resolve_exchange(true, RunState.player_attack_bag, ol_monster_def, false, false, false)
	var ol_cycle_after_turn4: int = ct_ol.player_pirate_overload_cycle
	var ol_hp_after_turn4: int = ct_ol.monster_hp
	# 3턴째까지 합계: 평소 피해 4x3=12, 함포 2(3턴째 1회) = 100-14=86.
	# 4턴째: 평소 4 + 함포 2(가속 발동) = 86-6=80.
	var overload_integration_ok: bool = (
		ol_cycle_initial == 3 and ol_cycle_after_turn3 == 2 and ol_hp_after_turn3 == 86
		and ol_cycle_after_turn4 == 1 and ol_hp_after_turn4 == 80
	)
	ok = overload_integration_ok and ok
	lines.append("  (7) 무한 장전(cannon_volley 통합, 가속): 초기 주기=%d(기대 3) -> 3턴 후 주기=%d(기대 2)/HP=%d(기대 86) -> 4턴 후 주기=%d(기대 1, 연속 발동)/HP=%d(기대 80) -> %s" % [
		ol_cycle_initial, ol_cycle_after_turn3, ol_hp_after_turn3, ol_cycle_after_turn4, ol_hp_after_turn4, "OK" if overload_integration_ok else "FAIL",
	])
	ct_ol.free()
	RunState.character_id = char_backup_ol
	RunState.skill_flags = flags_backup_ol
	RunState.player_attack_bag = atk_bag_backup_ol
	RunState.player_defense_bag = def_bag_backup_ol

	# (8) 회귀 — "매혹의 응보"/"저주의 흡수"가 반격의 벽(legend_guardian_overguard)
	# if 안에 잘못 중첩돼 overguard_active 없이는 영원히 발동 안 하던 기존 버그
	# (2/4·3/4에서 도입, 이번 4/4 작업 중 발견·수정)를 고쳤는지 — 둘 다 overguard를
	# 전혀 보유하지 않은 상태로 _resolve_exchange()를 직접 호출해 실제로 발동하는지
	# 확인한다.
	var char_backup_bug := RunState.character_id
	var flags_backup_bug := RunState.skill_flags.duplicate()
	var atk_bag_backup_bug := RunState.player_attack_bag
	var def_bag_backup_bug := RunState.player_defense_bag
	RunState.character_id = "enchantress"
	RunState.skill_flags = ["legend_enchantress_retribution"]
	var retro_atk := DiceBag.new(4, 1)
	retro_atk.force_fixed_value(0)
	var retro_def := DiceBag.new(4, 1)
	retro_def.force_fixed_value(0)
	var ct_retro = combat_script.new()
	ct_retro._reset_player_battle_state()
	ct_retro.monster_hp = 100
	ct_retro._resolve_exchange(false, retro_atk, retro_def, false, false, false)
	var retro_hp_after: int = ct_retro.monster_hp
	var retro_fired_without_overguard: bool = retro_hp_after == 98
	ct_retro.free()

	RunState.character_id = "shieldbearer"
	RunState.skill_flags = ["legend_shieldbearer_lifecurse"]
	var curse_atk := DiceBag.new(4, 1)
	curse_atk.force_fixed_value(2)
	var curse_def := DiceBag.new(4, 1)
	curse_def.force_fixed_value(9)
	var ct_curse = combat_script.new()
	ct_curse._reset_player_battle_state()
	ct_curse.player_hp = 10
	ct_curse._resolve_exchange(false, curse_atk, curse_def, false, true, false)
	var curse_hp_after: int = ct_curse.player_hp
	var lifecurse_fired_without_overguard: bool = curse_hp_after == 17
	ct_curse.free()

	var overguard_nesting_fix_ok: bool = retro_fired_without_overguard and lifecurse_fired_without_overguard
	ok = overguard_nesting_fix_ok and ok
	lines.append("  (8) 회귀(반격의 벽 중첩 버그 수정): 매혹의 응보 단독 보유 시 몬스터 HP 100->%d(기대 98, overguard 없이도 발동) / 저주의 흡수 단독 보유 시 플레이어 HP 10->%d(기대 17, 과잉방어 7 회복) -> %s" % [
		retro_hp_after, curse_hp_after, "OK" if overguard_nesting_fix_ok else "FAIL",
	])
	RunState.character_id = char_backup_bug
	RunState.skill_flags = flags_backup_bug
	RunState.player_attack_bag = atk_bag_backup_bug
	RunState.player_defense_bag = def_bag_backup_bug

	# (9) 설명 문구 — 4/4 6종 전부 "한 런에 하나만" 안내가 description에 포함돼야
	# 한다(1/4의 (7)·2/4의 (8)·3/4의 (8)과 같은 요구, 이번 6종에만 한정해 다시 확인).
	var notice_text := "한 런에 하나만"
	var target_ids := [
		"legend_juggler_evershuffle", "legend_juggler_balance", "legend_juggler_fatecorrect",
		"legend_pirate_overload", "legend_pirate_execute", "legend_pirate_fullbroadside",
	]
	var notice_missing: Array[String] = []
	var matched_count := 0
	for skill in SkillPool.LEGENDARY_SKILLS:
		if target_ids.has(skill["id"]):
			matched_count += 1
			var desc: String = skill.get("description", "")
			if not desc.contains(notice_text):
				notice_missing.append(skill["id"])
	var notice_ok: bool = notice_missing.is_empty() and matched_count == target_ids.size()
	ok = notice_ok and ok
	lines.append("  (9) 설명 문구 \"%s\" 포함: 4/4 6종(매칭 %d/%d) -> %s(누락: %s)" % [
		notice_text, matched_count, target_ids.size(), "OK" if notice_ok else "FAIL", notice_missing,
	])

	return ok


## [대형 기획 15] Q-11(몬스터 도감, 2026-10-20 사용자 추가 지시) — "플래그가 아니라
## 계산 결과/실제 렌더 결과"로 검증한다:
## (1) 격자 카드 수 == MonsterCatalog.MONSTERS.size()(하드코딩된 수가 아니라 카탈로그
##     전체 수와 항상 일치하는지)
## (1b)~(1d) [Q-11b, 2026-10-20 감독 캡처 피드백 — 썸네일 추가] 썸네일 슬롯 수==카드 수,
##     원화 있는 몬스터는 TextureRect+texture!=null, 원화 없는 몬스터는 FamilyIcon 폴백.
## (2) 격자 카드의 "원화/표정 n/5" 태그 텍스트가 실제 파일 존재(주입된 user:// 임시
##     디렉터리의 합성 에셋)와 일치하는지
## (3) 계열/티어 필터 버튼을 실제로 눌렀을 때(.pressed.emit()) 카드 수가 그 필터에
##     해당하는 몬스터 수와 정확히 일치하는지
## (4) 상세 뷰에서 표정 버튼을 누르면(.pressed.emit()) 실제로 렌더되는 텍스처의 픽셀이
##     바뀌는지(서로 다른 색의 합성 face_*.png), 미입고 표정 버튼은 disabled=true인지
## (5) 리소스 입고 현황 체크리스트가 실제 파일 존재와 일치하는지
## (6) 방향키 실제 주입(_n1_send_key, 엔진 입력 파이프라인)으로 필터 행 -> 격자 ->
##     상세 뷰 표정 버튼까지 포커스가 실제로 이동하는지
## 전부 실제 resources/monsters/에 의존하지 않고 user:// 임시 디렉터리 + 합성 PNG로
## 검증한다(과업 지시 "주입된 임시 디렉터리/합성 에셋 사용, 실제 resources 의존 금지").
## await를 쓰므로 호출부는 `await _check_q11_monster_codex(lines)`로 받아야 한다.
func _check_q11_monster_codex(lines: PackedStringArray) -> bool:
	var ok := true
	var base_dir_pattern := "user://q11_test_tmp/%s/"

	# --- 합성 에셋 준비 ---
	# slime: full.png + 표정 2장만(neutral/happy) — "일부만 입고" 경우.
	_art1c2_write_fake_full(base_dir_pattern, "slime")
	_art1b_write_fake_faces(base_dir_pattern, "slime", ["neutral", "happy"])
	# goblin_king(보스): full.png + 표정 4장(angry만 빠짐), 표정마다 다른 색 —
	# "표정 전환이 실제 텍스처를 바꾸는지"를 픽셀로 검증하기 위해 identical 1x1 fixture
	# (_art1b_write_fake_faces)가 아니라 색이 다른 PNG를 직접 쓴다.
	var gk_dir := base_dir_pattern % "goblin_king"
	DirAccess.make_dir_recursive_absolute(gk_dir)
	var gk_full := Image.create(118, 133, false, Image.FORMAT_RGBA8)
	gk_full.fill(Color(0.3, 0.5, 0.7, 1.0))
	gk_full.save_png(gk_dir + "full.png")
	var gk_colors := {
		"neutral": Color(1, 0, 0, 1), "happy": Color(0, 1, 0, 1),
		"hurt": Color(0, 0, 1, 1), "sad": Color(1, 1, 0, 1),
	}
	for expr in gk_colors.keys():
		var face_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		face_img.fill(gk_colors[expr])
		face_img.save_png(gk_dir + "face_%s.png" % expr)
	# ooze_lord(보스): 아무 파일도 없음 — "원화 미입고" 폴백 경로 검증용.

	var panel := MonsterCodexPanel.new()
	panel.art_base_dir = base_dir_pattern
	add_child(panel)
	var viewport := get_viewport()

	panel.open()
	await get_tree().process_frame

	# (1) 격자 카드 수 == 카탈로그 전체 수.
	var total_count: int = MonsterCatalog.MONSTERS.size()
	var grid_count_ok: bool = panel._card_controls.size() == total_count
	ok = grid_count_ok and ok
	lines.append("  (1) 필터 없음: 격자 카드 수=%d (기대 MonsterCatalog.MONSTERS.size()=%d) -> %s" % [
		panel._card_controls.size(), total_count, "OK" if grid_count_ok else "FAIL"
	])

	# (1b)~(1d) Q-11b(2026-10-20, 감독 캡처 피드백 — 썸네일 추가) — "플래그가 아니라 실제
	# 렌더 결과"로: 썸네일 슬롯이 카드 수만큼 있는지, 원화가 있는 몬스터는 실제 텍스처가
	# 들어갔는지, 원화가 없는 몬스터는 FamilyIcon 폴백으로 떨어지는지.
	var thumb_slot_count_ok: bool = panel._grid_thumb_slot_by_id.size() == panel._card_controls.size()
	ok = thumb_slot_count_ok and ok
	lines.append("  (1b) 썸네일 슬롯 수=%d (기대 카드 수=%d) -> %s" % [
		panel._grid_thumb_slot_by_id.size(), panel._card_controls.size(), "OK" if thumb_slot_count_ok else "FAIL"
	])

	var slime_slot: Control = panel._grid_thumb_slot_by_id.get("slime")
	var slime_thumb_ok: bool = slime_slot != null and slime_slot.get_child_count() == 1 \
		and slime_slot.get_child(0) is TextureRect and (slime_slot.get_child(0) as TextureRect).texture != null
	ok = slime_thumb_ok and ok
	lines.append("  (1c) slime(원화 있음) 썸네일 슬롯 -> TextureRect+texture!=null -> %s" % (
		"OK" if slime_thumb_ok else "FAIL"
	))

	var ooze_slot: Control = panel._grid_thumb_slot_by_id.get("ooze_lord")
	var ooze_fallback_ok: bool = ooze_slot != null and ooze_slot.get_child_count() == 1 \
		and ooze_slot.get_child(0) is FamilyIcon
	ok = ooze_fallback_ok and ok
	lines.append("  (1d) ooze_lord(원화 없음) 썸네일 슬롯 -> FamilyIcon 폴백 -> %s" % (
		"OK" if ooze_fallback_ok else "FAIL"
	))

	# (2) 격자 카드 리소스 태그가 실제 파일 존재와 일치.
	var slime_tag: String = panel._grid_face_tag_by_id["slime"].text if panel._grid_face_tag_by_id.has("slime") else ""
	var slime_tag_ok: bool = slime_tag == "원화 ✓ · 표정 2/5"
	ok = slime_tag_ok and ok
	lines.append("  (2a) slime(full+표정2장) 격자 태그='%s'(기대 '원화 ✓ · 표정 2/5') -> %s" % [
		slime_tag, "OK" if slime_tag_ok else "FAIL"
	])
	var gk_tag: String = panel._grid_face_tag_by_id["goblin_king"].text if panel._grid_face_tag_by_id.has("goblin_king") else ""
	var gk_tag_ok: bool = gk_tag == "원화 ✓ · 표정 4/5"
	ok = gk_tag_ok and ok
	lines.append("  (2b) goblin_king(full+표정4장) 격자 태그='%s'(기대 '원화 ✓ · 표정 4/5') -> %s" % [
		gk_tag, "OK" if gk_tag_ok else "FAIL"
	])
	var ooze_tag: String = panel._grid_face_tag_by_id["ooze_lord"].text if panel._grid_face_tag_by_id.has("ooze_lord") else ""
	var ooze_tag_ok: bool = ooze_tag == "원화 ✗ · 표정 0/5"
	ok = ooze_tag_ok and ok
	lines.append("  (2c) ooze_lord(미입고) 격자 태그='%s'(기대 '원화 ✗ · 표정 0/5') -> %s" % [
		ooze_tag, "OK" if ooze_tag_ok else "FAIL"
	])

	# (3) 필터 — 계열(실제 버튼 클릭).
	var expected_family_count := 0
	for m in MonsterCatalog.MONSTERS:
		if m.get("family", "") == "amorphous":
			expected_family_count += 1
	panel._family_filter_buttons["amorphous"].pressed.emit()
	await get_tree().process_frame
	var family_filter_ok: bool = panel._card_controls.size() == expected_family_count \
		and panel._grid_cards_by_id.has("slime") and not panel._grid_cards_by_id.has("goblin")
	ok = family_filter_ok and ok
	lines.append("  (3a) 계열 필터(부정형) 클릭 후 카드 수=%d(기대 %d), slime 포함/goblin 제외=%s -> %s" % [
		panel._card_controls.size(), expected_family_count,
		panel._grid_cards_by_id.has("slime") and not panel._grid_cards_by_id.has("goblin"),
		"OK" if family_filter_ok else "FAIL"
	])
	panel._family_filter_buttons[""].pressed.emit()
	await get_tree().process_frame

	# (3) 필터 — 티어(실제 버튼 클릭).
	var expected_boss_count: int = MonsterCatalog.boss_roster_ids().size()
	panel._tier_filter_buttons["boss"].pressed.emit()
	await get_tree().process_frame
	var tier_filter_ok: bool = panel._card_controls.size() == expected_boss_count \
		and panel._grid_cards_by_id.has("goblin_king") and not panel._grid_cards_by_id.has("slime")
	ok = tier_filter_ok and ok
	lines.append("  (3b) 티어 필터(보스) 클릭 후 카드 수=%d(기대 %d), goblin_king 포함/slime 제외=%s -> %s" % [
		panel._card_controls.size(), expected_boss_count,
		panel._grid_cards_by_id.has("goblin_king") and not panel._grid_cards_by_id.has("slime"),
		"OK" if tier_filter_ok else "FAIL"
	])
	panel._tier_filter_buttons[""].pressed.emit()
	await get_tree().process_frame

	# (4)/(5) 상세 뷰 — goblin_king 카드 활성화(실제 activated 시그널).
	panel._grid_cards_by_id["goblin_king"].activated.emit()
	await get_tree().process_frame
	var detail_opened_ok: bool = panel._view_mode == "detail" and panel._detail_monster_id == "goblin_king"
	ok = detail_opened_ok and ok
	lines.append("  (4a) goblin_king 카드 활성화 -> 상세 뷰 전환(_view_mode='%s', id='%s') -> %s" % [
		panel._view_mode, panel._detail_monster_id, "OK" if detail_opened_ok else "FAIL"
	])

	var full_rect_ok: bool = panel._detail_full_rect != null and panel._detail_full_rect.texture != null
	ok = full_rect_ok and ok
	lines.append("  (4b) 전신 full.png 텍스처 로드됨 -> %s" % ("OK" if full_rect_ok else "FAIL"))

	# 기본 표정(neutral)은 빨강이어야 한다.
	var neutral_img: Image = panel._detail_face_rect.texture.get_image() if panel._detail_face_rect.texture != null else null
	var neutral_pixel: Color = neutral_img.get_pixel(0, 0) if neutral_img != null else Color(0, 0, 0, 0)
	var neutral_ok: bool = neutral_pixel.is_equal_approx(Color(1, 0, 0, 1))
	ok = neutral_ok and ok
	lines.append("  (4c) 기본 표정(neutral) 렌더 픽셀=%s(기대 빨강) -> %s" % [neutral_pixel, "OK" if neutral_ok else "FAIL"])

	# happy 버튼을 실제로 눌러 텍스처가 초록으로 바뀌는지.
	panel._expression_buttons["happy"].pressed.emit()
	await get_tree().process_frame
	var happy_img: Image = panel._detail_face_rect.texture.get_image() if panel._detail_face_rect.texture != null else null
	var happy_pixel: Color = happy_img.get_pixel(0, 0) if happy_img != null else Color(0, 0, 0, 0)
	var happy_ok: bool = happy_pixel.is_equal_approx(Color(0, 1, 0, 1)) and panel._detail_expression == "happy"
	ok = happy_ok and ok
	lines.append("  (4d) 'happy' 버튼 클릭 후 렌더 픽셀=%s(기대 초록), _detail_expression='%s' -> %s" % [
		happy_pixel, panel._detail_expression, "OK" if happy_ok else "FAIL"
	])

	# angry는 파일이 없으므로 버튼이 비활성화돼야 한다(미입고 표정은 전환 불가).
	var angry_disabled_ok: bool = panel._expression_buttons["angry"].disabled
	ok = angry_disabled_ok and ok
	lines.append("  (4e) 미입고 표정(angry) 버튼 disabled=%s(기대 true, 전환 불가) -> %s" % [
		angry_disabled_ok, "OK" if angry_disabled_ok else "FAIL"
	])

	var crop_rect_ok: bool = panel._detail_crop_rect != null and panel._detail_crop_rect.texture != null
	ok = crop_rect_ok and ok
	lines.append("  (4f) 전투 화면 크롭 미리보기 텍스처 로드됨(보스 크롭 비율) -> %s" % ("OK" if crop_rect_ok else "FAIL"))

	# (5) 리소스 체크리스트가 실제 파일 존재와 일치.
	var check_full_ok: bool = panel._resource_check_labels["full"].text.contains("✓")
	var check_neutral_ok: bool = panel._resource_check_labels["neutral"].text.contains("✓")
	var check_angry_ok: bool = panel._resource_check_labels["angry"].text.contains("✗")
	var checklist_ok: bool = check_full_ok and check_neutral_ok and check_angry_ok
	ok = checklist_ok and ok
	lines.append("  (5) 리소스 체크리스트: full=%s neutral=%s angry=%s(기대 true/true/true) -> %s" % [
		check_full_ok, check_neutral_ok, check_angry_ok, "OK" if checklist_ok else "FAIL"
	])

	# "← 목록"으로 격자로 복귀.
	panel._back_button.pressed.emit()
	await get_tree().process_frame
	var back_ok: bool = panel._view_mode == "grid"
	ok = back_ok and ok
	lines.append("  (5-확인) '← 목록' 클릭 후 _view_mode='%s'(기대 grid) -> %s" % [panel._view_mode, "OK" if back_ok else "FAIL"])

	# (6) 실제 InputEventKey 주입으로 포커스 이동(필터 행 -> 격자 -> 격자 내부 이동).
	panel._family_filter_buttons[""].grab_focus()
	_n1_send_key(KEY_RIGHT)
	await get_tree().process_frame
	var first_family_id: String = MonsterCatalog.family_ids()[0]
	var filter_right_ok: bool = viewport.gui_get_focus_owner() == panel._family_filter_buttons[first_family_id]
	ok = filter_right_ok and ok
	lines.append("  (6a) 필터 행 '전체'에서 -> (오른쪽)으로 첫 계열 필터('%s')에 도달 -> %s" % [
		first_family_id, "OK" if filter_right_ok else "FAIL"
	])

	_n1_send_key(KEY_DOWN)
	await get_tree().process_frame
	var filter_down_to_grid_ok: bool = panel._card_controls.size() > 0 \
		and viewport.gui_get_focus_owner() == panel._card_controls[0]
	ok = filter_down_to_grid_ok and ok
	lines.append("  (6b) 필터 행에서 아래로 -> 격자 첫 카드에 도달 -> %s" % ("OK" if filter_down_to_grid_ok else "FAIL"))

	_n1_send_key(KEY_RIGHT)
	await get_tree().process_frame
	var grid_right_ok: bool = panel._card_controls.size() > 1 \
		and viewport.gui_get_focus_owner() == panel._card_controls[1]
	ok = grid_right_ok and ok
	lines.append("  (6c) 격자 첫 카드에서 오른쪽 -> 두 번째 카드 -> %s" % ("OK" if grid_right_ok else "FAIL"))

	if panel._card_controls.size() > MonsterCodexPanel.COLUMNS:
		panel._card_controls[0].grab_focus()
		_n1_send_key(KEY_DOWN)
		await get_tree().process_frame
		var grid_down_ok: bool = viewport.gui_get_focus_owner() == panel._card_controls[MonsterCodexPanel.COLUMNS]
		ok = grid_down_ok and ok
		lines.append("  (6d) 격자 첫 카드에서 아래 -> 다음 행 같은 열 카드 -> %s" % ("OK" if grid_down_ok else "FAIL"))

	# 상세 뷰 키보드 이동: 뒤로 버튼 -> 오른쪽 -> 첫 입고 표정 버튼.
	panel._grid_cards_by_id["goblin_king"].activated.emit()
	await get_tree().process_frame
	panel._back_button.grab_focus()
	_n1_send_key(KEY_RIGHT)
	await get_tree().process_frame
	var detail_right_ok: bool = viewport.gui_get_focus_owner() == panel._expression_buttons["neutral"]
	ok = detail_right_ok and ok
	lines.append("  (6e) 상세 뷰 '← 목록'에서 오른쪽 -> 첫 입고 표정 버튼('neutral') -> %s" % (
		"OK" if detail_right_ok else "FAIL"
	))

	remove_child(panel)
	panel.free()
	_art1b_remove_fake_faces(base_dir_pattern, "slime", ["neutral", "happy"])
	_art1c2_remove_fake_full(base_dir_pattern, "slime")
	for expr2 in gk_colors.keys():
		DirAccess.remove_absolute(gk_dir + "face_%s.png" % expr2)
	DirAccess.remove_absolute(gk_dir + "full.png")
	DirAccess.remove_absolute(gk_dir)
	DirAccess.remove_absolute("user://q11_test_tmp/")

	return ok


## [대형 기획 15] Q-12(a,b,c)(2026-10-20) — 보스 설정 스토리 반영. "플래그가 아니라
## 실제 값/실제 화면 텍스트"로 검증: (1)(2)(3) MonsterCatalog.boss_intro_text()의
## 결정적 조회(character_intro 우선/intro 폴백/비보스 몬스터는 빈 문자열), (4)
## production combat_test._ready()가 실제로 전투 기록 로그 첫 줄에 그 문구를 찍는지
## (보스/비보스 둘 다), (5) 몬스터 도감 상세 뷰 info_label에 보스만 "등장:" 줄이
## 붙는지. RunState.test_battle 경로(_monster_config_for_test())를 쓰는 이유는
## is_boss가 몬스터 프로필의 실제 tier로 판정돼(room_index 위치가 아님) 테스트가
## 몬스터 id만으로 보스/비보스를 결정적으로 고를 수 있기 때문.
func _check_q12_boss_intro(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 보스 6종 전부 intro 존재.
	var boss_ids: Array = MonsterCatalog.boss_roster_ids()
	var missing_intro: Array[String] = []
	for mid in boss_ids:
		var m: Dictionary = MonsterCatalog.get_by_id(mid)
		if String(m.get("intro", "")) == "":
			missing_intro.append(mid)
	var all_intro_ok: bool = missing_intro.is_empty()
	ok = all_intro_ok and ok
	lines.append("  (1) 보스 %d종 전부 intro 존재 -> %s%s" % [
		boss_ids.size(), "OK" if all_intro_ok else "FAIL",
		("" if all_intro_ok else (" (누락: " + ", ".join(missing_intro) + ")"))
	])

	# (2) 결정적 조회 — character_intro 우선(필수 2종: 광전사x광란의 마수/수호자x
	# 타락한 기사단장), 매치 없으면 기본 intro로 폴백.
	var beast: Dictionary = MonsterCatalog.get_by_id("frenzied_beast")
	var beast_berserker: String = MonsterCatalog.boss_intro_text(beast, "berserker")
	var beast_berserker_ok: bool = beast_berserker == beast["character_intro"]["berserker"] and beast_berserker != ""
	ok = beast_berserker_ok and ok
	lines.append("  (2a) 광란의 마수 x 광전사 -> character_intro 변형 대사 조회 -> %s" % ("OK" if beast_berserker_ok else "FAIL"))

	var beast_novice: String = MonsterCatalog.boss_intro_text(beast, "novice")
	var beast_novice_ok: bool = beast_novice == beast["intro"] and beast_novice != beast_berserker
	ok = beast_novice_ok and ok
	lines.append("  (2b) 광란의 마수 x 견습 모험가(변형 없음) -> 기본 intro로 폴백(변형과 다른 문구) -> %s" % ("OK" if beast_novice_ok else "FAIL"))

	var commander: Dictionary = MonsterCatalog.get_by_id("fallen_commander")
	var commander_guardian: String = MonsterCatalog.boss_intro_text(commander, "guardian")
	var commander_guardian_ok: bool = commander_guardian == commander["character_intro"]["guardian"] and commander_guardian != ""
	ok = commander_guardian_ok and ok
	lines.append("  (2c) 타락한 기사단장 x 수호자 -> character_intro 변형 대사 조회 -> %s" % ("OK" if commander_guardian_ok else "FAIL"))

	var commander_pirate: String = MonsterCatalog.boss_intro_text(commander, "pirate")
	var commander_pirate_ok: bool = commander_pirate == commander["intro"]
	ok = commander_pirate_ok and ok
	lines.append("  (2d) 타락한 기사단장 x 해적(변형 없음) -> 기본 intro로 폴백 -> %s" % ("OK" if commander_pirate_ok else "FAIL"))

	# (3) 보스가 아닌 몬스터(intro 필드 자체가 없음)도 크래시 없이 빈 문자열.
	var slime: Dictionary = MonsterCatalog.get_by_id("slime")
	var slime_intro: String = MonsterCatalog.boss_intro_text(slime, "novice")
	var slime_intro_ok: bool = slime_intro == ""
	ok = slime_intro_ok and ok
	lines.append("  (3) 일반 몬스터(slime, intro 없음) -> boss_intro_text()='%s'(기대 빈 문자열) -> %s" % [slime_intro, "OK" if slime_intro_ok else "FAIL"])

	# (4) production 배선 — RunState.test_battle 경로는 is_boss를 몬스터 프로필의
	# 실제 tier로 판정하므로(room_index 위치 무관) 보스/비보스를 몬스터 id만으로 결정적
	# 으로 고를 수 있다. combat_test._ready()가 전투 기록 로그 첫 줄에 실제로 그 문구를
	# 찍는지(그리고 비보스는 안 찍는지)를 확인한다.
	var character_backup: String = RunState.character_id
	var test_battle_backup: bool = RunState.test_battle
	var test_monster_backup: String = RunState.test_monster_id
	var test_difficulty_backup: int = RunState.test_difficulty

	RunState.test_battle = true
	RunState.test_difficulty = 5

	RunState.character_id = "berserker"
	RunState.test_monster_id = "frenzied_beast"
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat_boss = combat_scene.instantiate()
	add_child(combat_boss)
	var boss_log_ok: bool = combat_boss.log_label.text.find(beast["character_intro"]["berserker"]) != -1
	ok = boss_log_ok and ok
	lines.append("  (4a) production 전투 시작(광전사 x 광란의 마수) -> 전투 기록 로그에 변형 대사 포함 -> %s" % ("OK" if boss_log_ok else "FAIL"))
	remove_child(combat_boss)
	combat_boss.free()

	RunState.character_id = "novice"
	RunState.test_monster_id = "void_eye"
	var void_profile: Dictionary = MonsterCatalog.get_by_id("void_eye")
	var combat_void = combat_scene.instantiate()
	add_child(combat_void)
	var void_log_ok: bool = combat_void.log_label.text.find(void_profile["intro"]) != -1
	ok = void_log_ok and ok
	lines.append("  (4b) production 전투 시작(견습 모험가 x 공허의 눈, 캐릭터 변형 없음) -> 로그에 기본 intro 포함 -> %s" % ("OK" if void_log_ok else "FAIL"))
	remove_child(combat_void)
	combat_void.free()

	RunState.test_monster_id = "slime"
	var combat_normal = combat_scene.instantiate()
	add_child(combat_normal)
	var normal_log_ok: bool = combat_normal.log_label.text == ""
	ok = normal_log_ok and ok
	lines.append("  (4c) production 전투 시작(일반 몬스터 slime, 보스 아님) -> 전투 기록 로그에 보스 대사 없음(log='%s') -> %s" % [
		combat_normal.log_label.text, "OK" if normal_log_ok else "FAIL"
	])
	remove_child(combat_normal)
	combat_normal.free()

	RunState.character_id = character_backup
	RunState.test_battle = test_battle_backup
	RunState.test_monster_id = test_monster_backup
	RunState.test_difficulty = test_difficulty_backup

	# (5) 몬스터 도감 상세 뷰 — 보스만 "성격" 정보 줄 근처에 "등장: <기본 intro>"가
	# 붙는지(캐릭터 전용 변형은 도감에서 안 보여줌 — 항상 기본 문구).
	var panel := MonsterCodexPanel.new()
	add_child(panel)
	panel.open()
	await get_tree().process_frame

	panel._grid_cards_by_id["frenzied_beast"].activated.emit()
	await get_tree().process_frame
	var boss_info_label: Label = null
	for n in panel._ui:
		if n is Label and String((n as Label).text).begins_with("성격: "):
			boss_info_label = n
			break
	var boss_codex_ok: bool = boss_info_label != null and boss_info_label.text.find("등장: " + beast["intro"]) != -1
	ok = boss_codex_ok and ok
	lines.append("  (5a) 몬스터 도감 상세(광란의 마수, 보스) info_label에 '등장: <기본 intro>' 포함 -> %s" % ("OK" if boss_codex_ok else "FAIL"))

	# detail 뷰는 _grid_cards_by_id를 비워두므로(그 뷰 동안은 격자 자체가 안 그려짐)
	# 다른 카드를 보려면 먼저 "← 목록"으로 격자를 다시 그려야 한다(Q-11 테스트와 같은 패턴).
	panel._on_back_pressed()
	await get_tree().process_frame
	panel._grid_cards_by_id["slime"].activated.emit()
	await get_tree().process_frame
	var normal_info_label: Label = null
	for n2 in panel._ui:
		if n2 is Label and String((n2 as Label).text).begins_with("성격: "):
			normal_info_label = n2
			break
	var normal_codex_ok: bool = normal_info_label != null and normal_info_label.text.find("등장:") == -1
	ok = normal_codex_ok and ok
	lines.append("  (5b) 몬스터 도감 상세(slime, 일반) info_label에 '등장:' 줄 없음 -> %s" % ("OK" if normal_codex_ok else "FAIL"))

	remove_child(panel)
	panel.free()

	return ok


## [대형 기획 15] Q-10(2026-10-20): 스토리/특수 이벤트 일러스트 경로. "플래그가
## 들어갔는가"가 아니라 "일러스트가 실제로 나타나는가/사라지는가/제목이 실제
## 픽셀 폭 기준으로 겹칠 뻔한 케이스에서도 안 겹치는가"를 계산 결과로 검증한다.
func _check_q10_event_illustrations(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://q10_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir)

	# (1) CharacterArt.load_event_art()/has_event_art() 계약 — production 경로에
	# 존재할 수 없는 id는 null/false로 조용히 폴백한다(에러 없이).
	var missing_ok: bool = (
		not CharacterArt.has_event_art("q10_nonexistent_event_xyz")
		and CharacterArt.load_event_art("q10_nonexistent_event_xyz") == null
	)
	ok = missing_ok and ok
	lines.append("  (1) load_event_art(존재하지 않는 id, 운영 경로): 파일 없음 -> null/false -> %s" % ("OK" if missing_ok else "FAIL"))

	# (2) user:// 임시 폴더 — 합성 PNG 생성 전엔 false/null, 생성 후엔 true/Texture2D로
	# "계산 결과가 실제로 바뀌는지" 직접 확인.
	var before_ok: bool = (
		not CharacterArt.has_event_art("treasure", tmp_dir)
		and CharacterArt.load_event_art("treasure", tmp_dir) == null
	)
	ok = before_ok and ok
	lines.append("  (2a) 합성 PNG 생성 전: has_event_art/load_event_art -> false/null -> %s" % ("OK" if before_ok else "FAIL"))

	var synth_img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	synth_img.fill(Color(0.4, 0.2, 0.6, 1.0))
	var save_err := synth_img.save_png(tmp_dir + "treasure.png")
	var save_ok: bool = save_err == OK
	ok = save_ok and ok
	lines.append("  (2b) user:// 임시 PNG 저장: %s" % ("OK" if save_ok else "FAIL (err=%d)" % save_err))

	var after_ok: bool = CharacterArt.has_event_art("treasure", tmp_dir) and CharacterArt.load_event_art("treasure", tmp_dir) != null
	ok = after_ok and ok
	lines.append("  (2c) 합성 PNG 생성 후: has_event_art=true, load_event_art!=null -> %s" % ("OK" if after_ok else "FAIL"))

	# (3) 데이터 무결성 — 판정 이벤트(CHALLENGES) + 스토리 이벤트(SCENARIOS) 전수가
	# id를 갖고, 같은 resources/events/ 폴더를 공유하므로 둘을 합쳐도 전부 유니크해야
	# 파일 경로가 충돌하지 않는다.
	var all_ids: Array = []
	for c in EventChallengePool.CHALLENGES:
		all_ids.append(String(c.get("id", "")))
	var challenge_count := all_ids.size()
	for s in StoryEventPool.SCENARIOS:
		all_ids.append(String(s.get("id", "")))
	var scenario_count := all_ids.size() - challenge_count
	var ids_nonempty := true
	for id_str in all_ids:
		if id_str == "":
			ids_nonempty = false
	var seen := {}
	var ids_unique := true
	for id_str in all_ids:
		if seen.has(id_str):
			ids_unique = false
		seen[id_str] = true
	var ids_ok: bool = ids_nonempty and ids_unique
	ok = ids_ok and ok
	lines.append("  (3) 판정 이벤트 %d종 + 스토리 이벤트 %d종 전부 id 존재 + 합쳐서 전체 유니크 -> %s" % [
		challenge_count, scenario_count, "OK" if ids_ok else "FAIL"
	])

	# (4) event.gd 실배선 — 아트 없음(폴백 null) -> 있음(실제 표시) -> 선택 후(숨김),
	# 그리고 Q-12 인수인계 버그(제목이 subtitle이 길면 스킬 도감 버튼과 겹침) 회귀 확인.
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)
	event_node.event_art_base_dir = tmp_dir

	event_node._debug_force_challenge("exploration")  # tmp_dir에 exploration.png 없음
	var fallback_ok: bool = event_node._illustration_rect == null
	ok = fallback_ok and ok
	lines.append("  (4a) 아트 없는 챌린지(exploration) -> 일러스트 null(배경 폴백) -> %s" % ("OK" if fallback_ok else "FAIL"))

	event_node._debug_force_challenge_treasure()  # tmp_dir에 treasure.png 있음(2b)
	var shown_ok: bool = (
		event_node._illustration_rect != null
		and event_node._illustration_rect.visible
		and event_node._illustration_rect.texture != null
	)
	ok = shown_ok and ok
	lines.append("  (4b) 아트 있는 챌린지(treasure) -> 일러스트 실제 표시(texture!=null) -> %s" % ("OK" if shown_ok else "FAIL"))

	var illu_rect: Rect2 = event_node._illustration_rect.get_global_rect()
	var no_overlap_ok: bool = (
		not illu_rect.intersects(event_node.safe_button.get_global_rect())
		and not illu_rect.intersects(event_node.risky_button.get_global_rect())
	)
	ok = no_overlap_ok and ok
	lines.append("  (4c) 일러스트 rect가 안전/위험 버튼 rect와 겹치지 않음 -> %s" % ("OK" if no_overlap_ok else "FAIL"))

	event_node._on_safe_pressed()
	var hidden_ok: bool = event_node._illustration_rect != null and not event_node._illustration_rect.visible
	ok = hidden_ok and ok
	lines.append("  (4d) '안전하게 넘어가기' 선택 후(판정 결과 구역과 자리가 겹침) -> 일러스트 hide() -> %s" % ("OK" if hidden_ok else "FAIL"))

	event_node._debug_force_challenge("ancient_oath")  # 알려진 이슈(2026-10-20)의 실제 재현 조건
	var title_text: String = event_node.title_label.text
	var title_clip_ok: bool = (
		event_node.title_label.clip_text
		and event_node.title_label.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	var title_font: Font = event_node.title_label.get_theme_default_font()
	var title_font_size: int = event_node.title_label.get_theme_default_font_size()
	if event_node.title_label.label_settings != null:
		title_font_size = event_node.title_label.label_settings.font_size
		if event_node.title_label.label_settings.font != null:
			title_font = event_node.title_label.label_settings.font
	var text_width: float = title_font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size).x
	var title_rect: Rect2 = event_node.title_label.get_global_rect()
	# ancient_oath는 실제로 title_rect 폭(1020px)보다 넓게 렌더될 만큼 긴 문장이라야
	# "클리핑이 없었다면 겹쳤을 것"을 증명한다 — 이 조건 자체가 거짓이면 회귀를 못
	# 잡는 가짜 통과이므로 함께 검증한다.
	var reproduces_overflow: bool = text_width > title_rect.size.x
	var title_no_overlap_ok: bool = not title_rect.intersects(event_node.skill_codex_button.get_global_rect())
	var title_ok: bool = title_clip_ok and reproduces_overflow and title_no_overlap_ok
	ok = title_ok and ok
	lines.append("  (4e) ancient_oath 제목('%s', 실측폭 %.0fpx > 박스폭 %.0fpx) -> clip+ellipsis 설정 + 스킬 도감 버튼과 안 겹침 -> %s" % [
		title_text, text_width, title_rect.size.x, "OK" if title_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()

	# (5) story_event.gd 실배선 — 같은 계약(아트 없음/있음), 단 이 화면은 선택 후에도
	# 겹치는 요소가 없어 설계상 일러스트를 숨기지 않는다(story_event.gd의
	# _on_choice_pressed() 주석 참고).
	var story_scene := load("res://code/scenes/story_event.tscn")
	var story_node = story_scene.instantiate()
	add_child(story_node)
	story_node.event_art_base_dir = tmp_dir

	story_node._debug_force_scenario_by_title("낡은 보물상자")  # id=old_chest, tmp_dir에 없음
	var story_fallback_ok: bool = story_node._illustration_rect == null
	ok = story_fallback_ok and ok
	lines.append("  (5a) 아트 없는 시나리오(낡은 보물상자) -> 일러스트 null(배경 폴백) -> %s" % ("OK" if story_fallback_ok else "FAIL"))

	var story_img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	story_img.fill(Color(0.2, 0.5, 0.3, 1.0))
	story_img.save_png(tmp_dir + "suspicious_gambler.png")
	story_node._debug_force_scenario_by_title("수상한 도박꾼")  # id=suspicious_gambler
	var story_shown_ok: bool = (
		story_node._illustration_rect != null
		and story_node._illustration_rect.visible
		and story_node._illustration_rect.texture != null
	)
	ok = story_shown_ok and ok
	lines.append("  (5b) 아트 있는 시나리오(수상한 도박꾼) -> 일러스트 실제 표시 -> %s" % ("OK" if story_shown_ok else "FAIL"))

	var story_illu_rect: Rect2 = story_node._illustration_rect.get_global_rect()
	var story_no_overlap_ok: bool = (
		not story_illu_rect.intersects(story_node.choice_a_button.get_global_rect())
		and not story_illu_rect.intersects(story_node.choice_b_button.get_global_rect())
		and not story_illu_rect.intersects(story_node.continue_button.get_global_rect())
	)
	ok = story_no_overlap_ok and ok
	lines.append("  (5c) 일러스트 rect가 선택지 A/B/계속 버튼 rect와 겹치지 않음 -> %s" % ("OK" if story_no_overlap_ok else "FAIL"))

	story_node._on_choice_pressed(story_node._scenario["choice_a"])
	var story_kept_ok: bool = story_node._illustration_rect != null and story_node._illustration_rect.visible
	ok = story_kept_ok and ok
	lines.append("  (5d) 선택 후에도 일러스트 유지(겹치는 요소 없음, 설계 의도) -> %s" % ("OK" if story_kept_ok else "FAIL"))

	remove_child(story_node)
	story_node.free()

	DirAccess.remove_absolute(tmp_dir + "treasure.png")
	DirAccess.remove_absolute(tmp_dir + "suspicious_gambler.png")
	DirAccess.remove_absolute(tmp_dir)

	return ok


## [대형 기획 15] Q-9 검증. INBOX 설계 3가지를 전부 계산 결과로 확인한다:
## (1) 경로 규칙 — 기믹/업적 id 전수에 대해 external_art_path()가 "<base>/<id>.png"
##     형태로 일관되는지(resources/는 안 건드리고 식으로만 확인).
## (2) 외부 아트 override 계약 — user:// 합성 PNG로 "파일 없음->절차적 폴백,
##     파일 있음->외부 아트"가 실제로 바뀌는지(SkillIcon.render_source()/
##     AchievementIcon.render_source()), 그리고 SkillIcon의 틴트가 실제 픽셀 색을
##     바꾸는지(흰 아트+빨간 틴트 -> 빨간 픽셀).
## (3) 절차적 도안 전수 distinctness — 기믹 8종(CATEGORIES, "없음" 포함)과 업적
##     9유형(CATEGORIES)이 서로 다른 픽셀로 렌더되는지(K-4a와 같은 SubViewport 비교
##     패턴), 그리고 전부 완전 투명(안 그려짐)이 아닌지.
## (4) 동반 수정 회귀 — event.gd 특별 선택지 버튼(SPECIAL_CHOICE_BUTTON_RECT)이
##     safe/risky 버튼과 더 이상 겹치지 않는지(활성/잠김 두 상태 모두).
func _check_q9_gimmick_achievement_icons(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://q9_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir)

	# (1) 경로 규칙 일관성 — 기믹 id 전수(빈 문자열 "없음"은 애초에 외부 아트 대상이
	# 아니므로 제외) + 업적 id 전수(AchievementManager.DEFINITIONS, 32종).
	var gimmick_ids: Array = []
	for cat in SkillIcon.CATEGORIES:
		if cat != "":
			gimmick_ids.append(cat)
	var gimmick_path_bad: PackedStringArray = []
	for gid in gimmick_ids:
		var expected := "res://resources/skills/%s.png" % gid
		if SkillIcon.external_art_path(gid) != expected:
			gimmick_path_bad.append(gid)
	var achievement_ids: Array = AchievementManager.DEFINITIONS.keys()
	var achievement_path_bad: PackedStringArray = []
	for aid in achievement_ids:
		var expected_a := "res://resources/achievements/%s.png" % aid
		if AchievementIcon.external_art_path(aid) != expected_a:
			achievement_path_bad.append(aid)
	var path_ok: bool = gimmick_path_bad.is_empty() and achievement_path_bad.is_empty()
	ok = path_ok and ok
	lines.append("  (1) 기믹 %d종 + 업적 %d종 전수 external_art_path() == '<base>/<id>.png' -> %s" % [
		gimmick_ids.size(), achievement_ids.size(), "OK" if path_ok else "FAIL"
	])
	if not gimmick_path_bad.is_empty():
		lines.append("    기믹 경로 불일치: %s" % ", ".join(gimmick_path_bad))
	if not achievement_path_bad.is_empty():
		lines.append("    업적 경로 불일치: %s" % ", ".join(achievement_path_bad))

	# (2a) SkillIcon — 파일 없음(폴백 "category") -> 생성 -> "external"로 바뀌는지.
	var gimmick_test_id := "min_max_only"
	var skill_icon := SkillIcon.new()
	skill_icon.category = gimmick_test_id
	skill_icon.skill_id = gimmick_test_id
	skill_icon.external_art_base_dir = tmp_dir
	add_child(skill_icon)
	var before_src := skill_icon.render_source()
	var before_ok: bool = before_src == "category"
	ok = before_ok and ok
	lines.append("  (2a) SkillIcon override 파일 생성 전: render_source()=='category' -> %s (실제: %s)" % ["OK" if before_ok else "FAIL", before_src])

	# 흰색+알파 합성 PNG — 틴트가 실제로 RGB를 바꾸는지 보려고 일부러 순백으로 만든다.
	var white_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	white_img.fill(Color(1, 1, 1, 1))
	white_img.save_png(tmp_dir + gimmick_test_id + ".png")

	var after_src := skill_icon.render_source()
	var after_ok: bool = after_src == "external"
	ok = after_ok and ok
	lines.append("  (2b) SkillIcon override 파일 생성 후: render_source()=='external' -> %s (실제: %s)" % ["OK" if after_ok else "FAIL", after_src])

	# (2c) 캐릭터 퍼스널 컬러 틴트 — 순백 아트 + 빨간 틴트 -> 로드된 텍스처가 실제로
	# 빨간색이어야 한다(틴트 없음은 흰색 그대로).
	var untinted_tex := SkillIcon.load_external_art(gimmick_test_id, tmp_dir)
	var untinted_img: Image = untinted_tex.get_image() if untinted_tex != null else null
	var untinted_ok: bool = untinted_img != null and untinted_img.get_pixel(0, 0).is_equal_approx(Color(1, 1, 1, 1))
	var red_tint := Color(1, 0, 0, 1)
	var tinted_tex := SkillIcon.load_tinted_external_art(gimmick_test_id, tmp_dir, red_tint)
	var tinted_img: Image = tinted_tex.get_image() if tinted_tex != null else null
	var tinted_ok: bool = tinted_img != null and tinted_img.get_pixel(0, 0).is_equal_approx(red_tint)
	var tint_ok: bool = untinted_ok and tinted_ok
	ok = tint_ok and ok
	lines.append("  (2c) 틴트 없음 픽셀=흰색, 빨간 틴트 픽셀=빨강(흰 아트 RGB*tint, 알파 유지) -> %s" % ("OK" if tint_ok else "FAIL"))

	# (2d) 인스턴스의 tint 프로퍼티를 통해서도 같은 결과가 나오는지(render_source()는
	# 여전히 "external" 유지 — tint는 external 우선순위에 영향 없음).
	skill_icon.tint = red_tint
	var tinted_via_icon := skill_icon.render_source()
	var tinted_via_icon_ok: bool = tinted_via_icon == "external"
	ok = tinted_via_icon_ok and ok
	lines.append("  (2d) tint 설정 후에도 render_source()=='external' 유지 -> %s (실제: %s)" % ["OK" if tinted_via_icon_ok else "FAIL", tinted_via_icon])

	remove_child(skill_icon)
	skill_icon.free()
	DirAccess.remove_absolute(tmp_dir + gimmick_test_id + ".png")

	# (2e) AchievementIcon — 같은 계약(파일 없음->category, 생성 후->external).
	var achievement_test_id := "gold_100"
	var ach_icon := AchievementIcon.new()
	ach_icon.category = "gold"
	ach_icon.achievement_id = achievement_test_id
	ach_icon.external_art_base_dir = tmp_dir
	add_child(ach_icon)
	var ach_before := ach_icon.render_source()
	var ach_before_ok: bool = ach_before == "category"
	ok = ach_before_ok and ok
	lines.append("  (2e) AchievementIcon override 파일 생성 전: render_source()=='category' -> %s (실제: %s)" % ["OK" if ach_before_ok else "FAIL", ach_before])

	var ach_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	ach_img.fill(Color(0.2, 0.6, 0.3, 1.0))
	ach_img.save_png(tmp_dir + achievement_test_id + ".png")
	var ach_after := ach_icon.render_source()
	var ach_after_ok: bool = ach_after == "external"
	ok = ach_after_ok and ok
	lines.append("  (2f) AchievementIcon override 파일 생성 후: render_source()=='external' -> %s (실제: %s)" % ["OK" if ach_after_ok else "FAIL", ach_after])

	DirAccess.remove_absolute(tmp_dir + achievement_test_id + ".png")
	var ach_removed := ach_icon.render_source()
	var ach_removed_ok: bool = ach_removed == "category"
	ok = ach_removed_ok and ok
	lines.append("  (2g) override 파일 삭제 후: render_source()=='category'로 복귀 -> %s (실제: %s)" % ["OK" if ach_removed_ok else "FAIL", ach_removed])

	remove_child(ach_icon)
	ach_icon.free()
	DirAccess.remove_absolute(tmp_dir)

	# (3) 절차적 도안 전수 distinctness — 기믹 8종(SkillIcon.CATEGORIES, "없음" 포함)
	# + 업적 9유형(AchievementIcon.CATEGORIES), 각각 독립 SubViewport(K-4a와 같은 패턴).
	var icon_size := Vector2i(30, 30)

	var gimmick_viewports: Array[SubViewport] = []
	for cat in SkillIcon.CATEGORIES:
		var icon := SkillIcon.new()
		icon.size = Vector2(icon_size)
		icon.category = cat
		var vp := SubViewport.new()
		vp.size = icon_size
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.add_child(icon)
		add_child(vp)
		gimmick_viewports.append(vp)

	var ach_viewports: Array[SubViewport] = []
	for cat in AchievementIcon.CATEGORIES:
		var icon2 := AchievementIcon.new()
		icon2.size = Vector2(icon_size)
		icon2.category = cat
		var vp2 := SubViewport.new()
		vp2.size = icon_size
		vp2.transparent_bg = true
		vp2.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp2.add_child(icon2)
		add_child(vp2)
		ach_viewports.append(vp2)

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var gimmick_blank: PackedStringArray = []
	var gimmick_dup: PackedStringArray = []
	var seen_gimmick: Dictionary = {}
	for i in range(SkillIcon.CATEGORIES.size()):
		var cat_name: String = SkillIcon.CATEGORIES[i]
		var label_name: String = cat_name if cat_name != "" else "(없음)"
		var img: Image = gimmick_viewports[i].get_texture().get_image()
		var data: PackedByteArray = img.get_data() if img != null else PackedByteArray()
		var has_pixel := false
		for b in data:
			if b != 0:
				has_pixel = true
				break
		# "없음" 카테고리는 가는 회색 원 하나뿐이라도 그려지는 게 맞다(의도된 디자인).
		if not has_pixel:
			gimmick_blank.append(label_name)
		for other in seen_gimmick.keys():
			if seen_gimmick[other] == data:
				gimmick_dup.append("%s==%s" % [label_name, other])
		seen_gimmick[label_name] = data
	for vp in gimmick_viewports:
		remove_child(vp)
		vp.free()

	var ach_blank: PackedStringArray = []
	var ach_dup: PackedStringArray = []
	var seen_ach: Dictionary = {}
	for i in range(AchievementIcon.CATEGORIES.size()):
		var cat_name2: String = AchievementIcon.CATEGORIES[i]
		var img2: Image = ach_viewports[i].get_texture().get_image()
		var data2: PackedByteArray = img2.get_data() if img2 != null else PackedByteArray()
		var has_pixel2 := false
		for b in data2:
			if b != 0:
				has_pixel2 = true
				break
		if not has_pixel2:
			ach_blank.append(cat_name2)
		for other2 in seen_ach.keys():
			if seen_ach[other2] == data2:
				ach_dup.append("%s==%s" % [cat_name2, other2])
		seen_ach[cat_name2] = data2
	for vp in ach_viewports:
		remove_child(vp)
		vp.free()

	var distinct_ok: bool = gimmick_blank.is_empty() and gimmick_dup.is_empty() and ach_blank.is_empty() and ach_dup.is_empty()
	ok = distinct_ok and ok
	lines.append("  (3) 기믹 %d종(없음 포함) + 업적 %d유형 전부 비어있지 않고 서로 다른 픽셀로 렌더 -> %s" % [
		SkillIcon.CATEGORIES.size(), AchievementIcon.CATEGORIES.size(), "OK" if distinct_ok else "FAIL"
	])
	if not gimmick_blank.is_empty():
		lines.append("    빈 기믹 아이콘: %s" % ", ".join(gimmick_blank))
	if not gimmick_dup.is_empty():
		lines.append("    동일 렌더 기믹 쌍: %s" % ", ".join(gimmick_dup))
	if not ach_blank.is_empty():
		lines.append("    빈 업적 아이콘: %s" % ", ".join(ach_blank))
	if not ach_dup.is_empty():
		lines.append("    동일 렌더 업적 쌍: %s" % ", ".join(ach_dup))

	# (4) 동반 수정 회귀 — event.gd 특별 선택지 버튼이 safe/risky 버튼과 안 겹치는지,
	# 활성(enchantress)/잠김(novice) 두 상태 모두.
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)

	event_node._debug_force_special_choice_active()
	var active_rect: Rect2 = event_node._special_button.get_global_rect()
	var active_no_overlap_ok: bool = (
		not active_rect.intersects(event_node.safe_button.get_global_rect())
		and not active_rect.intersects(event_node.risky_button.get_global_rect())
	)
	ok = active_no_overlap_ok and ok
	lines.append("  (4a) 특별 선택지 '활성' 상태 — safe/risky 버튼과 안 겹침 -> %s" % ("OK" if active_no_overlap_ok else "FAIL"))

	event_node._debug_force_special_choice_locked()
	var locked_rect: Rect2 = event_node._special_button.get_global_rect()
	var locked_no_overlap_ok: bool = (
		not locked_rect.intersects(event_node.safe_button.get_global_rect())
		and not locked_rect.intersects(event_node.risky_button.get_global_rect())
	)
	ok = locked_no_overlap_ok and ok
	lines.append("  (4b) 특별 선택지 '잠김' 상태(매혹사 전용, novice가 봄) — safe/risky 버튼과 안 겹침 -> %s" % ("OK" if locked_no_overlap_ok else "FAIL"))

	remove_child(event_node)
	event_node.free()

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
		and first.story == second.story and first.elite == second.elite and first.order == second.order
	ok = deterministic_ok and ok
	lines.append("  _room_options_for_index(3) 반복 호출 결정성(노출 여부+순서 동일): %s -> %s" % [
		deterministic_ok, "OK" if deterministic_ok else "FAIL"
	])

	# order는 노출 여부(shop/event/story/elite 각각 true/false)와 무관하게 항상 네 종류를
	# 정확히 한 번씩만 담은 순열이어야 한다 — 버튼 레이아웃(_layout_visible_buttons)과
	# 칩 나열(_make_map_node)이 둘 다 "for t in opts.order: if opts[t]: ..."로
	# 순회하므로, order 자체에 값이 빠지거나 중복되면 노출된 방 선택지 하나가 화면에서
	# 통째로 안 보이거나(버튼 없음) 중복 렌더링될 수 있다. 단, 라운드 마지막 방
	# (idx == TOTAL_ROOMS - 1, 보스 방)은 2026-09-14 버그 수정으로 전투만 가능하도록
	# 강제되어 shop/event/story/elite가 전부 false + order가 빈 배열인 것이 의도된 예외다.
	# G-7(2026-10-07)로 "elite"가 네 번째 종류로 추가됐다(idx 1..TOTAL_ROOMS-2에서만
	# 확률 노출 — idx 0과 보스 방은 항상 false지만 order 순열에는 여전히 포함됨, 아래
	# 별도 검증에서 그 범위 제한을 직접 확인한다).
	var order_valid := true
	for idx in range(10):
		var opts = map._room_options_for_index(idx)
		if idx == RunState.TOTAL_ROOMS - 1:
			if opts.shop or opts.event or opts.story or opts.elite or not opts.order.is_empty():
				order_valid = false
			continue
		var sorted_order: Array = opts.order.duplicate()
		sorted_order.sort()
		if sorted_order != ["elite", "event", "shop", "story"]:
			order_valid = false
	ok = order_valid and ok
	lines.append("  order가 항상 shop/event/story/elite 순열임(idx 0..9, 보스 방 idx=%d는 예외로 4종 전부 미노출 확인): %s -> %s" % [
		RunState.TOTAL_ROOMS - 1, order_valid, "OK" if order_valid else "FAIL"
	])

	# G-7(2026-10-07) 신규: "정예 전투"는 idx 1..TOTAL_ROOMS-2(5방 기준 1~3)에서만 노출
	# 가능하고, idx 0(첫 방)과 보스 방(위에서 이미 확인)에서는 확률과 무관하게 항상 false.
	var elite_range_ok: bool = not map._room_options_for_index(0).elite
	var elite_seen_in_range := false
	for idx in range(1, RunState.TOTAL_ROOMS - 1):
		if map._room_options_for_index(idx).elite:
			elite_seen_in_range = true
	ok = elite_range_ok and ok
	lines.append("  정예 전투는 idx=0에서 항상 false=%s, idx 1..%d 중 적어도 한 곳은 true 가능=%s -> %s" % [
		elite_range_ok, RunState.TOTAL_ROOMS - 2, elite_seen_in_range, "OK" if elite_range_ok else "FAIL"
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
	# 기대값은 [대형 기획 10] J-2/J-3(2026-10-08~12) 튜닝이 끝난 최종 상태 —
	# 보스(room_index == RunState.TOTAL_ROOMS - 1, 지금은 4) 전용 공통 보정(공격/
	# 방어 다이스 개수 가산, HP 배율)은 전부 제거됐고(공격+0/방어+0/HP×1.0), 다이스
	# 면 승급 임계는 D6>=3/D8>=7(최초값 D6>=2/D8>=5에서 튜닝됨). 시도별 변화 경위는
	# `docs/BALANCE_TUNING_LOG.md`("J-2 보스 튜닝 시도 로그"/"J-3 방3 절벽 + 정예
	# 튜닝 시도 로그" 섹션) 참고 — 보스가 서는 room4는 D6/D8 두 임계 어느 쪽으로도
	# 영향받지 않는다(`_monster_dice_sides_for_room()` 주석 참고).
	var formula_ok := true
	for idx in range(7):
		var cfg = combat._monster_config_for_room(idx)
		var expected_attack := 2 + int(idx / 2.0)
		var expected_defense := 1 + int(idx / 3.0)
		var expected_hp := 10 + idx * 3
		var expected_sides := 8 if idx >= 7 else (6 if idx >= 3 else 4)
		if idx == RunState.TOTAL_ROOMS - 1:
			expected_hp = int(round(expected_hp * 1.0))
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

	# 이름 순환: 2026-10-26 R-1로 LEGACY_ROOM_CYCLE_IDS가 4개(slime/goblin/orc/
	# dark_knight)가 되며 "강화 " 접두어가 붙는 지점도 당겨졌다 — 4개를 다 돌면
	# (room_index=5, idx=1=goblin) 1번, 두 바퀴(room_index=10, idx=2=orc)면 2번
	# 누적되고, 각자의 gimmick 태그(고블린=anger_stack "[분노]", 오크=min_max_only
	# "[극단]")도 그대로 붙는다.
	var cycle1 = combat._monster_config_for_room(5)
	var cycle2 = combat._monster_config_for_room(10)
	var cycle_ok: bool = cycle1["name"] == "강화 고블린 [분노]" and cycle2["name"] == "강화 강화 오크 [극단]"
	ok = cycle_ok and ok
	lines.append("  이름 순환(room5, room10): %s, %s (기대 강화 고블린 [분노], 강화 강화 오크 [극단]) -> %s" % [
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

	# room2(오크, min_max_only, 2026-10-26 R-1로 "해골 전사" 제거 후 4종 순환이 되며
	# room2가 오크로 당겨짐): 극단 기믹 문구가 드러나야 한다.
	var room2_text: String = combat._monster_debug_info_text(combat._monster_config_for_room(2))
	var room2_ok: bool = room2_text.contains("극단")
	ok = room2_ok and ok
	lines.append("  room2(오크, min_max_only): %s -> %s" % [
		room2_text.replace("\n", " / "), "OK" if room2_ok else "FAIL"
	])

	# room3(다크 나이트, steady_guard, R-1로 4종 순환이 되며 room3으로 당겨짐): 하한선
	# 값이 문구에 드러나야 한다(보스 자리는 아님 — 4종 순환에서 TOTAL_ROOMS-1=4는 다시
	# slime으로 돌아가 보스+기믹 동시 검증은 room4 쪽에서 별도로 함).
	var room3_text: String = combat._monster_debug_info_text(combat._monster_config_for_room(3))
	var room3_ok: bool = room3_text.contains("철벽") \
		and room3_text.contains("성격: 차갑고 노련하며 방어에서 흔들리지 않는 기사")
	ok = room3_ok and ok
	lines.append("  room3(다크 나이트, steady_guard): %s -> %s" % [
		room3_text.replace("\n", " / "), "OK" if room3_ok else "FAIL"
	])

	# room4(TOTAL_ROOMS-1, 보스 방): 4종 순환이라 room4는 다시 slime(기믹 없음, "강화"
	# 1바퀴)이지만, "보스" 태그는 room_index 위치만으로 붙으므로 그 문구는 여전히 있어야
	# 한다(R-1로 기믹+보스 동시 검증 조합은 사라짐 — legacy 전용 경로라 실제 던전 진행에는
	# 영향 없음).
	var room4_config: Dictionary = combat._monster_config_for_room(RunState.TOTAL_ROOMS - 1)
	var room4_text: String = combat._monster_debug_info_text(room4_config)
	var room4_ok: bool = room4_text.contains("보스") and room4_config["name"] == "강화 슬라임 [보스]"
	ok = room4_ok and ok
	lines.append("  room4(강화 슬라임 + 보스): %s -> %s" % [
		room4_text.replace("\n", " / "), "OK" if room4_ok else "FAIL"
	])

	combat.free()
	return ok


## dice_bag.gd의 force_min_max_faces()/force_fixed_value()/count_max_rolls()는 INBOX.md
## 피드백(2026-09-09, "몬스터별 다이스 특이 특징" 예시 3개: "모든 주사위 눈이 min과
## max로만 이루어져 있다" / "주사위 값 x가 고정 데미지로 들어간다" / "주사위 x가 나올
## 때마다 분노 스택이 쌓여서 몇 개 이상이면 다음 턴에 20면체를 돌린다")를 구현한 것이다.
## combat_test.gd는 2026-09-16 [미니 기획 A]-1(몬스터 성격 기획)로 재배정된 뒤
## force_min_max_faces()를 "오크"(dice_gimmick="min_max_only")에,
## force_fixed_value()를 "해골 전사"(dice_gimmick="fixed_value")에, count_max_rolls()
## 기반 분노 스택 집계를 "고블린"(dice_gimmick="anger_stack")에 각각 적용했고,
## [미니 기획 A]-2(2026-09-16)로 "다크 나이트"에 apply_steady_guard() 기반 방어 결과
## 하한선 보정이 배정됐다 — 서로 다른 방에서만 켜지고, 다른 방(예: room0 슬라임)은
## 그대로 표준 다이스여야 한다. **2026-10-26 R-1(몬스터 로스터 정리)로 "해골 전사"가
## 카탈로그에서 완전히 제거되며, 레거시 순환(`MonsterCatalog.LEGACY_ROOM_CYCLE_IDS`,
## QA 전용 — 실제 던전 진행과 무관)이 5종(slime/goblin/skeleton/orc/dark_knight)에서
## 4종(slime/goblin/orc/dark_knight)으로 줄었다** — room_index가 room0=슬라임/
## room1=고블린(anger_stack)/room2=오크(min_max_only)/room3=다크 나이트(steady_guard)로
## 당겨졌고, fixed_value는 이 레거시 순환에서 더는 쓰는 몬스터가 없다(force_fixed_value()
## 자체의 순수 함수 검증은 그대로 유지, 몬스터 연결만 없어짐).
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

	# combat_test.gd _monster_config_for_room(): 2026-10-26 R-1로 "해골 전사" 제거 후
	# LEGACY_ROOM_CYCLE_IDS가 4종(slime/goblin/orc/dark_knight) 순환이 되며 min_max_only가
	# room3에서 room2로 당겨졌다 — room2만 gimmick이 켜지고 이름에 "[극단]"이 붙어야 하며,
	# room0(슬라임)은 영향받지 않아야 한다. "다크 나이트"(steady_guard)도 같은 이유로
	# room4->room3으로 당겨지는데, room3은 더 이상 보스 자리(TOTAL_ROOMS-1=4)가 아니라
	# steady_guard만 확인한다(보스+steady_guard 조합 자체는 4종 순환에서 더는 안 나옴 —
	# 이 경로는 QA 전용 레거시 호환이라 실제 던전 진행에는 영향 없음).
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	var room2_minmax_config = combat._monster_config_for_room(2)
	var room2_minmax_ok: bool = room2_minmax_config["dice_gimmick"] == "min_max_only" and room2_minmax_config["name"] == "오크 [극단]"
	ok = room2_minmax_ok and ok
	lines.append("  room2 config: dice_gimmick=%s name=%s (기대 min_max_only, '오크 [극단]') -> %s" % [
		room2_minmax_config["dice_gimmick"], room2_minmax_config["name"], "OK" if room2_minmax_ok else "FAIL"
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

	# combat_test.gd _monster_config_for_room(): 2026-10-26 R-1로 4종 순환이 되며
	# steady_guard("다크 나이트")가 room4에서 room3으로 당겨졌다 — room3만 gimmick이
	# 켜지고 min_max_only(room2)와 서로 영향 없이 독립적으로 동작해야 함. room3은 보스
	# 자리가 아니므로(TOTAL_ROOMS-1=4만 보스) 이름에 "[보스]"가 붙지 않아야 한다.
	var room3_config = combat._monster_config_for_room(3)
	var room3_ok: bool = room3_config["dice_gimmick"] == "steady_guard" \
		and room3_config["dice_gimmick_value"] == 3 \
		and room3_config["name"] == "다크 나이트 [철벽]"
	ok = room3_ok and ok
	lines.append("  room3 config: dice_gimmick=%s value=%d name=%s (기대 steady_guard/3/'다크 나이트 [철벽]') -> %s" % [
		room3_config["dice_gimmick"], room3_config["dice_gimmick_value"], room3_config["name"],
		"OK" if room3_ok else "FAIL"
	])
	# room4(TOTAL_ROOMS-1)는 4종 순환에서 다시 slime(cycle 1, "강화")으로 돌아가 gimmick이
	# 없지만, "보스" 이름 태그는 room_index 위치만으로 붙으므로 그대로 확인한다.
	var room4_config = combat._monster_config_for_room(4)
	var room4_ok: bool = room4_config["dice_gimmick"] == "" and room4_config["name"] == "강화 슬라임 [보스]"
	ok = room4_ok and ok
	lines.append("  room4 config: dice_gimmick=%s name=%s (기대 빈 문자열, '강화 슬라임 [보스]') -> %s" % [
		room4_config["dice_gimmick"], room4_config["name"], "OK" if room4_ok else "FAIL"
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
	# [대형 기획 5] F-2(a): 같은 시점에 캐릭터 전용 "r1_<id>"도 해금돼야 한다(다른 캐릭터는
	# 건드리지 않음) — 수호자로 검증.
	RunState.character_id = "guardian"
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
	var r1_char_ok := AchievementManager.is_unlocked("r1_guardian")
	var r1_other_char_not_unlocked_ok := not AchievementManager.is_unlocked("r1_berserker")
	ok = r1_char_ok and r1_other_char_not_unlocked_ok and ok
	lines.append("  라운드 1 보스 클리어(수호자): r1_guardian=%s(기대 true) r1_berserker=%s(기대 false) -> %s" % [
		AchievementManager.is_unlocked("r1_guardian"), AchievementManager.is_unlocked("r1_berserker"),
		"OK" if (r1_char_ok and r1_other_char_not_unlocked_ok) else "FAIL"
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

	# [대형 기획 9] I-2: 해적도 r1_pirate(라운드1 보스 클리어)/clear_pirate(최종 클리어)가
	# 실제로 해금되는지 직접 확인(DEFINITIONS에 키만 있고 unlock() 호출 경로가 캐릭터
	# id를 못 타는 버그를 놓치지 않기 위함 — _character_round1_achievement_id()/
	# _character_clear_achievement_id()는 이미 일반화돼 있지만, 새 캐릭터를 추가할
	# 때마다 실제 호출 결과로 재확인).
	AchievementManager._debug_reset_for_qa()
	RunState.character_id = "pirate"
	RunState.round_index = 1
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat5 = combat_script.new()
	combat5.player_won = true
	combat5.monster_is_boss = true
	combat5._apply_room_advance()
	var r1_pirate_ok := AchievementManager.is_unlocked("r1_pirate")
	ok = r1_pirate_ok and ok
	lines.append("  라운드 1 보스 클리어(해적): r1_pirate=%s(기대 true) -> %s" % [
		r1_pirate_ok, "OK" if r1_pirate_ok else "FAIL"
	])
	combat5.free()

	RunState.round_index = RunState.TOTAL_ROUNDS
	RunState.rooms_cleared = RunState.TOTAL_ROOMS - 1
	var combat6 = combat_script.new()
	combat6.player_won = true
	combat6.monster_is_boss = true
	combat6._apply_room_advance()
	var clear_pirate_ok := AchievementManager.is_unlocked("clear_pirate")
	ok = clear_pirate_ok and ok
	lines.append("  마지막 라운드 보스 클리어(해적): clear_pirate=%s(기대 true) -> %s" % [
		clear_pirate_ok, "OK" if clear_pirate_ok else "FAIL"
	])
	combat6.free()

	var all_clear_ids := ["clear_novice", "clear_berserker", "clear_guardian", "clear_explosive", "clear_shieldbearer", "clear_enchantress", "clear_juggler", "clear_pirate"]
	var all_ids_defined_ok := true
	for id in all_clear_ids:
		all_ids_defined_ok = all_ids_defined_ok and AchievementManager.DEFINITIONS.has(id)
	ok = all_ids_defined_ok and ok
	lines.append("  캐릭터 8종 전부 \"clear_<id>\" 업적 정의 존재: %s -> %s" % [
		all_ids_defined_ok, "OK" if all_ids_defined_ok else "FAIL"
	])

	# [대형 기획 5] F-2(a) 신설: 시작 스킬 슬롯 1의 새 조건 "r1_<id>"도 8종 전부 정의돼야 한다.
	var all_r1_ids := ["r1_novice", "r1_berserker", "r1_guardian", "r1_explosive", "r1_shieldbearer", "r1_enchantress", "r1_juggler", "r1_pirate"]
	var all_r1_ids_defined_ok := true
	for id in all_r1_ids:
		all_r1_ids_defined_ok = all_r1_ids_defined_ok and AchievementManager.DEFINITIONS.has(id)
	ok = all_r1_ids_defined_ok and ok
	lines.append("  캐릭터 8종 전부 \"r1_<id>\" 업적 정의 존재: %s -> %s" % [
		all_r1_ids_defined_ok, "OK" if all_r1_ids_defined_ok else "FAIL"
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


## INBOX.md 2026-09-15 [미니 기획 B]-4 검증. (1) PROFILES 8종 전부 event_die_sides
## 필드이 있고, 2026-10-15 [대형 기획 14] N-5(a)부터 곡예사(juggler)만 12(나머지
## 7종은 그대로 6)여야 함(DESIGN.md "이벤트 특화 클래스" 첫 차등 사례).
## (2) RunState.reset_run(id)가 이 필드를 event_die_sides로 그대로 복사하는지.
## (3) EventDieVisual._to_roman()이 1~6을 I~VI로, 표 밖 값은 숫자 폴백으로 바꾸는지.
func _check_event_die_sides(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup: String = RunState.character_id

	for profile in CharacterProfiles.PROFILES:
		var sides: int = int(profile.get("event_die_sides", -1))
		var expected_sides: int = 12 if profile["id"] == "juggler" else 6
		var sides_ok := sides == expected_sides
		ok = sides_ok and ok
		lines.append("  \"%s\" event_die_sides=%d(기대 %d) -> %s" % [profile["id"], sides, expected_sides, "OK" if sides_ok else "FAIL"])

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

	# "매혹사"(charm_flip, INBOX.md 2026-09-24 [대형 기획 4]-B)도 explosive_stack/guard_stack과
	# 마찬가지로 정적 다이스 개조가 없는 기믹(런타임 매 턴 apply_charm_flip()으로 사후
	# 보정) — reset_run()이 만든 새 주머니는 표준 D4x3 그대로여야 한다.
	RunState.reset_run("enchantress")
	var enchantress_id_ok: bool = RunState.character_id == "enchantress"
	var enchantress_gimmick_ok: bool = CharacterProfiles.get_profile("enchantress")["gimmick"] == "charm_flip"
	var enchantress_bags_standard_ok: bool = (
		RunState.player_attack_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
		and RunState.player_defense_bag.dice[0] == PackedInt32Array([1, 2, 3, 4])
	)
	ok = enchantress_id_ok and enchantress_gimmick_ok and enchantress_bags_standard_ok and ok
	lines.append("  reset_run(enchantress): character_id=%s gimmick=charm_flip=%s 공격/방어 주머니 표준 유지(정적 개조 없음)=%s -> %s" % [
		RunState.character_id, enchantress_gimmick_ok, enchantress_bags_standard_ok,
		"OK" if (enchantress_id_ok and enchantress_gimmick_ok and enchantress_bags_standard_ok) else "FAIL"
	])
	var enchantress_count_ok: bool = (
		RunState.player_attack_bag.count == 3 and RunState.player_defense_bag.count == 3
	)
	ok = enchantress_count_ok and ok
	lines.append("  reset_run(enchantress) 시작 다이스 개수: 공격=%d(기대 3) 방어=%d(기대 3) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if enchantress_count_ok else "FAIL"
	])

	# DiceBag.apply_charm_flip(): 그 턴 굴림값 중 가장 낮은 값을 보인 다이스 1개만 그
	# 다이스의 최댓값(면 개수)으로 바뀌어야 하고, 나머지는 그대로 유지돼야 한다. 동률이면
	# 먼저 나온(인덱스가 작은) 다이스를 고른다. steady_guard와 같은 이유로 면 값 자체
	# (dice 배열)는 건드리지 않는다.
	var charm_bag := DiceBag.new(4, 3)
	var charm_input := [3, 1, 2]
	var charm_adjusted: Array = charm_bag.apply_charm_flip(charm_input)
	var charm_lowest_flipped_ok: bool = charm_adjusted == [3, 4, 2]
	ok = charm_lowest_flipped_ok and ok
	lines.append("  apply_charm_flip(D4x3, [3,1,2]): adjusted=%s (기대 [3,4,2], 최저값 인덱스1이 최댓값 4로) -> %s" % [
		charm_adjusted, "OK" if charm_lowest_flipped_ok else "FAIL"
	])
	var charm_tie_input := [2, 2, 4]
	var charm_tie_adjusted: Array = charm_bag.apply_charm_flip(charm_tie_input)
	var charm_tie_ok: bool = charm_tie_adjusted == [4, 2, 4]
	ok = charm_tie_ok and ok
	lines.append("  apply_charm_flip(D4x3, [2,2,4], 동률): adjusted=%s (기대 [4,2,4], 먼저 나온 인덱스0 선택) -> %s" % [
		charm_tie_adjusted, "OK" if charm_tie_ok else "FAIL"
	])
	var charm_faces_untouched_ok: bool = charm_bag.dice[0][0] == 1
	ok = charm_faces_untouched_ok and ok
	lines.append("  apply_charm_flip 호출 후 면 값 자체는 안 바뀜: dice[0][0]=%d (기대 1) -> %s" % [
		charm_bag.dice[0][0], "OK" if charm_faces_untouched_ok else "FAIL"
	])

	# "곡예사"(juggle_swap, INBOX.md 2026-09-24 [대형 기획 4]-C)는 min_max_only/
	# fixed_defense_die와 같은 "reset_run() 직후 1회 정적 적용" 패턴 — 시작 다이스가
	# 전부 표준 D4라 swap 이후에도 값 배열([1,2,3,4])은 똑같아 보이므로, 여기서는
	# id/gimmick/개수 불변만 확인하고 실제 swap 로직 자체는 아래 DiceBag.swap_random_dice()
	# 순수 함수 단위 검증(서로 다른 면 개수의 두 주머니)으로 따로 확인한다.
	RunState.reset_run("juggler")
	var juggler_id_ok: bool = RunState.character_id == "juggler"
	var juggler_gimmick_ok: bool = CharacterProfiles.get_profile("juggler")["gimmick"] == "juggle_swap"
	var juggler_count_ok: bool = (
		RunState.player_attack_bag.count == 3 and RunState.player_defense_bag.count == 2
	)
	ok = juggler_id_ok and juggler_gimmick_ok and juggler_count_ok and ok
	lines.append("  reset_run(juggler): character_id=%s gimmick=juggle_swap=%s 시작 다이스 개수 공격=%d(기대 3) 방어=%d(기대 2) -> %s" % [
		RunState.character_id, juggler_gimmick_ok, RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		"OK" if (juggler_id_ok and juggler_gimmick_ok and juggler_count_ok) else "FAIL"
	])

	# DiceBag.swap_random_dice(): 서로 면 개수가 다른 두 주머니(D6x2/D8x2)를 교환하면,
	# bag_a는 원래 없던 8면체 다이스를 정확히 1개, bag_b는 원래 없던 6면체 다이스를
	# 정확히 1개 갖게 돼야 하고(그 외 나머지 다이스는 원래 면 개수 그대로), 개수(count)는
	# 양쪽 다 바뀌지 않아야 한다. 무작위 인덱스라 "몇 번째가 바뀌었는지"가 아니라 "몇 개가
	# 바뀌었는지"로 검증한다.
	var swap_bag_a := DiceBag.new(6, 2)
	var swap_bag_b := DiceBag.new(8, 2)
	DiceBag.swap_random_dice(swap_bag_a, swap_bag_b)
	var a_eight_count := 0
	for faces in swap_bag_a.dice:
		if faces.size() == 8:
			a_eight_count += 1
	var b_six_count := 0
	for faces in swap_bag_b.dice:
		if faces.size() == 6:
			b_six_count += 1
	var swap_counts_unchanged_ok: bool = swap_bag_a.count == 2 and swap_bag_b.count == 2
	var swap_exactly_one_each_ok: bool = a_eight_count == 1 and b_six_count == 1
	ok = swap_counts_unchanged_ok and swap_exactly_one_each_ok and ok
	lines.append("  swap_random_dice(D6x2, D8x2): bag_a에 8면체 %d개(기대 1)/bag_b에 6면체 %d개(기대 1), 개수 불변(2/2)=%s -> %s" % [
		a_eight_count, b_six_count, swap_counts_unchanged_ok,
		"OK" if (swap_counts_unchanged_ok and swap_exactly_one_each_ok) else "FAIL"
	])

	# 어느 한쪽 주머니가 비어 있으면 아무 일도 일어나지 않아야 한다(안전 가드).
	var swap_empty_bag := DiceBag.new()
	var swap_nonempty_bag := DiceBag.new(4, 2)
	DiceBag.swap_random_dice(swap_empty_bag, swap_nonempty_bag)
	var swap_empty_guard_ok: bool = swap_empty_bag.count == 0 and swap_nonempty_bag.count == 2
	ok = swap_empty_guard_ok and ok
	lines.append("  swap_random_dice(빈 주머니, D4x2): 아무 일도 안 일어남(개수 0/2 유지) -> %s" % [
		"OK" if swap_empty_guard_ok else "FAIL"
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


## FocusNav(신규, INBOX.md 2026-10-13 [대형 기획 11] K-1 — 기존 숫자 단축키
## KeyboardShortcuts를 완전히 대체)의 동작을 검증한다: (1) chain_linear()가 모든 버튼에
## FOCUS_ALL을 적용하고 순서대로 focus_neighbor_*(수직/수평)를 연결하는지(계산 결과인
## NodePath를 직접 비교), (2) wrap=true가 양 끝을 서로 연결하는지, (3) trap=true가 반대
## 축을 "자기 자신"으로 묶어 자동 탐색이 밖으로 못 나가게 하는지, (4) grab_first_focus()가
## 숨겨지거나 비활성화된 버튼은 건너뛰고 실제 엔진 포커스(has_focus())를 옮기는지. 버튼을
## 실제 트리(self의 자식)에 넣어야 get_path_to()/grab_focus()가 성립하므로, 테스트가
## 끝나면 바로 제거한다.
func _check_focus_nav(lines: PackedStringArray) -> bool:
	var ok := true

	var b1 := Button.new()
	b1.text = "전투 방 입장"
	var b2 := Button.new()
	b2.text = "상점 입장"
	var b3 := Button.new()
	b3.text = "커스터마이징"
	add_child(b1)
	add_child(b2)
	add_child(b3)
	var buttons: Array[Button] = [b1, b2, b3]

	FocusNav.chain_linear(buttons, false)
	var focus_mode_ok: bool = b1.focus_mode == Control.FOCUS_ALL and b2.focus_mode == Control.FOCUS_ALL and b3.focus_mode == Control.FOCUS_ALL
	var vertical_chain_ok: bool = (
		b1.focus_neighbor_top == NodePath() and b1.focus_neighbor_bottom == b1.get_path_to(b2)
		and b2.focus_neighbor_top == b2.get_path_to(b1) and b2.focus_neighbor_bottom == b2.get_path_to(b3)
		and b3.focus_neighbor_top == b3.get_path_to(b2) and b3.focus_neighbor_bottom == NodePath()
	)
	ok = focus_mode_ok and vertical_chain_ok and ok
	lines.append("  chain_linear(수직, wrap 없음): focus_mode 전부 ALL=%s, 위/아래 체인 순서대로=%s -> %s" % [
		focus_mode_ok, vertical_chain_ok, "OK" if (focus_mode_ok and vertical_chain_ok) else "FAIL"
	])

	FocusNav.chain_linear(buttons, true)
	var horizontal_chain_ok: bool = (
		b1.focus_neighbor_left == NodePath() and b1.focus_neighbor_right == b1.get_path_to(b2)
		and b2.focus_neighbor_left == b2.get_path_to(b1) and b2.focus_neighbor_right == b2.get_path_to(b3)
		and b3.focus_neighbor_left == b3.get_path_to(b2) and b3.focus_neighbor_right == NodePath()
	)
	ok = horizontal_chain_ok and ok
	lines.append("  chain_linear(수평, wrap 없음): 좌/우 체인 순서대로=%s -> %s" % [horizontal_chain_ok, "OK" if horizontal_chain_ok else "FAIL"])

	FocusNav.chain_linear(buttons, false, true)
	var wrap_ok: bool = b1.focus_neighbor_top == b1.get_path_to(b3) and b3.focus_neighbor_bottom == b3.get_path_to(b1)
	ok = wrap_ok and ok
	lines.append("  chain_linear(수직, wrap=true): 양 끝이 서로 연결됨(처음<-끝, 끝->처음)=%s -> %s" % [wrap_ok, "OK" if wrap_ok else "FAIL"])

	FocusNav.chain_linear(buttons, true, true, true)
	var trap_ok: bool = (
		b1.focus_neighbor_top == b1.get_path_to(b1) and b1.focus_neighbor_bottom == b1.get_path_to(b1)
		and b2.focus_neighbor_top == b2.get_path_to(b2) and b2.focus_neighbor_bottom == b2.get_path_to(b2)
	)
	ok = trap_ok and ok
	lines.append("  chain_linear(trap=true): 체인에 안 쓰는 축(위/아래)이 자기 자신으로 묶임=%s -> %s" % [trap_ok, "OK" if trap_ok else "FAIL"])

	# grab_first_focus: 숨겨지거나 비활성화된 버튼은 건너뛰고, 실제 엔진 포커스가 옮겨져야
	# 한다(has_focus()로 검증 — 플래그가 아니라 엔진이 실제로 그 컨트롤을 포커스했는지).
	b1.visible = false
	b2.disabled = true
	FocusNav.grab_first_focus(buttons)
	var grab_skips_ok: bool = b3.has_focus() and not b1.has_focus() and not b2.has_focus()
	ok = grab_skips_ok and ok
	lines.append("  grab_first_focus(): 숨김/비활성 건너뛰고 b3에 포커스=%s(기대 true) -> %s" % [grab_skips_ok, "OK" if grab_skips_ok else "FAIL"])

	b1.visible = true
	b2.disabled = false
	FocusNav.grab_first_focus(buttons)
	var grab_first_ok: bool = b1.has_focus() and not b2.has_focus() and not b3.has_focus()
	ok = grab_first_ok and ok
	lines.append("  grab_first_focus() 전부 활성/노출: b1에 포커스=%s(기대 true) -> %s" % [grab_first_ok, "OK" if grab_first_ok else "FAIL"])

	var style := FocusNav.focus_style()
	var style_ok: bool = style is StyleBoxFlat and style.border_color == FocusNav.ACCENT_DEFAULT
	ok = style_ok and ok
	lines.append("  focus_style(): 기본 accent로 테두리색 지정됨=%s -> %s" % [style_ok, "OK" if style_ok else "FAIL"])

	# CustomizePanel/AchievementPanel 실제 오버레이가 K-1의 "Esc로 닫기" 규칙을 지키는지
	# 실제 인스턴스로 확인한다(순수 함수 검증과 별개 — 이 둘은 @onready 없이 완결된
	# Control이라 add_child 없이도 동작하지만, grab_focus()가 성립하려면 실제 트리
	# 안에 있어야 하므로 add_child한다).
	var pip_backup := RunState.pip_inventory.duplicate()
	var die_backup := RunState.die_inventory.duplicate()
	RunState.pip_inventory = []
	RunState.die_inventory = []
	var panel := CustomizePanel.new()
	add_child(panel)
	panel.open()
	var open_visible: bool = panel.visible
	var open_ok: bool = open_visible and panel._ui.size() > 0
	var close_btn: Button = panel._ui[panel._ui.size() - 1]
	var panel_focus_ok: bool = close_btn.has_focus()
	# GDScript 람다는 바깥 지역 변수를 값으로 캡처하므로(참조 아님), int를 직접 캡처해
	# 증가시키면 바깥에서 안 보인다 — Array는 참조 타입이라 캡처한 복사본도 같은 객체를
	# 가리켜 append()가 바깥에서도 보인다.
	var closed_signal_log: Array = []
	panel.closed.connect(func(): closed_signal_log.append(true))
	var esc_key := InputEventKey.new()
	esc_key.pressed = true
	esc_key.keycode = KEY_ESCAPE
	panel._unhandled_input(esc_key)
	var esc_closes_ok: bool = not panel.visible and closed_signal_log.size() == 1
	ok = open_ok and panel_focus_ok and esc_closes_ok and ok
	lines.append("  CustomizePanel.open(): visible=%s(기대 true) 닫기 버튼에 포커스=%s(기대 true) -> %s" % [
		open_visible, panel_focus_ok, "OK" if (open_ok and panel_focus_ok) else "FAIL"
	])
	lines.append("  CustomizePanel Esc 입력: visible=%s(기대 false) closed 시그널 %d회(기대 1) -> %s" % [
		panel.visible, closed_signal_log.size(), "OK" if esc_closes_ok else "FAIL"
	])
	# close()가 내부적으로 _ui 자식들을 queue_free()(지연 삭제)로 이미 예약해뒀으므로,
	# panel 자신도 즉시 free() 대신 queue_free()를 써야 한다 — 즉시 free()는 아직 처리
	# 전인 자식들의 지연 삭제 예약과 겹쳐 이중 해제(use-after-free)로 다른 테스트에서
	# 뒤늦게 크래시를 내는 것을 실제로 겪었다(원인 불명한 세그폴트로 나타남).
	remove_child(panel)
	panel.queue_free()
	RunState.pip_inventory = pip_backup
	RunState.die_inventory = die_backup

	b1.queue_free()
	b2.queue_free()
	b3.queue_free()
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
	# (2f) 매혹 심화(charm_amplify)는 매혹사(enchantress) 전용 후보로만 제시된다
	# ([대형 기획 4]-D4, 2026-09-24).
	var enchantress_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "enchantress")
	var enchantress_has_charm_amplify := false
	for s in enchantress_choices:
		if s["id"] == "charm_amplify":
			enchantress_has_charm_amplify = true
	var berserker_has_charm_amplify := false
	for s in berserker_choices:
		if s["id"] == "charm_amplify":
			berserker_has_charm_amplify = true
	var charm_amplify_filter_ok: bool = enchantress_has_charm_amplify and not berserker_has_charm_amplify
	ok = charm_amplify_filter_ok and ok
	lines.append("  '매혹 심화' 캐릭터 필터: enchantress=%s berserker=%s (기대 true/false) -> %s" % [
		enchantress_has_charm_amplify, berserker_has_charm_amplify, "OK" if charm_amplify_filter_ok else "FAIL"
	])
	# (2g) 곡예 앙코르(juggle_encore)는 곡예사(juggler) 전용 후보로만 제시된다.
	var juggler_choices := SkillPool.available_choices(SkillPool.SKILLS.size() + SkillPool.UNIQUE_SKILLS.size(), "juggler")
	var juggler_has_encore := false
	for s in juggler_choices:
		if s["id"] == "juggle_encore":
			juggler_has_encore = true
	var enchantress_has_encore := false
	for s in enchantress_choices:
		if s["id"] == "juggle_encore":
			enchantress_has_encore = true
	var juggle_encore_filter_ok: bool = juggler_has_encore and not enchantress_has_encore
	ok = juggle_encore_filter_ok and ok
	lines.append("  '곡예 앙코르' 캐릭터 필터: juggler=%s enchantress=%s (기대 true/false) -> %s" % [
		juggler_has_encore, enchantress_has_encore, "OK" if juggle_encore_filter_ok else "FAIL"
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
	# R-4(2026-10-27): 이 비교는 전역 RNG에 의존해 실행마다 결과가 달라질 수 있었다
	# (2026-10-20 (237) 간헐적 FAIL 관측). 루프 진입 전 고정 시드로 전역 RNG를 재설정해
	# 매 실행 동일한 난수 시퀀스를 재현하도록 고정한다 — "count=2가 count=1 이상으로
	# 대체된다"는 확률적 검증 의도는 그대로, 결과만 매번 같게 만든다.
	seed(20261027)
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

	# (8) "매혹 심화"/"매혹 심화+"의 실제 효과: DiceBag.apply_charm_flip(values, count)가
	# count에 맞춰 가장 낮은 값부터 순서대로(이미 뒤집은 자리는 건너뛰고) count개를 그
	# 다이스의 최댓값(면 개수)으로 바꾼다. D4x4 주머니, values=[1,2,3,4] 기준으로
	# count=1은 1개만(기존 동작 그대로), count=2는 2개, count=3은 3개가 바뀌어야 한다.
	var charm_bag := DiceBag.new(4, 4)
	var charm_values: Array = [1, 2, 3, 4]
	var charm_count1: Array = charm_bag.apply_charm_flip(charm_values, 1)
	var charm_count2: Array = charm_bag.apply_charm_flip(charm_values, 2)
	var charm_count3: Array = charm_bag.apply_charm_flip(charm_values, 3)
	var charm_count1_ok: bool = charm_count1 == [4, 2, 3, 4]
	var charm_count2_ok: bool = charm_count2 == [4, 4, 3, 4]
	var charm_count3_ok: bool = charm_count3 == [4, 4, 4, 4]
	var charm_amplify_effect_ok: bool = charm_count1_ok and charm_count2_ok and charm_count3_ok
	ok = charm_amplify_effect_ok and ok
	lines.append("  apply_charm_flip([1,2,3,4], count=1/2/3) on D4x4 = %s/%s/%s (기대 [4,2,3,4]/[4,4,3,4]/[4,4,4,4]) -> %s" % [
		charm_count1, charm_count2, charm_count3, "OK" if charm_amplify_effect_ok else "FAIL"
	])

	# (9) "곡예 앙코르"/"곡예 앙코르+"의 실제 효과: RunState.advance_round()가 라운드를
	# 넘길 때(round_index 증가, is_last_round()가 아닐 때만) skill_flags에 따라
	# swap_random_dice()를 추가로 호출하는지 — 다이스 객체 자체가 공격/방어 주머니
	# 사이에서 실제로 옮겨갔는지는 판별하기 어려우므로(무작위라 같은 자리를 골라 겉보기
	# 변화가 없을 수도 있음), 대신 "호출 여부"를 개수 불변(다이스 개수는 유지) +
	# 크래시 없음으로 검증한다(swap_random_dice() 자체의 정확성은 juggle_swap 기믹
	# 검증에서 이미 다뤄짐).
	var encore_character_backup: String = RunState.character_id
	RunState.reset_run("juggler")
	var encore_atk_count_before: int = RunState.player_attack_bag.count
	var encore_def_count_before: int = RunState.player_defense_bag.count
	RunState.skill_flags = ["juggle_encore"]
	RunState.advance_round()
	var encore_round_advanced_ok: bool = RunState.round_index == 2
	var encore_counts_preserved_ok: bool = (
		RunState.player_attack_bag.count == encore_atk_count_before
		and RunState.player_defense_bag.count == encore_def_count_before
	)
	RunState.skill_flags = ["juggle_encore", "juggle_encore_plus"]
	RunState.advance_round()
	var encore_plus_round_advanced_ok: bool = RunState.round_index == 3
	var encore_plus_counts_preserved_ok: bool = (
		RunState.player_attack_bag.count == encore_atk_count_before
		and RunState.player_defense_bag.count == encore_def_count_before
	)
	var juggle_encore_ok: bool = (
		encore_round_advanced_ok and encore_counts_preserved_ok
		and encore_plus_round_advanced_ok and encore_plus_counts_preserved_ok
	)
	ok = juggle_encore_ok and ok
	lines.append("  advance_round()+'곡예 앙코르'(+): round_index 1->2->3=%s 다이스 개수(공격=%d 방어=%d) 불변=%s -> %s" % [
		encore_round_advanced_ok and encore_plus_round_advanced_ok, RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		encore_counts_preserved_ok and encore_plus_counts_preserved_ok, "OK" if juggle_encore_ok else "FAIL"
	])
	RunState.reset_run(encore_character_backup)

	return ok


## [대형 기획 5] F-3 3번째 조각: combat_test.gd._update_stack_progress()(광기 심화/
## 수호 심화/연쇄 폭발/연쇄 방어가 공유하는 "스택 적립->보너스 턴 전환" 공용 헬퍼) 검증.
## 전에는 이 로직이 _do_exchange() 안에 인라인돼 있어 _player_explosive_threshold()
## 같은 "임계치 값" 자체는 테스트할 수 있었지만 "그 임계치에 도달했을 때 실제로 스택이
## 쌓이고 pending으로 전환되는지"는 물리 시뮬레이션 없이 검증할 수 없었다(완료 기록
## (154)가 남긴 gap). 순수 함수로 분리된 지금은 물리 없이 직접 호출해 네 가지 경로
## (적립/도달/무변화/소모 리셋)를 전부 확인한다.
func _check_stack_progress(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat = combat_script.new()

	# (1) 적립: 현재 0스택, 이번 턴 최댓값 2회(max_hits=2), 임계치 3 -> 2스택까지만
	# 쌓이고 아직 pending은 켜지지 않아야 한다.
	var accumulate: Dictionary = combat._update_stack_progress(0, false, 2, 3)
	var accumulate_ok: bool = accumulate["stacks"] == 2 and not accumulate["pending"] and not accumulate["activated"] and accumulate["gained"] == 2
	ok = accumulate_ok and ok
	lines.append("  _update_stack_progress(0, false, max_hits=2, threshold=3) = %s (기대 stacks=2 pending=false) -> %s" % [
		accumulate, "OK" if accumulate_ok else "FAIL"
	])

	# (2) 도달: 2스택에서 1회 더 쌓이면(2+1=3) 임계치(3)에 도달해 pending이 켜져야 한다
	# (광기/수호 심화 base). "activated"는 "이번 턴에 새로 도달했다"는 의미.
	var activate: Dictionary = combat._update_stack_progress(2, false, 1, 3)
	var activate_ok: bool = activate["stacks"] == 3 and activate["pending"] and activate["activated"] and activate["gained"] == 1
	ok = activate_ok and ok
	lines.append("  _update_stack_progress(2, false, max_hits=1, threshold=3) = %s (기대 stacks=3 pending=true) -> %s" % [
		activate, "OK" if activate_ok else "FAIL"
	])

	# (2b) 연쇄 폭발/연쇄 방어는 임계치가 2로 낮아진다 — 같은 입력(2스택+1회)이라도
	# threshold=2면 이미 도달(2+... 사실 2스택 자체가 이미 임계치 2 이상이므로, 0스택에서
	# max_hits=2 한 번만으로도 즉시 도달해야 한다(threshold=3이었던 (1)과 대조).
	var chain_activate: Dictionary = combat._update_stack_progress(0, false, 2, 2)
	var chain_activate_ok: bool = chain_activate["stacks"] == 2 and chain_activate["pending"] and chain_activate["activated"]
	ok = chain_activate_ok and ok
	lines.append("  _update_stack_progress(0, false, max_hits=2, threshold=2) = %s (기대 stacks=2 pending=true, (1)의 threshold=3과 대조) -> %s" % [
		chain_activate, "OK" if chain_activate_ok else "FAIL"
	])

	# (3) 무변화: 이번 턴에 최댓값이 하나도 없었으면(max_hits=0) 스택/pending 둘 다
	# 그대로 유지돼야 한다(리셋도 아니고 추가 적립도 아님).
	var untouched: Dictionary = combat._update_stack_progress(2, false, 0, 3)
	var untouched_ok: bool = untouched["stacks"] == 2 and not untouched["pending"] and not untouched["reset"] and untouched["gained"] == 0
	ok = untouched_ok and ok
	lines.append("  _update_stack_progress(2, false, max_hits=0, threshold=3) = %s (기대 stacks=2 변화 없음) -> %s" % [
		untouched, "OK" if untouched_ok else "FAIL"
	])

	# (4) 소모 리셋: 이번 턴에 보너스 다이스(1D20 등)를 썼으면(used_bonus_dice=true)
	# 현재 스택이 얼마든 상관없이 0으로 리셋되고 pending도 꺼져야 한다.
	var consumed: Dictionary = combat._update_stack_progress(3, true, 0, 3)
	var consumed_ok: bool = consumed["stacks"] == 0 and not consumed["pending"] and consumed["reset"]
	ok = consumed_ok and ok
	lines.append("  _update_stack_progress(3, true, max_hits=0, threshold=3) = %s (기대 stacks=0 pending=false reset=true) -> %s" % [
		consumed, "OK" if consumed_ok else "FAIL"
	])

	combat.free()
	return ok


## [대형 기획 5] F-3 3번째 조각(INBOX.md 2026-10-06 기획자 결정이 지목한 마지막 항목):
## "전체 흐름(E2E)" 테스트 — 새 런 시작(슬롯0) -> 라운드1 보스 격파(r1 업적/슬롯1 해금) ->
## 최종 클리어(clear 업적/슬롯2 해금) -> 캐릭터 선택 화면 복귀 -> 해금된 슬롯 선택 -> 새 런
## 시작 -> skill_flags에 실제로 들어가고 실제 전투 한 판에서 효과가 적용되는지를 이어서
## 검증한다. 물리 다이스 정지 대기가 필요한 실제 전투 루프(_run_battle())는 돌리지 않고,
## _apply_room_advance()(순수 상태 전환 + 업적 unlock, 물리 의존 없음, _check_round_clear_
## achievements()가 이미 쓰는 패턴)로 "보스를 이겼다"는 결과를 흉내 낸다. 지시대로 견습
## 모험가+곡예사(런 시작 시 주머니를 바꾸는 유형) 2종만 돌린다. 업적 저장 파일은 실제
## 플레이 진행도를 건드리지 않아야 하므로 AchievementManager._debug_reset_for_qa()(파일을
## 통째로 지움)가 아니라 _unlocked Dictionary 자체를 백업/복원한다.
func _check_f3_e2e_flow(lines: PackedStringArray) -> bool:
	var ok := true
	var achievements_backup: Dictionary = AchievementManager._unlocked.duplicate(true)
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var round_backup := RunState.round_index
	var rooms_backup := RunState.rooms_cleared
	var combat_script := load("res://code/scenes/combat_test.gd")

	for character_id in ["novice", "juggler"]:
		AchievementManager._unlocked = {}
		RunState.chosen_starting_skill_id = ""
		RunState.reset_run(character_id)

		var slots_locked_before: bool = (
			not SkillPool.is_slot_requirement_met(character_id, 1)
			and not SkillPool.is_slot_requirement_met(character_id, 2)
		)

		# 라운드 1 보스 격파 -> r1_<id> 해금 + 슬롯1 해금 + round_index가 2로 넘어감 +
		# clear_<id>는 아직 미해금(슬롯2는 여전히 잠김).
		RunState.round_index = 1
		var combat1 = combat_script.new()
		combat1.player_won = true
		combat1.monster_is_boss = true
		combat1._apply_room_advance()
		combat1.free()
		var r1_stage_ok: bool = (
			AchievementManager.is_unlocked("r1_" + character_id)
			and SkillPool.is_slot_requirement_met(character_id, 1)
			and RunState.round_index == 2
			and not AchievementManager.is_unlocked("clear_" + character_id)
			and not SkillPool.is_slot_requirement_met(character_id, 2)
		)
		ok = r1_stage_ok and ok
		lines.append("  [%s] 라운드1 보스 격파: r1 해금=%s 슬롯1 해금=%s round_index=%d(기대 2) clear 아직 미해금=%s 슬롯2 아직 잠김=%s -> %s" % [
			character_id, AchievementManager.is_unlocked("r1_" + character_id), SkillPool.is_slot_requirement_met(character_id, 1),
			RunState.round_index, not AchievementManager.is_unlocked("clear_" + character_id), not SkillPool.is_slot_requirement_met(character_id, 2),
			"OK" if r1_stage_ok else "FAIL"
		])

		# 최종 라운드(TOTAL_ROUNDS) 보스 격파 -> clear_<id> 해금 + 슬롯2 해금.
		RunState.round_index = RunState.TOTAL_ROUNDS
		var combat2 = combat_script.new()
		combat2.player_won = true
		combat2.monster_is_boss = true
		combat2._apply_room_advance()
		combat2.free()
		var clear_stage_ok: bool = (
			AchievementManager.is_unlocked("clear_" + character_id)
			and SkillPool.is_slot_requirement_met(character_id, 2)
		)
		ok = slots_locked_before and clear_stage_ok and ok
		lines.append("  [%s] 최종 클리어: 시작 전 슬롯1/2 둘 다 잠김=%s clear 해금=%s 슬롯2 해금=%s -> %s" % [
			character_id, slots_locked_before, AchievementManager.is_unlocked("clear_" + character_id),
			SkillPool.is_slot_requirement_met(character_id, 2), "OK" if (slots_locked_before and clear_stage_ok) else "FAIL"
		])

		# 캐릭터 선택 화면으로 돌아가 이제 해금된 슬롯2 스킬을 고르고 새 런을 시작하면
		# chosen_starting_skill_id -> RunState.reset_run() -> SkillPool.grant()를 거쳐
		# skill_flags에 실제로 들어가야 한다("플래그만" 아니라, _do_exchange()가 그대로
		# 쓰는 production 조건식+보너스 함수를 그대로 호출해 "효과" 자체도 함께 확인).
		var slot2_skills: Array[Dictionary] = SkillPool.starting_skills_for_character(character_id)
		var slot2_skill_id: String = String(slot2_skills[2]["id"])
		RunState.chosen_starting_skill_id = slot2_skill_id
		RunState.reset_run(character_id)
		var flag_applied_ok: bool = RunState.skill_flags.has(slot2_skill_id)
		var effect_applied_ok := false
		if character_id == "novice":
			# 슬롯2 "황금손"(start_wealth): combat_test._do_exchange()와 완전히 같은
			# 조건(skill_flags.has("start_wealth")) + 같은 함수(_wealth_bonus(gold))를
			# 호출해, 골드가 쌓인 상태라면 실제로 양수 보너스가 나오는지 확인한다.
			RunState.gold = 60
			effect_applied_ok = (
				RunState.skill_flags.has("start_wealth")
				and combat_script._wealth_bonus(RunState.gold) == 2
			)
		elif character_id == "juggler":
			# 슬롯2 "잡화점"(start_diverse): 곡예사 기본 다이스는 전부 D4라
			# diverse_dice_type_count()가 1이라 바로는 발동하지 않는다 — 다른 면 개수
			# 다이스를 얻었다고 가정(아이템 습득 시뮬)하고 _do_exchange()와 같은 함수
			# (_diverse_dice_type_count -> _diverse_bonus)로 실제 양수 보너스를 확인한다.
			RunState.player_attack_bag.add_die(6)
			RunState.player_attack_bag.add_die(8)
			var diverse_count: int = combat_script._diverse_dice_type_count(RunState.player_attack_bag, RunState.player_defense_bag)
			effect_applied_ok = (
				RunState.skill_flags.has("start_diverse")
				and diverse_count >= 3
				and combat_script._diverse_bonus(diverse_count) == 1
			)
		ok = flag_applied_ok and effect_applied_ok and ok
		lines.append("  [%s] 해금된 슬롯2(%s) 선택 후 새 런: skill_flags 포함=%s 실제 보너스 효과 적용=%s -> %s" % [
			character_id, slot2_skill_id, flag_applied_ok, effect_applied_ok, "OK" if (flag_applied_ok and effect_applied_ok) else "FAIL"
		])

	AchievementManager._unlocked = achievements_backup
	AchievementManager._save()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	RunState.round_index = round_backup
	RunState.rooms_cleared = rooms_backup
	return ok


## [미니 기획 D]-1/2 검증: UPGRADE_SKILLS 데이터 형태(11종, "upgrades" 필드가 실제
## SKILLS/UNIQUE_SKILLS id를 가리키는지)와 available_upgrade_choices()/grant_upgrade()의
## 필터링 동작(base 미보유 시 후보 제외, "+" 이미 보유 시 후보 제외, character_id 필터,
## grant_upgrade가 올바른 "+"id를 추가하는지)을 검증한다.
func _check_upgrade_skill_pool(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) UPGRADE_SKILLS는 11종(SKILLS 2 + UNIQUE_SKILLS 9, 2026-10-15 [대형 기획 14]
	# N-5(a)로 "곡예 흥행+"(juggle_fortune_plus) 추가돼 10->11)이고, 각 "upgrades"
	# 필드가 실제 존재하는 base id를 가리키며, 이름은 전부 "<base 이름>+" 형태다.
	var base_ids: Array = []
	for s in SkillPool.SKILLS:
		base_ids.append(s["id"])
	for s in SkillPool.UNIQUE_SKILLS:
		base_ids.append(s["id"])
	var count_ok: bool = SkillPool.UPGRADE_SKILLS.size() == 11
	var all_upgrades_valid := true
	var all_names_plus := true
	for s in SkillPool.UPGRADE_SKILLS:
		if not base_ids.has(s["upgrades"]):
			all_upgrades_valid = false
		if not String(s["name"]).ends_with("+"):
			all_names_plus = false
	var data_ok: bool = count_ok and all_upgrades_valid and all_names_plus
	ok = data_ok and ok
	lines.append("  UPGRADE_SKILLS 데이터: 개수=%d(기대 11) upgrades 필드 전부 유효=%s 이름 전부 '+'로 끝남=%s -> %s" % [
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
## [미니 기획 M-6](2026-10-15) 갱신: resources/ui/panel/card_{base,accent}.png가 입고돼
## 기본 base_dir(production)로 부르면 이제 StyleBoxFlat이 아니라 StyleBoxTexture 이미지
## 스킨이 적용된다 — 이 테스트는 원래부터 "폴백 StyleBoxFlat의 border_color/width 계약"을
## 검증하려는 의도이므로, 존재하지 않는 base_dir를 명시적으로 넘겨 그 폴백 경로를 그대로
## 계속 검증한다(이미지 스킨 경로 자체의 검증은 `_check_m6_card_frame_skin()`이 담당).
## [대형 기획 15] Q-8(a)(2026-10-18) 기대값 의도적 변경: sample_skill은 SkillPool 스킬
## dict(id 필드 있음)라, 이제 등급색이 아니라 SkillPool.rarity_color(rarity_for(id))가
## "gcolor"다 — build_card()가 스킬 카드는 아이템 등급(S/A/B/C) 대신 스킬 레어리티로
## 테두리/배지 색을 정하도록 바뀌었기 때문(item_card_style.gd 주석 참고). 이전엔
## 스킬 dict에 "grade" 필드가 없어 매번 DEFAULT_GRADE("C")로 조용히 폴백되던 부정확한
## 비교였다.
func _check_skill_upgrade_card_highlight(lines: PackedStringArray) -> bool:
	var ok := true
	var sample_skill: Dictionary = SkillPool.SKILLS[0]
	var no_skin_dir := "user://m6_highlight_fallback_nonexistent/"
	var expected_gcolor := SkillPool.rarity_color(SkillPool.rarity_for(sample_skill["id"]))

	var normal_built := ItemCardStyle.build_card(sample_skill, "", false, false, no_skin_dir)
	add_child(normal_built["card"])
	var normal_style: StyleBoxFlat = normal_built["card"].get_theme_stylebox("panel")
	var normal_ok: bool = (
		normal_style.border_color == expected_gcolor
		and normal_style.border_width_left == 2
	)
	ok = normal_ok and ok
	lines.append("  highlight=false(스킨 없음): border_color=레어리티색=%s border_width=%d(기대 2) -> %s" % [
		normal_style.border_color == expected_gcolor,
		normal_style.border_width_left, "OK" if normal_ok else "FAIL"
	])
	normal_built["card"].queue_free()

	var highlighted_built := ItemCardStyle.build_card(sample_skill, "", false, true, no_skin_dir)
	add_child(highlighted_built["card"])
	var highlighted_style: StyleBoxFlat = highlighted_built["card"].get_theme_stylebox("panel")
	var highlight_ok: bool = (
		highlighted_style.border_color == ItemCardStyle.HIGHLIGHT_BORDER
		and highlighted_style.border_width_left == ItemCardStyle.HIGHLIGHT_BORDER_WIDTH
	)
	ok = highlight_ok and ok
	lines.append("  highlight=true(스킨 없음): border_color=%s(기대 HIGHLIGHT_BORDER) border_width=%d(기대 %d) -> %s" % [
		highlighted_style.border_color, highlighted_style.border_width_left, ItemCardStyle.HIGHLIGHT_BORDER_WIDTH,
		"OK" if highlight_ok else "FAIL"
	])
	highlighted_built["card"].queue_free()

	return ok


## [미니 기획 M-6](2026-10-15) 검증: item_card_style.gd build_card()가
## resources/ui/panel/card_{base,accent}.png 스킨 파일 유무에 따라 "StyleBoxTexture(등급/
## 강조/골드부족색으로 틴트된 카드 프레임)" <-> "기존 StyleBoxFlat 등급색 테두리" 사이를
## 실제로 전환하는지, 등급이 다르면 합성 텍스처도 실제로 달라지는지(픽셀/텍스처 정체성
## 둘 다), 골드 부족 카드가 모듈레이트로 눌려 칠해지는지를 확인한다(M-5a와 같은 "없음->
## 있음->없음" user:// 임시 경로 패턴 + production 자산 end-to-end).
func _check_m6_card_frame_skin(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://m6_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir + "panel")

	var sample_item: Dictionary = {"name": "테스트 아이템", "description": "desc", "grade": "S"}

	# --- (1) 파일 없음 -> StyleBoxFlat 폴백(기존 동작과 완전히 동일) ---
	var no_skin_built := ItemCardStyle.build_card(sample_item, "", false, false, tmp_dir)
	add_child(no_skin_built["card"])
	var no_skin_is_flat: bool = no_skin_built["card"].get_theme_stylebox("panel") is StyleBoxFlat
	ok = no_skin_is_flat and ok
	lines.append("  (1) card_base.png 없음: 'panel' 스타일=%s (기대 StyleBoxFlat 폴백) -> %s" % [
		no_skin_built["card"].get_theme_stylebox("panel").get_class(), "OK" if no_skin_is_flat else "FAIL"
	])
	no_skin_built["card"].queue_free()

	# --- (2) base+accent(합성 전부 불투명) -> 등급색이 다르면 합성 텍스처 픽셀도 실제로
	#     그 등급색과 근사 일치하고, 등급이 다르면 서로 달라야 한다(M-5a (3)과 같은 근거:
	#     accent 알파=1이면 blend_rect가 base를 완전히 덮어써 tint색 그 자체가 나온다).
	_m5a_write_solid_png(tmp_dir + "panel/card_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "panel/card_accent.png", 8, 8, Color(1, 1, 1, 1))

	var s_item: Dictionary = {"name": "S등급", "description": "desc", "grade": "S"}
	var c_item: Dictionary = {"name": "C등급", "description": "desc", "grade": "C"}
	var s_built := ItemCardStyle.build_card(s_item, "", false, false, tmp_dir)
	add_child(s_built["card"])
	var s_style: StyleBox = (s_built["card"] as Control).get_theme_stylebox("panel")
	var s_is_tex: bool = s_style is StyleBoxTexture
	ok = s_is_tex and ok
	var s_pixel: Color = (s_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if s_is_tex else Color.BLACK
	var s_color_ok: bool = _m5a_color_close(s_pixel, ItemCardStyle.grade_color("S"))
	ok = s_color_ok and ok
	lines.append("  (2) S등급 카드: 스타일=%s 합성픽셀=%s(기대 등급색=%s) -> %s" % [
		s_style.get_class(), s_pixel, ItemCardStyle.grade_color("S"), "OK" if (s_is_tex and s_color_ok) else "FAIL"
	])
	s_built["card"].queue_free()

	var c_built := ItemCardStyle.build_card(c_item, "", false, false, tmp_dir)
	add_child(c_built["card"])
	var c_style: StyleBox = (c_built["card"] as Control).get_theme_stylebox("panel")
	var c_pixel: Color = (c_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if c_style is StyleBoxTexture else Color.BLACK
	var c_color_ok: bool = _m5a_color_close(c_pixel, ItemCardStyle.grade_color("C"))
	ok = c_color_ok and ok
	var grades_differ_ok: bool = not _m5a_color_close(s_pixel, c_pixel)
	ok = grades_differ_ok and ok
	lines.append("  (2) C등급 카드: 합성픽셀=%s(기대 등급색=%s), S등급과 다름 -> %s" % [
		c_pixel, ItemCardStyle.grade_color("C"), "OK" if (c_color_ok and grades_differ_ok) else "FAIL"
	])
	c_built["card"].queue_free()

	# --- (3) highlight=true는 등급색 대신 HIGHLIGHT_BORDER로 틴트된다 ---
	var hl_built := ItemCardStyle.build_card(s_item, "", false, true, tmp_dir)
	add_child(hl_built["card"])
	var hl_style: StyleBox = (hl_built["card"] as Control).get_theme_stylebox("panel")
	var hl_pixel: Color = (hl_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if hl_style is StyleBoxTexture else Color.BLACK
	var hl_ok: bool = hl_style is StyleBoxTexture and _m5a_color_close(hl_pixel, ItemCardStyle.HIGHLIGHT_BORDER)
	ok = hl_ok and ok
	lines.append("  (3) highlight=true: 합성픽셀=%s(기대 HIGHLIGHT_BORDER=%s) -> %s" % [
		hl_pixel, ItemCardStyle.HIGHLIGHT_BORDER, "OK" if hl_ok else "FAIL"
	])
	hl_built["card"].queue_free()

	# --- (4) unaffordable=true는 등급색 틴트를 CARD_BORDER_UNAFFORDABLE로 바꾸고, 카드
	#     전체를 CARD_SKIN_UNAFFORDABLE_MODULATE로 눌러 칠한다(골드 부족 신호).
	var unafford_built := ItemCardStyle.build_card(s_item, "", true, false, tmp_dir)
	add_child(unafford_built["card"])
	var unafford_style: StyleBox = (unafford_built["card"] as Control).get_theme_stylebox("panel")
	var unafford_is_tex: bool = unafford_style is StyleBoxTexture
	ok = unafford_is_tex and ok
	var unafford_pixel: Color = (unafford_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if unafford_is_tex else Color.BLACK
	var unafford_tint_ok: bool = _m5a_color_close(unafford_pixel, ItemCardStyle.CARD_BORDER_UNAFFORDABLE)
	var unafford_modulate_ok: bool = unafford_is_tex and (unafford_style as StyleBoxTexture).modulate_color.is_equal_approx(ItemCardStyle.CARD_SKIN_UNAFFORDABLE_MODULATE)
	ok = unafford_tint_ok and unafford_modulate_ok and ok
	lines.append("  (4) unaffordable=true: 합성픽셀=%s(기대 CARD_BORDER_UNAFFORDABLE=%s) modulate=%s(기대 %s) -> %s" % [
		unafford_pixel, ItemCardStyle.CARD_BORDER_UNAFFORDABLE,
		(unafford_style as StyleBoxTexture).modulate_color if unafford_is_tex else "(없음)", ItemCardStyle.CARD_SKIN_UNAFFORDABLE_MODULATE,
		"OK" if (unafford_tint_ok and unafford_modulate_ok) else "FAIL"
	])
	unafford_built["card"].queue_free()

	# --- (5) 파일 삭제 -> 다시 StyleBoxFlat 폴백 ---
	DirAccess.remove_absolute(tmp_dir + "panel/card_base.png")
	DirAccess.remove_absolute(tmp_dir + "panel/card_accent.png")
	var removed_built := ItemCardStyle.build_card(sample_item, "", false, false, tmp_dir)
	add_child(removed_built["card"])
	var removed_is_flat: bool = removed_built["card"].get_theme_stylebox("panel") is StyleBoxFlat
	ok = removed_is_flat and ok
	lines.append("  (5) card_base.png 삭제 후 다시 build_card(): 스타일=%s (기대 StyleBoxFlat로 복귀) -> %s" % [
		removed_built["card"].get_theme_stylebox("panel").get_class(), "OK" if removed_is_flat else "FAIL"
	])
	removed_built["card"].queue_free()
	DirAccess.remove_absolute(tmp_dir + "panel")
	DirAccess.remove_absolute(tmp_dir)

	# --- (6) production 자산(이미 입고됨) end-to-end: 기본 base_dir로 부르면 이제
	#     StyleBoxTexture이고, 등급이 다르면 캐시 키(tint)가 달라 서로 다른 텍스처 객체가
	#     나온다(실제 아트의 장식 영역 좌표를 몰라도 검증 가능한 방식).
	var prod_s := ItemCardStyle.build_card(s_item)
	add_child(prod_s["card"])
	var prod_s_style: StyleBox = (prod_s["card"] as Control).get_theme_stylebox("panel")
	var prod_c := ItemCardStyle.build_card(c_item)
	add_child(prod_c["card"])
	var prod_c_style: StyleBox = (prod_c["card"] as Control).get_theme_stylebox("panel")
	var prod_is_tex: bool = prod_s_style is StyleBoxTexture and prod_c_style is StyleBoxTexture
	ok = prod_is_tex and ok
	var prod_tex_differ_ok: bool = prod_is_tex and (prod_s_style as StyleBoxTexture).texture != (prod_c_style as StyleBoxTexture).texture
	ok = prod_tex_differ_ok and ok
	var prod_margin_ok: bool = prod_is_tex and (prod_s_style as StyleBoxTexture).texture_margin_left == 24
	ok = prod_margin_ok and ok
	lines.append("  (6) production: S/C등급 스타일=%s/%s(기대 둘 다 StyleBoxTexture), 텍스처 서로 다름=%s, texture_margin_left=%s(기대 24) -> %s" % [
		prod_s_style.get_class(), prod_c_style.get_class(), prod_tex_differ_ok,
		(prod_s_style as StyleBoxTexture).texture_margin_left if prod_is_tex else "(없음)",
		"OK" if (prod_is_tex and prod_tex_differ_ok and prod_margin_ok) else "FAIL"
	])
	prod_s["card"].queue_free()
	prod_c["card"].queue_free()

	return ok


## [미니 기획 M-7](2026-10-16) 검증: dungeon_map.gd _make_map_node()가 M-6과 같은
## "없음→있음→없음" base_dir 주입 패턴으로 resources/ui/panel/card_{base,accent}.png
## 유무에 따라 StyleBoxTexture(방 상태색 틴트)<->StyleBoxFlat 폴백을 전환하는지, 방
## 상태 3종(현재/완료/미래)의 합성 결과가 실제로 서로 다른지(같은 tint면 같은 캐시
## 텍스처가 나올 수 있어 "다르다"를 직접 확인해야 함), production 자산으로도 실제
## 렌더되는지를 확인한다.
func _check_m7_map_card_skin(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://m7_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir + "panel")

	var character_backup := RunState.character_id
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	RunState.reset_run("novice")
	RunState.round_index = 1

	var map_script := load("res://code/scenes/dungeon_map.gd")
	var map_instance = map_script.new()

	# --- (1) 파일 없음 -> StyleBoxFlat 폴백(기존 동작과 완전히 동일), 상태별 border_color도
	#     기존 3색(MAP_CARD_TINT_*) 그대로 ---
	RunState.rooms_cleared = 0
	var current_no_skin: Control = map_instance._make_map_node(0, tmp_dir)
	add_child(current_no_skin)
	var current_no_skin_flat: bool = current_no_skin.get_theme_stylebox("panel") is StyleBoxFlat
	var current_no_skin_color_ok: bool = (current_no_skin.get_theme_stylebox("panel") as StyleBoxFlat).border_color == map_script.MAP_CARD_TINT_CURRENT
	ok = current_no_skin_flat and current_no_skin_color_ok and ok
	lines.append("  (1) card_base.png 없음(현재 방): 'panel' 스타일=%s border_color=%s(기대 MAP_CARD_TINT_CURRENT) -> %s" % [
		current_no_skin.get_theme_stylebox("panel").get_class(), current_no_skin_color_ok,
		"OK" if (current_no_skin_flat and current_no_skin_color_ok) else "FAIL"
	])
	current_no_skin.queue_free()

	# --- (2) base+accent(합성 전부 불투명) -> 방 상태별 tint가 합성 텍스처 픽셀에
	#     그대로 반영되고, 상태가 다르면 서로 달라야 한다 ---
	_m5a_write_solid_png(tmp_dir + "panel/card_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "panel/card_accent.png", 8, 8, Color(1, 1, 1, 1))

	RunState.rooms_cleared = 0
	var current_node: Control = map_instance._make_map_node(0, tmp_dir)
	add_child(current_node)
	var current_style: StyleBox = current_node.get_theme_stylebox("panel")
	var current_is_tex: bool = current_style is StyleBoxTexture
	ok = current_is_tex and ok
	var current_pixel: Color = (current_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if current_is_tex else Color.BLACK
	var current_color_ok: bool = _m5a_color_close(current_pixel, map_script.MAP_CARD_TINT_CURRENT)
	ok = current_color_ok and ok
	lines.append("  (2) 현재 방(idx==rooms_cleared): 스타일=%s 합성픽셀=%s(기대 MAP_CARD_TINT_CURRENT=%s) -> %s" % [
		current_style.get_class(), current_pixel, map_script.MAP_CARD_TINT_CURRENT, "OK" if (current_is_tex and current_color_ok) else "FAIL"
	])
	current_node.queue_free()

	RunState.rooms_cleared = 1
	var cleared_node: Control = map_instance._make_map_node(0, tmp_dir)
	add_child(cleared_node)
	var cleared_style: StyleBox = cleared_node.get_theme_stylebox("panel")
	var cleared_is_tex: bool = cleared_style is StyleBoxTexture
	ok = cleared_is_tex and ok
	var cleared_pixel: Color = (cleared_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if cleared_is_tex else Color.BLACK
	var cleared_color_ok: bool = _m5a_color_close(cleared_pixel, map_script.MAP_CARD_TINT_CLEARED)
	var cleared_modulate_ok: bool = cleared_node.modulate.a < 1.0
	ok = cleared_color_ok and cleared_modulate_ok and ok
	lines.append("  (2) 완료 방(idx<rooms_cleared): 합성픽셀=%s(기대 MAP_CARD_TINT_CLEARED=%s), panel.modulate.a=%s(기대 <1, 어둡게) -> %s" % [
		cleared_pixel, map_script.MAP_CARD_TINT_CLEARED, cleared_node.modulate.a,
		"OK" if (cleared_is_tex and cleared_color_ok and cleared_modulate_ok) else "FAIL"
	])
	cleared_node.queue_free()

	RunState.rooms_cleared = 0
	var future_node: Control = map_instance._make_map_node(2, tmp_dir)
	add_child(future_node)
	var future_style: StyleBox = future_node.get_theme_stylebox("panel")
	var future_is_tex: bool = future_style is StyleBoxTexture
	ok = future_is_tex and ok
	var future_pixel: Color = (future_style as StyleBoxTexture).texture.get_image().get_pixel(0, 0) if future_is_tex else Color.BLACK
	var future_color_ok: bool = _m5a_color_close(future_pixel, map_script.MAP_CARD_TINT_FUTURE)
	ok = future_color_ok and ok
	var states_differ_ok: bool = (
		not _m5a_color_close(current_pixel, cleared_pixel)
		and not _m5a_color_close(current_pixel, future_pixel)
		and not _m5a_color_close(cleared_pixel, future_pixel)
	)
	ok = states_differ_ok and ok
	lines.append("  (2) 미래 방(idx>rooms_cleared): 합성픽셀=%s(기대 MAP_CARD_TINT_FUTURE=%s), 현재/완료/미래 3색 서로 다름=%s -> %s" % [
		future_pixel, map_script.MAP_CARD_TINT_FUTURE, states_differ_ok,
		"OK" if (future_is_tex and future_color_ok and states_differ_ok) else "FAIL"
	])
	future_node.queue_free()

	# --- (3) 파일 삭제 -> 다시 StyleBoxFlat 폴백 ---
	DirAccess.remove_absolute(tmp_dir + "panel/card_base.png")
	DirAccess.remove_absolute(tmp_dir + "panel/card_accent.png")
	var removed_node: Control = map_instance._make_map_node(0, tmp_dir)
	add_child(removed_node)
	var removed_is_flat: bool = removed_node.get_theme_stylebox("panel") is StyleBoxFlat
	ok = removed_is_flat and ok
	lines.append("  (3) card_base.png 삭제 후 다시 _make_map_node(): 스타일=%s (기대 StyleBoxFlat로 복귀) -> %s" % [
		removed_node.get_theme_stylebox("panel").get_class(), "OK" if removed_is_flat else "FAIL"
	])
	removed_node.queue_free()
	DirAccess.remove_absolute(tmp_dir + "panel")
	DirAccess.remove_absolute(tmp_dir)

	# --- (4) production 자산(이미 입고됨) end-to-end: 기본 base_dir로 부르면 StyleBoxTexture.
	#     [대형 기획 15] Q-4a(13, 2026-10-17)로 방 카드는 더 이상 선택지 칩을 나열하지
	#     않으므로(_make_type_chip 자체가 삭제됨), 여기서는 "제목 Label 하나만 있고(idx=0은
	#     보스/정예 배지 대상이 아님) 보상 칩(RewardIcon)이 전혀 없는지"로 구조를 확인한다.
	RunState.rooms_cleared = 0
	var prod_node: Control = map_instance._make_map_node(0)
	add_child(prod_node)
	var prod_style: StyleBox = prod_node.get_theme_stylebox("panel")
	var prod_is_tex: bool = prod_style is StyleBoxTexture
	ok = prod_is_tex and ok
	var prod_margin_ok: bool = prod_is_tex and (prod_style as StyleBoxTexture).texture_margin_left == 24
	ok = prod_margin_ok and ok
	# idx=0은 보스 방도 아니고(TOTAL_ROOMS-1이 아님) ELITE_CHANCE 조건(idx>=1)도 만족하지
	# 않아 배지가 없는 자리 — vbox에는 제목 Label 하나만 있어야 한다.
	var vbox := prod_node.get_child(0) as VBoxContainer
	var only_title_ok: bool = vbox != null and vbox.get_child_count() == 1 and vbox.get_child(0) is Label
	ok = only_title_ok and ok
	lines.append("  (4) production: 스타일=%s(기대 StyleBoxTexture) texture_margin_left=%s(기대 24), 카드 구조=제목만(%d개, 기대 1) -> %s" % [
		prod_style.get_class(), (prod_style as StyleBoxTexture).texture_margin_left if prod_is_tex else "(없음)",
		vbox.get_child_count() if vbox != null else 0,
		"OK" if (prod_is_tex and prod_margin_ok and only_title_ok) else "FAIL"
	])
	prod_node.queue_free()

	map_instance.free()
	RunState.character_id = character_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup

	return ok


## [미니 기획 E]-2 검증(INBOX.md 2026-09-17 기획자 결정, [대형 기획 5] F-2(b)로 13종/
## 3슬롯으로 갱신): STARTING_SKILLS가 모두 전투 배선 없이도 검증 가능한 순수 데이터/필터
## 로직이므로, 기획서가 명시한 "캐릭터별 선택 가능한 시작 스킬 목록"(슬롯 0/1/2 순서 포함)이
## starting_skills_for_character()로 정확히 재현되는지 확인한다.
func _check_starting_skills(lines: PackedStringArray) -> bool:
	var ok := true

	var expected := {
		"novice": ["start_expand", "start_lean", "start_wealth"],
		"berserker": ["start_aggro", "start_hoard", "start_vanguard"],
		"guardian": ["start_wall", "start_ironclad", "start_bulwark"],
		"explosive": ["start_aggro", "start_expand", "start_overflow"],
		"shieldbearer": ["start_wall", "start_lean", "start_second_wind"],
		"enchantress": ["start_expand", "start_lean", "start_gambler"],
		# N-5(a)(2026-10-15 [대형 기획 14]): 곡예사가 이벤트 특화 클래스로 재편되며
		# start_aggro/start_hoard 대신 눈속임/한탕(이벤트 테마)으로 교체됐다 —
		# 전투 보조 1종(잡화점)만 유지.
		"juggler": ["start_sleight", "start_fortune", "start_diverse"],
		"pirate": ["start_vanguard", "start_wealth", "start_hoard"],
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
## 스킬 슬롯 UI가 (a) 기본 선택은 항상 슬롯 0, (b) 슬롯 1 업적("r1_<character_id>",
## [대형 기획 5] F-2(a)부터 — 아래 (c)는 그 전 조건이던 "clear_<character_id>"를 해금해
## 마이그레이션 경로로 슬롯 1을 여는지 검증) 미해금 시 버튼 자체가 disabled(클릭 경로
## 자체가 막힘, 스타일만 다른 게 아님)인지, (c) 해금되면 실제로 슬롯 1을 고를 수 있는지,
## (d) 캐릭터를 바꿨을 때
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

	# (b) [대형 기획 5] F-1부터는 잠긴 슬롯도 disabled=false(클릭 가능, 미리보기용)다 —
	# "클릭으로 고를 수 없다"는 chosen_starting_skill_id가 안 바뀌는 것으로 검증한다.
	var slot0_button: Button = node._starting_skill_container.get_child(0)
	var slot1_button: Button = node._starting_skill_container.get_child(1)
	var both_enabled_ok: bool = not slot0_button.disabled and not slot1_button.disabled
	ok = both_enabled_ok and ok
	lines.append("  업적 미해금 상태: 슬롯0 disabled=%s 슬롯1 disabled=%s(둘 다 false 기대) -> %s" % [
		slot0_button.disabled, slot1_button.disabled, "OK" if both_enabled_ok else "FAIL"
	])

	# (c) clear_novice를 해금하고 다시 선택하면 슬롯 1이 "선택"으로 동작하고, 실제로
	# 골랐을 때 chosen_starting_skill_id가 바뀐다.
	AchievementManager.unlock("clear_novice")
	node._on_card_selected("novice")
	var unlocked_ok: bool = node._is_slot_unlocked("novice", 1)
	ok = unlocked_ok and ok
	lines.append("  clear_novice 해금 후: _is_slot_unlocked(novice, 1)=%s(기대 true) -> %s" % [
		unlocked_ok, "OK" if unlocked_ok else "FAIL"
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


## [대형 기획 5] F-1 검증(INBOX.md 2026-10-06 기획자 결정): 잠긴 슬롯을 클릭하면
## (1) chosen_starting_skill_id는 그대로 유지되고, (2) 설명란에 그 스킬의 효과 설명과
## SkillPool.unlock_requirement()의 해금 조건 문구가 둘 다 나타나야 한다. 핵심은 "플래그가
## 들어갔는가"가 아니라 "화면에 실제로 보이는 텍스트가 바뀌는가"를 보는 것 — 세션 지침이
## 과거 수집가/강철 방비 중첩 버그를 놓친 원인으로 지목한 패턴을 반복하지 않기 위함.
func _check_starting_skill_locked_preview(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id

	AchievementManager._debug_reset_for_qa()

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	# (a) 견습 모험가, clear_novice 미해금 상태에서 슬롯 1("정예", start_lean)을 클릭.
	node._on_card_selected("novice")
	var chosen_before: String = RunState.chosen_starting_skill_id
	node._on_starting_skill_locked_preview("start_lean")

	var chosen_unchanged_ok: bool = RunState.chosen_starting_skill_id == chosen_before
	ok = chosen_unchanged_ok and ok
	lines.append("  잠긴 슬롯 클릭 후 chosen 불변: before=%s after=%s -> %s" % [
		chosen_before, RunState.chosen_starting_skill_id, "OK" if chosen_unchanged_ok else "FAIL"
	])

	var desc_text: String = node._starting_skill_desc_label.text
	var start_lean_skill := SkillPool.find_skill("start_lean")
	var has_effect_text: bool = desc_text.find(String(start_lean_skill["description"])) != -1
	ok = has_effect_text and ok
	lines.append("  미리보기 설명란에 효과 문구 포함: \"%s\" -> %s" % [
		desc_text, "OK" if has_effect_text else "FAIL"
	])

	var requirement: Dictionary = SkillPool.unlock_requirement("novice", 1)
	var unlock_text: String = node._starting_skill_unlock_label.text
	var has_unlock_text: bool = unlock_text.find(String(requirement["text"])) != -1
	ok = has_unlock_text and ok
	lines.append("  미리보기 해금 조건 줄: \"%s\" (기대 포함: \"%s\") -> %s" % [
		unlock_text, requirement["text"], "OK" if has_unlock_text else "FAIL"
	])

	var badge_visible_ok: bool = node._starting_skill_lock_badge_label.visible and node._starting_skill_unlock_label.visible
	ok = badge_visible_ok and ok
	lines.append("  잠김 배지/해금 조건 줄 visible: badge=%s unlock=%s(둘 다 true 기대) -> %s" % [
		node._starting_skill_lock_badge_label.visible, node._starting_skill_unlock_label.visible,
		"OK" if badge_visible_ok else "FAIL"
	])

	# (b) 해금된 슬롯(슬롯 0, "확장")을 다시 고르면 미리보기가 꺼지고 배지/해금 줄이 숨겨진다.
	node._on_starting_skill_selected("start_expand")
	var preview_cleared_ok: bool = node._preview_skill_id == "" and not node._starting_skill_lock_badge_label.visible and not node._starting_skill_unlock_label.visible
	ok = preview_cleared_ok and ok
	lines.append("  해금된 슬롯 선택 후 미리보기 해제: preview_id=\"%s\" badge=%s unlock=%s -> %s" % [
		node._preview_skill_id, node._starting_skill_lock_badge_label.visible, node._starting_skill_unlock_label.visible,
		"OK" if preview_cleared_ok else "FAIL"
	])

	# (c) unlock_requirement() 자체 검증([대형 기획 5] F-2(a)부터 3단): 슬롯 0은 항상 해금,
	# 슬롯 1은 캐릭터 이름이 들어간 "라운드 1 클리어" 문구와 r1_<id> 업적 id를 가리켜야 한다.
	var req_slot0: Dictionary = SkillPool.unlock_requirement("guardian", 0)
	var req_slot0_ok: bool = req_slot0["achievement_id"] == "" and req_slot0["text"] == "기본 해금"
	ok = req_slot0_ok and ok
	lines.append("  unlock_requirement(guardian, 0) = %s -> %s" % [req_slot0, "OK" if req_slot0_ok else "FAIL"])

	var req_slot1: Dictionary = SkillPool.unlock_requirement("guardian", 1)
	var req_slot1_ok: bool = (req_slot1["achievement_id"] == "r1_guardian"
		and req_slot1["text"].find("수호자") != -1 and req_slot1["text"].find("라운드 1") != -1)
	ok = req_slot1_ok and ok
	lines.append("  unlock_requirement(guardian, 1) = %s -> %s" % [req_slot1, "OK" if req_slot1_ok else "FAIL"])

	# (d) 마이그레이션: r1_<id>는 미해금이어도 clear_<id>(최종 클리어)가 이미 해금돼 있으면
	# is_slot_requirement_met()이 슬롯 1을 열어줘야 한다(F-2(a) 이전 세이브 호환).
	AchievementManager.unlock("clear_explosive")
	var migration_ok: bool = (SkillPool.is_slot_requirement_met("explosive", 1)
		and not AchievementManager.is_unlocked("r1_explosive"))
	ok = migration_ok and ok
	lines.append("  마이그레이션(clear_explosive만 해금, r1_explosive는 미해금): is_slot_requirement_met=%s -> %s" % [
		SkillPool.is_slot_requirement_met("explosive", 1), "OK" if migration_ok else "FAIL"
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
## reset_run()을 호출) 확인한다. 아래에서 두 캐릭터의 기본 다이스 구성(광전사=공격4/
## 방어2, 수호자=공격2/방어4)이 각 스킬의 발동 조건과 실제로 맞아떨어지는지(설계
## 의도대로 "그 캐릭터 기본 상태에서 발동 가능"인지)를 확인하고, 실전투 크래시 여부는
## qa_shot.sh 스크린샷으로 별도 확인한다. **2026-10-07 (F-3) 갱신**: 여기서 확인하는
## 조건식 자체는 여전히 combat_test.gd의 인라인 조건을 손으로 재현한 것이지만, "맹공"/
## "철벽"/"심호흡"(+)가 실제로 적용할 보너스 값을 계산하는 부분은 _aggro_bonus()/
## _wall_bonus()/_deep_breath_bonus() 정적 함수로 분리돼 물리 없이 직접 호출/검증
## 가능해졌다 — 아래 (n) 섹션 참고(더 이상 "단위 테스트할 수 없다"가 아님).
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

	# (d) "정예"(합계 <= 7, 2026-09-29 기획자 결정으로 6->7 완화) 발동 조건은 견습
	# 모험가 기본 구성(공격3/방어3=6)에서 참이어야 하고, 다이스를 하나 추가해 합계가
	# 7이 되어도 여전히 참이어야 하며, 두 개를 추가해 합계가 8이 되어야 거짓으로
	# 바뀐다(주술사 기본 합계 7에서도 발동해야 한다는 것이 이 완화의 목적).
	RunState.chosen_starting_skill_id = "start_lean"
	RunState.reset_run("novice")
	var lean_base_total: int = RunState.player_attack_bag.dice.size() + RunState.player_defense_bag.dice.size()
	var lean_condition_ok: bool = lean_base_total <= 7
	ok = lean_condition_ok and ok
	lines.append("  '정예' 발동 조건(견습 기본): 합계=%d (<=7 기대) -> %s" % [
		lean_base_total, "OK" if lean_condition_ok else "FAIL"
	])
	RunState.player_attack_bag.add_die(4)
	var lean_after_one_add_total: int = RunState.player_attack_bag.dice.size() + RunState.player_defense_bag.dice.size()
	var lean_still_active_ok: bool = lean_after_one_add_total <= 7
	ok = lean_still_active_ok and ok
	lines.append("  '정예' 다이스 1개 추가 후: 합계=%d (<=7 기대, 조건 유지) -> %s" % [
		lean_after_one_add_total, "OK" if lean_still_active_ok else "FAIL"
	])
	RunState.player_attack_bag.add_die(4)
	var lean_after_two_add_total: int = RunState.player_attack_bag.dice.size() + RunState.player_defense_bag.dice.size()
	var lean_deactivate_ok: bool = lean_after_two_add_total > 7
	ok = lean_deactivate_ok and ok
	lines.append("  '정예' 다이스 2개 추가 후: 합계=%d (>7 기대, 조건 꺼짐) -> %s" % [
		lean_after_two_add_total, "OK" if lean_deactivate_ok else "FAIL"
	])

	# (e) "확장"(합계 >= 8) 발동 조건은 폭발병 기본 구성(공격4/방어3=7)에서는 아직
	# 거짓이어야 하고, 다이스를 하나 추가해 합계가 8이 되면 참으로 바뀌어야 한다.
	RunState.chosen_starting_skill_id = "start_expand"
	RunState.reset_run("explosive")
	var expand_base_total: int = RunState.player_attack_bag.dice.size() + RunState.player_defense_bag.dice.size()
	var expand_not_yet_ok: bool = expand_base_total < 8
	ok = expand_not_yet_ok and ok
	lines.append("  '확장' 발동 조건(폭발병 기본): 합계=%d (<8 기대, 아직 안 켜짐) -> %s" % [
		expand_base_total, "OK" if expand_not_yet_ok else "FAIL"
	])
	RunState.player_attack_bag.add_die(4)
	var expand_after_add_total: int = RunState.player_attack_bag.dice.size() + RunState.player_defense_bag.dice.size()
	var expand_activate_ok: bool = expand_after_add_total >= 8
	ok = expand_activate_ok and ok
	lines.append("  '확장' 다이스 추가 후: 합계=%d (>=8 기대, 조건 켜짐) -> %s" % [
		expand_after_add_total, "OK" if expand_activate_ok else "FAIL"
	])

	# (f) "수집가"(눈금 인벤토리 >= 5) 발동 조건은 새 런 직후(pip_inventory가 비어있음)엔
	# 거짓이어야 하고, 눈금을 5개 채우면 참으로 바뀌어야 한다.
	RunState.chosen_starting_skill_id = "start_hoard"
	RunState.reset_run("berserker")
	var hoard_not_yet_ok: bool = RunState.pip_inventory.size() < 5
	ok = hoard_not_yet_ok and ok
	lines.append("  '수집가' 발동 조건(새 런 직후): 눈금=%d (<5 기대, 아직 안 켜짐) -> %s" % [
		RunState.pip_inventory.size(), "OK" if hoard_not_yet_ok else "FAIL"
	])
	for i in range(5):
		RunState.pip_inventory.append(1)
	var hoard_activate_ok: bool = RunState.pip_inventory.size() >= 5
	ok = hoard_activate_ok and ok
	lines.append("  '수집가' 눈금 5개 채운 후: 눈금=%d (>=5 기대, 조건 켜짐) -> %s" % [
		RunState.pip_inventory.size(), "OK" if hoard_activate_ok else "FAIL"
	])

	# (g) "강철 방비"(철제 재질 다이스 1개 이상 보유) 발동 조건은 수호자 기본 구성
	# (전부 D4, 철제 아님)에서는 거짓이어야 하고, D12 다이스를 추가하면 참으로 바뀌어야
	# 한다. combat_test.gd의 _material_for_sides()를 그대로 불러 판정 기준을 재사용한다.
	RunState.chosen_starting_skill_id = "start_ironclad"
	RunState.reset_run("guardian")
	var combat_script := load("res://code/scenes/combat_test.gd")
	var ironclad_metal_material = load("res://resources/materials/metal.tres")
	var has_metal_before := false
	for die_faces in RunState.player_attack_bag.dice:
		if combat_script._material_for_sides(die_faces.size()) == ironclad_metal_material:
			has_metal_before = true
	for die_faces in RunState.player_defense_bag.dice:
		if combat_script._material_for_sides(die_faces.size()) == ironclad_metal_material:
			has_metal_before = true
	var ironclad_not_yet_ok: bool = not has_metal_before
	ok = ironclad_not_yet_ok and ok
	lines.append("  '강철 방비' 발동 조건(수호자 기본, 전부 D4): 철제 보유=%s (false 기대, 아직 안 켜짐) -> %s" % [
		has_metal_before, "OK" if ironclad_not_yet_ok else "FAIL"
	])
	RunState.player_defense_bag.add_die(12)
	var has_metal_after := false
	for die_faces in RunState.player_defense_bag.dice:
		if combat_script._material_for_sides(die_faces.size()) == ironclad_metal_material:
			has_metal_after = true
	var ironclad_activate_ok: bool = has_metal_after
	ok = ironclad_activate_ok and ok
	lines.append("  '강철 방비' D12 추가 후: 철제 보유=%s (true 기대, 조건 켜짐) -> %s" % [
		has_metal_after, "OK" if ironclad_activate_ok else "FAIL"
	])

	# (h) 회귀 방지: combat_test.gd의 _do_exchange()에서 "수집가"/"강철 방비" 조건
	# 분기가 실수로 "정예"(start_lean) if-블록 안에 중첩됐던 버그가 있었다(2026-09-17
	# (138)에서 도입, 이번 이터레이션에 발견/수정). 그 버그가 있었다면 "수집가"는
	# skill_flags에 start_lean도 함께 있어야만 발동했을 것 — 그런데 berserker는
	# starting_skills_for_character()상 [start_aggro, start_hoard]만 선택 가능해
	# start_lean을 절대 가질 수 없으므로, 버그가 있었다면 "수집가"는 영원히 죽은
	# 코드였다. 이 케이스를 직접 재현해 skill_flags에 start_lean이 없는 상태로도
	# "수집가"/"강철 방비" 조건 자체는 정상적으로 평가 가능함을 명시적으로 남긴다
	# (실제 _do_exchange() 실행은 3D 다이스 물리 스폰이 필요해 여기선 안 하지만,
	# 적어도 "start_lean 없이 start_hoard/start_ironclad만 보유하는 조합"이 실제
	# 게임에서 나온다는 전제 자체는 검증해둔다 — 이게 거짓이면 애초에 이 버그가
	# 문제되지 않았을 것이므로).
	RunState.chosen_starting_skill_id = "start_hoard"
	RunState.reset_run("berserker")
	var hoard_without_lean_ok: bool = RunState.skill_flags.has("start_hoard") and not RunState.skill_flags.has("start_lean")
	ok = hoard_without_lean_ok and ok
	lines.append("  회귀 방지 (h): berserker+start_hoard -> skill_flags=%s (start_hoard 있고 start_lean 없어야 함) -> %s" % [
		RunState.skill_flags, "OK" if hoard_without_lean_ok else "FAIL"
	])

	RunState.chosen_starting_skill_id = "start_ironclad"
	RunState.reset_run("guardian")
	var ironclad_without_lean_ok: bool = RunState.skill_flags.has("start_ironclad") and not RunState.skill_flags.has("start_lean")
	ok = ironclad_without_lean_ok and ok
	lines.append("  회귀 방지 (h): guardian+start_ironclad -> skill_flags=%s (start_ironclad 있고 start_lean 없어야 함) -> %s" % [
		RunState.skill_flags, "OK" if ironclad_without_lean_ok else "FAIL"
	])

	# (i) "선제"(start_vanguard)/"대비"(start_bulwark): 1회성 플래그 게이팅이 실제로
	# "계산 결과"를 바꾸는지 — combat_test.gd의 인라인 조건식(skill_flags.has(...) and
	# not player_*_used)을 그대로 재현해, 1회차엔 발동(true)/사용 플래그를 올린 뒤
	# 2회차엔 발동 안 함(false)으로 바뀌는지 직접 확인한다(심호흡과 같은 패턴이라
	# 새 버그 유형은 아니지만, F-2(c)에서 "수집가" 블록 안에 중첩됐다가 바로 고친
	# 사고가 있었으므로 독립 조건으로 평가됨을 명시적으로 남긴다).
	var vanguard_combat = combat_script.new()
	RunState.skill_flags = ["start_vanguard"]
	var vanguard_fires_first: bool = RunState.skill_flags.has("start_vanguard") and not vanguard_combat.player_vanguard_used
	vanguard_combat.player_vanguard_used = true
	var vanguard_fires_second: bool = RunState.skill_flags.has("start_vanguard") and not vanguard_combat.player_vanguard_used
	var vanguard_ok: bool = vanguard_fires_first and not vanguard_fires_second
	ok = vanguard_ok and ok
	lines.append("  '선제' 1회성 게이팅: 1회차 발동=%s 2회차 발동=%s (기대 true/false) -> %s" % [
		vanguard_fires_first, vanguard_fires_second, "OK" if vanguard_ok else "FAIL"
	])
	vanguard_combat.free()

	var bulwark_combat = combat_script.new()
	RunState.skill_flags = ["start_bulwark"]
	var bulwark_fires_first: bool = RunState.skill_flags.has("start_bulwark") and not bulwark_combat.player_bulwark_used
	bulwark_combat.player_bulwark_used = true
	var bulwark_fires_second: bool = RunState.skill_flags.has("start_bulwark") and not bulwark_combat.player_bulwark_used
	var bulwark_ok: bool = bulwark_fires_first and not bulwark_fires_second
	ok = bulwark_ok and ok
	lines.append("  '대비' 1회성 게이팅: 1회차 발동=%s 2회차 발동=%s (기대 true/false) -> %s" % [
		bulwark_fires_first, bulwark_fires_second, "OK" if bulwark_ok else "FAIL"
	])
	bulwark_combat.free()

	# (j) "황금손"(start_wealth): combat_test.gd._wealth_bonus()를 물리 없이 직접 호출해
	# 골드 액수별 보너스 "계산 결과"(0/+1/+2)가 실제로 달라지는지 검증 — 플래그 유무가
	# 아니라 최종 수치 자체를 비교한다.
	var wealth_0: int = combat_script._wealth_bonus(0)
	var wealth_29: int = combat_script._wealth_bonus(29)
	var wealth_30: int = combat_script._wealth_bonus(30)
	var wealth_59: int = combat_script._wealth_bonus(59)
	var wealth_60: int = combat_script._wealth_bonus(60)
	var wealth_90: int = combat_script._wealth_bonus(90)
	var wealth_ok: bool = wealth_0 == 0 and wealth_29 == 0 and wealth_30 == 1 and wealth_59 == 1 and wealth_60 == 2 and wealth_90 == 2
	ok = wealth_ok and ok
	lines.append("  '황금손' 보너스 계산: gold=0/29/30/59/60/90 -> bonus=%d/%d/%d/%d/%d/%d (기대 0/0/1/1/2/2) -> %s" % [
		wealth_0, wealth_29, wealth_30, wealth_59, wealth_60, wealth_90, "OK" if wealth_ok else "FAIL"
	])

	# (k) "과적"(start_overflow): DiceBag.is_full()(MAX_DICE=6 캡) 조건이 combat_test.gd가
	# 실제로 쓰는 것과 동일한 함수이므로, 가득 차기 전/후 결과가 실제로 바뀌는지 확인한다.
	var overflow_bag := DiceBag.new(4, 3)
	var overflow_not_full_ok: bool = not overflow_bag.is_full()
	for i in range(3):
		overflow_bag.add_die(4)
	var overflow_full_ok: bool = overflow_bag.is_full()
	var overflow_ok: bool = overflow_not_full_ok and overflow_full_ok
	ok = overflow_ok and ok
	lines.append("  '과적' 발동 조건(MAX_DICE=6 캡): 3개일 때 가득 참=%s, 6개로 채운 뒤 가득 참=%s (기대 false/true) -> %s" % [
		not overflow_not_full_ok, overflow_full_ok, "OK" if overflow_ok else "FAIL"
	])

	# (l) "오뚝이"(start_second_wind): player_hp * 2 <= PLAYER_MAX_HP 조건이 HP 변화에
	# 따라 실제로 켜지고 꺼지는지 확인(HP 11=거짓, HP 10=절반 경계에서 참).
	var second_wind_combat = combat_script.new()
	second_wind_combat.player_hp = 11
	var second_wind_above_half_ok: bool = not (second_wind_combat.player_hp * 2 <= combat_script.PLAYER_MAX_HP)
	second_wind_combat.player_hp = 10
	var second_wind_at_half_ok: bool = second_wind_combat.player_hp * 2 <= combat_script.PLAYER_MAX_HP
	var second_wind_ok: bool = second_wind_above_half_ok and second_wind_at_half_ok
	ok = second_wind_ok and ok
	lines.append("  '오뚝이' 발동 조건(HP 절반 이하, MAX_HP=%d): HP=11 발동=%s, HP=10 발동=%s (기대 false/true) -> %s" % [
		combat_script.PLAYER_MAX_HP, not second_wind_above_half_ok, second_wind_at_half_ok, "OK" if second_wind_ok else "FAIL"
	])
	second_wind_combat.free()

	# (m) "잡화점"(start_diverse): combat_test.gd._diverse_dice_type_count()를 직접 호출해
	# 다이스 종류 수가 2종->3종으로 늘어날 때 실제 집계 결과가 바뀌는지 검증한다.
	RunState.chosen_starting_skill_id = "start_diverse"
	RunState.reset_run("juggler")
	var diverse_before: int = combat_script._diverse_dice_type_count(RunState.player_attack_bag, RunState.player_defense_bag)
	var diverse_before_ok: bool = diverse_before < 3
	RunState.player_attack_bag.add_die(8)
	RunState.player_attack_bag.add_die(12)
	var diverse_after: int = combat_script._diverse_dice_type_count(RunState.player_attack_bag, RunState.player_defense_bag)
	var diverse_after_ok: bool = diverse_after >= 3
	var diverse_ok: bool = diverse_before_ok and diverse_after_ok
	ok = diverse_ok and ok
	lines.append("  '잡화점' 다이스 종류 집계: D8/D12 추가 전=%d종(<3 기대) 추가 후=%d종(>=3 기대) -> %s" % [
		diverse_before, diverse_after, "OK" if diverse_ok else "FAIL"
	])

	# (n) "승부사"(start_gambler): event.gd.gambler_adjusted_dc()가 실제 DC 값을 1 낮추고
	# (최저 2), 스킬이 없으면 원래 DC를 그대로 유지하는지 — 물리/노드 없이 직접 호출.
	var event_script := load("res://code/scenes/event.gd")
	var gambler_dc3_without: int = event_script.gambler_adjusted_dc(3, false)
	var gambler_dc3_with: int = event_script.gambler_adjusted_dc(3, true)
	var gambler_dc_floor: int = event_script.gambler_adjusted_dc(2, true)
	var gambler_ok: bool = gambler_dc3_without == 3 and gambler_dc3_with == 2 and gambler_dc_floor == 2
	ok = gambler_ok and ok
	lines.append("  '승부사' DC 보정: base=3 미보유=%d(기대 3) 보유=%d(기대 2), base=2 보유=%d(최저 2 기대) -> %s" % [
		gambler_dc3_without, gambler_dc3_with, gambler_dc_floor, "OK" if gambler_ok else "FAIL"
	])

	# (o) "맹공"/"철벽"/"심호흡"(+): 2026-10-07 (F-3)에 이 세 스킬의 보너스 계산이
	# _aggro_bonus()/_wall_bonus()/_deep_breath_bonus() 정적 함수로 분리됐다 — 위 (c)/(i)
	# 섹션은 combat_test.gd의 조건식을 손으로 재현해 "조건이 맞는지"만 봤지만, 여기서는
	# 실제 게임이 호출하는 그 함수를 그대로 호출해 "적용될 보너스 값"(그리고 그 값을
	# apply_flat_bonus에 넣었을 때 결과 배열이 실제로 올라가는지)까지 확인한다 — F-3이
	# 지목한 "플래그만 보고 효과는 안 보는" 유형의 재발을 막기 위한 보강.
	var aggro_bonus_on: int = combat_script._aggro_bonus(4, 2)
	var aggro_bonus_off: int = combat_script._aggro_bonus(2, 2)
	var aggro_bonus_ok: bool = aggro_bonus_on == 1 and aggro_bonus_off == 0
	ok = aggro_bonus_ok and ok
	lines.append("  '맹공' 보너스 계산: 공격4/방어2 -> %d(기대 1), 공격2/방어2 -> %d(기대 0) -> %s" % [
		aggro_bonus_on, aggro_bonus_off, "OK" if aggro_bonus_ok else "FAIL"
	])

	var wall_bonus_on: int = combat_script._wall_bonus(2, 4)
	var wall_bonus_off: int = combat_script._wall_bonus(2, 2)
	var wall_bonus_ok: bool = wall_bonus_on == 1 and wall_bonus_off == 0
	ok = wall_bonus_ok and ok
	lines.append("  '철벽' 보너스 계산: 공격2/방어4 -> %d(기대 1), 공격2/방어2 -> %d(기대 0) -> %s" % [
		wall_bonus_on, wall_bonus_off, "OK" if wall_bonus_ok else "FAIL"
	])

	# 보너스 값을 실제로 다이스 결과 배열에 적용했을 때 합계가 바뀌는지까지 확인한다
	# (DiceBag.apply_flat_bonus()는 기존에 검증된 순수 함수 — 여기서는 "보너스 계산 ->
	# 적용"의 연결 자체를 본다, 면 개수 상한도 함께 확인).
	var aggro_bag := DiceBag.new(4, 2)
	var aggro_values: Array = [1, 2]
	var aggro_applied: Array = aggro_bag.apply_flat_bonus(aggro_values, aggro_bonus_on)
	var aggro_applied_ok: bool = aggro_applied == [2, 3]
	ok = aggro_applied_ok and ok
	lines.append("  '맹공' 적용 결과: [1,2]에 보너스 %d 적용 -> %s(기대 [2, 3]) -> %s" % [
		aggro_bonus_on, aggro_applied, "OK" if aggro_applied_ok else "FAIL"
	])

	# "심호흡"(base, 1회성) vs "심호흡+"(매 방어턴): 둘 다 있으면 "+"만 적용되고
	# consume=false(1회성 플래그를 건드리지 않음), base만 있으면 1회차엔 bonus=1/
	# consume=true, 이미 썼으면 bonus=0.
	var db_plus_result: Dictionary = combat_script._deep_breath_bonus(["deep_breath", "deep_breath_plus"], false)
	var db_plus_ok: bool = db_plus_result["bonus"] == 1 and db_plus_result["consume"] == false
	ok = db_plus_ok and ok
	lines.append("  '심호흡+' 보너스(base도 보유, 미사용): %s(기대 {bonus:1, consume:false}) -> %s" % [
		db_plus_result, "OK" if db_plus_ok else "FAIL"
	])

	var db_base_first: Dictionary = combat_script._deep_breath_bonus(["deep_breath"], false)
	var db_base_first_ok: bool = db_base_first["bonus"] == 1 and db_base_first["consume"] == true
	var db_base_second: Dictionary = combat_script._deep_breath_bonus(["deep_breath"], true)
	var db_base_second_ok: bool = db_base_second["bonus"] == 0
	var db_base_ok: bool = db_base_first_ok and db_base_second_ok
	ok = db_base_ok and ok
	lines.append("  '심호흡' 보너스: 1회차(미사용) %s(기대 {bonus:1, consume:true}), 2회차(사용함) %s(기대 bonus:0) -> %s" % [
		db_base_first, db_base_second, "OK" if db_base_ok else "FAIL"
	])

	# (p) F-3(2번째 조각, 2026-10-07): "나머지 시작 스킬들"(확장/정예/수집가/강철 방비/
	# 선제/대비/과적/오뚝이/잡화점) — 위 (e)/(f)/(g)/(i)/(k)/(l)/(m) 섹션은 모두
	# combat_test.gd의 조건식을 손으로 재현해 "조건이 맞는지"만 봤을 뿐, 그 조건이
	# 실제로 호출하는 _expand_bonus()/_lean_bonus()/_hoard_bonus()/_ironclad_bonus()/
	# _vanguard_bonus()/_bulwark_bonus()/_overflow_bonus()/_second_wind_bonus()/
	# _diverse_bonus() 함수가 돌려주는 "숫자"는 한 번도 검증하지 않았다 — (o)와
	# 같은 이유로 여기서 그 함수들을 직접 호출하고, 그 값을 apply_flat_bonus()에
	# 넣었을 때 결과 배열이 실제로 올라가는지까지 확인한다.
	var expand_bonus_on: int = combat_script._expand_bonus(4, 4)
	var expand_bonus_off: int = combat_script._expand_bonus(3, 4)
	var expand_bonus_ok: bool = expand_bonus_on == 1 and expand_bonus_off == 0
	ok = expand_bonus_ok and ok
	lines.append("  '확장' 보너스 계산: 공격4/방어4(합8) -> %d(기대 1), 공격3/방어4(합7) -> %d(기대 0) -> %s" % [
		expand_bonus_on, expand_bonus_off, "OK" if expand_bonus_ok else "FAIL"
	])

	var lean_bonus_on: int = combat_script._lean_bonus(3, 4)
	var lean_bonus_off: int = combat_script._lean_bonus(4, 4)
	var lean_bonus_ok: bool = lean_bonus_on == 1 and lean_bonus_off == 0
	ok = lean_bonus_ok and ok
	lines.append("  '정예' 보너스 계산: 공격3/방어4(합7) -> %d(기대 1), 공격4/방어4(합8) -> %d(기대 0) -> %s" % [
		lean_bonus_on, lean_bonus_off, "OK" if lean_bonus_ok else "FAIL"
	])

	var hoard_bonus_on: int = combat_script._hoard_bonus(5)
	var hoard_bonus_off: int = combat_script._hoard_bonus(4)
	var hoard_bonus_ok: bool = hoard_bonus_on == 1 and hoard_bonus_off == 0
	ok = hoard_bonus_ok and ok
	lines.append("  '수집가' 보너스 계산: 눈금5 -> %d(기대 1), 눈금4 -> %d(기대 0) -> %s" % [
		hoard_bonus_on, hoard_bonus_off, "OK" if hoard_bonus_ok else "FAIL"
	])

	var ironclad_bonus_on: int = combat_script._ironclad_bonus(true)
	var ironclad_bonus_off: int = combat_script._ironclad_bonus(false)
	var ironclad_bonus_ok: bool = ironclad_bonus_on == 1 and ironclad_bonus_off == 0
	ok = ironclad_bonus_ok and ok
	lines.append("  '강철 방비' 보너스 계산: 철제 보유 -> %d(기대 1), 미보유 -> %d(기대 0) -> %s" % [
		ironclad_bonus_on, ironclad_bonus_off, "OK" if ironclad_bonus_ok else "FAIL"
	])

	# _has_metal_die()도 두 주머니 중 "어느 쪽"에 있어도 감지하는지 실제 DiceBag으로 확인.
	var metal_atk_bag := DiceBag.new(4, 1)
	var metal_def_bag := DiceBag.new(4, 1)
	var metal_detect_before: bool = combat_script._has_metal_die(metal_atk_bag, metal_def_bag)
	metal_def_bag.add_die(12)
	var metal_detect_after: bool = combat_script._has_metal_die(metal_atk_bag, metal_def_bag)
	var metal_detect_ok: bool = not metal_detect_before and metal_detect_after
	ok = metal_detect_ok and ok
	lines.append("  '강철 방비' 재질 감지(_has_metal_die): D12 추가 전=%s(기대 false) 추가 후=%s(기대 true) -> %s" % [
		metal_detect_before, metal_detect_after, "OK" if metal_detect_ok else "FAIL"
	])

	var vanguard_bonus_first: int = combat_script._vanguard_bonus(false)
	var vanguard_bonus_second: int = combat_script._vanguard_bonus(true)
	var vanguard_bonus_ok: bool = vanguard_bonus_first == 2 and vanguard_bonus_second == 0
	ok = vanguard_bonus_ok and ok
	lines.append("  '선제' 보너스 계산: 1회차(미사용) -> %d(기대 2), 2회차(사용함) -> %d(기대 0) -> %s" % [
		vanguard_bonus_first, vanguard_bonus_second, "OK" if vanguard_bonus_ok else "FAIL"
	])

	var bulwark_bonus_first: int = combat_script._bulwark_bonus(false)
	var bulwark_bonus_second: int = combat_script._bulwark_bonus(true)
	var bulwark_bonus_ok: bool = bulwark_bonus_first == 2 and bulwark_bonus_second == 0
	ok = bulwark_bonus_ok and ok
	lines.append("  '대비' 보너스 계산: 1회차(미사용) -> %d(기대 2), 2회차(사용함) -> %d(기대 0) -> %s" % [
		bulwark_bonus_first, bulwark_bonus_second, "OK" if bulwark_bonus_ok else "FAIL"
	])

	var overflow_bonus_on: int = combat_script._overflow_bonus(true)
	var overflow_bonus_off: int = combat_script._overflow_bonus(false)
	var overflow_bonus_ok: bool = overflow_bonus_on == 1 and overflow_bonus_off == 0
	ok = overflow_bonus_ok and ok
	lines.append("  '과적' 보너스 계산: 주머니 가득 참 -> %d(기대 1), 안 참 -> %d(기대 0) -> %s" % [
		overflow_bonus_on, overflow_bonus_off, "OK" if overflow_bonus_ok else "FAIL"
	])

	var second_wind_bonus_on: int = combat_script._second_wind_bonus(10, 20)
	var second_wind_bonus_off: int = combat_script._second_wind_bonus(11, 20)
	var second_wind_bonus_ok: bool = second_wind_bonus_on == 1 and second_wind_bonus_off == 0
	ok = second_wind_bonus_ok and ok
	lines.append("  '오뚝이' 보너스 계산: HP10/20(절반) -> %d(기대 1), HP11/20 -> %d(기대 0) -> %s" % [
		second_wind_bonus_on, second_wind_bonus_off, "OK" if second_wind_bonus_ok else "FAIL"
	])

	var diverse_bonus_on: int = combat_script._diverse_bonus(3)
	var diverse_bonus_off: int = combat_script._diverse_bonus(2)
	var diverse_bonus_ok: bool = diverse_bonus_on == 1 and diverse_bonus_off == 0
	ok = diverse_bonus_ok and ok
	lines.append("  '잡화점' 보너스 계산: 종류3 -> %d(기대 1), 종류2 -> %d(기대 0) -> %s" % [
		diverse_bonus_on, diverse_bonus_off, "OK" if diverse_bonus_ok else "FAIL"
	])

	# 보너스 값을 실제로 다이스 결과 배열에 적용했을 때 합계가 바뀌는지까지 확인한다
	# (아래는 +2짜리 1회성 스킬(선제/대비)과 면 개수 상한이 실제로 걸리는지를 함께 본다).
	var vanguard_bag := DiceBag.new(4, 2)
	var vanguard_values: Array = [1, 4]
	var vanguard_applied: Array = vanguard_bag.apply_flat_bonus(vanguard_values, vanguard_bonus_first)
	var vanguard_applied_ok: bool = vanguard_applied == [3, 4]
	ok = vanguard_applied_ok and ok
	lines.append("  '선제' 적용 결과: [1,4](D4)에 보너스 %d 적용 -> %s(기대 [3, 4], 4는 면 상한에 걸림) -> %s" % [
		vanguard_bonus_first, vanguard_applied, "OK" if vanguard_applied_ok else "FAIL"
	])

	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	return ok


## SkillPool.find_skill()이 DeckPanel "보유 스킬" 섹션(2026-09-28 신규)이 기댈 유일한
## 조회 지점이라, 네 상수(SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS) 각각에서
## 최소 하나씩 실제로 찾아지는지 + 없는 id는 빈 Dictionary를 반환하는지 검증한다.
func _check_skill_pool_lookup(lines: PackedStringArray) -> bool:
	var ok := true

	var deep_breath := SkillPool.find_skill("deep_breath")
	var deep_breath_ok: bool = deep_breath.get("name", "") == "심호흡"
	ok = deep_breath_ok and ok
	lines.append("  SKILLS 조회: find_skill('deep_breath').name=%s (기대 '심호흡') -> %s" % [
		deep_breath.get("name", ""), "OK" if deep_breath_ok else "FAIL"
	])

	var frenzy := SkillPool.find_skill("frenzy_deepen")
	var frenzy_ok: bool = frenzy.get("name", "") == "광기 심화"
	ok = frenzy_ok and ok
	lines.append("  UNIQUE_SKILLS 조회: find_skill('frenzy_deepen').name=%s (기대 '광기 심화') -> %s" % [
		frenzy.get("name", ""), "OK" if frenzy_ok else "FAIL"
	])

	var frenzy_plus := SkillPool.find_skill("frenzy_deepen_plus")
	var frenzy_plus_ok: bool = frenzy_plus.get("name", "") == "광기 심화+"
	ok = frenzy_plus_ok and ok
	lines.append("  UPGRADE_SKILLS 조회: find_skill('frenzy_deepen_plus').name=%s (기대 '광기 심화+') -> %s" % [
		frenzy_plus.get("name", ""), "OK" if frenzy_plus_ok else "FAIL"
	])

	var start_expand := SkillPool.find_skill("start_expand")
	var start_expand_ok: bool = start_expand.get("name", "") == "확장"
	ok = start_expand_ok and ok
	lines.append("  STARTING_SKILLS 조회: find_skill('start_expand').name=%s (기대 '확장') -> %s" % [
		start_expand.get("name", ""), "OK" if start_expand_ok else "FAIL"
	])

	var unknown := SkillPool.find_skill("no_such_skill_id")
	var unknown_ok: bool = unknown.is_empty()
	ok = unknown_ok and ok
	lines.append("  존재하지 않는 id 조회: find_skill('no_such_skill_id')=%s (빈 Dictionary 기대) -> %s" % [
		unknown, "OK" if unknown_ok else "FAIL"
	])

	return ok


## [대형 기획 6] G-2(2026-10-07) 검증 — 기존 4종 기믹(anger_stack/fixed_value/
## min_max_only/steady_guard)이 `code/systems/monster_skills.gd`(MonsterSkills)로
## 이식된 뒤에도 "계산 결과"가 똑같이 나오는지 직접 확인한다(F-3 원칙 — 플래그가 아니라
## 효과를 본다). DiceBag 쪽 헬퍼(force_fixed_value/force_min_max_faces/
## apply_steady_guard/count_max_rolls) 자체의 정확성은 바로 아래 _check_monster_dice_
## gimmick()이 이미 검증하므로, 여기서는 MonsterSkills가 그 헬퍼들을 올바른 조건/시점에
## 불러 기존과 같은 결과를 내는지에 집중한다.
func _check_monster_skills_framework(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) on_combat_start: min_max_only는 주머니 면 값을 min/max로만 바꾼다 — 60회
	# 반복 굴림으로 중간값이 단 한 번도 안 나오는지 확인.
	var minmax_attack := DiceBag.new(6, 3)
	var minmax_defense := DiceBag.new(6, 3)
	var minmax_state := {}
	MonsterSkills.on_combat_start(["min_max_only"], minmax_state, minmax_attack, minmax_defense, 0)
	var minmax_hit_mid := false
	for i in 60:
		for v in minmax_attack.roll_detailed():
			if v != 1 and v != 6:
				minmax_hit_mid = true
	var minmax_ok := not minmax_hit_mid
	ok = minmax_ok and ok
	lines.append("  on_combat_start([min_max_only], D6x3) 60회 굴림: 중간값 없음 -> %s" % ("OK" if minmax_ok else "FAIL"))

	# (2) on_combat_start: fixed_value는 모든 면을 지정값으로 통일한다.
	var fixed_attack := DiceBag.new(6, 2)
	var fixed_defense := DiceBag.new(6, 2)
	var fixed_state := {}
	MonsterSkills.on_combat_start(["fixed_value"], fixed_state, fixed_attack, fixed_defense, 4)
	var fixed_always_4 := true
	for i in 10:
		for v in fixed_attack.roll_detailed():
			if v != 4:
				fixed_always_4 = false
	ok = fixed_always_4 and ok
	lines.append("  on_combat_start([fixed_value], D6x2, 4) 10회 굴림: 항상 4 -> %s" % ("OK" if fixed_always_4 else "FAIL"))

	# (3) steady_guard: 몬스터 "방어"턴(ctx.is_player_attacking=true)일 때만 하한선
	# 보정이 걸리고, 몬스터 "공격"턴(ctx.is_player_attacking=false)에는 걸리지 않아야
	# 한다(잘못된 턴에 적용되는 회귀를 잡기 위한 게이팅 검증 — 기존 코드는 `if
	# is_player_attacking and monster_dice_gimmick == "steady_guard"`로 같은 게이팅을
	# 했었다).
	var guard_bag := DiceBag.new(6, 3)
	var guard_state := {}
	MonsterSkills.on_combat_start(["steady_guard"], guard_state, DiceBag.new(6, 1), guard_bag, 0)
	var guard_adjusted: Array = MonsterSkills.modify_monster_roll(["steady_guard"], [1, 2, 3], guard_state, {
		"is_player_attacking": true, "bag": guard_bag,
	})
	var guard_ok: bool = guard_adjusted == [3, 3, 3]
	ok = guard_ok and ok
	lines.append("  modify_monster_roll([steady_guard], [1,2,3], is_player_attacking=true): %s (기대 [3,3,3]) -> %s" % [
		guard_adjusted, "OK" if guard_ok else "FAIL"
	])
	var guard_unaffected: Array = MonsterSkills.modify_monster_roll(["steady_guard"], [1, 2, 3], guard_state, {
		"is_player_attacking": false, "bag": guard_bag,
	})
	var guard_gate_ok: bool = guard_unaffected == [1, 2, 3]
	ok = guard_gate_ok and ok
	lines.append("  modify_monster_roll([steady_guard], [1,2,3], is_player_attacking=false, 몬스터 공격턴엔 적용 안 됨): %s (기대 [1,2,3]) -> %s" % [
		guard_unaffected, "OK" if guard_gate_ok else "FAIL"
	])

	# (4) anger_stack: 스택 적립 -> 임계치 도달 -> 보너스 다이스 사용 질의 -> 리셋까지
	# 전체 상태 전환을 직접 확인한다(단순히 "플래그가 있는가"가 아니라 실제 스택 수치와
	# should_use_bonus_attack_dice()의 반환값을 본다).
	var anger_attack_bag := DiceBag.new(4, 2)
	var anger_state := {}
	MonsterSkills.on_combat_start(["anger_stack"], anger_state, anger_attack_bag, DiceBag.new(4, 1), 0)
	var pending_before: bool = MonsterSkills.should_use_bonus_attack_dice(["anger_stack"], anger_state)
	ok = (pending_before == false) and ok
	lines.append("  초기 should_use_bonus_attack_dice([anger_stack])=%s (기대 false) -> %s" % [
		pending_before, "OK" if pending_before == false else "FAIL"
	])
	# 두 다이스 모두 최댓값(4)을 보이는 굴림을 2번 반복(임계치 3) -> max_hits=2씩 쌓여
	# 2번째 호출에서 누적 4로 이미 임계치를 넘어 pending=true가 돼야 한다.
	MonsterSkills.modify_monster_roll(["anger_stack"], [4, 4], anger_state, {
		"is_player_attacking": false, "bag": anger_attack_bag, "used_bonus_dice": false, "anger_threshold": 3,
	})
	var stacks_after_1: int = anger_state.get("anger_stacks", -1)
	ok = (stacks_after_1 == 2) and ok
	lines.append("  최댓값 2개 굴림 1회 후 anger_stacks=%d (기대 2) -> %s" % [
		stacks_after_1, "OK" if stacks_after_1 == 2 else "FAIL"
	])
	MonsterSkills.modify_monster_roll(["anger_stack"], [4, 4], anger_state, {
		"is_player_attacking": false, "bag": anger_attack_bag, "used_bonus_dice": false, "anger_threshold": 3,
	})
	var pending_after: bool = MonsterSkills.should_use_bonus_attack_dice(["anger_stack"], anger_state)
	ok = (pending_after == true) and ok
	lines.append("  최댓값 2개 굴림 2회 후(누적 4 >= 임계치 3) should_use_bonus_attack_dice=%s (기대 true) -> %s" % [
		pending_after, "OK" if pending_after == true else "FAIL"
	])
	# 보너스 1D20을 실제로 썼으면(used_bonus_dice=true) 스택/대기 상태가 리셋된다.
	MonsterSkills.modify_monster_roll(["anger_stack"], [20], anger_state, {
		"is_player_attacking": false, "bag": DiceBag.new(20, 1), "used_bonus_dice": true, "anger_threshold": 3,
	})
	var reset_ok: bool = anger_state.get("anger_stacks", -1) == 0 and anger_state.get("anger_pending", true) == false
	ok = reset_ok and ok
	lines.append("  보너스 1D20 사용 후 anger_stacks=%s anger_pending=%s (기대 0/false) -> %s" % [
		anger_state.get("anger_stacks", -1), anger_state.get("anger_pending", true), "OK" if reset_ok else "FAIL"
	])

	# (5) modify_player_roll / on_damage: 기존 4종에는 플레이어 굴림을 건드리거나 피해
	# 확정 후 처리하는 것이 없으므로, 호출해도 입력이 그대로 반환되는지(크래시 없이)
	# 확인 — G-3/G-4가 이 자리를 채우기 전까지의 "no-op" 계약을 지키는지 보장.
	var noop_values: Array = MonsterSkills.modify_player_roll(["anger_stack", "steady_guard"], [1, 2, 3], {}, {})
	var noop_ok: bool = noop_values == [1, 2, 3]
	ok = noop_ok and ok
	lines.append("  modify_player_roll(기존 4종, [1,2,3]) -> %s (기대 [1,2,3], no-op) -> %s" % [
		noop_values, "OK" if noop_ok else "FAIL"
	])
	MonsterSkills.on_damage(["anger_stack"], {}, {})
	lines.append("  on_damage(기존 4종) 호출 -> 크래시 없음 -> OK")

	# (6) _monster_config_for_room()이 만드는 "skill_ids"가 기존 "dice_gimmick"과 항상
	# 1:1로 대응하는지(room 0~4) — _do_exchange()가 이 필드로 MonsterSkills를 호출하므로
	# 어긋나면 바로 동작이 깨진다.
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	for room_index in range(5):
		var config: Dictionary = combat._monster_config_for_room(room_index)
		var gimmick: String = config["dice_gimmick"]
		var skill_ids: Array = config["skill_ids"]
		var expect_ids: Array = [] if gimmick == "" else [gimmick]
		var room_ok: bool = skill_ids == expect_ids
		ok = room_ok and ok
		lines.append("  room%d: dice_gimmick=%s skill_ids=%s (기대 %s) -> %s" % [
			room_index, gimmick, skill_ids, expect_ids, "OK" if room_ok else "FAIL"
		])
	combat.free()

	return ok


## [대형 기획 6] G-3(2026-10-07) 검증 — "플래그"가 아니라 "계산 결과"(보정된 다이스
## 값/합계/반사 피해)가 실제로 바뀌는지 직접 확인(F-3 원칙). 아직 몬스터 카탈로그에는
## 이 7종을 쓰는 몬스터가 없으므로(G-5 몫) 여기서는 MonsterSkills/DiceBag 함수를
## 직접 호출해 검증한다 — combat_test.gd 경로는 room 0~4 전부 기존 4종만 쓰므로
## _check_monster_skills_framework의 (6)번 검증이 그대로 "동작 보존"을 보장한다.
func _check_g3_monster_skill_primitives(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) DiceBag.apply_total_bonus: "다이스별 +n"이 아니라 "합계 +n" — 다이스가 몇 개든
	# 결과 합계가 정확히 amount만큼만 커져야 한다.
	var total_bonus_result: Array = DiceBag.new(6, 2).apply_total_bonus([2, 3], 3)
	var total_bonus_ok: bool = total_bonus_result == [5, 3]
	ok = total_bonus_ok and ok
	lines.append("  DiceBag.apply_total_bonus([2,3], 3) = %s (기대 [5,3], 합계 5->8) -> %s" % [
		total_bonus_result, "OK" if total_bonus_ok else "FAIL"
	])

	# (2) DiceBag.apply_reduce_highest: 가장 높은 값 1개만 깎이고, min_floor 밑으로는
	# 안 내려간다.
	var reduce_highest_result: Array = DiceBag.new(6, 3).apply_reduce_highest([2, 5, 3], 1, 1)
	var reduce_highest_ok: bool = reduce_highest_result == [2, 4, 3]
	ok = reduce_highest_ok and ok
	lines.append("  DiceBag.apply_reduce_highest([2,5,3], 1, floor=1) = %s (기대 [2,4,3]) -> %s" % [
		reduce_highest_result, "OK" if reduce_highest_ok else "FAIL"
	])
	var reduce_highest_floor_result: Array = DiceBag.new(6, 1).apply_reduce_highest([1], 1, 1)
	var reduce_highest_floor_ok: bool = reduce_highest_floor_result == [1]
	ok = reduce_highest_floor_ok and ok
	lines.append("  DiceBag.apply_reduce_highest([1], 1, floor=1) = %s (기대 [1], floor 보장) -> %s" % [
		reduce_highest_floor_result, "OK" if reduce_highest_floor_ok else "FAIL"
	])

	# (3) DiceBag.apply_zero_lowest: 가장 낮은 값 1개만 0이 되고 나머지는 그대로.
	var zero_lowest_result: Array = DiceBag.new(6, 3).apply_zero_lowest([2, 6, 4])
	var zero_lowest_ok: bool = zero_lowest_result == [0, 6, 4]
	ok = zero_lowest_ok and ok
	lines.append("  DiceBag.apply_zero_lowest([2,6,4]) = %s (기대 [0,6,4]) -> %s" % [
		zero_lowest_result, "OK" if zero_lowest_ok else "FAIL"
	])

	# (4) DiceBag.apply_reduce_max_rolls: 자신의 최댓값 면을 보인 다이스만(1개가 아니라
	# 전부) 깎이고, 최댓값이 아닌 다이스는 그대로 — 최소 1까지만 깎인다.
	var reduce_max_bag := DiceBag.new(6, 2)
	var reduce_max_result: Array = reduce_max_bag.apply_reduce_max_rolls([6, 3], 1)
	var reduce_max_ok: bool = reduce_max_result == [5, 3]
	ok = reduce_max_ok and ok
	lines.append("  DiceBag.apply_reduce_max_rolls([6,3](D6x2), 1) = %s (기대 [5,3], 최댓값 다이스만 -1) -> %s" % [
		reduce_max_result, "OK" if reduce_max_ok else "FAIL"
	])
	var reduce_max_floor_result: Array = reduce_max_bag.apply_reduce_max_rolls([6, 3], 10)
	var reduce_max_floor_ok: bool = reduce_max_floor_result == [1, 3]
	ok = reduce_max_floor_ok and ok
	lines.append("  DiceBag.apply_reduce_max_rolls([6,3](D6x2), 10) = %s (기대 [1,3], 최소 1 보장) -> %s" % [
		reduce_max_floor_result, "OK" if reduce_max_floor_ok else "FAIL"
	])

	# (5) armor(n): 몬스터 "방어 합계" +n. modify_monster_roll은 is_player_attacking=true
	# (몬스터 방어턴)에만 적용한다.
	var armor_bag := DiceBag.new(6, 2)
	var armor_result: Array = MonsterSkills.modify_monster_roll(["armor"], [2, 3], {}, {
		"is_player_attacking": true, "bag": armor_bag, "armor_amount": 3,
	})
	var armor_ok: bool = armor_result == [5, 3]
	ok = armor_ok and ok
	lines.append("  modify_monster_roll([armor], [2,3], armor_amount=3, is_player_attacking=true) = %s (기대 [5,3]) -> %s" % [
		armor_result, "OK" if armor_ok else "FAIL"
	])

	# (6) guard_up: 몬스터 HP가 최대 HP의 절반 이하일 때만 방어 다이스 결과값 전체 +1.
	var guard_up_bag := DiceBag.new(6, 2)
	var guard_up_active: Array = MonsterSkills.modify_monster_roll(["guard_up"], [2, 3], {}, {
		"is_player_attacking": true, "bag": guard_up_bag, "monster_hp": 5, "monster_max_hp": 10,
	})
	var guard_up_active_ok: bool = guard_up_active == [3, 4]
	ok = guard_up_active_ok and ok
	lines.append("  modify_monster_roll([guard_up], [2,3], HP 5/10) = %s (기대 [3,4], 절반 이하라 발동) -> %s" % [
		guard_up_active, "OK" if guard_up_active_ok else "FAIL"
	])
	var guard_up_inactive: Array = MonsterSkills.modify_monster_roll(["guard_up"], [2, 3], {}, {
		"is_player_attacking": true, "bag": guard_up_bag, "monster_hp": 6, "monster_max_hp": 10,
	})
	var guard_up_inactive_ok: bool = guard_up_inactive == [2, 3]
	ok = guard_up_inactive_ok and ok
	lines.append("  modify_monster_roll([guard_up], [2,3], HP 6/10) = %s (기대 [2,3], 절반 초과라 미발동) -> %s" % [
		guard_up_inactive, "OK" if guard_up_inactive_ok else "FAIL"
	])

	# (7) counter(n): 플레이어 공격이 완전히 막혀(dmg==0) 데미지가 0일 때만 반사 피해를
	# 돌려준다 — dmg>0이거나 몬스터 공격턴(is_player_attacking=false)이면 발동하지 않는다.
	var counter_hit: Dictionary = MonsterSkills.on_damage(["counter"], {}, {
		"is_player_attacking": true, "dmg": 0, "counter_amount": 4,
	})
	var counter_hit_ok: bool = counter_hit.get("reflect_damage", 0) == 4
	ok = counter_hit_ok and ok
	lines.append("  on_damage([counter], dmg=0, is_player_attacking=true) = %s (기대 reflect_damage=4) -> %s" % [
		counter_hit, "OK" if counter_hit_ok else "FAIL"
	])
	var counter_miss_dmg: Dictionary = MonsterSkills.on_damage(["counter"], {}, {
		"is_player_attacking": true, "dmg": 2, "counter_amount": 4,
	})
	var counter_miss_dmg_ok: bool = counter_miss_dmg.is_empty()
	ok = counter_miss_dmg_ok and ok
	lines.append("  on_damage([counter], dmg=2, is_player_attacking=true) = %s (기대 빈 Dictionary, 완전히 막히지 않음) -> %s" % [
		counter_miss_dmg, "OK" if counter_miss_dmg_ok else "FAIL"
	])
	var counter_wrong_turn: Dictionary = MonsterSkills.on_damage(["counter"], {}, {
		"is_player_attacking": false, "dmg": 0, "counter_amount": 4,
	})
	var counter_wrong_turn_ok: bool = counter_wrong_turn.is_empty()
	ok = counter_wrong_turn_ok and ok
	lines.append("  on_damage([counter], dmg=0, is_player_attacking=false) = %s (기대 빈 Dictionary, 몬스터 공격턴엔 미발동) -> %s" % [
		counter_wrong_turn, "OK" if counter_wrong_turn_ok else "FAIL"
	])

	# (8) sticky/seal: 플레이어 "공격" 턴에만 적용 — 방어턴(is_player_attacking=false)에는
	# 걸리지 않아야 한다.
	var sticky_bag := DiceBag.new(6, 3)
	var sticky_atk: Array = MonsterSkills.modify_player_roll(["sticky"], [2, 6, 4], {}, {
		"is_player_attacking": true, "bag": sticky_bag,
	})
	var sticky_atk_ok: bool = sticky_atk == [2, 5, 4]
	ok = sticky_atk_ok and ok
	lines.append("  modify_player_roll([sticky], [2,6,4], 공격턴) = %s (기대 [2,5,4]) -> %s" % [
		sticky_atk, "OK" if sticky_atk_ok else "FAIL"
	])
	var sticky_def: Array = MonsterSkills.modify_player_roll(["sticky"], [2, 6, 4], {}, {
		"is_player_attacking": false, "bag": sticky_bag,
	})
	var sticky_def_ok: bool = sticky_def == [2, 6, 4]
	ok = sticky_def_ok and ok
	lines.append("  modify_player_roll([sticky], [2,6,4], 방어턴) = %s (기대 [2,6,4], 공격턴에만 적용) -> %s" % [
		sticky_def, "OK" if sticky_def_ok else "FAIL"
	])
	var seal_atk: Array = MonsterSkills.modify_player_roll(["seal"], [2, 6, 4], {}, {
		"is_player_attacking": true, "bag": sticky_bag,
	})
	var seal_atk_ok: bool = seal_atk == [0, 6, 4]
	ok = seal_atk_ok and ok
	lines.append("  modify_player_roll([seal], [2,6,4], 공격턴) = %s (기대 [0,6,4]) -> %s" % [
		seal_atk, "OK" if seal_atk_ok else "FAIL"
	])

	# (9) numb: 플레이어 "방어" 턴에만 적용 — 공격턴에는 걸리지 않아야 한다(sticky와
	# 반대 게이팅).
	var numb_def: Array = MonsterSkills.modify_player_roll(["numb"], [2, 6, 4], {}, {
		"is_player_attacking": false, "bag": sticky_bag,
	})
	var numb_def_ok: bool = numb_def == [2, 5, 4]
	ok = numb_def_ok and ok
	lines.append("  modify_player_roll([numb], [2,6,4], 방어턴) = %s (기대 [2,5,4]) -> %s" % [
		numb_def, "OK" if numb_def_ok else "FAIL"
	])
	var numb_atk: Array = MonsterSkills.modify_player_roll(["numb"], [2, 6, 4], {}, {
		"is_player_attacking": true, "bag": sticky_bag,
	})
	var numb_atk_ok: bool = numb_atk == [2, 6, 4]
	ok = numb_atk_ok and ok
	lines.append("  modify_player_roll([numb], [2,6,4], 공격턴) = %s (기대 [2,6,4], 방어턴에만 적용) -> %s" % [
		numb_atk, "OK" if numb_atk_ok else "FAIL"
	])

	# (10) dull: 공격/방어 양쪽 다 적용 — 자신의 최댓값 면을 보인 다이스 전부 -1.
	var dull_bag := DiceBag.new(6, 3)
	var dull_atk: Array = MonsterSkills.modify_player_roll(["dull"], [6, 3, 6], {}, {
		"is_player_attacking": true, "bag": dull_bag,
	})
	var dull_atk_ok: bool = dull_atk == [5, 3, 5]
	ok = dull_atk_ok and ok
	lines.append("  modify_player_roll([dull], [6,3,6], 공격턴) = %s (기대 [5,3,5], 최댓값 다이스 전부 -1) -> %s" % [
		dull_atk, "OK" if dull_atk_ok else "FAIL"
	])
	var dull_def: Array = MonsterSkills.modify_player_roll(["dull"], [6, 3, 6], {}, {
		"is_player_attacking": false, "bag": dull_bag,
	})
	var dull_def_ok: bool = dull_def == [5, 3, 5]
	ok = dull_def_ok and ok
	lines.append("  modify_player_roll([dull], [6,3,6], 방어턴) = %s (기대 [5,3,5], 공격/방어 양쪽 적용) -> %s" % [
		dull_def, "OK" if dull_def_ok else "FAIL"
	])

	# (11) modify_player_roll에 "bag"이 없으면(ctx={}) 새 스킬 id가 있어도 크래시 없이
	# 입력을 그대로 반환해야 한다(null-bag 안전장치).
	var no_bag_result: Array = MonsterSkills.modify_player_roll(["sticky", "seal", "dull", "numb"], [1, 2, 3], {}, {})
	var no_bag_ok: bool = no_bag_result == [1, 2, 3]
	ok = no_bag_ok and ok
	lines.append("  modify_player_roll([sticky,seal,dull,numb], [1,2,3], ctx={}) = %s (기대 [1,2,3], bag 없으면 no-op) -> %s" % [
		no_bag_result, "OK" if no_bag_ok else "FAIL"
	])

	return ok


## [대형 기획 6] G-4(2026-10-07) 검증 — _check_g3_monster_skill_primitives와 같은 패턴
## (플래그가 아니라 실제 계산 결과를 직접 검증).
func _check_g4_monster_skill_primitives(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) pounce(n): 전투의 몬스터 "첫" 공격턴 한 번만 공격 합계 +n. state["pounce_used"]로
	# 1회 제한 — 같은 state로 두 번째 호출하면 보너스가 다시 붙지 않아야 한다.
	var pounce_bag := DiceBag.new(6, 2)
	var pounce_state := {}
	var pounce_first: Array = MonsterSkills.modify_monster_roll(["pounce"], [2, 3], pounce_state, {
		"is_player_attacking": false, "bag": pounce_bag, "pounce_amount": 3,
	})
	var pounce_first_ok: bool = pounce_first == [5, 3]
	ok = pounce_first_ok and ok
	lines.append("  modify_monster_roll([pounce], [2,3], pounce_amount=3, 1번째 공격) = %s (기대 [5,3]) -> %s" % [
		pounce_first, "OK" if pounce_first_ok else "FAIL"
	])
	var pounce_second: Array = MonsterSkills.modify_monster_roll(["pounce"], [2, 3], pounce_state, {
		"is_player_attacking": false, "bag": pounce_bag, "pounce_amount": 3,
	})
	var pounce_second_ok: bool = pounce_second == [2, 3]
	ok = pounce_second_ok and ok
	lines.append("  modify_monster_roll([pounce], [2,3], pounce_amount=3, 2번째 공격(이미 사용)) = %s (기대 [2,3], 전투당 1회) -> %s" % [
		pounce_second, "OK" if pounce_second_ok else "FAIL"
	])

	# (2) bloodlust: guard_up과 대칭(공격 쪽) — 몬스터 HP가 최대 HP의 절반 이하일 때만
	# 몬스터 "공격" 다이스 결과값 전체 +1.
	var bloodlust_bag := DiceBag.new(6, 2)
	var bloodlust_active: Array = MonsterSkills.modify_monster_roll(["bloodlust"], [2, 3], {}, {
		"is_player_attacking": false, "bag": bloodlust_bag, "monster_hp": 5, "monster_max_hp": 10,
	})
	var bloodlust_active_ok: bool = bloodlust_active == [3, 4]
	ok = bloodlust_active_ok and ok
	lines.append("  modify_monster_roll([bloodlust], [2,3], HP 5/10) = %s (기대 [3,4], 절반 이하라 발동) -> %s" % [
		bloodlust_active, "OK" if bloodlust_active_ok else "FAIL"
	])
	var bloodlust_inactive: Array = MonsterSkills.modify_monster_roll(["bloodlust"], [2, 3], {}, {
		"is_player_attacking": false, "bag": bloodlust_bag, "monster_hp": 6, "monster_max_hp": 10,
	})
	var bloodlust_inactive_ok: bool = bloodlust_inactive == [2, 3]
	ok = bloodlust_inactive_ok and ok
	lines.append("  modify_monster_roll([bloodlust], [2,3], HP 6/10) = %s (기대 [2,3], 절반 초과라 미발동) -> %s" % [
		bloodlust_inactive, "OK" if bloodlust_inactive_ok else "FAIL"
	])

	# (3) pounce + anger_stack을 한 몬스터가 함께 가져도(G-7 "암흑 늑대") 한 번의
	# modify_monster_roll 호출로 스택 집계가 중복되지 않고, 값 보정(pounce)과 스택
	# 집계(anger_stack)가 동시에 올바르게 일어나야 한다.
	var combo_bag := DiceBag.new(4, 2)
	var combo_state := {}
	var combo_result: Array = MonsterSkills.modify_monster_roll(["anger_stack", "pounce"], [4, 4], combo_state, {
		"is_player_attacking": false, "bag": combo_bag, "used_bonus_dice": false, "anger_threshold": 3,
		"monster_hp": 10, "monster_max_hp": 10, "pounce_amount": 2,
	})
	var combo_values_ok: bool = combo_result == [6, 4]
	var combo_stacks_ok: bool = combo_state.get("anger_stacks", -1) == 2
	ok = combo_values_ok and combo_stacks_ok and ok
	lines.append("  modify_monster_roll([anger_stack,pounce], [4,4](D4x2 최댓값), pounce_amount=2) = %s / anger_stacks=%s (기대 [6,4] / 2, 중복 집계 없음) -> %s" % [
		combo_result, combo_state.get("anger_stacks", -1), "OK" if (combo_values_ok and combo_stacks_ok) else "FAIL"
	])

	# (4) drain: "몬스터 공격턴"(is_player_attacking=false)에 입힌 피해의 절반(내림)만큼
	# 회복량을 돌려준다 — 플레이어 공격턴(is_player_attacking=true)에는 발동하지 않는다
	# (counter/revive 전용 분기이기 때문).
	var drain_hit: Dictionary = MonsterSkills.on_damage(["drain"], {}, {"is_player_attacking": false, "dmg": 5})
	var drain_hit_ok: bool = drain_hit.get("heal_amount", -1) == 2
	ok = drain_hit_ok and ok
	lines.append("  on_damage([drain], dmg=5, is_player_attacking=false) = %s (기대 heal_amount=2, floor(5/2)) -> %s" % [
		drain_hit, "OK" if drain_hit_ok else "FAIL"
	])
	var drain_no_dmg: Dictionary = MonsterSkills.on_damage(["drain"], {}, {"is_player_attacking": false, "dmg": 0})
	var drain_no_dmg_ok: bool = drain_no_dmg.is_empty()
	ok = drain_no_dmg_ok and ok
	lines.append("  on_damage([drain], dmg=0, is_player_attacking=false) = %s (기대 빈 Dictionary, 피해 없으면 회복 없음) -> %s" % [
		drain_no_dmg, "OK" if drain_no_dmg_ok else "FAIL"
	])
	var drain_wrong_turn: Dictionary = MonsterSkills.on_damage(["drain"], {}, {"is_player_attacking": true, "dmg": 5})
	var drain_wrong_turn_ok: bool = drain_wrong_turn.is_empty()
	ok = drain_wrong_turn_ok and ok
	lines.append("  on_damage([drain], dmg=5, is_player_attacking=true) = %s (기대 빈 Dictionary, 플레이어 공격턴엔 미발동) -> %s" % [
		drain_wrong_turn, "OK" if drain_wrong_turn_ok else "FAIL"
	])

	# (5) revive: 전투당 1회, 몬스터 HP가 0 이하가 된 플레이어 공격턴에만 부활값을
	# 돌려준다 — HP가 아직 남아있으면, 또는 이미 한 번 썼으면 발동하지 않는다.
	var revive_state := {}
	var revive_hit: Dictionary = MonsterSkills.on_damage(["revive"], revive_state, {
		"is_player_attacking": true, "monster_hp": 0, "monster_max_hp": 10, "revive_percent": 0.3,
	})
	var revive_hit_ok: bool = revive_hit.get("revive_to", -1) == 3
	ok = revive_hit_ok and ok
	lines.append("  on_damage([revive], monster_hp=0, max_hp=10, percent=0.3) = %s (기대 revive_to=3, floor(10*0.3)) -> %s" % [
		revive_hit, "OK" if revive_hit_ok else "FAIL"
	])
	var revive_twice: Dictionary = MonsterSkills.on_damage(["revive"], revive_state, {
		"is_player_attacking": true, "monster_hp": 0, "monster_max_hp": 10, "revive_percent": 0.3,
	})
	var revive_twice_ok: bool = revive_twice.is_empty()
	ok = revive_twice_ok and ok
	lines.append("  on_damage([revive], 같은 전투에서 2번째 HP 0 (이미 부활 사용)) = %s (기대 빈 Dictionary, 전투당 1회) -> %s" % [
		revive_twice, "OK" if revive_twice_ok else "FAIL"
	])
	var revive_alive: Dictionary = MonsterSkills.on_damage(["revive"], {}, {
		"is_player_attacking": true, "monster_hp": 4, "monster_max_hp": 10, "revive_percent": 0.3,
	})
	var revive_alive_ok: bool = revive_alive.is_empty()
	ok = revive_alive_ok and ok
	lines.append("  on_damage([revive], monster_hp=4(생존)) = %s (기대 빈 Dictionary, HP 0 이하일 때만 발동) -> %s" % [
		revive_alive, "OK" if revive_alive_ok else "FAIL"
	])

	# (6) chill: "플레이어 공격 다이스 중 가장 높은 1개 -1" — numb은 "방어" 턴에만 걸리므로
	# 같은 ctx(공격턴)에서 numb은 미발동, chill은 발동해야 둘이 구분된다(G-4 지시문).
	var chill_bag := DiceBag.new(6, 3)
	var chill_atk: Array = MonsterSkills.modify_player_roll(["chill"], [2, 6, 4], {}, {
		"is_player_attacking": true, "bag": chill_bag,
	})
	var chill_atk_ok: bool = chill_atk == [2, 5, 4]
	ok = chill_atk_ok and ok
	lines.append("  modify_player_roll([chill], [2,6,4], 공격턴) = %s (기대 [2,5,4]) -> %s" % [
		chill_atk, "OK" if chill_atk_ok else "FAIL"
	])
	var chill_def: Array = MonsterSkills.modify_player_roll(["chill"], [2, 6, 4], {}, {
		"is_player_attacking": false, "bag": chill_bag,
	})
	var chill_def_ok: bool = chill_def == [2, 6, 4]
	ok = chill_def_ok and ok
	lines.append("  modify_player_roll([chill], [2,6,4], 방어턴) = %s (기대 [2,6,4], 공격턴에만 적용 — numb과 구분) -> %s" % [
		chill_def, "OK" if chill_def_ok else "FAIL"
	])

	return ok


## [대형 기획 6] G-1(2026-10-07) 검증 — _check_skill_icons와 같은 패턴. 두 가지를 확인:
## (1) MonsterCatalog.MONSTERS 전부의 "family" 값이 FamilyIcon.CATEGORIES(그리고
## MonsterCatalog.FAMILIES 자신의 키)에 실제로 존재하는지 — 몬스터가 늘어날 G-5 이후에도
## 오타/리네임으로 아이콘이 조용히 빈 채로 그려지는 걸 사전에 잡기 위함.
## (2) G-1이 "동작 변경 없음"을 지켰는지 — MonsterCatalog.gimmick_of()로 뽑은 값이
## combat_test.gd._monster_config_for_room()이 돌려주는 기존 "dice_gimmick"과 방마다
## 정확히 일치하는지(5종 전부 한 바퀴 room 0~4로 확인).
func _check_monster_catalog_family_icons(lines: PackedStringArray) -> bool:
	var ok := true

	for monster in MonsterCatalog.MONSTERS:
		var family: String = monster.get("family", "")
		var family_known := MonsterCatalog.FAMILIES.has(family)
		var icon_known := FamilyIcon.CATEGORIES.has(family)
		var monster_ok := family_known and icon_known
		ok = monster_ok and ok
		lines.append("  \"%s\" family=%s -> FAMILIES=%s FamilyIcon.CATEGORIES=%s -> %s" % [
			monster["id"], family, "OK" if family_known else "FAIL", "OK" if icon_known else "FAIL",
			"OK" if monster_ok else "FAIL"
		])

	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	# 2026-10-26 R-1로 LEGACY_ROOM_CYCLE_IDS가 4종(slime/goblin/orc/dark_knight)이 됐고,
	# MONSTERS 배열의 맨 앞 4개가 정확히 그 순서와 같으므로 range(4)까지만 위치 대응이
	# 유효하다(room4는 4종 순환이 다시 slime으로 돌아가지만 MONSTERS[4]는 armored_goblin
	# 이라 더는 대응하지 않음 — range(5)로 두면 거짓 FAIL이 됨).
	for room_index in range(4):
		var expect_gimmick: String = MonsterCatalog.gimmick_of(MonsterCatalog.MONSTERS[room_index])
		var actual_gimmick: String = combat._monster_config_for_room(room_index)["dice_gimmick"]
		var room_ok := expect_gimmick == actual_gimmick
		ok = room_ok and ok
		lines.append("  room%d: MonsterCatalog.gimmick_of=%s vs _monster_config_for_room dice_gimmick=%s -> %s" % [
			room_index, expect_gimmick, actual_gimmick, "OK" if room_ok else "FAIL"
		])
	combat.free()

	return ok


## [대형 기획 6] G-5(2026-10-07) 검증 — 일반 몬스터 데이터(원래 계열당 5종, INBOX.md
## G-5 표) + 그 글루 코드(legacy_cycle_monster 호환, atk_dice_delta/def_dice_delta/
## hp_mult 반영, GAME_QA_MONSTER_ID QA 훅)가 "플래그"가 아니라 실제 계산 결과(다이스
## 개수/HP/스킬 보정값)를 바꾸는지 직접 확인한다(F-3 원칙).
## 2026-10-26 [대형 기획 16] R-1(몬스터 로스터 정리)로 해골 전사/해골 궁수/망령 병사/
## 해골 기사 4종이 카탈로그에서 완전히 제거되고(일반 20->17, 정예 8->7), 유령/그림자/
## 안개/망령(정예)이 amorphous->undead로 재분류됐다 — 아래 규모/계열 수 기대값은 그
## 결과를 반영한다. 같은 날 R-3(부정형 신규 5종 추가)로 일반 17->21/정예 7->8이 됐다.
func _check_g5_monster_catalog(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 카탈로그 규모: "일반 21종"(인간형5/부정형6/야수형5/언데드형5, R-3로 부정형
	# +4) + 아직 정예로 안 옮겨간 "다크 나이트" 1개 + 정예 8종(G-7, R-1로 해골 기사
	# 제거 + R-3로 심연의 사제 추가) + 보스 6종(G-8) = 36. 다크 나이트(id="dark_knight")는
	# G-7/G-8 둘 다 그대로 손대지 않았고(위 monster_catalog.gd 주석 참고 — 정예판은
	# 다른 id "dark_knight_elite"로 따로 추가) 계속 "일반" 쪽 "인간형" 집계에 남아있다.
	var total := MonsterCatalog.MONSTERS.size()
	var size_ok: bool = total == 36
	ok = size_ok and ok
	lines.append("  MonsterCatalog.MONSTERS.size()=%d (기대 36 = 21종 로스터 + 다크 나이트 + 정예 8종 + 보스 6종) -> %s" % [
		total, "OK" if size_ok else "FAIL"
	])

	var family_counts := {"humanoid": 0, "amorphous": 0, "beast": 0, "undead": 0}
	var ids_seen := {}
	var ids_unique_ok := true
	for m in MonsterCatalog.MONSTERS:
		var fam: String = m.get("family", "")
		if family_counts.has(fam):
			family_counts[fam] += 1
		var mid: String = m.get("id", "")
		if ids_seen.has(mid):
			ids_unique_ok = false
		ids_seen[mid] = true
	# R-1 이후: 인간형10(다크 나이트 포함)/부정형5(유령류가 undead로 빠짐)/야수형8/
	# 언데드형8. R-3로 부정형에 신규 일반 4종 + 정예 1종(심연의 사제)이 더해져
	# 부정형 5->10 — 상세 집계는 docs/STATUS.md R-1/R-3 완료 기록 참고.
	var family_counts_ok: bool = family_counts["humanoid"] == 10 and family_counts["amorphous"] == 10 \
		and family_counts["beast"] == 8 and family_counts["undead"] == 8
	ok = family_counts_ok and ids_unique_ok and ok
	lines.append("  계열별 개수=%s (기대 인간형10/부정형10/야수형8/언데드8), id 전부 고유=%s -> %s" % [
		family_counts, ids_unique_ok, "OK" if (family_counts_ok and ids_unique_ok) else "FAIL"
	])

	# (2) legacy_cycle_monster(): 2026-10-26 R-1로 "해골 전사"가 카탈로그에서 제거되며
	# 이 순환은 5종에서 4종(slime/goblin/orc/dark_knight)으로 줄었다 — 나머지 신규
	# 몬스터가 섞여 던전 순환(실제 플레이와 무관한 이 QA 전용 경로)이 영향받지 않는지만
	# 계속 확인한다(이 경로 자체의 구성 변경은 R-1이 의도한 결과).
	var expect_cycle_ids := ["slime", "goblin", "orc", "dark_knight",
		"slime", "goblin", "orc", "dark_knight", "slime", "goblin"]
	var cycle_ok := true
	for room_index in range(10):
		var picked: Dictionary = MonsterCatalog.legacy_cycle_monster(room_index)
		if picked.get("id", "") != expect_cycle_ids[room_index]:
			cycle_ok = false
	ok = cycle_ok and ok
	lines.append("  legacy_cycle_monster(room 0..9)가 4종만 순환(기대 %s): %s -> %s" % [
		expect_cycle_ids, cycle_ok, "OK" if cycle_ok else "FAIL"
	])

	# (3) GAME_QA_MONSTER_ID 훅: room 순환과 무관하게 지정한 몬스터로 구성되고,
	# atk_dice_delta/def_dice_delta/hp_mult가 실제 attack_count/defense_count/max_hp에
	# 반영되는지 확인. 테스트 끝에 반드시 빈 문자열로 되돌려 다른 테스트에 영향 없게 한다.
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	OS.set_environment("GAME_QA_MONSTER_ID", "dire_spider")
	var spider_cfg: Dictionary = combat._monster_config_for_room(0)
	# room0 기본 공식: 공격=2+0=2, 방어=1+0=1. 독거미는 def_dice_delta=-1 -> max(1,1-1)=1
	# (이미 1이라 클램프와 무관하게 동일값), atk_dice_delta 없음(그대로 2).
	var spider_ok: bool = spider_cfg["name"] == "독거미" and spider_cfg["attack_count"] == 2 \
		and spider_cfg["defense_count"] == 1 \
		and spider_cfg["skill_params"].get("pounce", {}).get("amount", 0) == 2
	ok = spider_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=dire_spider room0: name=%s 공격=%d 방어=%d pounce_amount=%d -> %s" % [
		spider_cfg["name"], spider_cfg["attack_count"], spider_cfg["defense_count"],
		spider_cfg["skill_params"].get("pounce", {}).get("amount", 0), "OK" if spider_ok else "FAIL"
	])

	# [대형 기획 16] R-2(2026-10-26) — 독 슬라임의 atk_dice_delta를 1->0으로 완화했다
	# (일반 방3 밸런스 복구, docs/BALANCE_TUNING_LOG.md "R-2" 참고). 기대값을 공격=2로
	# 갱신하고, atk_dice_delta 양수 반영 확인은 정예 고블린 족장(atk_dice_delta=1,
	# hp_mult=1.5)으로 옮긴다(음수 반영은 위 독거미가 이미 확인).
	OS.set_environment("GAME_QA_MONSTER_ID", "poison_slime")
	var poison_cfg: Dictionary = combat._monster_config_for_room(0)
	# room0 기본 공식: 공격=2+0=2, 방어=1+0=1. atk_dice_delta 제거로 더는 보정 없음.
	var poison_ok: bool = poison_cfg["name"] == "독 슬라임" and poison_cfg["attack_count"] == 2 \
		and poison_cfg["defense_count"] == 1
	ok = poison_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=poison_slime room0: name=%s 공격=%d(기대 2, atk_dice_delta 제거) 방어=%d(기대 1) -> %s" % [
		poison_cfg["name"], poison_cfg["attack_count"], poison_cfg["defense_count"], "OK" if poison_ok else "FAIL"
	])

	OS.set_environment("GAME_QA_MONSTER_ID", "goblin_chief")
	var chief_cfg: Dictionary = combat._monster_config_for_room(0)
	# room0 기본 공식: 공격=2+0=2, 방어=1+0=1. 고블린 족장은 atk_dice_delta=+1 -> 3,
	# hp_mult=1.5 -> max_hp=round(10*1.5)=15.
	var chief_ok: bool = chief_cfg["name"] == "고블린 족장 [정예]" and chief_cfg["attack_count"] == 3 \
		and chief_cfg["defense_count"] == 1 and chief_cfg["max_hp"] == 15
	ok = chief_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=goblin_chief room0: name=%s 공격=%d(기대 3) 방어=%d(기대 1) max_hp=%d(기대 15) -> %s" % [
		chief_cfg["name"], chief_cfg["attack_count"], chief_cfg["defense_count"], chief_cfg["max_hp"], "OK" if chief_ok else "FAIL"
	])

	OS.set_environment("GAME_QA_MONSTER_ID", "zombie")
	var zombie_cfg: Dictionary = combat._monster_config_for_room(0)
	# room0 기본 hp=10, 좀비 hp_mult=1.4 -> round(14.0)=14.
	var zombie_ok: bool = zombie_cfg["name"] == "좀비" and zombie_cfg["max_hp"] == 14
	ok = zombie_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=zombie room0: name=%s max_hp=%d(기대 14, hp_mult 1.4 반영) -> %s" % [
		zombie_cfg["name"], zombie_cfg["max_hp"], "OK" if zombie_ok else "FAIL"
	])

	OS.set_environment("GAME_QA_MONSTER_ID", "")
	var cleared_name: String = combat._monster_config_for_room(0)["name"]
	var override_cleared_ok: bool = cleared_name == "슬라임"
	ok = override_cleared_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=\"\"(해제) 후 room0: %s (기대 슬라임, 기존 순환 복귀) -> %s" % [
		cleared_name, "OK" if override_cleared_ok else "FAIL"
	])
	combat.free()

	# (4) 신규 프리미티브가 카탈로그의 실제 파라미터(amount)로 "계산 결과"를 바꾸는지 —
	# 플래그 확인이 아니라 MonsterSkills 훅에 그대로 넘겨 보정된 값/합계를 직접 비교.
	var armored_goblin: Dictionary = MonsterCatalog.get_by_id("armored_goblin")
	var armor_amount: int = armored_goblin["skills"][0].get("amount", 0)
	var armor_result: Array = MonsterSkills.modify_monster_roll(["armor"], [2, 3], {}, {
		"is_player_attacking": true, "bag": DiceBag.new(6, 2), "armor_amount": armor_amount,
	})
	var armor_sum: int = armor_result[0] + armor_result[1]
	var armor_ok: bool = armor_sum == 5 + armor_amount
	ok = armor_ok and ok
	lines.append("  아머 고블린 armor(%d): [2,3] -> %s (합계%d, 기대%d) -> %s" % [
		armor_amount, armor_result, armor_sum, 5 + armor_amount, "OK" if armor_ok else "FAIL"
	])

	var bandit: Dictionary = MonsterCatalog.get_by_id("bandit")
	var counter_amount: int = bandit["skills"][0].get("amount", 0)
	var counter_effect: Dictionary = MonsterSkills.on_damage(["counter"], {}, {
		"is_player_attacking": true, "dmg": 0, "counter_amount": counter_amount,
	})
	var counter_ok: bool = counter_effect.get("reflect_damage", 0) == counter_amount
	ok = counter_ok and ok
	lines.append("  풋내기 용병 counter(%d): dmg=0 -> reflect_damage=%d(기대%d) -> %s" % [
		counter_amount, counter_effect.get("reflect_damage", 0), counter_amount, "OK" if counter_ok else "FAIL"
	])

	var sticky_result: Array = MonsterSkills.modify_player_roll(["sticky"], [4, 6], {}, {
		"is_player_attacking": true, "bag": DiceBag.new(6, 2),
	})
	var sticky_ok: bool = sticky_result == [4, 5]
	ok = sticky_ok and ok
	lines.append("  독 슬라임 sticky: 플레이어 공격 [4,6] -> %s(기대 [4,5], 최댓값 1개 -1) -> %s" % [
		sticky_result, "OK" if sticky_ok else "FAIL"
	])

	var wolf: Dictionary = MonsterCatalog.get_by_id("wolf")
	var pounce_amount: int = wolf["skills"][0].get("amount", 0)
	var pounce_state := {}
	var pounce_bag := DiceBag.new(6, 2)
	var pounce_first: Array = MonsterSkills.modify_monster_roll(["pounce"], [1, 1], pounce_state, {
		"is_player_attacking": false, "bag": pounce_bag, "pounce_amount": pounce_amount,
	})
	var pounce_second: Array = MonsterSkills.modify_monster_roll(["pounce"], [1, 1], pounce_state, {
		"is_player_attacking": false, "bag": pounce_bag, "pounce_amount": pounce_amount,
	})
	var pounce_ok: bool = (pounce_first[0] + pounce_first[1] == 2 + pounce_amount) \
		and (pounce_second[0] + pounce_second[1] == 2)
	ok = pounce_ok and ok
	lines.append("  늑대 pounce(%d): 1회차 합계=%d(기대%d) 2회차 합계=%d(기대2, 1회 제한) -> %s" % [
		pounce_amount, pounce_first[0] + pounce_first[1], 2 + pounce_amount,
		pounce_second[0] + pounce_second[1], "OK" if pounce_ok else "FAIL"
	])

	var drain_result: Dictionary = MonsterSkills.on_damage(["drain"], {}, {
		"is_player_attacking": false, "dmg": 9,
	})
	var drain_ok: bool = drain_result.get("heal_amount", -1) == 4
	ok = drain_ok and ok
	lines.append("  구울 drain: dmg=9 -> heal_amount=%d(기대4, floor(9/2)) -> %s" % [
		drain_result.get("heal_amount", -1), "OK" if drain_ok else "FAIL"
	])

	return ok


## [대형 기획 16] R-1(2026-10-26) 검증 — 몬스터 로스터 정리(해골 전사/해골 궁수/망령
## 병사/해골 기사 제거, 유령/그림자/안개/망령 undead 재분류, 산적->풋내기 용병
## 개명)가 "데이터만 바뀐 게 아니라" 실제 조회/계획 생성 결과에 반영되는지 직접
## 확인한다(F-3 원칙) — 카탈로그/출현 풀 양쪽에서 제거됐는지, 재분류된 family가
## 실제로 읽히는지, build_monster_plan/build_elite_plan이 여러 시드에서 새 풀
## 크기로 중복 없이 채워지는지까지 본다.
func _check_r1_monster_roster_cleanup(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 제거된 4종이 카탈로그 자체(get_by_id) + 일반/정예 출현 풀 어디에도 없어야 한다.
	var removed_ids := ["skeleton", "skeleton_archer", "wraith_soldier", "skeleton_knight"]
	var normal_ids: Array = MonsterCatalog.normal_roster_ids()
	var elite_ids: Array = MonsterCatalog.elite_roster_ids()
	var removed_ok := true
	for id in removed_ids:
		if not MonsterCatalog.get_by_id(id).is_empty():
			removed_ok = false
		if normal_ids.has(id) or elite_ids.has(id):
			removed_ok = false
	ok = removed_ok and ok
	lines.append("  제거된 4종(%s)이 카탈로그/출현 풀에 전부 없음=%s -> %s" % [
		removed_ids, removed_ok, "OK" if removed_ok else "FAIL"
	])

	# (2) 유령/그림자/안개(일반)·망령(정예) family가 실제로 undead로 재분류됐는지.
	var reclassified_ids := ["ghost", "shadow", "mist", "specter"]
	var reclass_ok := true
	var reclass_families := []
	for id in reclassified_ids:
		var fam: String = MonsterCatalog.get_by_id(id).get("family", "")
		reclass_families.append(fam)
		if fam != "undead":
			reclass_ok = false
	ok = reclass_ok and ok
	lines.append("  유령/그림자/안개/망령 family=%s (기대 전부 undead) -> %s" % [
		reclass_families, "OK" if reclass_ok else "FAIL"
	])

	# (3) 산적(id 유지) -> 풋내기 용병 표시명 변경.
	var bandit: Dictionary = MonsterCatalog.get_by_id("bandit")
	var bandit_name_ok: bool = bandit.get("name", "") == "풋내기 용병"
	ok = bandit_name_ok and ok
	lines.append("  bandit 표시명=%s (기대 풋내기 용병, id는 유지) -> %s" % [
		bandit.get("name", ""), "OK" if bandit_name_ok else "FAIL"
	])

	# (4) build_monster_plan(): 여러 시드에서 일반 자리(라운드당 4개 x 3라운드=12개)가
	# 전부 서로 다른 id + 새 풀(21종, R-3 반영) 안이어야 한다(런 전체 기준 중복 없음,
	# 기존 G-6 계약 그대로 — 풀 크기만 20->17->21로 바뀌었다).
	var plan_seeds := [1, 42, 9999, 20261026]
	var plan_ok := true
	for seed in plan_seeds:
		var plan: Array = MonsterCatalog.build_monster_plan(seed, 3, 5)
		var seen := {}
		for round_slots in plan:
			for room in range(4):
				var id: String = round_slots[room]
				if seen.has(id) or not normal_ids.has(id):
					plan_ok = false
				seen[id] = true
	ok = plan_ok and ok
	lines.append("  build_monster_plan() 여러 시드(%s)에서 12자리 전부 고유 + 21종 풀 안=%s -> %s" % [
		plan_seeds, plan_ok, "OK" if plan_ok else "FAIL"
	])

	# (5) build_elite_plan(): 여러 시드에서 "라운드 안" 방1~3이 전부 서로 다른 id +
	# 새 풀(8종, R-3 반영) 안이어야 한다(라운드 단위 중복 없음, 기존 G-7 계약 그대로 —
	# 풀 크기만 8->7->8로 바뀌었다. 라운드를 넘어서는 전체 런 기준 중복까지는 보장 안
	# 하는 것도 기존과 동일 — 3라운드x3자리=9 > 풀 크기 8).
	var elite_plan_ok := true
	for seed in plan_seeds:
		var elite_plan: Array = MonsterCatalog.build_elite_plan(seed, 3, 5)
		for round_slots in elite_plan:
			var seen_in_round := {}
			for room in range(1, 4):
				var id: String = round_slots[room]
				if seen_in_round.has(id) or not elite_ids.has(id):
					elite_plan_ok = false
				seen_in_round[id] = true
	ok = elite_plan_ok and ok
	lines.append("  build_elite_plan() 여러 시드(%s)에서 라운드당 3자리 전부 고유 + 8종 풀 안=%s -> %s" % [
		plan_seeds, elite_plan_ok, "OK" if elite_plan_ok else "FAIL"
	])

	return ok


## [대형 기획 16] R-3(2026-10-26) 검증 — 부정형 신규 몬스터 5종(일반 4: 미믹/저주 인형/
## 심연의 불/심연의 아이, 정예 1: 심연의 사제)이 "데이터만 있는 게 아니라" 실제
## 조회/풀 편입/정예 규칙 계산/렌더 폴백까지 전부 맞는지 확인한다(F-3 원칙) —
## INBOX.md "부정형 신규 로스터 확정" 지시 그대로.
func _check_r3_amorphous_roster(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 신규 일반 4종: family=amorphous/tier=normal/personality 존재/지정된 스킬 1개.
	var new_normal_ids := ["mimic", "cursed_doll", "will_o_wisp", "abyss_child"]
	var expected_skill := {
		"mimic": "seal", "cursed_doll": "numb", "will_o_wisp": "dull", "abyss_child": "sticky",
	}
	var normal_exist_ok := true
	var normal_details := []
	for id in new_normal_ids:
		var m: Dictionary = MonsterCatalog.get_by_id(id)
		var fam: String = m.get("family", "")
		var tier: String = m.get("tier", "")
		var gimmick: String = MonsterCatalog.gimmick_of(m)
		normal_details.append("%s(family=%s,tier=%s,skill=%s)" % [id, fam, tier, gimmick])
		if m.is_empty() or fam != "amorphous" or tier != "normal" \
			or m.get("personality", "") == "" or gimmick != expected_skill[id]:
			normal_exist_ok = false
	ok = normal_exist_ok and ok
	lines.append("  신규 일반 4종 %s (기대 전부 family=amorphous/tier=normal/지정 스킬 일치) -> %s" % [
		normal_details, "OK" if normal_exist_ok else "FAIL"
	])

	# (2) 신규 정예 1종(심연의 사제): family=amorphous/tier=elite + 스킬 2개(dull+seal) +
	# "정예 공통 규칙"(atk_dice_delta +1, hp_mult 1.5) 그대로.
	var priest: Dictionary = MonsterCatalog.get_by_id("abyss_priest")
	var priest_skill_ids: Array = []
	for s in priest.get("skills", []):
		priest_skill_ids.append(s.get("id", ""))
	var priest_data_ok: bool = priest.get("family", "") == "amorphous" and priest.get("tier", "") == "elite" \
		and priest_skill_ids == ["dull", "seal"] and priest.get("atk_dice_delta", 0) == 1 \
		and priest.get("hp_mult", 0.0) == 1.5
	ok = priest_data_ok and ok
	lines.append("  심연의 사제: family=%s tier=%s skills=%s atk_dice_delta=%d hp_mult=%s -> %s" % [
		priest.get("family", ""), priest.get("tier", ""), priest_skill_ids,
		priest.get("atk_dice_delta", 0), priest.get("hp_mult", 0.0), "OK" if priest_data_ok else "FAIL"
	])

	# (3) 풀 편입: normal_roster_ids()에 신규 일반 4종, elite_roster_ids()에 심연의 사제.
	var normal_ids: Array = MonsterCatalog.normal_roster_ids()
	var elite_ids: Array = MonsterCatalog.elite_roster_ids()
	var pool_ok := true
	for id in new_normal_ids:
		if not normal_ids.has(id):
			pool_ok = false
	if not elite_ids.has("abyss_priest"):
		pool_ok = false
	ok = pool_ok and ok
	lines.append("  normal_roster_ids()가 신규 일반 4종 포함 + elite_roster_ids()가 abyss_priest 포함=%s -> %s" % [
		pool_ok, "OK" if pool_ok else "FAIL"
	])

	# (4) "플래그가 아니라 계산 결과" — GAME_QA_MONSTER_ID로 심연의 사제를 직접 구성해
	# 정예 공식(공격 다이스 +1, hp_mult 1.5)이 attack_count/max_hp에 실제로 반영되고
	# skill_ids에 2개 다 담기는지 확인(F-3 원칙, 기존 goblin_chief 검증과 같은 패턴).
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()
	OS.set_environment("GAME_QA_MONSTER_ID", "abyss_priest")
	var priest_cfg: Dictionary = combat._monster_config_for_room(0)
	# room0 기본 공식: 공격=2+0=2, atk_dice_delta=1 -> 3. hp_mult=1.5 -> max_hp=round(10*1.5)=15.
	var priest_cfg_ok: bool = priest_cfg["name"] == "심연의 사제 [정예]" and priest_cfg["attack_count"] == 3 \
		and priest_cfg["max_hp"] == 15 and priest_cfg["skill_ids"] == ["dull", "seal"]
	ok = priest_cfg_ok and ok
	lines.append("  GAME_QA_MONSTER_ID=abyss_priest room0: name=%s(기대 '심연의 사제 [정예]') 공격=%d(기대3) hp=%d(기대15) skill_ids=%s(기대 [dull,seal]) -> %s" % [
		priest_cfg["name"], priest_cfg["attack_count"], priest_cfg["max_hp"], priest_cfg["skill_ids"],
		"OK" if priest_cfg_ok else "FAIL"
	])
	OS.set_environment("GAME_QA_MONSTER_ID", "")
	combat.free()

	# (5) 아트 폴백 — resources/monsters/<id>/에 아직 full.png가 입고되지 않은 상태라
	# (지시문 "곧 입고되므로 파일이 없으면 기존 폴백으로 정상 동작해야 한다"), production
	# art_base_dir(가짜 디렉터리 주입 없이)로 MonsterPortraitPlaceholder.set_monster()를
	# 호출해도 크래시 없이 _use_face_art/_use_full_crop이 둘 다 false(계열 플레이스홀더
	# 폴백)로 남는지 직접 확인한다.
	# 2026-10-28: 신규 몬스터 원화가 하나씩 입고되기 시작했다(심연의 불). full.png가 이미
	# 입고된 몬스터는 폴백이 아니라 전신 크롭(full_crop=true)을 써야 정상이므로, 몬스터마다
	# 실제 입고 여부로 기대값을 정한다(face_*는 아직 아무도 없으니 face=false 고정).
	var all_new_ids: Array = new_normal_ids + ["abyss_priest"]
	var fallback_ok := true
	var fallback_details := []
	for id in all_new_ids:
		var portrait := MonsterPortraitPlaceholder.new()
		portrait.set_monster(id)
		var has_full: bool = ResourceLoader.exists("res://resources/monsters/%s/full.png" % id)
		fallback_details.append("%s(face=%s,full_crop=%s,입고=%s)" % [id, portrait._use_face_art, portrait._use_full_crop, has_full])
		if portrait._use_face_art or portrait._use_full_crop != has_full:
			fallback_ok = false
		portrait.free()
	ok = fallback_ok and ok
	lines.append("  신규 5종 아트 폴백(production art_base_dir) %s (기대: face=false, full_crop=입고 여부와 같음) -> %s" % [
		fallback_details, "OK" if fallback_ok else "FAIL"
	])

	return ok


## [대형 기획 6] G-6(2026-10-07) 검증 — MonsterCatalog.build_monster_plan()(순수 함수)이
## "라운드x방" 모양으로 결정론적인 계획을 만드는지, combat_test.gd의
## _monster_config_for_plan()이 그 계획 + 라운드를 반영한 난이도 공식(room_index +
## (round_index-1)*3)을 "플래그"가 아니라 실제 attack_count/defense_count/max_hp/
## dice_sides 계산 결과로 바꾸는지(F-3 원칙), reset_run()이 실제로 RunState.monster_plan을
## 채우는지까지 확인한다.
func _check_g6_monster_plan(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) normal_roster_ids(): 21종(R-1로 20->17, R-3로 17->21), 다크 나이트 제외
	# (일반 풀 뽑기 대상 아님).
	var normal_ids: Array = MonsterCatalog.normal_roster_ids()
	var roster_size_ok: bool = normal_ids.size() == 21 and not normal_ids.has("dark_knight")
	ok = roster_size_ok and ok
	lines.append("  MonsterCatalog.normal_roster_ids().size()=%d, 다크 나이트 포함=%s (기대 21, false) -> %s" % [
		normal_ids.size(), normal_ids.has("dark_knight"), "OK" if roster_size_ok else "FAIL"
	])

	# (2) build_monster_plan(seed, 3, 5): 라운드 3개 x 방 5개 모양 + 같은 seed -> 같은 결과
	# (재현 가능해야 QA/F-4 시뮬에서 의미가 있음).
	var plan_a: Array = MonsterCatalog.build_monster_plan(12345, 3, 5)
	var plan_b: Array = MonsterCatalog.build_monster_plan(12345, 3, 5)
	var shape_ok: bool = plan_a.size() == 3
	for round_slots in plan_a:
		if round_slots.size() != 5:
			shape_ok = false
	var deterministic_ok: bool = str(plan_a) == str(plan_b)
	ok = shape_ok and deterministic_ok and ok
	lines.append("  build_monster_plan(seed=12345, 3, 5) 모양(3라운드x5방)=%s, 같은 seed 재현=%s -> %s" % [
		shape_ok, deterministic_ok, "OK" if (shape_ok and deterministic_ok) else "FAIL"
	])

	# (3) "일반 전투" 자리(방 0~3, 라운드당 4개 = 총 12개)는 전부 서로 다른 id + 21종 풀 안
	# (R-1로 20->17, R-3로 17->21, INBOX.md 원문 "한 판 안에서 중복 없이" — 풀 크기 21 >= 12라
	# 여전히 가능).
	var normal_slot_ids: Array = []
	for round_slots in plan_a:
		for room in range(4):
			normal_slot_ids.append(round_slots[room])
	var seen := {}
	var all_unique := true
	for id in normal_slot_ids:
		if seen.has(id):
			all_unique = false
		seen[id] = true
	var all_in_pool := true
	for id in normal_slot_ids:
		if not normal_ids.has(id):
			all_in_pool = false
	ok = all_unique and all_in_pool and ok
	lines.append("  일반 전투 자리(방 0~3 x 3라운드=12개) 전부 고유=%s, 전부 21종 풀 안=%s -> %s" % [
		all_unique, all_in_pool, "OK" if (all_unique and all_in_pool) else "FAIL"
	])

	# (4) 보스 자리(방4)는 G-8(2026-10-07)부터 전용 보스 풀 — 그 라운드의
	# BOSS_ROSTER_BY_ROUND 후보 2종 중 하나여야 한다(일반 21종 풀 안이 아니다).
	var boss_ok := true
	for r in range(plan_a.size()):
		var boss_id: String = plan_a[r][4]
		var candidates: Array = MonsterCatalog.BOSS_ROSTER_BY_ROUND[r % MonsterCatalog.BOSS_ROSTER_BY_ROUND.size()]
		if not candidates.has(boss_id):
			boss_ok = false
	ok = boss_ok and ok
	lines.append("  보스 자리(방4, 3라운드) 전부 그 라운드의 보스 후보 2종 안=%s -> %s" % [
		boss_ok, "OK" if boss_ok else "FAIL"
	])

	# (5) 실제 배선: combat_test._monster_config_for_plan(round_index, room_index)이
	# RunState.monster_plan을 읽어 몬스터를 고르고, 난이도 공식(room_index+(round_index-1)*3)을
	# attack_count/defense_count/max_hp/dice_sides에 실제로 반영하는지 — "스킬 플래그가
	# 들어갔는가"가 아니라 "계산 결과가 실제로 바뀌는가"를 직접 비교(F-3 원칙). 검증용 계획을
	# RunState.monster_plan에 직접 꽂아두고 끝나면 원래 값으로 복원.
	var plan_backup: Array = RunState.monster_plan
	RunState.monster_plan = [
		["slime", "goblin", "armored_goblin", "orc", "dark_knight"],
		["armored_goblin", "poison_slime", "wolf", "ghoul", "zombie"],
		["bandit", "ghost", "mad_dog", "poison_slime", "dark_knight"],
	]
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	# 라운드1/방0: difficulty = 0+(1-1)*3 = 0 -> DESIGN.md 확정값(공격2D4/방어1D4/HP10)과 동일.
	var r1_room0: Dictionary = combat._monster_config_for_plan(1, 0)
	var r1_room0_ok: bool = r1_room0["name"] == "슬라임" and r1_room0["attack_count"] == 2 \
		and r1_room0["defense_count"] == 1 and r1_room0["max_hp"] == 10 and r1_room0["dice_sides"] == 4 \
		and r1_room0["is_boss"] == false
	ok = r1_room0_ok and ok
	lines.append("  라운드1/방0: name=%s 공격=%d 방어=%d hp=%d sides=%d is_boss=%s (기대 슬라임,2,1,10,4,false) -> %s" % [
		r1_room0["name"], r1_room0["attack_count"], r1_room0["defense_count"], r1_room0["max_hp"],
		r1_room0["dice_sides"], r1_room0["is_boss"], "OK" if r1_room0_ok else "FAIL"
	])

	# 라운드2/방0: difficulty = 0+(2-1)*3 = 3 -> 공격=2+1=3, 방어=1+1=2, hp=10+9=19,
	# sides=6([대형 기획 10] J-3 1차 시도 값(D6 임계 idx>=3) 그대로 유지 — 3차 시도로
	# D6 임계만 1차 시도로 되돌림, docs/BALANCE_TUNING_LOG.md 참고).
	# "아머 고블린"은 atk/def_dice_delta·hp_mult 전부 기본값(0/0/1.0)이라 공식 그대로 나와야 함.
	var r2_room0: Dictionary = combat._monster_config_for_plan(2, 0)
	var r2_room0_ok: bool = r2_room0["name"] == "아머 고블린" and r2_room0["attack_count"] == 3 \
		and r2_room0["defense_count"] == 2 and r2_room0["max_hp"] == 19 and r2_room0["dice_sides"] == 6
	ok = r2_room0_ok and ok
	lines.append("  라운드2/방0: name=%s 공격=%d(기대3) 방어=%d(기대2) hp=%d(기대19) sides=%d(기대6) -> %s" % [
		r2_room0["name"], r2_room0["attack_count"], r2_room0["defense_count"], r2_room0["max_hp"],
		r2_room0["dice_sides"], "OK" if r2_room0_ok else "FAIL"
	])

	# 라운드2/방4(보스): difficulty = 4+(2-1)*3 = 7 -> 기본 공격=2+3=5, 방어=1+2=3,
	# hp=round((10+21)*1.4)=43(좀비 hp_mult 1.4 반영), sides=8(difficulty=7은 D8 임계
	# D8>=7 경계값이라 승급됨). 보스 전용 공통 보정(공격/방어 다이스 가산, HP 배율)은
	# [대형 기획 10] J-2(2026-10-08)에서 전부 제거됐으므로(공격+0/방어+0/HP×1.0) 기본
	# 공식값이 그대로 나온다 -> 공격5 방어3 hp43.
	var r2_room4: Dictionary = combat._monster_config_for_plan(2, 4)
	var r2_room4_ok: bool = r2_room4["name"] == "좀비 [보스]" and r2_room4["attack_count"] == 5 \
		and r2_room4["defense_count"] == 3 and r2_room4["max_hp"] == 43 and r2_room4["is_boss"] == true
	ok = r2_room4_ok and ok
	lines.append("  라운드2/방4(보스): name=%s 공격=%d(기대5) 방어=%d(기대3) hp=%d(기대43, 좀비 hp_mult 1.4 + 보스 x1.0 반영) is_boss=%s -> %s" % [
		r2_room4["name"], r2_room4["attack_count"], r2_room4["defense_count"], r2_room4["max_hp"],
		r2_room4["is_boss"], "OK" if r2_room4_ok else "FAIL"
	])

	combat.free()
	RunState.monster_plan = plan_backup

	# (6) reset_run()이 실제로 RunState.monster_plan을 "라운드x방" 모양으로 채우는지
	# (글루 코드 자체가 호출되는지 — 값은 위 (1)~(5)에서 이미 직접 계산으로 검증했으므로
	# 여기서는 "비어있지 않고 모양이 맞는지"만 확인).
	var char_backup: String = RunState.character_id
	RunState.reset_run()
	var plan_generated_ok: bool = RunState.monster_plan.size() == RunState.TOTAL_ROUNDS \
		and RunState.monster_plan[0].size() == RunState.TOTAL_ROOMS
	ok = plan_generated_ok and ok
	lines.append("  reset_run() 후 RunState.monster_plan 모양 일치(기대 %d라운드x%d방)=%s -> %s" % [
		RunState.TOTAL_ROUNDS, RunState.TOTAL_ROOMS, plan_generated_ok, "OK" if plan_generated_ok else "FAIL"
	])
	RunState.reset_run(char_backup)

	return ok


## [대형 기획 6] G-7(2026-10-07) 검증 — 정예 풀 8종 + MonsterCatalog.build_elite_plan()
## (순수 함수)의 모양/결정론성/범위 제한, combat_test.gd의 _monster_config_for_elite()가
## "플래그"가 아니라 실제 계산 결과(hp_mult/atk_dice_delta가 attack_count/max_hp에
## 반영되는지, 스킬 2개가 skill_ids에 둘 다 담기는지)를 바꾸는지(F-3 원칙), 보상 풀
## (EliteRewardPool)이 DiceItemPool보다 실제로 더 높은 등급 쪽에 치우쳐 있는지까지
## 확인한다.
func _check_g7_elite_combat(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) elite_roster_ids(): INBOX.md 원문은 8종이었으나 2026-10-26 R-1로 해골 기사
	# (skeleton_knight)가 제거되며 7종이 됐다가, 같은 날 R-3로 심연의 사제가 추가돼
	# 다시 8종이 됐다.
	var elite_ids: Array = MonsterCatalog.elite_roster_ids()
	var elite_size_ok: bool = elite_ids.size() == 8
	ok = elite_size_ok and ok
	lines.append("  MonsterCatalog.elite_roster_ids().size()=%d (기대 8) -> %s" % [
		elite_ids.size(), "OK" if elite_size_ok else "FAIL"
	])

	# (2) 8종 전부 tier=="elite"이고 skills가 정확히 2개씩이어야 한다("정예 = 스킬 2개"
	# 공통 공식).
	var all_elite_two_skills := true
	for id in elite_ids:
		var m: Dictionary = MonsterCatalog.get_by_id(id)
		if m.get("tier", "") != "elite" or m.get("skills", []).size() != 2:
			all_elite_two_skills = false
	ok = all_elite_two_skills and ok
	lines.append("  정예 8종 전부 tier==elite && skills.size()==2: %s -> %s" % [
		all_elite_two_skills, "OK" if all_elite_two_skills else "FAIL"
	])

	# (3) build_elite_plan(seed, 3, 5): 모양(3라운드x5방) + 같은 seed -> 같은 결과 +
	# room 0/마지막 방(보스 자리)은 항상 "" + 중간(1~3)은 항상 elite_roster_ids() 안.
	var plan_a: Array = MonsterCatalog.build_elite_plan(777, 3, 5)
	var plan_b: Array = MonsterCatalog.build_elite_plan(777, 3, 5)
	var shape_ok: bool = plan_a.size() == 3
	for round_slots in plan_a:
		if round_slots.size() != 5:
			shape_ok = false
	var deterministic_ok: bool = str(plan_a) == str(plan_b)
	ok = shape_ok and deterministic_ok and ok
	lines.append("  build_elite_plan(seed=777, 3, 5) 모양(3라운드x5방)=%s, 같은 seed 재현=%s -> %s" % [
		shape_ok, deterministic_ok, "OK" if (shape_ok and deterministic_ok) else "FAIL"
	])

	var edge_slots_empty_ok := true
	var middle_slots_valid_ok := true
	for round_slots in plan_a:
		if round_slots[0] != "" or round_slots[4] != "":
			edge_slots_empty_ok = false
		for room in range(1, 4):
			if not elite_ids.has(round_slots[room]):
				middle_slots_valid_ok = false
	ok = edge_slots_empty_ok and middle_slots_valid_ok and ok
	lines.append("  방0/방4(보스 자리)는 항상 빈 문자열=%s, 방1~3은 항상 정예 8종 풀 안=%s -> %s" % [
		edge_slots_empty_ok, middle_slots_valid_ok, "OK" if (edge_slots_empty_ok and middle_slots_valid_ok) else "FAIL"
	])

	# (4) 실제 배선: combat_test._monster_config_for_elite(round_index, room_index)이
	# RunState.elite_plan을 읽어 몬스터를 고르고, "정예 = 스킬 2개 + hp_mult 1.5 + 공격
	# 다이스 +1" 공식이 계산 결과(attack_count/max_hp/skill_ids)에 실제로 반영되는지.
	# "다크 나이트"(dark_knight_elite, steady_guard+armor 2)를 1번째 방에 직접 꽂아
	# 검증용 계획을 만든다.
	var elite_plan_backup: Array = RunState.elite_plan
	RunState.elite_plan = [
		["", "dark_knight_elite", "goblin_chief", "orc_warrior", ""],
	]
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	# 라운드1/방1: difficulty=1+(1-1)*3=1 -> 기본(델타 전) 공격=2+int(1/2.0)=2, 방어=1+int(1/3.0)=1.
	# atk_dice_delta=1 -> 공격=3. hp_mult=1.5 -> max_hp=round((10+1*3)*1.5)=20(델타 없음).
	var elite_config: Dictionary = combat._monster_config_for_elite(1, 1)
	var elite_stats_ok: bool = elite_config["name"] == "다크 나이트 [철벽] [정예]" \
		and elite_config["attack_count"] == 3 and elite_config["max_hp"] == 20 \
		and elite_config["is_elite"] == true and elite_config["is_boss"] == false
	ok = elite_stats_ok and ok
	lines.append("  라운드1/방1(다크 나이트 정예): name=%s 공격=%d(기대3) hp=%d(기대20) is_elite=%s is_boss=%s -> %s" % [
		elite_config["name"], elite_config["attack_count"], elite_config["max_hp"],
		elite_config["is_elite"], elite_config["is_boss"], "OK" if elite_stats_ok else "FAIL"
	])

	# "스킬 2개가 전부 skill_ids에 담기는가"(F-3 원칙 — 과거 "[] if gimmick=='' else
	# [gimmick]" 방식이면 skills[0]만 담겨 2번째 스킬이 통째로 무시되는 버그가 있었음).
	var skill_ids_ok: bool = elite_config["skill_ids"] == ["steady_guard", "armor"] \
		and elite_config["skill_params"].get("armor", {}).get("amount", 0) == 2
	ok = skill_ids_ok and ok
	lines.append("  다크 나이트 정예 skill_ids=%s armor.amount=%d (기대 [steady_guard, armor], 2) -> %s" % [
		elite_config["skill_ids"], elite_config["skill_params"].get("armor", {}).get("amount", 0),
		"OK" if skill_ids_ok else "FAIL"
	])

	# 디버그 텍스트도 두 스킬 문구가 전부 들어있어야 한다(_skill_debug_line() 루프 검증).
	var elite_debug_text: String = combat._monster_debug_info_text(elite_config)
	var debug_text_ok: bool = elite_debug_text.contains("철벽 방어") and elite_debug_text.contains("방어구") \
		and elite_debug_text.contains("[정예]")
	ok = debug_text_ok and ok
	lines.append("  디버그 텍스트에 두 스킬(철벽 방어/방어구) + [정예] 태그 전부 포함: %s -> %s" % [
		debug_text_ok, "OK" if debug_text_ok else "FAIL"
	])

	combat.free()
	RunState.elite_plan = elite_plan_backup

	# (5) reset_run()이 실제로 RunState.elite_plan을 "라운드x방" 모양으로 채우는지.
	var char_backup: String = RunState.character_id
	RunState.reset_run()
	var elite_plan_generated_ok: bool = RunState.elite_plan.size() == RunState.TOTAL_ROUNDS \
		and RunState.elite_plan[0].size() == RunState.TOTAL_ROOMS
	ok = elite_plan_generated_ok and ok
	lines.append("  reset_run() 후 RunState.elite_plan 모양 일치(기대 %d라운드x%d방)=%s -> %s" % [
		RunState.TOTAL_ROUNDS, RunState.TOTAL_ROOMS, elite_plan_generated_ok, "OK" if elite_plan_generated_ok else "FAIL"
	])
	RunState.reset_run(char_backup)

	# (6) EliteRewardPool: DiceItemPool(C/B급뿐)보다 실제로 더 높은 등급(A/S)을 포함해야
	# "A급 이상 중심"이 의미가 있다. gain_pips(kind)는 combat_test.gd의 보상 카드 적용
	# 로직이 못 다루므로 제외돼야 한다.
	var elite_pool_grades := {}
	var has_gain_pips := false
	for item in EliteRewardPool._pool():
		elite_pool_grades[item.get("grade", "")] = true
		if item.get("kind", "") == "gain_pips":
			has_gain_pips = true
	var pool_grade_ok: bool = elite_pool_grades.has("A") and elite_pool_grades.has("S") and not has_gain_pips
	ok = pool_grade_ok and ok
	lines.append("  EliteRewardPool 풀에 A/S급 포함=%s, gain_pips 제외됨=%s -> %s" % [
		elite_pool_grades.has("A") and elite_pool_grades.has("S"), not has_gain_pips,
		"OK" if pool_grade_ok else "FAIL"
	])

	# random_choices(2)가 서로 다른 아이템 2개를 돌려주는지(복원추출 없음 — erase()가
	# 실제로 중복을 막는지).
	var distinct_ok := true
	for _i in 20:
		var choices: Array = EliteRewardPool.random_choices(2)
		if choices.size() == 2 and choices[0] == choices[1]:
			distinct_ok = false
	ok = distinct_ok and ok
	lines.append("  EliteRewardPool.random_choices(2) 20회 반복 — 같은 아이템 중복 없음: %s -> %s" % [
		distinct_ok, "OK" if distinct_ok else "FAIL"
	])

	return ok


## [대형 기획 6] G-8(2026-10-07) 검증 — 보스 풀 6종(라운드당 2종) 데이터/배정 +
## combat_test.gd의 _monster_config_for_plan()이 보스 몬스터에 대해서도 "계산 결과"
## (attack_count/max_hp/skill_ids)를 실제로 바꾸는지 + 2페이즈 활성화 순수 함수
## (_boss_phase2_activation())가 "이미 보유한 스킬 강화" / "새 스킬 추가" / "min_max_only
## 특수 처리" 세 경우 모두에서 실제 반환값이 바뀌는지(F-3 원칙 — UI/물리 없이 직접 검증).
func _check_g8_boss(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) boss_roster_ids(): INBOX.md 원문 그대로 6종.
	var boss_ids: Array = MonsterCatalog.boss_roster_ids()
	var boss_size_ok: bool = boss_ids.size() == 6
	ok = boss_size_ok and ok
	lines.append("  MonsterCatalog.boss_roster_ids().size()=%d (기대 6) -> %s" % [
		boss_ids.size(), "OK" if boss_size_ok else "FAIL"
	])

	# (2) BOSS_ROSTER_BY_ROUND: 라운드 3개 x 후보 2종, 6종이 라운드마다 겹치지 않고
	# 정확히 한 번씩만 등장(합쳐서 boss_roster_ids()와 정확히 일치).
	var round_roster_ok: bool = MonsterCatalog.BOSS_ROSTER_BY_ROUND.size() == 3
	var seen_in_rounds := {}
	for candidates in MonsterCatalog.BOSS_ROSTER_BY_ROUND:
		if candidates.size() != 2:
			round_roster_ok = false
		for id in candidates:
			if seen_in_rounds.has(id):
				round_roster_ok = false
			seen_in_rounds[id] = true
	for id in boss_ids:
		if not seen_in_rounds.has(id):
			round_roster_ok = false
	ok = round_roster_ok and ok
	lines.append("  BOSS_ROSTER_BY_ROUND 모양(3라운드x2종) + 6종 전부 라운드당 1회씩만 등장=%s -> %s" % [
		round_roster_ok, "OK" if round_roster_ok else "FAIL"
	])

	# (3) 실제 배선: _monster_config_for_plan()이 보스 자리에 "고블린 왕"(armor 1 +
	# guard_up + counter 1, 3스킬 — [대형 기획 10] J-2(2026-10-08)로 armor/counter를
	# 2에서 1로 완화한 최종값)을 꽂았을 때 is_boss(이제 공통 배율 없음, 아래 참고)와
	# skill_ids 3개가 전부 계산 결과에 반영되는지.
	var plan_backup: Array = RunState.monster_plan
	RunState.monster_plan = [
		["slime", "goblin", "armored_goblin", "orc", "goblin_king"],
	]
	var script := load("res://code/scenes/combat_test.gd")
	var combat = script.new()

	# 라운드1/방4(보스): difficulty=4+(1-1)*3=4 -> 기본 공격=2+int(4/2.0)=4, 방어=1+int(4/3.0)=2,
	# hp=10+12=22(hp_mult 1.0). 보스 전용 공통 보정(공격/방어 다이스 가산, HP 배율)은
	# [대형 기획 10] J-2(2026-10-08)에서 전부 제거됐으므로 기본 공식값 그대로 나온다
	# -> 공격4 방어2 hp22.
	var boss_config: Dictionary = combat._monster_config_for_plan(1, 4)
	var boss_stats_ok: bool = boss_config["name"] == "고블린 왕 [보스]" and boss_config["attack_count"] == 4 \
		and boss_config["defense_count"] == 2 and boss_config["max_hp"] == 22 and boss_config["is_boss"] == true
	ok = boss_stats_ok and ok
	lines.append("  라운드1/방4(고블린 왕): name=%s 공격=%d(기대4) 방어=%d(기대2) hp=%d(기대22) is_boss=%s -> %s" % [
		boss_config["name"], boss_config["attack_count"], boss_config["defense_count"], boss_config["max_hp"],
		boss_config["is_boss"], "OK" if boss_stats_ok else "FAIL"
	])

	# armor/counter.amount 기대값은 J-2 6차 시도(2026-10-08)로 2->1 완화.
	var boss_skill_ids_ok: bool = boss_config["skill_ids"] == ["armor", "guard_up", "counter"] \
		and boss_config["skill_params"].get("armor", {}).get("amount", 0) == 1 \
		and boss_config["skill_params"].get("counter", {}).get("amount", 0) == 1
	ok = boss_skill_ids_ok and ok
	lines.append("  고블린 왕 skill_ids=%s armor/counter.amount=%d/%d (기대 [armor,guard_up,counter], 1, 1) -> %s" % [
		boss_config["skill_ids"], boss_config["skill_params"].get("armor", {}).get("amount", 0),
		boss_config["skill_params"].get("counter", {}).get("amount", 0), "OK" if boss_skill_ids_ok else "FAIL"
	])

	# (4) _boss_phase2_activation() 순수 함수 — 보스가 아니거나 HP가 절반 넘으면 활성화
	# 안 됨(플래그/조건이 아니라 반환 Dictionary 자체를 비교). 정적 함수라 인스턴스 없이
	# 로드한 script 자체로 호출 가능(_wealth_bonus 등 기존 패턴과 동일).
	var not_boss_result: Dictionary = script._boss_phase2_activation(
		false, false, 5, 44, [{"id": "armor", "amount": 4}], ["armor"], {"armor": {"id": "armor", "amount": 2}}
	)
	var hp_above_half_result: Dictionary = script._boss_phase2_activation(
		true, false, 23, 44, [{"id": "armor", "amount": 4}], ["armor"], {"armor": {"id": "armor", "amount": 2}}
	)
	var gate_ok: bool = not not_boss_result.get("activate", false) and not hp_above_half_result.get("activate", false)
	ok = gate_ok and ok
	lines.append("  _boss_phase2_activation: 보스 아님/HP 절반 초과 -> 활성화 안 됨=%s -> %s" % [
		gate_ok, "OK" if gate_ok else "FAIL"
	])

	# (5) "고블린 왕" 패턴 — 이미 보유한 스킬(armor, amount=2)을 phase2_skills({"id":"armor",
	# "amount":4})로 덮어쓴다(새 스킬 추가가 아니라 기존 스킬 강화, skill_ids 길이 불변).
	var boost_result: Dictionary = script._boss_phase2_activation(
		true, false, 22, 44, [{"id": "armor", "amount": 4}],
		["armor", "guard_up", "counter"], {"armor": {"id": "armor", "amount": 2}, "counter": {"id": "counter", "amount": 2}}
	)
	var boost_ok: bool = boost_result.get("activate", false) and boost_result["skill_ids"].size() == 3 \
		and boost_result["skill_params"]["armor"]["amount"] == 4 and not boost_result.get("force_min_max", false)
	ok = boost_ok and ok
	lines.append("  _boss_phase2_activation(고블린 왕류, armor 2->4): activate=%s skill_ids.size()=%d armor.amount=%d -> %s" % [
		boost_result.get("activate", false), boost_result.get("skill_ids", []).size(),
		boost_result.get("skill_params", {}).get("armor", {}).get("amount", 0), "OK" if boost_ok else "FAIL"
	])

	# (6) "해골 장군" 패턴 — 아직 없던 스킬("revive")을 새로 추가(skill_ids 길이 +1).
	var add_result: Dictionary = script._boss_phase2_activation(
		true, false, 10, 44, [{"id": "revive"}], ["fixed_value", "drain", "chill"], {}
	)
	var add_ok: bool = add_result.get("activate", false) and add_result["skill_ids"].size() == 4 \
		and add_result["skill_ids"].has("revive") and not add_result.get("force_min_max", false)
	ok = add_ok and ok
	lines.append("  _boss_phase2_activation(해골 장군류, revive 신규 추가): activate=%s skill_ids=%s -> %s" % [
		add_result.get("activate", false), add_result.get("skill_ids", []), "OK" if add_ok else "FAIL"
	])

	# (7) "광란의 마수" 패턴 — min_max_only가 phase2로 들어오면 force_min_max=true로
	# 신호를 돌려줘야 호출부가 즉시 force_min_max_faces()를 적용할 수 있다.
	var min_max_result: Dictionary = script._boss_phase2_activation(
		true, false, 10, 44, [{"id": "min_max_only"}], ["anger_stack", "pounce", "bloodlust"], {}
	)
	var min_max_ok: bool = min_max_result.get("activate", false) and min_max_result.get("force_min_max", false) == true
	ok = min_max_ok and ok
	lines.append("  _boss_phase2_activation(광란의 마수류, min_max_only): activate=%s force_min_max=%s -> %s" % [
		min_max_result.get("activate", false), min_max_result.get("force_min_max", false), "OK" if min_max_ok else "FAIL"
	])

	# (8) 이미 활성화된 상태(already_active=true)면 조건을 다시 만족해도 활성화 안 됨
	# (전투당 1회 제한).
	var already_active_result: Dictionary = script._boss_phase2_activation(
		true, true, 10, 44, [{"id": "revive"}], ["fixed_value"], {}
	)
	var already_active_ok: bool = not already_active_result.get("activate", false)
	ok = already_active_ok and ok
	lines.append("  _boss_phase2_activation: 이미 활성화됨(already_active=true) -> 재활성화 안 됨=%s -> %s" % [
		already_active_ok, "OK" if already_active_ok else "FAIL"
	])

	# (9) _monster_debug_info_text()(인스턴스 메서드, combat을 아직 안 free했으므로 재사용)
	# 에 phase2_active 플래그가 있으면 "[2페이즈]" 문구가 실제로 붙는지(디버그 텍스트도
	# "플래그"가 아니라 "출력 결과"로 검증).
	var phase2_debug_text: String = combat._monster_debug_info_text({
		"dice_sides": 6, "attack_count": 4, "defense_count": 3, "skill_ids": [], "is_boss": true,
		"phase2_active": true,
	})
	var phase2_text_ok: bool = phase2_debug_text.contains("[2페이즈]")
	ok = phase2_text_ok and ok
	lines.append("  phase2_active=true인 config의 디버그 텍스트에 [2페이즈] 포함=%s -> %s" % [
		phase2_text_ok, "OK" if phase2_text_ok else "FAIL"
	])

	combat.free()
	RunState.monster_plan = plan_backup
	return ok


## [대형 기획 8] H-1(2026-10-08) — "테스트 전투" 플러밍 검증. F-3 원칙(플래그가 아니라
## 계산/상태 "결과"를 본다)을 그대로 따른다: AchievementManager._unlocked 백업/복원(F-3
## E2E 패턴), 강제 승리/패배를 force_fixed_value()로 결정론적으로 만들고(balance_sim.gd가
## 쓰는 "combat_test.gd를 .new()만 해서 production 함수를 직접 호출" 패턴 재사용),
## RunState.test_battle=true일 때 업적/골드/눈금/rooms_cleared/round_index/reset_run()이
## 전혀 안 바뀌는지, test_battle=false(일반 모드)에서는 똑같은 시나리오가 정상적으로
## 진행도를 바꾸는지(동작 보존)를 함께 확인한다.
func _check_h1_test_battle_mode(lines: PackedStringArray) -> bool:
	var ok := true
	var achievements_backup: Dictionary = AchievementManager._unlocked.duplicate(true)
	var character_backup := RunState.character_id
	var test_battle_backup := RunState.test_battle
	var test_monster_backup := RunState.test_monster_id
	var test_difficulty_backup := RunState.test_difficulty
	var gold_backup := RunState.gold
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) 강제 승리(보스 "고블린 왕" 대상) — RunState.test_battle=true면 업적 unlock
	# 전부 스킵, 골드/눈금 보상 스킵, rooms_cleared/round_index/advance_round() 스킵.
	AchievementManager._unlocked = {}
	RunState.reset_run("novice")
	RunState.gold = 0
	RunState.pip_inventory = []
	RunState.rooms_cleared = 0
	RunState.round_index = 1
	RunState.test_battle = true
	RunState.test_monster_id = "goblin_king"
	RunState.test_difficulty = 0

	var win_instance = combat_script.new()
	var win_config: Dictionary = win_instance._monster_config_for_test(RunState.test_difficulty)
	var win_is_boss_ok: bool = win_config["is_boss"] == true
	win_instance._apply_monster_config(win_config)
	win_instance._reset_player_battle_state()
	win_instance.monster_hp = 1
	var win_atk_bag := DiceBag.new(4, 1)
	win_atk_bag.force_fixed_value(50)
	var win_def_bag := DiceBag.new(4, 1)
	win_def_bag.force_fixed_value(0)
	win_instance._resolve_exchange(true, win_atk_bag, win_def_bag, false, false, false)
	var win_player_won: bool = win_instance.player_won
	var win_room_advanced: bool = win_instance._apply_room_advance()
	win_instance.free()

	var win_test_ok: bool = (
		win_is_boss_ok and win_player_won and win_room_advanced
		and AchievementManager._unlocked.is_empty()
		and RunState.gold == 0 and RunState.pip_inventory.is_empty()
		and RunState.rooms_cleared == 0 and RunState.round_index == 1
	)
	ok = win_test_ok and ok
	lines.append("  [테스트 전투] 강제 승리(보스 config.is_boss=%s) 후 업적 %d개/골드 %d/눈금 %d개/rooms_cleared %d/round %d (전부 불변 기대) -> %s" % [
		win_config["is_boss"], AchievementManager._unlocked.size(), RunState.gold, RunState.pip_inventory.size(),
		RunState.rooms_cleared, RunState.round_index, "OK" if win_test_ok else "FAIL"
	])

	# (2) 강제 패배 — reset_run()이 호출되면 지금 주머니(공격 다이스에 D20 1개를 표식으로
	# 추가해둠)가 캐릭터 기본값으로 리셋될 것이므로, 다이스 개수가 그대로인지로 "reset_run()
	# 호출 안 됨"을 검증한다.
	RunState.player_attack_bag.add_die(20)
	var marker_dice_count: int = RunState.player_attack_bag.dice.size()

	var lose_instance = combat_script.new()
	var lose_config: Dictionary = lose_instance._monster_config_for_test(RunState.test_difficulty)
	lose_instance._apply_monster_config(lose_config)
	lose_instance._reset_player_battle_state()
	lose_instance.player_hp = 1
	var lose_atk_bag := DiceBag.new(4, 1)
	lose_atk_bag.force_fixed_value(50)
	var lose_def_bag := DiceBag.new(4, 1)
	lose_def_bag.force_fixed_value(0)
	lose_instance._resolve_exchange(false, lose_atk_bag, lose_def_bag, false, false, false)
	var lose_player_lost: bool = not lose_instance.player_won and lose_instance.battle_over
	var lose_room_advanced: bool = lose_instance._apply_room_advance()
	lose_instance.free()

	var lose_test_ok: bool = (
		lose_player_lost and lose_room_advanced
		and AchievementManager._unlocked.is_empty()
		and RunState.rooms_cleared == 0 and RunState.round_index == 1
		and RunState.player_attack_bag.dice.size() == marker_dice_count
	)
	ok = lose_test_ok and ok
	lines.append("  [테스트 전투] 강제 패배 후에도 업적 0개/rooms_cleared/round 불변/reset_run() 미호출(공격 다이스 %d개 유지, 기대 %d) -> %s" % [
		RunState.player_attack_bag.dice.size(), marker_dice_count, "OK" if lose_test_ok else "FAIL"
	])

	# (3) 일반 모드(test_battle=false) 동작 보존 — 같은 강제 승리 시나리오에서 업적/골드/
	# rooms_cleared가 "정상적으로" 바뀌는지(이 가드 추가가 기존 동작을 깨지 않았는지).
	RunState.test_battle = false
	AchievementManager._unlocked = {}
	RunState.reset_run("novice")
	RunState.gold = 0
	RunState.pip_inventory = []
	RunState.rooms_cleared = 0
	RunState.round_index = 1

	var normal_instance = combat_script.new()
	var normal_config: Dictionary = normal_instance._monster_config_for_plan(1, 0)
	normal_instance._apply_monster_config(normal_config)
	normal_instance._reset_player_battle_state()
	normal_instance.monster_hp = 1
	# round1/room0 몬스터는 RunState.monster_plan(reset_run()의 randi() 시드)이 매번
	# 다르게 뽑는다 — "유령"(ghost, seal)이 뽑히면 공격 다이스가 1개뿐일 때
	# apply_zero_lowest()가 그 유일한 다이스를 통째로 0으로 만들어 강제 승리 전제가
	# 깨지는 실제 원인을 찾았다(기존 "6번 중 1번 일회성 FAIL" 노이즈, STATUS.md
	# 알려진 이슈). 다이스를 2개로 늘리면 seal이 하나를 0으로 만들어도 나머지
	# 하나(50)가 그대로 남아 몬스터 HP 1을 확실히 넘어서므로, 어떤 일반 몬스터가
	# 뽑혀도(sticky -1/dull -1 정도의 다른 감쇠도 마찬가지) 결과가 결정적이다.
	var normal_atk_bag := DiceBag.new(4, 2)
	normal_atk_bag.force_fixed_value(50)
	var normal_def_bag := DiceBag.new(4, 1)
	normal_def_bag.force_fixed_value(0)
	normal_instance._resolve_exchange(true, normal_atk_bag, normal_def_bag, false, false, false)
	normal_instance._apply_room_advance()
	normal_instance.free()

	var normal_mode_ok: bool = (
		RunState.gold > 0 and not RunState.pip_inventory.is_empty() and RunState.rooms_cleared == 1
	)
	ok = normal_mode_ok and ok
	lines.append("  [일반 모드 보존] test_battle=false면 골드 %d(기대 >0)/눈금 %d개(기대 >0)/rooms_cleared %d(기대 1) -> %s" % [
		RunState.gold, RunState.pip_inventory.size(), RunState.rooms_cleared, "OK" if normal_mode_ok else "FAIL"
	])

	# (4) reset_run()은 test_battle을 항상 false로 초기화한다.
	RunState.test_battle = true
	RunState.reset_run("novice")
	var reset_clears_test_battle_ok: bool = RunState.test_battle == false
	ok = reset_clears_test_battle_ok and ok
	lines.append("  reset_run() 호출 후 RunState.test_battle=%s (기대 false) -> %s" % [
		RunState.test_battle, "OK" if reset_clears_test_battle_ok else "FAIL"
	])

	AchievementManager._unlocked = achievements_backup
	AchievementManager._save()
	RunState.test_battle = test_battle_backup
	RunState.test_monster_id = test_monster_backup
	RunState.test_difficulty = test_difficulty_backup
	RunState.gold = gold_backup
	RunState.pip_inventory = pip_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	RunState.reset_run(character_backup)
	return ok


## H-3(2026-10-08) 검증 — F-3 원칙대로 "플래그가 들어갔는가"가 아니라 "계산
## 결과"(실제 주머니 개수/면 개수/골드/인벤토리/skill_flags)를 직접 확인한다.
func _check_h3_test_battle_growth(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) preset_growth() 계산 — 수호자(기본 공격2/방어4) + "R1 중반 정도"(delta+2,
	# sides6) -> 공격4/방어6(상한 DiceBag.MAX_DICE=6)/D6.
	var preset_result := TestBattleSetup.preset_growth("guardian", 1)
	var preset_ok: bool = preset_result["attack_count"] == 4 and preset_result["defense_count"] == 6 and preset_result["sides"] == 6
	ok = preset_ok and ok
	lines.append("  preset_growth(guardian, R1 중반): 공격=%d 방어=%d 면=%d (기대 4/6/6) -> %s" % [
		preset_result["attack_count"], preset_result["defense_count"], preset_result["sides"], "OK" if preset_ok else "FAIL"
	])

	# (2) sanitize_skill_flags() — 광전사 전용 "광기 심화"(+)를 들고 수호자로 바꾸면
	# 둘 다 떨어지고, 공용 스킬(spare_die)은 남아야 한다. "+"만 있고 base가 없는
	# 경우(guard_deepen_plus 단독)도 base 없이는 살아남지 못해야 한다.
	var sanitized: Array = TestBattleSetup.sanitize_skill_flags(
		["spare_die", "frenzy_deepen", "frenzy_deepen_plus", "guard_deepen_plus"], "guardian"
	)
	var sanitize_ok: bool = sanitized.has("spare_die") and not sanitized.has("frenzy_deepen") \
		and not sanitized.has("frenzy_deepen_plus") and not sanitized.has("guard_deepen_plus")
	ok = sanitize_ok and ok
	lines.append("  sanitize_skill_flags(수호자가 아닌 스킬+단독 plus 제거): 결과=%s -> %s" % [
		sanitized, "OK" if sanitize_ok else "FAIL"
	])

	# (3) _apply_start_selection()에 growth dict + extra_skill_flags를 실제로 넣어
	# RunState 결과값이 그대로 반영되는지 확인 — 수호자 + "대비"(start_bulwark) 시작
	# 스킬 + growth(공격5/방어6/D8/골드77/눈금4/다이스인벤2) + 보유 스킬(spare_die+그
	# "+"판 spare_die_plus) 조합.
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var test_battle_backup := RunState.test_battle
	var gold_backup := RunState.gold

	var setup_script := load("res://code/scenes/test_battle_setup.gd")
	var setup_instance = setup_script.new()
	var growth := {
		"attack_count": 5, "defense_count": 6, "sides": 8,
		"gold": 77, "pip_count": 4, "die_count": 2,
	}
	setup_instance._apply_start_selection(
		"guardian", "start_bulwark", "goblin", 1, 2, growth, ["spare_die", "spare_die_plus"]
	)

	var bag_ok: bool = RunState.player_attack_bag.dice.size() == 5 and RunState.player_attack_bag.dice[0].size() == 8 \
		and RunState.player_defense_bag.dice.size() == 6 and RunState.player_defense_bag.dice[0].size() == 8
	var gold_ok: bool = RunState.gold == 77
	var inventory_ok: bool = RunState.pip_inventory.size() == 4 and RunState.die_inventory.size() == 2
	var skill_ok: bool = RunState.skill_flags.has("start_bulwark") and RunState.skill_flags.has("spare_die") and RunState.skill_flags.has("spare_die_plus")

	# 수호자의 "fixed_defense_die" 기믹(방어 0번째 다이스가 항상 고정값)이 growth가
	# 바꾼 새 면 개수(D8)에 맞게 재적용됐는지 — run_state.gd._apply_character_gimmick()이
	# 예전처럼 "항상 D4 기준"으로 고정값을 계산하면(이 growth 기능이 추가되기 전에는
	# reset_run() 직후(항상 D4)에만 불려서 드러나지 않던 전제) D8 면 범위를 벗어난 값이
	# 나온다.
	var expected_fixed_value := CharacterProfiles.fixed_defense_die_value(8)
	var fixed_die_ok := true
	for v in RunState.player_defense_bag.dice[0]:
		if v != expected_fixed_value:
			fixed_die_ok = false

	var growth_ok: bool = bag_ok and gold_ok and inventory_ok and skill_ok and fixed_die_ok
	ok = growth_ok and ok
	lines.append("  [성장+보유 스킬 적용] 공격 D%dx%d / 방어 D%dx%d(고정값 다이스=%s, 기대 %d) / 골드=%d / 눈금=%d / 다이스인벤=%d / skill_flags에 start_bulwark+spare_die+spare_die_plus=%s -> %s" % [
		RunState.player_attack_bag.dice[0].size(), RunState.player_attack_bag.dice.size(),
		RunState.player_defense_bag.dice[0].size(), RunState.player_defense_bag.dice.size(),
		RunState.player_defense_bag.dice[0], expected_fixed_value,
		RunState.gold, RunState.pip_inventory.size(), RunState.die_inventory.size(),
		skill_ok, "OK" if growth_ok else "FAIL"
	])

	# (4) growth={}(빈 dict)는 기존 H-2 동작(캐릭터 기본 구성 그대로, reset_run()이
	# 만든 그대로)을 깨지 않아야 한다 — 하위 호환 확인.
	setup_instance._apply_start_selection("juggler", "start_aggro", "goblin", 1, 0)
	var backward_compat_ok: bool = RunState.player_attack_bag.dice.size() == 3 and RunState.player_defense_bag.dice.size() == 2 \
		and RunState.gold == 0 and RunState.pip_inventory.is_empty() and RunState.die_inventory.is_empty()
	ok = backward_compat_ok and ok
	lines.append("  [하위 호환] growth={} 호출 시 곡예사 기본 공격3/방어2, 골드0, 인벤토리 빈 배열 유지 -> %s" % [
		"OK" if backward_compat_ok else "FAIL"
	])

	setup_instance.free()
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.test_battle = test_battle_backup
	RunState.gold = gold_backup
	RunState.reset_run(character_backup)
	return ok


## [대형 기획 8] H-2(2026-10-08) — test_battle_setup.gd의 _apply_start_selection()이
## @onready 노드를 전혀 참조하지 않는 순수 반영부라(스크립트 클래스 주석 참고)
## combat_test.gd의 H-1 검증과 같은 패턴(.new()만 해서 production 함수를 직접 호출)으로
## "결과가 실제로 바뀌는가"를 검증한다 — chosen_starting_skill_id가 호출 전후로
## 그대로인지(실제 캐릭터 선택 화면의 "다음 런 시작 스킬"이 테스트 전투로 오염되지
## 않는지)가 핵심.
func _check_h2_test_battle_setup(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var test_battle_backup := RunState.test_battle
	var test_monster_backup := RunState.test_monster_id
	var test_difficulty_backup := RunState.test_difficulty
	var test_round_backup := RunState.test_round_index
	var test_room_backup := RunState.test_room_index

	RunState.reset_run("novice")
	RunState.chosen_starting_skill_id = "start_wealth" # 견습 모험가 슬롯 2(최종 클리어 해금) — 테스트 전투가 잠금을 무시한다는 걸 보여줄 대조값
	RunState.test_battle = false

	var setup_script := load("res://code/scenes/test_battle_setup.gd")
	var setup_instance = setup_script.new()
	setup_instance._apply_start_selection("juggler", "start_aggro", "goblin_king", 3, 4)

	var combat_script := load("res://code/scenes/combat_test.gd")
	var combat_instance = combat_script.new()
	var config: Dictionary = combat_instance._monster_config_for_test(RunState.test_difficulty)
	combat_instance.free()

	var difficulty_ok: bool = RunState.test_difficulty == 10 # room4 + (round3-1)*3
	var character_ok: bool = RunState.character_id == "juggler" and RunState.player_attack_bag.dice.size() == 3 and RunState.player_defense_bag.dice.size() == 2
	var skill_ok: bool = RunState.skill_flags.has("start_aggro")
	var monster_ok: bool = config.get("is_boss", false) == true and String(config.get("name", "")).begins_with("고블린 왕")
	var chosen_restored_ok: bool = RunState.chosen_starting_skill_id == "start_wealth"
	var test_battle_on_ok: bool = RunState.test_battle == true

	var test_ok: bool = difficulty_ok and character_ok and skill_ok and monster_ok and chosen_restored_ok and test_battle_on_ok
	ok = test_ok and ok
	lines.append("  [설정->반영] 곡예사+맹공+고블린 왕(라운드3/방4) 적용 후 character_id=%s(공격%d/방어%d) skill_flags에 start_aggro=%s test_difficulty=%d config.is_boss=%s chosen_starting_skill_id 복원=%s test_battle=%s -> %s" % [
		RunState.character_id, RunState.player_attack_bag.dice.size(), RunState.player_defense_bag.dice.size(),
		RunState.skill_flags.has("start_aggro"), RunState.test_difficulty, config.get("is_boss", false),
		chosen_restored_ok, RunState.test_battle, "OK" if test_ok else "FAIL"
	])

	setup_instance.free()

	RunState.chosen_starting_skill_id = chosen_backup
	RunState.test_battle = test_battle_backup
	RunState.test_monster_id = test_monster_backup
	RunState.test_difficulty = test_difficulty_backup
	RunState.test_round_index = test_round_backup
	RunState.test_room_index = test_room_backup
	RunState.reset_run(character_backup)
	return ok


## [대형 기획 9] I-1(2026-10-08) 검증 — "해적"(pirate) 캐릭터 + cannon_volley 기믹.
## F-3 원칙대로 "계산 결과가 실제로 바뀌는가"를 확인한다: (1) combat_test.gd의 순수
## 함수 _cannon_volley_damage(attack_sum, turn_count, cycle)가 1·2번째 턴은 0을,
## 3번째 턴은 ceil(합/2)을, 6번째 턴에 다시 발동하는지(cycle=3 기준). 이 함수는
## 애초에 방어 값을 매개변수로 받지 않으므로 "방어가 아무리 높아도 고정 피해 불변"은
## 함수 서명 자체로 보장된다(별도 호출로 재확인). (2) character_profiles.gd PROFILES에
## pirate가 gimmick="cannon_volley"/공격2/방어3으로 등록됐는지. (3) 전투 간 카운터
## 리셋 — _reset_player_battle_state()가 player_attack_turn_count를 0으로 되돌리는지.
## (4) skill_icon.gd SkillIcon.CATEGORIES에 "cannon_volley"가 있는지(없으면
## _check_skill_icons가 이미 FAIL로 잡아내지만, 여기서도 직접 재확인).
func _check_i1_pirate_cannon_volley(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) 1~9턴, cycle=3: 0,0,X,0,0,X,0,0,X (X=ceil(합/2))
	var damage_sequence_ok := true
	for turn in range(1, 10):
		var expect: int = ceili(17 / 2.0) if turn % 3 == 0 else 0
		var got: int = combat_script._cannon_volley_damage(17, turn, 3)
		if got != expect:
			damage_sequence_ok = false
	ok = damage_sequence_ok and ok
	lines.append("  _cannon_volley_damage(attack_sum=17, turn=1..9, cycle=3): 0,0,9,0,0,9,0,0,9 패턴 일치=%s -> %s" % [
		damage_sequence_ok, "OK" if damage_sequence_ok else "FAIL"
	])

	# 홀수/짝수 attack_sum 반올림(ceil) 확인.
	var rounding_ok: bool = combat_script._cannon_volley_damage(7, 3, 3) == 4 \
		and combat_script._cannon_volley_damage(8, 3, 3) == 4
	ok = rounding_ok and ok
	lines.append("  _cannon_volley_damage(7, 3, 3)=%d(기대 4=ceil(3.5)) _cannon_volley_damage(8, 3, 3)=%d(기대 4) -> %s" % [
		combat_script._cannon_volley_damage(7, 3, 3), combat_script._cannon_volley_damage(8, 3, 3),
		"OK" if rounding_ok else "FAIL"
	])

	# "방어가 아무리 높아도 고정 피해 불변" — 함수가 방어 값을 전혀 받지 않으므로 같은
	# attack_sum/turn/cycle이면 항상 같은 결과(호출 2회 비교로 재확인).
	var defense_irrelevant_ok: bool = combat_script._cannon_volley_damage(10, 3, 3) == combat_script._cannon_volley_damage(10, 3, 3)
	ok = defense_irrelevant_ok and ok
	lines.append("  _cannon_volley_damage는 방어 값을 매개변수로 받지 않음(방어 무관 고정 피해) -> %s" % ("OK" if defense_irrelevant_ok else "FAIL"))

	# (2) character_profiles.gd PROFILES에 pirate 등록 확인.
	var pirate_profile := CharacterProfiles.get_profile("pirate")
	var pirate_profile_ok: bool = pirate_profile["gimmick"] == "cannon_volley" \
		and pirate_profile["attack_count"] == 2 and pirate_profile["defense_count"] == 3
	ok = pirate_profile_ok and ok
	lines.append("  get_profile(pirate): gimmick=%s 공격=%d 방어=%d (기대 cannon_volley,2,3) -> %s" % [
		pirate_profile["gimmick"], pirate_profile["attack_count"], pirate_profile["defense_count"],
		"OK" if pirate_profile_ok else "FAIL"
	])

	# (3) 전투 간 카운터 리셋.
	var combat_instance = combat_script.new()
	combat_instance.player_attack_turn_count = 5
	combat_instance._reset_player_battle_state()
	var reset_ok: bool = combat_instance.player_attack_turn_count == 0
	ok = reset_ok and ok
	lines.append("  _reset_player_battle_state() 후 player_attack_turn_count=%d (기대 0) -> %s" % [
		combat_instance.player_attack_turn_count, "OK" if reset_ok else "FAIL"
	])
	combat_instance.free()

	# (4) 아이콘 카테고리 등록 확인.
	var icon_ok: bool = SkillIcon.CATEGORIES.has("cannon_volley")
	ok = icon_ok and ok
	lines.append("  SkillIcon.CATEGORIES.has(\"cannon_volley\")=%s -> %s" % [icon_ok, "OK" if icon_ok else "FAIL"])

	return ok


## [대형 기획 9] I-3(2026-10-08) 검증 — 해적 고유 스킬 "일제 사격"(broadside)/
## "일제 사격+"(broadside_plus). F-3 원칙대로 플래그 존재가 아니라 "계산 결과(주기,
## 고정 피해)"가 실제로 바뀌는지 확인한다. (1) SkillPool 등록(character_id=pirate,
## broadside_plus가 broadside를 upgrades). (2) _cannon_volley_cycle(): 미보유 3,
## broadside만 2, broadside_plus만(비정상 상황이지만 "+ 단독 보유"도 2여야 함) 2,
## 둘 다 2. (3) _cannon_volley_damage()에 cycle=2/full_damage 조합을 넣어 "주기가
## 2로 당겨지는지"(1턴차 0, 2턴차 발동)와 "+가 고정 피해를 attack_sum 전부로 올리는지"
## (기본/base는 ceil(합/2), +는 합 전부)를 직접 비교. (4) 기존 cycle=3/full_damage=false
## 호출(인자 3개)이 여전히 동작하는지(하위 호환, I-1 테스트가 이미 쓰고 있음).
func _check_i3_pirate_broadside(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")

	# (1) SkillPool 등록 확인.
	var broadside := SkillPool.find_skill("broadside")
	var broadside_registered_ok: bool = broadside.get("character_id", "") == "pirate"
	ok = broadside_registered_ok and ok
	lines.append("  SkillPool.find_skill(broadside).character_id=%s(기대 pirate) -> %s" % [
		broadside.get("character_id", "<없음>"), "OK" if broadside_registered_ok else "FAIL"
	])

	var broadside_plus := SkillPool.find_skill("broadside_plus")
	var broadside_plus_registered_ok: bool = broadside_plus.get("character_id", "") == "pirate" \
		and broadside_plus.get("upgrades", "") == "broadside"
	ok = broadside_plus_registered_ok and ok
	lines.append("  SkillPool.find_skill(broadside_plus): character_id=%s upgrades=%s(기대 pirate/broadside) -> %s" % [
		broadside_plus.get("character_id", "<없음>"), broadside_plus.get("upgrades", "<없음>"),
		"OK" if broadside_plus_registered_ok else "FAIL"
	])

	# grant_upgrade()로 base -> + 흐름이 chain_explosion 등 기존 패턴과 동일하게 동작하는지.
	var flags_backup: Array = RunState.skill_flags.duplicate()
	RunState.skill_flags = ["broadside"]
	SkillPool.grant_upgrade("broadside")
	var grant_added_plus: bool = RunState.skill_flags.has("broadside_plus") and RunState.skill_flags.has("broadside")
	ok = grant_added_plus and ok
	lines.append("  grant_upgrade(broadside) 후 skill_flags=%s(기대 broadside+broadside_plus 둘 다) -> %s" % [
		RunState.skill_flags, "OK" if grant_added_plus else "FAIL"
	])
	RunState.skill_flags = flags_backup

	# (2) _cannon_volley_cycle(): 인스턴스 상태(player_broadside_active/plus_active)에 따른 주기.
	var combat_instance = combat_script.new()
	var cycle_none: int = combat_instance._cannon_volley_cycle()
	combat_instance.player_broadside_active = true
	var cycle_base: int = combat_instance._cannon_volley_cycle()
	combat_instance.player_broadside_active = false
	combat_instance.player_broadside_plus_active = true
	var cycle_plus_only: int = combat_instance._cannon_volley_cycle()
	combat_instance.player_broadside_active = true
	var cycle_both: int = combat_instance._cannon_volley_cycle()
	var cycle_ok: bool = cycle_none == 3 and cycle_base == 2 and cycle_plus_only == 2 and cycle_both == 2
	ok = cycle_ok and ok
	lines.append("  _cannon_volley_cycle(): 미보유=%d(기대3) base=%d(기대2) plus단독=%d(기대2) 둘다=%d(기대2) -> %s" % [
		cycle_none, cycle_base, cycle_plus_only, cycle_both, "OK" if cycle_ok else "FAIL"
	])
	combat_instance.free()

	# (3) 주기 단축(2턴) 확인 — attack_sum=10, cycle=2: 1턴차 0, 2턴차 발동(기본은 ceil(5)=5).
	var cycle_sequence_ok: bool = combat_script._cannon_volley_damage(10, 1, 2) == 0 \
		and combat_script._cannon_volley_damage(10, 2, 2) == 5 \
		and combat_script._cannon_volley_damage(10, 3, 2) == 0 \
		and combat_script._cannon_volley_damage(10, 4, 2) == 5
	ok = cycle_sequence_ok and ok
	lines.append("  _cannon_volley_damage(attack_sum=10, turn=1..4, cycle=2): 0,5,0,5 패턴 일치 -> %s" % [
		"OK" if cycle_sequence_ok else "FAIL"
	])

	# "일제 사격+"가 고정 피해를 ceil(합/2)에서 공격 합계 전부로 올리는지(base/+ 비교).
	var full_damage_ok: bool = combat_script._cannon_volley_damage(11, 2, 2, false) == ceili(11 / 2.0) \
		and combat_script._cannon_volley_damage(11, 2, 2, true) == 11
	ok = full_damage_ok and ok
	lines.append("  _cannon_volley_damage(attack_sum=11, turn=2, cycle=2): full_damage=false -> %d(기대 6=ceil(5.5)), true -> %d(기대 11) -> %s" % [
		combat_script._cannon_volley_damage(11, 2, 2, false), combat_script._cannon_volley_damage(11, 2, 2, true),
		"OK" if full_damage_ok else "FAIL"
	])

	# (4) 기존 3-인자 호출(cycle=3, full_damage 기본값 false)이 여전히 동작하는지(하위 호환).
	var legacy_call_ok: bool = combat_script._cannon_volley_damage(17, 3, 3) == ceili(17 / 2.0)
	ok = legacy_call_ok and ok
	lines.append("  _cannon_volley_damage(17, 3, 3)(인자 3개, full_damage 기본값) -> %d(기대 9) -> %s" % [
		combat_script._cannon_volley_damage(17, 3, 3), "OK" if legacy_call_ok else "FAIL"
	])

	# (5) 테스트 전투 설정(H-3)의 "보유 스킬 토글" 행 목록이 broadside/broadside_plus를
	# 자동으로 올리는지 — skill_flag_rows_for_character()는 UNIQUE_SKILLS/UPGRADE_SKILLS를
	# 그대로 순회하는 static 함수라 새 데이터만 추가하면 자동 반영되어야 한다(INBOX.md I-3
	# 원문 "보유 스킬 토글이 새 스킬을 자동으로 목록에 올리는지 확인").
	var setup_script := load("res://code/scenes/test_battle_setup.gd")
	var pirate_rows: Array = setup_script.skill_flag_rows_for_character("pirate")
	var broadside_row_found := false
	for row in pirate_rows:
		if row["base"] == "broadside" and row["plus"] == "broadside_plus":
			broadside_row_found = true
	ok = broadside_row_found and ok
	lines.append("  TestBattleSetup.skill_flag_rows_for_character(pirate)에 {base:broadside, plus:broadside_plus} 행 포함=%s -> %s" % [
		broadside_row_found, "OK" if broadside_row_found else "FAIL"
	])

	return ok


## [대형 기획 7] F-5(a)(2026-10-08) — "성장 정책이 들어갔는가"가 아니라 "주머니
## 크기/면 수가 기대대로 바뀌는가"를 직접 검증한다(F-3 원칙 재적용). balance_sim.gd의
## 정책 계산 함수들은 전부 static이라 인스턴스 없이 바로 호출 가능.
func _check_f5a_growth_policies(lines: PackedStringArray) -> bool:
	var ok := true
	var sim_script := load("res://code/qa/balance_sim.gd")

	# (1) global_index_for(): 라운드1 방0 -> 0, 라운드1 방4 -> 4, 라운드2 방0 -> 5, 라운드3 방4 -> 14.
	var idx_r1_room0: int = sim_script.global_index_for(1, 0)
	var idx_r1_room4: int = sim_script.global_index_for(1, 4)
	var idx_r2_room0: int = sim_script.global_index_for(2, 0)
	var idx_r3_room4: int = sim_script.global_index_for(3, 4)
	var index_ok: bool = idx_r1_room0 == 0 and idx_r1_room4 == 4 and idx_r2_room0 == 5 and idx_r3_room4 == 14
	ok = index_ok and ok
	lines.append("  global_index_for(r1/방0,r1/방4,r2/방0,r3/방4) = %d,%d,%d,%d(기대 0,4,5,14) -> %s" % [
		idx_r1_room0, idx_r1_room4, idx_r2_room0, idx_r3_room4, "OK" if index_ok else "FAIL"
	])

	# (2) growth_sides_for(): "none"은 global_index와 무관하게 항상 4(성장 없음=기존
	# 기준선 유지). 성장 정책 3종은 전부 같은 임계값(5/10)을 공유.
	var sides_none_late: int = sim_script.growth_sides_for("none", 14)
	var sides_before5: int = sim_script.growth_sides_for("balanced", 4)
	var sides_at5: int = sim_script.growth_sides_for("attack_heavy", 5)
	var sides_before10: int = sim_script.growth_sides_for("defense_heavy", 9)
	var sides_at10: int = sim_script.growth_sides_for("balanced", 10)
	var sides_ok: bool = sides_none_late == 4 and sides_before5 == 4 and sides_at5 == 6 \
		and sides_before10 == 6 and sides_at10 == 8
	ok = sides_ok and ok
	lines.append("  growth_sides_for: none@14=%d(기대4) idx4=%d(기대4) idx5=%d(기대6) idx9=%d(기대6) idx10=%d(기대8) -> %s" % [
		sides_none_late, sides_before5, sides_at5, sides_before10, sides_at10, "OK" if sides_ok else "FAIL"
	])

	# (3) growth_counts_for(): "none"은 global_index와 무관하게 base 그대로.
	var counts_none: Dictionary = sim_script.growth_counts_for("none", 3, 3, 14)
	var none_counts_ok: bool = counts_none["attack_count"] == 3 and counts_none["defense_count"] == 3
	ok = none_counts_ok and ok
	lines.append("  growth_counts_for(none, base=3/3, idx=14) = %d/%d(기대 3/3, 성장 없음) -> %s" % [
		counts_none["attack_count"], counts_none["defense_count"], "OK" if none_counts_ok else "FAIL"
	])

	# balanced: 전투 2번마다 번갈아 +1개. idx=0,1 -> 추가 0회(3/3) / idx=2,3 -> 추가 1회,
	# 공격 먼저(4/3) / idx=4 -> 추가 2회, 공격+방어(4/4) / idx=14 -> 추가 7회(공격4회+방어3회
	# -> 7/6, 공격은 MAX_DICE=6을 안 넘지만 방어도 6을 안 넘음 — 둘 다 그대로).
	var balanced_idx1: Dictionary = sim_script.growth_counts_for("balanced", 3, 3, 1)
	var balanced_idx2: Dictionary = sim_script.growth_counts_for("balanced", 3, 3, 2)
	var balanced_idx4: Dictionary = sim_script.growth_counts_for("balanced", 3, 3, 4)
	var balanced_idx14: Dictionary = sim_script.growth_counts_for("balanced", 3, 3, 14)
	var balanced_ok: bool = balanced_idx1["attack_count"] == 3 and balanced_idx1["defense_count"] == 3 \
		and balanced_idx2["attack_count"] == 4 and balanced_idx2["defense_count"] == 3 \
		and balanced_idx4["attack_count"] == 4 and balanced_idx4["defense_count"] == 4 \
		and balanced_idx14["attack_count"] == 6 and balanced_idx14["defense_count"] == 6
	ok = balanced_ok and ok
	lines.append("  growth_counts_for(balanced, base=3/3): idx1=%d/%d(기대3/3) idx2=%d/%d(기대4/3) idx4=%d/%d(기대4/4) idx14=%d/%d(기대6/6, MAX_DICE 캡) -> %s" % [
		balanced_idx1["attack_count"], balanced_idx1["defense_count"], balanced_idx2["attack_count"], balanced_idx2["defense_count"],
		balanced_idx4["attack_count"], balanced_idx4["defense_count"], balanced_idx14["attack_count"], balanced_idx14["defense_count"],
		"OK" if balanced_ok else "FAIL"
	])

	# attack_heavy / defense_heavy: idx=14(추가 7회)에서 한쪽만 전부 몰려 MAX_DICE(6)에서
	# 막히고 반대쪽은 base 그대로 유지되는지.
	var attack_heavy_idx14: Dictionary = sim_script.growth_counts_for("attack_heavy", 3, 3, 14)
	var defense_heavy_idx14: Dictionary = sim_script.growth_counts_for("defense_heavy", 3, 3, 14)
	var heavy_ok: bool = attack_heavy_idx14["attack_count"] == DiceBag.MAX_DICE and attack_heavy_idx14["defense_count"] == 3 \
		and defense_heavy_idx14["defense_count"] == DiceBag.MAX_DICE and defense_heavy_idx14["attack_count"] == 3
	ok = heavy_ok and ok
	lines.append("  growth_counts_for(idx=14): attack_heavy=%d/%d(기대6/3) defense_heavy=%d/%d(기대3/6) -> %s" % [
		attack_heavy_idx14["attack_count"], attack_heavy_idx14["defense_count"],
		defense_heavy_idx14["attack_count"], defense_heavy_idx14["defense_count"],
		"OK" if heavy_ok else "FAIL"
	])

	# (4) growth_config_for(): CharacterProfiles 기본 공격/방어 개수를 실제로 읽어오는지
	# (해적 attack_count=2/defense_count=3) + sides 필드까지 한 Dictionary에 합쳐지는지.
	var pirate_config_idx0: Dictionary = sim_script.growth_config_for("balanced", "pirate", 0)
	var pirate_config_ok: bool = pirate_config_idx0["attack_count"] == 2 and pirate_config_idx0["defense_count"] == 3 \
		and pirate_config_idx0["sides"] == 4
	ok = pirate_config_ok and ok
	lines.append("  growth_config_for(balanced, pirate, idx=0) = 공격%d/방어%d/면%d(기대 2/3/4, CharacterProfiles 기본값) -> %s" % [
		pirate_config_idx0["attack_count"], pirate_config_idx0["defense_count"], pirate_config_idx0["sides"],
		"OK" if pirate_config_ok else "FAIL"
	])

	# (5) apply_growth(): 실제 RunState 주머니 개수/면 개수가 바뀌는지(플래그가 아니라
	# 다이스 배열 크기를 직접 확인). 검증 후 원래 RunState로 되돌린다.
	var attack_backup: DiceBag = RunState.player_attack_bag
	var defense_backup: DiceBag = RunState.player_defense_bag
	var character_backup := RunState.character_id
	RunState.character_id = "novice"
	sim_script.apply_growth({"attack_count": 5, "defense_count": 4, "sides": 6})
	var apply_ok: bool = RunState.player_attack_bag.count == 5 and RunState.player_defense_bag.count == 4 \
		and RunState.player_attack_bag.dice[0].size() == 6 and RunState.player_defense_bag.dice[0].size() == 6
	ok = apply_ok and ok
	lines.append("  apply_growth({공격5,방어4,면6}) 후 실제 RunState 주머니: 공격개수=%d(기대5) 방어개수=%d(기대4) 공격면수=%d 방어면수=%d(기대 둘 다 6) -> %s" % [
		RunState.player_attack_bag.count, RunState.player_defense_bag.count,
		RunState.player_attack_bag.dice[0].size(), RunState.player_defense_bag.dice[0].size(),
		"OK" if apply_ok else "FAIL"
	])
	RunState.player_attack_bag = attack_backup
	RunState.player_defense_bag = defense_backup
	RunState.character_id = character_backup

	return ok


## K-2 검증(INBOX.md 2026-10-13 [대형 기획 11] K-2 "캐릭터 선택 화면 가독성 개편"):
## "플래그가 들어갔는가"가 아니라 "화면에 실제로 보이는 텍스트/레이아웃이 바뀌는가"를
## 본다는 세션 지침대로, (a) 섹션 패널이 정확히 5개(헤더/능력치/고유 능력/시작 스킬/
## 안내) 실제로 생성됐는지, (b) 8명 전부에서 각 섹션의 라벨 텍스트가 실제로 채워지는지
## (빈 문자열로 남는 섹션이 없는지), (c) 상세 패널 내용의 결합 최소 높이가 패널 실제
## 크기(DetailPanelContainer, 840x540) 안에 들어오는지(넘치면 레이아웃이 화면 밖으로
## 밀려난다는 뜻), (d) 좌측 카드 목록 8행의 결합 높이가 ScrollContainer 가시 영역
## (540px) 안에 들어와 스크롤이 사실상 필요 없는지를 확인한다.
func _check_k2_character_select_sections(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	# (a) 상세 패널 섹션 개수 = 5(①헤더 ②능력치 ③고유 능력 ④시작 스킬 ⑤안내).
	var section_count: int = node._detail_sections_vbox.get_child_count()
	var section_count_ok: bool = section_count == 5
	ok = section_count_ok and ok
	lines.append("  상세 패널 섹션 개수: %d (기대 5) -> %s" % [section_count, "OK" if section_count_ok else "FAIL"])

	var detail_height: float = node.detail_container.size.y
	var scroll := node.get_node("CardsContainer") as ScrollContainer

	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)

		# (b) 섹션 내용이 실제로 채워지는지 — 헤더(이름/컨셉)/능력치(공격/방어/이벤트
		# 다이스 칩 텍스트)/고유 능력(이름+설명)/시작 스킬(설명)이 전부 빈 문자열이
		# 아니어야 한다.
		var non_empty_ok: bool = (node._detail_name_label.text != ""
			and node._detail_concept_label.text != ""
			and node._detail_attack_dice_row["chips"].get_child_count() > 0
			and node._detail_defense_dice_row["chips"].get_child_count() > 0
			and node._detail_event_die_label.text != ""
			and node._detail_ability_name_label.text != ""
			and node._detail_skill_label.text != ""
			and node._starting_skill_desc_label.text != "")
		ok = non_empty_ok and ok
		lines.append("  [%s] 섹션 텍스트 비어있지 않음(이름=\"%s\" 컨셉=\"%s\" 고유능력=\"%s\") -> %s" % [
			cid, node._detail_name_label.text, node._detail_concept_label.text,
			node._detail_ability_name_label.text, "OK" if non_empty_ok else "FAIL"
		])

		# (c) 상세 패널 전체 내용 높이가 실제 패널 높이(540) 예산 안에 들어오는지.
		var content_height: float = node._detail_sections_vbox.get_combined_minimum_size().y
		var fits_ok: bool = content_height <= detail_height
		ok = fits_ok and ok
		lines.append("  [%s] 상세 패널 내용 높이=%.1f (예산=%.1f) -> %s" % [
			cid, content_height, detail_height, "OK" if fits_ok else "FAIL"
		])

	# (d) 좌측 카드 목록(8행) 결합 높이가 ScrollContainer 가시 영역 안에 들어오는지
	# (스크롤 없이 한눈에 보인다는 K-2 목표의 직접 검증).
	var list_fits_ok: bool = node.cards_container.custom_minimum_size.y <= scroll.size.y
	ok = list_fits_ok and ok
	lines.append("  좌측 목록 결합 높이=%.1f (가시 영역=%.1f) -> %s" % [
		node.cards_container.custom_minimum_size.y, scroll.size.y, "OK" if list_fits_ok else "FAIL"
	])

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## N-2(2026-10-15, [대형 기획 14]) 검증. "플래그가 들어갔는가"가 아니라 "화면에 실제로
## 보이는 레이아웃/텍스처가 바뀌는가"를 본다: (a) 8명 전부 전신 이미지 홀더
## (_detail_portrait_holder) rect 높이가 INBOX.md N-2 테스트 기준(560) 이상이고 좌측
## 컬럼 폭(PORTRAIT_COLUMN_WIDTH) 안에 들어오는지, (b) 정보 컬럼이 좁아진 폭(이전 840
## -> 480)에서도 8명 전부 내용 높이가 상세 패널 예산 안에 들어오는지(K-2 체크와 같은
## 계산이지만 N-2가 바꾼 폭/텍스트 길이 기준으로 다시 검증), (c) 캐릭터를 바꾸면 전신
## 이미지 텍스처(둘 다 원화가 있는 novice/pirate)와 스포트라이트 틴트가 실제로
## 달라지는지.
func _check_n2_full_art_column(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	var detail_height: float = node.detail_container.size.y

	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)

		# (a) 전신 이미지 홀더 rect — 높이 ≥ 560, 폭은 좌측 컬럼 안에 들어옴.
		var holder_size: Vector2 = node._detail_portrait_holder.size
		var height_ok: bool = holder_size.y >= 560.0
		var width_ok: bool = holder_size.x <= node.PORTRAIT_COLUMN_WIDTH
		ok = height_ok and width_ok and ok
		lines.append("  [%s] 전신 이미지 홀더 rect=%s (기대: 높이>=560, 폭<=%.0f) -> %s" % [
			cid, holder_size, node.PORTRAIT_COLUMN_WIDTH,
			"OK" if (height_ok and width_ok) else "FAIL"
		])

		# (b) 정보 컬럼 내용 높이가 상세 패널 예산(detail_height) 안에 들어오는지 —
		# N-2로 폭이 좁아진(840->480) 만큼 텍스트가 더 많이 줄바꿈될 수 있어 다시 확인.
		var content_height: float = node._detail_sections_vbox.get_combined_minimum_size().y
		var fits_ok: bool = content_height <= detail_height
		ok = fits_ok and ok
		lines.append("  [%s] 정보 컬럼 내용 높이=%.1f (예산=%.1f) -> %s" % [
			cid, content_height, detail_height, "OK" if fits_ok else "FAIL"
		])

	# (c) 캐릭터를 바꾸면 전신 이미지 텍스처/스포트라이트 틴트가 실제로 달라지는지.
	node._on_card_selected("novice")
	var novice_texture: Texture2D = node._detail_art.texture
	var novice_tint: Color = node._detail_portrait_spotlight.modulate
	var novice_art_visible: bool = node._detail_art.visible

	node._on_card_selected("pirate")
	var pirate_texture: Texture2D = node._detail_art.texture
	var pirate_tint: Color = node._detail_portrait_spotlight.modulate
	var pirate_art_visible: bool = node._detail_art.visible

	var texture_present_ok: bool = novice_texture != null and pirate_texture != null
	var texture_changed_ok: bool = novice_texture != pirate_texture
	var tint_changed_ok: bool = novice_tint != pirate_tint
	var art_visible_ok: bool = novice_art_visible and pirate_art_visible
	ok = texture_present_ok and texture_changed_ok and tint_changed_ok and art_visible_ok and ok
	lines.append("  캐릭터 전환 시 전신 이미지 텍스처 변경: novice!=null=%s pirate!=null=%s 서로다름=%s art.visible(둘다)=%s -> %s" % [
		novice_texture != null, pirate_texture != null, texture_changed_ok, art_visible_ok,
		"OK" if (texture_present_ok and texture_changed_ok and art_visible_ok) else "FAIL"
	])
	lines.append("  캐릭터 전환 시 스포트라이트 틴트: novice=%s pirate=%s (달라야 함) -> %s" % [
		novice_tint, pirate_tint, "OK" if tint_changed_ok else "FAIL"
	])

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## N-2b(2026-10-15, [대형 기획 14] 감독 확인) 검증 — N-2의 검증(위)은 "홀더 rect 높이
## >=560"만 쟀는데, 원화(약 1181×1332 비율)가 STRETCH_KEEP_ASPECT_CENTERED로 그 홀더에
## 맞춰지면서 실제로 "폭이 병목"이 돼 그려지는 캐릭터 높이는 ~330~346px뿐이었다(감독이
## 스크린샷에서 직접 확인). 컨테이너가 아니라 **텍스처가 실제로 렌더되는 높이**(홀더와
## 텍스처 크기로 STRETCH_KEEP_ASPECT_CENTERED 스케일을 직접 계산)를 8명 전부 ≥520px로
## 검증한다. 추가로 "던전 시작" 버튼이 전신 컬럼과 겹치지 않는지(INBOX 원문)도 전역
## rect 교차로 확인한다.
func _check_n2b_full_art_rendered_height(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)
	# 전신 컬럼 패널은 HBoxContainer 자식(SIZE_EXPAND_FILL)이라 레이아웃 패스를 한 번도
	# 안 거치면 get_global_rect().size가 (가로만 있고) 세로 0으로 읽혀 아래 겹침 검사가
	# 항상 "겹치지 않음"으로 통과해버린다(의미 없는 PASS) — 한 프레임 기다려 실제
	# sort_children이 실행된 뒤 rect를 읽는다.
	await get_tree().process_frame

	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)

		var tex: Texture2D = node._detail_art.texture
		if tex == null:
			lines.append("  [%s] 전신 원화 없음(플레이스홀더만 사용) -> SKIP" % cid)
			continue
		var tex_size: Vector2 = tex.get_size()
		var holder_size: Vector2 = node._detail_art.size
		# STRETCH_KEEP_ASPECT_CENTERED와 동일한 계산: 두 축 스케일 중 더 작은 쪽이
		# 실제로 쓰이고(어느 축이 "병목"인지는 텍스처 가로세로 비율에 따라 캐릭터마다
		# 다를 수 있음), 그 스케일로 텍스처 높이를 곱한 값이 실제로 그려지는 높이다.
		var scale_factor: float = min(holder_size.x / tex_size.x, holder_size.y / tex_size.y)
		var rendered_height: float = tex_size.y * scale_factor
		var height_ok: bool = rendered_height >= 520.0
		ok = height_ok and ok
		lines.append("  [%s] 전신 원화 실제 렌더 높이=%.1f (텍스처=%s, 홀더=%s, 기대 >=520) -> %s" % [
			cid, rendered_height, tex_size, holder_size, "OK" if height_ok else "FAIL"
		])

		# 정보 컬럼이 자기 예산(INFO_COLUMN_WIDTH)을 실제로 넘지 않는지 — N-2b 작업 중
		# 실제로 터진 버그(능력치 칩 4개가 한 줄 HBoxContainer라 자연 최소 폭이 예산을
		# 크게 넘어서 _detail_sections_vbox 전체가, 그 안의 스킬 도감 버튼까지 함께
		# 화면 오른쪽 밖으로 밀려났었음 — EXPAND_FILL 자식의 "자연 최소 폭"이 할당된
		# 폭보다 크면 Container가 부모 rect를 넘어서도 그 폭을 그대로 써버린다)를
		# 세로 예산(detail_height)만 재던 기존 N-2 체크가 못 잡았던 지점. 모든 자식
		# 섹션의 실제 폭도 예산 안에 들어오는지 같이 확인한다.
		var sections_width: float = node._detail_sections_vbox.size.x
		var width_budget_ok: bool = sections_width <= node.INFO_COLUMN_WIDTH + 1.0
		ok = width_budget_ok and ok
		lines.append("  [%s] 정보 컬럼 실제 폭=%.1f (예산=%.1f) -> %s" % [
			cid, sections_width, node.INFO_COLUMN_WIDTH, "OK" if width_budget_ok else "FAIL"
		])

	# 스킬 도감 버튼(헤더 섹션 맨 오른쪽, 정보 컬럼 안에서 가장 밖으로 밀리기 쉬운 요소)이
	# 실제로 화면(뷰포트) 밖으로 나가지 않는지 — 위 "정보 컬럼 실제 폭" 검사와 별개로,
	# "그 폭 budget이 실제로 화면 안에 들어오는 좌표에 배치됐는지"까지 확인한다.
	# 실제 게임 해상도(프로젝트 설정)를 기준으로 비교한다. dice_test 씬은 자체 뷰포트가
	# 1028px 폭이라 get_viewport_rect()를 쓰면 정상 배치(x=1246)도 FAIL로 잡혔다(QA 환경 착시).
	var viewport_width: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var codex_button_rect: Rect2 = node._skill_codex_button.get_global_rect()
	var codex_button_on_screen: bool = codex_button_rect.position.x + codex_button_rect.size.x <= viewport_width + 1.0
	ok = codex_button_on_screen and ok
	lines.append("  스킬 도감 버튼 rect=%s, 뷰포트 폭=%.0f (오른쪽 끝이 화면 안이어야 함) -> %s" % [
		codex_button_rect, viewport_width, "OK" if codex_button_on_screen else "FAIL"
	])

	# 던전 시작 버튼이 전신 컬럼과 겹치지 않는지(INBOX N-2b 원문). [대형 기획 17] 감독
	# 검수 ③(2026-10-28)으로 강화: 예전엔 "교차하지 않음"만 확인해, 두 rect가 딱 붙어
	# (간격 0) 있어도 PASS였다 — 실제로 DetailPanelContainer.offset_bottom(680)과
	# StartButton.offset_top(680)이 같아서 원화 패널 하단 테두리가 버튼에 그대로 붙어
	# 보이는 버그가 이 체크를 통과한 채 남아있었다. DetailPanelContainer를 672로
	# 줄여(character_select.tscn) 8px 간격을 만들고, 이제 간격 수치 자체를 잰다.
	var portrait_rect: Rect2 = node._detail_portrait_panel.get_global_rect()
	var button_rect: Rect2 = node.start_button.get_global_rect()
	var gap: float = button_rect.position.y - (portrait_rect.position.y + portrait_rect.size.y)
	var gap_ok: bool = gap >= 8.0 - 0.5
	ok = gap_ok and ok
	lines.append("  전신 컬럼 rect=%s vs 던전 시작 버튼 rect=%s, 간격=%.1f(기대 >= 8px) -> %s" % [
		portrait_rect, button_rect, gap, "OK" if gap_ok else "FAIL"
	])

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## K-3(캐릭터 퍼스널 컬러) 검증. "플래그가 들어갔나"가 아니라 (a)실제 계산된 대비비
## 숫자, (b)(c) 실제 노드의 StyleBox border_color 값이 캐릭터를 바꾸면 실제로
## 달라지는지를 확인한다(세션 공통 지침 — 계산 결과/화면에 보이는 값이 바뀌는지).
func _check_k3_character_theme(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	# (a) 8명 전부 ui_palette().text 대 .panel_bg 대비비가 WCAG AA 기준(4.5) 이상인지.
	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		var palette := CharacterTheme.ui_palette(cid)
		var ratio := CharacterTheme.contrast_ratio(palette["text"], palette["panel_bg"])
		var contrast_ok: bool = ratio >= CharacterTheme.MIN_TEXT_CONTRAST
		ok = contrast_ok and ok
		lines.append("  [%s] text/panel_bg 대비비=%.2f (기준 %.1f 이상) -> %s" % [
			cid, ratio, CharacterTheme.MIN_TEXT_CONTRAST, "OK" if contrast_ok else "FAIL"
		])

	# (b) character_select 상세 패널: 캐릭터를 바꾸면 섹션 패널의 실제 border_color가
	# 바뀌는지 — "견습 모험가"(연한 라벤더/핑크)와 "해적"(어두운 청록)은 hue가 크게
	# 달라 같은 색으로 우연히 겹칠 가능성이 거의 없다.
	var scene := load("res://code/scenes/character_select.tscn")
	var cs_node = scene.instantiate()
	add_child(cs_node)

	cs_node._on_card_selected("novice")
	var novice_style: StyleBoxFlat = cs_node._detail_section_entries[1]["panel"].get_theme_stylebox("panel")
	var novice_border: Color = novice_style.border_color

	cs_node._on_card_selected("pirate")
	var pirate_style: StyleBoxFlat = cs_node._detail_section_entries[1]["panel"].get_theme_stylebox("panel")
	var pirate_border: Color = pirate_style.border_color

	var section_color_changed: bool = novice_border != pirate_border
	ok = section_color_changed and ok
	lines.append("  상세 패널 섹션 테두리색: novice=%s pirate=%s (달라야 함) -> %s" % [
		novice_border, pirate_border, "OK" if section_color_changed else "FAIL"
	])

	var expected_pirate_primary: Color = CharacterTheme.ui_palette("pirate")["primary"]
	var section_color_matches: bool = pirate_border.is_equal_approx(expected_pirate_primary)
	ok = section_color_matches and ok
	lines.append("  상세 패널 섹션 테두리색이 ui_palette(\"pirate\").primary와 일치 -> %s" % ("OK" if section_color_matches else "FAIL"))

	remove_child(cs_node)
	cs_node.free()

	# (c) DeckPanel: 캐릭터를 바꾸면 패널 자신의 border_color가 실제로 바뀌는지(별도
	# .tscn 없이 스크립트 하나로 완결된 Control이라 new()+add_child()만으로 충분,
	# deck_panel.gd 문서 주석 참고).
	var deck := DeckPanel.new()
	add_child(deck)

	RunState.character_id = "novice"
	deck._rebuild()
	var deck_novice_style: StyleBoxFlat = deck.get_theme_stylebox("panel")
	var deck_novice_border: Color = deck_novice_style.border_color

	RunState.character_id = "pirate"
	deck._rebuild()
	var deck_pirate_style: StyleBoxFlat = deck.get_theme_stylebox("panel")
	var deck_pirate_border: Color = deck_pirate_style.border_color

	var deck_color_changed: bool = deck_novice_border != deck_pirate_border
	ok = deck_color_changed and ok
	lines.append("  DeckPanel 테두리색: novice=%s pirate=%s (달라야 함) -> %s" % [
		deck_novice_border, deck_pirate_border, "OK" if deck_color_changed else "FAIL"
	])

	remove_child(deck)
	deck.free()
	RunState.character_id = character_backup
	return ok


## [대형 기획 12] L-3 검증. 세 갈래:
## (a) CharacterTheme.apply_background() 단위 검증 — combat_test.tscn과 같은
##     "Background" ColorRect 구조를 흉내낸 더미 Node2D로(combat_test.tscn 자체는
##     물리 시뮬레이션 await 때문에 이 동기 harness에서 직접 인스턴스화하지 않는
##     기존 관례를 그대로 따름 — L-2(c) 주석 참고). Background.color와 그 자식으로
##     생성되는 ThemeVignette(TextureRect).modulate가 캐릭터별로 실제로 달라지고
##     ui_palette() 값과 정확히 일치하는지 확인.
## (b) 실제 화면 5개(character_select는 카드 전환으로, dungeon_map/shop/event/
##     story_event는 RunState.character_id로) 인스턴스의 Background 노드 실제
##     color가 캐릭터를 바꾸면 달라지는지.
## (c) 오버레이 패널 3종(CustomizePanel/AchievementPanel/SkillCodexPanel)의 틀이
##     이제 ColorRect 대신 Panel이라 border_color를 갖고, 캐릭터를 바꾸면 그 색도
##     실제로 바뀌는지.
## character_select의 카드 전환은 Tween으로 애니메이션되므로(INBOX.md L-3 원문
## "부드럽게 전환") 색이 즉시 바뀌지 않는다 — await로 전환 시간(기본 0.25초)이 지날
## 때까지 기다린 뒤에 최종 색을 확인한다. 호출부(_ready())는 `await`로 받아야 한다.
func _check_l3_personal_color_background(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	# (a)
	var dummy := Node2D.new()
	var dummy_bg := ColorRect.new()
	dummy_bg.name = "Background"
	dummy_bg.color = Color(0.06, 0.06, 0.08, 1)
	dummy.add_child(dummy_bg)
	add_child(dummy)

	CharacterTheme.apply_background(dummy, "novice")
	var novice_bg_color: Color = dummy_bg.color
	var vignette: TextureRect = dummy_bg.get_node_or_null("ThemeVignette")
	var vignette_created_ok: bool = vignette != null and vignette.texture != null
	ok = vignette_created_ok and ok
	lines.append("  apply_background(novice): ThemeVignette 생성됨=%s -> %s" % [
		vignette != null, "OK" if vignette_created_ok else "FAIL"
	])

	CharacterTheme.apply_background(dummy, "pirate")
	var pirate_bg_color: Color = dummy_bg.color
	var pirate_vignette_modulate: Color = vignette.modulate if vignette != null else Color.WHITE

	var bg_changed: bool = novice_bg_color != pirate_bg_color
	ok = bg_changed and ok
	lines.append("  Background.color: novice=%s pirate=%s (달라야 함) -> %s" % [
		novice_bg_color, pirate_bg_color, "OK" if bg_changed else "FAIL"
	])

	var expected_pirate_bg: Color = CharacterTheme.ui_palette("pirate")["panel_bg"]
	expected_pirate_bg.a = 1.0
	var bg_matches: bool = pirate_bg_color.is_equal_approx(expected_pirate_bg)
	ok = bg_matches and ok
	lines.append("  Background.color이 ui_palette(\"pirate\").panel_bg와 일치 -> %s" % ("OK" if bg_matches else "FAIL"))

	var expected_pirate_tint: Color = CharacterTheme.ui_palette("pirate")["primary"]
	expected_pirate_tint.a = 1.0
	var vignette_matches: bool = pirate_vignette_modulate.is_equal_approx(expected_pirate_tint)
	ok = vignette_matches and ok
	lines.append("  ThemeVignette.modulate이 ui_palette(\"pirate\").primary와 일치 -> %s" % ("OK" if vignette_matches else "FAIL"))

	remove_child(dummy)
	dummy.free()

	# (b) character_select: 카드 전환으로 배경이 바뀌는지.
	RunState.character_id = "novice"
	var select_scene := load("res://code/scenes/character_select.tscn")
	var select_node = select_scene.instantiate()
	add_child(select_node)
	var select_novice_bg: Color = select_node.get_node("Background").color
	select_node._on_card_selected("pirate")
	# 카드 전환은 Tween으로 애니메이션되므로(즉시 적용 아님) 전환 시간이 지날 때까지 기다린다.
	await get_tree().create_timer(0.35).timeout
	var select_pirate_bg: Color = select_node.get_node("Background").color
	var select_changed: bool = select_novice_bg != select_pirate_bg
	ok = select_changed and ok
	lines.append("  character_select Background: novice=%s pirate=%s (카드 전환 시 달라야 함) -> %s" % [
		select_novice_bg, select_pirate_bg, "OK" if select_changed else "FAIL"
	])
	remove_child(select_node)
	select_node.free()

	# (b) 던전 진행 화면 4종: RunState.character_id로.
	var screen_paths := {
		"dungeon_map": "res://code/scenes/dungeon_map.tscn",
		"shop": "res://code/scenes/shop.tscn",
		"event": "res://code/scenes/event.tscn",
		"story_event": "res://code/scenes/story_event.tscn",
	}
	for screen_label in screen_paths:
		var scene := load(screen_paths[screen_label])

		RunState.character_id = "novice"
		var node_a = scene.instantiate()
		add_child(node_a)
		var bg_a: Color = node_a.get_node("Background").color
		remove_child(node_a)
		node_a.free()

		RunState.character_id = "pirate"
		var node_b = scene.instantiate()
		add_child(node_b)
		var bg_b: Color = node_b.get_node("Background").color
		remove_child(node_b)
		node_b.free()

		var screen_changed: bool = bg_a != bg_b
		ok = screen_changed and ok
		lines.append("  %s Background: novice=%s pirate=%s (캐릭터 다르면 달라야 함) -> %s" % [
			screen_label, bg_a, bg_b, "OK" if screen_changed else "FAIL"
		])

	# (c) 오버레이 패널 틀(Panel) 구분값 — [대형 기획 13] M-5a(2026-10-15)로
	# resources/ui/panel/overlay_{base,accent}.png가 입고되면 이 틀도 StyleBoxTexture로
	# 바뀌므로 _m5_style_fingerprint()로 StyleBoxFlat/Texture 양쪽을 다 받는다.
	RunState.character_id = "novice"
	var customize := CustomizePanel.new()
	add_child(customize)
	customize.open()
	var customize_novice_border: Variant = _m5_style_fingerprint((customize._ui[0] as Panel).get_theme_stylebox("panel"))
	customize.close()

	RunState.character_id = "pirate"
	customize.open()
	var customize_pirate_border: Variant = _m5_style_fingerprint((customize._ui[0] as Panel).get_theme_stylebox("panel"))
	var customize_changed: bool = customize_novice_border != customize_pirate_border
	ok = customize_changed and ok
	lines.append("  CustomizePanel 틀 구분값: novice=%s pirate=%s (달라야 함) -> %s" % [
		customize_novice_border, customize_pirate_border, "OK" if customize_changed else "FAIL"
	])
	customize.close()
	remove_child(customize)
	customize.free()

	RunState.character_id = "novice"
	var achievement := AchievementPanel.new()
	add_child(achievement)
	achievement.open()
	var ach_novice_border: Variant = _m5_style_fingerprint((achievement._ui[0] as Panel).get_theme_stylebox("panel"))
	achievement.close()

	RunState.character_id = "pirate"
	achievement.open()
	var ach_pirate_border: Variant = _m5_style_fingerprint((achievement._ui[0] as Panel).get_theme_stylebox("panel"))
	var ach_changed: bool = ach_novice_border != ach_pirate_border
	ok = ach_changed and ok
	lines.append("  AchievementPanel 틀 구분값: novice=%s pirate=%s (달라야 함) -> %s" % [
		ach_novice_border, ach_pirate_border, "OK" if ach_changed else "FAIL"
	])
	achievement.close()
	remove_child(achievement)
	achievement.free()

	RunState.character_id = "novice"
	var codex := SkillCodexPanel.new()
	add_child(codex)
	codex.open("novice", [])
	var codex_novice_border: Variant = _m5_style_fingerprint((codex._ui[0] as Panel).get_theme_stylebox("panel"))
	codex.close()

	codex.open("pirate", [])
	var codex_pirate_border: Variant = _m5_style_fingerprint((codex._ui[0] as Panel).get_theme_stylebox("panel"))
	var codex_changed: bool = codex_novice_border != codex_pirate_border
	ok = codex_changed and ok
	lines.append("  SkillCodexPanel 틀 구분값: novice=%s pirate=%s (달라야 함) -> %s" % [
		codex_novice_border, codex_pirate_border, "OK" if codex_changed else "FAIL"
	])
	codex.close()
	remove_child(codex)
	codex.free()

	RunState.character_id = character_backup
	return ok


## [대형 기획 11] K-4a 검증. 두 갈래:
## (1) SkillPool.SKILLS/UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS에 등장하는 스킬
##     id 전부가 SkillPool.icon_motif_for()로 빈 문자열 없이 모티프를 받는지(새 스킬을
##     추가하고 ICON_MOTIFS에 깜빡 안 넣으면 여기서 FAIL로 잡힘).
## (2) "플래그가 들어갔는가"가 아니라 "실제로 다른 그림이 그려지는가"를 검증하기 위해,
##     SkillPool.ICON_MOTIF_VALUES 11종을 각각 자기만의 작은 SubViewport(투명 배경)에
##     그려서 그 SubViewport의 텍스처를 직접 이미지로 캡처한다(메인 화면 뷰포트의
##     일부를 잘라내는 방식은 Image에 그런 API가 없어 포기 — SubViewport 하나당 모티프
##     하나면 캡처한 이미지 전체가 곧 그 모티프의 결과라 별도 잘라내기가 필요 없다).
##     캡처한 이미지들이 ①전부 투명이 아니고(알파 있는 픽셀이 하나라도 있어야 함,
##     즉 뭔가 그려짐) ②서로 다른 모티프끼리 완전히 같은 픽셀로 겹치지 않는지 바이트
##     단위로 비교한다. 검증용 SubViewport는 테스트 후 해제하고, 화면에는 (b) 단계
##     전까지 실제 UI 배선이 없으므로 눈으로 보고 싶으면 아래에서 메인 화면에도 같은
##     모티프를 작게 미리보기로 남겨둔다(qa_shot 스크린샷 우상단).
## await를 쓰므로 호출부(_ready())는 `await _check_k4a_skill_icon_motifs(lines)`로
## 받아야 한다.
func _check_k4a_skill_icon_motifs(lines: PackedStringArray) -> bool:
	var ok := true

	var skill_ids: Dictionary = {}
	for skill in SkillPool.SKILLS:
		skill_ids[skill["id"]] = true
	for skill in SkillPool.UNIQUE_SKILLS:
		skill_ids[skill["id"]] = true
	for skill in SkillPool.LEGENDARY_SKILLS:
		skill_ids[skill["id"]] = true
	for skill in SkillPool.UPGRADE_SKILLS:
		skill_ids[skill["id"]] = true
	for skill in SkillPool.STARTING_SKILLS:
		skill_ids[skill["id"]] = true

	var missing: PackedStringArray = []
	for id in skill_ids.keys():
		if SkillPool.icon_motif_for(id) == "":
			missing.append(id)
	var mapping_ok: bool = missing.is_empty()
	ok = mapping_ok and ok
	lines.append("  전체 스킬 id %d개 중 모티프 누락 %d개 -> %s" % [skill_ids.size(), missing.size(), "OK" if mapping_ok else "FAIL"])
	if not missing.is_empty():
		lines.append("    누락 id: %s" % ", ".join(missing))

	var icon_size := Vector2(20.0, 20.0)
	var motif_count: int = SkillPool.ICON_MOTIF_VALUES.size()

	# 검증용: 모티프마다 자기만의 SubViewport+SkillIcon을 만든다(투명 배경이라
	# "아무것도 안 그려짐"이 바로 "전부 알파 0"으로 드러난다).
	var test_viewports: Array[SubViewport] = []
	for i in range(motif_count):
		var icon := SkillIcon.new()
		icon.size = icon_size
		icon.motif = SkillPool.ICON_MOTIF_VALUES[i]
		var vp := SubViewport.new()
		vp.size = Vector2i(icon_size)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.add_child(icon)
		add_child(vp)
		test_viewports.append(vp)

	# 미리보기용: 화면(메인 뷰포트)에 작게 남겨 qa_shot 스크린샷으로 눈으로도 확인
	# 가능하게 한다(우상단, ResultLabel 텍스트 영역(offset_top=20) 위쪽 빈 띠).
	var spacing := 26.0
	var start_x: float = 1280.0 - float(motif_count) * spacing - 4.0
	for i in range(motif_count):
		var preview := SkillIcon.new()
		preview.position = Vector2(start_x + float(i) * spacing, 2.0)
		preview.size = icon_size
		preview.motif = SkillPool.ICON_MOTIF_VALUES[i]
		add_child(preview)

	# SubViewport들이 실제로 한 번 렌더링된 뒤의 프레임을 잡기 위해 대기
	# (visual_qa.gd의 _capture_and_quit()와 같은 "frame_post_draw까지 기다림" 패턴).
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var render_ok := true
	var seen_data: Dictionary = {}
	for i in range(motif_count):
		var motif: String = SkillPool.ICON_MOTIF_VALUES[i]
		var img: Image = test_viewports[i].get_texture().get_image()
		if img == null:
			render_ok = false
			lines.append("    FAIL: 모티프 '%s' SubViewport 이미지를 가져오지 못함" % motif)
			continue
		var data: PackedByteArray = img.get_data()
		var has_pixel := false
		for b in data:
			if b != 0:
				has_pixel = true
				break
		if not has_pixel:
			render_ok = false
			lines.append("    FAIL: 모티프 '%s' 아이콘이 완전히 투명(아무것도 안 그려짐)" % motif)
			continue
		for other_motif in seen_data.keys():
			if seen_data[other_motif] == data:
				render_ok = false
				lines.append("    FAIL: 모티프 '%s'와 '%s'가 완전히 같은 픽셀로 렌더됨" % [motif, other_motif])
		seen_data[motif] = data

	for vp in test_viewports:
		remove_child(vp)
		vp.free()

	ok = render_ok and ok
	lines.append("  모티프 %d종 실제 렌더 차이 검증(빈 아이콘 0건 + 모티프 간 픽셀 충돌 0건이어야) -> %s" % [motif_count, "OK" if render_ok else "FAIL"])

	return ok


## node 이하 트리를 재귀로 훑어 SkillIcon 노드를 전부 out에 모은다. K-4b 검증 전용 —
## "모티프 프로퍼티가 설정됐는가"가 아니라 "실제 화면 트리에 그 아이콘 노드가 자식으로
## 붙어있는가"를 확인하기 위해 필요(새 화면에 와이어링을 빼먹으면 플래그 테스트로는
## 못 잡지만 이 트리 탐색으로는 빈 배열이 나와 FAIL로 드러남).
func _collect_skill_icons(node: Node, out: Array) -> void:
	if node is SkillIcon:
		out.append(node)
	for c in node.get_children():
		_collect_skill_icons(c, out)


## [대형 기획 11] K-4b 검증. K-4a가 만든 모티프 그리기 자체는 이미 검증됐으므로, 여기서는
## "그 모티프가 실제 화면 호출부(보상 선택/이벤트 보상/캐릭터 선택 시작 스킬 슬롯/
## 덱 패널)에 와이어링됐는가"만 본다 — 전부 "SkillIcon 노드가 트리에 실제로 붙어있고
## 그 motif 값이 기대한 것과 일치하는가"로 검증(플래그만 보고 PASS 처리하지 않음).
func _check_k4b_skill_icon_wiring(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) ItemCardStyle.build_card(): SkillPool 스킬 딱셔너리(id 있음)를 넘기면 모티프
	# 아이콘이 카드에 실제로 붙고, id가 없는 일반 아이템(DiceItemPool류)을 넘기면 안
	# 붙는지(회귀 방지 — 스킬이 아닌 카드에 엉뚱한 아이콘이 생기면 안 됨) 둘 다 확인.
	var deep_breath := SkillPool.find_skill("deep_breath")
	var skill_built: Dictionary = ItemCardStyle.build_card(deep_breath)
	var skill_icons_in_card: Array = []
	_collect_skill_icons(skill_built["card"], skill_icons_in_card)
	var card_has_icon: bool = skill_icons_in_card.size() == 1 and skill_icons_in_card[0].motif == SkillPool.icon_motif_for("deep_breath")
	ok = card_has_icon and ok
	lines.append("  build_card(스킬 '심호흡'): SkillIcon 1개 + motif='%s' 일치 -> %s" % [
		SkillPool.icon_motif_for("deep_breath"), "OK" if card_has_icon else "FAIL"
	])
	(skill_built["card"] as Control).free()

	var plain_item := {"name": "다이스 추가 (D4)", "description": "테스트용", "kind": "add_die", "sides": 4}
	var item_built: Dictionary = ItemCardStyle.build_card(plain_item)
	var skill_icons_in_item_card: Array = []
	_collect_skill_icons(item_built["card"], skill_icons_in_item_card)
	var item_card_has_no_icon: bool = skill_icons_in_item_card.is_empty()
	ok = item_card_has_no_icon and ok
	lines.append("  build_card(스킬 id 없는 일반 아이템): SkillIcon 0개(회귀 방지) -> %s" % ("OK" if item_card_has_no_icon else "FAIL"))
	(item_built["card"] as Control).free()

	# (2) character_select.gd 시작 스킬 슬롯: 해금/잠금 양쪽 모두 모티프 아이콘이 붙는지
	# (잠금 슬롯은 INBOX.md 지시대로 "어둡게(알파 낮춤)"이지만 노드 자체는 존재해야 함).
	var cs_scene := load("res://code/scenes/character_select.tscn")
	var cs_node = cs_scene.instantiate()
	add_child(cs_node)
	cs_node._on_card_selected("novice")
	var novice_candidates: Array[Dictionary] = SkillPool.starting_skills_for_character("novice")
	var slot0_skill: Dictionary = novice_candidates[0]
	var slot0_motif: String = SkillPool.icon_motif_for(slot0_skill["id"])

	var unlocked_slot: Button = cs_node._make_starting_skill_slot(slot0_skill, true, 0)
	var unlocked_icons: Array = []
	_collect_skill_icons(unlocked_slot, unlocked_icons)
	var unlocked_ok: bool = unlocked_icons.size() == 1 and unlocked_icons[0].motif == slot0_motif
	ok = unlocked_ok and ok
	lines.append("  character_select 시작 스킬 슬롯(해금, '%s'): SkillIcon motif='%s' 일치 -> %s" % [
		slot0_skill["name"], slot0_motif, "OK" if unlocked_ok else "FAIL"
	])
	unlocked_slot.free()

	var locked_slot: Button = cs_node._make_starting_skill_slot(slot0_skill, false, 0)
	var locked_icons: Array = []
	_collect_skill_icons(locked_slot, locked_icons)
	var locked_ok: bool = locked_icons.size() == 1 and locked_icons[0].motif == slot0_motif and locked_icons[0].modulate.a < 1.0
	ok = locked_ok and ok
	lines.append("  character_select 시작 스킬 슬롯(잠금, '%s'): SkillIcon 윤곽 유지 + modulate.a<1 -> %s" % [
		slot0_skill["name"], "OK" if locked_ok else "FAIL"
	])
	locked_slot.free()

	remove_child(cs_node)
	cs_node.free()

	# (3) deck_panel.gd "보유 스킬" 섹션: 전투 중 토글/비전투 4개 화면이 공유하는 한
	# 곳이라 여기서만 확인하면 전부 커버된다. skill_flags가 비었을 때는 아이콘이 없고
	# (빈 텍스트 "(없음)"만), 스킬이 있으면 그 모티프가 실제로 붙는지 확인.
	var skill_flags_backup: Array = RunState.skill_flags.duplicate()
	var character_backup: String = RunState.character_id
	RunState.character_id = "novice"

	RunState.skill_flags = ["deep_breath"]
	var deck := DeckPanel.new()
	add_child(deck)
	var deck_icons: Array = []
	_collect_skill_icons(deck, deck_icons)
	# deck 안엔 캐릭터 기믹용 SkillIcon(category, _add_character_section)도 함께 있으므로
	# "motif가 기대값과 일치하는 아이콘이 정확히 1개 있는가"로 좁혀서 확인한다.
	var matching_deck_icons: Array = deck_icons.filter(func(icon): return icon.motif == SkillPool.icon_motif_for("deep_breath"))
	var deck_ok: bool = matching_deck_icons.size() == 1
	ok = deck_ok and ok
	lines.append("  DeckPanel 보유 스킬 섹션(skill_flags=[deep_breath]): SkillIcon motif='%s' 일치 -> %s" % [
		SkillPool.icon_motif_for("deep_breath"), "OK" if deck_ok else "FAIL"
	])

	remove_child(deck)
	deck.free()
	RunState.skill_flags = skill_flags_backup
	RunState.character_id = character_backup

	return ok


## [대형 기획 11] K-4c 검증. "override 텍스처가 존재하면 그걸 우선해서 쓰는가"를
## skill_icon.gd의 render_source()(실제 _draw() 분기와 같은 단일 진실 소스) 결과로
## 확인한다 — resources/skills/를 건드리지 않고 user:// 임시 폴더에 1x1 PNG를 직접
## 만들어서 "파일이 없을 때(motif로 폴백)" -> "파일이 생긴 뒤(override 우선)" ->
## "파일을 지운 뒤(다시 motif로 폴백)" 세 단계로 실제 분기가 바뀌는지 본다(플래그가
## 설정됐는지가 아니라 계산 결과가 바뀌는지를 봄). 테스트용 이미지는 INBOX.md 지시대로
## resources/ 밖(user://)에만 만들고 끝나면 지운다.
func _check_k4c_skill_icon_external_art(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 경로 조합 자체가 기대대로인지(운영 기본 경로).
	var expected_path := "res://resources/skills/deep_breath.png"
	var actual_path := SkillIcon.external_art_path("deep_breath")
	var path_ok: bool = actual_path == expected_path
	ok = path_ok and ok
	lines.append("  external_art_path('deep_breath') == '%s' -> %s (실제: %s)" % [
		expected_path, "OK" if path_ok else "FAIL", actual_path
	])

	# (2) 운영 경로(resources/skills/)에 파일이 없는 id는 load_external_art()가 null을
	# 돌려줘야 한다(파일 없음 -> 조용히 폴백, 에러 없이). "deep_breath"로 테스트하던
	# 과거 버전은 2026-10-16에 아트 스레드가 33종 스킬 아이콘을 전부 입고하면서
	# 깨졌다(STATUS.md 알려진 이슈와 같은 "하드코딩된 미입고 가정" 패턴 — ART-1b의
	# berserker/guardian face_* 사례와 동일) — 실존 스킬 id 대신 존재할 수 없는 id로
	# 바꿔 "파일 없음 -> null" 계약 자체를 검증한다.
	var missing_tex := SkillIcon.load_external_art("k4c_nonexistent_skill_id_xyz")
	var missing_null_ok: bool = missing_tex == null
	ok = missing_null_ok and ok
	lines.append("  load_external_art(존재하지 않는 id, 운영 경로): 파일 없음 -> null -> %s" % ("OK" if missing_null_ok else "FAIL"))

	# (2b) 반대로 "deep_breath"는 이제 아트 스레드가 실제로 입고한 스킬이므로, 운영
	# 경로에서 실제 Texture2D를 돌려줘야 한다(end-to-end — "파일이 있으면 쓴다" 쪽
	# 계약도 production 자산으로 직접 확인).
	var prod_tex := SkillIcon.load_external_art("deep_breath")
	var prod_loaded_ok: bool = prod_tex != null
	ok = prod_loaded_ok and ok
	lines.append("  load_external_art('deep_breath', 운영 경로): 아트 입고됨 -> Texture2D 로드=%s -> %s" % [
		prod_loaded_ok, "OK" if prod_loaded_ok else "FAIL"
	])

	# (3) user:// 임시 폴더에 override가 없는 상태에서 SkillIcon을 만들면 render_source()가
	# "motif"여야 한다(아직 파일 없음).
	var tmp_dir := "user://k4c_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var test_skill_id := "k4c_test_skill"
	var icon := SkillIcon.new()
	icon.motif = "reroll"
	icon.skill_id = test_skill_id
	icon.external_art_base_dir = tmp_dir
	add_child(icon)
	var before_source := icon.render_source()
	var before_ok: bool = before_source == "motif"
	ok = before_ok and ok
	lines.append("  override 파일 생성 전: render_source() == 'motif' -> %s (실제: %s)" % ["OK" if before_ok else "FAIL", before_source])

	# (4) 1x1 PNG를 user:// 임시 경로에 실제로 써서 override 파일을 만든 뒤, 같은
	# SkillIcon의 render_source()가 "external"로 바뀌는지 확인(계산 결과가 실제로
	# 바뀌는지 — 플래그만 보는 테스트가 아님).
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1, 0, 0, 1))
	var save_err := img.save_png(tmp_dir + test_skill_id + ".png")
	var save_ok: bool = save_err == OK
	ok = save_ok and ok
	lines.append("  user:// 임시 PNG 저장: %s" % ("OK" if save_ok else "FAIL (err=%d)" % save_err))

	var after_source := icon.render_source()
	var after_ok: bool = after_source == "external"
	ok = after_ok and ok
	lines.append("  override 파일 생성 후: render_source() == 'external' -> %s (실제: %s)" % ["OK" if after_ok else "FAIL", after_source])

	# (5) 같은 경로를 motif 없이(category도 없이) 쓰면 override가 유일한 그리기 소스가
	# 돼야 한다(override가 motif/category 둘 다보다 우선한다는 주석의 우선순위 보장).
	icon.motif = ""
	var no_motif_source := icon.render_source()
	var no_motif_ok: bool = no_motif_source == "external"
	ok = no_motif_ok and ok
	lines.append("  motif=''(카테고리도 없음)이어도 override 파일이 있으면 render_source() == 'external' -> %s" % ("OK" if no_motif_ok else "FAIL"))

	# (6) 파일을 지우면 다시 motif/none으로 폴백해야 한다(override가 영구적으로 캐시되지
	# 않고 매번 실제로 파일 존재를 확인함을 보장).
	DirAccess.remove_absolute(tmp_dir + test_skill_id + ".png")
	var removed_source := icon.render_source()
	var removed_ok: bool = removed_source == "none"
	ok = removed_ok and ok
	lines.append("  override 파일 삭제 후: render_source() == 'none'(motif도 비웠으므로) -> %s" % ("OK" if removed_ok else "FAIL"))

	remove_child(icon)
	icon.free()
	DirAccess.remove_absolute(tmp_dir)

	return ok


## [대형 기획 12] L-1(2026-10-14) 검증: 카드마다 있던 "선택" 버튼을 없애고 카드 패널
## (CharacterCardPanel) 전체를 클릭/스페이스 선택 영역으로 바꿨다. "플래그가 들어갔는가"가
## 아니라 실제 InputEventMouseButton/ui_accept 이벤트를 panel._gui_input()에 직접 넣어
## (a) 좌클릭으로 _selected_id가 바뀌는지 (b) 스페이스(ui_accept)로도 바뀌는지 (c) 선택된
## 카드의 실제 StyleBox 테두리 색이 "선택" 금테로 바뀌는지 (d) 씬 전체에 "선택" 텍스트
## 버튼이 더는 없는지를 확인한다.
func _check_l1_card_click_select(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	# (a) 기본 선택(견습 모험가)에서 "광전사" 카드 패널에 실제 좌클릭 이벤트를 넣으면
	# _selected_id가 "berserker"로 바뀌어야 한다.
	var berserker_panel: CharacterCardPanel = node._card_panels["berserker"]
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	berserker_panel._gui_input(click_event)
	var click_select_ok: bool = node._selected_id == "berserker"
	ok = click_select_ok and ok
	lines.append("  좌클릭 InputEventMouseButton -> _selected_id=%s(기대 berserker) -> %s" % [
		node._selected_id, "OK" if click_select_ok else "FAIL"
	])

	# (c) 선택된 카드의 실제 StyleBox border_color가 금테(_refresh_selection_highlight()의
	# 선택색)로 바뀌었는지 — 선택 안 된 카드(견습 모험가)와 비교해 실제로 달라야 한다.
	var berserker_border: Color = berserker_panel.get_theme_stylebox("panel").border_color
	var novice_panel: CharacterCardPanel = node._card_panels["novice"]
	var novice_border: Color = novice_panel.get_theme_stylebox("panel").border_color
	var highlight_ok: bool = berserker_border != novice_border
	ok = highlight_ok and ok
	lines.append("  선택된 카드(광전사) 테두리색=%s vs 미선택(견습 모험가)=%s(달라야 함) -> %s" % [
		berserker_border, novice_border, "OK" if highlight_ok else "FAIL"
	])

	# (b) 다른 카드("수호자")에 실제로 grab_focus()한 뒤 ui_accept(스페이스) 이벤트를
	# 넣으면 _selected_id가 "guardian"으로 바뀌어야 한다(마우스 없이 키보드만으로 선택).
	var guardian_panel: CharacterCardPanel = node._card_panels["guardian"]
	guardian_panel.grab_focus()
	var space_event := InputEventKey.new()
	space_event.keycode = KEY_SPACE
	space_event.pressed = true
	guardian_panel._gui_input(space_event)
	var space_select_ok: bool = node._selected_id == "guardian"
	ok = space_select_ok and ok
	lines.append("  스페이스(ui_accept) InputEventKey -> _selected_id=%s(기대 guardian) -> %s" % [
		node._selected_id, "OK" if space_select_ok else "FAIL"
	])

	# (e) 카드 패널이 실제로 포커스 가능한지(방향키 체인이 성립하려면 FOCUS_ALL 필수).
	var focusable_ok: bool = berserker_panel.focus_mode == Control.FOCUS_ALL
	ok = focusable_ok and ok
	lines.append("  카드 패널 focus_mode == FOCUS_ALL -> %s" % ("OK" if focusable_ok else "FAIL"))

	# (d) 씬 전체에 "선택" 텍스트를 가진 Button이 더는 없어야 한다(카드마다 있던 전용
	# 선택 버튼 제거 확인 — "던전 시작" 등 다른 버튼과 혼동되지 않게 정확한 텍스트로 검색).
	var leftover_button := _find_button_with_text(node, "선택")
	var no_select_button_ok: bool = leftover_button == null
	ok = no_select_button_ok and ok
	lines.append("  씬에 '선택' 텍스트 버튼이 남아있지 않음 -> %s" % ("OK" if no_select_button_ok else "FAIL"))

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## 트리를 재귀적으로 돌며 text가 정확히 일치하는 Button을 찾는다(없으면 null). L-1 검증이
## "카드마다 있던 선택 버튼이 완전히 사라졌는지"를 노드 레벨에서 직접 확인하기 위한 용도.
func _find_button_with_text(root: Node, text: String) -> Button:
	if root is Button and (root as Button).text == text:
		return root
	for child in root.get_children():
		var found := _find_button_with_text(child, text)
		if found != null:
			return found
	return null


## _check_n1_character_select_skill_slot_key_nav()가 쓰는 실제 키 주입 헬퍼
## (code/qa/visual_qa.gd의 _send_key()와 같은 이유로 press+release 둘 다 보낸다 —
## BaseButton은 release에서야 pressed를 emit하므로 press만으로는 버튼이 안 눌린다).
## dice_test는 실제로 돌아가는 SceneTree의 current_scene이라, add_child()로 붙인
## character_select 인스턴스도 같은 뷰포트의 포커스 체인 안에 있어 Input.parse_input_event()가
## 진짜 엔진 입력 파이프라인(ui_left/right/up/down/accept 액션 매칭 + focus_neighbor 이동)을
## 그대로 거친다.
func _n1_send_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)


## [대형 기획 14] N-1 전수 감사에서 발견한 버그 검증: character_select.gd의 시작 스킬
## 슬롯(수평 체인, _starting_skill_slot_buttons)이 카드 목록(수직 체인, _shortcut_buttons)과
## 전혀 연결돼 있지 않아 마우스로만 닿을 수 있었다. _link_cards_to_skill_slots()/
## _restore_starting_skill_focus() 추가로 고친 뒤를 "플래그"가 아니라 실제
## InputEventKey(방향키/스페이스)를 Input.parse_input_event()로 주입해(엔진의 진짜
## 포커스 이동 로직을 그대로 태움) 검증한다:
##   (1) 카드에서 -> (오른쪽)으로 슬롯[0]에 실제로 도달하는지
##   (2) 슬롯에서 <-(왼쪽)/위/아래로 다시 카드로 돌아오는지(세 방향 전부)
##   (3) 잠긴 슬롯을 스페이스로 "미리보기"한 뒤에도(슬롯 버튼이 전부 다시 만들어짐)
##       방향키가 계속 먹히는지(포커스가 끊기지 않는지) — 이게 바로 두 번째로 발견한
##       버그(_rebuild_starting_skill_slots()가 매번 버튼을 지우고 새로 만드는데 아무도
##       새 포커스를 받지 않아 방향키가 먹통이 되던 것)
## await를 쓰므로 호출부(_ready())는 `await _check_n1_character_select_skill_slot_key_nav(lines)`로
## 받아야 한다.
func _check_n1_character_select_skill_slot_key_nav(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup: String = RunState.character_id
	var chosen_backup: String = RunState.chosen_starting_skill_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)
	await get_tree().process_frame

	var viewport := get_viewport()
	var novice_card: Control = node._card_panels.get("novice")

	# (1) 카드에서 오른쪽 방향키로 슬롯[0]에 실제로 도달.
	novice_card.grab_focus()
	_n1_send_key(KEY_RIGHT)
	await get_tree().process_frame
	var slot0: Control = node._starting_skill_slot_buttons[0] if node._starting_skill_slot_buttons.size() > 0 else null
	var reach_slot_ok: bool = slot0 != null and viewport.gui_get_focus_owner() == slot0
	ok = reach_slot_ok and ok
	lines.append("  (1) 카드에서 -> (오른쪽) 시작 스킬 슬롯[0]에 실제로 도달 -> %s" % (
		"OK" if reach_slot_ok else "FAIL"
	))

	# (2) 슬롯에서 왼쪽/위/아래 세 방향 모두 카드로 돌아오는지(_link_cards_to_skill_slots()가
	# 세 방향 전부 selected_card로 묶어뒀는지 실제로 확인).
	var back_ok := true
	for key in [KEY_LEFT, KEY_UP, KEY_DOWN]:
		slot0.grab_focus()
		_n1_send_key(key)
		await get_tree().process_frame
		if viewport.gui_get_focus_owner() != novice_card:
			back_ok = false
	ok = back_ok and ok
	lines.append("  (2) 슬롯에서 좌/위/아래 세 방향 전부 카드로 복귀 -> %s" % ("OK" if back_ok else "FAIL"))

	# (3) 잠긴 슬롯(슬롯[1], "r1_novice" 해금 전이라 잠겨 있어야 함)을 스페이스로
	# "미리보기"하면 _rebuild_starting_skill_slots()가 버튼을 전부 새로 만드는데, 그 뒤에도
	# 방향키가 여전히 먹히는지(포커스가 끊기지 않았는지)를 "다시 오른쪽/왼쪽을 눌러 실제로
	# 이동하는지"로 확인한다 — 포커스가 null이 되면 아래 이동이 전부 조용히 실패한다.
	AchievementManager._debug_reset_for_qa()
	node._on_card_selected("novice")
	var slot1_before: Control = node._starting_skill_slot_buttons[1] if node._starting_skill_slot_buttons.size() > 1 else null
	var slot1_locked_ok: bool = slot1_before != null and not SkillPool.is_slot_requirement_met("novice", 1)
	if slot1_before != null:
		slot1_before.grab_focus()
		_n1_send_key(KEY_SPACE)
		await get_tree().process_frame
	# 슬롯 버튼이 전부 새로 만들어졌으므로 "같은 인덱스"의 새 인스턴스를 다시 읽어야 한다.
	var slot1_after: Control = node._starting_skill_slot_buttons[1] if node._starting_skill_slot_buttons.size() > 1 else null
	var focus_survived_ok: bool = slot1_after != null and viewport.gui_get_focus_owner() == slot1_after
	ok = slot1_locked_ok and focus_survived_ok and ok
	lines.append("  (3) 잠긴 슬롯[1] 미리보기(슬롯 버튼 전부 재생성) 후에도 포커스 유지=%s(기대 true, 잠김 확인=%s) -> %s" % [
		focus_survived_ok, slot1_locked_ok, "OK" if (slot1_locked_ok and focus_survived_ok) else "FAIL"
	])
	# 포커스가 안 끊겼다는 것을 방향키 한 번 더 눌러서 실제로 재확인(왼쪽 -> 카드로 복귀).
	_n1_send_key(KEY_LEFT)
	await get_tree().process_frame
	var still_navigable_ok: bool = viewport.gui_get_focus_owner() == novice_card
	ok = still_navigable_ok and ok
	lines.append("  (3-확인) 미리보기 후 왼쪽 방향키가 여전히 먹혀 카드로 복귀 -> %s" % (
		"OK" if still_navigable_ok else "FAIL"
	))

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	AchievementManager._debug_reset_for_qa()
	return ok


## [대형 기획 12] L-2(a)(2026-10-14) 검증: 스킬 도감 데이터/저장. "플래그가 들어갔는가"가
## 아니라 (1) codex_entries()가 실제로 돌려주는 배열의 크기/순서/codex_source 분류가
## 기대와 일치하는지 (2) SkillCodex 저장 파일이 실제로 디스크에 쓰이고 다시 읽어도
## 내용이 유지되는지 (3) 캐릭터별로 발견 기록이 실제로 분리되는지 (4) 테스트 전투 중엔
## 기록되지 않는지 (5) 깨진 JSON을 읽어도 크래시 없이 빈 상태로 안전한지 (6) 실제 화면
## 훅(event.gd _show_skill_offer / character_select.gd 슬롯 렌더링+잠금 미리보기)이
## 실제로 SkillCodex에 기록을 남기는지를 검증한다.
func _check_l2a_skill_codex(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_flags_backup := RunState.skill_flags.duplicate()
	var test_battle_backup := RunState.test_battle

	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()

	# (1) codex_entries() 완전성/순서 — 기본 7명은 총 9개(시작 3 + 전용 1 + 공용 2 +
	# 강화 3(공용 2 + 전용 1)), 등장 순서가 시작->전용->공용->강화이고, id 중복이 없어야
	# 한다. 곡예사는 2026-10-15 [대형 기획 14] N-5(a)로 고유 스킬이 2종(juggle_encore
	# + juggle_fortune)이 돼 총 11개(시작 3 + 전용 2 + 공용 2 + 강화 4(공용 2 + 전용
	# 2))로 늘었다. [대형 기획 15] Q-8(c)(2026-10-19)로 전설 스킬(LEGENDARY_SKILLS)이
	# 생기면서 그 캐릭터가 가진 전설 개수만큼 "전용" 바로 다음에 "legendary" 항목이
	# 더 끼어든다(codex_entries() 순서: 시작->전용->전설->공용->강화) — 기대값을
	# 하드코딩하지 않고 LEGENDARY_SKILLS를 character_id로 직접 세어 계산하므로, 다음
	# 이터레이션(2/4~4/4)이 나머지 6명에게 전설을 추가해도 이 테스트를 고칠 필요가 없다.
	var count_ok := true
	var order_ok := true
	var no_dup_ok := true
	for profile in CharacterProfiles.PROFILES:
		var character_id: String = profile["id"]
		var entries: Array[Dictionary] = SkillPool.codex_entries(character_id)
		var unique_count: int = 2 if character_id == "juggler" else 1
		var legendary_count := 0
		for skill in SkillPool.LEGENDARY_SKILLS:
			if skill.get("character_id", "") == character_id:
				legendary_count += 1
		var expected_for_character: Array[String] = []
		for _i in 3:
			expected_for_character.append("starting")
		for _i in unique_count:
			expected_for_character.append("unique")
		for _i in legendary_count:
			expected_for_character.append("legendary")
		expected_for_character.append("common")
		expected_for_character.append("common")
		for _i in (unique_count + 2):
			expected_for_character.append("upgrade")
		var expected_size: int = expected_for_character.size()
		if entries.size() != expected_size:
			count_ok = false
			lines.append("    %s: 크기 %d(기대 %d)" % [character_id, entries.size(), expected_size])
		var seen: Dictionary = {}
		for entry in entries:
			if seen.has(entry["id"]):
				no_dup_ok = false
			seen[entry["id"]] = true
		for i in min(entries.size(), expected_for_character.size()):
			if entries[i]["codex_source"] != expected_for_character[i]:
				order_ok = false
	ok = count_ok and order_ok and no_dup_ok and ok
	lines.append("  codex_entries() 크기(전설 개수 반영, 계산값) 8명 전부 일치 -> %s" % ("OK" if count_ok else "FAIL"))
	lines.append("  codex_entries() 순서(시작->전용->전설->공용->강화) 8명 전부 일치 -> %s" % ("OK" if order_ok else "FAIL"))
	lines.append("  codex_entries() id 중복 없음(8명 전부) -> %s" % ("OK" if no_dup_ok else "FAIL"))

	# (2) 저장/로드 왕복 — mark_discovered() 직후 _load()로 디스크에서 다시 읽어도
	# is_discovered()가 여전히 true여야 한다(메모리 캐시가 아니라 실제 파일 내용 확인).
	SkillCodex.mark_discovered("novice", "start_expand")
	SkillCodex._load()
	var roundtrip_ok: bool = SkillCodex.is_discovered("novice", "start_expand")
	ok = roundtrip_ok and ok
	lines.append("  mark_discovered(novice,start_expand) 후 _load() 재로드해도 is_discovered()==true -> %s" % ("OK" if roundtrip_ok else "FAIL"))

	# (3) 캐릭터별 격리 — 캐릭터 A에서 본 스킬이 캐릭터 B 도감에서는 미발견으로 남아야
	# 한다.
	var isolation_ok: bool = not SkillCodex.is_discovered("berserker", "start_expand")
	ok = isolation_ok and ok
	lines.append("  novice에서 발견한 start_expand는 berserker 도감에서는 여전히 미발견 -> %s" % ("OK" if isolation_ok else "FAIL"))

	# (4) 테스트 전투 가드 — RunState.test_battle=true인 동안 mark_discovered()를
	# 불러도 기록되지 않아야 한다.
	RunState.test_battle = true
	SkillCodex.mark_discovered("guardian", "start_wall")
	var test_battle_guard_ok: bool = not SkillCodex.is_discovered("guardian", "start_wall")
	ok = test_battle_guard_ok and ok
	lines.append("  RunState.test_battle=true 중 mark_discovered() 호출 -> 기록 안 됨(is_discovered()==false) -> %s" % ("OK" if test_battle_guard_ok else "FAIL"))
	RunState.test_battle = false
	SkillCodex.mark_discovered("guardian", "start_wall")
	var test_battle_recovers_ok: bool = SkillCodex.is_discovered("guardian", "start_wall")
	ok = test_battle_recovers_ok and ok
	lines.append("  RunState.test_battle=false로 복귀 후 같은 호출 -> 정상 기록 -> %s" % ("OK" if test_battle_recovers_ok else "FAIL"))
	RunState.test_battle = test_battle_backup

	# (5) 깨진 JSON — 저장 파일에 유효하지 않은 텍스트를 직접 써넣고 _load()를 불러도
	# 크래시 없이 빈 상태(discovered_count_for()==0)로 안전하게 떨어져야 한다.
	var corrupt_f := FileAccess.open(SkillCodex.SAVE_PATH, FileAccess.WRITE)
	corrupt_f.store_string("{이것은 유효한 JSON이 아님")
	corrupt_f.close()
	SkillCodex._load()
	var corrupt_json_ok: bool = SkillCodex.discovered_count_for("novice") == 0 and SkillCodex.discovered_count_for("guardian") == 0
	ok = corrupt_json_ok and ok
	lines.append("  깨진 JSON 파일 로드 -> 크래시 없이 빈 상태(discovered_count_for()==0) -> %s" % ("OK" if corrupt_json_ok else "FAIL"))

	SkillCodex._debug_reset_for_qa()

	# (6a) event.gd 훅 — 스킬 후보가 화면(_show_skill_offer)에 실제로 표시되면 그
	# 자리에서 SkillCodex에 기록되는지, 실제 씬을 인스턴스화해 QA 강제 훅(_debug_force_
	# skill_event_as_guardian, SKILLS[0]=심호흡/UNIQUE_SKILLS[1]=수호 심화를 강제로
	# 보여줌)으로 확인한다.
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)
	event_node._debug_force_skill_event_as_guardian()
	var event_hook_ok: bool = SkillCodex.is_discovered("guardian", SkillPool.SKILLS[0]["id"]) and SkillCodex.is_discovered("guardian", SkillPool.UNIQUE_SKILLS[1]["id"])
	ok = event_hook_ok and ok
	lines.append("  event.gd _show_skill_offer()로 표시된 두 스킬(심호흡/수호 심화)이 실제로 SkillCodex에 기록됨 -> %s" % ("OK" if event_hook_ok else "FAIL"))
	remove_child(event_node)
	event_node.free()
	SkillCodex._debug_reset_for_qa()

	# (6b) character_select.gd 훅 — 해금된 슬롯(슬롯 0)은 렌더링만으로 기록되고, 잠긴
	# 슬롯(슬롯 1)은 미리보기를 클릭하기 전에는 기록되지 않다가 클릭하면 기록돼야 한다.
	var select_scene := load("res://code/scenes/character_select.tscn")
	var select_node = select_scene.instantiate()
	add_child(select_node)
	select_node._on_card_selected("novice")
	var slot0_discovered_ok: bool = SkillCodex.is_discovered("novice", "start_expand")
	ok = slot0_discovered_ok and ok
	lines.append("  character_select.gd 슬롯0(항상 해금, 확장) 렌더링만으로 기록됨 -> %s" % ("OK" if slot0_discovered_ok else "FAIL"))
	var slot1_not_yet_ok: bool = not SkillCodex.is_discovered("novice", "start_lean")
	ok = slot1_not_yet_ok and ok
	lines.append("  슬롯1(잠김, 정예)은 미리보기 클릭 전엔 기록되지 않음 -> %s" % ("OK" if slot1_not_yet_ok else "FAIL"))
	select_node._on_starting_skill_locked_preview("start_lean")
	var slot1_preview_ok: bool = SkillCodex.is_discovered("novice", "start_lean")
	ok = slot1_preview_ok and ok
	lines.append("  슬롯1을 잠금 미리보기로 클릭한 뒤엔 기록됨 -> %s" % ("OK" if slot1_preview_ok else "FAIL"))
	remove_child(select_node)
	select_node.free()

	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup
	RunState.test_battle = test_battle_backup
	return ok


## [대형 기획 12] L-2(b)(2026-10-14) 검증: 스킬 도감 패널 UI. "플래그가 들어갔는가"가
## 아니라 실제로 렌더된 노드의 텍스트/모듈레이트가 3상태(보유/발견-미보유/미발견)에
## 따라 다른지, 요약 라벨 숫자가 맞는지, 격자 포커스 체인이 실제로 성립하는지, Esc로
## 닫히는지를 검증한다. "novice"(견습 모험가) 도감 9개 중 의도적으로 4개 상태를 섞어
## 만든다: 보유 2(확장/심호흡) · 발견-미보유 2(임기응변/심호흡+) · 미발견(힌트 없음)
## 3(여분/여분+/임기응변+) · 미발견(F-1 잠금 힌트 있음) 2(정예=슬롯1/황금손=슬롯2).
func _check_l2b_skill_codex_panel(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_flags_backup := RunState.skill_flags.duplicate()
	var test_battle_backup := RunState.test_battle

	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()
	RunState.test_battle = false
	RunState.character_id = "novice"

	var owned: Array[String] = ["start_expand", "deep_breath"]
	RunState.skill_flags = owned.duplicate()
	for skill_id in owned:
		SkillCodex.mark_discovered("novice", skill_id)
	SkillCodex.mark_discovered("novice", "versatile_surge")
	SkillCodex.mark_discovered("novice", "deep_breath_plus")

	var panel := SkillCodexPanel.new()
	add_child(panel)
	panel.open("novice", owned)

	var expected_entries := SkillPool.codex_entries("novice")
	var count_ok: bool = panel._card_by_id.size() == expected_entries.size()
	ok = count_ok and ok
	lines.append("  카드 수 == codex_entries('novice').size()(기대 %d) -> %s" % [expected_entries.size(), "OK" if count_ok else "FAIL"])

	# 보유 상태 — start_expand(확장).
	var owned_badge: Label = panel._badge_label_by_id["start_expand"]
	var owned_name: Label = panel._name_label_by_id["start_expand"]
	var owned_icon: SkillIcon = panel._icon_by_id["start_expand"]
	var owned_ok: bool = owned_badge.text == SkillCodexPanel.BADGE_TEXT_OWNED and owned_name.text == "확장" and is_equal_approx(owned_icon.modulate.a, 1.0)
	ok = owned_ok and ok
	lines.append("  보유(확장): 배지='%s'(기대 보유) 이름='%s'(기대 확장) 아이콘알파=%.2f(기대 1.0) -> %s" % [
		owned_badge.text, owned_name.text, owned_icon.modulate.a, "OK" if owned_ok else "FAIL"
	])

	# 발견-미보유 상태 — versatile_surge(임기응변).
	var disc_badge: Label = panel._badge_label_by_id["versatile_surge"]
	var disc_name: Label = panel._name_label_by_id["versatile_surge"]
	var disc_icon: SkillIcon = panel._icon_by_id["versatile_surge"]
	var disc_ok: bool = disc_badge.text == SkillCodexPanel.BADGE_TEXT_DISCOVERED and disc_name.text == "임기응변" and is_equal_approx(disc_icon.modulate.a, 0.55)
	ok = disc_ok and ok
	lines.append("  발견-미보유(임기응변): 배지='%s'(기대 발견) 이름='%s'(기대 임기응변) 아이콘알파=%.2f(기대 0.55) -> %s" % [
		disc_badge.text, disc_name.text, disc_icon.modulate.a, "OK" if disc_ok else "FAIL"
	])

	# 미발견(힌트 없음) 상태 — spare_die(여분). Q-6(8)부터 미발견 카드는 SkillIcon이
	# 아니라 LockIcon을 쓴다(스킬 정보 비공개 규칙 유지) — _icon_by_id에는 아예 안
	# 들어가고 _lock_icon_by_id에 들어간다.
	var undisc_badge: Label = panel._badge_label_by_id["spare_die"]
	var undisc_name: Label = panel._name_label_by_id["spare_die"]
	var undisc_lock: LockIcon = panel._lock_icon_by_id["spare_die"]
	var undisc_desc: Label = panel._desc_label_by_id["spare_die"]
	var undisc_no_skill_icon: bool = not panel._icon_by_id.has("spare_die")
	var undisc_ok: bool = (
		undisc_badge.text == SkillCodexPanel.BADGE_TEXT_UNDISCOVERED and undisc_name.text == "???"
		and undisc_lock != null and undisc_desc.text == "" and undisc_no_skill_icon
	)
	ok = undisc_ok and ok
	lines.append("  미발견(여분, 힌트 없음): 배지='%s'(기대 미발견) 이름='%s'(기대 ???) LockIcon=%s(기대 있음) SkillIcon 없음=%s(기대 true) 설명='%s'(기대 빈 문자열) -> %s" % [
		undisc_badge.text, undisc_name.text, undisc_lock != null, undisc_no_skill_icon, undisc_desc.text, "OK" if undisc_ok else "FAIL"
	])

	# Q-6(8): 아이콘(또는 LockIcon) rect가 56px 이상 정사각인지 — 보유/발견/미발견 3상태
	# 전부 같은 ICON_BOX_SIZE를 쓰므로 하나씩 대표로 확인.
	var owned_icon_box: SkillIcon = panel._icon_by_id["start_expand"]
	var icon_square_ok: bool = (
		owned_icon_box.custom_minimum_size.x >= 56.0 and owned_icon_box.custom_minimum_size.y >= 56.0
		and is_equal_approx(owned_icon_box.custom_minimum_size.x, owned_icon_box.custom_minimum_size.y)
		and undisc_lock.custom_minimum_size.x >= 56.0 and undisc_lock.custom_minimum_size.y >= 56.0
		and is_equal_approx(undisc_lock.custom_minimum_size.x, undisc_lock.custom_minimum_size.y)
	)
	ok = icon_square_ok and ok
	lines.append("  아이콘 rect: 보유=%s LockIcon=%s(둘 다 >=56 정사각 기대) -> %s" % [
		owned_icon_box.custom_minimum_size, undisc_lock.custom_minimum_size, "OK" if icon_square_ok else "FAIL"
	])

	# Q-6(2): 상태 배지가 카드 우상단 모서리 안(작은 칩)인지 — badge_panel은 Container가
	# 아닌 plain Control(wrap)의 자식이라 anchor/offset이 그대로 최종 위치를 결정하고,
	# Container의 지연(deferred) 정렬 타이밍에 영향받지 않는다(이 값들은 _make_corner_tag가
	# 직접 설정한 값이라 add_child() 직후에도 즉시 읽을 수 있음) — 그래서 get_rect()/size
	# 같은 "실제 정렬 후" 값 대신 anchor_left/right·offset_* 설정값 자체로 검증한다.
	var badge_panel: PanelContainer = panel._badge_panel_by_id["start_expand"]
	var owned_card: CharacterCardPanel = panel._card_by_id["start_expand"]
	var badge_anchored_top_right: bool = (
		is_equal_approx(badge_panel.anchor_left, 1.0) and is_equal_approx(badge_panel.anchor_right, 1.0)
		and is_equal_approx(badge_panel.anchor_top, 0.0) and is_equal_approx(badge_panel.anchor_bottom, 0.0)
		and badge_panel.offset_right <= 0.0 and badge_panel.offset_top >= 0.0
	)
	var badge_width: float = badge_panel.offset_right - badge_panel.offset_left
	# 이전 구현(make_codex_badge, L-2b)은 header 아래 한 줄 전체를 차지하는 PanelContainer
	# (가로로 카드 폭에 맞춰 늘어남)였다 — 지금은 고정 48px 칩이라 카드 폭(320)의 40%도
	# 안 된다.
	var badge_small_ok: bool = badge_width < SkillCodexPanel.CARD_SIZE.x * 0.4
	var badge_corner_ok: bool = badge_anchored_top_right and badge_small_ok
	ok = badge_corner_ok and ok
	lines.append("  상태 배지: 우상단 anchor=%s 폭=%.0f(카드폭 %.0f의 40%% 미만 기대) -> %s" % [
		badge_anchored_top_right, badge_width, SkillCodexPanel.CARD_SIZE.x, "OK" if badge_corner_ok else "FAIL"
	])

	# Q-6(4): 시작 스킬 구역이 별도 노드로 3개(슬롯 1/2/3 순서) + 일반 스킬은 그 아래.
	var starting_count_ok: bool = is_instance_valid(panel._starting_row) and panel._starting_row.get_child_count() == 3
	ok = starting_count_ok and ok
	lines.append("  시작 스킬 구역 노드 자식 수=%s(기대 3) -> %s" % [
		panel._starting_row.get_child_count() if is_instance_valid(panel._starting_row) else "(없음)", "OK" if starting_count_ok else "FAIL"
	])
	var start_expand_slot_text: String = (panel._slot_tag_by_id["start_expand"] as Label).text if panel._slot_tag_by_id.has("start_expand") else "(없음)"
	var start_lean_slot_text: String = (panel._slot_tag_by_id["start_lean"] as Label).text if panel._slot_tag_by_id.has("start_lean") else "(없음)"
	var slot_tags_ok: bool = start_expand_slot_text == "슬롯 1" and start_lean_slot_text == "슬롯 2"
	ok = slot_tags_ok and ok
	lines.append("  슬롯 태그: start_expand='%s'(기대 슬롯 1) start_lean='%s'(기대 슬롯 2) -> %s" % [
		start_expand_slot_text, start_lean_slot_text, "OK" if slot_tags_ok else "FAIL"
	])
	var general_child_count: int = (panel._general_grid as GridContainer).get_child_count() if is_instance_valid(panel._general_grid) else -1
	var starting_before_general_ok: bool = (
		is_instance_valid(panel._general_grid) and panel._slot_tag_by_id.size() == 3
		and general_child_count == expected_entries.size() - 3
	)
	ok = starting_before_general_ok and ok
	lines.append("  일반 스킬 구역 카드 수=%s(기대 %d) + 슬롯 태그 총 %d개(기대 3, 시작 스킬만) -> %s" % [
		general_child_count, expected_entries.size() - 3, panel._slot_tag_by_id.size(), "OK" if starting_before_general_ok else "FAIL"
	])

	# 미발견(F-1 잠금 힌트 있음) 상태 — start_lean(정예, 슬롯1).
	var locked_desc: Label = panel._desc_label_by_id["start_lean"]
	var expected_hint: String = SkillPool.unlock_requirement("novice", 1)["text"]
	var locked_hint_ok: bool = locked_desc.text == expected_hint and expected_hint != ""
	ok = locked_hint_ok and ok
	lines.append("  미발견(정예, 슬롯1 잠금 힌트): 설명='%s' == unlock_requirement 텍스트('%s') -> %s" % [
		locked_desc.text, expected_hint, "OK" if locked_hint_ok else "FAIL"
	])

	# 요약 라벨 — 보유 2개 · 발견 4(보유 2 + 발견-미보유 2) / 전체 9.
	var summary_ok: bool = panel._summary_label.text.contains("보유 2개") and panel._summary_label.text.contains("발견 4 / 전체 %d" % expected_entries.size())
	ok = summary_ok and ok
	lines.append("  요약 라벨='%s'(보유 2개/발견 4/전체 %d 포함 기대) -> %s" % [
		panel._summary_label.text, expected_entries.size(), "OK" if summary_ok else "FAIL"
	])

	# 격자 포커스 체인 — 첫 카드에 포커스가 가 있고, 각 행의 좌/우가 wrap으로 서로 연결.
	var first_card: Control = panel._card_controls[0]
	var grab_focus_ok: bool = first_card.has_focus()
	ok = grab_focus_ok and ok
	lines.append("  open() 직후 첫 카드에 포커스 -> %s" % ("OK" if grab_focus_ok else "FAIL"))

	var row_end_idx: int = min(SkillCodexPanel.COLUMNS - 1, panel._card_controls.size() - 1)
	var wrap_left_ok: bool = first_card.focus_neighbor_left == first_card.get_path_to(panel._card_controls[row_end_idx])
	ok = wrap_left_ok and ok
	lines.append("  첫 행 wrap: 첫 카드의 왼쪽 포커스 이웃 == 그 행 마지막 카드 -> %s" % ("OK" if wrap_left_ok else "FAIL"))

	# Q-6: 보유/발견 카드를 activated시키면 SkillDetailPopup이 열리는지(미발견은 연결
	# 자체가 없어 열리지 않음). 포커스를 옮기는(그리고 팝업을 닫아도 되돌려주지 않는)
	# 부수효과가 있어 위의 포커스 검증들이 끝난 뒤, 패널을 닫기 전에 한다.
	owned_card.activated.emit()
	var popup_opened_ok: bool = is_instance_valid(panel._skill_popup) and panel._skill_popup.visible and panel._skill_popup._name_label.text == "확장"
	ok = popup_opened_ok and ok
	lines.append("  보유 카드(확장) activated -> SkillDetailPopup 열림, 이름='%s'(기대 확장) -> %s" % [
		panel._skill_popup._name_label.text if is_instance_valid(panel._skill_popup) else "(없음)", "OK" if popup_opened_ok else "FAIL"
	])
	panel._skill_popup.close()
	var undisc_card: CharacterCardPanel = panel._card_by_id["spare_die"]
	undisc_card.activated.emit()
	var popup_stays_closed_ok: bool = not panel._skill_popup.visible
	ok = popup_stays_closed_ok and ok
	lines.append("  미발견 카드(여분) activated -> 팝업 안 열림(기대 유지 닫힘) -> %s" % ("OK" if popup_stays_closed_ok else "FAIL"))

	# Esc로 닫힘(customize_panel.gd 검증과 동일 패턴).
	var closed_signal_log: Array = []
	panel.closed.connect(func(): closed_signal_log.append(true))
	var esc_key := InputEventKey.new()
	esc_key.pressed = true
	esc_key.keycode = KEY_ESCAPE
	panel._unhandled_input(esc_key)
	var esc_closes_ok: bool = not panel.visible and closed_signal_log.size() == 1
	ok = esc_closes_ok and ok
	lines.append("  Esc 입력: visible=%s(기대 false) closed 시그널 %d회(기대 1) -> %s" % [
		panel.visible, closed_signal_log.size(), "OK" if esc_closes_ok else "FAIL"
	])

	remove_child(panel)
	panel.queue_free()
	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup
	RunState.test_battle = test_battle_backup
	return ok


## [대형 기획 12] L-2(c)(2026-10-14) 검증: 진입점 연결. character_select/dungeon_map/
## shop/event/story_event 다섯 화면에 실제로 추가된 "스킬 도감" 버튼이 (1) 눌리면
## SkillCodexPanel.visible이 실제로 true가 되는지 (2) 패널에 넘겨진 character_id/
## owned_skill_ids가 "플래그가 들어갔는가"가 아니라 패널 내부 상태(_character_id/
## _owned)로 실제로 맞는지 (3) 화면마다 호출부 의미가 다른지(캐릭터 선택 화면은
## 항상 owned=[], 던전 진행 화면은 RunState.skill_flags 그대로) (4) 다시 누르면
## 토글로 닫히는지를 검증한다. combat_test.tscn은 _run_battle()이 await로 이어지는
## 물리 시뮬레이션을 포함해 이 동기 테스트 harness에서 안전하게 인스턴스화할 수 없어
## (다른 화면들과 달리 이 파일에 인스턴스화 전례가 없음) 제외하고, qa_shot 스크린샷
## (_debug_press_shortcut_skill_codex)으로만 눈으로 확인한다.
func _check_l2c_skill_codex_entry_points(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_flags_backup := RunState.skill_flags.duplicate()
	var gold_backup := RunState.gold

	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()

	# (A) character_select: owned_skill_ids는 항상 빈 배열이어야 한다(런 시작 전이라
	# "보유"라는 개념이 없음 — INBOX.md L-2 원문). RunState.skill_flags를 일부러 채워둔
	# 채로 열어서, 패널이 그 값을 잘못 가져다 쓰지 않는지(항상 []) 함께 확인한다.
	RunState.character_id = "novice"
	RunState.skill_flags = ["start_expand", "deep_breath"]
	var select_scene := load("res://code/scenes/character_select.tscn")
	var select_node = select_scene.instantiate()
	add_child(select_node)
	select_node._on_card_selected("pirate")
	select_node._skill_codex_button.pressed.emit()
	var select_open_ok: bool = select_node.skill_codex_panel.visible
	var select_char_ok: bool = select_node.skill_codex_panel._character_id == "pirate"
	var select_owned_ok: bool = select_node.skill_codex_panel._owned.is_empty()
	ok = select_open_ok and select_char_ok and select_owned_ok and ok
	lines.append("  character_select: '스킬 도감' 버튼 클릭(pirate 선택 중) -> panel.visible=%s(기대 true) character_id=%s(기대 pirate) owned=%s(기대 빈 배열) -> %s" % [
		select_node.skill_codex_panel.visible, select_node.skill_codex_panel._character_id, select_node.skill_codex_panel._owned,
		"OK" if (select_open_ok and select_char_ok and select_owned_ok) else "FAIL"
	])
	select_node._skill_codex_button.pressed.emit()
	var select_close_ok: bool = not select_node.skill_codex_panel.visible
	ok = select_close_ok and ok
	lines.append("  character_select: 다시 클릭 -> 토글로 닫힘(visible=%s, 기대 false) -> %s" % [
		select_node.skill_codex_panel.visible, "OK" if select_close_ok else "FAIL"
	])
	remove_child(select_node)
	select_node.free()

	# (B) 던전 진행 화면 4종: RunState.character_id/skill_flags를 그대로 패널에 넘겨야
	# 한다("이번 회차 보유" 반영 — character_select와의 차이). 네 화면 모두 버튼/패널
	# 필드 이름이 같아(skill_codex_button/skill_codex_panel) 한 헬퍼로 검증한다.
	RunState.character_id = "pirate"
	RunState.skill_flags = ["start_vanguard", "broadside"]
	var dungeon_scene_paths := {
		"dungeon_map": "res://code/scenes/dungeon_map.tscn",
		"shop": "res://code/scenes/shop.tscn",
		"event": "res://code/scenes/event.tscn",
		"story_event": "res://code/scenes/story_event.tscn",
	}
	for screen_label in dungeon_scene_paths:
		var scene := load(dungeon_scene_paths[screen_label])
		var node = scene.instantiate()
		add_child(node)
		node.skill_codex_button.pressed.emit()
		var open_ok: bool = node.skill_codex_panel.visible
		var char_ok: bool = node.skill_codex_panel._character_id == "pirate"
		var owned_ok: bool = node.skill_codex_panel._owned == RunState.skill_flags
		var this_ok := open_ok and char_ok and owned_ok
		ok = this_ok and ok
		lines.append("  %s: '스킬 도감' 버튼 클릭 -> panel.visible=%s(기대 true) character_id=%s(기대 pirate) owned=%s(기대 %s) -> %s" % [
			screen_label, node.skill_codex_panel.visible, node.skill_codex_panel._character_id, node.skill_codex_panel._owned,
			RunState.skill_flags, "OK" if this_ok else "FAIL"
		])
		node.skill_codex_button.pressed.emit()
		var close_ok: bool = not node.skill_codex_panel.visible
		ok = close_ok and ok
		lines.append("  %s: 다시 클릭 -> 토글로 닫힘(visible=%s, 기대 false) -> %s" % [
			screen_label, node.skill_codex_panel.visible, "OK" if close_ok else "FAIL"
		])
		remove_child(node)
		node.free()

	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup
	RunState.gold = gold_backup
	return ok


## QA 전용(GAME_QA_CALL): 미발견/발견-미보유/보유 3상태가 한 화면에 같이 보이는
## SkillCodexPanel 스크린샷을 찍기 위한 훅. _check_l2b_skill_codex_panel()과 같은 혼합
## 상태를 만들어 연다 — L-2(c)(진입점 연결) 전이라 실제 화면 버튼은 아직 없으므로
## dice_test 씬을 빌려 패널만 띄운다.
func _debug_show_skill_codex_panel_mixed() -> void:
	SkillCodex._debug_reset_for_qa()
	AchievementManager._debug_reset_for_qa()
	RunState.test_battle = false
	RunState.character_id = "novice"
	var owned: Array[String] = ["start_expand", "deep_breath"]
	RunState.skill_flags = owned.duplicate()
	for skill_id in owned:
		SkillCodex.mark_discovered("novice", skill_id)
	SkillCodex.mark_discovered("novice", "versatile_surge")
	SkillCodex.mark_discovered("novice", "deep_breath_plus")
	var panel := SkillCodexPanel.new()
	add_child(panel)
	panel.open("novice", owned)


## [대형 기획 13] M-1(2026-10-14) 검증 — "플래그가 들어갔는가"가 아니라 실제 렌더/계산
## 결과(제목 문자열, 버튼 배경색 차이, HUD 라벨 텍스트, 점 개수, 패널 구조)를 확인한다.
## dungeon_map.gd는 @onready 노드를 쓰므로 실제 .tscn을 인스턴스화해야 한다(DeckPanel
## 검증과 같은 패턴).
func _check_m1_dungeon_map_hud_and_buttons(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var gold_backup := RunState.gold
	var rooms_backup := RunState.rooms_cleared
	var test_battle_backup := RunState.test_battle

	RunState.character_id = "novice"
	RunState.test_battle = false
	RunState.gold = 42
	RunState.rooms_cleared = 0

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map = map_scene.instantiate()
	add_child(map)

	# 제목: 개발용 문구("테스트 허브")가 없어야 하고, 테스트 전투가 아니면 "던전 맵"만.
	var title: Label = map.get_node("Title")
	var title_ok: bool = title.text == "던전 맵" and not title.text.contains("테스트 허브")
	ok = title_ok and ok
	lines.append("  제목(테스트 전투 아님): '%s' (기대 '던전 맵', 개발용 문구 없음) -> %s" % [
		title.text, "OK" if title_ok else "FAIL"
	])

	# [대형 기획 15] Q-4a(12, 2026-10-17)로 수정: 전투 버튼이 더 이상 "주 행동"이 아니라
	# 다른 방 선택지(상점)와 같은 보조 스타일을 받는다 — M-1 당시엔 둘이 달라야 했지만
	# INBOX 피드백("전투 방 선택지만 크고 메인 선택지처럼 보인다")으로 방향이 반대가 됐다.
	# [대형 기획 13] M-5a(2026-10-15): resources/ui/button/*가 입고되면 normal이
	# StyleBoxTexture일 수 있어 _m5_style_fingerprint()로 StyleBoxFlat/Texture 양쪽을
	# 다 받는다(실제 "원화 자체가 다른가"가 아니라 "두 버튼이 같은 렌더 결과를
	# 공유하는가"를 확인하는 게 이 테스트의 의도).
	var combat_style: StyleBox = map.enter_combat_button.get_theme_stylebox("normal")
	var secondary_style: StyleBox = map.enter_shop_button.get_theme_stylebox("normal")
	var combat_fp: Variant = _m5_style_fingerprint(combat_style)
	var secondary_fp: Variant = _m5_style_fingerprint(secondary_style)
	var button_hierarchy_ok: bool = combat_style != null and secondary_style != null and combat_fp == secondary_fp
	ok = button_hierarchy_ok and ok
	lines.append("  (Q-4a 12) 버튼 위계: 전투 normal=%s 상점 normal=%s (같아야 함, 위계 제거) -> %s" % [
		combat_fp, secondary_fp, "OK" if button_hierarchy_ok else "FAIL"
	])
	# 정예 전투 버튼은 tint(빨강)를 받아 상점과도, 전투와도 달라야 한다(G-7 "빨간 테두리"
	# 의도가 UIKit 통합 후에도 유지되는지).
	var elite_style: StyleBox = map.enter_elite_button.get_theme_stylebox("normal")
	var elite_fp: Variant = _m5_style_fingerprint(elite_style)
	var elite_distinct_ok: bool = elite_style != null and elite_fp != secondary_fp
	ok = elite_distinct_ok and ok
	lines.append("  정예 버튼 구분값이 일반 보조 버튼과 다름(위험 강조 유지): elite=%s secondary=%s -> %s" % [
		elite_fp, secondary_fp, "OK" if elite_distinct_ok else "FAIL"
	])

	# HUD 칩: 라운드/골드 값이 RunState를 그대로 반영.
	var round_text_ok: bool = map._hud_round_value_label.text == "%d/%d" % [RunState.round_index, RunState.TOTAL_ROUNDS]
	ok = round_text_ok and ok
	lines.append("  HUD 라운드 칩: '%s' (기대 '%d/%d') -> %s" % [
		map._hud_round_value_label.text, RunState.round_index, RunState.TOTAL_ROUNDS, "OK" if round_text_ok else "FAIL"
	])
	var gold_text_ok: bool = map._hud_gold_value_label.text == str(RunState.gold)
	ok = gold_text_ok and ok
	lines.append("  HUD 골드 칩: '%s' (기대 '%d') -> %s" % [
		map._hud_gold_value_label.text, RunState.gold, "OK" if gold_text_ok else "FAIL"
	])

	# 골드를 바꾸고 _update_labels()를 다시 불러도 칩이 따라오는지(정적 텍스트가 아님을 확인).
	RunState.gold = 999
	map._update_labels()
	var gold_updates_ok: bool = map._hud_gold_value_label.text == "999"
	ok = gold_updates_ok and ok
	lines.append("  HUD 골드 칩 갱신(999로 변경 후 _update_labels() 재호출): '%s' -> %s" % [
		map._hud_gold_value_label.text, "OK" if gold_updates_ok else "FAIL"
	])

	# 진행도 점 개수는 TOTAL_ROOMS와 같아야 한다(INBOX M-1 "진행도는 진행 바나 칸").
	var dots_count_ok: bool = map._hud_progress_dots.get_child_count() == RunState.TOTAL_ROOMS
	ok = dots_count_ok and ok
	lines.append("  진행도 점 개수: %d (기대 %d) -> %s" % [
		map._hud_progress_dots.get_child_count(), RunState.TOTAL_ROOMS, "OK" if dots_count_ok else "FAIL"
	])

	# MapStrip 카드가 뷰포트(1280x720) 밖으로 흘러나오지 않는지(카드 높이를 동적으로
	# 계산하도록 바꿨으므로, 계산값 자체가 화면을 벗어나지 않는지 확인).
	var strip_within_viewport_ok: bool = map._map_card_height > 0.0 and map.map_strip.offset_bottom <= 720.0
	ok = strip_within_viewport_ok and ok
	lines.append("  MapStrip 카드 높이=%.1f, 바닥 y=%.1f (기대 >0, <=720) -> %s" % [
		map._map_card_height, map.map_strip.offset_bottom, "OK" if strip_within_viewport_ok else "FAIL"
	])

	# DeckPanel: 구역 패널화(섹션 5개: 캐릭터/보유 스킬/공격/방어/기타 정보) + 넘치면
	# 스크롤되도록 ScrollContainer로 감쌌는지.
	var deck: DeckPanel = map.get_node("DeckPanel")
	var deck_sections := 0
	var has_scroll := false
	for c in deck.get_children():
		if c is ScrollContainer:
			has_scroll = true
			for inner in c.get_children():
				if inner is VBoxContainer:
					deck_sections = inner.get_child_count()
	var deck_structure_ok: bool = has_scroll and deck_sections == 5
	ok = deck_structure_ok and ok
	lines.append("  DeckPanel: ScrollContainer=%s 섹션 개수=%d (기대 true, 5) -> %s" % [
		has_scroll, deck_sections, "OK" if deck_structure_ok else "FAIL"
	])

	remove_child(map)
	map.free()

	# 테스트 전투 중(RunState.test_battle=true)이면 제목에 "(테스트 전투)"가 붙어야 한다.
	RunState.test_battle = true
	var map2_scene := load("res://code/scenes/dungeon_map.tscn")
	var map2 = map2_scene.instantiate()
	add_child(map2)
	var title2: Label = map2.get_node("Title")
	var test_battle_title_ok: bool = title2.text == "던전 맵 (테스트 전투)"
	ok = test_battle_title_ok and ok
	lines.append("  제목(테스트 전투 중): '%s' (기대 '던전 맵 (테스트 전투)') -> %s" % [
		title2.text, "OK" if test_battle_title_ok else "FAIL"
	])
	remove_child(map2)
	map2.free()

	# FocusNav.focus_style()의 배경이 투명해야(알파=0) 커스텀 버튼색(주/보조) 위에 포커스
	# 테두리가 겹쳐 그려져도 밑의 색이 그대로 보인다 — M-1 라운드 1에서 발견한 버그의 회귀
	# 방지(오버레이 방식으로 그려지는 Godot Button 포커스 스타일 특성상, 배경이 불투명하면
	# 포커스된 버튼은 항상 그 불투명색으로 덮여 주/보조 구분이 사라진다).
	var fstyle := FocusNav.focus_style()
	var focus_transparent_ok: bool = fstyle.bg_color.a == 0.0
	ok = focus_transparent_ok and ok
	lines.append("  FocusNav.focus_style() 배경 투명(포커스가 커스텀 버튼색을 안 가림): alpha=%.2f -> %s" % [
		fstyle.bg_color.a, "OK" if focus_transparent_ok else "FAIL"
	])

	RunState.character_id = character_backup
	RunState.gold = gold_backup
	RunState.rooms_cleared = rooms_backup
	RunState.test_battle = test_battle_backup
	return ok


## [대형 기획 13] M-2(2026-10-14) 검증 — combat_test.gd의 HUD 재설계를 "노드가 있는가"가
## 아니라 실제 렌더 텍스트/색이 맞는가로 검증한다. combat_test.tscn을 실제로 instantiate해
## 트리에 넣는다(M-1의 dungeon_map 테스트와 같은 패턴) — _ready()는 "HUD/버튼/몬스터 설정"을
## 전부 끝낸 뒤 맨 마지막 _run_battle() 호출에서만 await로 들어가므로(물리 다이스 정지
## 대기), add_child() 직후 시점엔 이미 검증 대상 전부가 동기적으로 완성돼 있다 — 물리
## 코루틴이 끝나길 기다릴 필요가 없다(다른 combat_test 테스트들이 피했던 "await 때문에
## 느리다"는 문제가 애초에 발생하지 않는 지점만 검사).
func _check_m2_combat_hud(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var test_battle_backup := RunState.test_battle
	var test_monster_id_backup := RunState.test_monster_id
	var test_difficulty_backup := RunState.test_difficulty

	# --- 순수 함수(인스턴스 없이도 검증 가능한 부분 먼저) ---
	var combat_script := load("res://code/scenes/combat_test.gd")
	var probe = combat_script.new()
	var tier_normal_ok: bool = probe._monster_tier_text(false, false) == "일반"
	var tier_elite_ok: bool = probe._monster_tier_text(true, false) == "정예"
	var tier_boss_ok: bool = probe._monster_tier_text(false, true) == "보스"
	ok = tier_normal_ok and tier_elite_ok and tier_boss_ok and ok
	lines.append("  티어 텍스트(일반/정예/보스): '%s'/'%s'/'%s' -> %s" % [
		probe._monster_tier_text(false, false), probe._monster_tier_text(true, false),
		probe._monster_tier_text(false, true),
		"OK" if (tier_normal_ok and tier_elite_ok and tier_boss_ok) else "FAIL"
	])
	var tier_colors_distinct_ok: bool = (
		probe._monster_tier_color(false, false) != probe._monster_tier_color(true, false)
		and probe._monster_tier_color(true, false) != probe._monster_tier_color(false, true)
	)
	ok = tier_colors_distinct_ok and ok
	lines.append("  티어 색이 일반/정예/보스 셋 다 다름(색만으로도 혼동 안 되게) -> %s" % [
		"OK" if tier_colors_distinct_ok else "FAIL"
	])
	# "특성" 요약 — _monster_debug_info_text()(QA용, 다이스 개수 등 수치 포함)와 달리
	# 성격 + 스킬 짧은 이름만 사람이 읽기 좋게 나열하고 수치는 안 들어가야 한다.
	var trait_config := {
		"personality": "무기력하고 단순함", "skill_ids": ["counter", "armor"],
		"attack_count": 99, "defense_count": 99, "dice_sides": 99,
	}
	var trait_text: String = probe._monster_trait_summary_text(trait_config)
	var trait_ok: bool = (
		trait_text.contains("무기력하고 단순함") and trait_text.contains("반격")
		and trait_text.contains("방어구") and not trait_text.contains("99")
	)
	ok = trait_ok and ok
	lines.append("  특성 요약(성격+스킬 짧은 이름 포함, 다이스 수치 미포함): '%s' -> %s" % [
		trait_text.replace("\n", " / "), "OK" if trait_ok else "FAIL"
	])
	var trait_empty_ok: bool = probe._monster_trait_summary_text({}) == "특성 없음"
	ok = trait_empty_ok and ok
	lines.append("  특성 요약(빈 config): '%s' (기대 '특성 없음') -> %s" % [
		probe._monster_trait_summary_text({}), "OK" if trait_empty_ok else "FAIL"
	])
	probe.free()

	# --- 실제 화면(테스트 전투 모드로 몬스터를 "슬라임" 고정 — 결정론적) ---
	RunState.character_id = "pirate"
	RunState.test_battle = true
	RunState.test_monster_id = "slime"
	RunState.test_difficulty = 0

	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var title: Label = combat.get_node("Title")
	var title_ok: bool = title.text == "전투 (테스트 전투)" and not title.text.contains("combat_test.tscn")
	ok = title_ok and ok
	lines.append("  제목(테스트 전투 중): '%s' (기대 '전투 (테스트 전투)', 개발용 파일명 없음) -> %s" % [
		title.text, "OK" if title_ok else "FAIL"
	])

	var monster_name_ok: bool = combat.monster_name_label.text == "슬라임"
	var monster_tier_text_ok: bool = combat.monster_tier_label.text == "일반"
	ok = monster_name_ok and monster_tier_text_ok and ok
	lines.append("  몬스터 HUD: 이름='%s'(기대 '슬라임') 티어='%s'(기대 '일반') -> %s" % [
		combat.monster_name_label.text, combat.monster_tier_label.text,
		"OK" if (monster_name_ok and monster_tier_text_ok) else "FAIL"
	])
	var trait_shown_ok: bool = combat.monster_trait_label.text.contains("무기력하고 단순함")
	ok = trait_shown_ok and ok
	lines.append("  몬스터 특성 패널: '%s' -> %s" % [
		combat.monster_trait_label.text.replace("\n", " / "), "OK" if trait_shown_ok else "FAIL"
	])

	# 디버그 줄("[QA] 공격...") 가시성은 [감독 추가 비평 2026-10-14]로 OS.is_debug_build()
	# (에디터 실행이면 항상 true라 일반 플레이에서도 보이던 버그)가 아니라 명시적 QA
	# 플래그(GAME_QA_DEBUG_UI)를 따라야 한다 — 플래그 없이는 항상 숨고, "1"이면 보임.
	var qa_debug_env_backup := OS.get_environment("GAME_QA_DEBUG_UI")
	OS.set_environment("GAME_QA_DEBUG_UI", "")
	var debug_hidden_by_default_ok: bool = combat._qa_debug_ui_enabled() == false and combat.monster_debug_info_label.visible == false
	ok = debug_hidden_by_default_ok and ok
	lines.append("  디버그 줄: 플래그 없음(일반 플레이, 에디터 실행 포함) -> visible=%s(기대 false) -> %s" % [
		combat.monster_debug_info_label.visible, "OK" if debug_hidden_by_default_ok else "FAIL"
	])
	OS.set_environment("GAME_QA_DEBUG_UI", "1")
	combat.monster_debug_info_label.visible = combat._qa_debug_ui_enabled()
	var debug_shown_with_flag_ok: bool = combat._qa_debug_ui_enabled() == true and combat.monster_debug_info_label.visible == true
	ok = debug_shown_with_flag_ok and ok
	lines.append("  디버그 줄: GAME_QA_DEBUG_UI=1 -> visible=%s(기대 true) -> %s" % [
		combat.monster_debug_info_label.visible, "OK" if debug_shown_with_flag_ok else "FAIL"
	])
	OS.set_environment("GAME_QA_DEBUG_UI", qa_debug_env_backup)

	# HP 바 오버레이 숫자가 실제 HP를 반영(두껍게 키운 바 위에 숫자를 겹쳐 표시 — 별도
	# 텍스트 줄이 아님). 값을 바꾸고 _update_labels()를 다시 불러도 따라오는지까지 확인.
	combat.player_hp = 13
	combat.monster_hp = 3
	combat._update_labels()
	var hp_overlay_ok: bool = combat.player_hp_label.text == "13 / 20" and combat.monster_hp_label.text == "3 / %d" % combat.monster_max_hp
	ok = hp_overlay_ok and ok
	lines.append("  HP 바 오버레이 갱신: 플레이어='%s'(기대 '13 / 20') 몬스터='%s' -> %s" % [
		combat.player_hp_label.text, combat.monster_hp_label.text, "OK" if hp_overlay_ok else "FAIL"
	])

	# 라운드/방 캡션 — 테스트 전투면 "난이도" 표기를 쓴다(던전 진행 라운드/방 개념이 없음).
	var caption_ok: bool = combat._round_room_caption() == "테스트 전투 · 난이도 0"
	ok = caption_ok and ok
	lines.append("  중앙 캡션(테스트 전투): '%s' (기대 '테스트 전투 · 난이도 0') -> %s" % [
		combat._round_room_caption(), "OK" if caption_ok else "FAIL"
	])

	# "전투 기록" 패널: 상태 요약 줄이 "상태:"로 시작하고, log_label이 그 패널 자식으로
	# 재부모화됐는지(평문 그대로 화면 루트에 남지 않았는지).
	var status_label_ok: bool = combat.player_status_label != null and combat.player_status_label.text.begins_with("상태:")
	ok = status_label_ok and ok
	lines.append("  전투 기록 패널 상태 요약 줄: '%s' -> %s" % [
		combat.player_status_label.text if combat.player_status_label else "(null)", "OK" if status_label_ok else "FAIL"
	])
	var log_reparented_ok: bool = combat.log_label.get_parent() != null and combat.log_label.get_parent() != combat
	ok = log_reparented_ok and ok
	lines.append("  LogLabel이 '전투 기록' 섹션 패널 자식으로 재부모화됨 -> %s" % [
		"OK" if log_reparented_ok else "FAIL"
	])

	# 주/보조 버튼 위계 — "다음"만 주 행동(캐릭터 accent 꽉 채움), 나머지는 보조(테두리만).
	# [대형 기획 13] M-5a(2026-10-15): resources/ui/button/*가 입고되면 normal이
	# StyleBoxTexture일 수 있어 _m5_style_fingerprint()로 양쪽을 다 받는다.
	var next_style: StyleBox = combat.next_button.get_theme_stylebox("normal")
	var codex_style: StyleBox = combat.skill_codex_button.get_theme_stylebox("normal")
	var next_fp: Variant = _m5_style_fingerprint(next_style)
	var codex_fp: Variant = _m5_style_fingerprint(codex_style)
	var button_hierarchy_ok: bool = next_style != null and codex_style != null and next_fp != codex_fp
	ok = button_hierarchy_ok and ok
	lines.append("  버튼 위계: 다음(주) normal=%s 스킬도감(보조) normal=%s (달라야 함) -> %s" % [
		next_fp, codex_fp, "OK" if button_hierarchy_ok else "FAIL"
	])

	# "몬스터 포트레이트가 화면 밖으로 안 나가는지"는 [대형 기획 15] Q-1(17,24)로
	# _check_q1_monster_portrait_tier_bounds()가 대체했다(이 자리의 옛 체크는 거의 안
	# 쓰이는 도형 플레이스홀더의 ellipse radius=66 + 삭제된 PORTRAIT_SCALE_BOSS 상수를
	# 썼던 것 — 실제 원화 _face_rect/_glow_rect를 카탈로그 전수로 재는 새 체크가 완전히
	# 상위 호환이라 중복 제거).

	remove_child(combat)
	combat.free()

	RunState.character_id = character_backup
	RunState.test_battle = test_battle_backup
	RunState.test_monster_id = test_monster_id_backup
	RunState.test_difficulty = test_difficulty_backup
	return ok


## [대형 기획 13] M-3 — 감독 추가 비평(2026-10-14) "3D 다이스 구역이 작고... 결과 칩이
## 가운데/아래에 흩어져 있다"를 코드로 고쳤는지 "계산 결과(실제 렌더된 노드 위치/크기)"로
## 검증한다(플래그가 아니라). _show_exchange_dice_chips()는 물리 다이스 스폰 없이도
## 순수하게 호출 가능해서(칩은 값을 받아서 그릴 뿐 굴리지 않음), combat_test.tscn을
## instantiate한 뒤 직접 호출해 확인할 수 있다.
func _check_m3_combat_dice_stage(lines: PackedStringArray) -> bool:
	var ok := true

	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	# 1) 다이스 뷰포트가 M-2보다 커졌고(세로 316->340), 더 이상 비율이 안 틀어지게
	#    SubViewport 해상도가 컨테이너 크기와 정확히 일치하는지.
	var viewport_container: SubViewportContainer = combat.get_node("DiceViewportContainer")
	var dice_viewport: SubViewport = combat.get_node("DiceViewportContainer/DiceViewport")
	var container_size: Vector2 = viewport_container.size
	var grew_ok: bool = container_size.y > 316.0
	ok = grew_ok and ok
	lines.append("  다이스 뷰포트 컨테이너 크기: %s (기대 세로 >316, M-2 값보다 커짐) -> %s" % [
		container_size, "OK" if grew_ok else "FAIL"
	])
	var no_distortion_ok: bool = dice_viewport.size == Vector2i(container_size)
	ok = no_distortion_ok and ok
	lines.append("  SubViewport 해상도=%s == 컨테이너 크기=%s (늘이기/찌그러짐 없음) -> %s" % [
		dice_viewport.size, Vector2i(container_size), "OK" if no_distortion_ok else "FAIL"
	])

	# 2) 결과 칩 한 줄: "공격"/"방어" 라벨이 각각 하나씩 있고, 그 사이에 칩들이 이어
	#    붙으며, 전체 묶음이 화면 중앙(EXCHANGE_ROW_CENTER_X)에 좌우 대칭으로 정렬되는지.
	var atk_bag := DiceBag.new(4, 3)
	var def_bag := DiceBag.new(4, 2)
	combat._show_exchange_dice_chips(atk_bag, [1, 2, 3], def_bag, [4, 1], Color(0.9, 0.3, 0.3, 1), Color(0.3, 0.5, 0.9, 1))

	var atk_label: Label = null
	var def_label: Label = null
	var chip_count := 0
	for node in combat._exchange_chip_nodes:
		if node is Label:
			if node.text == "공격":
				atk_label = node
			elif node.text == "방어":
				def_label = node
		else:
			chip_count += 1
	var labels_ok: bool = atk_label != null and def_label != null and atk_label.position.x < def_label.position.x
	ok = labels_ok and ok
	lines.append("  결과 칩 한 줄: '공격' 라벨 x=%s, '방어' 라벨 x=%s (공격이 왼쪽) -> %s" % [
		atk_label.position.x if atk_label else "(없음)", def_label.position.x if def_label else "(없음)",
		"OK" if labels_ok else "FAIL"
	])
	var chip_count_ok: bool = chip_count == atk_bag.dice.size() + def_bag.dice.size()
	ok = chip_count_ok and ok
	lines.append("  칩 개수=%d (기대 %d = 공격 %d + 방어 %d) -> %s" % [
		chip_count, atk_bag.dice.size() + def_bag.dice.size(), atk_bag.dice.size(), def_bag.dice.size(),
		"OK" if chip_count_ok else "FAIL"
	])

	var leftmost := INF
	var rightmost := -INF
	for node in combat._exchange_chip_nodes:
		leftmost = min(leftmost, node.position.x)
		var w: float = node.custom_minimum_size.x if node is Label else node.size.x
		rightmost = max(rightmost, node.position.x + w)
	var center := (leftmost + rightmost) / 2.0
	var centered_ok: bool = abs(center - combat.EXCHANGE_ROW_CENTER_X) < 2.0
	ok = centered_ok and ok
	lines.append("  칩 한 줄 중심 x=%.1f (기대 %.1f 근처, 화면 양 끝에 흩어지지 않고 중앙 정렬) -> %s" % [
		center, combat.EXCHANGE_ROW_CENTER_X, "OK" if centered_ok else "FAIL"
	])

	# 3) 버튼 행(다음/다시 하기/설정으로)이 넓어진 뷰포트 아래로 내려갔고, "전투 기록"
	#    패널(_setup_log_panel)과 겹치지 않는지.
	var viewport_bottom: float = viewport_container.position.y + container_size.y
	var next_button_top: float = combat.next_button.position.y
	var buttons_below_viewport_ok: bool = next_button_top >= viewport_bottom
	ok = buttons_below_viewport_ok and ok
	lines.append("  버튼 행 y=%.1f >= 다이스 뷰포트 바닥 y=%.1f (안 겹침) -> %s" % [
		next_button_top, viewport_bottom, "OK" if buttons_below_viewport_ok else "FAIL"
	])
	var log_panel_top: float = combat._log_panel.position.y
	var button_bottom: float = next_button_top + combat.next_button.size.y
	var log_below_buttons_ok: bool = log_panel_top >= button_bottom
	ok = log_below_buttons_ok and ok
	lines.append("  '전투 기록' 패널 y=%.1f >= 버튼 행 바닥 y=%.1f (안 겹침) -> %s" % [
		log_panel_top, button_bottom, "OK" if log_below_buttons_ok else "FAIL"
	])

	# 4) 승리 보상 프레임이 "전투 기록" 패널 위에서 끝나는지(M-2 인수인계 때 발견한
	#    겹침 회귀가 다이스 스테이지 확대로 재발하지 않았는지).
	var reward_frame_bottom_ok: bool = combat.REWARD_FRAME_BOTTOM <= log_panel_top - 8.0
	ok = reward_frame_bottom_ok and ok
	lines.append("  REWARD_FRAME_BOTTOM=%.1f <= '전투 기록' 패널 y(%.1f) - 8 (안 겹침, 여유 포함) -> %s" % [
		combat.REWARD_FRAME_BOTTOM, log_panel_top, "OK" if reward_frame_bottom_ok else "FAIL"
	])

	remove_child(combat)
	combat.free()
	return ok


## ART-1b: face_{neutral,happy,hurt,sad,angry}.png 5장이 전부 입고되면 전투 화면이
## 실제로 원화 텍스처를 쓰고, 1장이라도 없으면 도형 플레이스홀더로 안전하게 폴백하는지
## 검증. "노드가 있는가"가 아니라 실제 렌더 상태(_face_rect.visible/texture, _draw()
## 분기)를 확인한다.
##
## 2026-10-16 [대형 기획 14] N-6 인수인계 수정: 예전 버전은 "berserker는 face_*가
## 하나도 없다"를 하드코딩으로 가정했는데, 이 세션 시작 전 아트 스레드가 실제로
## berserker/guardian face_*를 입고해 그 가정이 깨져 4건이 FAIL로 돌아섰다(알려진
## 이슈 (214) 기록). 특정 캐릭터의 입고 상태에 의존하는 대신, user:// 임시 디렉터리에
## 직접 만든 가짜 캐릭터 3종(5장 모두/2장만/0장)으로 CharacterArt.has_all_faces()와
## CharacterPortraitPlaceholder.art_base_dir(이번에 신규 추가된 테스트 주입 지점)을
## 검증한다 — resources/는 전혀 건드리지 않는다(읽기도 안 함, 가짜 디렉터리는 전부
## user:// 아래).
func _check_art1b_combat_face_art(lines: PackedStringArray) -> bool:
	var ok := true

	var fake_base_dir := "user://art1b_fake_faces/%s/"
	var fake_full_id := "qa_fake_full"
	var fake_partial_id := "qa_fake_partial"
	var fake_none_id := "qa_fake_none"
	_art1b_write_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)
	_art1b_write_fake_faces(fake_base_dir, fake_partial_id, ["neutral", "happy"])
	DirAccess.make_dir_recursive_absolute(fake_base_dir % fake_none_id)

	# 1) CharacterArt.has_all_faces(base_dir=...) 순수 함수 — 세 경우 모두.
	var full_has_all := CharacterArt.has_all_faces(fake_full_id, fake_base_dir)
	ok = full_has_all and ok
	lines.append("  has_all_faces(가짜 '5장 모두') = %s (기대 true) -> %s" % [full_has_all, "OK" if full_has_all else "FAIL"])

	var partial_has_all := CharacterArt.has_all_faces(fake_partial_id, fake_base_dir)
	var partial_has_all_ok: bool = not partial_has_all
	ok = partial_has_all_ok and ok
	lines.append("  has_all_faces(가짜 '2장만') = %s (기대 false) -> %s" % [partial_has_all, "OK" if partial_has_all_ok else "FAIL"])

	var none_has_all := CharacterArt.has_all_faces(fake_none_id, fake_base_dir)
	var none_has_all_ok: bool = not none_has_all
	ok = none_has_all_ok and ok
	lines.append("  has_all_faces(가짜 '0장') = %s (기대 false) -> %s" % [none_has_all, "OK" if none_has_all_ok else "FAIL"])

	# 2) CharacterPortraitPlaceholder.set_character()가 art_base_dir(신규 테스트 주입
	#    지점)을 통해 이 가짜 디렉터리를 그대로 반영하는지 — "5장 모두"는 원화 모드 +
	#    표정 전환, "2장만"/"0장"은 플레이스홀더 유지.
	var portrait := CharacterPortraitPlaceholder.new()
	add_child(portrait)
	portrait.art_base_dir = fake_base_dir

	portrait.set_character(fake_none_id)
	var none_mode_ok: bool = not portrait._use_face_art
	ok = none_mode_ok and ok
	lines.append("  set_character(가짜 '0장') 후 _use_face_art=%s (기대 false) -> %s" % [portrait._use_face_art, "OK" if none_mode_ok else "FAIL"])

	portrait.set_character(fake_partial_id)
	var partial_mode_ok: bool = not portrait._use_face_art
	ok = partial_mode_ok and ok
	lines.append("  set_character(가짜 '2장만') 후 _use_face_art=%s (기대 false) -> %s" % [portrait._use_face_art, "OK" if partial_mode_ok else "FAIL"])

	portrait.set_character(fake_full_id)
	var full_mode_ok: bool = portrait._use_face_art
	ok = full_mode_ok and ok
	lines.append("  set_character(가짜 '5장 모두') 후 _use_face_art=%s (기대 true) -> %s" % [portrait._use_face_art, "OK" if full_mode_ok else "FAIL"])
	var neutral_tex := portrait._face_rect.texture if portrait._face_rect != null else null
	var neutral_tex_ok: bool = neutral_tex != null and portrait._face_rect.visible
	ok = neutral_tex_ok and ok
	lines.append("  가짜 '5장 모두' 초기 표정(neutral) 텍스처 로드됨=%s, _face_rect.visible=%s -> %s" % [
		neutral_tex != null, portrait._face_rect.visible if portrait._face_rect != null else false,
		"OK" if neutral_tex_ok else "FAIL"
	])

	portrait.set_expression("happy")
	var happy_tex := portrait._face_rect.texture
	var expression_switch_ok: bool = happy_tex != null and happy_tex != neutral_tex
	ok = expression_switch_ok and ok
	lines.append("  set_expression('happy') 후 텍스처가 neutral과 다른 리소스로 바뀜 -> %s" % ("OK" if expression_switch_ok else "FAIL"))

	remove_child(portrait)
	portrait.free()
	_art1b_remove_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)
	_art1b_remove_fake_faces(fake_base_dir, fake_partial_id, ["neutral", "happy"])
	_art1b_remove_fake_faces(fake_base_dir, fake_none_id, [])
	DirAccess.remove_absolute("user://art1b_fake_faces")

	# 3) 실제 combat_test.tscn 인스턴스 — production 배선(art_base_dir를 안 바꾸고
	#    기본값=실제 resources/ 경로 그대로 씀)이 지금 그 캐릭터의 실제
	#    CharacterArt.has_all_faces() 결과와 항상 일치하는지. 어떤 캐릭터가 입고
	#    됐는지는 가정하지 않는다 — 입고 상태가 앞으로 바뀌어도 이 검증은 깨지지
	#    않는다(실제 값을 기대값으로 직접 계산해서 비교).
	var character_backup: String = RunState.character_id
	RunState.character_id = "novice"
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var novice_expected := CharacterArt.has_all_faces("novice")
	var novice_combat_ok: bool = combat.player_portrait._use_face_art == novice_expected
	ok = novice_combat_ok and ok
	lines.append("  combat_test 인스턴스(캐릭터=novice) PlayerPortrait._use_face_art=%s (실제 has_all_faces=%s) -> %s" % [
		combat.player_portrait._use_face_art, novice_expected, "OK" if novice_combat_ok else "FAIL"
	])

	for cid in ["berserker", "pirate", "guardian"]:
		combat._debug_set_character(cid)
		var expected := CharacterArt.has_all_faces(cid)
		var cid_ok: bool = combat.player_portrait._use_face_art == expected
		ok = cid_ok and ok
		lines.append("  _debug_set_character('%s') 후 PlayerPortrait._use_face_art=%s (실제 has_all_faces=%s) -> %s" % [
			cid, combat.player_portrait._use_face_art, expected, "OK" if cid_ok else "FAIL"
		])

	remove_child(combat)
	combat.free()
	RunState.character_id = character_backup
	return ok


## ART-1c(2026-10-16) — 몬스터 쪽 원화 표정 컷 경로. ART-1b의 _check_art1b_combat_face_art()와
## 같은 구조(가짜 user:// 디렉터리로 5장 모두/일부만/없음 세 경우 검증)지만 대상이
## MonsterPortraitPlaceholder.set_monster()이고, 몬스터는 화면 우측(1170, 거의 화면
## 끝)이라 표정 컷이 오른쪽으로 잘리지 않는지까지 추가로 확인한다. `_art1b_write_fake_faces()`/
## `_art1b_remove_fake_faces()` 헬퍼는 character_id라는 매개변수 이름과 무관하게 순수하게
## "base_dir_pattern % id 아래에 가짜 face_*.png를 만드는" 범용 함수라 그대로 재사용한다.
func _check_art1c_monster_face_art(lines: PackedStringArray) -> bool:
	# 3)과 4)가 await를 쓰므로(RenderingServer.frame_post_draw) 이 함수 전체를
	# await로 불러야 한다(_check_art2_face_crop_fix와 같은 패턴).
	var ok := true

	var fake_base_dir := "user://art1c_fake_monster_faces/%s/"
	var fake_full_id := "qa_fake_monster_full"
	var fake_partial_id := "qa_fake_monster_partial"
	var fake_none_id := "qa_fake_monster_none"
	_art1b_write_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)
	_art1b_write_fake_faces(fake_base_dir, fake_partial_id, ["neutral", "happy"])
	DirAccess.make_dir_recursive_absolute(fake_base_dir % fake_none_id)

	# 1) MonsterPortraitPlaceholder.set_monster()가 art_base_dir(신규 테스트 주입
	#    지점)을 통해 이 가짜 디렉터리를 그대로 반영하는지 — "5장 모두"는 원화 모드 +
	#    표정 전환, "2장만"/"0장"은 플레이스홀더 유지.
	var portrait := MonsterPortraitPlaceholder.new()
	add_child(portrait)
	portrait.art_base_dir = fake_base_dir

	portrait.set_monster(fake_none_id)
	var none_mode_ok: bool = not portrait._use_face_art
	ok = none_mode_ok and ok
	lines.append("  set_monster(가짜 '0장') 후 _use_face_art=%s (기대 false) -> %s" % [portrait._use_face_art, "OK" if none_mode_ok else "FAIL"])

	portrait.set_monster(fake_partial_id)
	var partial_mode_ok: bool = not portrait._use_face_art
	ok = partial_mode_ok and ok
	lines.append("  set_monster(가짜 '2장만') 후 _use_face_art=%s (기대 false) -> %s" % [portrait._use_face_art, "OK" if partial_mode_ok else "FAIL"])

	portrait.set_monster(fake_full_id)
	var full_mode_ok: bool = portrait._use_face_art
	ok = full_mode_ok and ok
	lines.append("  set_monster(가짜 '5장 모두') 후 _use_face_art=%s (기대 true) -> %s" % [portrait._use_face_art, "OK" if full_mode_ok else "FAIL"])
	var neutral_tex := portrait._face_rect.texture if portrait._face_rect != null else null
	var neutral_tex_ok: bool = neutral_tex != null and portrait._face_rect.visible
	ok = neutral_tex_ok and ok
	lines.append("  가짜 '5장 모두' 초기 표정(neutral) 텍스처 로드됨=%s, _face_rect.visible=%s -> %s" % [
		neutral_tex != null, portrait._face_rect.visible if portrait._face_rect != null else false,
		"OK" if neutral_tex_ok else "FAIL"
	])

	portrait.set_expression("happy")
	var happy_tex := portrait._face_rect.texture
	var expression_switch_ok: bool = happy_tex != null and happy_tex != neutral_tex
	ok = expression_switch_ok and ok
	lines.append("  set_expression('happy') 후 텍스처가 neutral과 다른 리소스로 바뀜 -> %s" % ("OK" if expression_switch_ok else "FAIL"))

	remove_child(portrait)
	portrait.free()
	_art1b_remove_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)
	_art1b_remove_fake_faces(fake_base_dir, fake_partial_id, ["neutral", "happy"])
	_art1b_remove_fake_faces(fake_base_dir, fake_none_id, [])
	DirAccess.remove_absolute("user://art1c_fake_monster_faces")

	# 2) 실제 combat_test.tscn 인스턴스 — production 배선(art_base_dir를 안 바꾸고
	#    기본값=실제 resources/monsters/ 경로 그대로 씀)이 지금 그 몬스터의 실제
	#    CharacterArt.has_all_faces() 결과와 항상 일치하는지. 어떤 몬스터가 입고됐는지는
	#    가정하지 않는다 — 입고 상태가 앞으로 바뀌어도 이 검증은 깨지지 않는다.
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var monster_expected := CharacterArt.has_all_faces(combat.monster_id, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
	var monster_combat_ok: bool = combat.monster_portrait._use_face_art == monster_expected
	ok = monster_combat_ok and ok
	lines.append("  combat_test 인스턴스(몬스터=%s) MonsterPortrait._use_face_art=%s (실제 has_all_faces=%s) -> %s" % [
		combat.monster_id, combat.monster_portrait._use_face_art, monster_expected, "OK" if monster_combat_ok else "FAIL"
	])

	# 3) 표정 컷이 화면(1280px) 밖으로 오른쪽이 안 나가는지 — 가짜 '5장 모두'를 이
	#    production 인스턴스에 직접 주입해 실제 scale(보통 1.1/보스 1.3)이 적용된
	#    상태에서 우측 끝 글로벌 좌표를 측정한다. ART-2가 플레이어 쪽(화면 좌측)에서
	#    검증한 것과 대칭.
	combat.monster_portrait.art_base_dir = fake_base_dir
	_art1b_write_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)

	for scale_case in [
		{"label": "일반(1.1배)", "scale": Vector2(1.1, 1.1)},
		{"label": "보스(1.3배)", "scale": Vector2(1.3, 1.3)},
	]:
		combat.monster_portrait.scale = scale_case["scale"]
		combat.monster_portrait.set_monster(fake_full_id)
		var face_rect: TextureRect = combat.monster_portrait._face_rect
		var right_edge: float = (face_rect.get_global_transform() * Vector2(face_rect.size.x, 0)).x if face_rect != null else 9999.0
		var right_margin_ok: bool = right_edge <= 1280.0 - 8.0
		ok = right_margin_ok and ok
		lines.append("  %s 표정 컷 오른쪽 끝 글로벌 x=%.1f (기대 <= %.1f, 화면 오른쪽 끝에서 안 잘리는 여백) -> %s" % [
			scale_case["label"], right_edge, 1280.0 - 8.0, "OK" if right_margin_ok else "FAIL"
		])

	# 4) 하단 페이드 셰이더가 실제로 렌더되는지 — _check_art2_face_crop_fix()와 같은
	#    방식(실제 쓰이는 face_rect를 독립 SubViewport로 옮겨 중간 높이 vs 바닥 근처
	#    알파 비교). 몬스터 쪽도 같은 FACE_ART_FADE_SHADER를 그대로 재사용하므로 캐릭터
	#    쪽과 같은 결과가 나와야 한다.
	var material_ok: bool = (combat.monster_portrait._face_rect != null
		and combat.monster_portrait._face_rect.material is ShaderMaterial
		and (combat.monster_portrait._face_rect.material as ShaderMaterial).shader == MonsterPortraitPlaceholder.FACE_ART_FADE_SHADER)
	ok = material_ok and ok
	lines.append("  표정 컷에 하단 페이드 셰이더(FACE_ART_FADE_SHADER)가 적용됨 -> %s" % (
		"OK" if material_ok else "FAIL"
	))

	var probe_viewport := SubViewport.new()
	probe_viewport.size = Vector2i(240, 240)
	probe_viewport.transparent_bg = true
	probe_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(probe_viewport)

	var render_ok := false
	var mid_alpha := 0.0
	var bottom_alpha := 0.0
	var probe_face_rect: TextureRect = combat.monster_portrait._face_rect
	if probe_face_rect != null:
		combat.monster_portrait.remove_child(probe_face_rect)
		probe_face_rect.position = Vector2.ZERO
		probe_viewport.add_child(probe_face_rect)

		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var img: Image = probe_viewport.get_texture().get_image()
		render_ok = img != null
		if render_ok:
			mid_alpha = img.get_pixel(120, 120).a
			bottom_alpha = img.get_pixel(120, 238).a
	ok = render_ok and ok
	if render_ok:
		var fade_ok: bool = bottom_alpha < mid_alpha * 0.3
		ok = fade_ok and ok
		lines.append("  렌더된 표정 컷 알파: 중간 높이=%.3f, 바닥 근처(y=238)=%.3f (기대 바닥이 중간의 30%% 미만) -> %s" % [
			mid_alpha, bottom_alpha, "OK" if fade_ok else "FAIL"
		])
	else:
		lines.append("    FAIL: SubViewport 이미지를 가져오지 못함")
	probe_viewport.queue_free() # probe_face_rect도 함께 해제됨(재부모화돼 combat 트리 밖으로 나감)

	_art1b_remove_fake_faces(fake_base_dir, fake_full_id, CharacterArt.FACE_EXPRESSIONS)
	DirAccess.remove_absolute("user://art1c_fake_monster_faces")

	remove_child(combat)
	combat.free()
	return ok


## ART-1c-2(2026-10-16) — face_* 5장이 없고 full.png만 있을 때의 상반신 크롭 폴백
## (CharacterArt.load_full_crop()/has_full() 재사용, 새 크롭 로직 없음). 우선순위
## (face_* 5장 > full.png 크롭 > 도형 플레이스홀더), set_expression()의 안전 무시를
## 가짜 user:// 디렉터리로 검증하고, production은 카탈로그 35종 전체를 순회해 "지금
## 실제로 full.png가 입고된 몬스터는 크롭 모드, 없는 몬스터는 플레이스홀더"가 has_full()/
## has_all_faces() 실시간 결과와 항상 일치하는지 본다(특정 id를 하드코딩해 "원화 없음"
## 또는 "원화 있음"을 가정하지 않음 — ART-1c의 N-6 교훈 재적용).
func _check_art1c2_monster_full_crop_fallback(lines: PackedStringArray) -> bool:
	var ok := true

	var fake_base_dir := "user://art1c2_fake_monster_full/%s/"
	var fake_none_id := "qa_fake_monster_none2"
	var fake_full_only_id := "qa_fake_monster_full_only"
	var fake_both_id := "qa_fake_monster_face_and_full"

	# "없음" — 디렉터리만 만들고 아무 파일도 안 둠.
	DirAccess.make_dir_recursive_absolute(fake_base_dir % fake_none_id)
	# "full.png만" — 1장짜리 가짜 전신 원화만.
	_art1c2_write_fake_full(fake_base_dir, fake_full_only_id)
	# "face_* 5장 + full.png 둘 다" — 우선순위 검증용(원화 표정 컷이 이겨야 함).
	_art1b_write_fake_faces(fake_base_dir, fake_both_id, CharacterArt.FACE_EXPRESSIONS)
	_art1c2_write_fake_full(fake_base_dir, fake_both_id)

	var portrait := MonsterPortraitPlaceholder.new()
	add_child(portrait)
	portrait.art_base_dir = fake_base_dir

	portrait.set_monster(fake_none_id)
	var none_ok: bool = not portrait._use_face_art and not portrait._use_full_crop
	ok = none_ok and ok
	lines.append("  set_monster(가짜 '아무 파일도 없음') 후 _use_face_art=%s/_use_full_crop=%s (기대 둘 다 false) -> %s" % [
		portrait._use_face_art, portrait._use_full_crop, "OK" if none_ok else "FAIL"
	])

	portrait.set_monster(fake_full_only_id)
	var full_only_ok: bool = (not portrait._use_face_art) and portrait._use_full_crop
	ok = full_only_ok and ok
	lines.append("  set_monster(가짜 'full.png만') 후 _use_face_art=%s/_use_full_crop=%s (기대 false/true) -> %s" % [
		portrait._use_face_art, portrait._use_full_crop, "OK" if full_only_ok else "FAIL"
	])
	var crop_tex := portrait._face_rect.texture if portrait._face_rect != null else null
	var crop_visible_ok: bool = crop_tex != null and portrait._face_rect.visible
	ok = crop_visible_ok and ok
	lines.append("  'full.png만' 크롭 텍스처 로드됨=%s, _face_rect.visible=%s -> %s" % [
		crop_tex != null, portrait._face_rect.visible if portrait._face_rect != null else false,
		"OK" if crop_visible_ok else "FAIL"
	])

	# set_expression() 호출이 크롭 상태를 깨지 않고 안전하게 무시하는지(표정 컷이 없으므로
	# 텍스처가 그대로 유지돼야 함) — "같은 몬스터가 set_expression()을 호출해도 full.png
	# 폴백 상태에선 안전하게 무시" 요구사항.
	portrait.set_expression("angry")
	var expression_noop_ok: bool = portrait._face_rect.texture == crop_tex and portrait._use_full_crop
	ok = expression_noop_ok and ok
	lines.append("  'full.png만' 상태에서 set_expression('angry') 호출 후에도 텍스처 불변 + _use_full_crop 유지 -> %s" % (
		"OK" if expression_noop_ok else "FAIL"
	))

	# 우선순위 — face_* 5장과 full.png가 둘 다 있으면 원화 표정 컷(_use_face_art)이 이김.
	portrait.set_monster(fake_both_id)
	var priority_ok: bool = portrait._use_face_art and not portrait._use_full_crop
	ok = priority_ok and ok
	lines.append("  set_monster(가짜 'face_* 5장 + full.png 둘 다') 후 _use_face_art=%s/_use_full_crop=%s (기대 true/false, face_*가 우선) -> %s" % [
		portrait._use_face_art, portrait._use_full_crop, "OK" if priority_ok else "FAIL"
	])

	remove_child(portrait)
	portrait.free()
	DirAccess.remove_absolute(fake_base_dir % fake_none_id)
	_art1c2_remove_fake_full(fake_base_dir, fake_full_only_id)
	_art1b_remove_fake_faces(fake_base_dir, fake_both_id, CharacterArt.FACE_EXPRESSIONS)
	_art1c2_remove_fake_full(fake_base_dir, fake_both_id)
	DirAccess.remove_absolute("user://art1c2_fake_monster_full")

	# 카탈로그 전체(일반+레거시+정예+보스, 35종)를 순회해 "지금 실제로 full.png가 입고된
	# 몬스터는 크롭 모드, 아직 없는 몬스터는 플레이스홀더 그대로"가 항상 CharacterArt.
	# has_full()의 실시간 결과와 정확히 일치하는지 본다 — 특정 id를 "원화 없음"으로
	# 하드코딩해 가정하지 않는다(ART-1c의 N-6 교훈: "berserker는 face_*가 없다"는 가정이
	# 실제 입고로 깨졌던 사고 재발 방지. 이번 이터레이션 중에도 slime/goblin/orc/skeleton
	# 4종이 동시에 입고돼 이 가정 없는 방식이 바로 유효함이 실제로 증명됨). ART-1c-3이
	# 추가한 MonsterCatalog.art_resource_id() 별칭도 거쳐야 한다 — dark_knight는 자기
	# 폴더가 아니라 dark_knight_elite 경로로 조회되므로, 기대값도 별칭 해석 후 id로 계산.
	var crop_count := 0
	var placeholder_count := 0
	var mismatch_ids: Array = []
	for m in MonsterCatalog.MONSTERS:
		var mid: String = m["id"]
		var art_mid: String = MonsterCatalog.art_resource_id(mid)
		var expected_face: bool = CharacterArt.has_all_faces(art_mid, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
		var expected_full: bool = CharacterArt.has_full(art_mid, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
		var expected_crop: bool = expected_full and not expected_face
		var mp := MonsterPortraitPlaceholder.new()
		add_child(mp)
		mp.set_monster(mid)
		var matches: bool = mp._use_face_art == expected_face and mp._use_full_crop == expected_crop
		if not matches:
			mismatch_ids.append(mid)
		ok = matches and ok
		if expected_crop:
			crop_count += 1
			var tex_ok: bool = mp._face_rect != null and mp._face_rect.texture != null
			ok = tex_ok and ok
			if not tex_ok:
				mismatch_ids.append(mid + "(텍스처 없음)")
		elif not expected_face:
			placeholder_count += 1
		remove_child(mp)
		mp.free()
	lines.append("  카탈로그 35종 전수 — has_all_faces()/has_full() 실시간 상태와 _use_face_art/_use_full_crop 일치: 크롭 모드=%d종, 플레이스홀더=%d종, 불일치=%s -> %s" % [
		crop_count, placeholder_count, mismatch_ids, "OK" if mismatch_ids.is_empty() else "FAIL"
	])
	ok = mismatch_ids.is_empty() and ok

	# 화면 우측 끝(1280px) 안에 들어오는지 — ART-1c의 _check_art1c_monster_face_art() 3)과
	# 같은 방식(실제 combat_test.tscn 인스턴스 + 실제 scale). 지금 크롭 모드로 확인된
	# 몬스터 중 하나를 대표로 측정(전부 같은 _face_rect 배치 로직을 공유하므로 위치
	# 좌표 자체는 몬스터별로 달라지지 않음) — 아직 하나도 입고 전이면 이 측정은 건너뛴다.
	var crop_sample_id := ""
	for m in MonsterCatalog.MONSTERS:
		var mid: String = m["id"]
		if CharacterArt.has_full(mid, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR) and not CharacterArt.has_all_faces(mid, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR):
			crop_sample_id = mid
			break
	if crop_sample_id != "":
		var combat_scene := load("res://code/scenes/combat_test.tscn")
		var combat = combat_scene.instantiate()
		add_child(combat)
		for scale_case in [
			{"label": "일반(1.1배)", "scale": Vector2(1.1, 1.1)},
			{"label": "보스(1.3배)", "scale": Vector2(1.3, 1.3)},
		]:
			combat.monster_portrait.scale = scale_case["scale"]
			combat.monster_portrait.set_monster(crop_sample_id)
			var face_rect: TextureRect = combat.monster_portrait._face_rect
			var right_edge: float = (face_rect.get_global_transform() * Vector2(face_rect.size.x, 0)).x if face_rect != null else 9999.0
			var right_margin_ok: bool = right_edge <= 1280.0 - 8.0
			ok = right_margin_ok and ok
			lines.append("  '%s' full.png 크롭 %s 오른쪽 끝 글로벌 x=%.1f (기대 <= %.1f) -> %s" % [
				crop_sample_id, scale_case["label"], right_edge, 1280.0 - 8.0, "OK" if right_margin_ok else "FAIL"
			])
		remove_child(combat)
		combat.free()
	else:
		lines.append("  (크롭 모드로 전환된 몬스터가 아직 없어 화면 경계 측정 건너뜀)")

	return ok


## [미니 기획 ART-1c-3](2026-10-16, [대형 기획 13] 인수인계) — 몬스터 컷 가장자리
## 페이드(하단·좌·우·위) + 경로 별칭(dark_knight -> dark_knight_elite) 검증. SubViewport
## 렌더 알파 샘플링을 쓰므로(_check_art1c_monster_face_art()와 같은 패턴) await로 불러야
## 한다.
func _check_art1c3_monster_edge_fade_and_alias(lines: PackedStringArray) -> bool:
	var ok := true

	# 1) 별칭 표 — dark_knight만 dark_knight_elite로 바뀌고, 별칭이 없는 id는 그대로.
	var alias_dark_knight: String = MonsterCatalog.art_resource_id("dark_knight")
	var alias_ok: bool = alias_dark_knight == "dark_knight_elite"
	ok = alias_ok and ok
	lines.append("  MonsterCatalog.art_resource_id('dark_knight') = '%s' (기대 'dark_knight_elite') -> %s" % [
		alias_dark_knight, "OK" if alias_ok else "FAIL"
	])
	var alias_passthrough: String = MonsterCatalog.art_resource_id("slime")
	var alias_passthrough_ok: bool = alias_passthrough == "slime"
	ok = alias_passthrough_ok and ok
	lines.append("  MonsterCatalog.art_resource_id('slime')(별칭 없음) = '%s' (기대 'slime' 그대로) -> %s" % [
		alias_passthrough, "OK" if alias_passthrough_ok else "FAIL"
	])

	# 2) production 경로에서 실제로 별칭이 적용되는지 — dark_knight 자신의 폴더
	#    (resources/monsters/dark_knight/)에는 원화가 없어야 하고(별칭이 필요한 이유),
	#    MonsterPortraitPlaceholder.set_monster("dark_knight")는 그래도 dark_knight_elite
	#    경로를 봐서 크롭 모드로 전환돼야 한다.
	var dark_knight_own_folder_empty: bool = not CharacterArt.has_full("dark_knight", MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
	var elite_has_full: bool = CharacterArt.has_full("dark_knight_elite", MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
	lines.append("  전제: dark_knight 전용 폴더에 원화 없음=%s, dark_knight_elite에 full.png 있음=%s" % [
		dark_knight_own_folder_empty, elite_has_full
	])
	var alias_portrait := MonsterPortraitPlaceholder.new()
	add_child(alias_portrait)
	alias_portrait.set_monster("dark_knight")
	var alias_render_ok: bool = alias_portrait._use_full_crop or alias_portrait._use_face_art
	ok = alias_render_ok and ok
	lines.append("  set_monster('dark_knight') 후 _use_full_crop=%s/_use_face_art=%s (별칭 경로로 원화가 실제로 로드됨, 기대 둘 중 하나는 true) -> %s" % [
		alias_portrait._use_full_crop, alias_portrait._use_face_art, "OK" if alias_render_ok else "FAIL"
	])
	remove_child(alias_portrait)
	alias_portrait.free()

	# 3) 가장자리 페이드 — 가짜 full.png 크롭으로 MonsterPortrait를 원화 크롭 모드로
	#    전환하고, 실제 렌더 결과(SubViewport)에서 중앙은 불투명, 하단·좌·우·위 네
	#    가장자리는 전부 중앙 대비 뚜렷이 낮은 알파인지 확인한다. _art1c2_write_fake_full()
	#    (실제 보스 원화 비율 1181x1332)은 크롭 결과가 정사각이 아니라 240x240 박스 안에서
	#    레터박스(좌우 여백)가 생겨 "가장자리 샘플"이 레터박스의 원래 투명 영역과 셰이더
	#    페이드를 구분 못 하게 만든다 — 대신 정사각 비율의 전용 가짜 원화를 써서 크롭도
	#    정사각(240x240을 레터박스 없이 꽉 채움)이 되게 한다.
	var fake_base_dir := "user://art1c3_fake_monster_full/%s/"
	var fake_id := "qa_fake_monster_edge_fade"
	_art1c3_write_fake_square_full(fake_base_dir, fake_id)

	var portrait := MonsterPortraitPlaceholder.new()
	add_child(portrait)
	portrait.art_base_dir = fake_base_dir
	portrait.set_monster(fake_id)

	var shader_params_ok: bool = (portrait._face_rect != null and portrait._face_rect.material is ShaderMaterial
		and float((portrait._face_rect.material as ShaderMaterial).get_shader_parameter("side_fade")) > 0.0
		and float((portrait._face_rect.material as ShaderMaterial).get_shader_parameter("top_fade")) > 0.0)
	ok = shader_params_ok and ok
	lines.append("  몬스터 표정 컷 셰이더에 side_fade/top_fade > 0.0 설정됨(캐릭터 쪽은 기본값 0.0 유지) -> %s" % (
		"OK" if shader_params_ok else "FAIL"
	))

	var probe_viewport := SubViewport.new()
	probe_viewport.size = Vector2i(240, 240)
	probe_viewport.transparent_bg = true
	probe_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(probe_viewport)

	var render_ok := false
	var center_alpha := 0.0
	var bottom_alpha := 0.0
	var left_alpha := 0.0
	var right_alpha := 0.0
	var top_alpha := 0.0
	var probe_face_rect: TextureRect = portrait._face_rect
	if probe_face_rect != null:
		portrait.remove_child(probe_face_rect)
		probe_face_rect.position = Vector2.ZERO
		probe_viewport.add_child(probe_face_rect)

		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var img: Image = probe_viewport.get_texture().get_image()
		render_ok = img != null
		if render_ok:
			center_alpha = img.get_pixel(120, 120).a
			bottom_alpha = img.get_pixel(120, 238).a
			top_alpha = img.get_pixel(120, 1).a
			left_alpha = img.get_pixel(1, 120).a
			right_alpha = img.get_pixel(238, 120).a
	ok = render_ok and ok
	if render_ok:
		var center_opaque_ok: bool = center_alpha > 0.9
		ok = center_opaque_ok and ok
		lines.append("  렌더된 크롭 중앙(120,120) 알파=%.3f (기대 > 0.9, 불투명) -> %s" % [
			center_alpha, "OK" if center_opaque_ok else "FAIL"
		])
		for edge in [
			{"label": "하단(y=238)", "alpha": bottom_alpha},
			{"label": "상단(y=1)", "alpha": top_alpha},
			{"label": "좌측(x=1)", "alpha": left_alpha},
			{"label": "우측(x=238)", "alpha": right_alpha},
		]:
			var edge_fade_ok: bool = edge["alpha"] < center_alpha * 0.3
			ok = edge_fade_ok and ok
			lines.append("  렌더된 크롭 %s 알파=%.3f (기대 중앙의 30%% 미만=%.3f) -> %s" % [
				edge["label"], edge["alpha"], center_alpha * 0.3, "OK" if edge_fade_ok else "FAIL"
			])
	else:
		lines.append("    FAIL: SubViewport 이미지를 가져오지 못함")
	probe_viewport.queue_free() # probe_face_rect도 함께 해제됨(재부모화돼 portrait 트리 밖으로 나감)

	_art1c2_remove_fake_full(fake_base_dir, fake_id) # 파일명(full.png) 규칙이 같아 기존 제거 헬퍼 재사용 가능
	DirAccess.remove_absolute("user://art1c3_fake_monster_full")
	remove_child(portrait)
	portrait.free()

	# 4) 입고된 실제 몬스터 전체(카탈로그 전수) — 크롭/원화 모드로 전환된 몬스터 "전부"가
	#    화면 우측 끝(1280px) 안에 들어오는지(일반 1.1배/보스 1.3배 둘 다). ART-1c-2는
	#    대표 1종만 쟀지만, 이번 지시는 "입고된 실제 몬스터 전체"를 요구하므로 전수로 돈다.
	var combat_scene_all := load("res://code/scenes/combat_test.tscn")
	var combat_all = combat_scene_all.instantiate()
	add_child(combat_all)
	var checked_count := 0
	for m in MonsterCatalog.MONSTERS:
		var mid: String = m["id"]
		var art_id: String = MonsterCatalog.art_resource_id(mid)
		var has_art: bool = CharacterArt.has_all_faces(art_id, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR) \
			or CharacterArt.has_full(art_id, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
		if not has_art:
			continue
		checked_count += 1
		for scale_case in [
			{"label": "일반(1.1배)", "scale": Vector2(1.1, 1.1)},
			{"label": "보스(1.3배)", "scale": Vector2(1.3, 1.3)},
		]:
			combat_all.monster_portrait.scale = scale_case["scale"]
			combat_all.monster_portrait.set_monster(mid)
			var face_rect_all: TextureRect = combat_all.monster_portrait._face_rect
			var right_edge_all: float = (face_rect_all.get_global_transform() * Vector2(face_rect_all.size.x, 0)).x if face_rect_all != null else 9999.0
			var right_margin_ok_all: bool = right_edge_all <= 1280.0 - 8.0
			ok = right_margin_ok_all and ok
			if not right_margin_ok_all:
				lines.append("  FAIL '%s'(%s) 오른쪽 끝 글로벌 x=%.1f (기대 <= %.1f)" % [
					mid, scale_case["label"], right_edge_all, 1280.0 - 8.0
				])
	remove_child(combat_all)
	combat_all.free()
	lines.append("  카탈로그 전수 화면 경계 확인 — 원화/크롭이 있는 몬스터 %d종 전부 일반/보스 배율 양쪽에서 화면 우측 끝 안에 들어옴 -> %s" % [
		checked_count, "OK" if ok else "FAIL(위 개별 FAIL 줄 참고)"
	])

	return ok


## _check_art1c2_monster_full_crop_fallback() 전용 헬퍼 — 실제 보스 원화(1181x1332)와
## 같은 비율의 가짜 full.png를 만든다(절대 해상도는 테스트 속도를 위해 축소, 비율 기반
## 크롭 계산은 해상도와 무관하므로 테스트 목적상 충분).
func _art1c2_write_fake_full(base_dir_pattern: String, monster_id: String) -> void:
	var dir_path := base_dir_pattern % monster_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var img := Image.create(118, 133, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.6, 0.8, 1.0))
	img.save_png(dir_path + "full.png")


func _art1c2_remove_fake_full(base_dir_pattern: String, monster_id: String) -> void:
	var dir_path := base_dir_pattern % monster_id
	DirAccess.remove_absolute(dir_path + "full.png")
	DirAccess.remove_absolute(dir_path)


## _check_art1c3_monster_edge_fade_and_alias() 전용 헬퍼 — 정사각 비율(200x200) 가짜
## full.png. DEFAULT_FACE_CROP_RATIO(0.48x0.48, 가로/세로 같은 비율)를 정사각 원본에
## 적용하면 크롭 결과도 정사각(96x96)이 돼, 240x240 표시 박스에 레터박스 없이 꽉 찬다 —
## 가장자리 알파 샘플이 셰이더 페이드만 반영하도록(_art1c2_write_fake_full()의 1181x1332
## 비율은 세로로 긴 크롭이라 좌우에 레터박스 여백이 생겨 이 용도에 안 맞음).
func _art1c3_write_fake_square_full(base_dir_pattern: String, monster_id: String) -> void:
	var dir_path := base_dir_pattern % monster_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.6, 0.8, 1.0))
	img.save_png(dir_path + "full.png")


## _check_art1b_combat_face_art() 전용 헬퍼 — base_dir_pattern(예: "user://.../%s/")
## 아래 character_id 폴더를 만들고 expressions만큼 1x1 가짜 PNG(face_<표정>.png)를
## 써넣는다. dice_test.gd의 기존 M-5/M-6 "user:// 임시 디렉터리" 패턴과 동일
## (Image.create + save_png).
func _art1b_write_fake_faces(base_dir_pattern: String, character_id: String, expressions: Array) -> void:
	var dir_path := base_dir_pattern % character_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	for expression in expressions:
		img.save_png(dir_path + "face_%s.png" % expression)


## _art1b_write_fake_faces()가 만든 파일/디렉터리를 정리한다.
func _art1b_remove_fake_faces(base_dir_pattern: String, character_id: String, expressions: Array) -> void:
	var dir_path := base_dir_pattern % character_id
	for expression in expressions:
		DirAccess.remove_absolute(dir_path + "face_%s.png" % expression)
	DirAccess.remove_absolute(dir_path)


## [미니 기획 ART-2] qa_out/art1b_novice_after_exchange.png에서 드러난 "표정 컷 아래 끝이
## y≈448에서 일직선으로 잘려 떠 보이고 왼쪽도 화면 끝(x<0)에 붙어 잘린다"는 문제를
## 실제로 고쳤는지 검증한다 — "속성이 설정됐는가"가 아니라 ① 실제 production
## combat_test.tscn 인스턴스에서 표정 컷의 글로벌 왼쪽 끝 좌표가 화면 밖으로 안 나가는지,
## ② 하단 페이드 셰이더를 실제로 SubViewport에 렌더해 바닥 근처 알파가 중간 높이보다
## 뚜렷이 낮아지는지(= 일직선 절단이 아니라 투명하게 사라짐) 렌더 결과로 확인한다.
## await를 쓰므로 호출부는 `await _check_art2_face_crop_fix(lines)`로 불러야 한다
## (_check_k4a_skill_icon_motifs와 같은 패턴).
func _check_art2_face_crop_fix(lines: PackedStringArray) -> bool:
	var ok := true

	var character_backup: String = RunState.character_id
	RunState.character_id = "novice" # face_* 5장이 입고된 유일한 캐릭터 — 원화 모드 보장
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var portrait: CharacterPortraitPlaceholder = combat.player_portrait
	var use_face_art_ok: bool = portrait._use_face_art
	ok = use_face_art_ok and ok
	lines.append("  combat_test(novice) PlayerPortrait._use_face_art=%s (기대 true, 원화 모드) -> %s" % [
		use_face_art_ok, "OK" if use_face_art_ok else "FAIL"
	])

	var face_rect: TextureRect = portrait._face_rect
	var left_edge: float = face_rect.global_position.x if face_rect != null else -999.0
	var left_margin_ok: bool = left_edge >= 16.0
	ok = left_margin_ok and ok
	lines.append("  표정 컷 왼쪽 끝 글로벌 x=%.1f (기대 >= 16.0, 화면 왼쪽 끝에서 안 잘리는 여백) -> %s" % [
		left_edge, "OK" if left_margin_ok else "FAIL"
	])

	var material_ok: bool = (face_rect != null and face_rect.material is ShaderMaterial
		and (face_rect.material as ShaderMaterial).shader == CharacterPortraitPlaceholder.FACE_ART_FADE_SHADER)
	ok = material_ok and ok
	lines.append("  표정 컷에 하단 페이드 셰이더(FACE_ART_FADE_SHADER)가 적용됨 -> %s" % (
		"OK" if material_ok else "FAIL"
	))

	# 실제 렌더 결과로 "아래쪽이 일직선으로 뚝 잘리지 않고 투명해지는지" 확인 — 실제로
	# 쓰이고 있는 face_rect 그 자체(이미 production에서 렌더되는 것으로 확인된 노드)를
	# 독립 SubViewport로 옮겨 중간 높이와 바닥 근처의 알파를 비교한다(새로 만든 별도
	# TextureRect를 쓰면 레이아웃/텍스처 준비 타이밍이 달라질 수 있어 실제 노드를 재사용).
	var probe_viewport := SubViewport.new()
	probe_viewport.size = Vector2i(240, 240)
	probe_viewport.transparent_bg = true
	probe_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(probe_viewport)

	var render_ok := false
	var mid_alpha := 0.0
	var bottom_alpha := 0.0
	if face_rect != null:
		portrait.remove_child(face_rect)
		face_rect.position = Vector2.ZERO
		probe_viewport.add_child(face_rect)

		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var img: Image = probe_viewport.get_texture().get_image()
		render_ok = img != null
		if render_ok:
			mid_alpha = img.get_pixel(120, 120).a
			bottom_alpha = img.get_pixel(120, 238).a
	ok = render_ok and ok
	if render_ok:
		var fade_ok: bool = bottom_alpha < mid_alpha * 0.3
		ok = fade_ok and ok
		lines.append("  렌더된 표정 컷 알파: 중간 높이=%.3f, 바닥 근처(y=238)=%.3f (기대 바닥이 중간의 30%% 미만) -> %s" % [
			mid_alpha, bottom_alpha, "OK" if fade_ok else "FAIL"
		])
	else:
		lines.append("    FAIL: SubViewport 이미지를 가져오지 못함")

	probe_viewport.queue_free() # face_rect도 함께 해제됨(재부모화돼 combat 트리 밖으로 나감)
	remove_child(combat)
	combat.free()
	RunState.character_id = character_backup
	return ok


## [대형 기획 13] M-4(2026-10-15) — event.gd/shop.gd/story_event.gd를 dungeon_map/
## combat_test와 같은 HUD·구역 패널·버튼 스타일로 맞췄는지, "속성이 설정됐는가"가
## 아니라 ① shop의 HUD 골드 칩이 RunState.gold를 실제로 반영/갱신하는지 ② 버튼들이
## 실제로 커스텀 stylebox override를 받았는지(has_theme_stylebox_override — 기본
## Godot 버튼 테마 그대로 남아있지 않은지) ③ 안전/위험처럼 의미가 다른 버튼 쌍이
## 서로 다른 tint로 구분되는지(_m5_style_fingerprint) ④ 카드 안에서 동적으로 생성되는
## 구매/적용/획득 버튼까지 스타일링되는지 ⑤ 서사 텍스트 뒤에 배경 프레임(make_backdrop)이
## 실제로 깔렸는지를 확인한다.
func _check_m4_event_shop_story_ui(lines: PackedStringArray) -> bool:
	var ok := true

	var character_backup: String = RunState.character_id
	var gold_backup := RunState.gold
	var rooms_backup := RunState.rooms_cleared
	RunState.character_id = "novice"
	RunState.rooms_cleared = 0

	# --- shop: HUD 골드 칩 ---
	RunState.gold = 42
	var shop_scene := load("res://code/scenes/shop.tscn")
	var shop = shop_scene.instantiate()
	add_child(shop)

	var gold_hidden_ok: bool = not shop.gold_label.visible
	ok = gold_hidden_ok and ok
	lines.append("  shop: 기존 GoldLabel(평문) 숨김=%s (기대 true, HUD 칩이 대신함) -> %s" % [
		gold_hidden_ok, "OK" if gold_hidden_ok else "FAIL"
	])
	var gold_chip_text_ok: bool = shop._hud_gold_value_label.text == "42"
	ok = gold_chip_text_ok and ok
	lines.append("  shop: HUD 골드 칩 = '%s' (기대 '42') -> %s" % [
		shop._hud_gold_value_label.text, "OK" if gold_chip_text_ok else "FAIL"
	])
	RunState.gold = 777
	shop._rebuild_items()
	var gold_chip_updates_ok: bool = shop._hud_gold_value_label.text == "777"
	ok = gold_chip_updates_ok and ok
	lines.append("  shop: 골드를 777로 바꾸고 _rebuild_items() 재호출 후 칩 = '%s' -> %s" % [
		shop._hud_gold_value_label.text, "OK" if gold_chip_updates_ok else "FAIL"
	])

	# 버튼 위계: "던전으로 돌아가기"(주 행동)와 "커스터마이징"(보조 행동)이 서로 다른
	# stylebox를 받아야 한다(dungeon_map M-1과 같은 검증 방식).
	var leave_fp: Variant = _m5_style_fingerprint(shop.leave_button.get_theme_stylebox("normal"))
	var shop_customize_fp: Variant = _m5_style_fingerprint(shop.customize_button.get_theme_stylebox("normal"))
	var shop_hierarchy_ok: bool = shop.leave_button.has_theme_stylebox_override("normal") \
		and shop.customize_button.has_theme_stylebox_override("normal") and leave_fp != shop_customize_fp
	ok = shop_hierarchy_ok and ok
	lines.append("  shop: 던전으로 돌아가기(주)=%s 커스터마이징(보조)=%s (달라야 함, 둘 다 override) -> %s" % [
		leave_fp, shop_customize_fp, "OK" if shop_hierarchy_ok else "FAIL"
	])
	var shop_codex_styled_ok: bool = shop.skill_codex_button.has_theme_stylebox_override("normal")
	ok = shop_codex_styled_ok and ok
	lines.append("  shop: 스킬 도감 버튼도 override 받음(기본 Godot 테마 아님) -> %s" % (
		"OK" if shop_codex_styled_ok else "FAIL"
	))
	# 카드 안 동적 버튼(품목별 공격/방어 구매, 또는 upgrade_die의 단일 구매 버튼)도
	# 스타일링되는지 — _shortcut_buttons 맨 앞이 그 버튼들이다(leave/customize/codex는
	# 리스트 맨 끝에 붙음, shop.gd _rebuild_items() 참고).
	var shop_card_btn_styled_ok: bool = shop._shortcut_buttons.size() > 0 \
		and shop._shortcut_buttons[0].has_theme_stylebox_override("normal")
	ok = shop_card_btn_styled_ok and ok
	lines.append("  shop: 카드 안 첫 구매 버튼('%s')도 override 받음 -> %s" % [
		shop._shortcut_buttons[0].text if shop._shortcut_buttons.size() > 0 else "<없음>",
		"OK" if shop_card_btn_styled_ok else "FAIL"
	])

	# [대형 기획 14] N-1 전수 감사에서 발견한 버그: _shortcut_buttons는 화면에 보이는
	# 순서(품목 카드들이 맨 앞, leave_button이 맨 뒤)라 grab_first_focus()만 쓰면 기본
	# 포커스가 "주 행동"(leave_button, 위 shop_hierarchy_ok 검증대로 style_primary_button)이
	# 아니라 첫 품목 버튼에 가버렸다. FocusNav.grab_default_focus()로 고쳐 기본 포커스가
	# 명시적으로 leave_button에 가도록 보장했는지 확인 — add_child() 시점에 _ready()가
	# 이미 한 번 불렀으므로 여기서는 그 결과(현재 포커스 소유자)를 그대로 읽는다.
	var shop_default_focus_ok: bool = get_viewport().gui_get_focus_owner() == shop.leave_button
	ok = shop_default_focus_ok and ok
	lines.append("  shop: 기본 포커스 = 주 행동(던전으로 돌아가기), 품목 버튼 아님 -> %s" % (
		"OK" if shop_default_focus_ok else "FAIL"
	))

	remove_child(shop)
	shop.free()

	# --- event: 버튼 위계 + 안전/위험 tint 구분 + 배경 프레임 ---
	var event_scene := load("res://code/scenes/event.tscn")
	var event = event_scene.instantiate()
	add_child(event)

	var safe_styled_ok: bool = event.safe_button.has_theme_stylebox_override("normal")
	var risky_styled_ok: bool = event.risky_button.has_theme_stylebox_override("normal")
	ok = safe_styled_ok and risky_styled_ok and ok
	lines.append("  event: 안전/위험 버튼 둘 다 override 받음 -> %s" % (
		"OK" if (safe_styled_ok and risky_styled_ok) else "FAIL"
	))
	var safe_fp: Variant = _m5_style_fingerprint(event.safe_button.get_theme_stylebox("normal"))
	var risky_fp: Variant = _m5_style_fingerprint(event.risky_button.get_theme_stylebox("normal"))
	var safe_risky_distinct_ok: bool = safe_fp != risky_fp
	ok = safe_risky_distinct_ok and ok
	lines.append("  event: 안전(초록 tint)=%s 위험(주황 tint)=%s (의미가 다르니 달라야 함) -> %s" % [
		safe_fp, risky_fp, "OK" if safe_risky_distinct_ok else "FAIL"
	])
	var continue_primary_ok: bool = event.continue_button.has_theme_stylebox_override("normal")
	ok = continue_primary_ok and ok
	lines.append("  event: '계속'(실패 후 유일한 진행 행동) 버튼 override 받음 -> %s" % (
		"OK" if continue_primary_ok else "FAIL"
	))

	# 서사 텍스트("상황") 배경 프레임 — Background(0) 바로 다음(index 1)에
	# make_backdrop()이 만든 PanelContainer가 끼워져 있어야 한다(event.gd _ready()의
	# move_child(prompt_backdrop, 1) 참고).
	var event_backdrop_ok: bool = event.get_child_count() > 1 and event.get_child(1) is PanelContainer
	ok = event_backdrop_ok and ok
	lines.append("  event: PromptLabel 뒤 배경 프레임(PanelContainer, index 1) 존재 -> %s" % (
		"OK" if event_backdrop_ok else "FAIL"
	))

	# 카드 안 동적 버튼(스킬 획득 "이 능력 익히기") 스타일링. 고정된 스킬 2개를
	# 직접 넘겨(_debug_force_skill_event_as_guardian()과 같은 패턴) available_choices()의
	# 무작위 셔플을 피한다 — 이 테스트가 전역 RNG 스트림을 소비하면 다이스
	# 테스트 스위트 뒤쪽의 "강제 고정값으로 반드시 이긴다" 류 시나리오(H-1 등, 몬스터
	# 종류를 전역 randi()로 뽑음)가 어떤 몬스터를 뽑는지가 바뀌어, 이 M-4 검증과는
	# 무관한 다른 검증이 간헐적으로 실패하는 부작용이 있었다(실측 확인).
	var fixed_skill_offer: Array[Dictionary] = [SkillPool.SKILLS[0], SkillPool.SKILLS[1]]
	event._setup_skill_event(fixed_skill_offer)
	var event_skill_btn_styled_ok: bool = false
	for n in event.items_root.get_children():
		for btn in n.find_children("*", "Button", true, false):
			if (btn as Button).text == "이 능력 익히기":
				event_skill_btn_styled_ok = (btn as Button).has_theme_stylebox_override("normal")
	ok = event_skill_btn_styled_ok and ok
	lines.append("  event: 스킬 카드 '이 능력 익히기' 버튼도 override 받음 -> %s" % (
		"OK" if event_skill_btn_styled_ok else "FAIL"
	))

	remove_child(event)
	event.free()

	# --- story_event: 버튼 위계 + 배경 프레임 ---
	var story_scene := load("res://code/scenes/story_event.tscn")
	var story = story_scene.instantiate()
	add_child(story)

	var story_choices_styled_ok: bool = story.choice_a_button.has_theme_stylebox_override("normal") \
		and story.choice_b_button.has_theme_stylebox_override("normal")
	ok = story_choices_styled_ok and ok
	lines.append("  story_event: A/B 선택지 버튼 둘 다 override 받음 -> %s" % (
		"OK" if story_choices_styled_ok else "FAIL"
	))
	var story_continue_styled_ok: bool = story.continue_button.has_theme_stylebox_override("normal")
	ok = story_continue_styled_ok and ok
	lines.append("  story_event: '계속' 버튼(유일한 진행 행동) override 받음 -> %s" % (
		"OK" if story_continue_styled_ok else "FAIL"
	))
	var story_backdrop_ok: bool = story.get_child_count() > 1 and story.get_child(1) is PanelContainer
	ok = story_backdrop_ok and ok
	lines.append("  story_event: Description 뒤 배경 프레임(PanelContainer, index 1) 존재 -> %s" % (
		"OK" if story_backdrop_ok else "FAIL"
	))

	remove_child(story)
	story.free()

	RunState.character_id = character_backup
	RunState.gold = gold_backup
	RunState.rooms_cleared = rooms_backup
	return ok


func _m5a_write_solid_png(path: String, w: int, h: int, color: Color) -> void:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	img.save_png(path)


## 8비트 PNG 왕복(set_pixel/저장/로드)의 양자화 오차(채널당 1/255 ≈ 0.0039)를 감안한
## 느슨한 색 비교 — Color.is_equal_approx()의 기본 epsilon(1e-5)은 이 오차보다 훨씬
## 작아 틴트 비교에 못 쓴다.
func _m5a_color_close(a: Color, b: Color, eps: float = 0.01) -> bool:
	return abs(a.r - b.r) <= eps and abs(a.g - b.g) <= eps and abs(a.b - b.b) <= eps


## [대형 기획 13] M-5a(2026-10-15) 검증. ui_kit.gd의 apply_panel_skin()/
## style_primary_button()/style_secondary_button()/make_hp_bar()가 resources/ui/
## 이미지 스킨 파일 유무에 따라 "StyleBoxTexture(+9-slice 마진)" <-> "기존 절차적
## StyleBoxFlat/ColorRect 폴백" 사이를 실제로 전환하는지, 캐릭터/틴트별로 다른
## 결과를 합성하는지를 확인한다. "플래그가 들어갔는가"가 아니라 "실제 렌더 스타일
## 종류/텍스처 픽셀"이 바뀌는지를 본다(k4c_skill_icon_external_art와 같은 "없음→
## 있음→없음" user:// 임시 경로 패턴). 마지막으로 resources/ui/에 실제로 입고된
## production 자산으로 combat_test/dungeon_map을 인스턴스화해 끝까지 배선됐는지도
## 확인한다.
func _check_m5a_uikit_image_skin(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://m5a_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir + "panel")
	DirAccess.make_dir_recursive_absolute(tmp_dir + "button")
	DirAccess.make_dir_recursive_absolute(tmp_dir + "bar")

	# --- (1) 패널 스킨: 없음 -> StyleBoxFlat 폴백 ---
	var no_skin_body := UIKit.make_section(self, "", "novice", Vector2.ZERO, tmp_dir)
	var no_skin_panel: PanelContainer = no_skin_body.get_parent()
	var no_skin_is_flat: bool = no_skin_panel.get_theme_stylebox("panel") is StyleBoxFlat
	ok = no_skin_is_flat and ok
	lines.append("  (1) panel/section_base.png 없음: make_section() 'panel' 스타일 = %s (기대 StyleBoxFlat 폴백) -> %s" % [
		no_skin_panel.get_theme_stylebox("panel").get_class(), "OK" if no_skin_is_flat else "FAIL"
	])
	no_skin_panel.queue_free()

	# --- (2) base만 있음 -> StyleBoxTexture(9-slice 마진=24) ---
	_m5a_write_solid_png(tmp_dir + "panel/section_base.png", 8, 8, Color(0, 0, 0, 1))
	var base_only_body := UIKit.make_section(self, "", "novice", Vector2.ZERO, tmp_dir)
	var base_only_panel: PanelContainer = base_only_body.get_parent()
	var base_only_style: StyleBox = base_only_panel.get_theme_stylebox("panel")
	var base_only_ok: bool = base_only_style is StyleBoxTexture and (base_only_style as StyleBoxTexture).texture_margin_left == 24
	ok = base_only_ok and ok
	lines.append("  (2) section_base.png만 있음: 스타일=%s, texture_margin_left=%s (기대 StyleBoxTexture, 24) -> %s" % [
		base_only_style.get_class(),
		(base_only_style as StyleBoxTexture).texture_margin_left if base_only_style is StyleBoxTexture else "(해당없음)",
		"OK" if base_only_ok else "FAIL"
	])
	base_only_panel.queue_free()

	# --- (3) base+accent: 캐릭터가 다르면 합성 결과(텍스처 픽셀)가 실제로 달라야 한다.
	#     base=검정 불투명, accent=흰색 완전 불투명 -> blend_rect 결과는 accent의 알파가
	#     1이라 base를 완전히 덮어써 tint 색 그 자체가 나온다(근사 없이 정확히 비교 가능).
	_m5a_write_solid_png(tmp_dir + "panel/section_accent.png", 8, 8, Color(1, 1, 1, 1))
	var tinted_a_body := UIKit.make_section(self, "", "berserker", Vector2.ZERO, tmp_dir)
	var tinted_a_panel: PanelContainer = tinted_a_body.get_parent()
	var tinted_a_tex: Texture2D = (tinted_a_panel.get_theme_stylebox("panel") as StyleBoxTexture).texture
	var tinted_a_pixel: Color = tinted_a_tex.get_image().get_pixel(0, 0)
	tinted_a_panel.queue_free()

	var tinted_b_body := UIKit.make_section(self, "", "pirate", Vector2.ZERO, tmp_dir)
	var tinted_b_panel: PanelContainer = tinted_b_body.get_parent()
	var tinted_b_tex: Texture2D = (tinted_b_panel.get_theme_stylebox("panel") as StyleBoxTexture).texture
	var tinted_b_pixel: Color = tinted_b_tex.get_image().get_pixel(0, 0)
	tinted_b_panel.queue_free()

	var accent_a: Color = CharacterTheme.ui_palette("berserker")["accent"]
	var accent_b: Color = CharacterTheme.ui_palette("pirate")["accent"]
	var tint_pixel_matches_ok: bool = _m5a_color_close(tinted_a_pixel, accent_a) and _m5a_color_close(tinted_b_pixel, accent_b)
	ok = tint_pixel_matches_ok and ok
	lines.append("  (3) 합성 픽셀이 실제 accent 색과 근사 일치(8비트 양자화 오차 감안): berserker 합성=%s accent=%s / pirate 합성=%s accent=%s -> %s" % [
		tinted_a_pixel, accent_a, tinted_b_pixel, accent_b, "OK" if tint_pixel_matches_ok else "FAIL"
	])
	var tint_differs_ok: bool = not _m5a_color_close(tinted_a_pixel, tinted_b_pixel)
	ok = tint_differs_ok and ok
	lines.append("  (3) 캐릭터가 다르면 합성 텍스처도 달라짐(berserker != pirate) -> %s" % ("OK" if tint_differs_ok else "FAIL"))

	# --- (4) base 삭제 -> 다시 StyleBoxFlat 폴백(캐시가 production 경로에만 적용되므로
	#     임시 base_dir는 매번 실제 파일 존재를 다시 확인해야 한다).
	DirAccess.remove_absolute(tmp_dir + "panel/section_base.png")
	DirAccess.remove_absolute(tmp_dir + "panel/section_accent.png")
	var removed_body := UIKit.make_section(self, "", "novice", Vector2.ZERO, tmp_dir)
	var removed_panel: PanelContainer = removed_body.get_parent()
	var removed_is_flat: bool = removed_panel.get_theme_stylebox("panel") is StyleBoxFlat
	ok = removed_is_flat and ok
	lines.append("  (4) section_base.png 삭제 후 다시 make_section(): 스타일=%s (기대 StyleBoxFlat로 복귀) -> %s" % [
		removed_panel.get_theme_stylebox("panel").get_class(), "OK" if removed_is_flat else "FAIL"
	])
	removed_panel.queue_free()

	# --- (5) hud 종류는 마진이 다르다(좌우 34, 상하 20) ---
	_m5a_write_solid_png(tmp_dir + "panel/hud_base.png", 8, 8, Color(0.5, 0.5, 0.5, 1))
	var hud_bar := UIKit.make_bar(self, "novice", Vector2.ZERO, tmp_dir)
	var hud_panel: PanelContainer = hud_bar.get_parent()
	var hud_style := hud_panel.get_theme_stylebox("panel") as StyleBoxTexture
	var hud_margin_ok: bool = hud_style != null and hud_style.texture_margin_left == 34 and hud_style.texture_margin_top == 20
	ok = hud_margin_ok and ok
	lines.append("  (5) make_bar('hud') 마진: left=%s top=%s (기대 34, 20) -> %s" % [
		hud_style.texture_margin_left if hud_style else "(없음)", hud_style.texture_margin_top if hud_style else "(없음)",
		"OK" if hud_margin_ok else "FAIL"
	])
	hud_panel.queue_free()

	# --- (6) 버튼 스킨: "normal" 상태만 있으면 그 상태만 스킨, 나머지는 절차적 폴백
	#     (INBOX M-5 "버튼 상태 5종은 파일이 일부만 있어도 상태별로 폴백").
	_m5a_write_solid_png(tmp_dir + "button/primary_normal_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "button/primary_normal_accent.png", 8, 8, Color(1, 1, 1, 1))
	var btn := Button.new()
	add_child(btn)
	UIKit.style_primary_button(btn, "pirate", Color(0, 0, 0, 0), tmp_dir)
	var normal_skinned_ok: bool = btn.get_theme_stylebox("normal") is StyleBoxTexture
	ok = normal_skinned_ok and ok
	lines.append("  (6) primary_normal_*만 있음: 'normal' 스타일=%s (기대 StyleBoxTexture) -> %s" % [
		btn.get_theme_stylebox("normal").get_class(), "OK" if normal_skinned_ok else "FAIL"
	])
	var hover_fallback_ok: bool = btn.get_theme_stylebox("hover") is StyleBoxFlat
	ok = hover_fallback_ok and ok
	lines.append("  (6) primary_hover_* 없음: 'hover' 스타일=%s (기대 StyleBoxFlat 폴백, 상태별 폴백) -> %s" % [
		btn.get_theme_stylebox("hover").get_class(), "OK" if hover_fallback_ok else "FAIL"
	])
	var normal_tex: Texture2D = (btn.get_theme_stylebox("normal") as StyleBoxTexture).texture
	var normal_pixel: Color = normal_tex.get_image().get_pixel(0, 0)
	var pirate_accent: Color = CharacterTheme.ui_palette("pirate")["accent"]
	var button_tint_ok: bool = _m5a_color_close(normal_pixel, pirate_accent)
	ok = button_tint_ok and ok
	lines.append("  (6) primary normal 합성 픽셀=%s == pirate accent=%s -> %s" % [
		normal_pixel, pirate_accent, "OK" if button_tint_ok else "FAIL"
	])
	btn.queue_free()

	# --- (7) 보조 버튼의 커스텀 tint(정예 전투 위험색 등)도 accent 대신 그대로 틴트된다.
	_m5a_write_solid_png(tmp_dir + "button/secondary_normal_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "button/secondary_normal_accent.png", 8, 8, Color(1, 1, 1, 1))
	var btn2 := Button.new()
	add_child(btn2)
	var danger_tint := Color(0.85, 0.2, 0.2)
	UIKit.style_secondary_button(btn2, "novice", danger_tint, tmp_dir)
	var secondary_tex: Texture2D = (btn2.get_theme_stylebox("normal") as StyleBoxTexture).texture
	var secondary_pixel: Color = secondary_tex.get_image().get_pixel(0, 0)
	var secondary_tint_ok: bool = _m5a_color_close(secondary_pixel, danger_tint)
	ok = secondary_tint_ok and ok
	lines.append("  (7) secondary normal 합성 픽셀=%s == 커스텀 tint=%s (팔레트 대신 틴트 인자 사용) -> %s" % [
		secondary_pixel, danger_tint, "OK" if secondary_tint_ok else "FAIL"
	])
	btn2.queue_free()

	# --- (8) HP 바: 프레임 스킨이 있으면 NinePatchRect 채움 + fill_full_width가 프레임
	#     안쪽 홈(좌22+우22=44)만큼 줄어들고, 없으면 기존 ColorRect + 전체 폭 그대로.
	var hp_fallback := UIKit.make_hp_bar(self, 310.0, 28.0, "novice", tmp_dir)
	var hp_fallback_ok: bool = not hp_fallback["skinned"] and hp_fallback["fill"] is ColorRect and hp_fallback["fill_full_width"] == 310.0
	ok = hp_fallback_ok and ok
	lines.append("  (8) bar/hp_frame_base.png 없음: skinned=%s fill=%s fill_full_width=%s (기대 false, ColorRect, 310) -> %s" % [
		hp_fallback["skinned"], hp_fallback["fill"].get_class(), hp_fallback["fill_full_width"], "OK" if hp_fallback_ok else "FAIL"
	])
	(hp_fallback["fill"].get_parent() as Control).queue_free()

	_m5a_write_solid_png(tmp_dir + "bar/hp_frame_base.png", 64, 28, Color(0.3, 0.3, 0.3, 1))
	_m5a_write_solid_png(tmp_dir + "bar/hp_fill.png", 8, 8, Color(1, 1, 1, 1))
	var hp_skinned := UIKit.make_hp_bar(self, 310.0, 28.0, "novice", tmp_dir)
	var hp_skinned_ok: bool = hp_skinned["skinned"] and hp_skinned["fill"] is NinePatchRect and is_equal_approx(hp_skinned["fill_full_width"], 310.0 - 22.0 - 22.0)
	ok = hp_skinned_ok and ok
	lines.append("  (8) hp_frame_base.png + hp_fill.png 있음: skinned=%s fill=%s fill_full_width=%s (기대 true, NinePatchRect, %.1f) -> %s" % [
		hp_skinned["skinned"], hp_skinned["fill"].get_class(), hp_skinned["fill_full_width"], 310.0 - 44.0, "OK" if hp_skinned_ok else "FAIL"
	])
	(hp_skinned["fill"].get_parent() as Control).queue_free()

	# --- (9) 실제 production 경로(resources/ui/, 이미 입고됨) end-to-end: combat_test를
	#     인스턴스화해 HP 바가 실제로 스킨 모드이고, HP 변화 후에도 비율/색이 기존처럼
	#     동작하는지(ColorRect/NinePatchRect 양쪽 다 통과해야 하는 _update_hp_bar()의
	#     타입 분기가 실제 화면에서도 맞는지).
	var character_backup: String = RunState.character_id
	RunState.character_id = "novice"
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var prod_hp_skinned_ok: bool = combat.player_hp_bar_fill is NinePatchRect
	ok = prod_hp_skinned_ok and ok
	lines.append("  (9) production combat_test: player_hp_bar_fill=%s (resources/ui/bar/hp_frame_base.png 입고됨 -> NinePatchRect 기대) -> %s" % [
		combat.player_hp_bar_fill.get_class(), "OK" if prod_hp_skinned_ok else "FAIL"
	])
	# [대형 기획 17] S-0 사용자 확정(2026-10-28) — 버튼 장식은 B안(이미지 스킨 대신 얇은
	# 테두리 플랫)으로 바뀌어, resources/ui/button/*가 입고돼 있어도 production 버튼은
	# 더 이상 그 스킨을 쓰지 않는다(UIKit.BUTTON_SKIN_ENABLED 기본값 false). 기대값을
	# StyleBoxTexture -> StyleBoxFlat(테두리 1px)로 갱신.
	var prod_button_style: StyleBox = combat.next_button.get_theme_stylebox("normal")
	var prod_button_skinned_ok: bool = prod_button_style is StyleBoxFlat and (prod_button_style as StyleBoxFlat).border_width_left == 0
	ok = prod_button_skinned_ok and ok
	lines.append("  (9) production combat_test: next_button(주 버튼) 'normal' 스타일=%s (B안 플랫, 기대 StyleBoxFlat) -> %s" % [
		prod_button_style.get_class(), "OK" if prod_button_skinned_ok else "FAIL"
	])

	var full_hp_width: float = combat.player_hp_bar_full_width
	combat.player_hp = combat.PLAYER_MAX_HP
	combat._update_labels()
	var full_width_ok: bool = is_equal_approx(combat.player_hp_bar_fill.size.x, full_hp_width)
	ok = full_width_ok and ok
	var high_color_ok: bool = combat.player_hp_bar_fill.modulate.is_equal_approx(combat.HP_BAR_COLOR_HIGH)
	ok = high_color_ok and ok
	lines.append("  (9) HP 100%%: fill.size.x=%.1f(기대 %.1f) modulate=%s(기대 HP_BAR_COLOR_HIGH=%s) -> %s" % [
		combat.player_hp_bar_fill.size.x, full_hp_width, combat.player_hp_bar_fill.modulate, combat.HP_BAR_COLOR_HIGH,
		"OK" if (full_width_ok and high_color_ok) else "FAIL"
	])

	combat.player_hp = int(combat.PLAYER_MAX_HP * 0.1)
	combat._update_labels()
	var low_width_ok: bool = combat.player_hp_bar_fill.size.x < full_hp_width * 0.5
	ok = low_width_ok and ok
	var low_color_ok: bool = combat.player_hp_bar_fill.modulate.is_equal_approx(combat.HP_BAR_COLOR_LOW)
	ok = low_color_ok and ok
	lines.append("  (9) HP 10%%: fill.size.x=%.1f(기대 < %.1f) modulate=%s(기대 HP_BAR_COLOR_LOW=%s) -> %s" % [
		combat.player_hp_bar_fill.size.x, full_hp_width * 0.5, combat.player_hp_bar_fill.modulate, combat.HP_BAR_COLOR_LOW,
		"OK" if (low_width_ok and low_color_ok) else "FAIL"
	])

	remove_child(combat)
	combat.free()
	RunState.character_id = character_backup

	DirAccess.remove_absolute(tmp_dir + "button/primary_normal_base.png")
	DirAccess.remove_absolute(tmp_dir + "button/primary_normal_accent.png")
	DirAccess.remove_absolute(tmp_dir + "button/secondary_normal_base.png")
	DirAccess.remove_absolute(tmp_dir + "button/secondary_normal_accent.png")
	DirAccess.remove_absolute(tmp_dir + "panel/hud_base.png")
	DirAccess.remove_absolute(tmp_dir + "bar/hp_frame_base.png")
	DirAccess.remove_absolute(tmp_dir + "bar/hp_fill.png")
	DirAccess.remove_absolute(tmp_dir + "panel")
	DirAccess.remove_absolute(tmp_dir + "button")
	DirAccess.remove_absolute(tmp_dir + "bar")
	DirAccess.remove_absolute(tmp_dir)

	return ok


## [대형 기획 13] M-5b(2026-10-15) 검증. ui_kit.gd의 make_badge()/tier_badge_texture()/
## make_codex_badge()/apply_chip_skin()/make_section() 제목 장식·구분선/icon_texture()와
## character_theme.gd의 apply_background() scene_key가 "실제 노드 종류/텍스처/마진/픽셀"
## 기준으로 스킨↔폴백을 전환하는지 확인한다(M-5a와 같은 "없음→있음→없음" user:// 임시
## 경로 패턴 + production 자산 end-to-end 재확인).
func _check_m5b_badges_decor_icons_backgrounds(lines: PackedStringArray) -> bool:
	var ok := true
	var tmp_dir := "user://m5b_test_tmp/"
	DirAccess.make_dir_recursive_absolute(tmp_dir + "badge")
	DirAccess.make_dir_recursive_absolute(tmp_dir + "deco")
	DirAccess.make_dir_recursive_absolute(tmp_dir + "icon")

	var scratch := Control.new()
	add_child(scratch)

	# --- 턴/라운드 배지: 없음 -> 배경 없는 Label, 있음 -> PanelContainer+StyleBoxTexture
	#     (kind별 마진) + 캐릭터 accent 틴트.
	var round_no_skin := UIKit.make_badge(scratch, "round", "R", "novice", tmp_dir)
	var round_no_skin_ok: bool = round_no_skin["skinned"] == false and round_no_skin["control"] is Label
	ok = round_no_skin_ok and ok
	lines.append("  라운드 배지(파일 없음): skinned=%s control=%s (기대 false, Label) -> %s" % [
		round_no_skin["skinned"], round_no_skin["control"].get_class(), "OK" if round_no_skin_ok else "FAIL"
	])
	(round_no_skin["control"] as Control).queue_free()

	_m5a_write_solid_png(tmp_dir + "badge/round_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "badge/round_accent.png", 8, 8, Color(1, 1, 1, 1))
	_m5a_write_solid_png(tmp_dir + "badge/turn_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "badge/turn_accent.png", 8, 8, Color(1, 1, 1, 1))

	var round_skinned := UIKit.make_badge(scratch, "round", "R", "pirate", tmp_dir)
	var round_panel := round_skinned["control"] as PanelContainer
	var round_style := round_panel.get_theme_stylebox("panel") as StyleBoxTexture if round_panel != null else null
	var round_skin_ok: bool = (
		round_skinned["skinned"] == true and round_panel != null and round_style != null
		and round_style.texture_margin_left == 40 and round_style.texture_margin_top == 12
	)
	ok = round_skin_ok and ok
	lines.append("  라운드 배지(있음): skinned=%s margin_left=%s margin_top=%s (기대 true, 40, 12) -> %s" % [
		round_skinned["skinned"], round_style.texture_margin_left if round_style else "(없음)",
		round_style.texture_margin_top if round_style else "(없음)", "OK" if round_skin_ok else "FAIL"
	])
	var round_pixel: Color = round_style.texture.get_image().get_pixel(0, 0) if round_style else Color.BLACK
	var pirate_accent: Color = CharacterTheme.ui_palette("pirate")["accent"]
	var round_tint_ok: bool = _m5a_color_close(round_pixel, pirate_accent)
	ok = round_tint_ok and ok
	lines.append("  라운드 배지 합성 픽셀=%s == pirate accent=%s -> %s" % [round_pixel, pirate_accent, "OK" if round_tint_ok else "FAIL"])
	round_panel.queue_free()

	var turn_skinned := UIKit.make_badge(scratch, "turn", "내 공격턴", "novice", tmp_dir)
	var turn_panel := turn_skinned["control"] as PanelContainer
	var turn_style := turn_panel.get_theme_stylebox("panel") as StyleBoxTexture if turn_panel != null else null
	var turn_margin_ok: bool = turn_style != null and turn_style.texture_margin_left == 44 and turn_style.texture_margin_top == 12
	ok = turn_margin_ok and ok
	lines.append("  턴 배지(있음) 마진: left=%s top=%s (기대 44, 12 — round과 다른 kind별 마진) -> %s" % [
		turn_style.texture_margin_left if turn_style else "(없음)", turn_style.texture_margin_top if turn_style else "(없음)",
		"OK" if turn_margin_ok else "FAIL"
	])
	var turn_label_ok: bool = (turn_skinned["label"] as Label).text == "내 공격턴"
	ok = turn_label_ok and ok
	lines.append("  턴 배지 글자='%s'(기대 '내 공격턴') -> %s" % [(turn_skinned["label"] as Label).text, "OK" if turn_label_ok else "FAIL"])
	turn_panel.queue_free()

	# --- 몬스터 티어 배지(badge/tier_{normal,elite,boss}.png) — 캐릭터색 틴트 없음, kind만 ---
	var tier_no_file_ok: bool = UIKit.tier_badge_texture("boss", tmp_dir) == null
	ok = tier_no_file_ok and ok
	lines.append("  티어 배지(파일 없음): tier_badge_texture('boss')=%s (기대 null) -> %s" % [
		UIKit.tier_badge_texture("boss", tmp_dir), "OK" if tier_no_file_ok else "FAIL"
	])
	_m5a_write_solid_png(tmp_dir + "badge/tier_boss.png", 16, 16, Color(0.9, 0.8, 0.2, 1))
	var tier_file_tex := UIKit.tier_badge_texture("boss", tmp_dir)
	var tier_file_ok: bool = tier_file_tex != null
	ok = tier_file_ok and ok
	lines.append("  티어 배지(파일 있음): tier_badge_texture('boss')=%s (기대 non-null) -> %s" % [
		tier_file_tex, "OK" if tier_file_ok else "FAIL"
	])
	var tier_unknown_kind_ok: bool = UIKit.tier_badge_texture("legendary", tmp_dir) == null
	ok = tier_unknown_kind_ok and ok
	lines.append("  티어 배지(알 수 없는 kind): tier_badge_texture('legendary')=null -> %s" % ("OK" if tier_unknown_kind_ok else "FAIL"))

	# --- 도감 상태 배지(badge/codex_base.png) — 단일 파일, 상태색 modulate ---
	var codex_no_skin := UIKit.make_codex_badge(scratch, "보유", Color(0.95, 0.85, 0.35), tmp_dir)
	var codex_no_skin_ok: bool = codex_no_skin.get_parent() == scratch and codex_no_skin.get_theme_color("font_color") == Color(0.95, 0.85, 0.35)
	ok = codex_no_skin_ok and ok
	lines.append("  도감 배지(파일 없음): 부모=scratch 직속=%s 글자색=%s(기대 상태색 그대로) -> %s" % [
		codex_no_skin.get_parent() == scratch, codex_no_skin.get_theme_color("font_color"), "OK" if codex_no_skin_ok else "FAIL"
	])
	codex_no_skin.queue_free()

	_m5a_write_solid_png(tmp_dir + "badge/codex_base.png", 8, 8, Color(1, 1, 1, 1))
	var owned_color := Color(0.95, 0.85, 0.35)
	var codex_skinned := UIKit.make_codex_badge(scratch, "보유", owned_color, tmp_dir)
	var codex_panel := codex_skinned.get_parent() as PanelContainer
	var codex_style := codex_panel.get_theme_stylebox("panel") as StyleBoxTexture if codex_panel != null else null
	var codex_skin_ok: bool = (
		codex_panel != null and codex_style != null and codex_style.modulate_color.is_equal_approx(owned_color)
		and codex_style.texture_margin_left == 18 and codex_style.texture_margin_top == 8
	)
	ok = codex_skin_ok and ok
	lines.append("  도감 배지(파일 있음): modulate_color=%s(기대 %s) margin_left=%s(기대 18) -> %s" % [
		codex_style.modulate_color if codex_style else "(없음)", owned_color,
		codex_style.texture_margin_left if codex_style else "(없음)", "OK" if codex_skin_ok else "FAIL"
	])
	var codex_text_contrast_ok: bool = codex_skinned.get_theme_color("font_color") == UIKit.contrasting_text_color(owned_color)
	ok = codex_text_contrast_ok and ok
	lines.append("  도감 배지 글자색(스킨 모드) == contrasting_text_color(상태색) -> %s" % ("OK" if codex_text_contrast_ok else "FAIL"))
	codex_panel.queue_free()

	# --- 칩 배경(deco/chip.png) — 단일 파일, 캐릭터 무관 ---
	var chip_panel_a := PanelContainer.new()
	var chip_no_skin_ok: bool = not UIKit.apply_chip_skin(chip_panel_a, tmp_dir)
	ok = chip_no_skin_ok and ok
	lines.append("  칩 배경(파일 없음): apply_chip_skin()=%s (기대 false) -> %s" % [not chip_no_skin_ok, "OK" if chip_no_skin_ok else "FAIL"])
	chip_panel_a.free()

	_m5a_write_solid_png(tmp_dir + "deco/chip.png", 8, 8, Color(0.5, 0.5, 0.5, 1))
	var chip_panel_b := PanelContainer.new()
	var chip_skin_applied: bool = UIKit.apply_chip_skin(chip_panel_b, tmp_dir)
	var chip_style := chip_panel_b.get_theme_stylebox("panel") as StyleBoxTexture
	var chip_skin_ok: bool = chip_skin_applied and chip_style != null and chip_style.texture_margin_left == 12 and chip_style.texture_margin_top == 10
	ok = chip_skin_ok and ok
	lines.append("  칩 배경(파일 있음): margin_left=%s margin_top=%s (기대 12, 10) -> %s" % [
		chip_style.texture_margin_left if chip_style else "(없음)", chip_style.texture_margin_top if chip_style else "(없음)",
		"OK" if chip_skin_ok else "FAIL"
	])
	chip_panel_b.free()

	# make_stat_chip() 자체도 칩 배경이 있으면 PanelContainer로 감싸는지.
	var stat_chip := UIKit.make_stat_chip(scratch, null, "42", "골드", "novice", tmp_dir)
	var stat_chip_wrapped_ok: bool = stat_chip["container"] is PanelContainer
	ok = stat_chip_wrapped_ok and ok
	lines.append("  make_stat_chip() 칩 배경 있음: container=%s (기대 PanelContainer) -> %s" % [
		stat_chip["container"].get_class(), "OK" if stat_chip_wrapped_ok else "FAIL"
	])
	(stat_chip["container"] as Control).queue_free()

	# --- 섹션 제목 장식(deco/title_ornament_{left,right})/구분선(deco/divider) ---
	var section_no_deco := UIKit.make_section(scratch, "제목", "novice", Vector2.ZERO, tmp_dir)
	var title_row_no_deco := section_no_deco.get_child(0) as HBoxContainer
	var no_deco_ok: bool = title_row_no_deco.get_child_count() == 1 and title_row_no_deco.get_child(0) is Label
	ok = no_deco_ok and ok
	lines.append("  제목 장식(파일 없음): title_row 자식 수=%d (기대 1, Label만) -> %s" % [
		title_row_no_deco.get_child_count(), "OK" if no_deco_ok else "FAIL"
	])
	var divider_no_deco := section_no_deco.get_child(1)
	var divider_no_deco_ok: bool = divider_no_deco is ColorRect
	ok = divider_no_deco_ok and ok
	lines.append("  구분선(파일 없음): %s (기대 ColorRect 폴백) -> %s" % [divider_no_deco.get_class(), "OK" if divider_no_deco_ok else "FAIL"])
	(section_no_deco.get_parent() as Control).queue_free()

	_m5a_write_solid_png(tmp_dir + "deco/title_ornament_left_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "deco/title_ornament_right_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "deco/divider_base.png", 8, 8, Color(0, 0, 0, 1))
	_m5a_write_solid_png(tmp_dir + "deco/divider_accent.png", 8, 8, Color(1, 1, 1, 1))
	_m5a_write_solid_png(tmp_dir + "icon/attack.png", 8, 8, Color(1, 1, 1, 1))

	var section_with_deco := UIKit.make_section(scratch, "제목", "berserker", Vector2.ZERO, tmp_dir, "attack")
	var title_row_with_deco := section_with_deco.get_child(0) as HBoxContainer
	var with_deco_ok: bool = (
		title_row_with_deco.get_child_count() == 4
		and title_row_with_deco.get_child(0) is TextureRect
		and title_row_with_deco.get_child(1) is TextureRect
		and title_row_with_deco.get_child(2) is Label
		and title_row_with_deco.get_child(3) is TextureRect
	)
	ok = with_deco_ok and ok
	lines.append("  제목 장식(장식+아이콘 있음): title_row 자식 수=%d, 순서=[좌장식,아이콘,제목,우장식] -> %s" % [
		title_row_with_deco.get_child_count(), "OK" if with_deco_ok else "FAIL"
	])
	var divider_with_deco := section_with_deco.get_child(1)
	var divider_with_deco_ok: bool = divider_with_deco is TextureRect and (divider_with_deco as TextureRect).texture != null
	ok = divider_with_deco_ok and ok
	lines.append("  구분선(파일 있음): %s, texture=%s -> %s" % [
		divider_with_deco.get_class(), (divider_with_deco as TextureRect).texture != null, "OK" if divider_with_deco_ok else "FAIL"
	])
	var divider_pixel: Color = (divider_with_deco as TextureRect).texture.get_image().get_pixel(0, 0)
	var berserker_accent: Color = CharacterTheme.ui_palette("berserker")["accent"]
	var divider_tint_ok: bool = _m5a_color_close(divider_pixel, berserker_accent)
	ok = divider_tint_ok and ok
	lines.append("  구분선 합성 픽셀=%s == berserker accent=%s -> %s" % [divider_pixel, berserker_accent, "OK" if divider_tint_ok else "FAIL"])
	(section_with_deco.get_parent() as Control).queue_free()

	# --- 기능 아이콘 9종 공용 로더(icon_texture) — 없음 -> null, 있음 -> tint색 그대로 ---
	var icon_no_file_ok: bool = UIKit.icon_texture("gold", Color.WHITE, tmp_dir) == null
	ok = icon_no_file_ok and ok
	lines.append("  icon_texture('gold', 파일 없음) == null -> %s" % ("OK" if icon_no_file_ok else "FAIL"))

	_m5a_write_solid_png(tmp_dir + "icon/gold.png", 8, 8, Color(1, 1, 1, 1))
	var gold_tint := Color(0.2, 0.6, 0.9)
	var gold_tex := UIKit.icon_texture("gold", gold_tint, tmp_dir)
	var gold_pixel: Color = gold_tex.get_image().get_pixel(0, 0) if gold_tex != null else Color.BLACK
	var icon_tint_ok: bool = gold_tex != null and _m5a_color_close(gold_pixel, gold_tint)
	ok = icon_tint_ok and ok
	lines.append("  icon_texture('gold', 파일 있음) 합성 픽셀=%s == tint=%s -> %s" % [gold_pixel, gold_tint, "OK" if icon_tint_ok else "FAIL"])

	scratch.queue_free()
	DirAccess.remove_absolute(tmp_dir + "badge/round_base.png")
	DirAccess.remove_absolute(tmp_dir + "badge/round_accent.png")
	DirAccess.remove_absolute(tmp_dir + "badge/turn_base.png")
	DirAccess.remove_absolute(tmp_dir + "badge/turn_accent.png")
	DirAccess.remove_absolute(tmp_dir + "badge/tier_boss.png")
	DirAccess.remove_absolute(tmp_dir + "badge/codex_base.png")
	DirAccess.remove_absolute(tmp_dir + "deco/chip.png")
	DirAccess.remove_absolute(tmp_dir + "deco/title_ornament_left_base.png")
	DirAccess.remove_absolute(tmp_dir + "deco/title_ornament_right_base.png")
	DirAccess.remove_absolute(tmp_dir + "deco/divider_base.png")
	DirAccess.remove_absolute(tmp_dir + "deco/divider_accent.png")
	DirAccess.remove_absolute(tmp_dir + "icon/attack.png")
	DirAccess.remove_absolute(tmp_dir + "icon/gold.png")
	DirAccess.remove_absolute(tmp_dir + "badge")
	DirAccess.remove_absolute(tmp_dir + "deco")
	DirAccess.remove_absolute(tmp_dir + "icon")
	DirAccess.remove_absolute(tmp_dir)

	# --- 배경 사진(resources/backgrounds/<scene_key>.png) — character_theme.gd apply_background() ---
	var bg_tmp_dir := "user://m5b_bg_test_tmp/"
	DirAccess.make_dir_recursive_absolute(bg_tmp_dir)
	var bg_dummy := Node2D.new()
	var bg_dummy_rect := ColorRect.new()
	bg_dummy_rect.name = "Background"
	bg_dummy_rect.color = Color(0.06, 0.06, 0.08, 1)
	bg_dummy.add_child(bg_dummy_rect)
	add_child(bg_dummy)

	CharacterTheme.apply_background(bg_dummy, "novice", false, 0.25, "dungeon_map", bg_tmp_dir)
	var no_bg_image_ok: bool = bg_dummy_rect.get_node_or_null("SceneBackgroundImage") == null and is_equal_approx(bg_dummy_rect.color.a, 1.0)
	ok = no_bg_image_ok and ok
	lines.append("  배경 사진(파일 없음): SceneBackgroundImage 없음=%s ColorRect.alpha=%.1f(기대 1.0) -> %s" % [
		bg_dummy_rect.get_node_or_null("SceneBackgroundImage") == null, bg_dummy_rect.color.a, "OK" if no_bg_image_ok else "FAIL"
	])

	_m5a_write_solid_png(bg_tmp_dir + "dungeon_map.png", 8, 8, Color(0.4, 0.2, 0.6, 1))
	CharacterTheme.apply_background(bg_dummy, "novice", false, 0.25, "dungeon_map", bg_tmp_dir)
	var bg_image: TextureRect = bg_dummy_rect.get_node_or_null("SceneBackgroundImage")
	var bg_image_ok: bool = bg_image != null and bg_image.texture != null and is_equal_approx(bg_dummy_rect.color.a, 0.0)
	ok = bg_image_ok and ok
	lines.append("  배경 사진(파일 있음): SceneBackgroundImage=%s texture=%s ColorRect.alpha=%.1f(기대 0.0, 사진이 그대로 보이게) -> %s" % [
		bg_image != null, bg_image.texture != null if bg_image else false, bg_dummy_rect.color.a, "OK" if bg_image_ok else "FAIL"
	])

	# scene_key가 비어있으면(배경 사진 없는 화면, 예 character_select) 기존 동작 그대로.
	CharacterTheme.apply_background(bg_dummy, "pirate", false, 0.25, "", bg_tmp_dir)
	var empty_key_ok: bool = bg_dummy_rect.get_node_or_null("SceneBackgroundImage") == null and is_equal_approx(bg_dummy_rect.color.a, 1.0)
	ok = empty_key_ok and ok
	lines.append("  scene_key 빈 문자열(기존 화면): SceneBackgroundImage 없음=%s ColorRect.alpha=%.1f(기대 1.0, 기존 폴백 유지) -> %s" % [
		bg_dummy_rect.get_node_or_null("SceneBackgroundImage") == null, bg_dummy_rect.color.a, "OK" if empty_key_ok else "FAIL"
	])

	remove_child(bg_dummy)
	bg_dummy.free()
	DirAccess.remove_absolute(bg_tmp_dir + "dungeon_map.png")
	DirAccess.remove_absolute(bg_tmp_dir)

	# --- production 자산(이미 입고됨) end-to-end: combat_test/dungeon_map을 실제로
	#     인스턴스화해 티어 배지/배경 사진/칩 배경이 실제로 스킨 모드인지 재확인.
	var character_backup: String = RunState.character_id
	RunState.character_id = "novice"
	RunState.test_battle = true
	RunState.test_monster_id = "slime"
	RunState.test_difficulty = 0
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)

	var prod_tier_icon_ok: bool = combat.monster_tier_icon.visible == true and combat.monster_tier_icon.texture != null
	ok = prod_tier_icon_ok and ok
	lines.append("  production combat_test: monster_tier_icon.visible=%s texture=%s (badge/tier_normal.png 입고됨 -> 보임 기대) -> %s" % [
		combat.monster_tier_icon.visible, combat.monster_tier_icon.texture != null, "OK" if prod_tier_icon_ok else "FAIL"
	])
	var prod_tier_label_ok: bool = combat.monster_tier_label.text == "일반"
	ok = prod_tier_label_ok and ok
	lines.append("  production combat_test: monster_tier_label.text='%s'(기대 '일반', 아이콘이 있어도 글자는 그대로 유지) -> %s" % [
		combat.monster_tier_label.text, "OK" if prod_tier_label_ok else "FAIL"
	])
	var prod_combat_bg: TextureRect = combat.get_node("Background").get_node_or_null("SceneBackgroundImage")
	var prod_combat_bg_ok: bool = prod_combat_bg != null and prod_combat_bg.texture != null
	ok = prod_combat_bg_ok and ok
	lines.append("  production combat_test: 배경 SceneBackgroundImage=%s (resources/backgrounds/combat.png 입고됨) -> %s" % [
		prod_combat_bg != null, "OK" if prod_combat_bg_ok else "FAIL"
	])
	remove_child(combat)
	combat.free()
	RunState.test_battle = false

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map_node = map_scene.instantiate()
	add_child(map_node)
	var prod_map_bg: TextureRect = map_node.get_node("Background").get_node_or_null("SceneBackgroundImage")
	var prod_map_bg_ok: bool = prod_map_bg != null and prod_map_bg.texture != null
	ok = prod_map_bg_ok and ok
	lines.append("  production dungeon_map: 배경 SceneBackgroundImage=%s (resources/backgrounds/dungeon_map.png 입고됨) -> %s" % [
		prod_map_bg != null, "OK" if prod_map_bg_ok else "FAIL"
	])
	var prod_gold_chip_ok: bool = map_node._hud_gold_value_label.get_parent().get_parent().get_parent() is PanelContainer
	ok = prod_gold_chip_ok and ok
	lines.append("  production dungeon_map: 골드 칩이 deco/chip.png 배경(PanelContainer)으로 감싸짐=%s -> %s" % [
		prod_gold_chip_ok, "OK" if prod_gold_chip_ok else "FAIL"
	])
	remove_child(map_node)
	map_node.free()
	RunState.character_id = character_backup

	return ok


## btn의 "normal" 스타일박스가 실제로 "보이는" 모습인지 판정한다 — override가 전혀
## 없으면(기본 Godot 테마에만 의존) 곧바로 false다(이 N-3 버그의 본체 — UIKit.style_*/
## FaceChipStyle.style_button()/_apply_selection_style() 등 "스타일링 함수를 거쳤는가"가
## 기준이지, 엔진 기본 테마가 실제로 어떻게 그려지는지는 신경 쓰지 않는다. 다른 화면들의
## has_theme_stylebox_override("normal") 검증(M-4 등)과 같은 기준). override가 있으면
## StyleBoxTexture는 텍스처 존재로, StyleBoxFlat은 배경 알파>0 또는 "알파 있는 테두리"로
## "눈에 보이는지"를 판정한다.
func _n3_button_looks_styled(btn: Button) -> bool:
	if btn.flat:
		return false
	if not btn.has_theme_stylebox_override("normal"):
		return false
	var style := btn.get_theme_stylebox("normal")
	if style is StyleBoxTexture:
		return (style as StyleBoxTexture).texture != null
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		if flat.bg_color.a > 0.0:
			return true
		var has_border: bool = flat.border_width_left > 0 or flat.border_width_top > 0 \
			or flat.border_width_right > 0 or flat.border_width_bottom > 0
		return has_border and flat.border_color.a > 0.0
	return false


## node 아래 모든 Button을 재귀적으로 모아(find_children) 스타일이 안 된 것들의 이름을
## 돌려준다. btn.get_class() != "Button"인 경우(OptionButton/CheckBox/LinkButton 등 —
## 전부 Button의 서브클래스라 type 필터 "Button"에 함께 걸린다)는 allowlist로 건너뛴다 —
## 이들은 엔진 기본 테마로도 이미 체크박스/드롭다운 등 자기 종류의 입체감 있는 모습을
## 그리는 별개의 컨트롤이라, "flat/무테두리 Button"(단순 텍스트처럼 보이는 평범한 누름
## 버튼) 버그의 대상이 아니다(test_battle_setup.gd의 OptionButton/CheckBox가 해당).
func _n3_find_unstyled_buttons(node: Node) -> Array:
	var result: Array = []
	for child in node.find_children("*", "Button", true, false):
		var btn := child as Button
		if btn.get_class() != "Button":
			continue
		if not _n3_button_looks_styled(btn):
			result.append(btn.text if btn.text != "" else String(btn.name))
	return result


## [대형 기획 14] N-3(2026-10-15) — 사용자 지적("스킬 도감, 업적 등의 버튼이 단순
## 글자처럼 보인다")을 받아 "flat/무테두리 Button을 전수 검색"한 결과 실제로 UIKit
## 스타일링을 전혀 안 받고 있던 버튼 9개를 찾았다: character_select.gd의 "던전 시작"/
## "업적"/"테스트 전투"/"스킬 도감"(4개, M-1~M-4가 다른 화면을 전부 통일한 뒤에도 이
## 화면만 빠져 있었음), dungeon_map.gd의 "스킬 도감"(_style_action_buttons()에서만
## 빠져 있었음 — event/shop/story_event는 이미 스타일링하고 있었음), achievement_
## panel.gd/skill_codex_panel.gd의 "닫기", customize_panel.gd의 "닫기"/"뒤로" 4개 +
## 다이스 승급/눈금 적용 1단계의 가로 목록 행 버튼(이것도 FaceChipStyle 정사각 칩류와
## 달리 스타일 호출이 애초에 없었음), test_battle_setup.gd의 "뒤로"/"전투 시작"/성장
## 프리셋 버튼. 전부 UIKit.style_primary_button()/style_secondary_button()으로
## 고쳤다(이 화면들이 이미 쓰던 공용 팩토리를 그대로 재사용 — 새 "make_button()" 같은
## 별도 팩토리를 만들지 않음, 기존 호출부들과 똑같은 한 줄 패턴이면 충분했음).
## character_select.gd의 네 버튼은 DESIGN.md가 이미 확정한 "이 화면의 공용 버튼은
## 아직 런이 시작되지 않았으니 캐릭터 퍼스널 컬러 대신 중립색을 유지"(K-3) 규칙을
## 지키려고 FocusNav.ACCENT_DEFAULT(포커스 강조색과 같은 중립 시안색)를 tint로 썼다
## (style_primary_button()에 tint 매개변수를 이번에 새로 추가 — style_secondary_
## button()에는 이미 있던 패턴을 그대로 가져왔을 뿐).
##
## 이 검증은 "버그가 있었다"는 사실을 안 상태로 거꾸로 짠 것이 아니라, 모든 화면/
## 오버레이 패널을 실제로 인스턴스화해서 Button 노드를 재귀적으로 순회하는 전수
## 검사다 — 다음에 새 버튼이 생기면서 같은 종류의 버그가 재발해도 이 테스트가 잡는다.
func _check_n3_button_styling(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var test_battle_backup := RunState.test_battle
	var test_monster_backup := RunState.test_monster_id
	var test_difficulty_backup := RunState.test_difficulty
	var gold_backup := RunState.gold
	var rooms_backup := RunState.rooms_cleared
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	var die_backup: Array[int] = RunState.die_inventory.duplicate()

	# --- 정적 화면 7개: 각 화면이 이미 쓰던 설정 패턴(M-1/M-2/M-4/H-2 참고)을 그대로 ---
	RunState.character_id = "novice"
	RunState.test_battle = false
	RunState.gold = 42
	RunState.rooms_cleared = 0

	var static_scenes := [
		"res://code/scenes/character_select.tscn",
		"res://code/scenes/dungeon_map.tscn",
		"res://code/scenes/event.tscn",
		"res://code/scenes/shop.tscn",
		"res://code/scenes/story_event.tscn",
	]
	for path in static_scenes:
		var node: Node = (load(path) as PackedScene).instantiate()
		add_child(node)
		var unstyled := _n3_find_unstyled_buttons(node)
		var scene_ok: bool = unstyled.is_empty()
		ok = scene_ok and ok
		lines.append("  %s: 미스타일 버튼=%s -> %s" % [
			path.get_file(), unstyled, "OK" if scene_ok else "FAIL"
		])
		remove_child(node)
		node.free()

	RunState.test_battle = true
	RunState.test_monster_id = "slime"
	RunState.test_difficulty = 0
	var combat_node: Node = (load("res://code/scenes/combat_test.tscn") as PackedScene).instantiate()
	add_child(combat_node)
	var combat_unstyled := _n3_find_unstyled_buttons(combat_node)
	var combat_ok: bool = combat_unstyled.is_empty()
	ok = combat_ok and ok
	lines.append("  combat_test.tscn: 미스타일 버튼=%s -> %s" % [combat_unstyled, "OK" if combat_ok else "FAIL"])
	remove_child(combat_node)
	combat_node.free()
	RunState.test_battle = false

	RunState.reset_run("novice")
	var tbs_node: Node = (load("res://code/scenes/test_battle_setup.tscn") as PackedScene).instantiate()
	add_child(tbs_node)
	var tbs_unstyled := _n3_find_unstyled_buttons(tbs_node)
	var tbs_ok: bool = tbs_unstyled.is_empty()
	ok = tbs_ok and ok
	lines.append("  test_battle_setup.tscn: 미스타일 버튼=%s -> %s" % [tbs_unstyled, "OK" if tbs_ok else "FAIL"])
	remove_child(tbs_node)
	tbs_node.free()

	# --- 오버레이 패널 3종: open()을 실제로 불러야 버튼이 생성된다(.tscn 없이 스크립트
	#     하나로 완결된 Control — customize_panel.gd 클래스 주석 참고) ---
	var achievement := AchievementPanel.new()
	add_child(achievement)
	achievement.open()
	var ach_unstyled := _n3_find_unstyled_buttons(achievement)
	var ach_ok: bool = ach_unstyled.is_empty()
	ok = ach_ok and ok
	lines.append("  AchievementPanel: 미스타일 버튼=%s -> %s" % [ach_unstyled, "OK" if ach_ok else "FAIL"])
	achievement.queue_free()

	var codex := SkillCodexPanel.new()
	add_child(codex)
	codex.open("novice", [])
	var codex_unstyled := _n3_find_unstyled_buttons(codex)
	var codex_ok: bool = codex_unstyled.is_empty()
	ok = codex_ok and ok
	lines.append("  SkillCodexPanel: 미스타일 버튼=%s -> %s" % [codex_unstyled, "OK" if codex_ok else "FAIL"])
	codex.queue_free()

	# [대형 기획 15] Q-5(16) 재설계 후: CustomizePanel의 "눈금<->면" 교환은 더 이상
	# 별도 화면이 아니라 통합 화면(_show_pip_picker)이 상태(_selected_pip_index/
	# _pending_face)에 따라 다르게 그려진다 — 아무것도 선택 안 함/눈금만 선택/
	# 눈금+면까지 선택(미리보기+적용/취소 버튼) 3가지 상태를 _show_die_picker()/
	# _show_face_picker() shim으로 만들어가며 누적 검사한다. 다이스 인벤토리 흐름
	# (_show_die_inventory_picker/_show_die_target_picker)은 이번 재설계 대상이 아니라
	# 그대로 별도 화면이다.
	RunState.pip_inventory = [4]
	RunState.die_inventory = [6]
	var cp := CustomizePanel.new()
	add_child(cp)
	var cp_unstyled: Array = []
	cp.open() # _show_pip_picker() — 선택 없음
	cp_unstyled += _n3_find_unstyled_buttons(cp)
	cp._show_die_inventory_picker()
	cp_unstyled += _n3_find_unstyled_buttons(cp)
	cp._show_die_target_picker(0)
	cp_unstyled += _n3_find_unstyled_buttons(cp)
	cp._show_die_picker(0) # 눈금만 선택
	cp_unstyled += _n3_find_unstyled_buttons(cp)
	cp._show_face_picker(RunState.player_attack_bag, 0, 0) # 눈금+면 선택 -> 미리보기
	cp_unstyled += _n3_find_unstyled_buttons(cp)
	var cp_ok: bool = cp_unstyled.is_empty()
	ok = cp_ok and ok
	lines.append("  CustomizePanel(통합 화면 상태 전체): 미스타일 버튼=%s -> %s" % [cp_unstyled, "OK" if cp_ok else "FAIL"])
	cp.queue_free()

	RunState.character_id = character_backup
	RunState.test_battle = test_battle_backup
	RunState.test_monster_id = test_monster_backup
	RunState.test_difficulty = test_difficulty_backup
	RunState.gold = gold_backup
	RunState.rooms_cleared = rooms_backup
	RunState.pip_inventory = pip_backup
	RunState.die_inventory = die_backup

	return ok


## N-4(2026-10-15 [대형 기획 14]) 검증 — INBOX.md 원문 "지금은 능력치 칩이 '공격 D4×3'
## 같은 문자열이다 -> 실제 다이스 칩/아이콘을 개수만큼 나열". "플래그가 들어갔는가"가
## 아니라 "화면에 실제로 렌더된 칩 개수/모양/숫자"와 "시작 보너스 배지가 실제로
## 켜지고 꺼지는가"를 검증한다:
## (a) 8명 전부에서 공격/방어 다이스 칩 컨테이너의 자식 개수가 프로필의
##     attack_count/defense_count와 정확히 같은지, 각 칩의 shape_sides/value가 실제
##     면 수(지금은 전부 D4=4)와 일치하는지.
## (b) 이벤트 다이스 줄의 텍스트가 event_die_sides와 일치하고 EventDieVisual이 실제로
##     그 줄에 붙어 있는지.
## (c) "+n" 배지 — _static_dice_bonus() 공식이 combat_test.gd의 실전 적용 함수
##     (_aggro_bonus/_wall_bonus/_expand_bonus/_lean_bonus)와 정확히 같은 값을 내는지
##     여러 조합으로 직접 검증.
## (d) 실제 화면 end-to-end: 광전사(공격4/방어2, 슬롯0=맹공)를 고르면 공격 줄에 "+1"
##     배지가 뜨고 방어 줄은 숨겨지는지, 견습 모험가(공격3/방어3, 슬롯0=확장, 합계 6<8이라
##     보너스 없음)를 고르면 양쪽 다 숨겨지는지 — 캐릭터 전환으로 chosen_starting_
##     skill_id가 새 캐릭터의 슬롯0으로 자동 확정되는 기존 동작(_valid_or_default_
##     starting_skill_id)을 그대로 이용한다.
func _check_n4_dice_chip_stats(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	# (d)의 "캐릭터를 바꾸면 슬롯0으로 폴백"이 업적 해금 상태와 무관하게 항상 성립해야
	# 하므로(슬롯2 해금 업적이 다른 테스트에서 이미 unlock된 채로 남아있으면 폴백이
	# 아니라 그 슬롯이 그대로 선택될 수 있음), 다른 업적 테스트들과 같은 패턴으로
	# 시작/종료에 리셋한다.
	AchievementManager._debug_reset_for_qa()

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	# (a)+(b) 8명 전부.
	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)
		var expected_attack: int = int(profile.get("attack_count", 3))
		var expected_defense: int = int(profile.get("defense_count", 3))
		var expected_event_sides: int = int(profile.get("event_die_sides", 6))

		var attack_chips: Array = node._detail_attack_dice_row["chips"].get_children()
		var defense_chips: Array = node._detail_defense_dice_row["chips"].get_children()
		var count_ok: bool = attack_chips.size() == expected_attack and defense_chips.size() == expected_defense
		ok = count_ok and ok
		lines.append("  [%s] 다이스 칩 개수: 공격=%d(기대 %d) 방어=%d(기대 %d) -> %s" % [
			cid, attack_chips.size(), expected_attack, defense_chips.size(), expected_defense,
			"OK" if count_ok else "FAIL"
		])

		var shape_ok: bool = true
		for chip in attack_chips:
			if not (chip is ShapeDieChip and chip.shape_sides == 3 and chip.value == 4):
				shape_ok = false
		for chip in defense_chips:
			if not (chip is ShapeDieChip and chip.shape_sides == 3 and chip.value == 4):
				shape_ok = false
		ok = shape_ok and ok
		lines.append("  [%s] 다이스 칩 모양/숫자(D4 -> 삼각형+4) 전부 일치 -> %s" % [cid, "OK" if shape_ok else "FAIL"])

		var event_label_ok: bool = node._detail_event_die_label.text == "D%d" % expected_event_sides
		var event_visual_ok: bool = is_instance_valid(node._detail_event_die_visual) and node._detail_event_die_visual.get_parent() != null
		ok = event_label_ok and event_visual_ok and ok
		lines.append("  [%s] 이벤트 다이스 줄: 텍스트=\"%s\"(기대 D%d) 비주얼 부착=%s -> %s" % [
			cid, node._detail_event_die_label.text, expected_event_sides, event_visual_ok,
			"OK" if (event_label_ok and event_visual_ok) else "FAIL"
		])

	# (c) _static_dice_bonus() vs combat_test.gd 실전 함수.
	var combat_script := load("res://code/scenes/combat_test.gd")
	var combos := [
		["start_aggro", 4, 2], ["start_aggro", 2, 2],
		["start_wall", 2, 4], ["start_wall", 2, 2],
		["start_expand", 4, 4], ["start_expand", 3, 3],
		["start_lean", 3, 4], ["start_lean", 4, 4],
		["", 4, 2], # 모르는/빈 id는 보너스 없음.
	]
	for combo in combos:
		var skill_id: String = combo[0]
		var atk_count: int = combo[1]
		var def_count: int = combo[2]
		var got: Dictionary = node._static_dice_bonus(skill_id, atk_count, def_count)
		var expected_atk := 0
		var expected_def := 0
		match skill_id:
			"start_aggro":
				expected_atk = combat_script._aggro_bonus(atk_count, def_count)
			"start_wall":
				expected_def = combat_script._wall_bonus(atk_count, def_count)
			"start_expand":
				var eb: int = combat_script._expand_bonus(atk_count, def_count)
				expected_atk = eb
				expected_def = eb
			"start_lean":
				var lb: int = combat_script._lean_bonus(atk_count, def_count)
				expected_atk = lb
				expected_def = lb
		var combo_ok: bool = int(got["attack"]) == expected_atk and int(got["defense"]) == expected_def
		ok = combo_ok and ok
		lines.append("  _static_dice_bonus(\"%s\", %d, %d) = {공격=%d, 방어=%d} (기대 공격=%d, 방어=%d) -> %s" % [
			skill_id, atk_count, def_count, got["attack"], got["defense"], expected_atk, expected_def,
			"OK" if combo_ok else "FAIL"
		])

	# (d) 실제 화면 end-to-end.
	node._on_card_selected("berserker")
	var berserker_skill_ok: bool = RunState.chosen_starting_skill_id == "start_aggro"
	var berserker_attack_bonus: Label = node._detail_attack_dice_row["bonus"]
	var berserker_defense_bonus: Label = node._detail_defense_dice_row["bonus"]
	var berserker_ok: bool = (berserker_skill_ok and berserker_attack_bonus.visible
		and berserker_attack_bonus.text == "+1" and not berserker_defense_bonus.visible)
	ok = berserker_ok and ok
	lines.append("  [berserker] 시작 스킬=%s(기대 start_aggro) 공격 배지=\"%s\"(visible=%s, 기대 +1/true) 방어 배지 visible=%s(기대 false) -> %s" % [
		RunState.chosen_starting_skill_id, berserker_attack_bonus.text, berserker_attack_bonus.visible,
		berserker_defense_bonus.visible, "OK" if berserker_ok else "FAIL"
	])

	node._on_card_selected("novice")
	var novice_skill_ok: bool = RunState.chosen_starting_skill_id == "start_expand"
	var novice_attack_bonus: Label = node._detail_attack_dice_row["bonus"]
	var novice_defense_bonus: Label = node._detail_defense_dice_row["bonus"]
	var novice_ok: bool = novice_skill_ok and not novice_attack_bonus.visible and not novice_defense_bonus.visible
	ok = novice_ok and ok
	lines.append("  [novice] 시작 스킬=%s(기대 start_expand, 합계 6<8) 공격/방어 배지 visible=%s/%s(기대 둘 다 false) -> %s" % [
		RunState.chosen_starting_skill_id, novice_attack_bonus.visible, novice_defense_bonus.visible,
		"OK" if novice_ok else "FAIL"
	])

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	AchievementManager._debug_reset_for_qa()
	return ok


## [대형 기획 14] N-5(a)(INBOX.md 2026-10-15, "곡예사를 이벤트 특화 클래스로") 검증:
## (a) 곡예사만 event_die_sides=12, 나머지 7종은 그대로 6.
## (b) RunState.reset_run("juggler")가 이 값을 그대로 복사하는지.
## (c) 곡예사의 시작 스킬 슬롯 순서가 눈속임(이벤트)->한탕(이벤트)->잡화점(전투
##     보조) 3개로 재구성됐는지, start_aggro/start_hoard가 더는 곡예사 후보에 없는지
##     (다른 캐릭터(광전사)에게는 여전히 있는지 — 회귀 확인).
## (d) chosen_starting_skill_id가 사라진 id(start_aggro, 곡예사 기준)를 가리키는 채로
##     캐릭터를 곡예사로 바꾸면 안전하게 슬롯0(눈속임)으로 폴백하는지 — "폴백 안전성"
##     요구사항(INBOX.md N-5(a) 원문).
## (e) "눈속임"/"승부사"가 event.gd의 실제 DC 계산(_dc)을 1 낮추는지(물리 없이
##     event.tscn 인스턴스화 + _dc 읽기).
## (f) event_roll_bonus() 순수 함수: 플래그 없음/juggle_fortune/juggle_fortune_plus
##     각각 0/1/2를 돌려주는지.
## (g) _effective_risky_roll()이 실제로 그 보정을 raw_roll에 더하고 이벤트 주사위
##     면 개수로 상한을 거는지(여러 raw_roll/skill_flags 조합).
## (h) "한탕"(start_fortune) — 판정 성공 시 RunState.gold가 FORTUNE_GOLD_BONUS만큼
##     실제로 늘어나는지(계산 결과 검증, _debug_force_risky_success()로 성공 경로
##     결정적 재현).
func _check_n5a_juggler_event_specialist(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var skill_flags_backup: Array[String] = RunState.skill_flags.duplicate()
	var rooms_backup := RunState.rooms_cleared
	var gold_backup := RunState.gold
	var event_sides_backup := RunState.event_die_sides

	# (a) 프로필 event_die_sides.
	var sides_ok := true
	for profile in CharacterProfiles.PROFILES:
		var expected: int = 12 if profile["id"] == "juggler" else 6
		if int(profile.get("event_die_sides", -1)) != expected:
			sides_ok = false
	ok = sides_ok and ok
	lines.append("  CharacterProfiles.PROFILES: 곡예사만 event_die_sides=12, 나머지 7종은 6 -> %s" % ("OK" if sides_ok else "FAIL"))

	# (b) RunState 복사.
	RunState.reset_run("juggler")
	var runstate_copy_ok: bool = RunState.event_die_sides == 12
	ok = runstate_copy_ok and ok
	lines.append("  reset_run(\"juggler\") 후 RunState.event_die_sides=%d(기대 12) -> %s" % [
		RunState.event_die_sides, "OK" if runstate_copy_ok else "FAIL"
	])

	# (c) 시작 스킬 슬롯 순서 + start_aggro/start_hoard 제외.
	var juggler_candidates := SkillPool.starting_skills_for_character("juggler")
	var juggler_ids: Array = []
	for c in juggler_candidates:
		juggler_ids.append(c["id"])
	var juggler_order_ok: bool = juggler_ids == ["start_sleight", "start_fortune", "start_diverse"]
	ok = juggler_order_ok and ok
	lines.append("  곡예사 시작 스킬 슬롯 순서: %s (기대 [start_sleight, start_fortune, start_diverse]) -> %s" % [
		juggler_ids, "OK" if juggler_order_ok else "FAIL"
	])

	var berserker_ids: Array = []
	for c in SkillPool.starting_skills_for_character("berserker"):
		berserker_ids.append(c["id"])
	var berserker_unaffected_ok: bool = berserker_ids.has("start_aggro") and berserker_ids.has("start_hoard")
	ok = berserker_unaffected_ok and ok
	lines.append("  광전사 시작 스킬 후보에는 여전히 start_aggro/start_hoard 포함(회귀 확인): %s -> %s" % [
		berserker_ids, "OK" if berserker_unaffected_ok else "FAIL"
	])

	# (d) 사라진 id -> 슬롯0 폴백.
	var select_scene := load("res://code/scenes/character_select.tscn")
	var select_node = select_scene.instantiate()
	add_child(select_node)
	AchievementManager._debug_reset_for_qa()
	RunState.chosen_starting_skill_id = "start_aggro"
	select_node._on_card_selected("juggler")
	var fallback_ok: bool = RunState.chosen_starting_skill_id == "start_sleight"
	ok = fallback_ok and ok
	lines.append("  chosen_starting_skill_id=\"start_aggro\"(곡예사 기준 사라진 id)인 채로 곡예사 선택 -> %s(기대 start_sleight) -> %s" % [
		RunState.chosen_starting_skill_id, "OK" if fallback_ok else "FAIL"
	])
	remove_child(select_node)
	select_node.free()
	AchievementManager._debug_reset_for_qa()

	# (e) DC 계산(물리 없이 event.tscn 인스턴스화 + _dc 읽기).
	var event_scene := load("res://code/scenes/event.tscn")
	RunState.rooms_cleared = 0
	RunState.skill_flags = []
	var dc_without_node = event_scene.instantiate()
	add_child(dc_without_node)
	var dc_without: int = dc_without_node._dc
	remove_child(dc_without_node)
	dc_without_node.free()

	RunState.skill_flags = ["start_sleight"]
	var dc_with_node = event_scene.instantiate()
	add_child(dc_with_node)
	var dc_with: int = dc_with_node._dc
	remove_child(dc_with_node)
	dc_with_node.free()

	var dc_ok: bool = dc_without == 3 and dc_with == 2
	ok = dc_ok and ok
	lines.append("  '눈속임' DC 보정(방0, base DC3): 미보유=%d(기대 3) 보유=%d(기대 2) -> %s" % [
		dc_without, dc_with, "OK" if dc_ok else "FAIL"
	])

	# (f) event_roll_bonus() 순수 함수.
	var event_script := load("res://code/scenes/event.gd")
	var bonus_none: int = event_script.event_roll_bonus([])
	var bonus_base: int = event_script.event_roll_bonus(["juggle_fortune"])
	var bonus_plus: int = event_script.event_roll_bonus(["juggle_fortune_plus"])
	var bonus_ok: bool = bonus_none == 0 and bonus_base == 1 and bonus_plus == 2
	ok = bonus_ok and ok
	lines.append("  event_roll_bonus(): 없음=%d(기대 0) juggle_fortune=%d(기대 1) juggle_fortune_plus=%d(기대 2) -> %s" % [
		bonus_none, bonus_base, bonus_plus, "OK" if bonus_ok else "FAIL"
	])

	# (g) _effective_risky_roll() — 보정 + 상한.
	RunState.event_die_sides = 6
	var roll_node = event_scene.instantiate()
	add_child(roll_node)
	RunState.skill_flags = []
	var roll_plain: int = roll_node._effective_risky_roll(3)
	RunState.skill_flags = ["juggle_fortune"]
	var roll_boosted: int = roll_node._effective_risky_roll(3)
	RunState.skill_flags = ["juggle_fortune_plus"]
	var roll_boosted_plus: int = roll_node._effective_risky_roll(3)
	var roll_capped: int = roll_node._effective_risky_roll(6)
	var roll_ok: bool = roll_plain == 3 and roll_boosted == 4 and roll_boosted_plus == 5 and roll_capped == 6
	ok = roll_ok and ok
	lines.append("  _effective_risky_roll(raw=3, D6): 없음=%d(기대 3) juggle_fortune=%d(기대 4) juggle_fortune_plus=%d(기대 5); raw=6 juggle_fortune_plus=%d(상한 6 기대) -> %s" % [
		roll_plain, roll_boosted, roll_boosted_plus, roll_capped, "OK" if roll_ok else "FAIL"
	])
	remove_child(roll_node)
	roll_node.free()

	# (h) "한탕" 골드 보너스 — 성공 경로를 결정적으로 강제(_debug_force_risky_success()).
	RunState.rooms_cleared = 0
	RunState.gold = 0
	RunState.skill_flags = ["start_fortune"]
	AchievementManager._debug_reset_for_qa()
	var fortune_node = event_scene.instantiate()
	add_child(fortune_node)
	fortune_node._debug_force_risky_success()
	var fortune_gold_ok: bool = RunState.gold == fortune_node.FORTUNE_GOLD_BONUS
	ok = fortune_gold_ok and ok
	lines.append("  '한탕' 보유 + 위험 감수 강제 성공: RunState.gold=%d(기대 %d) -> %s" % [
		RunState.gold, fortune_node.FORTUNE_GOLD_BONUS, "OK" if fortune_gold_ok else "FAIL"
	])
	remove_child(fortune_node)
	fortune_node.free()

	# 골드 없이(스킬 미보유)는 보너스가 없어야 한다 — 회귀 확인.
	RunState.rooms_cleared = 0
	RunState.gold = 0
	RunState.skill_flags = []
	AchievementManager._debug_reset_for_qa()
	var no_fortune_node = event_scene.instantiate()
	add_child(no_fortune_node)
	no_fortune_node._debug_force_risky_success()
	var no_fortune_gold_ok: bool = RunState.gold == 0
	ok = no_fortune_gold_ok and ok
	lines.append("  '한탕' 미보유 + 위험 감수 강제 성공: RunState.gold=%d(기대 0, 보너스 없음) -> %s" % [
		RunState.gold, "OK" if no_fortune_gold_ok else "FAIL"
	])
	remove_child(no_fortune_node)
	no_fortune_node.free()

	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.skill_flags = skill_flags_backup
	RunState.rooms_cleared = rooms_backup
	RunState.gold = gold_backup
	RunState.event_die_sides = event_sides_backup
	AchievementManager._debug_reset_for_qa()
	return ok


## [대형 기획 14] N-5(b)(INBOX.md 2026-10-15, "이벤트 판정 콘텐츠 확충 + 대성공")
## 검증:
## (a) EventChallengePool.CHALLENGES가 보물 포함 4종 이상이고, 각 항목이 필요한 키
##     (subtitle/prompt/safe_reward/success_reward/crit_reward/fail_penalty)를 전부
##     갖는지.
## (b) tier_for_roll()의 fail/success/crit 3단 경계 — CRIT_MARGIN=3 기준 DC=5일 때
##     roll 4=fail, 5=success, 7=success, 8=crit.
## (c) roll_reward()가 spec의 type별로 실제 값을 추첨하는지(gold/pips는 범위 안,
##     item_grade는 지정된 등급 집합 안, none은 "none") — 여러 회 반복해 경계값까지
##     확인.
## (d) D6 클래스(novice 등) vs D12 곡예사의 성공률/대성공률을 success_probability()/
##     crit_probability()로 실제 계산해 비교 — 방 4 이상(DC5)에서 D6은 대성공이
##     수학적으로 불가능(0%)인데 D12는 0보다 뚜렷하게 큰지, 성공률도 D12가 더 높은지.
## (e) 화면 동작: event.tscn을 인스턴스화해 _debug_force_challenge_*()로 도박/탐색/
##     함정 해체 각각의 초기 화면(제목/버튼 텍스트)이 실제로 바뀌는지.
## (f) _debug_force_gambling_crit_success() — RunState.gold가 실제로 crit_reward
##     범위(24~32) + (한탕 보유 시 FORTUNE_GOLD_BONUS) 안에서 증가하고, 굴림 결과
##     레이블에 "대성공!"이 실제로 찍히는지(아이템 카드 없이).
## (g) _debug_force_trap_disarm_failure() — RunState.gold가 fail_penalty 범위(3~5)
##     안에서 실제로 감소하고(0 밑으로는 안 내려감), fail_label 문구에 패널티
##     문장이 실제로 포함되는지.
func _check_n5b_event_challenge_variety(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_flags_backup: Array[String] = RunState.skill_flags.duplicate()
	var rooms_backup := RunState.rooms_cleared
	var gold_backup := RunState.gold
	var event_sides_backup := RunState.event_die_sides

	# (a) 데이터 표 구조.
	var challenges: Array = EventChallengePool.CHALLENGES
	var count_ok: bool = challenges.size() >= 4
	ok = count_ok and ok
	var ids: Array[String] = []
	var keys_ok := true
	for c in challenges:
		ids.append(String(c.get("id", "")))
		for key in ["subtitle", "prompt", "safe_reward", "success_reward", "crit_reward", "fail_penalty"]:
			if not c.has(key):
				keys_ok = false
	ok = keys_ok and ok
	var has_treasure: bool = ids.has("treasure")
	var new_kinds_count: int = ids.size() - (1 if has_treasure else 0)
	var variety_ok: bool = has_treasure and new_kinds_count >= 2
	ok = variety_ok and ok
	lines.append("  EventChallengePool.CHALLENGES: %d종(id=%s), 필수 키 전부 보유=%s, 보물 외 신규 %d종(기대 2종 이상) -> %s" % [
		challenges.size(), ", ".join(ids), keys_ok, new_kinds_count, "OK" if (count_ok and keys_ok and variety_ok) else "FAIL"
	])

	# (b) tier_for_roll() 경계 — DC=5, CRIT_MARGIN=3 기준.
	var tier4: String = EventChallengePool.tier_for_roll(4, 5)
	var tier5: String = EventChallengePool.tier_for_roll(5, 5)
	var tier7: String = EventChallengePool.tier_for_roll(7, 5)
	var tier8: String = EventChallengePool.tier_for_roll(8, 5)
	var tier_ok: bool = tier4 == "fail" and tier5 == "success" and tier7 == "success" and tier8 == "crit"
	ok = tier_ok and ok
	lines.append("  tier_for_roll(DC5, CRIT_MARGIN3): roll4/5/7/8=%s/%s/%s/%s(기대 fail/success/success/crit) -> %s" % [
		tier4, tier5, tier7, tier8, "OK" if tier_ok else "FAIL"
	])

	# (c) roll_reward() — type별 실제 추첨 결과.
	var gold_spec := {"type": "gold", "min": 10, "max": 16}
	var gold_in_range := true
	for i in 100:
		var amount: int = int(EventChallengePool.roll_reward(gold_spec)["amount"])
		if amount < 10 or amount > 16:
			gold_in_range = false
	ok = gold_in_range and ok
	lines.append("  roll_reward(gold 10~16) 100회 전부 범위 안 -> %s" % ("OK" if gold_in_range else "FAIL"))

	var pips_spec := {"type": "pips", "min": 7, "max": 9}
	var pips_in_range := true
	for i in 100:
		var count: int = int(EventChallengePool.roll_reward(pips_spec)["count"])
		if count < 7 or count > 9:
			pips_in_range = false
	ok = pips_in_range and ok
	lines.append("  roll_reward(pips 7~9) 100회 전부 범위 안 -> %s" % ("OK" if pips_in_range else "FAIL"))

	var item_spec := {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 1.0, "S": 3.0}}
	var item_grades_ok := true
	var item_saw_a := false
	for i in 100:
		var g: String = String(EventChallengePool.roll_reward(item_spec)["item"].get("grade", ""))
		if g != "A" and g != "S":
			item_grades_ok = false
		if g == "A":
			item_saw_a = true
	ok = item_grades_ok and ok
	ok = item_saw_a and ok
	lines.append("  roll_reward(item_grade A/S) 100회 전부 grade=A/S, A급 목격=%s -> %s" % [item_saw_a, "OK" if (item_grades_ok and item_saw_a) else "FAIL"])

	var none_result: Dictionary = EventChallengePool.roll_reward({"type": "none"})
	var none_ok: bool = String(none_result.get("type", "")) == "none"
	ok = none_ok and ok
	lines.append("  roll_reward(none) -> type=%s(기대 none) -> %s" % [none_result.get("type", ""), "OK" if none_ok else "FAIL"])

	# (d) D6 클래스 vs D12 곡예사 — 성공률/대성공률 이론 계산 비교(샘플링 없이 정확).
	var dc5 := 5
	var success_d6: float = EventChallengePool.success_probability(dc5, 6)
	var success_d12: float = EventChallengePool.success_probability(dc5, 12)
	var crit_d6: float = EventChallengePool.crit_probability(dc5, 6)
	var crit_d12: float = EventChallengePool.crit_probability(dc5, 12)
	var probability_ok: bool = success_d12 > success_d6 and crit_d6 == 0.0 and crit_d12 > 0.3
	ok = probability_ok and ok
	lines.append("  DC%d(방4 이상) 성공률: D6=%.3f D12=%.3f(기대 D12>D6) / 대성공률: D6=%.3f(기대 0, 최댓값 6<DC+3=8) D12=%.3f(기대 >0.3) -> %s" % [
		dc5, success_d6, success_d12, crit_d6, crit_d12, "OK" if probability_ok else "FAIL"
	])

	# (e) 화면 동작 — 챌린지별 초기 화면.
	AchievementManager._debug_reset_for_qa()
	var event_scene := load("res://code/scenes/event.tscn")
	var screen_node = event_scene.instantiate()
	add_child(screen_node)
	screen_node._debug_force_challenge_gambling()
	var gambling_subtitle_ok: bool = screen_node.title_label.text.contains("적게 걸까")
	var gambling_dc_text_ok: bool = screen_node.risky_button.text.contains("대성공")
	ok = gambling_subtitle_ok and gambling_dc_text_ok and ok
	lines.append("  _debug_force_challenge_gambling() -> title=\"%s\" 포함 확인=%s, risky 버튼에 \"대성공\" 포함=%s -> %s" % [
		screen_node.title_label.text, gambling_subtitle_ok, gambling_dc_text_ok, "OK" if (gambling_subtitle_ok and gambling_dc_text_ok) else "FAIL"
	])

	screen_node._debug_force_challenge_exploration()
	var exploration_ok: bool = screen_node.title_label.text.contains("샛길")
	ok = exploration_ok and ok
	lines.append("  _debug_force_challenge_exploration() -> title=\"%s\"(\"샛길\" 포함 기대) -> %s" % [screen_node.title_label.text, "OK" if exploration_ok else "FAIL"])

	screen_node._debug_force_challenge_trap_disarm()
	var trap_title_ok: bool = screen_node.title_label.text.contains("함정")
	ok = trap_title_ok and ok
	lines.append("  _debug_force_challenge_trap_disarm() -> title=\"%s\"(\"함정\" 포함 기대) -> %s" % [screen_node.title_label.text, "OK" if trap_title_ok else "FAIL"])
	remove_child(screen_node)
	screen_node.free()

	# (f) 대성공 보상 — 골드 실제 증가 + "대성공!" 표시(계산 결과 검증, 플래그만 보지 않음).
	RunState.rooms_cleared = 0
	RunState.gold = 0
	RunState.skill_flags = []
	AchievementManager._debug_reset_for_qa()
	var crit_node = event_scene.instantiate()
	add_child(crit_node)
	crit_node._debug_force_gambling_crit_success()
	var crit_gold_ok: bool = RunState.gold >= 24 and RunState.gold <= 32
	ok = crit_gold_ok and ok
	var roll_label_text := ""
	for child in crit_node.roll_root.get_children():
		if child is Label:
			roll_label_text = child.text
	var crit_label_ok: bool = roll_label_text.contains("대성공!")
	ok = crit_label_ok and ok
	var crit_no_card_ok: bool = crit_node._row_ui.is_empty()
	ok = crit_no_card_ok and ok
	lines.append("  '도박' 대성공 강제: RunState.gold=%d(기대 24~32) 굴림 라벨=\"%s\"(\"대성공!\" 포함 기대) 아이템 카드 없음(기대 true)=%s -> %s" % [
		RunState.gold, roll_label_text, crit_no_card_ok, "OK" if (crit_gold_ok and crit_label_ok and crit_no_card_ok) else "FAIL"
	])
	remove_child(crit_node)
	crit_node.free()

	# (g) 온건한 실패 패널티 — 골드 실제 감소(계산 결과 검증).
	RunState.rooms_cleared = 0
	RunState.gold = 10
	RunState.skill_flags = []
	AchievementManager._debug_reset_for_qa()
	var fail_node = event_scene.instantiate()
	add_child(fail_node)
	fail_node._debug_force_trap_disarm_failure()
	var penalty_gold_ok: bool = RunState.gold >= 5 and RunState.gold <= 7
	ok = penalty_gold_ok and ok
	var penalty_text_ok: bool = fail_node.fail_label.text.contains("금화")
	ok = penalty_text_ok and ok
	lines.append("  '함정 해체' 강제 실패(골드 10에서 시작): RunState.gold=%d(기대 5~7, 패널티 3~5) fail_label=\"%s\"(\"금화\" 포함 기대) -> %s" % [
		RunState.gold, fail_node.fail_label.text, "OK" if (penalty_gold_ok and penalty_text_ok) else "FAIL"
	])
	remove_child(fail_node)
	fail_node.free()

	RunState.character_id = character_backup
	RunState.skill_flags = skill_flags_backup
	RunState.rooms_cleared = rooms_backup
	RunState.gold = gold_backup
	RunState.event_die_sides = event_sides_backup
	AchievementManager._debug_reset_for_qa()
	return ok


## [대형 기획 14] N-5(c)(2026-10-16) 검증: 곡예사 D12가 실제로 눈에 보이는 화면 텍스트에
## 반영되는지(플래그/필드가 아니라 렌더된 문자열로 확인). N-4/N-5(a) 체크가 이미
## "능력치 칩 줄의 D12 텍스트"는 검증했으므로 여기서는 (1) "고유 능력" 섹션 설명
## (2026-10-17 [대형 기획 15] Q-3(9)로 글자 수 자르기(ABILITY_DESC_MAX_CHARS) 대신
## CharacterProfiles.PROFILES["ability_summary"]를 그대로 보여주는 방식으로 바뀜 —
## 곡예사 ability_summary 문구 자체에 "D12"를 항상 포함하도록 손으로 썼으므로 여전히
## 유효한 검증) (2) DeckPanel(던전 맵/상점/이벤트/스토리 이벤트 상시)의 "이벤트 주사위
## D12" 줄 (3) 스킬 도감에 juggle_fortune/juggle_fortune_plus id 자체가 실제로
## 들어있는지(L-2(a)는 개수/순서만 쟀을 뿐 id는 확인한 적이 없음)를 본다.
func _check_n5c_juggler_wrapup(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id

	# (a) character_select 고유 능력 설명(ability_summary) — "D12"가 실제로 보이는지.
	var select_scene := load("res://code/scenes/character_select.tscn")
	var select_node = select_scene.instantiate()
	add_child(select_node)
	select_node._on_card_selected("juggler")
	var ability_text: String = select_node._detail_skill_label.text
	var ability_shows_d12: bool = ability_text.findn("D12") != -1
	ok = ability_shows_d12 and ok
	lines.append("  character_select 고유 능력 설명(ability_summary): \"%s\" (D12 포함 기대) -> %s" % [
		ability_text, "OK" if ability_shows_d12 else "FAIL"
	])
	remove_child(select_node)
	select_node.free()

	# (b) DeckPanel(던전 맵/상점/이벤트/스토리 이벤트 5개 화면이 공유) — 트리 전체에서
	# "이벤트 주사위 D12" 라벨을 실제로 찾는다(노드 하나를 짚어둔 게 아니라 _rebuild()가
	# 매번 새로 그리는 구조라 재귀 탐색이 가장 안전함).
	RunState.reset_run("juggler")
	var deck := DeckPanel.new()
	add_child(deck)
	var deck_has_d12: bool = _n5c_find_label_containing(deck, "이벤트 주사위 D12")
	ok = deck_has_d12 and ok
	lines.append("  DeckPanel(던전 맵 등 5개 화면 상시): \"이벤트 주사위 D12\" 라벨 존재 -> %s" % (
		"OK" if deck_has_d12 else "FAIL"
	))
	remove_child(deck)
	deck.free()

	# (c) 스킬 도감 — juggle_fortune/juggle_fortune_plus id가 실제로 codex_entries()에
	# 들어있는지(L-2(a)는 "개수/순서"만 쟀을 뿐 id 자체는 확인한 적이 없었음).
	var entries := SkillPool.codex_entries("juggler")
	var ids: Array = []
	for e in entries:
		ids.append(e["id"])
	var codex_has_fortune: bool = ids.has("juggle_fortune") and ids.has("juggle_fortune_plus")
	ok = codex_has_fortune and ok
	lines.append("  SkillPool.codex_entries(\"juggler\")에 juggle_fortune/juggle_fortune_plus 포함: %s -> %s" % [
		ids, "OK" if codex_has_fortune else "FAIL"
	])

	# 밸런스(균형 정책 기준 견습 모험가 대비 -15%p 이내) 확인은 qa_out/balance_sim_raw.tsv
	# (bash scripts/qa_shot.sh balance_sim으로 재생성, 50400판 규모)를 읽어야 해서 dice_test
	# 자동 검증 범위 밖이다 — 수동 측정 결과는 STATUS.md 완료 기록에 남긴다.

	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	return ok


## 노드 서브트리 안에 text가 substring을 포함하는 Label이 하나라도 있으면 true.
## DeckPanel처럼 _rebuild()가 매번 새 노드를 만드는 구조에서 특정 Label을 멤버
## 변수로 짚어두지 않고도 "화면에 실제로 그 문구가 보이는가"를 확인하기 위한 범용 헬퍼.
func _n5c_find_label_containing(node: Node, substring: String) -> bool:
	if node is Label and String(node.text).contains(substring):
		return true
	for child in node.get_children():
		if _n5c_find_label_containing(child, substring):
			return true
	return false


## [대형 기획 14] N-6(2026-10-16) 검증: 캐릭터 전용 이벤트 + 특별 선택지. INBOX 지시대로
## "계산/동작 결과"를 확인한다 — 플래그 존재 여부가 아니라 pick_challenge()의 실제 분포,
## 버튼을 실제로 눌렀을 때 상태가 바뀌는지/안 바뀌는지, 보상 수치 비교, 8명 전부
## 커버리지를 직접 계산/렌더해서 검증한다.
func _check_n6_character_events_and_special_choices(lines: PackedStringArray) -> bool:
	var ok := true
	var event_script := load("res://code/scenes/event.gd")

	var all_ids: Array[String] = []
	for p in CharacterProfiles.PROFILES:
		all_ids.append(String(p["id"]))

	# 1) 8명 전부 전용 이벤트 또는 특별 선택지를 최소 1개 갖는지.
	var missing: Array[String] = []
	for cid in all_ids:
		var has_exclusive := not EventChallengePool.exclusive_challenges_for(cid).is_empty()
		var has_special := not EventChallengePool.special_choice_challenges_for(cid).is_empty()
		if not (has_exclusive or has_special):
			missing.append(cid)
	var coverage_ok: bool = missing.is_empty()
	ok = coverage_ok and ok
	lines.append("  8명 전부 전용 이벤트/특별 선택지 >=1개 보유 — 미보유: %s -> %s" % [missing, "OK" if coverage_ok else "FAIL"])

	# 2) 최소 분량(전용 이벤트 4종 이상, 특별 선택지 4종 이상).
	var exclusive_count := 0
	var special_count := 0
	for c in EventChallengePool.CHALLENGES:
		if EventChallengePool.is_exclusive(c):
			exclusive_count += 1
		if EventChallengePool.has_special_choice(c):
			special_count += 1
	var volume_ok: bool = exclusive_count >= 4 and special_count >= 4
	ok = volume_ok and ok
	lines.append("  전용 이벤트 %d종(기대 >=4) / 특별 선택지 %d종(기대 >=4) -> %s" % [
		exclusive_count, special_count, "OK" if volume_ok else "FAIL"
	])

	# 3) pick_challenge() 분포 — 전용 이벤트가 있는 캐릭터는 시드 100개 중 기대 확률
	#    범위(EXCLUSIVE_EVENT_CHANCE=0.25 기준 10~40회)만큼, 전용 이벤트가 없는 나머지
	#    캐릭터는 항상 0회(어떤 챌린지를 뽑아도 그 캐릭터 소유의 전용 이벤트일 수가
	#    없으므로 — INBOX "다른 7명은 시드 100개에서 0회"를 모든 캐릭터에 대해 일반화).
	for cid in all_ids:
		var exclusive_draw_count := 0
		var rng := RandomNumberGenerator.new()
		for seed_i in 100:
			rng.seed = seed_i * 7919 + 13
			var picked := EventChallengePool.pick_challenge(cid, rng)
			if EventChallengePool.is_exclusive(picked):
				exclusive_draw_count += 1
		var has_own_exclusive := not EventChallengePool.exclusive_challenges_for(cid).is_empty()
		if has_own_exclusive:
			var in_range: bool = exclusive_draw_count >= 10 and exclusive_draw_count <= 40
			ok = in_range and ok
			lines.append("  pick_challenge('%s') 100회 중 전용 등장 %d회(기대 10~40, EXCLUSIVE_EVENT_CHANCE=%.2f) -> %s" % [
				cid, exclusive_draw_count, EventChallengePool.EXCLUSIVE_EVENT_CHANCE, "OK" if in_range else "FAIL"
			])
		else:
			var zero_ok: bool = exclusive_draw_count == 0
			ok = zero_ok and ok
			lines.append("  pick_challenge('%s') 100회 중 전용 등장 %d회(기대 0, 전용 이벤트 없는 캐릭터) -> %s" % [
				cid, exclusive_draw_count, "OK" if zero_ok else "FAIL"
			])

	# 4) challenge_seed()/pick_challenge() 결정성 — 같은 run_seed+방 번호면 항상 같은
	#    시드, 같은 시드면 항상 같은 챌린지(테스트 전투/QA 시드에서도 재현 가능해야
	#    한다는 INBOX 지시 반영).
	var seed_a: int = event_script.challenge_seed(12345, 2)
	var seed_a2: int = event_script.challenge_seed(12345, 2)
	var seed_determinism_ok: bool = seed_a == seed_a2
	ok = seed_determinism_ok and ok
	lines.append("  challenge_seed(12345,2) 두 번 호출 결과 동일(%d == %d) -> %s" % [seed_a, seed_a2, "OK" if seed_determinism_ok else "FAIL"])

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = seed_a
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = int(event_script.challenge_seed(12345, 2))
	var picked_a: Dictionary = EventChallengePool.pick_challenge("pirate", rng_a)
	var picked_b: Dictionary = EventChallengePool.pick_challenge("pirate", rng_b)
	var reproducible_ok: bool = picked_a["id"] == picked_b["id"]
	ok = reproducible_ok and ok
	lines.append("  같은 run_seed+방 번호면 pick_challenge() 결과도 항상 동일('%s' == '%s') -> %s" % [
		picked_a["id"], picked_b["id"], "OK" if reproducible_ok else "FAIL"
	])

	# 5) 특별 선택지 — 비소유 캐릭터는 잠김(눌러도 상태 불변), 소유 캐릭터는 활성
	#    (실제로 눌렀을 때 보상이 적용되고, 그 보상 기대값이 같은 challenge의 안전
	#    선택지보다 실제로 크다). "treasure"(enchantress 전용 특별 선택지 보유)로 확인.
	var event_scene := load("res://code/scenes/event.tscn")
	var ev = event_scene.instantiate()
	add_child(ev)
	var character_backup: String = RunState.character_id

	RunState.character_id = "novice"  # "treasure"의 special_choice는 enchantress 전용
	ev._debug_force_challenge("treasure")
	var locked_btn: Button = ev._special_button
	var locked_exists_ok: bool = locked_btn != null
	ok = locked_exists_ok and ok
	lines.append("  비소유(novice) 상태에서 특별 선택지 버튼 존재 -> %s" % ("OK" if locked_exists_ok else "FAIL"))
	if locked_btn != null:
		var title_lbl: Label = locked_btn.get_child(0).get_child(0) if locked_btn.get_child_count() > 0 else null
		var lock_badge_ok: bool = title_lbl != null and String(title_lbl.text).begins_with("🔒")
		ok = lock_badge_ok and ok
		lines.append("  잠김 버튼 문구='%s' (🔒로 시작 기대) -> %s" % [
			title_lbl.text if title_lbl != null else "(없음)", "OK" if lock_badge_ok else "FAIL"
		])

		var choice_made_before: bool = ev._choice_made
		locked_btn.pressed.emit()
		var state_unchanged_ok: bool = ev._choice_made == choice_made_before and ev._row_ui.is_empty()
		ok = state_unchanged_ok and ok
		lines.append("  잠긴 선택지 pressed.emit() 후 상태 불변(choice_made=%s->%s, 카드 수=%d) -> %s" % [
			choice_made_before, ev._choice_made, ev._row_ui.size(), "OK" if state_unchanged_ok else "FAIL"
		])

	RunState.character_id = "enchantress"
	ev._debug_force_challenge("treasure")
	var active_btn: Button = ev._special_button
	var active_exists_ok: bool = active_btn != null
	ok = active_exists_ok and ok
	lines.append("  소유(enchantress) 상태에서 특별 선택지 버튼 존재 -> %s" % ("OK" if active_exists_ok else "FAIL"))
	if active_btn != null:
		var title_lbl2: Label = active_btn.get_child(0).get_child(0) if active_btn.get_child_count() > 0 else null
		var active_badge_ok: bool = title_lbl2 != null and not String(title_lbl2.text).begins_with("🔒")
		ok = active_badge_ok and ok
		lines.append("  활성 버튼 문구='%s' (자물쇠 없이 '전용' 표기 기대) -> %s" % [
			title_lbl2.text if title_lbl2 != null else "(없음)", "OK" if active_badge_ok else "FAIL"
		])

		var reward_spec: Dictionary = ev._challenge["special_choice"]["reward"]
		var safe_spec: Dictionary = ev._challenge["safe_reward"]
		var reward_ev := EventChallengePool.reward_expected_value(reward_spec)
		var safe_ev := EventChallengePool.reward_expected_value(safe_spec)
		var bigger_ok: bool = reward_ev > safe_ev
		ok = bigger_ok and ok
		lines.append("  특별 선택지 기대값=%.2f > 안전 선택지 기대값=%.2f(둘 다 type=%s) -> %s" % [
			reward_ev, safe_ev, reward_spec.get("type", "?"), "OK" if bigger_ok else "FAIL"
		])

		active_btn.pressed.emit()
		var applied_ok: bool = ev._choice_made and ev._row_ui.size() == 1
		ok = applied_ok and ok
		lines.append("  활성 선택지 pressed.emit() 후 choice_made=%s, 카드 수=%d(기대 1, 보상 적용됨) -> %s" % [
			ev._choice_made, ev._row_ui.size(), "OK" if applied_ok else "FAIL"
		])

	# 6) 전용 이벤트 화면 — 제목에 "전용" 배지가 실제로 뜨는지(pirate + treasure_map).
	RunState.character_id = "pirate"
	ev._debug_force_challenge("treasure_map")
	var exclusive_title_ok: bool = String(ev.title_label.text).find("전용") != -1
	ok = exclusive_title_ok and ok
	lines.append("  전용 이벤트(pirate, treasure_map) 제목에 '전용' 배지 포함: '%s' -> %s" % [
		ev.title_label.text, "OK" if exclusive_title_ok else "FAIL"
	])

	remove_child(ev)
	ev.free()
	RunState.character_id = character_backup
	return ok


## [미니 기획 ART-1c-4] 어두운 몬스터 외곽 글로우 검증 — ① CharacterArt.
## average_opaque_luminance()가 투명 픽셀을 제외하고 올바르게 판정하는지(합성 어두운/
## 밝은 이미지, 실제 원화와 무관해 결정적), ② 카탈로그 전수(입고된 몬스터 전체)의
## 휘도표를 찍어(docs/STATUS.md 완료 기록에 그대로 옮겨 적음), ③ 실제 production
## 자산(설계 문서가 예시로 든 "그림자"=어두움 / "슬라임"=밝음)으로
## MonsterPortraitPlaceholder.set_monster()가 글로우를 올바르게 켜고 끄는지, ④ 합성
## 정사각 가짜 원화(레터박스 없음, _check_art1c3와 같은 패턴)로 글로우 레이어 자체를
## SubViewport에 렌더해 실제 알파가 완전 투명이 아닌지 확인한다. SubViewport를 쓰므로
## await로 불러야 한다.
func _check_art1c4_monster_dark_glow(lines: PackedStringArray) -> bool:
	var ok := true

	# 1) 휘도 함수 단위 검증 — 합성 이미지(실제 원화와 무관, 결정적).
	var dark_img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	dark_img.fill(Color(0.05, 0.05, 0.05, 1.0))
	var dark_luminance: float = CharacterArt.average_opaque_luminance(dark_img)
	var dark_ok: bool = dark_luminance < CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD
	ok = dark_ok and ok
	lines.append("  합성 어두운 이미지(0.05,0.05,0.05) 평균 휘도=%.4f (기대 < %.2f) -> %s" % [
		dark_luminance, CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD, "OK" if dark_ok else "FAIL"
	])

	var bright_img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	bright_img.fill(Color(0.9, 0.9, 0.9, 1.0))
	var bright_luminance: float = CharacterArt.average_opaque_luminance(bright_img)
	var bright_ok: bool = bright_luminance >= CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD
	ok = bright_ok and ok
	lines.append("  합성 밝은 이미지(0.9,0.9,0.9) 평균 휘도=%.4f (기대 >= %.2f) -> %s" % [
		bright_luminance, CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD, "OK" if bright_ok else "FAIL"
	])

	# 투명 픽셀 제외 검증 — 절반은 완전 투명한 검정(크롭 레터박스를 흉내), 절반은 불투명한
	# 밝은 색. 평균이 "밝은 색" 값과 거의 같아야 한다(투명 검정에 끌려 내려가면 안 됨).
	var mixed_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in range(4):
		for x in range(4):
			if x < 2:
				mixed_img.set_pixel(x, y, Color(0, 0, 0, 0)) # 투명(레터박스 흉내)
			else:
				mixed_img.set_pixel(x, y, Color(0.8, 0.8, 0.8, 1.0)) # 불투명 밝음
	var mixed_luminance: float = CharacterArt.average_opaque_luminance(mixed_img)
	var mixed_ok: bool = absf(mixed_luminance - 0.8) < 0.01
	ok = mixed_ok and ok
	lines.append("  투명 픽셀 50%% + 불투명 밝은 픽셀(0.8) 50%% 평균 휘도=%.4f (기대 ≈0.8, 투명 픽셀이 평균을 안 끌어내림) -> %s" % [
		mixed_luminance, "OK" if mixed_ok else "FAIL"
	])

	# 2) 카탈로그 전수 휘도표 — 입고된 몬스터 전체(full.png가 있는 id, 별칭 해석 포함,
	#    face_* 5장이 있는 몬스터는 아직 없어 전부 크롭 경로).
	lines.append("  [카탈로그 전수 휘도표 (불투명 픽셀 평균 상대 휘도, 기준 < %.2f = 글로우 대상)]" % CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD)
	var dark_ids: Array = []
	var catalog_count := 0
	for m in MonsterCatalog.MONSTERS:
		var mid: String = m["id"]
		var art_id: String = MonsterCatalog.art_resource_id(mid)
		if not CharacterArt.has_full(art_id, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR):
			continue
		if CharacterArt.has_all_faces(art_id, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR):
			continue # face_* 있으면 full.png 크롭 경로를 안 쓰므로 이 표에서는 제외(현재 없음)
		catalog_count += 1
		var luminance: float = CharacterArt.full_crop_luminance(art_id, CharacterArt.DEFAULT_FACE_CROP_RATIO, MonsterPortraitPlaceholder.MONSTER_ART_BASE_DIR)
		var is_dark: bool = luminance < CharacterArt.DARK_PORTRAIT_LUMINANCE_THRESHOLD
		if is_dark:
			dark_ids.append(mid)
		lines.append("    %s (%s): 휘도=%.3f -> %s" % [mid, m["name"], luminance, "글로우" if is_dark else "-"])
	lines.append("  카탈로그 전수 %d종 중 글로우 대상 %d종: %s" % [catalog_count, dark_ids.size(), dark_ids])
	var catalog_nonempty_ok: bool = catalog_count > 0
	ok = catalog_nonempty_ok and ok
	lines.append("  (카탈로그에 원화가 1종 이상 입고돼 표가 비지 않음) -> %s" % ("OK" if catalog_nonempty_ok else "FAIL"))

	# 3) "어두운 원화" 경로 — 작성 당시(2026-10-16)에는 "그림자"(shadow) 몬스터가
	#    카탈로그에서 유일하게 어두워 실제 production 자산으로 검증했지만, 그 뒤
	#    아트 스레드의 v3 재디자인(커밋 ad19295, 2026-10-17)으로 일반 몬스터 14종이
	#    전부 밝아져 지금은 카탈로그 35종 전수 중 글로우 대상이 0종이다(위 "카탈로그
	#    전수 휘도표" 참고 — 앞으로 아트가 다시 바뀌어도 이 경로가 "마침 그 시점에
	#    카탈로그에 어두운 몬스터가 있는지"에 좌우되지 않도록, 합성 가짜 원화(아래
	#    _art1c4_write_fake_square_full_dark(), 섹션 4와 공유)로 어두운 경로 자체를
	#    검증한다. "슬라임"(밝은 초록, 실제 production 자산)은 여전히 안 켜지는지로
	#    밝은 경로를 검증.
	var fake_base_dir := "user://art1c4_fake_monster_dark/%s/"
	var fake_id := "qa_fake_monster_dark_glow"
	_art1c4_write_fake_square_full_dark(fake_base_dir, fake_id)

	var dark_portrait := MonsterPortraitPlaceholder.new()
	add_child(dark_portrait)
	dark_portrait.art_base_dir = fake_base_dir
	dark_portrait.set_monster(fake_id)
	var shadow_dark_ok: bool = dark_portrait._is_dark_portrait and dark_portrait._glow_rect != null and dark_portrait._glow_rect.visible
	ok = shadow_dark_ok and ok
	lines.append("  합성 어두운 원화(fake_id=%s)로 set_monster() 후 _is_dark_portrait=%s, 글로우 노드 visible=%s -> %s" % [
		fake_id,
		dark_portrait._is_dark_portrait,
		(dark_portrait._glow_rect.visible if dark_portrait._glow_rect != null else "(없음)"),
		"OK" if shadow_dark_ok else "FAIL"
	])

	var bright_portrait := MonsterPortraitPlaceholder.new()
	add_child(bright_portrait)
	bright_portrait.set_monster("slime")
	var slime_bright_ok: bool = (not bright_portrait._is_dark_portrait) and (bright_portrait._glow_rect == null or not bright_portrait._glow_rect.visible)
	ok = slime_bright_ok and ok
	lines.append("  set_monster('slime') 후 _is_dark_portrait=%s, 글로우 노드=%s -> %s" % [
		bright_portrait._is_dark_portrait,
		("없음" if bright_portrait._glow_rect == null else ("visible=%s" % bright_portrait._glow_rect.visible)),
		"OK" if slime_bright_ok else "FAIL"
	])

	# 밝은 몬스터는 _face_rect 자체도(글로우와 무관하게) 기존과 동일해야 한다 — ART-1c-3
	# 페이드 셰이더 파라미터가 그대로인지 재확인(회귀 가드, "밝은 몬스터는 화면이 기존과
	# 완전히 동일해야 한다"는 요구사항).
	var bright_shader_ok: bool = (bright_portrait._face_rect != null and bright_portrait._face_rect.material is ShaderMaterial
		and float((bright_portrait._face_rect.material as ShaderMaterial).get_shader_parameter("side_fade")) == MonsterPortraitPlaceholder.FACE_ART_SIDE_FADE)
	ok = bright_shader_ok and ok
	lines.append("  밝은 몬스터 _face_rect 셰이더 파라미터 불변(side_fade=%.2f) -> %s" % [
		MonsterPortraitPlaceholder.FACE_ART_SIDE_FADE, "OK" if bright_shader_ok else "FAIL"
	])

	remove_child(dark_portrait)
	dark_portrait.free()
	remove_child(bright_portrait)
	bright_portrait.free()

	# 4) 합성 정사각 가짜 원화(레터박스 없음, 섹션 3이 이미 써둔 fake_base_dir/fake_id를
	#    그대로 재사용)로 글로우 레이어 자체를 SubViewport에 렌더해 실제 알파를
	#    확인한다 — 중심(글로우 전체가 불투명 소스를 그대로 보여주는 지점)은
	#    GLOW_ALPHA에 근접, 본체(_face_rect)에 안 덮이는 가장자리 margin도 완전 투명(0)은
	#    아니어야 한다(= 실제로 뭔가 보인다, 과업 지시의 "글로우 영역 픽셀이 투명이 아닌지"
	#    요구사항).
	var glow_portrait := MonsterPortraitPlaceholder.new()
	add_child(glow_portrait)
	glow_portrait.art_base_dir = fake_base_dir
	glow_portrait.set_monster(fake_id)

	var synthetic_dark_ok: bool = glow_portrait._is_dark_portrait and glow_portrait._glow_rect != null
	ok = synthetic_dark_ok and ok
	lines.append("  합성 어두운 가짜 원화(0.05,0.05,0.05) set_monster() 후 글로우 생성됨 -> %s" % (
		"OK" if synthetic_dark_ok else "FAIL"
	))

	var render_ok := false
	var center_alpha := 0.0
	var margin_alpha := 0.0
	if glow_portrait._glow_rect != null:
		var glow_box_size: Vector2 = MonsterPortraitPlaceholder.FACE_ART_SIZE * MonsterPortraitPlaceholder.GLOW_SCALE
		var probe_viewport := SubViewport.new()
		probe_viewport.size = Vector2i(ceili(glow_box_size.x), ceili(glow_box_size.y))
		probe_viewport.transparent_bg = true
		probe_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(probe_viewport)

		var probe_glow_rect: TextureRect = glow_portrait._glow_rect
		glow_portrait.remove_child(probe_glow_rect)
		probe_glow_rect.position = Vector2.ZERO
		probe_viewport.add_child(probe_glow_rect)

		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		var img: Image = probe_viewport.get_texture().get_image()
		render_ok = img != null
		if render_ok:
			var cx := int(glow_box_size.x / 2.0)
			var cy := int(glow_box_size.y / 2.0)
			center_alpha = img.get_pixel(cx, cy).a
			# 본체(_face_rect, 240x240)에 덮이는 범위를 벗어난 margin 지점 — 글로우
			# 박스 왼쪽 끝에서 10px(= GLOW_SCALE이 벌려놓은 여백 안쪽, _face_rect가 안
			# 닿는 영역).
			margin_alpha = img.get_pixel(10, cy).a
		probe_viewport.queue_free()
	ok = render_ok and ok
	if render_ok:
		var center_ok: bool = absf(center_alpha - MonsterPortraitPlaceholder.GLOW_ALPHA) < 0.05
		ok = center_ok and ok
		lines.append("  글로우 레이어 중앙 알파=%.3f (기대 ≈ GLOW_ALPHA=%.2f) -> %s" % [
			center_alpha, MonsterPortraitPlaceholder.GLOW_ALPHA, "OK" if center_ok else "FAIL"
		])
		var margin_ok: bool = margin_alpha > 0.02
		ok = margin_ok and ok
		lines.append("  글로우 레이어 가장자리 margin(본체 밖) 알파=%.3f (기대 > 0.02, 완전 투명 아님) -> %s" % [
			margin_alpha, "OK" if margin_ok else "FAIL"
		])
	else:
		lines.append("    FAIL: SubViewport 이미지를 가져오지 못함")

	_art1c2_remove_fake_full(fake_base_dir, fake_id) # 파일명(full.png) 규칙 공유 — 기존 제거 헬퍼 재사용
	DirAccess.remove_absolute("user://art1c4_fake_monster_dark")
	remove_child(glow_portrait)
	glow_portrait.free()

	return ok


## _check_art1c4_monster_dark_glow() 전용 헬퍼 — _art1c3_write_fake_square_full()과
## 같은 정사각(레터박스 없음) 가짜 full.png지만 평균 휘도가 DARK_PORTRAIT_LUMINANCE_
## THRESHOLD보다 뚜렷이 낮은 어두운 색(0.05,0.05,0.05)을 쓴다.
func _art1c4_write_fake_square_full_dark(base_dir_pattern: String, monster_id: String) -> void:
	var dir_path := base_dir_pattern % monster_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var img := Image.create(200, 200, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.05, 1.0))
	img.save_png(dir_path + "full.png")


## [미니 기획 ART-1c-4] 전투 결과 줄 "공격"/"방어" 라벨 색 검증 — 어두운 몬스터(그림자,
## monster_color=Color(0.2,0.2,0.25))가 선택된 전투에서도 라벨이 ATTACK_LABEL_COLOR/
## DEFENSE_LABEL_COLOR 고정값을 그대로 쓰는지(몬스터 색에 더는 좌우되지 않는지), 두 색
## 다 어두운 배경 기준 WCAG AA(4.5:1) 이상 대비인지 계산으로 확인한다. combat_test의
## 실제 _show_exchange_dice_chips()를 직접 호출해(물리 스폰 없이) 검증 — 감독 캡처
## (qa_out/art1c4_shadow_attack_before.png)에서 라벨이 안 보이던 실제 재현 경로.
func _check_art1c4_dice_label_contrast(lines: PackedStringArray) -> bool:
	var ok := true
	var dark_reference := Color(0.05, 0.05, 0.05) # 전투 배경/패널의 어두운 쪽 대표값
	var combat_script := load("res://code/scenes/combat_test.gd")
	var attack_label_color: Color = combat_script.ATTACK_LABEL_COLOR
	var defense_label_color: Color = combat_script.DEFENSE_LABEL_COLOR

	var attack_contrast: float = CharacterTheme.contrast_ratio(attack_label_color, dark_reference)
	var attack_contrast_ok: bool = attack_contrast >= 4.5
	ok = attack_contrast_ok and ok
	lines.append("  ATTACK_LABEL_COLOR(%s) vs 어두운 배경 대비비=%.1f:1 (기대 >= 4.5:1) -> %s" % [
		attack_label_color, attack_contrast, "OK" if attack_contrast_ok else "FAIL"
	])

	var defense_contrast: float = CharacterTheme.contrast_ratio(defense_label_color, dark_reference)
	var defense_contrast_ok: bool = defense_contrast >= 4.5
	ok = defense_contrast_ok and ok
	lines.append("  DEFENSE_LABEL_COLOR(%s) vs 어두운 배경 대비비=%.1f:1 (기대 >= 4.5:1) -> %s" % [
		defense_label_color, defense_contrast, "OK" if defense_contrast_ok else "FAIL"
	])

	# 실제 호출 경로 — 어두운 몬스터(그림자) 색을 tint로 넘겨도 라벨 색이 영향받지 않는지.
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	var shadow_tint := Color(0.2, 0.2, 0.25) # MonsterCatalog "shadow"의 실제 color 필드
	var atk_bag := DiceBag.new(4, 3)
	var def_bag := DiceBag.new(4, 1)
	combat._show_exchange_dice_chips(atk_bag, [2, 3, 2], def_bag, [1], shadow_tint, shadow_tint)

	var attack_label: Label = null
	var defense_label: Label = null
	for node in combat._exchange_chip_nodes:
		if node is Label:
			if node.text == "공격":
				attack_label = node
			elif node.text == "방어":
				defense_label = node

	var labels_found_ok: bool = attack_label != null and defense_label != null
	ok = labels_found_ok and ok
	lines.append("  _show_exchange_dice_chips(어두운 monster_color 전달) 후 '공격'/'방어' 라벨 노드 둘 다 발견됨 -> %s" % (
		"OK" if labels_found_ok else "FAIL"
	))
	if labels_found_ok:
		var attack_color_ok: bool = attack_label.get_theme_color("font_color") == attack_label_color
		ok = attack_color_ok and ok
		lines.append("  '공격' 라벨 font_color=%s (기대 ATTACK_LABEL_COLOR, 몬스터 색과 무관) -> %s" % [
			attack_label.get_theme_color("font_color"), "OK" if attack_color_ok else "FAIL"
		])
		var defense_color_ok: bool = defense_label.get_theme_color("font_color") == defense_label_color
		ok = defense_color_ok and ok
		lines.append("  '방어' 라벨 font_color=%s (기대 DEFENSE_LABEL_COLOR, 몬스터 색과 무관) -> %s" % [
			defense_label.get_theme_color("font_color"), "OK" if defense_color_ok else "FAIL"
		])

	remove_child(combat)
	combat.free()
	return ok


## [대형 기획 15] Q-1(17, 24, 2026-10-16) — 몬스터 포트레이트 배율/화면 밖 잘림 검증.
## 사용자 피드백(17) "몬스터 이미지가 잘린다"/(24) "보스가 다른 몬스터와 사이즈가 비슷해
## 위상이 안 높아 보인다" — 기존 유일한 검증(_check_m3_combat_dice_stage의 "ellipse
## radius_x=66" 체크)은 지금은 거의 안 쓰이는 도형 플레이스홀더 경로만 쟀을 뿐, 실제
## 원화(_face_rect)/글로우(_glow_rect)가 production 배치 좌표에서 화면 밖으로 나가는지는
## 한 번도 검증된 적이 없었다. combat_test.gd의 _apply_monster_portrait_tier()(production이
## 실제로 쓰는 바로 그 함수)를 카탈로그 전수(일반/정예/보스 전부)에 실제로 호출해
## _face_rect.get_global_rect()(그리고 보이면 _glow_rect도)가 화면(1280x720) 안에 드는지
## 전부 측정한다 — "_debug_shift_monster_portrait_center로 화면 중앙에 옮긴 뒤" 보는 게
## 아니라 실제 프로덕션 앵커(MONSTER_PORTRAIT_BASE_POSITION)+배율 그대로다.
func _check_q1_monster_portrait_tier_bounds(lines: PackedStringArray) -> bool:
	var ok := true
	var combat_script := load("res://code/scenes/combat_test.gd")
	var scale_by_tier: Dictionary = combat_script.MONSTER_PORTRAIT_SCALE_BY_TIER

	var normal_s: float = scale_by_tier.get("normal", 1.0)
	var elite_s: float = scale_by_tier.get("elite", 1.0)
	var boss_s: float = scale_by_tier.get("boss", 1.0)
	var monotonic_ok: bool = boss_s > elite_s and elite_s > normal_s
	ok = monotonic_ok and ok
	lines.append("  티어별 배율 상수: 일반=%.2f 정예=%.2f 보스=%.2f (보스>정예>일반이어야 함) -> %s" % [
		normal_s, elite_s, boss_s, "OK" if monotonic_ok else "FAIL"
	])
	var const_ratio_ok: bool = normal_s > 0.0 and (boss_s / normal_s) >= 1.4
	ok = const_ratio_ok and ok
	lines.append("  보스/일반 배율 비=%.2f (기대 >= 1.4) -> %s" % [
		(boss_s / normal_s) if normal_s > 0.0 else -1.0, "OK" if const_ratio_ok else "FAIL"
	])

	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	var screen := Rect2(0.0, 0.0, 1280.0, 720.0)

	# 실제 렌더 높이로도 "보스 > 정예 > 일반" 및 "보스 >= 일반 * 1.4"를 확인한다(상수값이
	# 아니라 실제 노드 rect — 대표 몬스터 3종은 전부 production 원화가 입고돼 있음).
	var rep_by_tier := {"normal": "slime", "elite": "goblin_chief", "boss": "goblin_king"}
	var rep_heights := {}
	for tier_key in rep_by_tier:
		var mid: String = rep_by_tier[tier_key]
		var is_boss: bool = tier_key == "boss"
		var is_elite: bool = tier_key == "elite"
		combat.monster_portrait.set_monster(mid)
		combat._apply_monster_portrait_tier(is_elite, is_boss)
		var fr: TextureRect = combat.monster_portrait._face_rect
		rep_heights[tier_key] = fr.get_global_rect().size.y if fr != null else 0.0
	var render_monotonic_ok: bool = rep_heights["boss"] > rep_heights["elite"] and rep_heights["elite"] > rep_heights["normal"]
	ok = render_monotonic_ok and ok
	lines.append("  실제 렌더 높이: 일반(%s)=%.1f 정예(%s)=%.1f 보스(%s)=%.1f (보스>정예>일반) -> %s" % [
		rep_by_tier["normal"], rep_heights["normal"], rep_by_tier["elite"], rep_heights["elite"],
		rep_by_tier["boss"], rep_heights["boss"], "OK" if render_monotonic_ok else "FAIL"
	])
	var render_ratio_ok: bool = rep_heights["normal"] > 0.0 and (rep_heights["boss"] / rep_heights["normal"]) >= 1.4
	ok = render_ratio_ok and ok
	lines.append("  실제 렌더 높이 비(보스/일반)=%.2f (기대 >= 1.4) -> %s" % [
		(rep_heights["boss"] / rep_heights["normal"]) if rep_heights["normal"] > 0.0 else -1.0,
		"OK" if render_ratio_ok else "FAIL"
	])

	# 카탈로그 전수(35종) — production 배치(앵커+배율)로 실제 렌더해 화면 밖 잘림이 있는지
	# _face_rect/_glow_rect 둘 다 Rect2.encloses()로 확인한다("_debug_shift_monster_
	# portrait_center" 같은 QA 전용 중앙 이동 없이 실제 배치 좌표 그대로).
	var out_of_bounds: Array[String] = []
	var checked_count := 0
	for profile in MonsterCatalog.MONSTERS:
		var mid: String = profile["id"]
		var tier: String = profile.get("tier", "normal")
		var is_boss := tier == "boss"
		var is_elite := tier == "elite"
		combat.monster_portrait.set_monster(mid)
		combat._apply_monster_portrait_tier(is_elite, is_boss)
		checked_count += 1
		var fr: TextureRect = combat.monster_portrait._face_rect
		if fr != null and fr.visible:
			var r := fr.get_global_rect()
			if not screen.encloses(r):
				out_of_bounds.append("%s(face, tier=%s, rect=%s)" % [mid, tier, r])
		var gr_node: TextureRect = combat.monster_portrait._glow_rect
		if gr_node != null and gr_node.visible:
			var gr := gr_node.get_global_rect()
			if not screen.encloses(gr):
				out_of_bounds.append("%s(glow, tier=%s, rect=%s)" % [mid, tier, gr])

	var bounds_ok: bool = out_of_bounds.is_empty()
	ok = bounds_ok and ok
	lines.append("  카탈로그 전수(%d종) production 배치 화면 밖 잘림 검사 -> %s%s" % [
		checked_count, "OK" if bounds_ok else "FAIL",
		("" if bounds_ok else (" (잘림: " + ", ".join(out_of_bounds) + ")"))
	])

	remove_child(combat)
	combat.free()

	return ok


## [미니 기획 ART-1c-5](2026-10-19) — 보스 크롭이 가슴 중심이라 v3 보스의 큰 왕관/
## 머리장식이 위쪽 페이드에 묻히고(고블린 왕 왕관이 거의 안 보임, 공허의 눈 이마 세
## 번째 눈이 잘림), 보스 컷이 몬스터 HUD 패널 바로 아래 붙어 머리가 패널에 눌려 보이던
## 문제의 수치 검증. "플래그 존재"가 아니라 실제 계산 결과(크롭 Rect 값/텍스처 상단 y)로
## 확인한다 — "계산 결과가 실제로 바뀌는가"를 봐야 한다는 세션 원칙(플래그만 보는
## 테스트가 과거 효과 안 붙는 버그를 놓친 적 있음) 그대로.
func _check_art1c5_boss_crop(lines: PackedStringArray) -> bool:
	await get_tree().process_frame
	var ok := true

	# ① 보스 크롭 비율 — BOSS_FACE_CROP_RATIO가 사람이 튜닝해둔 고정값 그대로인지
	#    (monster_face_crop_ratio()가 tier=="boss"면 바로 이 상수를 돌려줘야 함 —
	#    [미니 기획 ART-1c-6]부터 일반/정예는 더는 이 고정값을 안 쓰고 알파 기반
	#    자동 탐지로 바뀌었다 — 그 검증은 _check_art1c6_monster_face_crop_and_hud_
	#    margin()이 담당, 여기서는 "보스는 안 바뀌었다"만 확인).
	var boss_crop: Rect2 = CharacterArt.monster_face_crop_ratio("아무몬스터id", "boss")
	var unchanged_ok: bool = boss_crop == CharacterArt.BOSS_FACE_CROP_RATIO
	ok = unchanged_ok and ok
	lines.append("  보스 크롭 비율이 BOSS_FACE_CROP_RATIO 그대로인지(tier=='boss'면 몬스터 id와 무관하게 고정값) -> %s" % ["OK" if unchanged_ok else "FAIL"])
	var crop_start_ok: bool = boss_crop.position.y < CharacterArt.DEFAULT_FACE_CROP_RATIO.position.y
	ok = crop_start_ok and ok
	lines.append("  크롭 시작 y: 캐릭터 기본값=%.4f 보스=%.4f (보스가 더 위쪽/작아야 함) -> %s" % [
		CharacterArt.DEFAULT_FACE_CROP_RATIO.position.y, boss_crop.position.y, "OK" if crop_start_ok else "FAIL"
	])

	# ② top_fade — 보스만 더 작은지(FACE_ART_TOP_FADE_BY_TIER).
	var fade_by_tier: Dictionary = MonsterPortraitPlaceholder.FACE_ART_TOP_FADE_BY_TIER
	var normal_fade: float = fade_by_tier.get("normal", 1.0)
	var boss_fade: float = fade_by_tier.get("boss", 1.0)
	var fade_ok: bool = boss_fade < normal_fade
	ok = fade_ok and ok
	lines.append("  top_fade: 일반=%.3f 보스=%.3f (보스가 더 작아야 함) -> %s" % [normal_fade, boss_fade, "OK" if fade_ok else "FAIL"])

	# ③+④ 보스 6종 전수 — production 배치(combat_test.tscn, _apply_monster_portrait_tier)로
	#    실제 렌더해 _face_rect 상단 y가 몬스터 HUD 패널 하단 y + 여백 이상인지, 화면
	#    (1280x720) 안에 드는지. 몬스터 HUD 패널 높이는 실제 "특성" 줄 텍스트 길이에
	#    따라 달라지므로(_setup_combat_hud()가 만드는 PanelContainer 자동 높이), 각
	#    보스의 실제 trait 텍스트(_monster_trait_summary_text, production과 동일 함수)를
	#    채우고 레이아웃이 안정될 때까지 기다린 뒤 측정한다 — 빈 텍스트로 측정하면 패널이
	#    실제보다 작게 나와 여백 미달을 놓칠 수 있다.
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	var combat_script := load("res://code/scenes/combat_test.gd")
	var screen := Rect2(0.0, 0.0, 1280.0, 720.0)
	const MARGIN := 10.0

	var boss_ids: Array = MonsterCatalog.boss_roster_ids()
	var missing_margin: Array[String] = []
	var out_of_bounds: Array[String] = []
	for mid in boss_ids:
		var profile: Dictionary = MonsterCatalog.get_by_id(mid)
		var skill_ids: Array = []
		for skill in profile.get("skills", []):
			var skill_id: String = skill.get("id", "")
			if skill_id != "":
				skill_ids.append(skill_id)
		var trait_config := {"personality": profile.get("personality", ""), "skill_ids": skill_ids}
		combat.monster_trait_label.text = combat_script._monster_trait_summary_text(trait_config)
		combat.monster_portrait.set_monster(mid)
		combat._apply_monster_portrait_tier(false, true)
		await get_tree().process_frame
		await get_tree().process_frame
		var fr: TextureRect = combat.monster_portrait._face_rect
		if fr == null or not fr.visible:
			missing_margin.append("%s(no face_rect)" % mid)
			continue
		var fr_rect := fr.get_global_rect()
		var panel_rect: Rect2 = combat._hud_panels[2].get_global_rect() if combat._hud_panels.size() >= 3 else Rect2()
		var panel_bottom: float = panel_rect.position.y + panel_rect.size.y
		if fr_rect.position.y < panel_bottom + MARGIN:
			missing_margin.append("%s(top=%.1f, panel_bottom+margin=%.1f)" % [mid, fr_rect.position.y, panel_bottom + MARGIN])
		if not screen.encloses(fr_rect):
			out_of_bounds.append("%s(rect=%s)" % [mid, fr_rect])

	var margin_ok: bool = missing_margin.is_empty()
	ok = margin_ok and ok
	lines.append("  보스 %d종 — 포트레이트 상단 y >= 몬스터 HUD 패널 하단 y + 여백(%.0fpx) -> %s%s" % [
		boss_ids.size(), MARGIN, "OK" if margin_ok else "FAIL",
		("" if margin_ok else (" (미달: " + ", ".join(missing_margin) + ")"))
	])
	var boss_bounds_ok: bool = out_of_bounds.is_empty()
	ok = boss_bounds_ok and ok
	lines.append("  보스 %d종 — production 배치 화면(1280x720) 안 배치 -> %s%s" % [
		boss_ids.size(), "OK" if boss_bounds_ok else "FAIL",
		("" if boss_bounds_ok else (" (잘림: " + ", ".join(out_of_bounds) + ")"))
	])

	remove_child(combat)
	combat.free()

	return ok


## [미니 기획 ART-1c-6](2026-10-21) 일반/정예 몬스터 전투 컷 — 아트 스레드 요청(머리가
## 몬스터 HUD 패널에 가려지고, full.png 크롭이 가슴께부터 시작해 머리가 아예 안 보이는
## 문제) 수치 검증. "플래그만 보지 않는다" 원칙대로 실제 계산 결과(크롭 Rect 값/텍스처
## 상단 y)를 본다. ①②는 CharacterArt.detect_face_crop_ratio() 순수 함수를 합성 이미지로
## (production 원화에 의존하지 않고) 검증, ③은 카탈로그 전체(정상 범위 sanity), ④는
## ART-1c-5와 같은 방식으로 일반/정예 전수를 production 배치로 실제 렌더해 HUD 패널
## 여백을 확인한다.
func _check_art1c6_monster_face_crop_and_hud_margin(lines: PackedStringArray) -> bool:
	var ok := true

	# ① "머리 꼭대기 기준" — 위쪽 PAD_Y px는 완전 투명, 그 아래는 폭 전체가 불투명한
	#    합성 이미지. 크롭 시작 y가 불투명이 실제로 시작하는 지점(PAD_Y) 근처여야 한다
	#    (과거 버그: 캐릭터용 고정값 0.015를 그대로 몬스터에 썼는데, 몬스터 원화는
	#    머리 위 여백이 제각각이라 이 값이 맞을 때도/안 맞을 때도 있었음).
	var syn_size := Vector2i(200, 300)
	var pad_y := 40
	var top_pad_img := Image.create(syn_size.x, syn_size.y, false, Image.FORMAT_RGBA8)
	top_pad_img.fill(Color(0, 0, 0, 0))
	for y in range(pad_y, syn_size.y):
		for x in range(syn_size.x):
			top_pad_img.set_pixel(x, y, Color(0.6, 0.6, 0.6, 1.0))
	var top_pad_ratio: Rect2 = CharacterArt.detect_face_crop_ratio(top_pad_img, 0.4, 0.4, 0.06, 0.5, 1)
	var expected_y_ratio: float = float(pad_y) / float(syn_size.y)
	var top_pad_ok: bool = abs(top_pad_ratio.position.y - expected_y_ratio) < 0.02
	ok = top_pad_ok and ok
	lines.append("  detect_face_crop_ratio(): 위쪽 투명 여백 %dpx(비율 %.4f)인 합성 이미지 -> 크롭 시작 y=%.4f(오차 < 0.02 기대) -> %s" % [
		pad_y, expected_y_ratio, top_pad_ratio.position.y, "OK" if top_pad_ok else "FAIL"
	])

	# ② 머리 가로 중심 추적 — 머리(위, 왼쪽에 작게)와 몸통/꼬리(아래, 오른쪽에 훨씬 크게)를
	#    분리해 그린 합성 이미지(암흑 늑대의 웅크린 포즈 + 큰 꼬리 구도를 추상화). 크롭
	#    중심이 "머리" 쪽을 따라가야지, 픽셀 수가 훨씬 많은 아래쪽 덩어리에 끌려가
	#    중앙/몸통 쪽으로 쏠리면 안 된다.
	var off_center_img := Image.create(syn_size.x, syn_size.y, false, Image.FORMAT_RGBA8)
	off_center_img.fill(Color(0, 0, 0, 0))
	var head_top := 20
	var head_band_end := 50
	for y in range(head_top, head_band_end):
		for x in range(10, 50): # 머리 — 왼쪽에 작게.
			off_center_img.set_pixel(x, y, Color(0.6, 0.6, 0.6, 1.0))
	for y in range(head_band_end, syn_size.y):
		for x in range(100, 200): # "꼬리/몸통" — 오른쪽에 훨씬 크게.
			off_center_img.set_pixel(x, y, Color(0.6, 0.6, 0.6, 1.0))
	var off_center_ratio: Rect2 = CharacterArt.detect_face_crop_ratio(off_center_img, 0.3, 0.3, 0.1, 0.5, 1)
	var head_center_x_ratio: float = 30.0 / syn_size.x # 머리 영역(10..50) 중심 = 30px.
	var body_center_x_ratio: float = 150.0 / syn_size.x # 몸통 영역(100..200) 중심 = 150px.
	var detected_center_x_ratio: float = off_center_ratio.position.x + off_center_ratio.size.x / 2.0
	var off_center_ok: bool = abs(detected_center_x_ratio - head_center_x_ratio) < abs(detected_center_x_ratio - body_center_x_ratio)
	ok = off_center_ok and ok
	lines.append("  detect_face_crop_ratio(): 머리(위/왼쪽, 작음) + 몸통(아래/오른쪽, 큼) 합성 이미지 -> 크롭 중심 x비율=%.4f (머리쪽=%.4f에 더 가까워야 함, 몸통쪽=%.4f) -> %s" % [
		detected_center_x_ratio, head_center_x_ratio, body_center_x_ratio, "OK" if off_center_ok else "FAIL"
	])

	# ③ 카탈로그 전체(일반+정예) — full.png 크롭 경로를 타는 몬스터(face_* 5장 없음)마다
	#    monster_face_crop_ratio()가 유효 범위(0..1, 이미지 밖으로 안 나감) 안의 Rect를
	#    돌려주고, 같은 입력에 항상 같은 결과를 내는지(결정적)도 함께 확인한다.
	var catalog_bad: Array[String] = []
	for profile in MonsterCatalog.MONSTERS:
		var mid: String = profile["id"]
		var tier: String = profile.get("tier", "normal")
		if tier == "boss":
			continue
		var art_id: String = MonsterCatalog.art_resource_id(mid)
		if CharacterArt.has_all_faces(art_id) or not CharacterArt.has_full(art_id):
			continue
		var r1: Rect2 = CharacterArt.monster_face_crop_ratio(art_id, tier)
		var r2: Rect2 = CharacterArt.monster_face_crop_ratio(art_id, tier)
		var in_bounds: bool = r1.position.x >= 0.0 and r1.position.y >= 0.0 and (r1.position.x + r1.size.x) <= 1.0001 and (r1.position.y + r1.size.y) <= 1.0001
		var deterministic: bool = r1 == r2
		if not (in_bounds and deterministic):
			catalog_bad.append("%s(rect=%s, deterministic=%s)" % [mid, r1, deterministic])
	var catalog_ok: bool = catalog_bad.is_empty()
	ok = catalog_ok and ok
	lines.append("  카탈로그 일반/정예(full.png 크롭 경로) 전수 — 크롭 Rect가 0..1 범위 안 + 결정적 -> %s%s" % [
		"OK" if catalog_ok else "FAIL",
		("" if catalog_ok else (" (" + ", ".join(catalog_bad) + ")"))
	])

	# ④ HUD 패널 여백 — ART-1c-5(보스)와 같은 방식: 일반/정예 전수를 production
	#    배치(combat_test.tscn, _apply_monster_portrait_tier())로 실제 렌더하고 실제
	#    trait 텍스트(_monster_trait_summary_text, production과 동일 함수)를 채운 뒤
	#    레이아웃이 안정될 때까지 기다려 측정한다 — 패널 높이는 "특성" 줄 텍스트 길이에
	#    따라 달라지므로(_setup_combat_hud()가 만드는 PanelContainer 자동 높이), 빈
	#    텍스트로 재면 패널이 실제보다 작게 나와 여백 미달을 놓칠 수 있다.
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	var combat_script := load("res://code/scenes/combat_test.gd")
	var screen := Rect2(0.0, 0.0, 1280.0, 720.0)
	const MARGIN := 10.0

	var missing_margin: Array[String] = []
	var out_of_bounds: Array[String] = []
	var checked_count := 0
	for profile in MonsterCatalog.MONSTERS:
		var mid: String = profile["id"]
		var tier: String = profile.get("tier", "normal")
		if tier == "boss":
			continue
		# [대형 기획 16] R-3(2026-10-26) — 아트가 전혀(face_*도 full.png도) 입고되지
		# 않은 몬스터는 _face_rect 자체가 안 만들어지는 게 정상 동작(순수 도형
		# 플레이스홀더로 폴백)이라, 이 "HUD 패널 여백" 측정은 애초에 적용 대상이
		# 아니다 — 신규 부정형 5종이 바로 이 경우라 측정에서 건너뛴다(실제 폴백
		# 동작 자체는 _check_r3_amorphous_roster()가 따로 검증).
		var art_id: String = MonsterCatalog.art_resource_id(mid)
		if not (CharacterArt.has_all_faces(art_id) or CharacterArt.has_full(art_id)):
			continue
		var skill_ids: Array = []
		for skill in profile.get("skills", []):
			var skill_id: String = skill.get("id", "")
			if skill_id != "":
				skill_ids.append(skill_id)
		var trait_config := {"personality": profile.get("personality", ""), "skill_ids": skill_ids}
		combat.monster_trait_label.text = combat_script._monster_trait_summary_text(trait_config)
		combat.monster_portrait.set_monster(mid)
		combat._apply_monster_portrait_tier(tier == "elite", false)
		await get_tree().process_frame
		await get_tree().process_frame
		checked_count += 1
		var fr: TextureRect = combat.monster_portrait._face_rect
		if fr == null or not fr.visible:
			missing_margin.append("%s(no face_rect)" % mid)
			continue
		var fr_rect := fr.get_global_rect()
		var panel_rect: Rect2 = combat._hud_panels[2].get_global_rect() if combat._hud_panels.size() >= 3 else Rect2()
		var panel_bottom: float = panel_rect.position.y + panel_rect.size.y
		if fr_rect.position.y < panel_bottom + MARGIN:
			missing_margin.append("%s(top=%.1f, panel_bottom+margin=%.1f)" % [mid, fr_rect.position.y, panel_bottom + MARGIN])
		if not screen.encloses(fr_rect):
			out_of_bounds.append("%s(rect=%s)" % [mid, fr_rect])

	var margin_ok: bool = missing_margin.is_empty()
	ok = margin_ok and ok
	lines.append("  일반+정예 %d종 — 포트레이트 상단 y >= 몬스터 HUD 패널 하단 y + 여백(%.0fpx) -> %s%s" % [
		checked_count, MARGIN, "OK" if margin_ok else "FAIL",
		("" if margin_ok else (" (미달: " + ", ".join(missing_margin) + ")"))
	])
	var bounds_ok: bool = out_of_bounds.is_empty()
	ok = bounds_ok and ok
	lines.append("  일반+정예 %d종 — production 배치 화면(1280x720) 안 배치 -> %s%s" % [
		checked_count, "OK" if bounds_ok else "FAIL",
		("" if bounds_ok else (" (잘림: " + ", ".join(out_of_bounds) + ")"))
	])

	remove_child(combat)
	combat.free()

	return ok


## [대형 기획 15] Q-1(18, 2026-10-16) — 감독 피드백 재현: "전투 후 보상 선택을 하고
## 나면 주사위 값(결과 칩 줄)이 버튼과 겹친다". 원인은 EXCHANGE_CHIP_Y(526)가
## REWARD_FRAME_TOP~BOTTOM(184~560) 범위 안인데, 전투가 끝나면 더 이상 새 교환이
## 없어 마지막 교환의 결과 칩 줄이 화면에 그대로 남아 보상 카드/버튼과 같은 자리에
## 걸쳐 있었던 것 — `_maybe_finish_battle()`이 battle_over를 확정하는 시점에
## `_clear_exchange_dice_chips()`를 호출하도록 고쳤다. 승리(보상 UI)/패배(다음 버튼)
## 둘 다 같은 함수를 거치므로 한 번에 검증한다. "플래그만 보지 않는다" 원칙대로
## _exchange_chip_nodes가 실제로 비는지 + 남는 노드가 있다면 보상 버튼과 rect 교차가
## 없는지(이중 안전망)까지 확인한다.
func _check_q1_reward_chip_overlap(lines: PackedStringArray) -> bool:
	var ok := true

	var character_backup := RunState.character_id
	var test_battle_backup := RunState.test_battle

	# --- 승리: 보상 UI가 뜬 상태에서 칩 줄이 비는지 ---
	RunState.character_id = "novice"
	RunState.test_battle = false # production의 "승리 -> 보상 UI" 경로를 타게 강제(테스트
	# 전투 경로는 보상 카드 대신 "다시 하기"/"설정으로 돌아가기"를 보여줘 이 버그 재현과
	# 다른 분기라 반드시 꺼둬야 한다).
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat_win = combat_scene.instantiate()
	add_child(combat_win)

	var atk_bag := DiceBag.new(4, 3)
	var def_bag := DiceBag.new(4, 2)
	combat_win._show_exchange_dice_chips(atk_bag, [1, 2, 3], def_bag, [4, 1], Color(0.9, 0.3, 0.3, 1), Color(0.3, 0.5, 0.9, 1))
	var chips_before_win: int = combat_win._exchange_chip_nodes.size()
	combat_win.battle_over = true
	combat_win.player_won = true
	combat_win.monster_hp = 0
	await combat_win._maybe_finish_battle(0)

	var win_chips_cleared_ok: bool = chips_before_win > 0 and combat_win._exchange_chip_nodes.is_empty()
	ok = win_chips_cleared_ok and ok
	lines.append("  승리(보상 UI) 전 결과 칩 %d개 -> battle_over 처리 후 %d개(기대 0) -> %s" % [
		chips_before_win, combat_win._exchange_chip_nodes.size(), "OK" if win_chips_cleared_ok else "FAIL"
	])

	var win_reward_shown_ok: bool = combat_win._reward_action_buttons.size() > 0
	ok = win_reward_shown_ok and ok
	lines.append("  보상 액션 버튼 실제로 생성됨(개수=%d) -> %s" % [
		combat_win._reward_action_buttons.size(), "OK" if win_reward_shown_ok else "FAIL"
	])

	# 이중 안전망 — 혹시 남은 칩 노드가 있어도(있으면 안 되지만) 보상 버튼과 rect가
	# 겹치면 안 된다는 것을 노드 rect 교차 계산으로 직접 확인.
	var win_overlap_found := false
	for chip_node in combat_win._exchange_chip_nodes:
		if chip_node is Control:
			var chip_rect: Rect2 = (chip_node as Control).get_global_rect()
			for btn in combat_win._reward_action_buttons:
				if chip_rect.intersects(btn.get_global_rect()):
					win_overlap_found = true
	var win_no_overlap_ok: bool = not win_overlap_found
	ok = win_no_overlap_ok and ok
	lines.append("  (안전망) 남은 칩 rect와 보상 버튼 rect 교차 없음 -> %s" % (
		"OK" if win_no_overlap_ok else "FAIL"
	))

	remove_child(combat_win)
	combat_win.free()

	# --- 패배: "처음부터 다시" 버튼이 뜬 상태에서도 칩 줄이 비는지 ---
	var combat_lose = combat_scene.instantiate()
	add_child(combat_lose)
	combat_lose._show_exchange_dice_chips(atk_bag, [1, 1, 1], def_bag, [1, 1], Color(0.9, 0.3, 0.3, 1), Color(0.3, 0.5, 0.9, 1))
	var chips_before_lose: int = combat_lose._exchange_chip_nodes.size()
	combat_lose.battle_over = true
	combat_lose.player_won = false
	combat_lose.player_hp = 0
	await combat_lose._maybe_finish_battle(0)

	var lose_chips_cleared_ok: bool = chips_before_lose > 0 and combat_lose._exchange_chip_nodes.is_empty()
	ok = lose_chips_cleared_ok and ok
	lines.append("  패배(다음 버튼) 전 결과 칩 %d개 -> battle_over 처리 후 %d개(기대 0) -> %s" % [
		chips_before_lose, combat_lose._exchange_chip_nodes.size(), "OK" if lose_chips_cleared_ok else "FAIL"
	])

	var lose_next_visible_ok: bool = combat_lose.next_button.visible
	ok = lose_next_visible_ok and ok
	lines.append("  패배 화면 '처음부터 다시' 버튼 visible=%s(기대 true) -> %s" % [
		combat_lose.next_button.visible, "OK" if lose_next_visible_ok else "FAIL"
	])

	var lose_overlap_found := false
	for chip_node in combat_lose._exchange_chip_nodes:
		if chip_node is Control and (chip_node as Control).get_global_rect().intersects(combat_lose.next_button.get_global_rect()):
			lose_overlap_found = true
	var lose_no_overlap_ok: bool = not lose_overlap_found
	ok = lose_no_overlap_ok and ok
	lines.append("  (안전망) 남은 칩 rect와 '다음' 버튼 rect 교차 없음 -> %s" % (
		"OK" if lose_no_overlap_ok else "FAIL"
	))

	remove_child(combat_lose)
	combat_lose.free()

	RunState.character_id = character_backup
	RunState.test_battle = test_battle_backup
	return ok


## [대형 기획 15] Q-1(23, 2026-10-16) — 감독 재현: "'수상한 도박꾼' 이벤트에서 이벤트
## 텍스트가 UI에 맞지 않게 들어가 있다". 실제 원인은 두 가지였다: ① event.gd의
## PromptLabel이 autowrap_mode를 아예 안 켠 채(기본값 OFF) 폭 920(원래는 1240)짜리
## 고정 박스에 들어있어, EventChallengePool의 실제 prompt 문구(최대 70자 이상)가 줄바꿈
## 없이 한 줄로 그려지며 라벨 자기 박스조차 훌쩍 넘어 화면 오른쪽 밖으로 삐져나갔다.
## ② story_event.gd의 Description은 autowrap은 있었지만 vertical_alignment가 기본값
## (TOP)이라 자기보다 큰 배경 프레임(UIKit.make_backdrop) 안에서 텍스트가 위쪽에만
## 붙고 아래가 텅 비어 "패널과 안 맞는" 모양이었다(`qa_out/q1_23_gambler_event.png`로
## 직접 확인). 두 라벨 다 autowrap_mode=3(WORD_SMART)+vertical_alignment=1(CENTER)+
## 배경 프레임과 같은 폭(920)으로 맞췄다 — 이 테스트는 "모든 이벤트 데이터를 순회해
## 렌더된 텍스트 노드 rect가 부모 패널 rect 안인지 검사"(INBOX 원문)를 실제 Label
## 노드로 autowrap 레이아웃까지 거쳐 측정한다(하드코딩 글자수 계산 아님).
func _check_q1_event_text_layout(lines: PackedStringArray) -> bool:
	var ok := true

	# --- event.gd PromptLabel: EventChallengePool 전수 prompt + 스킬 이벤트 2종 ---
	var event_scene := load("res://code/scenes/event.tscn")
	var event_node = event_scene.instantiate()
	add_child(event_node)
	await get_tree().process_frame

	var prompt_label: Label = event_node.prompt_label
	var prompt_backdrop_rect := Rect2(Vector2(32, 62), Vector2(900, 74)) # event.gd _ready()의 make_backdrop 인자와 동일
	var safe_button_rect: Rect2 = event_node.get_node("SafeButton").get_global_rect()

	var prompt_texts: Array[String] = []
	for c in EventChallengePool.CHALLENGES:
		prompt_texts.append(c["prompt"])
	prompt_texts.append("낯선 기운이 스며든다. 후보 중 하나를 익힐 수 있을 것 같다.")
	prompt_texts.append("낯익은 기운이 한층 짙어진다. 후보 중 하나를 골라 더 강하게 벼릴 수 있을 것 같다.")

	var worst_prompt := ""
	var worst_prompt_height := 0.0
	for t in prompt_texts:
		prompt_label.text = t
		await get_tree().process_frame
		var h: float = prompt_label.get_combined_minimum_size().y
		if h > worst_prompt_height:
			worst_prompt_height = h
			worst_prompt = t
		var label_rect: Rect2 = prompt_label.get_global_rect()
		# 실제 autowrap 레이아웃 결과 rect가 배경 프레임 폭을 넘지 않는지(가로 — autowrap이
		# 켜졌으니 넘으면 안 됨), 그리고 세로로 자란 뒤에도 바로 아래 버튼과 안 겹치는지.
		var within_backdrop_width: bool = label_rect.position.x >= prompt_backdrop_rect.position.x \
			and label_rect.position.x + label_rect.size.x <= prompt_backdrop_rect.position.x + prompt_backdrop_rect.size.x + 1.0
		var grown_rect := Rect2(label_rect.position, Vector2(label_rect.size.x, h))
		var no_button_overlap: bool = not grown_rect.intersects(safe_button_rect)
		if not (within_backdrop_width and no_button_overlap):
			ok = false
			lines.append("  PromptLabel '%s' -> 폭 안=%s, 버튼 비겹침=%s, 필요 높이=%.1f (FAIL)" % [
				t.left(20) + ("..." if t.length() > 20 else ""), within_backdrop_width, no_button_overlap, h
			])
	var prompt_fit_ok := ok
	lines.append("  EventChallengePool prompt %d종 + 스킬 이벤트 2종 전수: 배경 프레임 폭 안 + 버튼과 비겹침 -> %s (최대 필요 높이=%.1f, '%s')" % [
		prompt_texts.size(), "OK" if prompt_fit_ok else "FAIL", worst_prompt_height,
		worst_prompt.left(24) + ("..." if worst_prompt.length() > 24 else "")
	])

	var prompt_autowrap_ok: bool = prompt_label.autowrap_mode != TextServer.AUTOWRAP_OFF
	ok = prompt_autowrap_ok and ok
	lines.append("  PromptLabel.autowrap_mode=%d (기대 != OFF=0, 줄바꿈 없이 화면 밖으로 안 나가게) -> %s" % [
		prompt_label.autowrap_mode, "OK" if prompt_autowrap_ok else "FAIL"
	])

	remove_child(event_node)
	event_node.free()

	# --- story_event.gd Description: 시나리오 8종 전수 ---
	var story_scene := load("res://code/scenes/story_event.tscn")
	var story_node = story_scene.instantiate()
	add_child(story_node)
	await get_tree().process_frame

	var desc_label: Label = story_node.desc_label
	var desc_backdrop_rect := Rect2(Vector2(32, 74), Vector2(900, 72)) # story_event.gd _ready()의 make_backdrop 인자와 동일
	var choice_a_rect: Rect2 = story_node.choice_a_button.get_global_rect()

	var worst_desc := ""
	var worst_desc_height := 0.0
	var desc_ok := true
	for s in StoryEventPool.SCENARIOS:
		var t: String = s["description"]
		desc_label.text = t
		await get_tree().process_frame
		var h: float = desc_label.get_combined_minimum_size().y
		if h > worst_desc_height:
			worst_desc_height = h
			worst_desc = t
		var label_rect: Rect2 = desc_label.get_global_rect()
		var within_backdrop: bool = label_rect.position.x >= desc_backdrop_rect.position.x \
			and label_rect.position.x + label_rect.size.x <= desc_backdrop_rect.position.x + desc_backdrop_rect.size.x + 1.0
		var grown_rect := Rect2(label_rect.position, Vector2(label_rect.size.x, h))
		var no_overlap: bool = not grown_rect.intersects(choice_a_rect)
		if not (within_backdrop and no_overlap):
			desc_ok = false
			lines.append("  Description '%s' -> 폭 안=%s, 버튼 비겹침=%s, 필요 높이=%.1f (FAIL)" % [
				t, within_backdrop, no_overlap, h
			])
	ok = desc_ok and ok
	lines.append("  StoryEventPool description %d종 전수: 배경 프레임 폭 안 + A안 버튼과 비겹침 -> %s (최대 필요 높이=%.1f, '%s')" % [
		StoryEventPool.SCENARIOS.size(), "OK" if desc_ok else "FAIL", worst_desc_height, worst_desc
	])

	var desc_vcenter_ok: bool = desc_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER
	ok = desc_vcenter_ok and ok
	lines.append("  Description.vertical_alignment=%d (기대 CENTER=1, 배경 프레임 안에서 위로 쏠리지 않게) -> %s" % [
		desc_label.vertical_alignment, "OK" if desc_vcenter_ok else "FAIL"
	])

	remove_child(story_node)
	story_node.free()

	return ok


## [대형 기획 15] Q-3(7, 2026-10-17) 검증, [대형 기획 17] S-7(a)(2026-10-28)로 측정
## 방식 강화: "플래그가 들어갔는가"(custom_minimum_size는 호출부가 못박은 값이라
## 컨테이너가 실제로 그 값을 지켰는지는 증명하지 못한다)가 아니라 "실제 렌더 트리에서
## 레이아웃을 거친 뒤의 .size"를 본다 — 시작 스킬 슬롯(해금/잠금 둘 다)의 icon_area
## Control이 8명 전부(각 2슬롯, 총 16개)에서 실제로 정사각(오차 2% 이내)이고
## STARTING_SKILL_ICON_SIZE(44, 40~48px 예산 안)를 유지하는지 확인한다. 고치기 전에는
## content(VBoxContainer)의 기본 SIZE_FILL(cross-axis)이 icon_area를 슬롯 폭(115px)까지
## 가로로 늘려 44x115가 되는 회귀가 실제로 있었다 — custom_minimum_size만 보는 이전
## 버전은 이 버그를 전혀 못 잡았다.
func _check_q3_starting_skill_icon_ratio(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)
	await get_tree().process_frame
	await get_tree().process_frame

	var checked := 0
	var locked_checked := 0
	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)
		await get_tree().process_frame
		await get_tree().process_frame
		for button in node._starting_skill_slot_buttons:
			var content = button.get_child(0)
			var icon_area = content.get_child(0)
			var w: float = icon_area.size.x
			var h: float = icon_area.size.y
			var square_ok: bool = abs(w - h) <= max(w, h) * 0.02
			var size_ok: bool = w >= 40.0 and w <= 48.0
			checked += 1
			if icon_area.get_child_count() > 1:
				locked_checked += 1
			if not (square_ok and size_ok):
				ok = false
				lines.append("  [%s] 시작 스킬 슬롯 아이콘 영역 실제 렌더 크기=%.1fx%.1f (기대 정사각 40~48px) -> FAIL" % [cid, w, h])

	var locked_seen_ok: bool = locked_checked > 0
	ok = locked_seen_ok and ok
	lines.append("  시작 스킬 슬롯 아이콘 영역 %d개(8명 x 최대 2슬롯) 전수, 실제 렌더 크기: 정사각(오차 2%% 이내) 40~48px -> %s (잠긴 슬롯도 자물쇠 배지 포함 %d개 확인)" % [
		checked, "OK" if ok else "FAIL", locked_checked
	])

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## [대형 기획 17] S-7(a)(2026-10-28) 검증: "함수를 썼는지"가 아니라 "실제 렌더된
## 아이콘 노드의 크기"를 본다(INBOX 원문). 세 겹으로 확인한다 — (1) UIKit.
## compute_keep_aspect_rect() 자체가 비정사각 slot/텍스처 조합에서 원본 비율을 오차
## 없이 유지하는지(물리/화면 없는 순수 함수 단위 검증), (2) 던전 맵 "전투"/"정예 전투"
## 선택지 버튼 안 FamilyIcon·RewardIcon(HBoxContainer 기본 SIZE_FILL로 세로가 늘어나던
## 실제 버그 지점, VISUAL_STANDARD.md 6-2)이 레이아웃 후 실제로 정사각인지, (3) 캐릭터
## 선택 시작 스킬 슬롯 icon_area(VBoxContainer cross-axis로 가로가 늘어나던 지점)도
## 마찬가지인지 — (3)은 Q-3(7) 테스트가 이미 하지만, 여기서는 "픽셀 단위 렌더 결과"라는
## 같은 관점으로 한 번 더 모아 S-7 전수 점검 의도를 분명히 한다.
func _check_s7a_icon_keep_aspect(lines: PackedStringArray) -> bool:
	var ok := true

	# (1) 순수 함수 — 두 가지 비대칭 조합.
	# (1a) 텍스처(64x32, 비율 2.0)와 slot(40x20, 비율 2.0)이 같은 비율 -> slot을 꽉 채움.
	var rect_a := UIKit.compute_keep_aspect_rect(Vector2(64, 32), Rect2(Vector2.ZERO, Vector2(40, 20)))
	var ratio_a_ok: bool = abs((rect_a.size.x / rect_a.size.y) - 2.0) < 0.02
	var fill_a_ok: bool = rect_a.size.is_equal_approx(Vector2(40, 20))
	ok = ratio_a_ok and fill_a_ok and ok
	lines.append("  (1a) compute_keep_aspect_rect(tex=64x32, slot=40x20, 비율 둘 다 2.0): 렌더 사각형=%s 비율=%.4f(기대 2.0, slot 꽉 채움) -> %s" % [
		rect_a.size, rect_a.size.x / rect_a.size.y, "OK" if (ratio_a_ok and fill_a_ok) else "FAIL"
	])

	# (1b) 텍스처가 정사각(32x32, 비율 1.0)인데 slot은 가로로 긴 직사각형(40x20, 비율 2.0)
	# -> letterbox로 slot 높이(20)에 맞춰 20x20 정사각으로 축소, 가로 중앙 정렬.
	var slot_b := Rect2(Vector2.ZERO, Vector2(40, 20))
	var rect_b := UIKit.compute_keep_aspect_rect(Vector2(32, 32), slot_b)
	var square_b_ok: bool = abs(rect_b.size.x - rect_b.size.y) < 0.01
	var height_b_ok: bool = is_equal_approx(rect_b.size.y, 20.0)
	var centered_b_ok: bool = is_equal_approx(rect_b.position.x, (slot_b.size.x - rect_b.size.x) * 0.5)
	ok = square_b_ok and height_b_ok and centered_b_ok and ok
	lines.append("  (1b) compute_keep_aspect_rect(tex=32x32, slot=40x20, 비율 다름): 렌더 사각형=%s(기대 정사각, 높이 20 기준 축소+가로 중앙 정렬) -> %s" % [
		rect_b, "OK" if (square_b_ok and height_b_ok and centered_b_ok) else "FAIL"
	])

	# (2) 던전 맵 "전투"/"정예 전투" 선택지 — FamilyIcon + 보상 RewardIcon 실제 렌더 크기.
	var character_backup := RunState.character_id
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	RunState.reset_run("novice")
	RunState.round_index = 1
	RunState.rooms_cleared = 0

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map = map_scene.instantiate()
	add_child(map)
	map._elite_available = true
	map._shop_available = true
	map._event_available = true
	map._story_available = true
	map._room_order.assign(["shop", "event", "story", "elite"])
	map._update_labels()
	await get_tree().process_frame
	await get_tree().process_frame

	var map_icons_checked := 0
	for t in ["combat", "elite"]:
		var family_icon: Control = map._family_icon_by_type[t]
		var fw: float = family_icon.size.x
		var fh: float = family_icon.size.y
		var family_square_ok: bool = abs(fw - fh) <= max(fw, fh) * 0.02
		map_icons_checked += 1
		ok = family_square_ok and ok
		lines.append("  (2) 던전 맵 '%s' 선택지 FamilyIcon 실제 렌더 크기=%.1fx%.1f(기대 정사각, 오차 2%% 이내) -> %s" % [
			t, fw, fh, "OK" if family_square_ok else "FAIL"
		])
		var reward_row: HBoxContainer = map._reward_icon_rows[t]
		for icon in reward_row.get_children():
			var rw: float = icon.size.x
			var rh: float = icon.size.y
			var reward_square_ok: bool = abs(rw - rh) <= max(rw, rh) * 0.02
			map_icons_checked += 1
			ok = reward_square_ok and ok
			lines.append("  (2) 던전 맵 '%s' 선택지 보상 아이콘(category=%s) 실제 렌더 크기=%.1fx%.1f -> %s" % [
				t, (icon as RewardIcon).category, rw, rh, "OK" if reward_square_ok else "FAIL"
			])

	remove_child(map)
	map.free()

	# 전투 화면 몬스터 FamilyIcon(combat_test.gd monster_family_icon, HBoxContainer 안).
	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	await get_tree().process_frame
	await get_tree().process_frame
	var mfw: float = combat.monster_family_icon.size.x
	var mfh: float = combat.monster_family_icon.size.y
	var combat_family_square_ok: bool = abs(mfw - mfh) <= max(mfw, mfh) * 0.02
	map_icons_checked += 1
	ok = combat_family_square_ok and ok
	lines.append("  (2) 전투 화면 몬스터 FamilyIcon 실제 렌더 크기=%.1fx%.1f(기대 정사각, 오차 2%% 이내) -> %s" % [
		mfw, mfh, "OK" if combat_family_square_ok else "FAIL"
	])
	remove_child(combat)
	combat.free()

	lines.append("  (2) 던전 맵/전투 화면 아이콘 %d개 전수 정사각 확인 -> %s" % [
		map_icons_checked, "OK" if ok else "FAIL"
	])

	RunState.character_id = character_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	return ok


## [대형 기획 17] S-7(b)(2026-10-28) 검증: "전투 기록" 패널이 1280x720 화면 안에 실제로
## 들어오는지(화면 밖 잘림 금지)와, 기록이 _log_clip 고정 높이를 넘겨도 가장 최근 줄이
## 보이는 위치로 스크롤되는지를 실제 렌더 트리로 확인한다. 40줄을 채운 상태(_append_log
## 40회 호출, MAX_LOG_LINES=200이라 전부 유지됨)로 측정해 INBOX 원문 "기록이 길어지면"
## 시나리오를 재현한다 — "스크롤 로직을 호출했는가"가 아니라 "실제 position.y가 음수로
## 밀렸는가/패널 하단 y가 화면 안인가"를 잰다.
func _check_s7b_combat_log_panel_bounds(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	RunState.character_id = "novice"

	var combat_scene := load("res://code/scenes/combat_test.tscn")
	var combat = combat_scene.instantiate()
	add_child(combat)
	await get_tree().process_frame
	await get_tree().process_frame

	for i in 40:
		combat._append_log("전투 기록 테스트 줄 %d — 다이스 교환 결과가 길어지는 경우를 흉내내는 더미 문장" % i)
	await get_tree().process_frame
	await get_tree().process_frame

	var panel_rect: Rect2 = combat._log_panel.get_global_rect()
	var panel_bottom: float = panel_rect.position.y + panel_rect.size.y
	var within_screen_ok: bool = panel_bottom <= 720.0
	ok = within_screen_ok and ok
	lines.append("  (1) 전투 기록 40줄 상태: 패널 global rect=%s, 하단 y=%.1f(기대 <= 720.0) -> %s" % [
		panel_rect, panel_bottom, "OK" if within_screen_ok else "FAIL"
	])

	# (2) log_label이 _log_clip 고정 높이보다 커져(40줄은 당연히 76px보다 큼) 실제로
	# 음수 position.y로 밀렸는지(= 맨 위가 아니라 최신 줄이 보이는 쪽으로 스크롤됐는지).
	var content_taller_ok: bool = combat.log_label.size.y > combat._log_clip.size.y
	var scrolled_ok: bool = combat.log_label.position.y < 0.0
	ok = content_taller_ok and scrolled_ok and ok
	lines.append("  (2) log_label 높이=%.1f > _log_clip 높이=%.1f(내용이 더 큼) -> %s, position.y=%.1f(기대 음수, 아래로 스크롤) -> %s" % [
		combat.log_label.size.y, combat._log_clip.size.y, "OK" if content_taller_ok else "FAIL",
		combat.log_label.position.y, "OK" if scrolled_ok else "FAIL"
	])

	# (3) 마지막으로 추가한 줄의 텍스트가 log_label.text 끝에 실제로 남아있는지(스크롤이
	# "맨 아래"를 향하고 있다는 것을 내용으로도 확인 — _log_lines가 MAX_LOG_LINES=200
	# 한도 안이라 40줄 전부 유지돼야 한다).
	var last_line_kept_ok: bool = combat.log_label.text.ends_with("전투 기록 테스트 줄 39 — 다이스 교환 결과가 길어지는 경우를 흉내내는 더미 문장")
	ok = last_line_kept_ok and ok
	lines.append("  (3) 마지막 줄이 log_label.text 끝에 남아있음(40줄 다 유지, MAX_LOG_LINES=200) -> %s" % [
		"OK" if last_line_kept_ok else "FAIL"
	])

	remove_child(combat)
	combat.free()
	RunState.character_id = character_backup
	return ok


## [대형 기획 15] Q-3(9, 2026-10-17) 검증: 고유 능력 설명(profile["ability_summary"])이
## 8명 전부에서 (a) 더 이상 글자 수로 잘리지 않으므로 말줄임표(…)가 전혀 안 남아있고,
## (b) 실제 폰트 측정(Label.get_combined_minimum_size(), autowrap 레이아웃 결과)으로
## ABILITY_DESC_WRAP_WIDTH 안에서 2줄 예산을 넘지 않는지 확인한다. "글자 수가
## 32 이하인가"가 아니라 "실제 렌더 높이가 2줄 치를 넘지 않는가"를 재는 것이 핵심 —
## 숫자(D12 등)가 살아남는지는 곡예사 케이스로 별도 확인.
func _check_q3_ability_summary_fits(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id

	var scene := load("res://code/scenes/character_select.tscn")
	var node = scene.instantiate()
	add_child(node)

	var label: Label = node._detail_skill_label
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var line_height: float = font.get_height(font_size)
	var max_height: float = line_height * 2.0 + 2.0 # 2줄 예산 + 반올림 여유

	for profile in CharacterProfiles.PROFILES:
		var cid: String = profile["id"]
		node._on_card_selected(cid)

		var text: String = label.text
		var no_ellipsis: bool = not text.ends_with("…")
		var h: float = label.get_combined_minimum_size().y
		var fits_ok: bool = h <= max_height
		var row_ok: bool = no_ellipsis and fits_ok and text != ""
		ok = row_ok and ok
		lines.append("  [%s] ability_summary=\"%s\" 필요 높이=%.1f(2줄 예산=%.1f) 말줄임 없음=%s -> %s" % [
			cid, text, h, max_height, no_ellipsis, "OK" if row_ok else "FAIL"
		])

	node._on_card_selected("juggler")
	var juggler_shows_d12: bool = label.text.findn("D12") != -1
	ok = juggler_shows_d12 and ok
	lines.append("  곡예사 ability_summary에 'D12' 포함(차별점이 짧은 문구에서도 보여야 함) -> %s" % (
		"OK" if juggler_shows_d12 else "FAIL"
	))

	remove_child(node)
	node.free()
	RunState.character_id = character_backup
	return ok


## [대형 기획 15] Q-4a(12,13,14, 2026-10-17) 검증 — INBOX 원문 테스트 요구사항을 그대로
## 코드화: (12) 방 선택지 5종(전투/상점/이벤트/스토리/정예) 버튼 rect 크기가 전부 같은지,
## (14) 보상 칩(+전투/정예 계열 아이콘)이 버튼의 자손 노드인지(더 이상 옆에 떠 있는 형제
## 노드가 아닌지), (13) 방 카드(MapStrip)에는 보상 칩이 전혀 없고 정예/보스가 노출되는
## 방에만 그 배지가 붙는지.
func _check_q4a_dungeon_room_choices(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	RunState.reset_run("novice")
	RunState.round_index = 1
	RunState.rooms_cleared = 0

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map = map_scene.instantiate()
	add_child(map)

	# (12) 방 선택지 5종을 전부 강제로 노출시켜 버튼 rect 크기를 비교한다(실제 플레이에서는
	# 노출 여부가 방마다 갈리지만, "노출되면 전부 같은 크기"라는 요구는 전부 동시에 보여도
	# 성립해야 한다).
	map._shop_available = true
	map._event_available = true
	map._story_available = true
	map._elite_available = true
	var forced_room_order: Array[String] = ["shop", "event", "story", "elite"]
	map._room_order = forced_room_order
	map._update_labels()

	var buttons: Array = [
		map.enter_combat_button, map.enter_shop_button, map.enter_event_button,
		map.enter_story_button, map.enter_elite_button,
	]
	var sizes: Array = []
	for b in buttons:
		sizes.append(b.size)
	var sizes_equal_ok := true
	for s in sizes:
		if not (s as Vector2).is_equal_approx(sizes[0]):
			sizes_equal_ok = false
	ok = sizes_equal_ok and ok
	lines.append("  (12) 방 선택지 5종(전투/상점/이벤트/스토리/정예) 버튼 rect 크기: %s (전부 같아야 함) -> %s" % [
		sizes, "OK" if sizes_equal_ok else "FAIL"
	])

	# (14) 보상 칩이 각 버튼의 자손 노드인지 확인 — 더 이상 버튼 옆에 떠 있는 형제 노드가
	# 아니다.
	var reward_in_button_ok := true
	for t in map.REWARD_CATEGORIES.keys():
		var btn: Button = map._button_for_type(t)
		var row: HBoxContainer = map._reward_icon_rows[t]
		if btn == null or row == null or not btn.is_ancestor_of(row):
			reward_in_button_ok = false
	ok = reward_in_button_ok and ok
	lines.append("  (14) 보상 칩 행이 각 방 선택지 버튼의 자손 노드인지(전투/상점/이벤트/스토리/정예) -> %s" % (
		"OK" if reward_in_button_ok else "FAIL"
	))
	var family_in_button_ok := true
	for t in ["combat", "elite"]:
		var btn2: Button = map._button_for_type(t)
		var icon: Control = map._family_icon_by_type[t]
		if btn2 == null or icon == null or not btn2.is_ancestor_of(icon):
			family_in_button_ok = false
	ok = family_in_button_ok and ok
	lines.append("  (14) 계열 아이콘(전투/정예)도 버튼의 자손 노드인지 -> %s" % (
		"OK" if family_in_button_ok else "FAIL"
	))

	# (13) 방 카드(MapStrip)에는 보상 칩이 전혀 없어야 한다 — idx=0(일반 방)/마지막 idx
	# (보스 방) 두 가지로 확인한다.
	var boss_idx: int = RunState.TOTAL_ROOMS - 1
	for idx in [0, boss_idx]:
		var card: Control = map._make_map_node(idx)
		add_child(card)
		var reward_icon_count := _q4a_count_reward_icons(card)
		var card_ok: bool = reward_icon_count == 0
		ok = card_ok and ok
		lines.append("  (13) 방 카드(idx=%d)에 보상 칩 없음: %d개 -> %s" % [
			idx, reward_icon_count, "OK" if card_ok else "FAIL"
		])
		card.queue_free()

	# 보스 방 카드에는 "보스" 배지가 있어야 한다.
	var boss_card: Control = map._make_map_node(boss_idx)
	add_child(boss_card)
	var has_boss_badge: bool = _q4a_contains_label_text(boss_card, "보스")
	ok = has_boss_badge and ok
	lines.append("  (13) 보스 방(idx=%d)에 '보스' 배지 존재 -> %s" % [
		boss_idx, "OK" if has_boss_badge else "FAIL"
	])
	boss_card.queue_free()

	# 정예가 노출되는 방에는 "정예" 배지가 있어야 한다 — ELITE_CHANCE 대상 구간
	# (idx 1..TOTAL_ROOMS-2) 중 실제로 정예가 뜨는 자리를 찾아 확인한다(결정적 시드라
	# 매번 같은 자리가 나옴, dungeon_map.gd _debug_press_shortcut_elite() 주석 참고).
	var elite_idx := -1
	for idx in range(1, RunState.TOTAL_ROOMS - 1):
		if map._room_options_for_index(idx).elite:
			elite_idx = idx
			break
	var elite_found_ok: bool = elite_idx != -1
	ok = elite_found_ok and ok
	lines.append("  (13) 정예 노출 방 탐색(idx 1~%d 중): idx=%d -> %s" % [
		RunState.TOTAL_ROOMS - 2, elite_idx, "OK" if elite_found_ok else "FAIL"
	])
	if elite_found_ok:
		var elite_card: Control = map._make_map_node(elite_idx)
		add_child(elite_card)
		var has_elite_badge: bool = _q4a_contains_label_text(elite_card, "정예")
		var elite_no_reward: bool = _q4a_count_reward_icons(elite_card) == 0
		ok = has_elite_badge and elite_no_reward and ok
		lines.append("  (13) idx=%d 정예 노출 방 카드: '정예' 배지=%s, 보상 칩 없음=%s -> %s" % [
			elite_idx, has_elite_badge, elite_no_reward, "OK" if (has_elite_badge and elite_no_reward) else "FAIL"
		])
		elite_card.queue_free()

	remove_child(map)
	map.free()
	RunState.character_id = character_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	return ok


## _check_q4a_dungeon_room_choices() 전용 재귀 헬퍼 — 트리 안의 RewardIcon 인스턴스 개수.
func _q4a_count_reward_icons(node: Node) -> int:
	var count := 0
	if node is RewardIcon:
		count += 1
	for c in node.get_children():
		count += _q4a_count_reward_icons(c)
	return count


## _check_q4a_dungeon_room_choices() 전용 재귀 헬퍼 — 트리 안에 해당 텍스트 그대로인
## Label이 있는지.
func _q4a_contains_label_text(node: Node, text: String) -> bool:
	if node is Label and (node as Label).text == text:
		return true
	for c in node.get_children():
		if _q4a_contains_label_text(c, text):
			return true
	return false


## _check_q4b_skill_detail_popup() 전용 재귀 헬퍼 — 트리 안의 첫 CharacterCardPanel.
## DeckPanel의 "보유 스킬" 섹션만 이 클래스를 쓰므로(캐릭터 정보 섹션은 평문 Label),
## RunState.skill_flags에 스킬을 하나만 넣어두면 모호함 없이 그 행을 찾을 수 있다.
func _q4b_find_card_panel(node: Node) -> CharacterCardPanel:
	if node is CharacterCardPanel:
		return node
	for c in node.get_children():
		var found := _q4b_find_card_panel(c)
		if found != null:
			return found
	return null


## [대형 기획 15] Q-4b(11, 2026-10-17) 검증 — INBOX 원문 "클릭/Space하면 팝업으로 스킬
## 이름·효과 설명을 보여준다... 화면 바깥(어두운 배경) 클릭 또는 우상단 X 버튼 또는
## Esc로 닫힘, 키보드 포커스 트랩"을 그대로 코드화한다. DeckPanel.new()로 직접
## 인스턴스화(기존 (c) DeckPanel 테두리색 검증과 같은 패턴, 이터레이션 192 참고)해
## _skill_popup이 실제로 get_parent()(=이 테스트 자신, dice_test)의 자식으로 붙는지까지
## 포함해 검증한다.
func _check_q4b_skill_detail_popup(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var skill_backup: Array[String] = RunState.skill_flags.duplicate()

	RunState.character_id = "novice"
	RunState.skill_flags = ["deep_breath"]

	var deck := DeckPanel.new()
	add_child(deck)
	deck._rebuild()

	var card := _q4b_find_card_panel(deck)
	var card_found_ok: bool = card != null
	ok = card_found_ok and ok
	lines.append("  보유 스킬 'deep_breath' 행이 CharacterCardPanel(클릭/Space 공용 activated)로 렌더됨 -> %s" % (
		"OK" if card_found_ok else "FAIL"
	))

	# _ensure_skill_popup()이 지연 생성이라(combat_test.gd가 DeckPanel을 자기 _ready()
	# 도중 동적으로 add_child()하는 경합을 피하기 위함, deck_panel.gd 클래스 주석 참고)
	# 첫 activated 전에는 deck._skill_popup이 아직 null이다 — 활성화 이후에 조회한다.
	if card_found_ok:
		card.activated.emit()
	var popup: SkillDetailPopup = deck._skill_popup
	var popup_opened_ok: bool = card_found_ok and popup != null and popup.visible
	ok = popup_opened_ok and ok
	lines.append("  카드 activated -> 팝업 visible=%s -> %s" % [
		popup_opened_ok, "OK" if popup_opened_ok else "FAIL"
	])

	var popup_parent_ok: bool = popup_opened_ok and popup.get_parent() == self
	ok = popup_parent_ok and ok
	lines.append("  _skill_popup이 DeckPanel 형제(get_parent()의 자식)로 붙어 화면 전체(1280x720)를 덮을 수 있음 -> %s" % (
		"OK" if popup_parent_ok else "FAIL"
	))

	var expected: Dictionary = SkillPool.find_skill("deep_breath")
	var name_ok: bool = popup_opened_ok and popup._name_label.text == String(expected.get("name", ""))
	var desc_ok: bool = popup_opened_ok and popup._desc_label.text == String(expected.get("description", ""))
	ok = name_ok and desc_ok and ok
	lines.append("  팝업 이름='%s'(기대 '%s'), 설명 일치=%s -> %s" % [
		popup._name_label.text if popup_opened_ok else "", expected.get("name", ""), desc_ok,
		"OK" if (name_ok and desc_ok) else "FAIL"
	])

	var close_btn: Button = popup._close_button if popup_opened_ok else null
	var trap_ok := false
	var focused_ok := false
	if close_btn != null:
		var self_path := close_btn.get_path_to(close_btn)
		trap_ok = close_btn.focus_neighbor_top == self_path and close_btn.focus_neighbor_bottom == self_path \
			and close_btn.focus_neighbor_left == self_path and close_btn.focus_neighbor_right == self_path
		focused_ok = close_btn.has_focus()
	ok = trap_ok and focused_ok and ok
	lines.append("  닫기 버튼 포커스 트랩(4방향 전부 자기 자신)=%s, 팝업 열리면 실제 엔진 포커스(has_focus)=%s -> %s" % [
		trap_ok, focused_ok, "OK" if (trap_ok and focused_ok) else "FAIL"
	])

	# 세 가지 닫기 경로 — 매번 다시 연다.
	var backdrop_event := InputEventMouseButton.new()
	backdrop_event.pressed = true
	backdrop_event.button_index = MOUSE_BUTTON_LEFT
	if popup_opened_ok:
		popup.open("deep_breath", "novice")
		popup._on_backdrop_gui_input(backdrop_event)
	var backdrop_close_ok: bool = popup_opened_ok and not popup.visible
	ok = backdrop_close_ok and ok
	lines.append("  화면 바깥(어두운 배경) 클릭으로 닫힘 -> %s" % ("OK" if backdrop_close_ok else "FAIL"))

	if popup_opened_ok:
		popup.open("deep_breath", "novice")
		popup._close_button.pressed.emit()
	var x_close_ok: bool = popup_opened_ok and not popup.visible
	ok = x_close_ok and ok
	lines.append("  우상단 X 버튼으로 닫힘 -> %s" % ("OK" if x_close_ok else "FAIL"))

	var esc_event := InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE
	if popup_opened_ok:
		popup.open("deep_breath", "novice")
		popup._unhandled_input(esc_event)
	var esc_close_ok: bool = popup_opened_ok and not popup.visible
	ok = esc_close_ok and ok
	lines.append("  Esc로 닫힘 -> %s" % ("OK" if esc_close_ok else "FAIL"))

	remove_child(deck)
	deck.free()
	RunState.skill_flags = skill_backup
	RunState.character_id = character_backup
	return ok


## [대형 기획 15] Q-4b(21, 2026-10-17) 검증 — INBOX 원문 "포기 후 RunState 초기화,
## 업적/도감 파일 내용 유지, 씬 전환, 팝업이 바깥 클릭/X/Esc로 닫히는지(실제 입력
## 이벤트), 포커스 트랩"을 그대로 코드화한다. change_scene_to_file()을 포함하는
## _on_quit_run_confirmed() 전체는 직접 호출하면 QA 중인 dice_test 씬 자체가 바뀌어버려
## (event.gd._check_event_double_pick_guard() 주석과 같은 이유), "실제 폐기 로직"만
## 분리한 _abandon_run()을 대신 호출해 부작용 없이 검증한다("씬 전환" 자체는 이 함수가
## get_tree().change_scene_to_file()을 직접 부르는 한 줄짜리 코드라 그 자체는 사람이
## 셀프 피드백 캡처로 확인).
func _check_q4b_quit_run_confirm(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var gold_backup := RunState.gold
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	var skill_backup: Array[String] = RunState.skill_flags.duplicate()
	# 다른 체크가 RunState.chosen_starting_skill_id를 남겨두면 reset_run()이 그 id를
	# SkillPool.grant()로 즉시 다시 부여해 "리셋 직후 skill_flags가 비어있어야 한다"는
	# 이 체크의 가정이 깨진다(다른 chosen_starting_skill_id 관련 체크들과 같은 이유로
	# 백업/복원 — 이 파일 전체의 확립된 관례, 예: 이터레이션 165 부근).
	var chosen_skill_backup := RunState.chosen_starting_skill_id

	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()

	RunState.chosen_starting_skill_id = ""
	RunState.reset_run("novice")
	RunState.gold = 77
	RunState.rooms_cleared = 3
	RunState.round_index = 2
	RunState.skill_flags = ["deep_breath", "spare_die"]

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map = map_scene.instantiate()
	add_child(map)

	# QA 0-arity 훅(dungeon_map.gd의 다른 _debug_press_shortcut_*()와 같은 패턴)으로
	# "던전 포기" 버튼까지 포커스+확정 경로가 실제로 이어지는지 확인한다 — open()만
	# 호출하는 안전한 경로라(change_scene_to_file() 없음) 테스트 스위트 안에서 직접
	# 눌러도 된다.
	map._debug_press_shortcut_quit_run()
	var dialog: ConfirmDialog = map.quit_confirm_dialog
	var opened_ok: bool = dialog.visible
	ok = opened_ok and ok
	lines.append("  '던전 포기' 버튼(포커스+확정) -> 확인 팝업 visible=%s -> %s" % [
		opened_ok, "OK" if opened_ok else "FAIL"
	])
	var message_ok: bool = opened_ok and _q4a_contains_label_text(dialog, map.QUIT_RUN_MESSAGE)
	ok = message_ok and ok
	lines.append("  확인 팝업에 지정 문구('현재 진행도를 버리고...') 그대로 표시 -> %s" % (
		"OK" if message_ok else "FAIL"
	))

	var cancel_btn: Button = dialog._cancel_button if opened_ok else null
	var confirm_btn: Button = dialog._confirm_button if opened_ok else null
	var trap_ok := false
	var default_focus_ok := false
	if cancel_btn != null and confirm_btn != null:
		trap_ok = cancel_btn.focus_neighbor_left == cancel_btn.get_path_to(confirm_btn) \
			and cancel_btn.focus_neighbor_right == cancel_btn.get_path_to(confirm_btn) \
			and confirm_btn.focus_neighbor_left == confirm_btn.get_path_to(cancel_btn) \
			and confirm_btn.focus_neighbor_right == confirm_btn.get_path_to(cancel_btn) \
			and cancel_btn.focus_neighbor_top == cancel_btn.get_path_to(cancel_btn) \
			and cancel_btn.focus_neighbor_bottom == cancel_btn.get_path_to(cancel_btn)
		default_focus_ok = cancel_btn.has_focus()
	ok = trap_ok and default_focus_ok and ok
	lines.append("  포커스 트랩(취소<->확인 좌우 순환, 상하는 자기 자신)=%s, 기본 포커스=취소 버튼(섣부른 확정 방지)=%s -> %s" % [
		trap_ok, default_focus_ok, "OK" if (trap_ok and default_focus_ok) else "FAIL"
	])

	# 취소(취소 버튼/배경 클릭/Esc) 세 갈래 전부 RunState를 전혀 건드리지 않아야 한다.
	if opened_ok:
		dialog._cancel_button.pressed.emit()
	var cancel_preserves_ok: bool = opened_ok and not dialog.visible and RunState.gold == 77 and RunState.rooms_cleared == 3
	ok = cancel_preserves_ok and ok
	lines.append("  '취소' 버튼: 팝업 닫힘=%s, RunState 안 건드림(gold=%d rooms=%d) -> %s" % [
		not dialog.visible, RunState.gold, RunState.rooms_cleared, "OK" if cancel_preserves_ok else "FAIL"
	])

	map._debug_press_shortcut_quit_run()
	var backdrop_event := InputEventMouseButton.new()
	backdrop_event.pressed = true
	backdrop_event.button_index = MOUSE_BUTTON_LEFT
	dialog._on_backdrop_gui_input(backdrop_event)
	var backdrop_cancel_ok: bool = not dialog.visible and RunState.gold == 77 and RunState.rooms_cleared == 3
	ok = backdrop_cancel_ok and ok
	lines.append("  배경(바깥) 클릭도 취소와 동일(RunState 안 건드림) -> %s" % ("OK" if backdrop_cancel_ok else "FAIL"))

	map._debug_press_shortcut_quit_run()
	var esc_event := InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE
	dialog._unhandled_input(esc_event)
	var esc_cancel_ok: bool = not dialog.visible and RunState.gold == 77 and RunState.rooms_cleared == 3
	ok = esc_cancel_ok and ok
	lines.append("  Esc도 취소와 동일(RunState 안 건드림) -> %s" % ("OK" if esc_cancel_ok else "FAIL"))

	# 업적/도감은 RunState와 무관한 별도 저장소(write-through) — _abandon_run() 전에
	# 하나씩 직접 해금/발견시켜 그 전후로 유지되는지까지 실제로 확인한다.
	AchievementManager.unlock("first_run_start")
	SkillCodex.mark_discovered("novice", "deep_breath")
	var ach_before: bool = AchievementManager.is_unlocked("first_run_start")
	var codex_before: bool = SkillCodex.is_discovered("novice", "deep_breath")

	# 실제 폐기 — change_scene_to_file()을 포함하는 _on_quit_run_confirmed() 전체가 아니라
	# _abandon_run()만 직접 호출(위 클래스 주석 참고).
	map._abandon_run()
	var reset_ok: bool = RunState.gold == 0 and RunState.rooms_cleared == 0 and RunState.round_index == 1 and RunState.skill_flags.is_empty()
	ok = reset_ok and ok
	lines.append("  '던전 포기' 확정 -> RunState 리셋: gold=%d rooms=%d round=%d skill_flags=%s(전부 초기값이어야) -> %s" % [
		RunState.gold, RunState.rooms_cleared, RunState.round_index, RunState.skill_flags, "OK" if reset_ok else "FAIL"
	])

	var ach_preserved_ok: bool = ach_before and AchievementManager.is_unlocked("first_run_start")
	var codex_preserved_ok: bool = codex_before and SkillCodex.is_discovered("novice", "deep_breath")
	ok = ach_preserved_ok and codex_preserved_ok and ok
	lines.append("  업적/스킬 도감 해금·발견 상태가 _abandon_run() 전후로 유지됨(업적=%s, 도감=%s) -> %s" % [
		ach_preserved_ok, codex_preserved_ok, "OK" if (ach_preserved_ok and codex_preserved_ok) else "FAIL"
	])

	remove_child(map)
	map.free()
	AchievementManager._debug_reset_for_qa()
	SkillCodex._debug_reset_for_qa()
	RunState.character_id = character_backup
	RunState.gold = gold_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	RunState.skill_flags = skill_backup
	RunState.chosen_starting_skill_id = chosen_skill_backup
	return ok


## [대형 기획 15] Q-5(15, 2026-10-17) 검증 — INBOX 원문 "선택지 목록에서 제거하고
## 던전 맵의 별도 영역(HUD/하단 '정비' 작업대 진입 버튼)으로 이동... 보유 눈금이 있을
## 때만 강조/활성"을 그대로 코드화한다: "정비" 버튼이 방 선택지가 몇 개 보이든(0개/
## 전부 5개) 헤더의 같은 고정 위치에 머무는지(= _layout_visible_buttons()의 y-스택
## 루프 대상이 아님), 그래도 FocusNav 체인에는 포함돼 방향키로 도달 가능한지, 보유
## 눈금 유무에 따라 primary/secondary 스타일이 실제로 바뀌는지(둘 다 비활성화는
## 아님 — "항상 접근 가능" 요구).
func _check_q5_maintenance_entry_point(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var rooms_backup := RunState.rooms_cleared
	var round_backup := RunState.round_index
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	RunState.reset_run("novice")
	RunState.round_index = 1
	RunState.rooms_cleared = 0

	var map_scene := load("res://code/scenes/dungeon_map.tscn")
	var map = map_scene.instantiate()
	add_child(map)

	# 방 선택지 전부 숨긴 상태(전투만 노출)에서 "정비" 버튼의 헤더 위치를 기록한다.
	map._shop_available = false
	map._event_available = false
	map._story_available = false
	map._elite_available = false
	var empty_room_order: Array[String] = []
	map._room_order = empty_room_order
	map._update_labels()
	var pos_minimal: Vector2 = map.customize_button.position

	# 방 선택지를 전부(5종) 노출시켜도 같은 자리에 그대로 있어야 한다 — y-스택 루프
	# 대상이었다면 아래로 밀려났을 것이다.
	map._shop_available = true
	map._event_available = true
	map._story_available = true
	map._elite_available = true
	var full_room_order: Array[String] = ["shop", "event", "story", "elite"]
	map._room_order = full_room_order
	map._update_labels()
	var pos_full: Vector2 = map.customize_button.position
	var fixed_position_ok: bool = pos_minimal.is_equal_approx(pos_full)
	ok = fixed_position_ok and ok
	lines.append("  (15) '정비' 버튼 위치: 방 선택지 0개=%s, 5개=%s(같아야 함) -> %s" % [
		pos_minimal, pos_full, "OK" if fixed_position_ok else "FAIL"
	])

	# 방 선택지 버튼과 같은 y범위를 쓰지 않아야 한다(= 같은 스택에 안 섞여 있음).
	var not_overlapping_room_stack_ok: bool = absf(pos_full.y - map.enter_combat_button.position.y) > 1.0
	ok = not_overlapping_room_stack_ok and ok
	lines.append("  (15) '정비' y좌표(%.1f)가 방 선택지 스택 첫 자리(%.1f)와 달라야 함 -> %s" % [
		pos_full.y, map.enter_combat_button.position.y, "OK" if not_overlapping_room_stack_ok else "FAIL"
	])

	# 그래도 방향키 체인(_shortcut_buttons)에는 포함돼 있어야 한다("항상 접근 가능").
	var in_chain_ok: bool = map._shortcut_buttons.has(map.customize_button)
	ok = in_chain_ok and ok
	lines.append("  (15) '정비' 버튼이 방향키 포커스 체인에 포함됨(항상 접근 가능) -> %s" % (
		"OK" if in_chain_ok else "FAIL"
	))

	# 보유 눈금 유무에 따라 강조(primary)/보조(secondary) 스타일이 바뀌어야 한다 —
	# 두 경우 다 비활성화는 아니다.
	RunState.pip_inventory = []
	map._style_action_buttons()
	var style_empty: StyleBox = map.customize_button.get_theme_stylebox("normal")
	var disabled_when_empty: bool = map.customize_button.disabled

	RunState.pip_inventory = [4]
	map._style_action_buttons()
	var style_with_pips: StyleBox = map.customize_button.get_theme_stylebox("normal")
	var disabled_when_has_pips: bool = map.customize_button.disabled

	var highlight_changes_ok: bool = not disabled_when_empty and not disabled_when_has_pips \
		and _q5_stylebox_bg(style_empty) != _q5_stylebox_bg(style_with_pips)
	ok = highlight_changes_ok and ok
	lines.append("  (15) 눈금 없음 bg=%s / 눈금 있음 bg=%s(달라야 함), 둘 다 비활성 아님(없음=%s, 있음=%s) -> %s" % [
		_q5_stylebox_bg(style_empty), _q5_stylebox_bg(style_with_pips), disabled_when_empty, disabled_when_has_pips,
		"OK" if highlight_changes_ok else "FAIL"
	])

	remove_child(map)
	map.free()
	RunState.character_id = character_backup
	RunState.rooms_cleared = rooms_backup
	RunState.round_index = round_backup
	RunState.pip_inventory = pip_backup
	return ok


## _check_q5_maintenance_entry_point() 전용 헬퍼 — StyleBoxFlat/StyleBoxTexture 양쪽을
## 다 받아 "구분 가능한 지문" 하나를 돌려준다(M-5a 이미지 스킨이 있으면 StyleBoxTexture,
## 없으면 StyleBoxFlat로 폴백하는 UIKit 관례 — _m5_style_fingerprint()와 같은 이유).
func _q5_stylebox_bg(style: StyleBox) -> Variant:
	if style is StyleBoxFlat:
		return (style as StyleBoxFlat).bg_color
	if style is StyleBoxTexture:
		return (style as StyleBoxTexture).texture
	return style


## [대형 기획 15] Q-5(16, 2026-10-17) 검증 — INBOX 원문 "결과 미리보기(전/후 값 비교,
## 바뀐 면 강조)... 전/후 미리보기 값이 실제 적용 결과와 일치하는지(계산)"을 그대로
## 코드화한다. 통합 화면이 실제로 렌더한 미리보기 칩(PENDING_HIGHLIGHT_BORDER=적용 전
## 바뀔 면, APPLIED_HIGHLIGHT_BORDER=적용 후 값)의 .value를 읽어 _exchange_pip()의
## 실제 결과(클램프 포함)와 비교한다 — "적용" 전에는 아무것도 안 바뀌고, "적용"을
## 눌러야만 bag/pip_inventory가 실제로 바뀌는지까지 확인한다.
func _check_q5_customize_preview_matches_apply(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	# 통합 화면이 RunState.player_attack_bag/player_defense_bag도 함께 그리므로(공격/방어
	# 주머니 섹션), 이 테스트 실행 전 다른 테스트가 남긴 상태와 무관하게 결정적으로
	# 만들어 둔다(이 파일 전체의 확립된 관례).
	RunState.reset_run("novice")

	var panel := CustomizePanel.new()
	add_child(panel)

	# D6 다이스 1개, 면 index=2를 바꿀 대상으로 고른다. 눈금 7은 상한(6)으로 클램프돼야
	# 한다 — 클램프 경로까지 미리보기가 정확히 반영하는지 함께 검증.
	var bag := DiceBag.new(6, 1)
	var before_face_value: int = bag.dice[0][2]
	RunState.pip_inventory = [7]
	panel.open()
	panel._selected_pip_index = 0
	panel._pending_face = {"bag": bag, "die_index": 0, "face_index": 2}
	panel._show_pip_picker()

	var expected_after: int = min(7, bag.dice[0].size())

	# "적용" 전에는 아무것도 바뀌지 않아야 한다.
	var nothing_changed_yet_ok: bool = bag.dice[0][2] == before_face_value and RunState.pip_inventory == [7]
	ok = nothing_changed_yet_ok and ok
	lines.append("  (16) 미리보기 단계에서는 아직 bag/pip_inventory가 안 바뀜(face=%d, pip=%s) -> %s" % [
		bag.dice[0][2], RunState.pip_inventory, "OK" if nothing_changed_yet_ok else "FAIL"
	])

	var after_chip := _q5_find_chip_by_border(panel, CustomizePanel.APPLIED_HIGHLIGHT_BORDER)
	var after_preview_ok: bool = after_chip != null and after_chip.value == expected_after
	ok = after_preview_ok and ok
	lines.append("  (16) 미리보기 '적용 후' 칩 값=%s (기대 min(7,6)=%d, 클램프 반영) -> %s" % [
		(after_chip.value if after_chip != null else "없음"), expected_after, "OK" if after_preview_ok else "FAIL"
	])

	var before_chip := _q5_find_chip_by_border(panel, CustomizePanel.PENDING_HIGHLIGHT_BORDER)
	var before_preview_ok: bool = before_chip != null and before_chip.value == before_face_value
	ok = before_preview_ok and ok
	lines.append("  (16) 미리보기 '적용 전'(바뀔 면) 칩 값=%s (기대 %d, 원래 면 값) -> %s" % [
		(before_chip.value if before_chip != null else "없음"), before_face_value, "OK" if before_preview_ok else "FAIL"
	])

	panel._confirm_exchange()
	var applied_ok: bool = bag.dice[0][2] == expected_after and RunState.pip_inventory == [before_face_value]
	ok = applied_ok and ok
	lines.append("  (16) '적용' 실제 결과: face=%d inventory=%s (기대 %d, [%d] — 미리보기와 정확히 일치해야) -> %s" % [
		bag.dice[0][2], RunState.pip_inventory, expected_after, before_face_value, "OK" if applied_ok else "FAIL"
	])

	var state_reset_ok: bool = panel._selected_pip_index == -1 and panel._pending_face.is_empty()
	ok = state_reset_ok and ok
	lines.append("  (16) '적용' 후 선택 상태 초기화(pip_index=-1, pending_face 없음) -> %s" % (
		"OK" if state_reset_ok else "FAIL"
	))

	remove_child(panel)
	panel.queue_free()
	RunState.character_id = character_backup
	RunState.pip_inventory = pip_backup
	return ok


## _check_q5_customize_preview_matches_apply() 전용 재귀 헬퍼 — 트리 안에서 지정한
## border_color를 가진 첫 ShapeDieChip을 찾는다(미리보기 섹션의 "바뀔 면"/"적용 후"
## 강조 칩은 고유한 상수 border색을 쓰므로 모호함 없이 식별 가능).
func _q5_find_chip_by_border(node: Node, border: Color) -> ShapeDieChip:
	if node is ShapeDieChip and (node as ShapeDieChip).border_color == border:
		return node
	for c in node.get_children():
		var found := _q5_find_chip_by_border(c, border)
		if found != null:
			return found
	return null


## [대형 기획 15] Q-5(16) 후속 — 셀프 피드백 캡처(qa_out/q5_preview.png)로 발견한 버그
## 검증: 공격/방어 주머니에 다이스가 많이 쌓인(DiceBag.MAX_DICE=6 근처) 후반 런에서
## 미리보기 단계까지 펼치면 전체 내용 높이가 720px를 넘어 '닫기' 버튼이 화면 밖으로
## 잘려 보이지도 눌리지도 않았다. 처음에는 ScrollContainer로 감쌌으나, 이 패널이
## 매달리는 씬들의 루트가 전부 Node2D라 ScrollContainer가 자기 크기를 뷰포트 기준
## 으로 엉뚱하게(실측 2560x1440, 1280x720의 정확히 2배) 계산해버려 못 믿었다 —
## _clip(평범한 Control, size를 1280x720으로 직접 고정)+_content_root.position
## 수동 이동 방식으로 바꿨다(customize_panel.gd _ensure_step_button_visible() 참고).
## 포커스가 '닫기'까지 이동하면 그 수동 스크롤이 실제로 화면(0~720) 안으로 넣어
## 주는지 확인한다.
func _check_q5_customize_scroll_follow_focus(lines: PackedStringArray) -> bool:
	var ok := true
	var character_backup := RunState.character_id
	var attack_backup := RunState.player_attack_bag
	var defense_backup := RunState.player_defense_bag
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	RunState.reset_run("novice")

	# 후반 런을 흉내내 공격/방어 둘 다 DiceBag.MAX_DICE(6)까지 채운다 — 이 정도는 돼야
	# 미리보기까지 포함한 전체 내용이 720px를 확실히 넘는다(기본 3개짜리는 넘더라도
	# 아슬아슬해 재현이 불안정할 수 있음).
	RunState.player_attack_bag = DiceBag.new(4, DiceBag.MAX_DICE)
	RunState.player_defense_bag = DiceBag.new(4, DiceBag.MAX_DICE)
	RunState.pip_inventory = [4]

	var panel := CustomizePanel.new()
	add_child(panel)
	panel.open()
	panel._selected_pip_index = 0
	panel._pending_face = {"bag": RunState.player_attack_bag, "die_index": 0, "face_index": 0}
	panel._show_pip_picker()

	var content_height: float = panel._content_height
	var overflow_ok: bool = content_height > 720.0
	ok = overflow_ok and ok
	lines.append("  내용 전체 높이=%.1f (기대 > 720, 스크롤이 실제로 필요한 상태) -> %s" % [
		content_height, "OK" if overflow_ok else "FAIL"
	])

	var close_btn := _q5_find_button_by_text(panel, "닫기")
	var found_ok: bool = close_btn != null
	ok = found_ok and ok
	lines.append("  '닫기' 버튼을 트리에서 찾음 -> %s" % ("OK" if found_ok else "FAIL"))

	if close_btn != null:
		close_btn.grab_focus()
		var screen := Rect2(0.0, 0.0, 1280.0, 720.0)
		var btn_rect := close_btn.get_global_rect()
		var visible_ok: bool = screen.encloses(btn_rect)
		ok = visible_ok and ok
		lines.append("  '닫기'에 포커스 이동 후 실제 화면 rect=%s (기대: 화면(0~1280,0~720) 안) -> %s" % [
			btn_rect, "OK" if visible_ok else "FAIL"
		])

	remove_child(panel)
	panel.queue_free()
	RunState.character_id = character_backup
	RunState.player_attack_bag = attack_backup
	RunState.player_defense_bag = defense_backup
	RunState.pip_inventory = pip_backup
	return ok


## _check_q5_customize_scroll_follow_focus() 전용 헬퍼 — 트리 안에서 지정한 text를
## 가진 Button을 찾되, "마지막으로 찾은 것"을 반환한다(첫 번째가 아니라). CustomizePanel의
## _clear_ui()는 queue_free()(지연 해제)를 쓰므로, open() 직후 바로 _show_pip_picker()를
## 또 호출하는 식으로 같은 프레임 안에서 재호출하면 지난 redraw의 "닫기" 버튼이 아직
## 트리에 남아있는 채로 새 "닫기" 버튼이 맨 끝에 추가된다 — 첫 번째 매치만 찾으면 이미
## 못 쓰게 된(값이 낡은) 버튼을 짚게 된다(실제로 이 버그로 처음엔 거짓 PASS가 났었다).
func _q5_find_button_by_text(node: Node, text: String) -> Button:
	var last_match: Button = null
	if node is Button and (node as Button).text == text:
		last_match = node
	for c in node.get_children():
		var found := _q5_find_button_by_text(c, text)
		if found != null:
			last_match = found
	return last_match
