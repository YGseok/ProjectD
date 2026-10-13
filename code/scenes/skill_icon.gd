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
## - "cannon_volley": 함포 (포탄 모양, 2026-10-08 [대형 기획 9] I-1 "해적" 신규)
##
## **motif([대형 기획 11] K-4a, 2026-10-13 신규)**: 위 category(캐릭터 고유 기믹 8종)와는
## 완전히 별개의 두 번째 그리기 모드 — "스킬"(SkillPool의 SKILLS/UNIQUE_SKILLS/
## UPGRADE_SKILLS/STARTING_SKILLS)에 쓰는 ~11종 효과 모티프를 그린다(값은
## SkillPool.ICON_MOTIF_VALUES, 스킬 id -> 모티프 매핑은 SkillPool.icon_motif_for()).
## `motif`가 비어있지 않으면 motif 그리기가 category보다 우선한다(기존 category
## 호출부는 motif를 설정하지 않으므로 동작 변화 없음 — 하위 호환 유지). 전 화면 실제
## 배선(K-4b)과 외부 아트 override(K-4c)는 아직 — 지금은 모티프별 그리기 함수와
## 테스트(dice_test.gd의 _check_k4a_skill_icon_motifs)만 갖춰진 상태.

const CATEGORIES := ["", "min_max_only", "fixed_defense_die", "explosive_stack", "guard_stack", "charm_flip", "juggle_swap", "cannon_volley"]

var category: String = "":
	set(v):
		category = v
		queue_redraw()

## K-4a 신규. SkillPool.ICON_MOTIF_VALUES 중 하나(또는 미설정 시 "")를 받는다.
var motif: String = "":
	set(v):
		motif = v
		queue_redraw()

const COLOR_NONE := Color(0.55, 0.55, 0.55)
const COLOR_EXTREME := Color(0.85, 0.25, 0.2)
const COLOR_FIXED := Color(0.4, 0.55, 0.85)
const COLOR_EXPLOSIVE := Color(0.95, 0.55, 0.15)
const COLOR_GUARD := Color(0.55, 0.6, 0.65)
const COLOR_CHARM := Color(0.85, 0.2, 0.5)
const COLOR_JUGGLE := Color(0.9, 0.75, 0.15)
const COLOR_CANNON := Color(0.12, 0.65, 0.63)

## K-4a 모티프 전용 색상(캐릭터 기믹 색상과는 별개 팔레트 — 같은 모티프는 항상 같은
## 색조를 공유해야 한다는 INBOX.md 요구를 색상 상수 하나로 보장).
const COLOR_ATTACK := Color(0.9, 0.35, 0.15)
const COLOR_DEFENSE := Color(0.3, 0.55, 0.85)
const COLOR_DUAL := Color(0.6, 0.4, 0.85)
const COLOR_REROLL := Color(0.25, 0.75, 0.55)
const COLOR_FLIP := Color(0.85, 0.3, 0.55)
const COLOR_CYCLE := Color(0.15, 0.65, 0.6)
const COLOR_EVENT := Color(0.65, 0.5, 0.85)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(28, 28)


func _draw() -> void:
	if motif != "":
		_draw_motif()
		return
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
		"cannon_volley":
			_draw_cannon()
		_:
			pass


## K-4a 모티프 그리기 분기. SkillPool.ICON_MOTIF_VALUES 11종을 전부 커버하고,
## 못 알아듣는 값(이론상 SkillPool.ICON_MOTIFS가 오타를 낸 경우)은 빈 원으로
## 떨어진다(dice_test.gd가 "빈 아이콘으로 떨어지는 스킬이 0개"를 별도로 검증하므로
## 여기서 조용히 숨기지 않고 시각적으로도 드러남).
func _draw_motif() -> void:
	match motif:
		"attack_boost":
			_draw_motif_attack_boost()
		"defense_boost":
			_draw_motif_defense_boost()
		"dual_boost":
			_draw_motif_dual_boost()
		"reroll":
			_draw_motif_reroll()
		"burst_stack":
			_draw_burst(COLOR_EXPLOSIVE)
		"guard_stack":
			_draw_layered_shield(COLOR_GUARD)
		"dual_stack":
			_draw_motif_dual_stack()
		"dice_flip":
			_draw_motif_dice_flip()
		"dice_swap":
			_draw_swap_arrows(COLOR_JUGGLE)
		"cycle_strike":
			_draw_motif_cycle_strike()
		"event_check":
			_draw_motif_event_check()
		_:
			_draw_none()


## 공격 다이스 결과값 보정 — 위쪽을 향한 화살표(칼끝 느낌의 뾰족한 머리 + 자루).
func _draw_motif_attack_boost() -> void:
	draw_rect(Rect2(size.x * 0.42, size.y * 0.48, size.x * 0.16, size.y * 0.38), COLOR_ATTACK)
	var head := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.08),
		Vector2(size.x * 0.78, size.y * 0.5),
		Vector2(size.x * 0.22, size.y * 0.5),
	])
	draw_colored_polygon(head, COLOR_ATTACK)


