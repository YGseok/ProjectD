class_name FamilyIcon
extends Control
## 몬스터 "계열"(MonsterCatalog.FAMILIES) 옆에 붙는 유형별 아이콘
## (INBOX.md [대형 기획 6] G-1, 2026-10-07).
##
## skill_icon.gd(SkillIcon)/reward_icon.gd(RewardIcon)와 같은 패턴 — 별도 이미지
## 에셋 없이 _draw()로 도형을 그리는 절차적 아이콘. 사용자 지시 원문 예시를 그대로
## 따른다: "[인간형 아이콘] 고블린, [인간형 아이콘] 아머 고블린 = 인간형은 방어 관련
## 무언가를 함. [부정형 아이콘] 슬라임, [부정형 아이콘] 유령 = 이들은 주사위에 무언가를
## 함." 전투 화면 몬스터 이름 라벨 앞에 이 아이콘을 둬서 같은 계열끼리 한눈에 묶여
## 보이게 한다.
##
## category (MonsterCatalog.FAMILIES의 키와 1:1 대응, dice_test.gd의
## "카탈로그의 모든 family 값이 FamilyIcon.CATEGORIES에 존재" 검증이 누락을 잡아줌):
## - "humanoid": 인간형 (방패)
## - "amorphous": 부정형 (물방울)
## - "beast": 야수형 (발톱 자국 3개)
## - "undead": 언데드형 (해골)
##
## is_boss가 true면 아이콘 그리기가 끝난 뒤 작은 왕관을 위에 덧그린다(G-8 보스
## 6종이 쓸 자리 — 지금은 마지막 방 보스 강화(_monster_config_for_room()의
## is_boss)에 그대로 연동해 둠).

const CATEGORIES := ["humanoid", "amorphous", "beast", "undead"]

var category: String = "":
	set(v):
		category = v
		queue_redraw()

var is_boss: bool = false:
	set(v):
		is_boss = v
		queue_redraw()

const COLOR_HUMANOID := Color(0.55, 0.65, 0.85)
const COLOR_AMORPHOUS := Color(0.35, 0.75, 0.7)
const COLOR_BEAST := Color(0.8, 0.45, 0.25)
const COLOR_UNDEAD := Color(0.75, 0.78, 0.72)
const COLOR_CROWN := Color(0.95, 0.8, 0.25)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(24, 24)


func _draw() -> void:
	match category:
		"humanoid":
			_draw_shield()
		"amorphous":
			_draw_droplet()
		"beast":
			_draw_claw()
		"undead":
			_draw_skull()
		_:
			pass
	if is_boss and category != "":
		_draw_crown()


func _draw_shield() -> void:
	var pts := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.85, size.y * 0.24),
		Vector2(size.x * 0.85, size.y * 0.52),
		Vector2(size.x * 0.5, size.y * 0.92),
		Vector2(size.x * 0.15, size.y * 0.52),
		Vector2(size.x * 0.15, size.y * 0.24),
	])
	draw_colored_polygon(pts, COLOR_HUMANOID)
	draw_polyline(pts + PackedVector2Array([pts[0]]), COLOR_HUMANOID.darkened(0.4), 1.5)


## 물방울(위는 뾰족, 아래는 둥근) 형태 — 원 + 위쪽 삼각형을 겹쳐 근사한다.
func _draw_droplet() -> void:
	var r := size.x * 0.32
	var center := Vector2(size.x * 0.5, size.y * 0.6)
	draw_circle(center, r, COLOR_AMORPHOUS)
	var tip := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.5 - r * 0.95, size.y * 0.58),
		Vector2(size.x * 0.5 + r * 0.95, size.y * 0.58),
	])
	draw_colored_polygon(tip, COLOR_AMORPHOUS)


## 발톱 자국 3개(끝이 가는 곡선 대신 가늘고 긴 삼각형으로 근사) — 야수형의 공격성을
## 표현. achievement_icon류처럼 draw_colored_polygon 조합만으로 그린다.
func _draw_claw() -> void:
	for i in range(3):
		var x_center: float = size.x * (0.28 + i * 0.22)
		var pts := PackedVector2Array([
			Vector2(x_center - size.x * 0.05, size.y * 0.12),
			Vector2(x_center + size.x * 0.05, size.y * 0.12),
			Vector2(x_center, size.y * 0.88),
		])
		draw_colored_polygon(pts, COLOR_BEAST)


## 해골 — 둥근 두개골(원) + 눈구멍 2개(어두운 원) + 치아 줄(짧은 선 여러 개).
func _draw_skull() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.42)
	var r := size.x * 0.38
	draw_circle(center, r, COLOR_UNDEAD)
	var eye_r := size.x * 0.1
	draw_circle(center + Vector2(-r * 0.4, 0), eye_r, Color(0.15, 0.15, 0.18))
	draw_circle(center + Vector2(r * 0.4, 0), eye_r, Color(0.15, 0.15, 0.18))
	var jaw_top := size.y * 0.68
	var jaw_bottom := size.y * 0.88
	draw_rect(Rect2(size.x * 0.3, jaw_top, size.x * 0.4, jaw_bottom - jaw_top), COLOR_UNDEAD)
	for i in range(3):
		var x: float = size.x * (0.38 + i * 0.12)
		draw_line(Vector2(x, jaw_top), Vector2(x, jaw_bottom), Color(0.15, 0.15, 0.18), 1.0)


## 보스 전용 왕관 오버레이 — 아이콘 위쪽에 작은 삼각 톱니 3개로 근사.
func _draw_crown() -> void:
	var base_y := size.y * 0.06
	var pts := PackedVector2Array([
		Vector2(size.x * 0.22, base_y + size.y * 0.1),
		Vector2(size.x * 0.3, base_y - size.y * 0.08),
		Vector2(size.x * 0.4, base_y + size.y * 0.06),
		Vector2(size.x * 0.5, base_y - size.y * 0.1),
		Vector2(size.x * 0.6, base_y + size.y * 0.06),
		Vector2(size.x * 0.7, base_y - size.y * 0.08),
		Vector2(size.x * 0.78, base_y + size.y * 0.1),
	])
	draw_colored_polygon(pts, COLOR_CROWN)
