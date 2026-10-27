extends Node2D
## [대형 기획 17] S-0 시안 — 승리 보상 화면 개편안(S-5). 고정 예시 데이터(DiceItemPool
## 아이템 3종 보상 선택)만 쓰는 정적 시안.
##
## 반영한 기준: 카드 높이(210)가 "획득" 버튼까지 포함한 실제 콘텐츠 높이보다 넉넉해
## 버튼이 카드 밖으로 나오지 않고, "커스터마이징" 버튼은 화면 왼쪽 가장자리에서
## 40px 띄워(기존 보고된 "카드 가장자리에 걸침" 방지) 배치한다.

const CHARACTER_ID := "novice"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	var title := Label.new()
	title.text = "승리! 보상을 하나 고르세요"
	title.position = Vector2(40, 20)
	title.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	var row := HBoxContainer.new()
	row.position = Vector2(140, 100)
	row.add_theme_constant_override("separation", 24)
	add_child(row)

	var items := DiceItemPool.ITEMS
	for i in min(3, items.size()):
		var item: Dictionary = items[i]
		var result := ItemCardStyle.build_card(item, "", false, false, MockupCommon.FLAT_SKIN_DIR)
		var card: Control = result["card"]
		card.custom_minimum_size = Vector2(300, 220)
		card.size = Vector2(300, 220)
		var take_btn := Button.new()
		take_btn.text = "획득"
		take_btn.custom_minimum_size = Vector2(0, 36)
		UIKit.style_secondary_button(take_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
		(result["button_row"] as Control).add_child(take_btn)
		row.add_child(card)

	var next_btn := Button.new()
	next_btn.text = "다음"
	next_btn.position = Vector2(560, 660)
	next_btn.size = Vector2(160, 44)
	UIKit.style_primary_button(next_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(next_btn)

	# S-5: 카드 영역 좌측(140)보다 안쪽(40)이지만 화면 가장자리(0)에서는 충분히(40px)
	# 떨어져 있어 "카드 가장자리에 걸침" 문제가 재현되지 않는다.
	var customize_btn := Button.new()
	customize_btn.text = "커스터마이징"
	customize_btn.position = Vector2(40, 660)
	customize_btn.size = Vector2(180, 44)
	UIKit.style_secondary_button(customize_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(customize_btn)

	var deck_btn := Button.new()
	deck_btn.text = "덱 보기"
	deck_btn.position = Vector2(1060, 660)
	deck_btn.size = Vector2(180, 44)
	UIKit.style_secondary_button(deck_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(deck_btn)

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 100, 816, 220), "number": 1, "label": "보상 카드(좌/우)"},
		{"rect": Rect2(40, 660, 1200, 44), "number": 2, "label": "하단 보조 버튼"},
	])
