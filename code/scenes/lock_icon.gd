class_name LockIcon
extends Control
## 잠긴 콘텐츠 표시용 자물쇠 아이콘 — achievement_icon.gd/reward_icon.gd와 같은 패턴으로
## 별도 이미지 에셋 없이 _draw()만으로 그린다. [미니 기획 E]-3(INBOX.md 2026-09-17
## 기획자 결정)의 "슬롯 1은 업적 미해금 시 자물쇠 아이콘"을 위해 신설했다 —
## character_select.gd의 시작 스킬 슬롯에서만 쓰이지만, 다른 화면에서 "잠김" 표현이
## 필요해지면 그대로 재사용 가능하도록 범용 컴포넌트로 분리했다.

const BODY_COLOR := Color(0.6, 0.58, 0.55)
const KEYHOLE_COLOR := Color(0.28, 0.26, 0.24)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(20, 20)


func _draw() -> void:
	var body := Rect2(size.x * 0.18, size.y * 0.45, size.x * 0.64, size.y * 0.45)
	draw_rect(body, BODY_COLOR, true)
	var shackle_center := Vector2(size.x * 0.5, size.y * 0.42)
	draw_arc(shackle_center, size.x * 0.24, PI, TAU, 16, BODY_COLOR, size.x * 0.1)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.67), size.x * 0.07, KEYHOLE_COLOR)
