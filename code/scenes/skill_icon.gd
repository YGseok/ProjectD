class_name SkillIcon
extends Control
## 캐릭터 "보유 스킬"(character_profiles.gd의 gimmick) 옆에 붙는 유형별 아이콘.
## INBOX.md 2026-09-14 "캐릭터 스킬에 아이콘을 추가한다" 반영.
##
## achievement_icon.gd(AchievementIcon)/reward_icon.gd(RewardIcon)와 같은 패턴 —
## 별도 이미지 에셋 없이 _draw()로 도형을 그리는 절차적 아이콘. 지금 "스킬"이라고
## 부를 수 있는 건 character_profiles.gd의 gimmick 필드(전투 시작 시 정적으로
## 적용되거나 전투 중 스택으로 추적되는 다이스 특성) 하나뿐이라, 이벤트로 얻는
## 별도 "고유 스킬" 시스템이 생기기 전까지는 category로 gimmick 필드 값을 그대로
## 받는다(재매핑 테이블 없이 1:1 대응 — 새 기믹이 추가되면 이 스크립트에도 case를
## 추가해야 함, dice_test.gd의 _check_skill_icons가 누락을 잡아줌).
##
## category (character_profiles.gd의 gimmick 필드 값과 1:1 대응):
## - "": 기믹 없음 (표준 다이스 — 빈 원)
## - "min_max_only": 극단형 (위/아래로 뾰족한 마름모 — 최솟값/최댓값만 나옴)
## - "fixed_defense_die": 고정 방어 (자물쇠 달린 방패 — 항상 같은 값)
## - "explosive_stack": 폭발 스택 (별 모양 폭발)
## - "guard_stack": 수호 스택 (겹겹의 방패)
## - "charm_flip": 매혹 (하트 모양, 2026-09-24 [대형 기획 4]-B "매혹사" 신규)
## - "juggle_swap": 저글링 (교차하는 화살표 2개, 2026-09-24 [대형 기획 4]-C "곡예사" 신규)

const CATEGORIES := ["", "min_max_only", "fixed_defense_die", "explosive_stack", "guard_stack", "charm_flip", "juggle_swap"]

var category: String = "":
	set(v):
		category = v
		queue_redraw()

const COLOR_NONE := Color(0.55, 0.55, 0.55)
const COLOR_EXTREME := Color(0.85, 0.25, 0.2)
const COLOR_FIXED := Color(0.4, 0.55, 0.85)
const COLOR_EXPLOSIVE := Color(0.95, 0.55, 0.15)
const COLOR_GUARD := Color(0.55, 0.6, 0.65)
const COLOR_CHARM := Color(0.85, 0.2, 0.5)
const COLOR_JUGGLE := Color(0.9, 0.75, 0.15)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(28, 28)


func _draw() -> void:
	match category:
		"":
			_draw_none()
		"min_max_only":
			_draw_extreme()
		"fixed_defense_die":
			_draw_fixed_shield()
		"explosive_stack":
			_draw_burst()
		"guard_stack":
			_draw_layered_shield()
		"charm_flip":
			_draw_heart()
		"juggle_swap":
			_draw_swap_arrows()
		_:
			pass


func _draw_none() -> void:
	draw_arc(size * 0.5, size.x * 0.32, 0, TAU, 20, COLOR_NONE, 2.0)


func _draw_extreme() -> void:
	var top := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.78, size.y * 0.46),
		Vector2(size.x * 0.22, size.y * 0.46),
	])
	draw_colored_polygon(top, COLOR_EXTREME)
	var bottom := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.92),
		Vector2(size.x * 0.78, size.y * 0.54),
		Vector2(size.x * 0.22, size.y * 0.54),
	])
	draw_colored_polygon(bottom, COLOR_EXTREME.darkened(0.25))


func _draw_shield_outline(color: Color) -> void:
	var pts := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.85, size.y * 0.22),
		Vector2(size.x * 0.85, size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.92),
		Vector2(size.x * 0.15, size.y * 0.5),
		Vector2(size.x * 0.15, size.y * 0.22),
	])
	draw_colored_polygon(pts, color)


func _draw_fixed_shield() -> void:
	_draw_shield_outline(COLOR_FIXED)
	draw_rect(Rect2(size.x * 0.34, size.y * 0.42, size.x * 0.32, size.y * 0.18), COLOR_FIXED.darkened(0.4))


func _draw_layered_shield() -> void:
	_draw_shield_outline(COLOR_GUARD)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.4), size.x * 0.22, PI * 0.15, PI * 0.85, 10, COLOR_GUARD.darkened(0.35), 2.0)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.62), size.x * 0.18, PI * 0.15, PI * 0.85, 10, COLOR_GUARD.darkened(0.35), 2.0)


## "charm_flip"(매혹사) 전용 아이콘 — 원 두 개(하트 윗부분) + 삼각형(하트 아랫부분)을
## 겹쳐 하트 모양을 근사한다(achievement_icon.gd류처럼 draw_circle/draw_colored_polygon
## 조합만으로 별도 벡터 에셋 없이 그림).
func _draw_heart() -> void:
	var lobe_r := size.x * 0.24
	draw_circle(Vector2(size.x * 0.32, size.y * 0.38), lobe_r, COLOR_CHARM)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.38), lobe_r, COLOR_CHARM)
	var tip := PackedVector2Array([
		Vector2(size.x * 0.12, size.y * 0.42),
		Vector2(size.x * 0.88, size.y * 0.42),
		Vector2(size.x * 0.5, size.y * 0.92),
	])
	draw_colored_polygon(tip, COLOR_CHARM)


## "juggle_swap"(곡예사) 전용 아이콘 — 서로 반대 방향을 가리키는 화살표 2개(각각 선분 +
## 삼각형 화살촉)로 "두 다이스가 맞바뀐다"는 저글링/교환 느낌을 근사한다.
func _draw_swap_arrows() -> void:
	var top_y := size.y * 0.34
	var bottom_y := size.y * 0.66
	draw_line(Vector2(size.x * 0.2, top_y), Vector2(size.x * 0.72, top_y), COLOR_JUGGLE, 2.5)
	var top_head := PackedVector2Array([
		Vector2(size.x * 0.72, top_y - size.y * 0.1),
		Vector2(size.x * 0.72, top_y + size.y * 0.1),
		Vector2(size.x * 0.88, top_y),
	])
	draw_colored_polygon(top_head, COLOR_JUGGLE)
	draw_line(Vector2(size.x * 0.8, bottom_y), Vector2(size.x * 0.28, bottom_y), COLOR_JUGGLE.darkened(0.2), 2.5)
	var bottom_head := PackedVector2Array([
		Vector2(size.x * 0.28, bottom_y - size.y * 0.1),
		Vector2(size.x * 0.28, bottom_y + size.y * 0.1),
		Vector2(size.x * 0.12, bottom_y),
	])
	draw_colored_polygon(bottom_head, COLOR_JUGGLE.darkened(0.2))


func _draw_burst() -> void:
	var center := size * 0.5
	var outer := size.x * 0.44
	var inner := size.x * 0.18
	var points := PackedVector2Array()
	var spikes := 8
	for i in range(spikes * 2):
		var r: float = outer if i % 2 == 0 else inner
		var a: float = TAU * i / (spikes * 2.0) - PI / 2
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, COLOR_EXPLOSIVE)
