class_name SkillDetailPopup
extends Control
## 보유 스킬 아이콘을 클릭/Space하면 뜨는 상세 팝업 (INBOX.md [대형 기획 15] Q-4b, 원문 11).
##
## achievement_panel.gd/skill_codex_panel.gd와 같은 "스크립트 하나로 완결된 Control,
## 별도 .tscn 불필요" 패턴. open(skill_id, character_id)로 연다. 당시(Q-4b)엔 "레어리티는
## 아직 없으니 생략"이었지만, [대형 기획 15] Q-8(a)(2026-10-18)로 레어리티 체계가
## 생기면서 이름 옆에 등급 배지(SkillPool.build_rarity_badge())가 추가됐다.
##
## 공용 컴포넌트로 설계해 스킬 도감/보상/상점에서도 재사용할 수 있게 한다(INBOX 원문,
## Q-6/Q-7이 이어서 쓸 예정) — 이번 조각은 호출부를 deck_panel.gd(던전 진행 5개 화면이
## 공유하는 "보유 스킬" 섹션) 한 곳에만 배선한다.
##
## 닫기는 세 갈래(INBOX 원문): ① 화면 전체를 덮는 어두운 배경(backdrop) 클릭
## ② 우상단 X 버튼 ③ Esc. achievement_panel.gd/skill_codex_panel.gd는 바깥 클릭으로
## 닫는 기능이 없어(닫기 버튼/Esc만) 이 팝업만의 구조적 차이는 "전체 화면을 덮는
## ColorRect(backdrop)가 자기 자신의 gui_input으로 클릭을 감지하고, 그 위에 얹힌 박스
## (_box)는 mouse_filter=STOP이라 그 안쪽 클릭은 backdrop까지 번지지 않는다"는 것 —
## 별도의 "바깥 영역" 판정(rect 비교) 없이 Godot의 기본 입력 전파 순서(자식이 먼저
## 받고, STOP이면 부모로 안 번짐)만으로 "안쪽 클릭은 유지, 바깥 클릭은 닫힘"이 성립한다.
## 포커스 트랩은 닫기 버튼 하나뿐이라 achievement_panel.gd와 같은 패턴(wrap=true 자기
## 순환)으로 충분하다 — "트랩"은 이 팝업 자체(포커스가 뒤에 가려진 화면으로 못 나감)를
## 뜻하고, 팝업을 띄우는 보유 스킬 아이콘 목록 쪽 방향키 이동까지 포함하지 않는다.

signal closed

## [대형 기획 15] Q-7(c)(2026-10-17): 420x260 -> 460x340 — 헤더/설명 사이에 SkillDiagram
## (SIZE_POPUP, 56px 칩)을 넣을 공간을 확보하려고 세로를 키움(감독 피드백: 팝업은 카드
## 보다도 한 단계 더 큰 56px 이상 칩을 쓰라는 지시).
const POPUP_SIZE := Vector2(460, 340)
const ICON_SIZE := Vector2(40, 40)
const CLOSE_BUTTON_SIZE := 36.0

var _ui: Array[Node] = []
var _box: Panel
var _close_button: Button
## dice_test.gd가 "플래그가 아니라 실제로 렌더된 텍스트"를 검증할 수 있도록 테스트
## 전용으로 공개해둔다(skill_codex_panel.gd의 _name_label_by_id 등과 같은 이유).
var _name_label: Label
var _desc_label: Label
## [대형 기획 15] Q-8(a) 신규 — 레어리티 등급 배지 텍스트(dice_test.gd가 실제로 렌더된
## 텍스트를 검증할 수 있게 공개).
var _rarity_badge_label: Label
## Q-7(c) 신규 — 도식 자체도 테스트가 직접 들여다볼 수 있게 공개(diagram_data가
## skill_id와 일치하는지 등).
var _diagram: SkillDiagram


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## skill_id: SkillPool.find_skill()으로 이름/설명을 조회할 수 있는 id(SKILLS/
## UNIQUE_SKILLS/UPGRADE_SKILLS/STARTING_SKILLS 어디 소속이든 무관). character_id:
## 아이콘 모티프 배경색/닫기 버튼 스킨에 쓸 캐릭터 퍼스널 컬러.
func open(skill_id: String, character_id: String) -> void:
	visible = true
	_rebuild(skill_id, character_id)


func close() -> void:
	_clear_ui()
	visible = false
	closed.emit()


func _clear_ui() -> void:
	for node in _ui:
		if is_instance_valid(node):
			node.queue_free()
	_ui.clear()
	_box = null
	_close_button = null
	_name_label = null
	_desc_label = null
	_diagram = null
	_rarity_badge_label = null


