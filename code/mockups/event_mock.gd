extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28) — 특수 이벤트 화면 시안(S-3 재사용 사례, S-6).
##
## code/scenes/event.tscn을 그대로 instantiate()한다 — 배경/서사 텍스트/안전·위험
## 선택지는 실제 씬이 그대로 그린다. 이 화면은 상태 메시지 바(S-3)를 캐릭터 선택
## 외의 화면에 재사용하는 두 번째 사례다.

const RealScene := preload("res://code/scenes/event.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	# event.gd._ready()는 매번 스킬/아이템 이벤트 중 하나를 무작위로 고른다(SKILL_EVENT_
	# CHANCE). 이 시안의 상태 메시지 바는 "안전/위험 선택지" 문구를 쓰므로, 기존 QA 훅
	# _debug_force_challenge_treasure()(2026-09-15부터 있던 결정적 보물 이벤트 강제 훅)로
	# 그 상태를 확정해 문구와 화면이 항상 맞물리게 한다.
	if _real.has_method("_debug_force_challenge_treasure"):
		_real.call("_debug_force_challenge_treasure")
	await get_tree().process_frame

	_patch_status_bar()
	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


## S-3: "안전/위험" 선택 전이라는 지금 상태를 바 형태로 알려준다. DeckPanel(x=980~1240)과
## 안 겹치게 폭을 960까지로 제한하고, 하단 버튼 줄(y=650~695)과 안 겹치게 그 위
## 빈 공간(FailLabel 영역 아래, 실제로는 선택 전엔 비어 있음)에 둔다.
func _patch_status_bar() -> void:
	MockupCommon.make_status_bar(
		self,
		"\"안전하게 넘어가기\" 또는 \"위험을 감수하기\" 중 하나를 선택하세요.",
		Rect2(40, 600, 920, 40))


func _patch_buttons() -> void:
	var cid := RunState.character_id
	var continue_btn: Button = _real.get("continue_button")
	if continue_btn != null:
		MockupCommon.restyle_button(continue_btn, cid, true, "B")
	for n in ["customize_button", "skill_codex_button"]:
		var b: Button = _real.get(n)
		if b != null:
			MockupCommon.restyle_button(b, cid, false, "B")
	# safe/risky는 장식이 아니라 "안전/위험" 의미를 나타내는 녹/주황 틴트(2순위 정보)라
	# VISUAL_STANDARD.md가 말하는 "장식"과 다른 신호로 보고 색 자체는 유지한다 — 다만
	# 텍스트 대비를 보강하는 외곽선만 A안 패턴으로 추가한다.
	for n in ["safe_button", "risky_button"]:
		var b: Button = _real.get(n)
		if b != null:
			b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
			b.add_theme_constant_override("outline_size", 3)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(260, 140, 760, 60), "number": 1, "label": "선택지(안전/위험, 좌/우)"},
		{"rect": Rect2(40, 650, 300, 45), "number": 2, "label": "하단 보조 버튼(좌/우)"},
	])
