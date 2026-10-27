extends Node2D
## [대형 기획 17] S-0 시안 — 상점 화면 개편안(S-5/S-6). 고정 예시 데이터(DiceItemPool의
## 실제 아이템 4종, 보유 골드 85)만 쓰는 정적 시안.

const CHARACTER_ID := "novice"
const PRICES := [30, 60, 25, 55]

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	var title := Label.new()
	title.text = "상점 — 골드로 다이스를 개조하세요"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	var hud := UIKit.make_bar(self, CHARACTER_ID, Vector2(40, 56), MockupCommon.FLAT_SKIN_DIR)
	var gold_icon := RewardIcon.new()
	gold_icon.category = "gold"
	gold_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gold_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UIKit.make_stat_chip(hud, gold_icon, "85", "보유 골드", CHARACTER_ID, MockupCommon.FLAT_SKIN_DIR)

	_build_item_grid()
	_build_bottom_buttons()

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 112, 724, 428), "number": 1, "label": "품목 격자(4방향)"},
		{"rect": Rect2(40, 650, 700, 44), "number": 2, "label": "하단 보조 버튼"},
	])


func _build_item_grid() -> void:
	var items := DiceItemPool.ITEMS
	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(140, 112)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	add_child(grid)
	for i in items.size():
		var item: Dictionary = items[i]
		var price: int = PRICES[i]
		var unaffordable: bool = price > 85
		var result := ItemCardStyle.build_card(item, "%d 골드" % price, unaffordable, false, MockupCommon.FLAT_SKIN_DIR)
		var card: Control = result["card"]
		card.custom_minimum_size = Vector2(440, 190)
		card.size = Vector2(440, 190)
		var buy_btn := Button.new()
		buy_btn.text = "구매"
		buy_btn.custom_minimum_size = Vector2(0, 36)
		buy_btn.disabled = unaffordable
		# S-5: 버튼은 button_row(카드 본문 VBox 맨 아래)에 들어가 카드 content_margin
		# 안쪽에 자연히 맞춰진다 — 카드 밖으로 튀어나오지 않음(기존 승리 보상 화면에서
		# 보고된 문제의 재현 방지).
		UIKit.style_secondary_button(buy_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		(result["button_row"] as Control).add_child(buy_btn)
		grid.add_child(card)


func _build_bottom_buttons() -> void:
	var leave_btn := Button.new()
	leave_btn.text = "던전으로 돌아가기"
	leave_btn.position = Vector2(540, 650)
	leave_btn.size = Vector2(200, 44)
	UIKit.style_primary_button(leave_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(leave_btn)

	var customize_btn := Button.new()
	customize_btn.text = "커스터마이징"
	customize_btn.position = Vector2(40, 650)
	customize_btn.size = Vector2(180, 44)
	UIKit.style_secondary_button(customize_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(customize_btn)
