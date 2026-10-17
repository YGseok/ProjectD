extends Node2D
## [대형 기획 15] Q-7(b)(2026-10-17) QA 디버그 전용 — SkillDiagram이 스킬 37종 전부를
## 실제로 어떻게 그리는지 한 화면(1280x720) 격자로 모아 scripts/qa_shot.sh 캡처로
## 직접 읽고 가독성/일관성을 비평·수정하기 위한 셀프 피드백용 씬이다.
##
## 화면 적용(Q-7c)이 아니다 — 실제 게임 화면(카드/팝업/도감)에는 연결하지 않고,
## 렌더러 자체(SkillDiagram/SkillDiagramChip)만 독립적으로 세워 검증한다.
##
## 기본(= qa_call 없이 그냥 로드)은 SIZE_LARGE 격자. qa_shot의 4번째 인자(qa_call)로
## `_debug_show_small`을 호출하면 SIZE_SMALL 격자로 다시 그려 두 크기를 각각 캡처해
## 비교할 수 있다.

## 37종 스킬 전부(SKILLS 2 + UNIQUE_SKILLS 9 + UPGRADE_SKILLS 11 + STARTING_SKILLS
## 고유 15)를 5열×8행 격자로 1280x720 한 화면 안에 겹침 없이 담는다. 1차 셀프
## 피드백 캡처(4열×10행, CELL_H=72)에서 마지막 행("잡화점")이 화면 아래로 살짝
## 잘렸던 것을 보고 열을 늘리고 행을 줄여 고쳤다.
const COLUMNS := 5
const CELL_W := 252.0
const CELL_H := 85.0
const MARGIN := 10.0

@onready var background: ColorRect = $Background


func _ready() -> void:
	_build_grid(SkillDiagramChip.SIZE_LARGE)


## scripts/qa_shot.sh ... "" "" "" "" "" _debug_show_small 식의 qa_call 인자로 호출된다
## (combat_test.gd의 _debug_open_customize()와 같은 패턴 — 인자 없는 0-arity 래퍼).
func _debug_show_small() -> void:
	_build_grid(SkillDiagramChip.SIZE_SMALL)


func _build_grid(size_variant: int) -> void:
	for child in get_children():
		if child != background:
			remove_child(child)
			child.queue_free()

	var label := Label.new()
	label.text = "SkillDiagram 미리보기 — %s" % ("LARGE" if size_variant == SkillDiagramChip.SIZE_LARGE else "SMALL")
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label.position = Vector2(MARGIN, 2.0)
	add_child(label)

	var ids := _all_skill_ids()
	var col := 0
	var row := 0
	var top: float = 18.0
	for id in ids:
		var cell_x := MARGIN + float(col) * CELL_W
		var cell_y := top + MARGIN + float(row) * CELL_H

		var name_label := Label.new()
		var skill := SkillPool.find_skill(id)
		name_label.text = "%s(%s)" % [skill.get("name", id), id]
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
		name_label.position = Vector2(cell_x, cell_y)
		name_label.size = Vector2(CELL_W - MARGIN, 13)
		name_label.clip_text = true
		add_child(name_label)

		var diagram := SkillDiagram.new()
		diagram.size_variant = size_variant
		diagram.diagram_data = SkillPool.diagram_for(id)
		diagram.position = Vector2(cell_x, cell_y + 14.0)
		diagram.size = Vector2(CELL_W - MARGIN * 2.0, CELL_H - 16.0)
		add_child(diagram)

		col += 1
		if col >= COLUMNS:
			col = 0
			row += 1


func _all_skill_ids() -> Array:
	var seen: Dictionary = {}
	var ids: Array = []
	for group in [SkillPool.SKILLS, SkillPool.UNIQUE_SKILLS, SkillPool.UPGRADE_SKILLS, SkillPool.STARTING_SKILLS]:
		for skill in group:
			var id: String = skill["id"]
			if not seen.has(id):
				seen[id] = true
				ids.append(id)
	return ids
