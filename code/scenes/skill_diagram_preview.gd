extends Node2D
## [대형 기획 15] Q-7(b)(2026-10-17) QA 디버그 전용 — SkillDiagram이 스킬 37종 전부를
## 실제로 어떻게 그리는지 한 화면(1280x720) 격자로 모아 scripts/qa_shot.sh 캡처로
## 직접 읽고 가독성/일관성을 비평·수정하기 위한 셀프 피드백용 씬이다.
##
## 화면 적용(Q-7c)이 아니다 — 실제 게임 화면(카드/팝업/도감)에는 연결하지 않고,
## 렌더러 자체(SkillDiagram/SkillDiagramChip)만 독립적으로 세워 검증한다.
##
## 기본(= qa_call 없이 그냥 로드)은 SIZE_LARGE 1페이지. qa_shot의 4번째 인자(qa_call)로
## `_debug_show_small`을 호출하면 SIZE_SMALL 격자로, `_debug_show_large_page2`를 호출하면
## LARGE 2페이지(나머지 스킬)로 다시 그려 비교할 수 있다.
##
## Q-7(c)(2026-10-17) 감독 피드백("LARGE 칩이 30px 안팎이라 카드/팝업에서 눈에 안
## 띈다")으로 SkillDiagramChip.CHIP_HEIGHT[LARGE]가 34->44로 커지면서, 기존 5x8(40칸)
## 한 화면에 37종을 다 담던 LARGE 격자가 2줄 예산(44*2+gap)을 감당 못 해(칸당 필요
## 높이가 화면이 줄 수 있는 칸 높이를 넘음) 더는 한 화면에 안 들어간다. SMALL은
## 20px로 그대로라 기존 5x8 한 화면 그대로 유지하고, LARGE만 4열x5행(20칸) 2페이지로
## 나눴다 — 어차피 실제 가독성 판단은 이 합성 격자보다 "실제 화면 컨텍스트"(도감 카드/
## 팝업/보상 카드 등 Q-7(c) 적용 지점) 캡처를 기준으로 한다(INBOX.md 지시).

const SMALL_COLUMNS := 5
const SMALL_CELL_W := 252.0
const SMALL_CELL_H := 85.0

const LARGE_COLUMNS := 4
const LARGE_CELL_W := 300.0
const LARGE_CELL_H := 135.0
const LARGE_PAGE_SIZE := 20

const MARGIN := 10.0

@onready var background: ColorRect = $Background


func _ready() -> void:
	_build_grid(SkillDiagramChip.SIZE_LARGE, 0)


## scripts/qa_shot.sh ... "" "" "" "" "" _debug_show_small 식의 qa_call 인자로 호출된다
## (combat_test.gd의 _debug_open_customize()와 같은 패턴 — 인자 없는 0-arity 래퍼).
func _debug_show_small() -> void:
	_build_grid(SkillDiagramChip.SIZE_SMALL, 0)


func _debug_show_large_page2() -> void:
	_build_grid(SkillDiagramChip.SIZE_LARGE, 1)


func _build_grid(size_variant: int, page: int) -> void:
	for child in get_children():
		if child != background:
			remove_child(child)
			child.queue_free()

	var is_large := size_variant == SkillDiagramChip.SIZE_LARGE
	var columns := LARGE_COLUMNS if is_large else SMALL_COLUMNS
	var cell_w := LARGE_CELL_W if is_large else SMALL_CELL_W
	var cell_h := LARGE_CELL_H if is_large else SMALL_CELL_H

	var all_ids := _all_skill_ids()
	var ids := all_ids
	var page_label := ""
	if is_large:
		var start: int = page * LARGE_PAGE_SIZE
		var end: int = min(start + LARGE_PAGE_SIZE, all_ids.size())
		ids = all_ids.slice(start, end)
		page_label = " (page %d/2, %d-%d of %d)" % [page + 1, start + 1, end, all_ids.size()]

	var label := Label.new()
	label.text = "SkillDiagram 미리보기 — %s%s" % ["LARGE" if is_large else "SMALL", page_label]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label.position = Vector2(MARGIN, 2.0)
	add_child(label)

	var col := 0
	var row := 0
	var top: float = 18.0
	for id in ids:
		var cell_x := MARGIN + float(col) * cell_w
		var cell_y := top + MARGIN + float(row) * cell_h

		var name_label := Label.new()
		var skill := SkillPool.find_skill(id)
		name_label.text = "%s(%s)" % [skill.get("name", id), id]
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88))
		name_label.position = Vector2(cell_x, cell_y)
		name_label.size = Vector2(cell_w - MARGIN, 13)
		name_label.clip_text = true
		add_child(name_label)

		var diagram := SkillDiagram.new()
		diagram.size_variant = size_variant
		diagram.diagram_data = SkillPool.diagram_for(id)
		diagram.position = Vector2(cell_x, cell_y + 14.0)
		diagram.size = Vector2(cell_w - MARGIN * 2.0, cell_h - 16.0)
		add_child(diagram)

		col += 1
		if col >= columns:
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
