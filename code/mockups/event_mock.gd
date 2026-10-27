extends Node2D
## [대형 기획 17] S-0 시안 — 특수 이벤트 화면 개편안(S-5/S-3/S-6). 고정 예시 데이터
## ("도박" 챌린지)만 쓰는 정적 시안.

const CHARACTER_ID := "novice"

var _key_overlay: KeyOverlay


func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = Vector2(1280, 720)
	add_child(bg)
	CharacterTheme.apply_background(self, CHARACTER_ID)

	var title := Label.new()
	title.text = "특수 이벤트 — 도박"
	title.position = Vector2(40, 24)
	title.add_theme_font_size_override("font_size", 20)
	CharacterTheme.apply_label(title, CHARACTER_ID, true)
	add_child(title)

	var backdrop := UIKit.make_backdrop(self, CHARACTER_ID, Rect2(140, 100, 1000, 140), MockupCommon.FLAT_SKIN_DIR)
	var prompt := Label.new()
	prompt.text = "낯선 도박꾼이 주사위 판을 펼친다. 걸어볼까, 그냥 지나칠까?"
	prompt.position = Vector2(164, 124)
	prompt.size = Vector2(952, 92)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD
	prompt.add_theme_font_size_override("font_size", 15)
	prompt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	add_child(prompt)

	# S-5: 선택지 줄(y=280)이 위 상황 패널(y=100~240) 아래로 충분히(40px) 떨어져 있어
	# 겹치지 않는다(실제 화면에서 보고된 "전투/특수 이벤트 줄이 카드와 겹침" 재발 방지).
	var safe_btn := Button.new()
	safe_btn.text = "안전하게 넘어가기 (골드 +8)"
	safe_btn.position = Vector2(140, 280)
	safe_btn.size = Vector2(480, 56)
	UIKit.style_secondary_button(safe_btn, CHARACTER_ID, Color(0.3, 0.62, 0.35), MockupCommon.FLAT_SKIN_DIR)
	add_child(safe_btn)

	var risky_btn := Button.new()
	risky_btn.text = "위험을 감수하기 (D6, 4+ 성공/7+ 대성공)"
	risky_btn.position = Vector2(660, 280)
	risky_btn.size = Vector2(480, 56)
	UIKit.style_secondary_button(risky_btn, CHARACTER_ID, Color(0.82, 0.38, 0.18), MockupCommon.FLAT_SKIN_DIR)
	add_child(risky_btn)

	var deck_btn := Button.new()
	deck_btn.text = "덱 보기"
	deck_btn.position = Vector2(140, 360)
	deck_btn.size = Vector2(160, 40)
	UIKit.style_secondary_button(deck_btn, CHARACTER_ID, Color(0, 0, 0, 0), MockupCommon.FLAT_SKIN_DIR)
	add_child(deck_btn)

	MockupCommon.make_status_bar(self, "둘 중 하나를 선택해야 다음 방으로 넘어갈 수 있습니다.", Rect2(140, 664, 1000, 40))

	_key_overlay = KeyOverlay.new()
	_key_overlay.visible = false
	add_child(_key_overlay)


func _debug_show_key_overlay() -> void:
	_key_overlay.visible = true
	_key_overlay.set_steps([
		{"rect": Rect2(140, 280, 480, 56), "number": 1, "label": "선택지(좌/우)"},
		{"rect": Rect2(660, 280, 480, 56), "number": 1, "label": ""},
		{"rect": Rect2(140, 360, 160, 40), "number": 2, "label": "보조 버튼"},
	])
