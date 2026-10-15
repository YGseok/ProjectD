class_name SkillCodexPanel
extends Control
## 캐릭터별 스킬 도감 오버레이 패널 ([대형 기획 12] L-2(b), INBOX.md 2026-10-14).
##
## achievement_panel.gd/customize_panel.gd와 같은 "스크립트 하나로 완결된 Control,
## 별도 .tscn 불필요" 패턴 — 아무 씬에나 Control 노드를 만들고 이 스크립트만 붙이면
## 동작한다(L-2(c)에서 각 화면에 실제로 배선할 예정, 이 조각은 재사용 가능한 패널
## 자체만 만든다).
##
## open(character_id, owned_skill_ids)로 연다. "보유" 여부는 패널이 RunState를 직접
## 읽지 않고 호출부가 넘겨주는 배열로만 판단한다 — 캐릭터 선택 화면은 "보유 0개"를
## 넘기고, 던전 진행 중인 화면은 RunState.skill_flags를 그대로 넘기는 식으로 호출부마다
## 다른 의미를 그대로 받아들이기 위함이다(INBOX.md L-2 원문 "선택 화면에서는 보유
## 0개" 참고). "발견" 여부는 SkillCodex(전역 영구 저장)를 직접 읽는다 — 이건 호출부와
## 무관하게 항상 같은 의미이기 때문.
##
## 3상태(우선순위 순): ①**보유**(owned_skill_ids에 있음, 발견 여부와 무관하게 항상
## 최우선) ②**발견-미보유**(SkillCodex.is_discovered()==true, 보유하지 않음)
## ③**미발견**(둘 다 아님). 상태는 아이콘 밝기뿐 아니라 이름 텍스트("???" vs 실제 이름)와
## 배지 텍스트로도 구분한다(INBOX.md "색만으로 구분 금지"). 미발견 카드의 설명 줄은
## 비워두되, 시작 스킬(codex_source=="starting")은 F-1의 잠금 안내 문구
## (SkillPool.unlock_requirement)를 그대로 재사용한다.
##
## 카드 포커스 이동은 FocusNav.chain_linear()(1자 체인)로는 격자(그리드)의 상/하 이동을
## 표현할 수 없어, 이 패널 전용으로 격자 전체를 wrap(모든 모서리에서 반대편으로 순환)으로
## 묶는 _chain_grid()를 둔다 — 격자 칸 전체가 서로 연결돼 있어 포커스가 패널 밖(뒤에
## 가려진 화면)으로 못 나가므로, FocusNav.chain_linear()의 trap 매개변수와 같은 효과를
## 별도 설정 없이 얻는다(모든 칸이 상/하/좌/우 전부 다른 카드로 연결돼 있어 "탈출구"
## 자체가 없음). 닫기 버튼은 격자 마지막 칸 아래 하나에만 추가로 연결한다.

signal closed

const COLUMNS := 3
const CARD_SIZE := Vector2(300, 150)
const GRID_GAP := 14

const COLOR_UNDISCOVERED_BORDER := Color(0.3, 0.3, 0.3)
const COLOR_DISCOVERED_BORDER := Color(0.55, 0.55, 0.55)
const COLOR_UNDISCOVERED_BG := Color(0.08, 0.08, 0.08, 0.95)
const COLOR_DISCOVERED_BG := Color(0.14, 0.14, 0.16, 0.95)
const COLOR_OWNED_BG := Color(0.16, 0.16, 0.12, 0.97)
const BADGE_UNDISCOVERED := Color(0.5, 0.5, 0.5)
const BADGE_DISCOVERED := Color(0.65, 0.65, 0.7)
const BADGE_OWNED := Color(0.95, 0.85, 0.35)

const BADGE_TEXT_UNDISCOVERED := "미발견"
const BADGE_TEXT_DISCOVERED := "발견"
const BADGE_TEXT_OWNED := "보유"

var _character_id: String = ""
var _owned: Array = []
var _ui: Array[Node] = []
var _card_controls: Array[Control] = []
var _close_button: Button
var _summary_label: Label

## skill_id -> 각 카드의 자식 노드. dice_test.gd가 "플래그가 아니라 실제로 렌더된
## 결과(텍스트/모듈레이트)"를 검증할 수 있도록 테스트 전용으로 공개해둔다.
var _card_by_id: Dictionary = {}
var _badge_label_by_id: Dictionary = {}
var _name_label_by_id: Dictionary = {}
var _desc_label_by_id: Dictionary = {}
var _icon_by_id: Dictionary = {}


func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## character_id: 도감을 보여줄 캐릭터. owned_skill_ids: 이번 회차 보유 스킬 id 목록
## (호출부가 의미를 정함 — 위 클래스 주석 참고).
func open(character_id: String, owned_skill_ids: Array = []) -> void:
	_character_id = character_id
	_owned = owned_skill_ids.duplicate()
	visible = true
	_rebuild()


func close() -> void:
	_clear_ui()
	visible = false
	closed.emit()


