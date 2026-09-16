class_name EventDieVisual
extends Control
## RunState.event_die_sides(특수 이벤트 전용 "이벤트 주사위")의 면 값을 보여주는 칩.
## INBOX.md 2026-09-15 [미니 기획 B]-4 "이벤트 주사위는 단순하게 커스터마이징되면 안될
## 것 같다. 로마 숫자로 표기된다던가 해서 일반 눈금으로는 커스텀 불가능해야할듯" 반영.
##
## shape_die_chip.gd(ShapeDieChip)와 같은 "값이 바뀌면 라벨/모양을 다시 그리는 절차적
## Control" 패턴이지만, 두 가지로 일부러 다르게 만든다 — (1) 숫자 대신 로마 숫자
## (I/II/III/IV/V/VI)를 그려서 "이건 일반 다이스가 아니다, 커스터마이징 대상이 아니다"를
## 시각적으로도 구분하고, (2) 육각형 테두리 + 보라/금색 배색으로 공격/방어 다이스의
## 베이지색 사각/삼각 칩과 한눈에 갈린다(D6 면 개수 자체는 같지만 "특별한 다이스"라는
## 인상을 주기 위함).
##
## 이 이터레이션(4번 조각)에서는 필드(RunState.event_die_sides)와 이 시각화 컴포넌트만
## 만든다 — 실제로 이 다이스를 굴려서 판정하는 로직(난이도 체크, [미니 기획 B]-2/3)은
## 아직 없다. 지금은 character_select.gd 상세 패널에 "이벤트 주사위: D6" 정보와 함께
## 샘플 값(I) 하나를 보여주는 용도로만 쓰인다.

const ROMAN := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

var value: int = 1:
	set(v):
		value = v
		if _label:
			_label.text = _to_roman(v)
		queue_redraw()

var fill_color: Color = Color(0.32, 0.16, 0.42)
var border_color: Color = Color(0.85, 0.68, 0.25)
var font_color: Color = Color(0.92, 0.85, 0.6)

var _label: Label


## static인 이유: INBOX.md [미니 기획 B]-3(event.gd의 위험 판정 결과 문구)이 인스턴스를
## 만들지 않고도 "굴린 값 -> 로마 숫자"를 바로 얻을 수 있어야 해서(EventDieVisual._to_roman(roll)
## 형태로 직접 호출). ROMAN 상수만 참조하고 인스턴스 상태를 쓰지 않으므로 static으로 바꿔도
## 기존 호출부(_ready()/setter, dice_test.gd의 instance._to_roman() 호출 모두)는 그대로 동작한다.
static func _to_roman(v: int) -> String:
	if v >= 1 and v < ROMAN.size():
		return ROMAN[v]
	return str(v) # 로마 숫자 표를 벗어나는 값(면 개수가 10 넘는 이벤트 다이스가 생기면)은
	# 숫자로 폴백 — 표를 넓히기 전까지 빈 칩보다는 낫다.


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(30, 30)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", max(10, int(size.y * 0.4)))
	_label.add_theme_color_override("font_color", font_color)
	_label.text = _to_roman(value)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _draw() -> void:
	var r: float = size.x * 0.48
	var center := size * 0.5
	var points := PackedVector2Array()
	for i in 6:
		var angle := -PI / 2.0 + i * TAU / 6.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, fill_color)
	for i in 6:
		draw_line(points[i], points[(i + 1) % 6], border_color, 2.0, true)
