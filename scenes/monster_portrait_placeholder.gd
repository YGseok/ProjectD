extends Node2D
class_name MonsterPortraitPlaceholder
## 몬스터 초상화 플레이스홀더. 실제 몬스터 스프라이트(INBOX.md: "몬스터 무스메들이
## 나온다")가 생기기 전까지 도형 조립으로 "이 몬스터가 지금 화나있는지/기뻐하는지"만
## 표시하는 임시 실루엣. `combat_test.gd`가 이미 몬스터별로 부여하는 색(monster_color,
## MONSTER_PROFILES)을 그대로 받아 몸 색으로 쓰므로, 이름/색 구분에 이어 표정까지
## 몬스터별로 달라 보인다.
##
## 사람 형태가 아니라 "동그란 몸 + 뿔 두 개"의 최소 몬스터 실루엣으로 플레이어
## 초상화(character_portrait_placeholder.gd)와 형태를 분명히 구분한다.

const EYE_COLOR := Color(0.12, 0.1, 0.08)
const MOUTH_COLOR := Color(0.25, 0.08, 0.08)
const HORN_COLOR := Color(0.85, 0.82, 0.75)

## "neutral" / "happy" / "hurt" / "sad" / "angry"
@export var expression: String = "neutral"
@export var body_color: Color = Color(0.5, 0.5, 0.5)


func set_expression(new_expression: String) -> void:
	expression = new_expression
	queue_redraw()


func set_body_color(color: Color) -> void:
	body_color = color
	queue_redraw()


func _draw() -> void:
	# 뿔 두 개 (몸보다 먼저 그려서 몸에 살짝 가려지게)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-46, -30), Vector2(-26, -30), Vector2(-40, -78),
	]), HORN_COLOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(26, -30), Vector2(46, -30), Vector2(40, -78),
	]), HORN_COLOR)
	# 몸통 (둥근 블롭)
	draw_colored_polygon(_ellipse_points(Vector2(0, 10), 66, 74), body_color)

	var eye_l := Vector2(-20, -6)
	var eye_r := Vector2(20, -6)
	var mouth_center := Vector2(0, 24)

	match expression:
		"angry":
			draw_line(eye_l + Vector2(-8, -10), eye_l + Vector2(8, -3), EYE_COLOR, 3.0)
			draw_line(eye_r + Vector2(-8, -3), eye_r + Vector2(8, -10), EYE_COLOR, 3.0)
		"sad", "hurt":
			draw_line(eye_l + Vector2(-8, -3), eye_l + Vector2(8, -10), EYE_COLOR, 2.5)
			draw_line(eye_r + Vector2(-8, -10), eye_r + Vector2(8, -3), EYE_COLOR, 2.5)
		_:
			pass

	draw_circle(eye_l, 6, EYE_COLOR)
	draw_circle(eye_r, 6, EYE_COLOR)

	match expression:
		"happy":
			draw_polyline(_arc_points(mouth_center + Vector2(0, -6), 16, PI * 0.1, PI * 0.9), MOUTH_COLOR, 3.0)
		"angry":
			draw_polyline(PackedVector2Array([
				mouth_center + Vector2(-14, -2), mouth_center + Vector2(-5, 4),
				mouth_center + Vector2(5, -2), mouth_center + Vector2(14, 4),
			]), MOUTH_COLOR, 3.0)
		"sad", "hurt":
			draw_polyline(_arc_points(mouth_center + Vector2(0, 12), 16, PI * 1.1, PI * 1.9), MOUTH_COLOR, 3.0)
		_:
			draw_line(mouth_center + Vector2(-12, 2), mouth_center + Vector2(12, 2), MOUTH_COLOR, 3.0)


func _arc_points(center: Vector2, radius: float, angle_from: float, angle_to: float, segments: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle: float = lerp(angle_from, angle_to, t)
		pts.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	return pts


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return pts