func _clear_ui() -> void:
	for node in _ui:
		if is_instance_valid(node):
			node.queue_free()
	_ui.clear()
	_card_controls.clear()
	_card_by_id.clear()
	_badge_label_by_id.clear()
	_name_label_by_id.clear()
	_desc_label_by_id.clear()
	_icon_by_id.clear()


## Esc로 패널을 닫는다(K-1 — 오버레이 패널 공통 규칙, achievement_panel.gd와 동일 패턴).
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


func _rebuild() -> void:
	_clear_ui()

	var palette := CharacterTheme.ui_palette(_character_id)

	# L-3(2026-10-14, [대형 기획 12] K-3 후속): 평범한 검정 ColorRect였던 틀을
	# Panel(테두리 있음)로 바꿔 CharacterTheme.apply()로 캐릭터 색 테두리를 입힌다.
	var bg := Panel.new()
	# [대형 기획 13] M-5a(2026-10-15): resources/ui/panel/overlay_{base,accent}.png가
	# 있으면 그 이미지 스킨을, 없으면 기존 StyleBoxFlat 절차적 테두리로 폴백.
	var skin_applied := UIKit.apply_panel_skin(bg, "overlay", _character_id)
	if not skin_applied:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0, 0, 0, 0.9)
		frame_style.set_border_width_all(2)
		frame_style.set_corner_radius_all(8)
		bg.add_theme_stylebox_override("panel", frame_style)
	bg.position = Vector2(100, 60)
	bg.size = Vector2(1080, 600)
	add_child(bg)
	_ui.append(bg)
	if not skin_applied:
		CharacterTheme.apply(bg, _character_id, false)

	var entries := SkillPool.codex_entries(_character_id)
	var starting_list := SkillPool.starting_skills_for_character(_character_id)

	var owned_count := 0
	var discovered_count := 0
	for entry in entries:
		if _owned.has(entry["id"]):
			owned_count += 1
		if SkillCodex.is_discovered(_character_id, entry["id"]):
			discovered_count += 1

	var character_name: String = CharacterProfiles.get_profile(_character_id).get("name", _character_id)
	_summary_label = Label.new()
	var summary_text := "%s 스킬 도감 — 보유 %d개 · 발견 %d / 전체 %d" % [
		character_name, owned_count, discovered_count, entries.size()
	]
	if entries.size() > 0 and discovered_count == entries.size():
		summary_text += " (도감 완성)"
	_summary_label.text = summary_text
	_summary_label.position = Vector2(130, 80)
	_summary_label.size = Vector2(1020, 28)
	_summary_label.add_theme_font_size_override("font_size", 18)
	_summary_label.add_theme_color_override("font_color", palette["accent"])
	add_child(_summary_label)
	_ui.append(_summary_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(130, 120)
	scroll.size = Vector2(1020, 440)
	add_child(scroll)
	_ui.append(scroll)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GRID_GAP)
	grid.add_theme_constant_override("v_separation", GRID_GAP)
	scroll.add_child(grid)

	for entry in entries:
		var slot_index := -1
		if entry.get("codex_source", "") == "starting":
			for i in starting_list.size():
				if starting_list[i]["id"] == entry["id"]:
					slot_index = i
					break
		var card := _make_card(entry, slot_index, palette)
		grid.add_child(card)
		_card_controls.append(card)

	_close_button = Button.new()
	_close_button.text = "닫기"
	_close_button.position = Vector2(575, 610)
	_close_button.size = Vector2(130, 36)
	_close_button.pressed.connect(close)
	add_child(_close_button)
	_ui.append(_close_button)

	_chain_grid(_card_controls, COLUMNS, palette["accent"])
	FocusNav.make_focusable(_close_button, palette["accent"])
	if not _card_controls.is_empty():
		var first_card := _card_controls[0]
		var last_card := _card_controls[_card_controls.size() - 1]
		last_card.focus_neighbor_bottom = last_card.get_path_to(_close_button)
		_close_button.focus_neighbor_top = _close_button.get_path_to(last_card)
		_close_button.focus_neighbor_bottom = _close_button.get_path_to(_close_button)
		_close_button.focus_neighbor_left = _close_button.get_path_to(_close_button)
		_close_button.focus_neighbor_right = _close_button.get_path_to(_close_button)
		FocusNav.grab_first_focus(_card_controls)
	else:
		_close_button.focus_neighbor_top = _close_button.get_path_to(_close_button)
		_close_button.focus_neighbor_bottom = _close_button.get_path_to(_close_button)
		_close_button.focus_neighbor_left = _close_button.get_path_to(_close_button)
		_close_button.focus_neighbor_right = _close_button.get_path_to(_close_button)
		FocusNav.grab_first_focus([_close_button])


