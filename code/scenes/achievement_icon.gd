class_name AchievementIcon
extends Control
## 업적 카드 앞에 붙는 유형별 아이콘 (INBOX.md 2026-09-14: "업적에 유형별 아이콘을
## 추가한다. 예를 들어 골드 보유 업적이면 금화가 쌓인 아이콘. 다이스 관련이면 다이스
## 모양 아이콘.").
##
## reward_icon.gd(RewardIcon, 던전 맵 선택지 보상 카테고리 아이콘)와 같은 패턴 —
## 별도 이미지 에셋 없이 _draw()로 도형을 그리는 절차적 아이콘. AchievementManager.
## DEFINITIONS의 각 항목이 "icon" 필드(category 문자열)를 갖고, achievement_panel.gd가
## 이 category를 그대로 넘겨 카드 왼쪽에 붙인다.
##
## category (achievement_manager.gd DEFINITIONS의 "icon" 필드와 1:1 대응):
## - "start": 첫 시작류 (발자국)
## - "milestone": 클리어/달성류 (깃발)
## - "dice": 다이스 보유/수집류 (다이스 눈금 5 배치 면)
## - "gold": 골드 보유류 (동전 쌓기)
## - "combat": 전투 판정류 — 무결점/기사회생/오버킬 (검)
## - "pip": 눈금 수집류 (눈금 1개짜리 면)
## - "bag": 주머니 용량류 (주머니)
## - "shop": 상점 이용류 (좌판)
## - "material": 재질 수집류 (4분할 색상환)
##
## **외부 아트 override([대형 기획 15] Q-9, 2026-10-20 신규)**: `achievement_id`를
## 설정하면 `resources/achievements/<업적 id>.png`(개별 업적 1:1, category "유형"
## 공유와는 별개 축)가 있는지 확인해 있으면 그 이미지를 category보다 우선 그린다
## (없으면 조용히 기존 category 그리기로 폴백 — skill_icon.gd K-4c와 같은 패턴).

## 알 수 없는/누락된 category가 들어와도 조용히 아무것도 안 그리는 대신 이 목록으로
## 검증 가능하게 공개 상수로 둔다(dice_test.gd가 DEFINITIONS 전체를 이 목록과 대조).
const CATEGORIES := ["start", "milestone", "dice", "gold", "combat", "pip", "bag", "shop", "material"]

## [대형 기획 15] Q-9 신규. skill_icon.gd(SkillIcon)의 K-4c 외부 아트 override와 같은
## 패턴 — `achievement_id`를 설정하면 `EXTERNAL_ART_DIR/<achievement_id>.png`(업적
## "유형"이 아니라 "개별 업적"마다 다른 그림을 받을 수 있게, category와는 별개 축)가
## 있는지 확인해 있으면 그 이미지를, 없으면 기존 절차적 category 그리기로 조용히
## 폴백한다. 업적 아이콘은 (SkillIcon의 고유 능력 틴트와 달리) 특정 캐릭터에 묶이지
## 않으므로 틴트는 적용하지 않는다.
const EXTERNAL_ART_DIR := "res://resources/achievements/"

var category: String = "milestone":
	set(v):
		category = v
		queue_redraw()

## K-4c와 동일한 의미의 테스트 주입 지점 — 운영 중에는 항상 기본값(EXTERNAL_ART_DIR).
var external_art_base_dir: String = EXTERNAL_ART_DIR:
	set(v):
		external_art_base_dir = v
		queue_redraw()

var achievement_id: String = "":
	set(v):
		achievement_id = v
		queue_redraw()

const COLOR_START := Color(0.6, 0.45, 0.3)
const COLOR_MILESTONE := Color(0.85, 0.68, 0.25)
const COLOR_DICE_BORDER := Color(0.55, 0.35, 0.75)
const COLOR_GOLD := Color(0.85, 0.7, 0.25)
const COLOR_COMBAT := Color(0.75, 0.25, 0.25)
const COLOR_PIP := Color(0.3, 0.75, 0.75)
const COLOR_BAG := Color(0.55, 0.4, 0.25)
const COLOR_SHOP := Color(0.8, 0.5, 0.3)
const COLOR_FACE_BG := Color(0.92, 0.88, 0.78)

