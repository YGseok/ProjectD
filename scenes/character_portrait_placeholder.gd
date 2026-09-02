extends Node2D
## 캐릭터 초상화 플레이스홀더 (실제 일러스트 에셋이 생기기 전까지 임시로 쓰는
## 도형 조립 실루엣). `_draw()`로 그려서 별도 이미지 파일이 필요 없다.
## 여캐 실루엣(단발머리 + 원피스)을 최소한의 색 구성(살구색 피부, 라벤더 머리,
## 분홍 원피스)으로 표현 — "이쁘장한 여캐"라는 지시의 방향성만 표시하는 스케치용.

const SKIN_COLOR := Color(0.96, 0.82, 0.72)
const HAIR_COLOR := Color(0.78, 0.62, 0.86)
const DRESS_COLOR := Color(0.92, 0.55, 0.66)
const EYE_COLOR := Color(0.25, 0.2, 0.3)


func _draw() -> void:
	# 머리카락 뒷부분 (얼굴보다 넓은 타원형 블롭)
	draw_colored_polygon(_ellipse_points(Vector2(0, -30), 68, 78), HAIR_COLOR)
	# 얼굴 (원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -20), 52, 56), SKIN_COLOR)
	# 앞머리 (얼굴 위쪽을 가리는 작은 타원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -58), 54, 26), HAIR_COLOR)
	# 눈 두 개
	draw_circle(Vector2(-18, -16), 5, EYE_COLOR)
	draw_circle(Vector2(18, -16), 5, EYE_COLOR)
	# 몸통 / 원피스 (사다리꼴)
	var dress := PackedVector2Array([
		Vector2(-30, 40), Vector2(30, 40), Vector2(52, 140), Vector2(-52, 140),
	])
	draw_colored_polygon(dress, DRESS_COLOR)
	# 목/어깨 연결부 (피부색 작은 사각형)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, 30), Vector2(14, 30), Vector2(14, 44), Vector2(-14, 44),
	]), SKIN_COLOR)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return pts
