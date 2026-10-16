class_name ConfirmDialog
extends Control
## 범용 확인(예/아니오) 모달 — SkillDetailPopup과 같은 "화면 전체를 덮는 어두운 backdrop +
## 중앙 박스" 구조를 공유한다(INBOX.md [대형 기획 15] Q-4b 원문 21, "던전 포기" 확인에
## 처음 쓰였다). open(message, character_id, confirm_text, cancel_text)로 열고, 실제
## 동작(런 폐기 등)은 호출부가 confirmed 시그널에 연결해서 수행한다 — 이 클래스 자신은
## "확인했는지 아닌지"만 알릴 뿐 무엇을 확인하는지는 전혀 모른다(재사용 가능하게).
##
## 닫기(=취소)는 SkillDetailPopup과 동일하게 세 갈래: 배경 클릭 / 취소 버튼 / Esc.
## 확인 버튼을 누르면 confirmed를, 그 외 전부(취소 버튼/배경 클릭/Esc)는 cancelled를
## emit한다.

signal confirmed
signal cancelled

const BOX_SIZE := Vector2(520, 220)

var _ui: Array[Node] = []
var _box: Panel
var _confirm_button: Button
var _cancel_button: Button


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open(message: String, character_id: String, confirm_text: String = "확인", cancel_text: String = "취소") -> void:
	visible = true
	_rebuild(message, character_id, confirm_text, cancel_text)


func close() -> void:
	_clear_ui()
	visible = false


func _clear_ui() -> void:
	for node in _ui:
		if is_instance_valid(node):
			node.queue_free()
	_ui.clear()
	_box = null
	_confirm_button = null
	_cancel_button = null


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	var viewport := get_viewport()
	_on_cancel_pressed()
	if viewport != null:
		viewport.set_input_as_handled()


func _rebuild(message: String, character_id: String, confirm_text: String, cancel_text: String) -> void:
	_clear_ui()
	var palette := CharacterTheme.ui_palette(character_id)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.65)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(backdrop)
	_ui.append(backdrop)

	_box = Panel.new()
	var skin_applied := UIKit.apply_panel_skin(_box, "overlay", character_id)
	if not skin_applied:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.08, 0.08, 0.08, 0.98)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(10)
		_box.add_theme_stylebox_override("panel", frame_style)
	_box.position = (Vector2(1280, 720) - BOX_SIZE) / 2.0
	_box.size = BOX_SIZE
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.add_child(_box)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 24
	content.offset_top = 20
	content.offset_right = -24
	content.offset_bottom = -20
	content.add_theme_constant_override("separation", 16)
	_box.add_child(content)

	var msg_label := Label.new()
	msg_label.text = message
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.add_theme_font_size_override("font_size", 15)
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	msg_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(msg_label)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 12)
	content.add_child(button_row)

	_cancel_button = Button.new()
	_cancel_button.text = cancel_text
	_cancel_button.custom_minimum_size = Vector2(120, 40)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	UIKit.style_secondary_button(_cancel_button, character_id)
	button_row.add_child(_cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = confirm_text
	_confirm_button.custom_minimum_size = Vector2(120, 40)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	# 확인 버튼만 경고색(빨강) tint — dungeon_map.gd의 "정예 전투" 버튼과 같은 패턴으로
	# 되돌릴 수 없는/신중해야 할 동작임을 색으로도 알린다.
	UIKit.style_secondary_button(_confirm_button, character_id, Color(0.85, 0.2, 0.2))
	button_row.add_child(_confirm_button)

	# 포커스 트랩: 두 버튼을 가로 체인(wrap=true, trap=true)으로 묶어 포커스가 팝업
	# 밖으로 못 나가게 한다(SkillDetailPopup과 같은 원칙, 버튼이 둘이라 실제로 순환).
	FocusNav.chain_linear([_cancel_button, _confirm_button], true, true, true, palette["accent"])
	FocusNav.grab_first_focus([_cancel_button])


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()


func _on_confirm_pressed() -> void:
	close()
	confirmed.emit()


func _on_cancel_pressed() -> void:
	close()
	cancelled.emit()