const MATERIAL_COLORS := [
	Color(0.92, 0.9, 0.86),  # 플라스틱
	Color(0.5, 0.32, 0.18),  # 나무
	Color(0.65, 0.85, 0.85, 0.85),  # 유리
	Color(0.72, 0.72, 0.78),  # 철제
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(32, 32)


## [미니 기획 ART-3] skill_icon.gd가 이미 겪은 버그(매 프레임 _draw()에서 새
## ImageTexture를 지역 변수로만 만들면 함수 종료 즉시 RID가 무효화돼 흰 사각형으로
## 보임)를 처음부터 피하려고 멤버 변수로 캐시한다 — path가 바뀔 때만 다시 로드.
var _cached_external_texture: Texture2D = null
var _cached_external_path: String = ""


func _external_texture() -> Texture2D:
	if achievement_id == "":
		_cached_external_texture = null
		_cached_external_path = ""
		return null
	var path := AchievementIcon.external_art_path(achievement_id, external_art_base_dir)
	var exists: bool = ResourceLoader.exists(path) if external_art_base_dir == EXTERNAL_ART_DIR else FileAccess.file_exists(path)
	if not exists:
		_cached_external_texture = null
		_cached_external_path = ""
		return null
	if _cached_external_texture == null or _cached_external_path != path:
		_cached_external_texture = AchievementIcon.load_external_art(achievement_id, external_art_base_dir)
		_cached_external_path = path
	return _cached_external_texture


## dice_test.gd가 "_draw()가 실제로 어느 분기를 타는지"를 계산 결과로 검증할 수 있게
## 노출한다(skill_icon.gd의 render_source()와 같은 목적 — 단일 진실 소스).
func render_source() -> String:
	if _external_texture() != null:
		return "external"
	if category != "":
		return "category"
	return "none"


static func external_art_path(achievement_id_value: String, base_dir: String = EXTERNAL_ART_DIR) -> String:
	return base_dir + achievement_id_value + ".png"


## skill_icon.gd의 load_external_art()와 같은 패턴 — production res://(.import된 자산,
## ResourceLoader로 로드)와 테스트 user://(raw PNG, FileAccess+Image.load) 두 경로를
## 지원한다.
static func load_external_art(achievement_id_value: String, base_dir: String = EXTERNAL_ART_DIR) -> Texture2D:
	if achievement_id_value == "":
		return null
	var path := external_art_path(achievement_id_value, base_dir)
	if base_dir == EXTERNAL_ART_DIR:
		if not ResourceLoader.exists(path):
			return null
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(path) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _draw() -> void:
	var override_texture := _external_texture()
	if override_texture != null:
		draw_texture_rect(override_texture, Rect2(Vector2.ZERO, size), false)
		return
	match category:
		"start":
			_draw_footprints()
		"milestone":
			_draw_flag()
		"dice":
			_draw_face([Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5, 0.5), Vector2(0.25, 0.75), Vector2(0.75, 0.75)], COLOR_DICE_BORDER)
		"gold":
			_draw_coin_stack()
		"combat":
			_draw_sword()
		"pip":
			_draw_face([Vector2(0.5, 0.5)], COLOR_PIP)
		"bag":
			_draw_bag()
		"shop":
			_draw_shop()
		"material":
			_draw_material()
		_:
			pass


## [대형 기획 15] Q-9 신규. 36px 안팎으로 작게 그려지는 업적 아이콘이 어두운/밝은
## 배경 양쪽에서도 또렷이 보이도록, 채워진 폴리곤 테두리에 짙은 스트로크를 덧그리는
## 공용 헬퍼(실루엣 자체는 바꾸지 않아 기존 색 비교 테스트와 호환). skill_icon.gd의
## 같은 이름 헬퍼와 동일한 알고리즘.
func _stroke_polygon(points: PackedVector2Array, color: Color, width: float = 1.4) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, width, true)


func _draw_footprints() -> void:
	var r := size.x * 0.14
	draw_circle(Vector2(size.x * 0.32, size.y * 0.32), r, COLOR_START)
	draw_arc(Vector2(size.x * 0.32, size.y * 0.32), r, 0, TAU, 16, COLOR_START.darkened(0.5), 1.2)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.62), r, COLOR_START)
	draw_arc(Vector2(size.x * 0.68, size.y * 0.62), r, 0, TAU, 16, COLOR_START.darkened(0.5), 1.2)
	draw_circle(Vector2(size.x * 0.32, size.y * 0.6), r * 0.55, COLOR_START)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.32), r * 0.55, COLOR_START)


