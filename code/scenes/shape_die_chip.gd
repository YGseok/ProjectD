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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
