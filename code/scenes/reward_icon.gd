class_name RewardIcon
extends Control
## 던전 맵 방 선택지가 "어떤 보상 카테고리"를 줄 수 있는지 도형으로 보여주는 작은 아이콘.
##
## INBOX.md 피드백(2026-09-09): "선택지가 어떤 리스크인지는 보이지만 어떤 리턴(보상)을
## 주는지는 미리 알기 어렵다 — 텍스트보다 도형/기호/이미지로 표현할 것". 실제 골드/눈금
## 수치나 상점 판매 품목은 매번 달라지므로(STATUS.md 판단: "카테고리"가 더 적합해 보임),
## 여기서는 "이 방 종류는 골드 / 눈금 / 다이스 중 무엇을 줄 수 있는가"만 형태로 표시한다.
##
## category:
## - "gold": 동전 모양(원 + 안쪽 테두리 원)
## - "pip": 주사위 눈금 1개짜리 사각형(눈금 인벤토리 아이템과 같은 개념)
## - "dice": 주사위 눈금 3개짜리 사각형(다이스 아이템 — ShapeDieChip과 같은 "주사위" 은유)
## - "mystery": 물음표(무엇이 나올지 미리 알려주지 않는 방 — INBOX.md 2026-09-14
##   "특수 이벤트 선택지 옆 아이콘으로... 어떤 보상이 될지 모른다는 느낌의 물음표
##   아이콘만 있으면 될것 같다" 반영. 특수 이벤트만 매번 dice/pip 중 무엇이 나올지
##   달라져 카테고리 아이콘이 결과를 스포일링했던 것을 이걸로 대체)
## - "elite": 불꽃형 외곽선 + 해골 눈 느낌의 점 2개(INBOX.md [대형 기획 6] G-7 원문
##   "전용 아이콘(해골+불꽃 느낌)" 반영) — "정예 전투" 선택지/범례 전용.

var category: String = "gold":
	set(v):
		category = v
		queue_redraw()

const COLOR_GOLD := Color(0.85, 0.7, 0.25)
const COLOR_PIP := Color(0.3, 0.75, 0.75)
const COLOR_DICE := Color(0.55, 0.35, 0.75)
const COLOR_MYSTERY := Color(0.65, 0.65, 0.7)
const COLOR_ELITE := Color(0.85, 0.25, 0.2)
const COLOR_FACE_BG := Color(0.92, 0.88, 0.78)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(18, 18)


func _draw() -> void:
	match category:
		"gold":
			_draw_gold()
		"pip":
			_draw_die_face([Vector2(0.5, 0.5)], COLOR_PIP)
		"dice":
			_draw_die_face([Vector2(0.28, 0.28), Vector2(0.5, 0.5), Vector2(0.72, 0.72)], COLOR_DICE)
		"mystery":
			_draw_mystery()
		"elite":
			_draw_elite()
		_:
			pass


func _draw_gold() -> void:
	var r := size.x * 0.46
	var center := size * 0.5
	draw_circle(center, r, COLOR_GOLD)
	draw_arc(center, r * 0.6, 0, TAU, 16, Color(0.5, 0.38, 0.1, 0.8), 1.5)


## 원형 배지 안에 "?" 글자만 그려, "무엇이 나올지 모른다"는 느낌을 카테고리 형태(동전/
## 주사위 면)와 구별되게 표현한다.
func _draw_mystery() -> void:
	var r := size.x * 0.46
	var center := size * 0.5
	draw_circle(center, r, Color(0.22, 0.22, 0.26))
	draw_arc(center, r * 0.88, 0, TAU, 16, COLOR_MYSTERY, 1.5)
	var font := ThemeDB.fallback_font
	var font_size := int(size.y * 0.62)
	var text := "?"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(center.x - text_size.x * 0.5, center.y + text_size.y * 0.32)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, COLOR_MYSTERY)


## 불꽃형 외곽(위가 뾰족한 5각 윤곽) + 눈구멍 2개(어두운 점) — "해골+불꽃 느낌"(INBOX.md
## G-7 원문)의 "위험한 강적"을 도형으로 근사한다. family_icon.gd의 draw_colored_polygon
## 패턴을 그대로 재사용.
func _draw_elite() -> void:
	var pts := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.06),
		Vector2(size.x * 0.84, size.y * 0.42),
		Vector2(size.x * 0.68, size.y * 0.94),
		Vector2(size.x * 0.32, size.y * 0.94),
		Vector2(size.x * 0.16, size.y * 0.42),
	])
	draw_colored_polygon(pts, COLOR_ELITE)
	var eye_r := size.x * 0.07
	draw_circle(Vector2(size.x * 0.38, size.y * 0.46), eye_r, Color(0.12, 0.05, 0.05))
	draw_circle(Vector2(size.x * 0.62, size.y * 0.46), eye_r, Color(0.12, 0.05, 0.05))


## 주사위 면(둥근 사각형) 안에 dot_ratios(0..1 비율 좌표) 위치에 점을 찍어, "눈금이 있는
## 주사위 면"이라는 시각 은유로 카테고리를 표현한다 (customize_panel/shape_die_chip이
## 이미 쓰는 "면+눈금" 어휘를 재사용).
func _draw_die_face(dot_ratios: Array, dot_color: Color) -> void:
	var rect := Rect2(size.x * 0.08, size.y * 0.08, size.x * 0.84, size.y * 0.84)
	draw_rect(rect, COLOR_FACE_BG, true)
	draw_rect(rect, dot_color, false, 1.5)
	var dot_r := size.x * 0.09
	for ratio in dot_ratios:
		draw_circle(Vector2(size.x * ratio.x, size.y * ratio.y), dot_r, dot_color)