## 방어 다이스 결과값 보정 — 방패 윤곽 + 안쪽 상승 쉐브론(↑ 꺾쇠).
func _draw_motif_defense_boost() -> void:
	_draw_shield_outline(COLOR_DEFENSE)
	var chevron := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.3),
		Vector2(size.x * 0.66, size.y * 0.52),
		Vector2(size.x * 0.56, size.y * 0.52),
		Vector2(size.x * 0.5, size.y * 0.44),
		Vector2(size.x * 0.44, size.y * 0.52),
		Vector2(size.x * 0.34, size.y * 0.52),
	])
	draw_colored_polygon(chevron, COLOR_DEFENSE.darkened(0.4))


## 공격+방어 동시 보정 — 좌우 대칭 상승 화살표 2개를 겹쳐 "양쪽 다"를 나타낸다.
func _draw_motif_dual_boost() -> void:
	var left := PackedVector2Array([
		Vector2(size.x * 0.32, size.y * 0.12),
		Vector2(size.x * 0.48, size.y * 0.52),
		Vector2(size.x * 0.16, size.y * 0.52),
	])
	draw_colored_polygon(left, COLOR_DUAL)
	var right := PackedVector2Array([
		Vector2(size.x * 0.68, size.y * 0.12),
		Vector2(size.x * 0.84, size.y * 0.52),
		Vector2(size.x * 0.52, size.y * 0.52),
	])
	draw_colored_polygon(right, COLOR_DUAL.darkened(0.3))
	draw_rect(Rect2(size.x * 0.4, size.y * 0.52, size.x * 0.2, size.y * 0.36), COLOR_DUAL.darkened(0.15))


## 여분/재굴림으로 값을 대체 — 순환 화살표(리프레시 아이콘).
func _draw_motif_reroll() -> void:
	draw_arc(size * 0.5, size.x * 0.32, -PI * 0.1, PI * 1.5, 24, COLOR_REROLL, 3.0)
	var head := PackedVector2Array([
		Vector2(size.x * 0.8, size.y * 0.2),
		Vector2(size.x * 0.94, size.y * 0.34),
		Vector2(size.x * 0.72, size.y * 0.36),
	])
	draw_colored_polygon(head, COLOR_REROLL)


## 공격+방어 스택이 함께 쌓임(임기응변 전용) — 폭발 스택 색(주황)과 수호 스택 색
## (회색)을 반씩 나눈 다이아몬드로 "두 파이프라인이 동시에 열린다"를 나타낸다.
func _draw_motif_dual_stack() -> void:
	var left := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.1),
		Vector2(size.x * 0.5, size.y * 0.9),
		Vector2(size.x * 0.1, size.y * 0.5),
	])
	draw_colored_polygon(left, COLOR_EXPLOSIVE)
	var right := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.1),
		Vector2(size.x * 0.5, size.y * 0.9),
		Vector2(size.x * 0.9, size.y * 0.5),
	])
	draw_colored_polygon(right, COLOR_GUARD)


## 다이스 값을 최댓값으로 전환(매혹 심화) — 겹쳐진 두 다이스 면(사각형) + 전환
## 화살표로 "낮은 값이 높은 값으로 바뀐다"를 나타낸다.
func _draw_motif_dice_flip() -> void:
	draw_rect(Rect2(size.x * 0.16, size.y * 0.42, size.x * 0.4, size.y * 0.4), COLOR_FLIP.darkened(0.25))
	draw_circle(Vector2(size.x * 0.36, size.y * 0.62), size.x * 0.05, COLOR_FLIP.darkened(0.55))
	draw_rect(Rect2(size.x * 0.44, size.y * 0.18, size.x * 0.4, size.y * 0.4), COLOR_FLIP)
	draw_circle(Vector2(size.x * 0.56, size.y * 0.3), size.x * 0.045, COLOR_FLIP.lightened(0.3))
	draw_circle(Vector2(size.x * 0.72, size.y * 0.3), size.x * 0.045, COLOR_FLIP.lightened(0.3))
	draw_circle(Vector2(size.x * 0.64, size.y * 0.46), size.x * 0.045, COLOR_FLIP.lightened(0.3))


## 주기형(쿨타임) 고정 피해(일제 사격) — 시계판(테두리 + 짧은/긴 바늘) + 발사 지점
## 점 하나로 "일정 턴마다 터진다"는 쿨타임 느낌을 나타낸다.
func _draw_motif_cycle_strike() -> void:
	draw_arc(size * 0.5, size.x * 0.38, 0, TAU, 28, COLOR_CYCLE, 2.5)
	draw_line(size * 0.5, Vector2(size.x * 0.5, size.y * 0.24), COLOR_CYCLE, 2.5)
	draw_line(size * 0.5, Vector2(size.x * 0.68, size.y * 0.5), COLOR_CYCLE, 2.5)
	draw_circle(Vector2(size.x * 0.78, size.y * 0.24), size.x * 0.1, COLOR_CYCLE.lightened(0.25))


