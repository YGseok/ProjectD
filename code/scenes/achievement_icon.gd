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

## 알 수 없는/누락된 category가 들어와도 조용히 아무것도 안 그리는 대신 이 목록으로
## 검증 가능하게 공개 상수로 둔다(dice_test.gd가 DEFINITIONS 전체를 이 목록과 대조).
const CATEGORIES := ["start", "milestone", "dice", "gold", "combat", "pip", "bag", "shop", "material"]

var category: String = "milestone":
	set(v):
		category = v
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
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(32, 32)


func _draw() -> void:
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


func _draw_footprints() -> void:
	var r := size.x * 0.14
	draw_circle(Vector2(size.x * 0.32, size.y * 0.32), r, COLOR_START)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.62), r, COLOR_START)
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
		draw_arc(Vector2(size.x * 0.5, cy), r * 0.6, 0, TAU, 16, Color(0.5, 0.38, 0.1, 0.8), 1.2)


func _draw_sword() -> void:
	var blade := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.6, size.y * 0.6),
		Vector2(size.x * 0.4, size.y * 0.6),
	])
	draw_colored_polygon(blade, COLOR_COMBAT)
	draw_rect(Rect2(size.x * 0.28, size.y * 0.58, size.x * 0.44, size.y * 0.08), COLOR_COMBAT.darkened(0.2))
	draw_line(Vector2(size.x * 0.5, size.y * 0.66), Vector2(size.x * 0.5, size.y * 0.9), COLOR_COMBAT.darkened(0.3), size.x * 0.08)


func _draw_bag() -> void:
	var body := Rect2(size.x * 0.22, size.y * 0.35, size.x * 0.56, size.y * 0.5)
	draw_rect(body, COLOR_BAG, true)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.35), size.x * 0.18, PI, TAU, 12, COLOR_BAG.darkened(0.2), 3.0)


func _draw_shop() -> void:
	var roof := PackedVector2Array([
		Vector2(size.x * 0.12, size.y * 0.42),
		Vector2(size.x * 0.5, size.y * 0.14),
		Vector2(size.x * 0.88, size.y * 0.42),
	])
	draw_colored_polygon(roof, COLOR_SHOP)
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