## Esc로 닫기(K-1 — 오버레이 패널 공통 규칙, achievement_panel.gd와 동일 패턴).
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return
	var viewport := get_viewport()
	close()
	if viewport != null:
		viewport.set_input_as_handled()


func _rebuild(skill_id: String, character_id: String) -> void:
	_clear_ui()
	var palette := CharacterTheme.ui_palette(character_id)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(backdrop)
	_ui.append(backdrop)

	var skill := SkillPool.find_skill(skill_id)
	var skill_name: String = String(skill.get("name", skill_id))
	var skill_desc: String = String(skill.get("description", ""))

	_box = Panel.new()
	var skin_applied := UIKit.apply_panel_skin(_box, "overlay", character_id)
	if not skin_applied:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.08, 0.08, 0.08, 0.98)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(10)
		_box.add_theme_stylebox_override("panel", frame_style)
	_box.position = (Vector2(1280, 720) - POPUP_SIZE) / 2.0
	_box.size = POPUP_SIZE
	# 박스 안쪽 클릭이 backdrop까지 번져 팝업이 즉시 닫혀버리지 않도록 STOP — Godot은
	# 자식(먼저 그려진 _box)이 입력을 소비하면 부모(backdrop)로 전파하지 않는다.
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.add_child(_box)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_top = 18
	content.offset_right = -20
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 10)
	_box.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var icon := SkillIcon.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.motif = SkillPool.icon_motif_for(skill_id)
	icon.skill_id = skill_id
	header.add_child(icon)

	_name_label = Label.new()
	_name_label.text = skill_name
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", palette["accent"])
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_name_label)

	# [대형 기획 15] Q-8(a)(2026-10-18): 레어리티 배지 — 위 클래스 주석의 "레어리티는
	# 아직 없으니 생략"은 Q-8(a)로 더 이상 사실이 아니다(아래로 옮겨 적음).
	var rarity_info := SkillPool.build_rarity_badge(skill_id, 13)
	_rarity_badge_label = rarity_info["label"]
	header.add_child(rarity_info["panel"])

	# 닫기 버튼: UIKit.style_secondary_button()은 가로로 긴 장식(양끝 보석 모양) 버튼을
	# 가정한 스킨이라 36x36 정사각 아이콘 버튼에 억지로 씌우면 장식이 짓눌려 거의 안
	# 보이는 문제가 셀프 피드백 캡처(qa_out/q4b_skill_popup.png)에서 실제로 발견됐다 —
	# 그 스킨을 쓰지 않고 또렷한 단색 사각 버튼 + 굵은 "X"로 직접 스타일링한다.
	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE)
	_close_button.pressed.connect(close)
	var close_normal := StyleBoxFlat.new()
	close_normal.bg_color = Color(0.3, 0.1, 0.1)
	close_normal.border_color = Color(0.85, 0.4, 0.4)
	close_normal.set_border_width_all(2)
	close_normal.set_corner_radius_all(6)
	_close_button.add_theme_stylebox_override("normal", close_normal)
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.5, 0.15, 0.15)
	close_hover.border_color = Color(1.0, 0.5, 0.5)
	close_hover.set_border_width_all(2)
	close_hover.set_corner_radius_all(6)
	_close_button.add_theme_stylebox_override("hover", close_hover)
	var close_pressed := StyleBoxFlat.new()
	close_pressed.bg_color = Color(0.2, 0.05, 0.05)
	close_pressed.border_color = Color(0.85, 0.4, 0.4)
	close_pressed.set_border_width_all(2)
	close_pressed.set_corner_radius_all(6)
	_close_button.add_theme_stylebox_override("pressed", close_pressed)
	_close_button.add_theme_color_override("font_color", Color(1, 1, 1))
	_close_button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	_close_button.add_theme_font_size_override("font_size", 18)
	header.add_child(_close_button)

	# Q-7(c): 도식(SIZE_POPUP, 56px 칩 — 세 위젯 중 가장 큼)을 이름 아래/설명 위에 둬서
	# "글을 읽지 않아도 효과를 빠르게 안다"는 요구를 팝업에서도 충족한다.
	_diagram = SkillDiagram.new()
	_diagram.size_variant = SkillDiagramChip.SIZE_POPUP
	_diagram.diagram_data = SkillPool.diagram_for(skill_id)
	content.add_child(_diagram)

	_desc_label = Label.new()
	_desc_label.text = skill_desc
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.add_theme_font_size_override("font_size", 14)
	_desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_desc_label)

	# 포커스 트랩: 닫기 버튼 하나뿐이라 achievement_panel.gd와 같은 "자기 자신에게
	# 자기 자신"(wrap=true, n==1) 패턴으로 포커스가 팝업 밖으로 못 나간다.
	FocusNav.chain_linear([_close_button], false, true, true, palette["accent"])
	FocusNav.grab_first_focus([_close_button])


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