## 전투 외 이벤트 판정 보정(승부사) — event_die_visual.gd의 로마 숫자 칩과 같은 "육각형
## 이벤트 다이스" 모양을 재사용해, 체크 표식(작은 원+사각 꼭짓점)으로 "판정을 유리하게
## 만든다"를 나타낸다.
func _draw_motif_event_check() -> void:
	var pts := PackedVector2Array()
	for i in range(6):
		var angle: float = TAU * i / 6.0 - PI / 2.0
		pts.append(size * 0.5 + Vector2(cos(angle), sin(angle)) * size.x * 0.42)
	draw_colored_polygon(pts, COLOR_EVENT)
	draw_circle(Vector2(size.x * 0.4, size.y * 0.52), size.x * 0.07, COLOR_EVENT.lightened(0.35))
	draw_rect(Rect2(size.x * 0.52, size.y * 0.4, size.x * 0.14, size.x * 0.14), COLOR_EVENT.lightened(0.35))


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


## color 매개변수(기본값 COLOR_GUARD)는 K-4a가 추가 — "guard_stack" 모티프가 같은
## 그리기를 재사용하도록(겹겹의 방패는 기믹/모티프 양쪽에서 같은 의미이므로 중복 구현
## 안 함). 기존 호출부(category="guard_stack")는 인자 없이 호출해 색이 그대로 유지된다.
func _draw_layered_shield(color: Color = COLOR_GUARD) -> void:
	_draw_shield_outline(color)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.4), size.x * 0.22, PI * 0.15, PI * 0.85, 10, color.darkened(0.35), 2.0)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.62), size.x * 0.18, PI * 0.15, PI * 0.85, 10, color.darkened(0.35), 2.0)


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
## 삼각형 화살촉)로 "두 다이스가 맞바뀐다"는 저글링/교환 느낌을 근사한다. color
## 매개변수(기본값 COLOR_JUGGLE)는 K-4a가 추가 — "dice_swap" 모티프가 같은 그리기를
## 재사용(다이스를 맞바꾸는 의미가 기믹/모티프 양쪽에서 동일하므로 중복 구현 안 함).
func _draw_swap_arrows(color: Color = COLOR_JUGGLE) -> void:
	var top_y := size.y * 0.34
	var bottom_y := size.y * 0.66
	draw_line(Vector2(size.x * 0.2, top_y), Vector2(size.x * 0.72, top_y), color, 2.5)
	var top_head := PackedVector2Array([
		Vector2(size.x * 0.72, top_y - size.y * 0.1),
		Vector2(size.x * 0.72, top_y + size.y * 0.1),
		Vector2(size.x * 0.88, top_y),
	])
	draw_colored_polygon(top_head, color)
	draw_line(Vector2(size.x * 0.8, bottom_y), Vector2(size.x * 0.28, bottom_y), color.darkened(0.2), 2.5)
	var bottom_head := PackedVector2Array([
		Vector2(size.x * 0.28, bottom_y - size.y * 0.1),
		Vector2(size.x * 0.28, bottom_y + size.y * 0.1),
		Vector2(size.x * 0.12, bottom_y),
	])
	draw_colored_polygon(bottom_head, color.darkened(0.2))


## color 매개변수(기본값 COLOR_EXPLOSIVE)는 K-4a가 추가 — "burst_stack" 모티프가 같은
## 폭발 모양을 재사용(스택이 터져 보너스턴을 주는 의미가 기믹/모티프 양쪽에서
## 동일하므로 중복 구현 안 함).
func _draw_burst(color: Color = COLOR_EXPLOSIVE) -> void:
	var center := size * 0.5
	var outer := size.x * 0.44
	var inner := size.x * 0.18
	var points := PackedVector2Array()
	var spikes := 8
	for i in range(spikes * 2):
		var r: float = outer if i % 2 == 0 else inner
		var a: float = TAU * i / (spikes * 2.0) - PI / 2
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)


## "cannon_volley"(해적) 전용 아이콘 — 비스듬한 포신(사각형) + 포탄(원) + 발사 궤적
## 점선 느낌의 작은 원 2개로 "함포 일제사격"을 근사한다(achievement_icon.gd류처럼
## draw_rect/draw_circle 조합만으로 별도 벡터 에셋 없이 그림).
func _draw_cannon() -> void:
	var barrel := PackedVector2Array([
		Vector2(size.x * 0.18, size.y * 0.78),
		Vector2(size.x * 0.78, size.y * 0.22),
		Vector2(size.x * 0.68, size.y * 0.1),
		Vector2(size.x * 0.08, size.y * 0.66),
	])
	draw_colored_polygon(barrel, COLOR_CANNON.darkened(0.25))
	draw_circle(Vector2(size.x * 0.28, size.y * 0.72), size.x * 0.2, COLOR_CANNON)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.3), size.x * 0.08, COLOR_CANNON)
	draw_circle(Vector2(size.x * 0.84, size.y * 0.16), size.x * 0.05, COLOR_CANNON.lightened(0.15))
