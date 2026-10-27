extends Node2D
## [대형 기획 17] S-0 재작업(2026-10-28) — 상점 화면 시안(S-5, S-6).
##
## code/scenes/shop.tscn을 그대로 instantiate()한다. 코드를 읽어보니 카드 겹침
## 문제(MOCKUP_REVIEW.md 1단계가 가정했던 "품목이 늘어나면 겹칠 수 있다")는 이미
## shop.gd._rebuild_items()의 row_step(235, 효과 미리보기로 카드가 자연히 커지는
## 것까지 감안해 조정된 값)으로 처리돼 있었다 — 이 시안은 레이아웃을 다시 고치지
## 않고, 실제 "골드 부족" 상태(_debug_show_partial_gold, 기존 QA 훅)까지 보여준 뒤
## 버튼 장식만 패치해 재확인한다.

const RealScene := preload("res://code/scenes/shop.tscn")

var _real: Node
var _key_overlay: KeyOverlay


func _ready() -> void:
	_real = RealScene.instantiate()
	add_child(_real)
	await get_tree().process_frame

	if _real.has_method("_debug_show_partial_gold"):
		_real.call("_debug_show_partial_gold")
	await get_tree().process_frame

	_patch_card_grid_overlap()
	_patch_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _qa_is_settled() -> bool:
	return true


## S-5 발견 사항(1단계 시안에는 없던, 실제 씬을 그대로 띄워보고서야 드러난 문제) —
## "골드 부족" 배지(unaffordable=true)가 붙으면 카드 설명 줄에 "골드 부족" 텍스트가
## 추가로 들어가 카드 높이가 shop.gd의 row_step(235, 효과 미리보기 기준으로만 맞춘 값)
## 보다 커질 수 있고, 그러면 2행 카드 하단이 "던전으로 돌아가기"/"커스터마이징" 버튼
## 줄(y=650)과 거의 맞닿는다. 실측 카드 하단을 기준으로 버튼 줄을 그 아래로 민다
## (실제 씬 파일은 고치지 않음 — 본 구현 때 row_step 공식에 반영할 몫).
func _patch_card_grid_overlap() -> void:
	var row_ui: Array = _real.get("_row_ui")
	var items_root: Node2D = _real.get("items_root")
	if row_ui == null or items_root == null:
		return
	var max_bottom := 0.0
	for c in row_ui:
		if c is Control:
			var card: Control = c
			max_bottom = max(max_bottom, items_root.position.y + card.position.y + card.size.y)
	var needed_button_y := max_bottom + 16.0
	if needed_button_y <= 650.0:
		return
	# 화면 밖으로 밀려나지 않게 674(버튼 높이 45 기준 바닥 719)로 못박는다 — 그보다
	# 카드가 더 커지면(이번 예시 데이터에선 재현 안 됨) 버튼과 살짝 맞닿을 수 있다는
	# 뜻이므로, 그 경우는 row_step 자체를 손볼 몫으로 MOCKUP_REVIEW.md에 남긴다.
	needed_button_y = min(needed_button_y, 674.0)
	for n in ["leave_button", "customize_button"]:
		var b: Button = _real.get(n)
		if b != null:
			b.position.y = needed_button_y


func _patch_buttons() -> void:
	var cid := RunState.character_id
	var shortcut_buttons: Array = _real.get("_shortcut_buttons")
	if shortcut_buttons == null:
		return
	var leave_btn: Button = _real.get("leave_button")
	for b in shortcut_buttons:
		if b == leave_btn:
			MockupCommon.restyle_button(b, cid, true, "B")
		else:
			MockupCommon.restyle_button(b, cid, false, "B")


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 100, 680, 470), "number": 1, "label": "품목 카드 격자(4방향)"},
		{"rect": Rect2(40, 650, 300, 45), "number": 2, "label": "던전으로 돌아가기 + 보조 버튼(좌/우)"},
	])
