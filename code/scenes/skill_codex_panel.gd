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
## **[대형 기획 15] Q-6(2026-10-17, 원문 2/4/8) 레이아웃 전면 개편**:
## (2) 상태 배지가 카드 안쪽 줄 하나를 차지하던 것 → 카드 우상단 모서리에 겹쳐 뜨는
## 작은 태그(폭 48px, 폰트 9)로 축소. (4) 시작 스킬 3개를 codex_entries() 순서(항상
## 맨 앞, SkillPool.starting_skills_for_character()가 보장하는 슬롯 순서 그대로)로 뽑아
## 별도 "시작 스킬" 구역(가로 한 줄, 슬롯 번호 태그를 좌상단에 추가로 겹쳐 일반 스킬과
## 레이아웃을 구분)에 먼저 그리고, "일반 스킬" 구역(기존 3열 격자)이 그 아래 이어진다.
## (8) 아이콘을 "좌측 큰 정사각형(60px, 프레임 포함) + 우측 이름/설명" 가로 배치로
## 바꿈 — 미발견 카드는 모티프 아이콘 대신 LockIcon(스킬 정보 비공개 규칙 유지)을 보여준다.
## 덤으로 카드를 클릭/Space하면(CharacterCardPanel.activated, deck_panel.gd의 "보유 스킬"
## 행과 같은 패턴) SkillDetailPopup이 열리도록 배선했다 — **발견된 스킬(보유 포함)만**,
## 미발견 카드는 클릭해도 아무 일도 일어나지 않는다(정보 비공개).
##
## 카드 포커스 이동은 FocusNav.chain_linear()(1자 체인)로는 격자(그리드)의 상/하 이동을
## 표현할 수 없어, 이 패널 전용으로 격자 전체를 wrap(모든 모서리에서 반대편으로 순환)으로
## 묶는 _chain_grid()를 둔다 — 격자 칸 전체가 서로 연결돼 있어 포커스가 패널 밖(뒤에
## 가려진 화면)으로 못 나가므로, FocusNav.chain_linear()의 trap 매개변수와 같은 효과를
## 별도 설정 없이 얻는다(모든 칸이 상/하/좌/우 전부 다른 카드로 연결돼 있어 "탈출구"
## 자체가 없음). 닫기 버튼은 격자 마지막 칸 아래 하나에만 추가로 연결한다.
## **Q-6부터는 시작 스킬 줄(항상 COLUMNS개, 지금은 8명 전부 정확히 3개)이 _card_controls의
## 맨 앞을 차지**하므로, 두 구역을 서로 다른 Control(가로줄/격자)로 따로 그려도
## _chain_grid()의 "평평한 배열을 columns로 나눈 가상 행" 계산은 시작 스킬 줄을 정확히
## 첫 행으로, 일반 스킬을 그 아래 행들로 인식해 시각 레이아웃과 그대로 일치한다.

signal closed

const COLUMNS := 3
const CARD_SIZE := Vector2(320, 160)
const GRID_GAP := 14

const ICON_BOX_SIZE := 60.0

const CORNER_TAG_W := 48.0
const CORNER_TAG_H := 16.0
const CORNER_TAG_INSET := 6.0

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

const SLOT_TAG_BG := Color(1, 1, 1, 0.12)

var _character_id: String = ""
var _owned: Array = []
var _ui: Array[Node] = []
var _card_controls: Array[Control] = []
var _close_button: Button
var _summary_label: Label
var _starting_row: Control = null
var _general_grid: Control = null

## skill_id -> 각 카드의 자식 노드. dice_test.gd가 "플래그가 아니라 실제로 렌더된
## 결과(텍스트/모듈레이트)"를 검증할 수 있도록 테스트 전용으로 공개해둔다.
var _card_by_id: Dictionary = {}
var _badge_label_by_id: Dictionary = {}
var _badge_panel_by_id: Dictionary = {}
var _name_label_by_id: Dictionary = {}
var _desc_label_by_id: Dictionary = {}
var _icon_by_id: Dictionary = {}
## Q-6 신규: 미발견 카드는 SkillIcon이 아니라 LockIcon을 쓴다(스킬 정보 비공개 유지).
var _lock_icon_by_id: Dictionary = {}
## Q-6 신규: 시작 스킬 카드에만 붙는 좌상단 "슬롯 N" 태그.
var _slot_tag_by_id: Dictionary = {}

## Q-6 신규: 보유/발견 카드를 클릭/Space하면 여는 상세 팝업(SkillDetailPopup, 공용
## 컴포넌트) — deck_panel.gd의 "보유 스킬" 행과 같은 패턴. _ui/_clear_ui()에 묶지 않고
## 패널 자체의 수명과 함께 간다(열려 있는 도중 _rebuild()가 다시 불려도 사라지지 않음).
var _skill_popup: SkillDetailPopup = null


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
	_badge_panel_by_id.clear()
	_name_label_by_id.clear()
	_desc_label_by_id.clear()
	_icon_by_id.clear()
	_lock_icon_by_id.clear()
	_slot_tag_by_id.clear()
	_starting_row = null
	_general_grid = null


