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
##
## hair_color/dress_color를 @export로 뺀 것은 [대형 기획 1] 플레이어블 캐릭터 여러
## 종(character_profiles.gd)을 같은 실루엣 그리기 코드로 색만 다르게 구분하기
## 위함(2026-09-09 신규) — 실루엣 자체를 새로 그리는 대신 기존 "이쁘장한 여캐"
## 실루엣의 색 팔레트만 캐릭터별로 바꿔 최소 구분을 준다.

const SKIN_COLOR := Color(0.96, 0.82, 0.72)
const EYE_COLOR := Color(0.25, 0.2, 0.3)
const MOUTH_COLOR := Color(0.55, 0.25, 0.3)

## ART-1b: 전투 화면 상반신 표정 컷(원화) 크기 — 상반신 정사각 구도라 정사각으로 둔다.
## HP 패널/다이스 스테이지와 안 겹치는 범위(INBOX "약 220~260px") 중간값.
const FACE_ART_SIZE := Vector2(240, 240)

## [미니 기획 ART-2] combat_test.tscn의 PlayerPortrait 위치(110, 300)는
## 2026-10-15까지 FACE_ART_SIZE를 정확히 중앙 정렬했는데, PORTRAIT_SCALE_NORMAL(1.1,
## combat_test.gd)이 곱해지면 왼쪽 끝이 화면 밖(음수 x)으로 나가 일직선으로 잘려
## 보였다(INBOX ART-2, qa_out/art1b_novice_after_exchange.png). 중심을 오른쪽으로
## 40px(로컬 기준, 1.1배 스케일에서 글로벌 약 +44px) 밀어 왼쪽 여백이 16px 이상
## 남도록 고정값으로 보정 — set_character()를 부르는 곳이 combat_test.gd 하나뿐이라
## (character_select/deck_panel/test_battle_setup은 플레이스홀더만 쓰고 원화 모드로
## 전환하지 않음) 이 화면 전용 보정으로 안전하다.
const FACE_ART_LEFT_SHIFT := 40.0

## [미니 기획 ART-2] 표정 컷 아래 20~25% 구간을 투명으로 그라데이션 처리해 가슴께에서
## 끊긴 원화 하단이 배경 위에 떠 보이는 것 대신 자연스럽게 사라지게 한다.
const FACE_ART_FADE_SHADER := preload("res://code/shaders/face_art_fade.gdshader")

## "neutral" / "happy" / "hurt" / "sad" / "angry"
@export var expression: String = "neutral"
@export var hair_color := Color(0.78, 0.62, 0.86)
@export var dress_color := Color(0.92, 0.55, 0.66)

## ART-1b: set_character()가 face_* 5장을 전부 찾으면 true — 이때 _draw()의 도형
## 플레이스홀더 대신 _face_rect 텍스처를 보여준다(1장이라도 없으면 항상 false로 유지돼
## 플레이스홀더 그대로).
var _use_face_art := false
var _character_id := ""
var _face_rect: TextureRect = null


func set_palette(new_hair_color: Color, new_dress_color: Color) -> void:
	hair_color = new_hair_color
	dress_color = new_dress_color
	queue_redraw()


## ART-1b: 전투 화면이 플레이어 캐릭터가 정해질 때(또는 QA로 캐릭터를 바꿀 때) 호출.
## face_* 5장이 전부 있으면 원화 모드로 전환해 이후 set_expression() 호출마다 텍스처만
## 갈아끼운다. 캐릭터 선택/테스트 전투 설정 등 이 함수를 부르지 않는 기존 사용처는
## _use_face_art가 항상 false라 지금과 동일한 도형 플레이스홀더로 동작한다.
func set_character(character_id: String) -> void:
	_character_id = character_id
	_use_face_art = CharacterArt.has_all_faces(character_id)
	if _use_face_art:
		_ensure_face_rect()
	if _face_rect != null:
		_face_rect.visible = _use_face_art
	set_expression(expression)


func _ensure_face_rect() -> void:
	if _face_rect != null:
		return
	_face_rect = TextureRect.new()
	_face_rect.custom_minimum_size = FACE_ART_SIZE
	_face_rect.size = FACE_ART_SIZE
	_face_rect.position = Vector2(-FACE_ART_SIZE.x / 2.0 + FACE_ART_LEFT_SHIFT, -FACE_ART_SIZE.y / 2.0 + 16.0)
	_face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_material := ShaderMaterial.new()
	fade_material.shader = FACE_ART_FADE_SHADER
	_face_rect.material = fade_material
	add_child(_face_rect)


func set_expression(new_expression: String) -> void:
	expression = new_expression
	if _use_face_art and _face_rect != null:
		_face_rect.texture = CharacterArt.load_face(_character_id, expression)
	queue_redraw()


func _draw() -> void:
	if _use_face_art:
		return
	# 머리카락 뒷부분 (얼굴보다 넓은 타원형 블롭)
	draw_colored_polygon(_ellipse_points(Vector2(0, -30), 68, 78), hair_color)
	# 얼굴 (원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -20), 52, 56), SKIN_COLOR)
	# 앞머리 (얼굴 위쪽을 가리는 작은 타원)
	draw_colored_polygon(_ellipse_points(Vector2(0, -58), 54, 26), hair_color)
	_draw_face(Vector2(-18, -16), Vector2(18, -16), Vector2(0, 6))
	# 몸통 / 원피스 (사다리꼴)
	var dress := PackedVector2Array([
		Vector2(-30, 40), Vector2(30, 40), Vector2(52, 140), Vector2(-52, 140),
	])
	draw_colored_polygon(dress, dress_color)
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
