class_name KeyOverlay
extends Node2D
## [대형 기획 17] S-0/S-8 — 화면별 키 매핑 표(VISUAL_STANDARD.md 8절)를 시안 위에 번호
## 순서 + 화살표로 겹쳐 그려 "<화면>_keys.png"를 만들 때 쓴다. 평소에는 숨겨뒀다가(각
## 시안의 `_debug_show_key_overlay()`가 visible=true로 켬) QA 캡처 직전에만 보이게 한다.

## steps: [{"rect": Rect2, "number": int, "label": String}] — rect는 그 포커스 영역의
## 화면 좌표 사각형(번호 배지는 rect 중심에, 순서대로 화살표로 이어진다).
var steps: Array = []


func _draw() -> void:
	for i in steps.size():
		var s: Dictionary = steps[i]
		var rect: Rect2 = s["rect"]
		var center: Vector2 = rect.position + rect.size / 2.0
		draw_rect(rect, Color(1, 0.85, 0.2, 0.9), false, 3.0)
		if i > 0:
			var prev_rect: Rect2 = steps[i - 1]["rect"]
			var prev_center: Vector2 = prev_rect.position + prev_rect.size / 2.0
			draw_line(prev_center, center, Color(1, 0.85, 0.2, 0.85), 3.0)
			_draw_arrowhead(prev_center, center)
		draw_circle(center, 15, Color(0.95, 0.55, 0.1, 0.95))
		draw_circle(center, 15, Color(0, 0, 0, 0.8), false, 2.0)
		var font := ThemeDB.fallback_font
		var num_text: String = str(s["number"])
		draw_string(font, center + Vector2(-4.0 * num_text.length(), 6), num_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.08, 0.08, 0.08))
		var label: String = s.get("label", "")
		if label != "":
			var label_pos: Vector2 = rect.position + Vector2(0, -6)
			draw_string_outline(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
			draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.9, 0.5))


func _draw_arrowhead(from: Vector2, to: Vector2) -> void:
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := to - dir * 16.0
	var p1 := tip - dir * 10.0 + perp * 6.0
	var p2 := tip - dir * 10.0 - perp * 6.0
	var tri := PackedVector2Array([tip + dir * 10.0, p1, p2])
	draw_polygon(tri, PackedColorArray([Color(1, 0.85, 0.2, 0.95)]))


func set_steps(new_steps: Array) -> void:
	steps = new_steps
	queue_redraw()
