class_name FaceChipStyle
extends RefCounted
## 다이스 면 값을 보여주는 정사각형 칩/버튼의 공용 시각 스타일.
##
## 원래 combat_test.gd(승리 보상 화면의 커스터마이징 3단계)에만 있던
## _make_face_chip()/_style_die_face_button()을 그대로 옮긴 것 — 동작/외형 변경 없음.
## code/scenes/customize_panel.gd(어디서든 열 수 있는 커스터마이징 오버레이)가 같은
## 스타일을 재사용해야 해서, 두 곳에 같은 ~90줄을 복사하는 대신 정적 함수로 뽑아냈다.

const MAX_FACE_BG_COLOR := Color(1.0, 0.82, 0.2)
const MAX_FACE_BORDER_COLOR := Color(0.55, 0.35, 0.0)


## 클릭 불가능한 미리보기 칩(Panel+Label). is_max면(그 다이스가 낼 수 있는 최댓값을
## 이 면이 이미 보유) 금색으로 강조한다.
static func make_chip(value: int, size: float, muted: bool = false, is_max: bool = false) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(size, size)
	panel.size = Vector2(size, size)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	if muted:
		style.bg_color = Color(0.5, 0.46, 0.4)
	elif is_max:
		style.bg_color = MAX_FACE_BG_COLOR
	else:
		style.bg_color = Color(0.92, 0.88, 0.78)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = MAX_FACE_BORDER_COLOR if is_max and not muted else Color(0.15, 0.12, 0.08)
	style.set_corner_radius_all(int(size * 0.12))
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = str(value)
	label.size = Vector2(size, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(size * 0.42))
	label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75) if muted else Color(0.15, 0.12, 0.08))
	panel.add_child(label)
	return panel


## 위 칩과 같은 생김새를 가진 클릭 가능한 Button 버전 (면 선택 / 값 선택 화면에서 사용).
## is_max 강조는 make_chip()과 동일한 규칙을 따른다.
static func style_button(btn: Button, size: float, muted: bool = false, is_max: bool = false) -> void:
	btn.custom_minimum_size = Vector2(size, size)
	btn.size = Vector2(size, size)
	btn.add_theme_font_size_override("font_size", int(size * 0.42))

	var base_bg: Color
	if muted:
		base_bg = Color(0.5, 0.46, 0.4)
	elif is_max:
		base_bg = MAX_FACE_BG_COLOR
	else:
		base_bg = Color(0.92, 0.88, 0.78)
	var border_col := MAX_FACE_BORDER_COLOR if is_max and not muted else Color(0.15, 0.12, 0.08)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_bg
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.border_color = border_col
	normal.set_corner_radius_all(int(size * 0.12))

	var hover := normal.duplicate()
	hover.bg_color = base_bg.lightened(0.15) if (muted or is_max) else Color(1.0, 0.95, 0.75)

	var pressed := normal.duplicate()
	pressed.bg_color = base_bg.darkened(0.15) if (muted or is_max) else Color(0.8, 0.75, 0.6)

	var disabled := normal.duplicate()
	disabled.bg_color = base_bg if is_max else Color(0.5, 0.46, 0.4)
	disabled.border_color = border_col if is_max else Color(0.3, 0.3, 0.3)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)

	var font_color := Color(0.85, 0.82, 0.75) if muted else Color(0.15, 0.12, 0.08)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color)