## 보유/발견 카드가 클릭/Space되면 상세 팝업을 연다(Q-6, deck_panel.gd와 같은 지연
## 생성 패턴). 미발견 카드는 이 핸들러에 연결되지 않으므로 호출될 일이 없다.
func _ensure_skill_popup() -> SkillDetailPopup:
	if _skill_popup == null or not is_instance_valid(_skill_popup):
		_skill_popup = SkillDetailPopup.new()
		add_child(_skill_popup)
	return _skill_popup


func _on_card_activated(skill_id: String) -> void:
	_ensure_skill_popup().open(skill_id, _character_id)


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
	bg.position = Vector2(60, 40)
	bg.size = Vector2(1160, 640)
	add_child(bg)
	_ui.append(bg)
	if not skin_applied:
		CharacterTheme.apply(bg, _character_id, false)

	var entries := SkillPool.codex_entries(_character_id)

	# Q-6(4): codex_entries()는 항상 시작 스킬(슬롯 순서)을 맨 앞에 두므로, 그 선두
	# 구간만 떼어내면 추가 조회 없이 그대로 "시작 스킬" 구역 데이터가 된다.
	var starting_entries: Array[Dictionary] = []
	var general_entries: Array[Dictionary] = []
	for entry in entries:
		if entry.get("codex_source", "") == "starting":
			starting_entries.append(entry)
		else:
			general_entries.append(entry)

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
	_summary_label.position = Vector2(90, 60)
	_summary_label.size = Vector2(1100, 28)
	_summary_label.add_theme_font_size_override("font_size", 18)
	_summary_label.add_theme_color_override("font_color", palette["accent"])
	add_child(_summary_label)
	_ui.append(_summary_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(90, 100)
	scroll.size = Vector2(1100, 560)
	add_child(scroll)
	_ui.append(scroll)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	scroll.add_child(outer)

	if not starting_entries.is_empty():
		var starting_title := Label.new()
		starting_title.text = "시작 스킬"
		starting_title.add_theme_font_size_override("font_size", 15)
		starting_title.add_theme_color_override("font_color", palette["accent"])
		outer.add_child(starting_title)

		_starting_row = HBoxContainer.new()
		_starting_row.add_theme_constant_override("separation", GRID_GAP)
		outer.add_child(_starting_row)
		for i in starting_entries.size():
			var starting_card := _make_card(starting_entries[i], i, palette, true)
			_starting_row.add_child(starting_card)
			_card_controls.append(starting_card)

		var general_title := Label.new()
		general_title.text = "일반 스킬"
		general_title.add_theme_font_size_override("font_size", 15)
		general_title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		outer.add_child(general_title)

	_general_grid = GridContainer.new()
	(_general_grid as GridContainer).columns = COLUMNS
	_general_grid.add_theme_constant_override("h_separation", GRID_GAP)
	_general_grid.add_theme_constant_override("v_separation", GRID_GAP)
	outer.add_child(_general_grid)

	for entry in general_entries:
		var card := _make_card(entry, -1, palette, false)
		_general_grid.add_child(card)
		_card_controls.append(card)

	_close_button = Button.new()
	_close_button.text = "닫기"
	_close_button.position = Vector2(635, 650)
	_close_button.size = Vector2(130, 36)
	_close_button.pressed.connect(close)
	# [대형 기획 14] N-3(2026-10-15): 전수 검색에서 발견 — 이 버튼이 UIKit 스타일링을
	# 전혀 안 받아 기본 Godot 테마로만 그려지고 있었다("단순 글자처럼 보인다").
	UIKit.style_secondary_button(_close_button, _character_id)
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


## 카드 우상단(또는 좌상단)에 겹쳐 뜨는 작은 모서리 태그 하나(Q-6(2) — 상태 배지를
## "작은 글씨/작은 칩"으로 축소, 슬롯 번호 태그도 같은 모양 재사용). 부모(parent)는
## Container가 아닌 plain Control이어야 한다 — Container는 자식 전부를 같은 rect로
## 강제 맞추므로 anchor로 모서리에 겹치는 효과를 낼 수 없다(icon_area 패턴과 동일한
## 이유, character_select.gd의 LockIcon 겹침 참고).
func _make_corner_tag(parent: Control, text: String, bg_color: Color, text_color: Color, align_right: bool) -> Dictionary:
	var tag := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(4)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	tag.add_theme_stylebox_override("panel", style)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", text_color)
	tag.add_child(label)

	parent.add_child(tag)
	tag.anchor_top = 0.0
	tag.anchor_bottom = 0.0
	tag.offset_top = CORNER_TAG_INSET
	tag.offset_bottom = CORNER_TAG_INSET + CORNER_TAG_H
	if align_right:
		tag.anchor_left = 1.0
		tag.anchor_right = 1.0
		tag.offset_left = -CORNER_TAG_W - CORNER_TAG_INSET
		tag.offset_right = -CORNER_TAG_INSET
	else:
		tag.anchor_left = 0.0
		tag.anchor_right = 0.0
		tag.offset_left = CORNER_TAG_INSET
		tag.offset_right = CORNER_TAG_INSET + CORNER_TAG_W
	return {"panel": tag, "label": label}


## 카드 하나(CharacterCardPanel 재사용 — L-1이 만든 "클릭/포커스 가능한 PanelContainer +
## hover 피드백"을 그대로 쓴다). Q-6부터 보유/발견 카드는 클릭/Space로 SkillDetailPopup을
## 연다(미발견은 정보 비공개라 연결하지 않음). is_starting이면 좌상단에 "슬롯 N" 태그가
## 추가로 붙는다(슬롯 번호는 slot_index+1 — 일반 스킬은 slot_index=-1이라 태그 없음).
func _make_card(entry: Dictionary, slot_index: int, palette: Dictionary, is_starting: bool = false) -> Control:
	var skill_id: String = entry["id"]
	var owned: bool = _owned.has(skill_id)
	var discovered: bool = SkillCodex.is_discovered(_character_id, skill_id)
	var revealed: bool = owned or discovered

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

	# wrap은 plain Control(Container 아님) — 안쪽 hbox(정상 레이아웃 흐름)와 모서리
	# 태그(겹쳐지는 절대 위치) 두 가지를 함께 자식으로 둬야 해서, Container가 모든
	# 자식을 같은 rect로 강제하는 동작을 피한다(_make_corner_tag 주석과 같은 이유).
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(wrap)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(hbox)

	# Q-6(8): 아이콘을 좌측에 크게(60px 정사각) + 프레임. 미발견은 모티프 대신
	# LockIcon(스킬 정보 비공개 규칙 유지).
	var icon_frame := PanelContainer.new()
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0.35)
	frame_style.border_color = palette["accent"] if revealed else COLOR_UNDISCOVERED_BORDER
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(6)
	frame_style.content_margin_left = 4
	frame_style.content_margin_right = 4
	frame_style.content_margin_top = 4
	frame_style.content_margin_bottom = 4
	icon_frame.add_theme_stylebox_override("panel", frame_style)
	hbox.add_child(icon_frame)

	if revealed:
		var icon := SkillIcon.new()
		icon.custom_minimum_size = Vector2(ICON_BOX_SIZE, ICON_BOX_SIZE)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.motif = SkillPool.icon_motif_for(skill_id)
		icon.skill_id = skill_id
		icon.modulate = Color(1, 1, 1, 1.0 if owned else 0.55)
		icon_frame.add_child(icon)
		_icon_by_id[skill_id] = icon
	else:
		var lock := LockIcon.new()
		lock.custom_minimum_size = Vector2(ICON_BOX_SIZE, ICON_BOX_SIZE)
		icon_frame.add_child(lock)
		_lock_icon_by_id[skill_id] = lock

	var text_col := VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 4)
	hbox.add_child(text_col)

	var name_label := Label.new()
	name_label.text = String(entry.get("name", skill_id)) if revealed else "???"
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 15)
	if owned:
		name_label.add_theme_color_override("font_color", palette["accent"])
	elif discovered:
		name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	text_col.add_child(name_label)
	_name_label_by_id[skill_id] = name_label

	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(0, 70)
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
	text_col.add_child(desc)
	_desc_label_by_id[skill_id] = desc

	# Q-6(2): 상태 배지를 카드 우상단에 겹치는 작은 태그로(이전엔 header 아래 한 줄을
	# 차지하는 넓은 PanelContainer였음).
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
	var badge_info := _make_corner_tag(wrap, badge_text, badge_color, UIKit.contrasting_text_color(badge_color), true)
	_badge_label_by_id[skill_id] = badge_info["label"]
	_badge_panel_by_id[skill_id] = badge_info["panel"]

	# Q-6(4): 시작 스킬만 좌상단에 "슬롯 N" 태그를 추가로 겹쳐 일반 스킬과 레이아웃을
	# 구분한다(이름 라벨 텍스트는 그대로 둔다 — 보유 스킬 이름이 "확장"처럼 그대로
	# 보여야 하는 기존 계약을 깨지 않기 위해 슬롯 번호는 별도 태그로만 표시).
	if is_starting:
		var slot_info := _make_corner_tag(wrap, "슬롯 %d" % (slot_index + 1), SLOT_TAG_BG, palette["accent"], false)
		_slot_tag_by_id[skill_id] = slot_info["label"]

	if revealed:
		card.activated.connect(_on_card_activated.bind(skill_id))

	_card_by_id[skill_id] = card
	return card
