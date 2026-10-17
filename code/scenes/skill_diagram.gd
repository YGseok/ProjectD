class_name SkillDiagram
extends HFlowContainer
## [대형 기획 15] Q-7(b)(2026-10-17) 신규 — SkillPool.diagram_for(skill_id)가 돌려주는
## "조건 칩... -> 효과 칩..." 배열(최대 SkillPool.MAX_DIAGRAM_SYMBOLS개)을 받아
## SkillDiagramChip(기호 1개당 1칩)을 가로로 배치하는 재사용 위젯.
##
## HFlowContainer를 바로 extends해서, 폭이 모자라면 Godot 엔진이 자동으로 다음 줄로
## 넘긴다(INBOX.md "한 줄(최대 2줄)" 요구 — 직접 줄바꿈 로직을 만들지 않음). 실제
## 줄바꿈은 이 노드의 size.x(폭)에 좌우되므로, 호출부가 폭을 고정해야 한다 —
## 카드/팝업처럼 고정폭 부모(Container) 안에 두면 자동으로 그 폭을 따른다.
##
## 크기 2종: SkillDiagramChip.SIZE_LARGE(카드/팝업용)/SIZE_SMALL(툴팁/목록용).
## diagram_data 또는 size_variant를 바꾸면 기존 칩을 전부 지우고 다시 만든다.

var diagram_data: Array = []:
	set(v):
		diagram_data = v
		_rebuild()

var size_variant: int = SkillDiagramChip.SIZE_LARGE:
	set(v):
		size_variant = v
		_rebuild()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var gap: float = 4.0 if size_variant == SkillDiagramChip.SIZE_LARGE else 2.0
	add_theme_constant_override("h_separation", int(gap))
	add_theme_constant_override("v_separation", int(gap))
	for entry in diagram_data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var chip := SkillDiagramChip.new()
		chip.setup(entry, size_variant)
		add_child(chip)


## skill_id 하나로 바로 세팅하는 편의 헬퍼(Q-7(c) 적용부가 쓸 용도) — SkillPool을
## 직접 참조하지만 분기는 없음(그 함수가 data lookup만 함).
func set_skill(skill_id: String) -> void:
	diagram_data = SkillPool.diagram_for(skill_id)