func _draw_flag() -> void:
	var pole_x := size.x * 0.3
	draw_line(Vector2(pole_x, size.y * 0.12), Vector2(pole_x, size.y * 0.88), COLOR_MILESTONE, size.x * 0.06)
	var pennant := PackedVector2Array([
		Vector2(pole_x, size.y * 0.16),
		Vector2(size.x * 0.82, size.y * 0.3),
		Vector2(pole_x, size.y * 0.44),
	])
	draw_colored_polygon(pennant, COLOR_MILESTONE)
	_stroke_polygon(pennant, COLOR_MILESTONE.darkened(0.5))


func _draw_face(dot_ratios: Array, dot_color: Color) -> void:
	var rect := Rect2(size.x * 0.1, size.y * 0.1, size.x * 0.8, size.y * 0.8)
	draw_rect(rect, COLOR_FACE_BG, true)
	draw_rect(rect, dot_color, false, 1.5)
	var dot_r := size.x * 0.09
	for ratio in dot_ratios:
		draw_circle(Vector2(size.x * ratio.x, size.y * ratio.y), dot_r, dot_color)


func _draw_coin_stack() -> void:
	var r := size.x * 0.24
	for i in range(3):
		var cy := size.y * (0.78 - i * 0.22)
		draw_circle(Vector2(size.x * 0.5, cy), r, COLOR_GOLD)
		draw_arc(Vector2(size.x * 0.5, cy), r, 0, TAU, 20, COLOR_GOLD.darkened(0.55), 1.2)
		draw_arc(Vector2(size.x * 0.5, cy), r * 0.6, 0, TAU, 16, Color(0.5, 0.38, 0.1, 0.8), 1.2)


## [대형 기획 13] M-5(b) — resources/ui/icon/attack.png(흰 칼 실루엣)가 있으면 COLOR_COMBAT
## 으로 칠해 쓰고, 없으면 기존 절차적 폴리곤 칼로 폴백한다.
func _draw_sword() -> void:
	var tex := UIKit.icon_texture("attack", COLOR_COMBAT)
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
		return
	var blade := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.6, size.y * 0.6),
		Vector2(size.x * 0.4, size.y * 0.6),
	])
	draw_colored_polygon(blade, COLOR_COMBAT)
	_stroke_polygon(blade, COLOR_COMBAT.darkened(0.5))
	draw_rect(Rect2(size.x * 0.28, size.y * 0.58, size.x * 0.44, size.y * 0.08), COLOR_COMBAT.darkened(0.2))
	draw_line(Vector2(size.x * 0.5, size.y * 0.66), Vector2(size.x * 0.5, size.y * 0.9), COLOR_COMBAT.darkened(0.3), size.x * 0.08)


func _draw_bag() -> void:
	var body := Rect2(size.x * 0.22, size.y * 0.35, size.x * 0.56, size.y * 0.5)
	draw_rect(body, COLOR_BAG, true)
	draw_rect(body, COLOR_BAG.darkened(0.5), false, 1.4)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.35), size.x * 0.18, PI, TAU, 12, COLOR_BAG.darkened(0.2), 3.0)


func _draw_shop() -> void:
	var roof := PackedVector2Array([
		Vector2(size.x * 0.12, size.y * 0.42),
		Vector2(size.x * 0.5, size.y * 0.14),
		Vector2(size.x * 0.88, size.y * 0.42),
	])
	draw_colored_polygon(roof, COLOR_SHOP)
	_stroke_polygon(roof, COLOR_SHOP.darkened(0.5))
	draw_rect(Rect2(size.x * 0.2, size.y * 0.42, size.x * 0.6, size.y * 0.42), COLOR_SHOP.lightened(0.2))
	draw_rect(Rect2(size.x * 0.42, size.y * 0.6, size.x * 0.16, size.y * 0.24), COLOR_SHOP.darkened(0.3))


func _draw_material() -> void:
	var center := size * 0.5
	var r := size.x * 0.42
	for i in range(4):
		var start_angle := TAU * i / 4.0 - PI / 2
		var end_angle := start_angle + TAU / 4.0
		var points := PackedVector2Array([center])
		var steps := 8
		for s in range(steps + 1):
			var a: float = lerp(start_angle, end_angle, float(s) / steps)
			points.append(center + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(points, MATERIAL_COLORS[i])
	# 4분할 경계를 짙은 선으로 또렷하게(색만으로는 구분이 약한 유리/철제 조합 대비).
	draw_arc(center, r, 0, TAU, 32, Color(0.15, 0.15, 0.17, 0.85), 1.2)
	for i in range(4):
		var a: float = TAU * i / 4.0 - PI / 2
		draw_line(center, center + Vector2(cos(a), sin(a)) * r, Color(0.15, 0.15, 0.17, 0.85), 1.2)
