extends Node2D
## [대형 기획 17] S-0 시안 — 던전 맵 화면 개편안(S-5/S-6/S-7a). 고정 예시 데이터(라운드
## 2, 3번째 방, 골드 120)만 쓰는 정적 시안.
##
## 반영한 기준:
## - S-5: 오른쪽 정보 패널이 화면 폭(1280) 안에 완전히 들어오고, 선택지 줄과 범례가
##   겹치지 않게 세로 간격을 확보.
## - S-6: 장식을 FLAT_SKIN_DIR로 낮춤(character_select_mock과 동일한 근사).
## - S-7a: 보상 카테고리/계열 아이콘이 담긴 Control의 size_flags를 SHRINK로 고정해
##   컨테이너가 강제로 늘리지 못하게 함(VISUAL_STANDARD.md 6-2가 지목한 원인의 직접
##   대응) — RewardIcon/FamilyIcon 클래스 자체는 그대로 재사용(_draw 로직 변경 없음).

const CHARACTER_ID := "novice"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	_build_hud()
	_build_legend()
	_build_room_choices()
	_build_info_panel()
	MockupCommon.make_status_bar(self, "방을 선택하세요 — 방향키로 고르고 스페이스/Enter로 입장", Rect2(40, 664, 920, 40))

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _build_hud() -> void:
	var title := Label.new()
	title.text = "던전 맵"
	title.position = Vector2(40, 16)
	title.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	var bar := UIKit.make_bar(self, CHARACTER_ID, Vector2(40, 48), MockupCommon.FLAT_SKIN_DIR)
	UIKit.make_stat_chip(bar, null, "2/3", "라운드", CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)
	UIKit.make_progress_dots(bar, 5, 2, 2, CHARACTER_ID)
	var gold_icon := RewardIcon.new()
	gold_icon.category = "gold"
	gold_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gold_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIKit.make_stat_chip(bar, gold_icon, "120", "골드", CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)


func _build_legend() -> void:
	# S-5: HUD 바(y=48~92 근방)와 최소 16px 띄워 겹치지 않게.
	var legend := UIKit.make_bar(self, CHARACTER_ID, Vector2(40, 108), MockupCommon.FLAT_SKIN_DIR)
	for cat_label in [["gold", "골드"], ["pip", "눈금"], ["dice", "다이스"], ["mystery", "???"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		legend.add_child(row)
		var icon := RewardIcon.new()
		icon.category = cat_label[0]
		icon.custom_minimum_size = Vector2(16, 16)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var label := Label.new()
		label.text = cat_label[1]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		row.add_child(label)


func _build_room_choices() -> void:
	var choices := [
		{"type": "combat", "name": "전투", "categories": ["gold", "dice"], "family": "beast"},
		{"type": "shop", "name": "상점", "categories": ["gold"], "family": ""},
		{"type": "elite", "name": "정예 전투", "categories": ["gold", "pip", "dice"], "family": "undead"},
	]
	var y := 160.0
	for choice in choices:
		var btn := Button.new()
		btn.text = ""
		btn.position = Vector2(40, y)
		btn.size = Vector2(920, 56)
		if choice["type"] == "combat":
			UIKit.style_primary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		else:
			UIKit.style_secondary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		add_child(btn)

		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.position = Vector2(56, y)
		content.size = Vector2(888, 56)
		content.add_theme_constant_override("separation", 10)
		add_child(content)

		if choice["family"] != "":
			var family_icon := FamilyIcon.new()
			family_icon.category = choice["family"]
			family_icon.custom_minimum_size = Vector2(22, 22)
			# S-7a 핵심 수정 — 컨테이너 세로 FILL 기본값이 56px 행 높이로 늘려버리던
			# 것을 SHRINK로 고정해 22x22 정사각을 유지시킨다.
			family_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			family_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			content.add_child(family_icon)

		var name_label := Label.new()
		name_label.text = choice["name"]
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 15)
		content.add_child(name_label)

		var reward_row := HBoxContainer.new()
		reward_row.add_theme_constant_override("separation", 6)
		content.add_child(reward_row)
		for cat in choice["categories"]:
			var icon := RewardIcon.new()
			icon.category = cat
			icon.custom_minimum_size = Vector2(18, 18)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			reward_row.add_child(icon)

		y += 72.0


func _build_info_panel() -> void:
	# S-5 핵심 수정 — 패널 x=980, 폭 260이면 우측 끝이 1240으로 화면(1280) 안에 완전히
	# 들어온다(실제 화면에서 창 비율에 따라 잘리던 문제의 재현/수정 시안).
	var body := UIKit.make_section(self, "캐릭터", CHARACTER_ID, Vector2(980, 48), MockupCommon.FLAT_SKIN_DIR)
	var panel: Control = body.get_parent()
	panel.custom_minimum_size = Vector2(260, 600)
	panel.size = Vector2(260, 600)
	var name_label := Label.new()
	name_label.text = "견습 모험가"
	name_label.add_theme_font_size_override("font_size", 14)
	body.add_child(name_label)
	var hp_label := Label.new()
	hp_label.text = "HP 20 / 20"
	hp_label.add_theme_font_size_override("font_size", 12)
	hp_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	body.add_child(hp_label)
	var atk_label := Label.new()
	atk_label.text = "공격 주머니: D4 x3"
	atk_label.add_theme_font_size_override("font_size", 12)
	atk_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	body.add_child(atk_label)
	var def_label := Label.new()
	def_label.text = "방어 주머니: D4 x3"
	def_label.add_theme_font_size_override("font_size", 12)
	def_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	body.add_child(def_label)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(40, 160, 920, 168), "number": 1, "label": "방 선택지(위/아래 순환)"},
		{"rect": Rect2(980, 48, 260, 600), "number": 2, "label": "정보 패널(보기 전용)"},
	])
