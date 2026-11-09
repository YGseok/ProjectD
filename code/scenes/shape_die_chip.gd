class_name ShapeDieChip
extends Control
## 전투 중 개별 다이스가 굴려서 나온 값을 "면 모양"별 아이콘으로 보여주는 칩.
## INBOX.md 피드백(2026-09-03): "전투 시 어떤 주사위에서 어떤 값이 나왔는지, 이미지로
## 보이면 좋을 것 같다 (세모 안에 숫자 4, 네모 안에 숫자 5 등, 사면체는 세모,
## 육면체는 네모)". 면 개수(sides)와 실제 면 모양(삼각/사각/오각)의 대응은
## code/dice/die_d4.gd가 만드는 실제 지오메트리를 따른다: D4/D8/D20 = 삼각형 면,
## D6 = 사각형 면, D10 = 연꼴(사각형으로 근사), D12 = 오각형 면.

var value: int = 0:
	set(v):
		value = v
		if _label:
			_label.text = str(v)

var shape_sides: int = 4:
	set(v):
		shape_sides = v
		queue_redraw()

var fill_color: Color = Color(0.92, 0.88, 0.78):
	set(v):
		fill_color = v
		queue_redraw()

var border_color: Color = Color(0.15, 0.12, 0.08):
	set(v):
		border_color = v
		queue_redraw()

var font_color: Color = Color(0.15, 0.12, 0.08)

var _label: Label


## 다이스 면 개수 -> 실제 면 모양의 변(3=삼각형, 4=사각형, 5=오각형).
static func shape_sides_for_dice_sides(sides: int) -> int:
	match sides:
		4, 8, 20:
			return 3
		12:
			return 5
		_:
			return 4 # D6(정사각형), D10(연꼴 근사) 및 그 외 미확정 다면체 기본값


func _ready() -> void:
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", max(10, int(size.y * 0.42)))
	_label.add_theme_color_override("font_color", font_color)
	_label.text = str(value)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not selectable:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	add_child(_label)


func _draw() -> void:
	var n: int = max(shape_sides, 3)
	var r: float = size.x * 0.46
	var center := size * 0.5
	var start_angle := -PI / 4.0 if n == 4 else -PI / 2.0
	var points := PackedVector2Array()
	for i in n:
		var angle := start_angle + i * TAU / n
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, fill_color)
	for i in n:
		draw_line(points[i], points[(i + 1) % n], border_color, 2.0, true)
	_draw_hold_overlay(points)


## [대형 기획 18] 시험판(코어 플레이) 전용 — 플레이어 칩을 눌러 "고정"할 수 있게 한다.
## selectable=false(기본)면 기존과 완전히 같다(마우스 무시, 고정 표시 없음).
signal hold_toggled(chip: ShapeDieChip)

var selectable: bool = false:
	set(v):
		selectable = v
		mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_ALL if v else Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if v else Control.CURSOR_ARROW
		queue_redraw()

## 고정 상태 — 두꺼운 금색 테두리 + 칩 아래 짧은 막대로 표시(장식 없이 차분하게).
var held: bool = false:
	set(v):
		held = v
		queue_redraw()

## 미리보기 보정 표시(예: "0", "-1") — 몬스터 부정형 효과로 확정 시 바뀔 값을 칩 위
## 오른쪽 위에 작게 보여준다. 빈 문자열이면 표시 안 함.
var note_text: String = "":
	set(v):
		note_text = v
		queue_redraw()

const HELD_BORDER_COLOR := Color(0.95, 0.78, 0.32)


func _gui_input(event: InputEvent) -> void:
	if not selectable:
		return
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed = true
	elif event.is_action_pressed("ui_accept"):
		pressed = true
	if pressed:
		accept_event()
		hold_toggled.emit(self)


func _draw_hold_overlay(points: PackedVector2Array) -> void:
	var n := points.size()
	if held:
		for i in n:
			draw_line(points[i], points[(i + 1) % n], HELD_BORDER_COLOR, 4.0, true)
		draw_rect(Rect2(size.x * 0.25, size.y + 3.0, size.x * 0.5, 3.0), HELD_BORDER_COLOR)
	if selectable and has_focus():
		draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), Color(1, 1, 1, 0.55), false, 1.0)
	if note_text != "":
		var font := get_theme_default_font()
		var fs := 12
		var tw := font.get_string_size(note_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(size.x - tw * 0.5 - 8.0, -8.0, tw + 8.0, 16.0)
		draw_rect(box, Color(0.55, 0.12, 0.16))
		draw_string(font, Vector2(box.position.x + 4.0, box.position.y + 12.5), note_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.9))
