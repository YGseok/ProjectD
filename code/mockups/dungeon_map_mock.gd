extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28, 1단계 와이어프레임 반려 후) — 던전 맵 시안
## (S-5/S-7a).
##
## 1단계 반려 사유: 방 카드가 "빈 막대"로만 남아 실제 맵 내용(전투/상점/정예 보상
## 아이콘, 계열 아이콘, HUD, DeckPanel)이 전혀 안 보였다.
## 재작업: code/scenes/dungeon_map.tscn을 그대로 instantiate()한다 — HUD/방 선택지/
## DeckPanel은 실제 씬이 그대로 그리므로 손댈 필요가 없다. 2026-10-27 사용자 피드백
## 중 "오른쪽 정보 패널이 화면 밖으로 잘림" 문제는 project.godot stretch(canvas_items+
## keep, 커밋 fccc35d) 추가로 이미 해결됐을 가능성이 커서(S-5 질문 1 참고), 이 시안은
## 그 부분을 좌표로 다시 고치지 않고 1280x720/1100x620/1600x900 세 해상도로 실제
## 재확인만 한다(qa_shot.sh가 아니라 scripts/qa_mockup_multi_res.sh로 캡처). 이
## 시안이 실제로 패치하는 것은 S-7a(아이콘이 세로로 늘어남) 하나뿐이다.

const RealScene := preload("res://code/scenes/dungeon_map.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	_patch_icon_aspect()
	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


## S-7a: RewardIcon/FamilyIcon이 HBoxContainer 기본 SIZE_FILL 때문에 세로로 늘어나
## 눌려 보인다(VISUAL_STANDARD.md 6-2 코드 레벨 원인). 트리 전체에서 두 타입을 찾아
## SHRINK_CENTER로 고정한다 — 어떤 방 구성(전투/상점/정예 등)이 떠 있어도 전수 적용.
func _patch_icon_aspect() -> void:
	var found: Array = []
	MockupCommon.find_nodes(_real, func(n): return n is RewardIcon or n is FamilyIcon, found)
	for icon in found:
		MockupCommon.fix_icon_aspect(icon)


func _patch_buttons() -> void:
	var cid := RunState.character_id
	var secondary_names := ["enter_shop_button", "enter_event_button", "enter_story_button", "enter_elite_button", "customize_button", "skill_codex_button", "quit_run_button"]
	for n in secondary_names:
		var b: Button = _real.get(n)
		if b != null:
			MockupCommon.restyle_button(b, cid, false, "B")
	var primary: Button = _real.get("enter_combat_button")
	if primary != null:
		MockupCommon.restyle_button(primary, cid, true, "B")


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(350, 300, 340, 140), "number": 1, "label": "방 선택지 목록(위/아래 순환)"},
		{"rect": Rect2(740, 20, 500, 40), "number": 2, "label": "상단 HUD 보조 버튼(정비/도감/던전 포기, 좌/우)"},
	])
