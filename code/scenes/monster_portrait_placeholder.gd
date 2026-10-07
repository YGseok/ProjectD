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
##
## G-5(2026-10-07, INBOX.md [대형 기획 6] G-5): `family` export로 계열별 최소 장식을
## 덧붙인다 — "humanoid"=뿔 대신 투구 테두리(가로줄), "amorphous"=뿔 없이 몸 하단에
## 물방울이 떨어지는 장식, "beast"=기존 뿔을 더 뾰족한 귀+송곳니 느낌으로, "undead"=눈을
## 채운 원이 아니라 뚫린 눈구멍(테두리만)으로. family가 빈 문자열이면(기존 호출부가
## family를 안 넘기는 경우) 기존 그대로(뿔 두 개 + 채운 눈) 그려 동작 보존.

const EYE_COLOR := Color(0.12, 0.1, 0.08)
const MOUTH_COLOR := Color(0.25, 0.08, 0.08)
const HORN_COLOR := Color(0.85, 0.82, 0.75)

## "neutral" / "happy" / "hurt" / "sad" / "angry"
@export var expression: String = "neutral"
@export var body_color: Color = Color(0.5, 0.5, 0.5)
## ""(기존 동작 보존) / "humanoid" / "amorphous" / "beast" / "undead"
## (MonsterCatalog.FAMILIES 키와 1:1 대응)
@export var family: String = ""


func set_expression(new_expression: String) -> void:
	expression = new_expression
	queue_redraw()


func set_body_color(color: Color) -> void:
	body_color = color
	queue_redraw()


func set_family(new_family: String) -> void:
	family = new_family
	queue_redraw()


func _draw() -> void:
	if family == "amorphous":
		# 뿔 없이, 몸 하단에 흘러내리는 물방울 장식.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, 60), Vector2(10, 60), Vector2(0, 86),
		]), body_color)
	elif family == "undead":
		# 뿔 대신 갈라진 뼈 장식(해골 컨셉).
		draw_colored_polygon(PackedVector2Array([
			Vector2(-40, -30), Vector2(-30, -30), Vector2(-35, -70), Vector2(-45, -70),
		]), HORN_COLOR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(30, -30), Vector2(40, -30), Vector2(45, -70), Vector2(35, -70),
		]), HORN_COLOR)
	else:
		# "humanoid"/"beast"/빈 문자열(기존 호출부 호환) — 기존 뿔 두 개 그대로.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-46, -30), Vector2(-26, -30), Vector2(-40, -78),
		]), HORN_COLOR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(26, -30), Vector2(46, -30), Vector2(40, -78),
		]), HORN_COLOR)
	if family == "humanoid":
		# 투구 테두리(가로줄) — 몸을 그리기 전에 그려서 몸에 살짝 덮이게.
		draw_line(Vector2(-50, -20), Vector2(50, -20), HORN_COLOR, 6.0)
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

	if family == "undead":
		# 눈구멍(테두리만, 채우지 않음) — 눈썹 선 위에 그려져 기존처럼 눈이 또렷이 보임.
		draw_arc(eye_l, 6, 0, TAU, 12, EYE_COLOR, 2.0)
		draw_arc(eye_r, 6, 0, TAU, 12, EYE_COLOR, 2.0)
	else:
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
