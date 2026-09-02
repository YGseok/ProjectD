extends Node2D
class_name CharacterPortraitPlaceholder
## 캐릭터 초상화 플레이스홀더 (실제 일러스트 에셋이 생기기 전까지 임시로 쓰는
## 도형 조립 실루엣). `_draw()`로 그려서 별도 이미지 파일이 필요 없다.
## 여캐 실루엣(단발머리 + 원피스)을 최소한의 색 구성(살구색 피부, 라벤더 머리,
## 분홍 원피스)으로 표현 — "이쁘장한 여캐"라는 지시의 방향성만 표시하는 스케치용.
##
## INBOX.md 피드백("공방을 주고받을 때는 웃거나 찡그린다", "승리할 때는 즐거워한다",
## "패배할 때는 슬퍼하거나 분노한다")을 반영해 표정(expression)에 따라 눈썹/입 모양이
## 바뀐다. set_expression()을 호출하면 즉시 다시 그려진다.

const SKIN_COLOR := Color(0.96, 0.82, 0.72)
const HAIR_COLOR := Color(0.78, 0.62, 0.86)
const DRESS_COLOR := Color(0.92, 0.55, 0.66)
const EYE_COLOR := Color(0.25, 0.2, 0.3)
const MOUTH_COLOR := Color(0.55, 0.25, 0.3)

## "neutral" / "happy" / "hurt" / "sad" / "angry"
@export var expression: String = "neutral"


func set_expression(new_expression: String) -> void:
	expression = new_expression
	queue_redraw()


func _draw() -> void:
	# 머리카락 뒷부분 (얼굴보다 넓은 타원형 블롭)
	draw_colored_polygon(_ellipse_points(Vector2(0, -30), 68, 78), HAIR_COLOR)
	# 얼굴 (원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -20), 52, 56), SKIN_COLOR)
	# 앞머리 (얼굴 위쪽을 가리는 작은 타원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -58), 54, 26), HAIR_COLOR)
	_draw_face(Vector2(-18, -16), Vector2(18, -16), Vector2(0, 6))
	# 몸통 / 원피스 (사다리꼴)
	var dress := PackedVector2Array([
		Vector2(-30, 40), Vector2(30, 40), Vector2(52, 140), Vector2(-52, 140),
	])
	draw_colored_polygon(dress, DRESS_COLOR)
	# 목/어깨 연결부 (피부색 작은 사각형)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, 30), Vector2(14, 30), Vector2(14, 44), Vector2(-14, 44),
	]), SKIN_COLOR)


## 눈/눈썹/입을 expression에 맞춰 그린다. eye_l/eye_r/mouth_center는 이 실루엣 기준
## 좌표(중심 부근 위치)이며, 다른 초상화(몬스터 등)에서도 같은 값을 넘겨 재사용 가능.
func _draw_face(eye_l: Vector2, eye_r: Vector2, mouth_center: Vector2) -> void:
	match expression:
		"angry":
			draw_line(eye_l + Vector2(-7, -9), eye_l + Vector2(7, -3), EYE_COLOR, 3.0)
			draw_line(eye_r + Vector2(-7, -3), eye_r + Vector2(7, -9), EYE_COLOR, 3.0)
		"sad", "hurt":
			draw_line(eye_l + Vector2(-7, -3), eye_l + Vector2(7, -9), EYE_COLOR, 2.5)
			draw_line(eye_r + Vector2(-7, -9), eye_r + Vector2(7, -3), EYE_COLOR, 2.5)
		_:
			pass

	draw_circle(eye_l, 5, EYE_COLOR)
	draw_circle(eye_r, 5, EYE_COLOR)

	match expression:
		"happy":
			draw_polyline(_arc_points(mouth_center + Vector2(0, -4), 14, PI * 0.15, PI * 0.85), MOUTH_COLOR, 2.5)
		"angry":
			draw_polyline(PackedVector2Array([
				mouth_center + Vector2(-12, 2), mouth_center + Vector2(-4, 6),
				mouth_center + Vector2(4, 2), mouth_center + Vector2(12, 6),
			]), MOUTH_COLOR, 2.5)
		"sad", "hurt":
			draw_polyline(_arc_points(mouth_center + Vector2(0, 10), 14, PI * 1.15, PI * 1.85), MOUTH_COLOR, 2.5)
		_:
			draw_line(mouth_center + Vector2(-10, 4), mouth_center + Vector2(10, 4), MOUTH_COLOR, 2.5)


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