## 격자 전체를 wrap(상/하/좌/우 전부 반대편 모서리로 순환)으로 묶는다 — 모든 칸이 네
## 방향 다 다른 카드로 연결돼 있으므로 포커스가 패널 밖으로 못 나간다(별도 trap 설정
## 불필요). columns로 나누어떨어지지 않는 마지막 행(카드 수가 COLUMNS의 배수가 아닌
## 경우)도 안전하게 처리한다.
func _chain_grid(cards: Array[Control], columns: int, accent: Color) -> void:
	var n := cards.size()
	if n == 0:
		return
	for c in cards:
		FocusNav.make_focusable(c, accent)
	for i in n:
		var row := i / columns
		var row_start := row * columns
		var row_end: int = min(row_start + columns - 1, n - 1)
		var left_idx: int = i - 1 if i > row_start else row_end
		var right_idx: int = i + 1 if i < row_end else row_start
		cards[i].focus_neighbor_left = cards[i].get_path_to(cards[left_idx])
		cards[i].focus_neighbor_right = cards[i].get_path_to(cards[right_idx])

		var col := i % columns
		var col_indices: Array[int] = []
		var j := col
		while j < n:
			col_indices.append(j)
			j += columns
		var pos_in_col := col_indices.find(i)
		var up_idx: int = col_indices[pos_in_col - 1] if pos_in_col > 0 else col_indices[col_indices.size() - 1]
		var down_idx: int = col_indices[pos_in_col + 1] if pos_in_col < col_indices.size() - 1 else col_indices[0]
		cards[i].focus_neighbor_top = cards[i].get_path_to(cards[up_idx])
		cards[i].focus_neighbor_bottom = cards[i].get_path_to(cards[down_idx])


## 카드 하나(CharacterCardPanel 재사용 — L-1이 만든 "클릭/포커스 가능한 PanelContainer +
## hover 피드백"을 그대로 쓴다, 이 패널의 카드는 클릭해도 아무 동작이 없는 view-only라
## activated 시그널은 연결하지 않는다).
func _make_card(entry: Dictionary, slot_index: int, palette: Dictionary) -> Control:
	var skill_id: String = entry["id"]
	var owned: bool = _owned.has(skill_id)
	var discovered: bool = SkillCodex.is_discovered(_character_id, skill_id)

	var card := CharacterCardPanel.new()
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if owned:
		style.bg_color = COLOR_OWNED_BG
		style.border_color = palette["accent"]
		style.set_border_width_all(3)
	elif discovered:
		style.bg_color = COLOR_DISCOVERED_BG
		style.border_color = COLOR_DISCOVERED_BORDER
		style.set_border_width_all(2)
	else:
		style.bg_color = COLOR_UNDISCOVERED_BG
		style.border_color = COLOR_UNDISCOVERED_BORDER
		style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	var icon := SkillIcon.new()
	icon.custom_minimum_size = Vector2(28, 28)
	if owned or discovered:
		icon.motif = SkillPool.icon_motif_for(skill_id)
		icon.skill_id = skill_id
		icon.modulate = Color(1, 1, 1, 1.0) if owned else Color(1, 1, 1, 0.55)
	else:
		# 미발견: motif/category를 설정하지 않아 _draw_none()의 빈 원(실루엣)으로
		# 떨어지고, 알파를 더 낮춰 "흐릿한 그림자" 느낌을 준다.
		icon.modulate = Color(1, 1, 1, 0.35)
	header.add_child(icon)
	_icon_by_id[skill_id] = icon

	var name_label := Label.new()
	name_label.text = String(entry.get("name", skill_id)) if (owned or discovered) else "???"
	name_label.add_theme_font_size_override("font_size", 15)
	if owned:
		name_label.add_theme_color_override("font_color", palette["accent"])
	elif discovered:
		name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.add_child(name_label)
	_name_label_by_id[skill_id] = name_label

	# [대형 기획 13] M-5(b) — badge/codex_base.png가 있으면 상태색(BADGE_OWNED/DISCOVERED/
	# UNDISCOVERED)으로 modulate된 배지 배경 위에, 없으면 기존처럼 배경 없는 색깔 텍스트
	# 그대로(폴백, L-2b 당시와 동일). UIKit.make_codex_badge()가 두 경로 다 담당.
	var badge_text: String
	var badge_color: Color
	if owned:
		badge_text = BADGE_TEXT_OWNED
		badge_color = BADGE_OWNED
	elif discovered:
		badge_text = BADGE_TEXT_DISCOVERED
		badge_color = BADGE_DISCOVERED
	else:
		badge_text = BADGE_TEXT_UNDISCOVERED
		badge_color = BADGE_UNDISCOVERED
	var badge := UIKit.make_codex_badge(vbox, badge_text, badge_color)
	_badge_label_by_id[skill_id] = badge

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(CARD_SIZE.x - 20, 56)
	desc.add_theme_font_size_override("font_size", 11)
	if owned:
		desc.text = String(entry.get("description", ""))
		desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	elif discovered:
		desc.text = String(entry.get("description", ""))
		desc.add_theme_color_override("font_color", Color(0.62, 0.62, 0.62))
	else:
		# 미발견 힌트는 기본적으로 없음(INBOX.md 명시) — 시작 스킬 슬롯만 F-1의 잠금
		# 안내 문구를 그대로 재사용한다(slot_index가 -1이 아닐 때만 해당).
		desc.text = SkillPool.unlock_requirement(_character_id, slot_index)["text"] if slot_index >= 0 else ""
		desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(desc)
	_desc_label_by_id[skill_id] = desc

	_card_by_id[skill_id] = card
	return card
