extends Node2D
## [대형 기획 17] S-0 시안 — 정비(커스터마이징) 화면 개편안(S-5/S-7). 고정 예시
## 데이터(보유 눈금 6개, 공격 주머니 D4 3개)만 쓰는 정적 시안.
##
## 반영한 기준:
## - S-5: 내용(눈금 목록)이 길어도 ScrollContainer 안에서만 늘어나고, "닫기" 버튼은
##   스크롤 영역 밖(화면 하단 고정)에 둬서 항상 보인다(기존엔 내용이 길면 닫기 버튼이
##   스크롤에 같이 밀려 화면 밖으로 나갈 수 있었음).
## - S-7: ShapeDieChip(눈금 칩)을 CenterContainer로 감싸 정사각 비율을 강제 유지.

const CHARACTER_ID := "novice"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	var title := Label.new()
	title.text = "정비 — 눈금/다이스 교체"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	var section := UIKit.make_section(self, "보유 눈금", CHARACTER_ID, Vector2(140, 70), MockupCommon.FLAT_SKIN_DIR)
	var panel: Control = section.get_parent()
	panel.custom_minimum_size = Vector2(1000, 520)
	panel.size = Vector2(1000, 520)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(960, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	# 눈금 18개(스크롤이 실제로 필요한 분량)를 채워 "내용이 길어져도 닫기 버튼은 항상
	# 화면 안"을 증명한다.
	for i in 18:
		var cell := CenterContainer.new()
		cell.custom_minimum_size = Vector2(40, 40)
		grid.add_child(cell)
		var chip := ShapeDieChip.new()
		chip.custom_minimum_size = Vector2(36, 36)
		chip.shape_sides = ShapeDieChip.shape_sides_for_dice_sides(4)
		chip.value = (i % 4) + 1
		cell.add_child(chip)

	var close_btn := Button.new()
	close_btn.text = "닫기"
	close_btn.position = Vector2(1100, 70)
	close_btn.size = Vector2(80, 36)
	UIKit.style_secondary_button(close_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(close_btn)

	var apply_btn := Button.new()
	apply_btn.text = "적용"
	apply_btn.position = Vector2(540, 650)
	apply_btn.size = Vector2(200, 44)
	UIKit.style_primary_button(apply_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(apply_btn)

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 70, 960, 520), "number": 1, "label": "보유 눈금 목록(위/아래)"},
		{"rect": Rect2(1100, 70, 80, 36), "number": 2, "label": "닫기(항상 보임)"},
		{"rect": Rect2(540, 650, 200, 44), "number": 3, "label": "적용"},
	])
