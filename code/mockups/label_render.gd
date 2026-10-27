extends Node2D
## [대형 기획 17] S-0 재작업 — compare 이미지용 "전"/"후" 라벨을 한 번만 정상 해상도
## (1280x720, 이 환경에서 안정적으로 동작 확인된 유일한 창 크기)로 그려서 캡처한 뒤,
## code/qa/mockup_compare.gd(헤드리스, 창 없이 순수 Image API)가 그 라벨 영역만 잘라
## 아무 크기의 비교 캔버스에나 재사용한다 — 이 환경의 디스플레이가 2592x760 같은 큰
## 창을 띄우지 못해(실측: 요청해도 1280x720으로 다시 clamp됨) compare_view.gd를 직접
## 그 크기로 캡처할 수 없었던 문제의 우회.

const BG := Color(0.04, 0.04, 0.05)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(1280, 720)
	add_child(bg)

	_add_label("전", Vector2(40, 40))
	_add_label("후", Vector2(680, 40))


func _add_label(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
