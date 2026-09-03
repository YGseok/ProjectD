class_name DeckPanel
extends PanelContainer
## 화면 한쪽에 상시 떠 있는 "내 덱 보기" 패널 (view-only).
## INBOX.md 피드백(2026-09-03): "내 공격 덱과 방어 덱이 어떤 눈금을 보유한 주사위들인지
## 항상 떠있으면 좋겠다 (전투 중에도, 선택지 중에도)".
##
## STATUS.md 큐 0번 권고("공용 패널을 한 번에 다 하지 말고 '보기 전용 패널 추가'부터
## 작게 시작할 것")를 반영해, 이번 이터레이션에서는 상호작용(커스터마이징) 없이
## 공격/방어 주머니 구성을 보여주기만 한다. 여러 씬(dungeon_map/shop/event/
## story_event)에 그대로 붙여 쓸 수 있도록 스크립트 하나로 완결된 Control이며
## 별도 .tscn이 필요 없다 (shape_die_chip.gd와 같은 패턴).
##
## combat_test.tscn은 화면이 이미 다이스 뷰포트/초상화/로그로 꽉 차 있어 이 패널을
## 넣을 여유 공간이 없다 — 다음 이터레이션에서 레이아웃을 다시 짜야 함 (docs/STATUS.md
## 참고).

const CHIP_SIZE := 20.0
const CHIP_GAP := 3.0
const SECTION_GAP := 10.0

var _vbox: VBoxContainer
var _last_signature := ""


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.4)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)
	_rebuild()


## 커스터마이징/아이템 적용 등으로 RunState의 다이스 구성이 바뀔 수 있으므로, 매
## 프레임 내용을 문자열 서명으로 비교해 실제로 바뀐 경우에만 다시 그린다 (모든
## 호출부에 "덱이 바뀌면 패널도 갱신해라" 배선을 일일이 추가하지 않아도 되게 하기
## 위함 — 다이스 개수가 많아야 수십 개 수준이라 매 프레임 비교 비용은 무시할 만함).
func _process(_delta: float) -> void:
	var sig := _signature()
	if sig != _last_signature:
		_last_signature = sig
		_rebuild()


func _signature() -> String:
	return "%s#%s" % [_bag_signature(RunState.player_attack_bag), _bag_signature(RunState.player_defense_bag)]


func _bag_signature(bag: DiceBag) -> String:
	var s := ""
	for faces in bag.dice:
		s += "["
		for v in faces:
			s += str(v) + ","
		s += "]"
	return s


func _rebuild() -> void:
	for c in _vbox.get_children():
		c.queue_free()
	_add_section("공격 주머니", RunState.player_attack_bag)
	_add_spacer()
	_add_section("방어 주머니", RunState.player_defense_bag)


func _add_section(title_text: String, bag: DiceBag) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_vbox.add_child(title)
	for faces in bag.dice:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", CHIP_GAP)
		for v in faces:
			row.add_child(_make_chip(v))
		_vbox.add_child(row)


func _make_chip(value: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(CHIP_SIZE, CHIP_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.88, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.15, 0.12, 0.08)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = str(value)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08))
	panel.add_child(label)
	return panel


func _add_spacer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, SECTION_GAP)
	_vbox.add_child(spacer)
