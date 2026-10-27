extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28) — 정비(커스터마이징) 화면 시안(S-5).
##
## CustomizePanel은 따로 씬이 없다 — dungeon_map.tscn의 자식(CustomizePanel 노드)으로
## 상시 존재하다가 "정비" 버튼으로 open()된다. 그래서 code/scenes/dungeon_map.tscn을
## 그대로 instantiate()한 뒤 실제 open()을 호출해 실제 패널 상태를 그대로 보여준다
## (고정 예시 데이터로 다시 그리지 않음).
##
## MOCKUP_REVIEW.md 7절 질문: 실제 코드는 이미 "수동 clip+position 스크롤 + 포커스
## 이동마다 닫기 버튼이 보이도록 자동 스크롤"(_ensure_step_button_visible(), 과거
## 셀프 피드백으로 추가됨)을 쓰고 있어, 1단계 시안이 가정했던 "ScrollContainer로
## 바꿔야 한다"는 전제가 이미 낡았을 수 있다 — 이번 재작업은 그 로직을 건드리지 않고
## 실제 동작을 그대로 캡처해 확인한다(S-6 버튼 장식만 패치).

const RealScene := preload("res://code/scenes/dungeon_map.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	var customize_panel: Node = _real.get("customize_panel")
	if customize_panel != null and customize_panel.has_method("open"):
		customize_panel.call("open")
	await get_tree().process_frame

	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


func _patch_buttons() -> void:
	var cid := RunState.character_id
	var customize_panel: Node = _real.get("customize_panel")
	if customize_panel == null:
		return
	var content_root: Node = customize_panel.get("_content_root")
	if content_root == null:
		return
	var buttons: Array = []
	MockupCommon.find_nodes(content_root, func(n): return n is Button, buttons)
	for b in buttons:
		MockupCommon.restyle_button(b, cid, false, "B")


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(40, 100, 360, 560), "number": 1, "label": "보유 눈금/다이스 목록(위/아래)"},
		{"rect": Rect2(420, 100, 500, 560), "number": 2, "label": "적용 대상 선택(위/아래)"},
		{"rect": Rect2(40, 664, 1200, 40), "number": 3, "label": "적용/취소/닫기(좌/우)"},
	])
