extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28) — 몬스터 도감 화면 시안(S-2 핵심 사례).
##
## MonsterCodexPanel은 따로 씬이 없다 — character_select.tscn의 자식으로 상시 존재
## 하다가 "몬스터 도감" 버튼으로 open()된다. code/scenes/character_select.tscn을 그대로
## instantiate()한 뒤 실제 open()을 호출한다. VISUAL_STANDARD.md 2-2절이 실측으로 확인한
## "필터 줄 '전체' 글자 대비 1.86:1 FAIL"(장식 아이콘이 글자와 겹침)이 이 화면의 핵심
## 반영 대상이다.
##
## MOCKUP_VARIANT 환경변수("A"/"B", 기본 "A")로 필터 칩 장식 방향을 고른다 —
## character_select_mock.gd와 같은 트릭.

const RealScene := preload("res://code/scenes/character_select.tscn")

var _real: Node
var _variant: String
var _key_overlay: KeyOverlay


func _ready() -> void:
	_variant = OS.get_environment("MOCKUP_VARIANT")
	if _variant != "B":
		_variant = "A"

	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	var codex: Node = _real.get("monster_codex_panel")
	if codex != null and codex.has_method("open"):
		codex.call("open")
	await get_tree().process_frame

	_patch_filter_chips()
	_patch_icon_aspect()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


## S-2 핵심: "전체"(가족/티어 둘 다) 필터 칩의 글자-장식 대비가 실측 1.86:1로 기준
## 미달이었다. _family_filter_buttons/_tier_filter_buttons(Dictionary, key -> Button)를
## 그대로 가져와 A/B 두 방향으로 다시 스킨한다.
func _patch_filter_chips() -> void:
	var codex: Node = _real.get("monster_codex_panel")
	if codex == null:
		return
	var cid := RunState.character_id
	for dict_name in ["_family_filter_buttons", "_tier_filter_buttons"]:
		var buttons: Dictionary = codex.get(dict_name)
		if buttons == null:
			continue
		for key in buttons.keys():
			var btn: Button = buttons[key]
			if btn == null:
				continue
			# 활성(선택된) 칩은 primary, 비활성은 secondary — _make_filter_button()과
			# 같은 판정(활성 칩의 modulate가 1,1,1인지로 구분).
			var active: bool = btn.modulate.a >= 0.99 and btn.modulate.r >= 0.99
			MockupCommon.restyle_button(btn, cid, active, _variant)


func _patch_icon_aspect() -> void:
	var codex: Node = _real.get("monster_codex_panel")
	if codex == null:
		return
	var found: Array = []
	MockupCommon.find_nodes(codex, func(n): return n is RewardIcon or n is FamilyIcon, found)
	for icon in found:
		MockupCommon.fix_icon_aspect(icon)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(70, 84, 1100, 32), "number": 1, "label": "필터 줄(계열/티어, 좌/우)"},
		{"rect": Rect2(70, 130, 1100, 520), "number": 2, "label": "카드 격자(4방향 순환)"},
		{"rect": Rect2(1140, 44, 80, 32), "number": 3, "label": "닫기"},
	])
