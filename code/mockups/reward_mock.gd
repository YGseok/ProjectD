extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28) — 승리 보상 화면 시안(S-5).
##
## "승리 보상"은 따로 씬이 없다 — combat_test.gd가 전투 승리 시 같은 화면 위에
## _show_reward_ui()로 그리는 상태다. 그래서 code/scenes/combat_test.tscn을 그대로
## instantiate()한 뒤, QA 전용 0-arity 훅 _debug_show_reward_after_last_exchange()
## (combat_test.gd가 이미 갖고 있음 — 타이머 await 없이 보상 UI를 즉시 띄우는 QA용
## 메서드, 새로 만든 것 아님)를 호출해 실제 보상 화면 상태로 만든다. 카드/버튼 내용은
## DiceItemPool/ItemCardStyle이 실제로 만드는 데이터 그대로다.

const RealScene := preload("res://code/scenes/combat_test.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	if _real.has_method("_debug_show_reward_after_last_exchange"):
		_real.call("_debug_show_reward_after_last_exchange")
	await get_tree().process_frame

	_patch_reward_layout()
	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


## S-5: "획득/적용" 버튼이 카드 밖으로 나오거나 '커스터마이징' 버튼이 카드 가장자리에
## 걸치는 문제 — combat_test.gd의 _show_reward_ui()는 카드 높이를 REWARD_CARD_HEIGHT
## (250) 상수로 고정하고, 그 "선언값" 기준 고정 오프셋으로 하단 버튼 위치를 잡는다.
## 실제 카드 내용(이름+설명+효과 미리보기+버튼 2개)이 250px보다 크면 PanelContainer가
## 그 쪽으로 커지면서(= Container는 선언한 size보다 작아지지 않음) 하단 버튼과
## 실제로 겹친다. 이 패치는 카드의 **실제** 결합 최소 높이를 측정해 필요하면 카드를
## 그만큼 키우고, 하단 버튼을 "선언값"이 아니라 "실제로 커진 카드들 중 가장 아래"
## 기준으로 다시 배치한다 — 실측값을 쓰므로 어떤 보상 아이템이 뽑혀도 안전하다.
func _patch_reward_layout() -> void:
	var reward_ui: Array = _real.get("_reward_ui")
	if reward_ui == null:
		return

	var cards: Array = []
	var bg_frame: Control = null
	var custom_btn: Button = null
	var skip_btn: Button = null
	for n in reward_ui:
		if n is PanelContainer:
			cards.append(n)
		elif n is Panel and not (n is PanelContainer) and bg_frame == null:
			bg_frame = n
		elif n is Button:
			var text: String = (n as Button).text
			if text.begins_with("커스터마이징"):
				custom_btn = n
			elif text == "건너뛰기":
				skip_btn = n

	var max_bottom := 0.0
	for c in cards:
		var card: Control = c
		var needed: float = card.get_combined_minimum_size().y
		var actual: float = max(needed, card.size.y)
		if actual > card.size.y:
			card.size = Vector2(card.size.x, actual)
		max_bottom = max(max_bottom, card.position.y + actual)

	if max_bottom <= 0.0:
		return
	var btn_y := max_bottom + 10.0
	if custom_btn != null:
		custom_btn.position.y = btn_y
	if skip_btn != null:
		skip_btn.position.y = btn_y
	if bg_frame != null:
		var frame_bottom_needed := btn_y + 46.0
		var frame_rect_bottom: float = bg_frame.position.y + bg_frame.size.y
		if frame_bottom_needed > frame_rect_bottom:
			bg_frame.size = Vector2(bg_frame.size.x, frame_bottom_needed - bg_frame.position.y)


func _patch_buttons() -> void:
	var cid := RunState.character_id
	var action_buttons: Array = _real.get("_reward_action_buttons")
	if action_buttons != null:
		for n in action_buttons:
			if n is Button:
				MockupCommon.restyle_button(n, cid, false, "B")
	var deck_btn: Button = _real.get("deck_toggle_button")
	if deck_btn != null:
		MockupCommon.restyle_button(deck_btn, cid, false, "B")


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(160, 249, 780, 260), "number": 1, "label": "보상 카드(좌/우)"},
		{"rect": Rect2(160, 509, 540, 46), "number": 2, "label": "하단 보조 행동(커스터마이징/건너뛰기)"},
	])
