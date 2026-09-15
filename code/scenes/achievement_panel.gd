class_name AchievementPanel
extends Control
## 업적 목록을 보여주는 오버레이 (INBOX.md 2026-09-09 "[대형 기획 3] 업적 시스템").
##
## AchievementManager(Autoload)가 들고 있는 정의/해금 상태를 그대로 읽어 보여주기만
## 하는 view-only 패널 — customize_panel.gd/deck_panel.gd와 같은 "스크립트 하나로
## 완결된 Control, 별도 .tscn 불필요" 패턴을 따른다. 아무 씬에나 Control 노드를 만들고
## 이 스크립트만 붙이면 동작한다.

signal closed

var _ui: Array[Node] = []

## KeyboardShortcuts로 "닫기" 버튼에 "[1] " 단축키를 배정하는 데 쓴다(INBOX.md
## 2026-09-14 "키보드로도 조작이 되도록" — docs/STATUS.md 큐 16 "키보드 조작/단축키"
## 마지막 남은 화면, 지금은 버튼이 "닫기" 하나뿐이라 배열도 항상 1개짜리). 다른 5개
## 화면과 같은 패턴을 재사용하되, 이 패널은 스스로 씬을 바꾸지 않으므로(close()는
## visible=false만 함) 5개 화면에서 겪었던 "get_viewport()를 try_press() 이후에 부르면
## 크래시" 문제와는 무관하다 — 그래도 일관성을 위해 미리 받아두는 순서를 그대로 따른다.
var _shortcut_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open() -> void:
	visible = true
	_rebuild()


func close() -> void:
	_clear_ui()
	visible = false
	closed.emit()


func _clear_ui() -> void:
	for node in _ui:
		node.queue_free()
	_ui.clear()


## QA 전용: 목록 스크롤을 맨 아래로 내려, 위쪽 카드에 가려 안 보이던 나머지 업적
## (pip/bag/shop/material 아이콘 등)도 스크린샷 한 장으로 확인할 수 있게 한다.
func _debug_scroll_to_bottom() -> void:
	for node in _ui:
		if node is ScrollContainer:
			node.scroll_vertical = 100000
			return


func _rebuild() -> void:
	_clear_ui()

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.position = Vector2(140, 80)
	bg.size = Vector2(1000, 560)
	add_child(bg)
	_ui.append(bg)

	var entries := AchievementManager.get_all_for_display()
	var unlocked_count := 0
	for e in entries:
		if e.unlocked:
			unlocked_count += 1

	var title := Label.new()
	title.text = "업적 (%d / %d 달성)" % [unlocked_count, entries.size()]
	title.position = Vector2(170, 100)
	title.size = Vector2(940, 30)
	add_child(title)
	_ui.append(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(170, 140)
	scroll.size = Vector2(940, 440)
	add_child(scroll)
	_ui.append(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(920, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for e in entries:
		list.add_child(_make_row(e))

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.position = Vector2(570, 592)
	close_button.size = Vector2(140, 36)
	close_button.pressed.connect(close)
	add_child(close_button)
	_ui.append(close_button)

	_shortcut_buttons = [close_button]
	KeyboardShortcuts.apply_hints(_shortcut_buttons)


## 숫자 키(1)로 "닫기" 버튼을 누른다(다른 5개 화면과 같은 패턴 재사용). 패널이
## 닫혀 있을 때는(visible=false) 뒤에 가려진 character_select 화면의 카드/버튼이
## 함께 눌리지 않도록 무시한다 — character_select.gd도 이 패널이 열려 있을 때 자신의
## 단축키를 무시하도록 이미 가드돼 있으므로 서로 겹치지 않는다.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var idx := KeyboardShortcuts.digit_index(event)
	if idx < 0:
		return
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press(_shortcut_buttons, idx) and viewport != null:
		viewport.set_input_as_handled()


func _make_row(entry: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(920, 60)

	var style := StyleBoxFlat.new()
	style.content_margin_left = 14
	style.content_margin_top = 8
	style.content_margin_right = 14
	style.content_margin_bottom = 8
	style.set_corner_radius_all(6)
	if entry.unlocked:
		style.bg_color = Color(0.25, 0.2, 0.05, 0.85)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.85, 0.68, 0.25)
	else:
		style.bg_color = Color(0.12, 0.12, 0.12, 0.85)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.35, 0.35, 0.35)
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	var icon := AchievementIcon.new()
	icon.category = entry.get("icon", "milestone")
	icon.custom_minimum_size = Vector2(36, 36)
	if not entry.unlocked:
		icon.modulate = Color(1, 1, 1, 0.4)
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var title := Label.new()
	title.text = ("★ " if entry.unlocked else "🔒 ") + entry.title
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5) if entry.unlocked else Color(0.6, 0.6, 0.6))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = entry.desc
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8) if entry.unlocked else Color(0.5, 0.5, 0.5))
	vbox.add_child(desc)

	return row
