extends Node2D
## [대형 기획 17] S-0 시안 — 몬스터 도감 화면 개편안(S-2 중심). 고정 예시 데이터
## (MonsterCatalog 실제 데이터 6종, 필터는 전부 "전체" 상태)만 쓰는 정적 시안.
##
## 반영한 기준: VISUAL_STANDARD.md 2절이 실측으로 확인한 "티어 필터 '전체' 칩 1.86:1
## FAIL"의 직접 원인(장식 텍스처 내부 밝기 편차)을 — 이 시안에서는 아트 교체 없이
## FLAT_SKIN_DIR로 장식 자체를 내려(S-6와 같은 트릭) 글자가 깨끗한 단색 배경 위에만
## 놓이게 한다. style_primary_button의 contrasting_text_color()는 원래도 단색
## 배경을 전제로 설계돼 있어, 장식만 없어지면 코드 변경 없이 바로 기준(4.5:1)을
## 통과한다(VISUAL_STANDARD.md 2-2 표의 "코드 레벨 통과" 사례와 동일 메커니즘).

const CHARACTER_ID := "novice"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.05, 0.06, 1.0)
	backdrop.size = Vector2(1280, 720)
	add_child(backdrop)

	var panel := PanelContainer.new()
	var skinned := UIKit.apply_panel_skin(panel, "overlay", CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)
	if not skinned:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.12, 0.96)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(40, 30)
	panel.size = Vector2(1200, 660)
	add_child(panel)
	CharacterTheme.apply(panel, CHARACTER_ID, false)

	var title := Label.new()
	title.text = "몬스터 도감 — 21 / 21종"
	title.position = Vector2(70, 40)
	title.add_theme_font_size_override("font_size", 18)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	_build_filter_row()
	_build_grid()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(70, 84, 520, 32), "number": 1, "label": "필터 줄(좌/우)"},
		{"rect": Rect2(70, 130, 1128, 140), "number": 2, "label": "카드 격자(4방향)"},
	])


func _build_filter_row() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(70, 84)
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_make_filter_chip(row, "전체", true)
	for fam_id in MonsterCatalog.family_ids():
		_make_filter_chip(row, MonsterCatalog.FAMILIES[fam_id]["name"], false)
	row.add_child(VSeparator.new())
	_make_filter_chip(row, "전체", true)
	for tier_label in ["일반", "정예", "보스"]:
		_make_filter_chip(row, tier_label, false)


func _make_filter_chip(parent: Node, text: String, active: bool) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 30)
	if active:
		UIKit.style_primary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	else:
		UIKit.style_secondary_button(btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	parent.add_child(btn)


func _build_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(70, 130)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)

	var sample_ids := ["slime", "goblin", "orc", "dark_knight", "armored_goblin", "bandit"]
	for mid in sample_ids:
		var monster := MonsterCatalog.get_by_id(mid)
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.14, 0.16)
		style.set_border_width_all(1)
		style.border_color = Color(0.35, 0.35, 0.38)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", style)
		card.custom_minimum_size = Vector2(178, 120)
		grid.add_child(card)

		var vbox := VBoxContainer.new()
		card.add_child(vbox)
		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 4)
		vbox.add_child(header)
		var family_icon := FamilyIcon.new()
		family_icon.category = monster.get("family", "")
		family_icon.custom_minimum_size = Vector2(16, 16)
		family_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		family_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(family_icon)
		var tier_label := Label.new()
		tier_label.text = "일반"
		tier_label.add_theme_font_size_override("font_size", 11)
		tier_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
		header.add_child(tier_label)

		var name_label := Label.new()
		name_label.text = String(monster.get("name", mid))
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
		vbox.add_child(name_label)

		var status_label := Label.new()
		status_label.text = "원화 ✓ · 표정 0/5"
		status_label.add_theme_font_size_override("font_size", 11)
		status_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.6))
		vbox.add_child(status_label)
