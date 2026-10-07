extends Node2D
## 캐릭터 선택 화면.
##
## INBOX.md 피드백("던전에 입장하면, 플레이어블 캐릭터를 선택해야한다. 슬더스와
## 유사" + "일단은 능력 없는 기본 캐릭터. 이쁘장한 여캐 하나 디자인한다")을 반영한
## 최소 구현에서 시작해, [대형 기획 1]("플레이어블 캐릭터 4종 추가, 총 5종 중 선택
## 입장", 2026-09-09)의 첫 조각으로 카드 1개("확인")에서 여러 카드 중 하나를 고르는
## 형태로 확장했다. 실제 캐릭터 정의는 code/systems/character_profiles.gd
## (CharacterProfiles.PROFILES)에 있고, 이 씬은 그 목록을 카드로 그리고 클릭한
## 카드를 금테로 강조하는 역할만 한다(achievement_panel.gd의 카드 스타일 패턴을
## 재사용). 실제 일러스트 에셋은 없어서(아트 파이프라인 필요, 사람 확인 대기) 도형으로
## 조립한 플레이스홀더 실루엣(character_portrait_placeholder.gd)을 캐릭터별로 색만
## 바꿔서 보여준다.
##
## 흐름: 이 화면이 project.godot의 main_scene이 됨 -> 카드 클릭으로 캐릭터 선택
## (기본값: 첫 번째 프로필) -> "던전 시작" 버튼 -> RunState.reset_run(선택한 id)로
## 새 런 시작 -> dungeon_map.tscn.

## CARD_WIDTH/CARD_HEIGHT/CARD_GAP: 왼쪽 카드 목록(초상+이름만, INBOX.md 2026-09-14
## "외형과 이름들만 간략하게 나오고, 패널 선택시 오른쪽에 상세 정보를 제공"을 반영해
## 2026-09-15에 "카드 하나에 모든 정보" 방식에서 "간략한 목록 + 오른쪽 상세 패널"
## 방식으로 개편)의 한 행 "기대" 크기 — 실제 행 간격은 _build_cards()가 각 카드의
## 실제 결합 최소 높이(get_combined_minimum_size())를 측정해서 쌓으므로(ART-1a,
## 2026-10-07), CARD_HEIGHT는 포트레이트 칸 크기 등 다른 계산의 기준값으로만 쓰인다.
## **CardsContainer는 이제 ScrollContainer**(캐릭터가 늘어나 목록이 보이는 영역(540px)
## 보다 길어져도 스크롤로 전부 닿을 수 있게 — 7종(7×104=728px)부터 실제로 넘침,
## `qa_out/art_character_select.png`에서 7번째 카드가 화면 밖으로 밀려 선택 불가했던
## 버그로 발견됨).
const CARD_WIDTH := 360.0
const CARD_HEIGHT := 92.0
const CARD_GAP := 12.0
## PORTRAIT_SCALE: CharacterPortraitPlaceholder는 원래 카드 전체(약 136x248px)를 채우는
## 크기로 그려지므로, 목록의 작은 초상 칸에 맞추려면 축소해야 한다(Node2D.scale 사용 —
## _draw() 좌표 자체를 다시 계산하지 않고 그대로 축소).
const PORTRAIT_SCALE := 0.32
## DETAIL_ART_SIZE: 상세 패널 왼쪽 전신 원화 칸 크기. 원화 비율(1181x1332 ≈ 0.89)에
## 맞추고, 패널 내용 높이(540 - 상하 여백 48 = 492) 안에 들어가게 잡았다.
const DETAIL_ART_SIZE := Vector2(260, 293)

@onready var cards_container: Control = $CardsContainer/CardsList
@onready var detail_container: Control = $DetailPanelContainer
@onready var start_button: Button = $StartButton
@onready var achievement_button: Button = $AchievementButton
@onready var achievement_panel: AchievementPanel = $AchievementPanel

var _selected_id: String = CharacterProfiles.PROFILES[0]["id"]
var _card_panels: Dictionary = {} # id -> PanelContainer (선택 강조 갱신용)

## 상세 정보 패널(오른쪽)의 자식 노드들. _build_detail_panel()에서 한 번만 만들고,
## 카드를 고를 때마다 _refresh_detail_panel()이 텍스트/초상만 바꿔 다시 만들지 않는다
## (매번 새로 만들면 불필요하게 무겁고, 스크롤 위치 등 상태가 있다면 리셋될 수 있음).
var _detail_portrait: CharacterPortraitPlaceholder
## 원화가 입고된 캐릭터는 이 TextureRect에 전신(CharacterArt.load_full)을 띄우고
## _detail_portrait(플레이스홀더)를 숨긴다. 원화가 없으면 반대로.
var _detail_art: TextureRect
var _detail_placeholder_note: Label
var _detail_name_label: Label
var _detail_concept_label: Label
var _detail_dice_label: Label
var _detail_skill_label: Label
var _detail_skill_icon: SkillIcon
var _detail_event_die_label: Label
var _detail_event_die_visual: EventDieVisual

## 시작 스킬 선택([미니 기획 E]-3, INBOX.md 2026-09-17 기획자 결정) — 캐릭터마다
## SkillPool.starting_skills_for_character()가 돌려주는 후보(항상 최대 2개, 슬롯
## 0/1)를 _starting_skill_container 안에 버튼으로 채운다. 캐릭터를 바꿀 때마다 후보
## 목록 자체가 달라지므로(cards_container와 달리) 매번 자식을 지우고 다시 만든다.
var _starting_skill_container: HBoxContainer
var _starting_skill_desc_label: Label
var _starting_skill_lock_badge_label: Label
var _starting_skill_unlock_label: Label

## 잠긴 슬롯을 "미리보기" 중인 스킬 id([대형 기획 5] F-1) — 빈 문자열이면 미리보기
## 없음(설명란은 RunState.chosen_starting_skill_id를 보여줌). 캐릭터를 바꾸거나 실제로
## 해금된 스킬을 고르면 비운다. chosen_starting_skill_id와 별개 상태이므로 미리보기
## 중에도 "던전 시작"은 항상 chosen_starting_skill_id(해금된 마지막 선택) 기준으로 진행된다.
var _preview_skill_id: String = ""

## KeyboardShortcuts로 1~N 숫자 키를 순서대로 배정하는 데 쓴다(INBOX.md 2026-09-14
## "키보드로도 조작이 되도록" — 던전 맵/스토리 이벤트/특수 이벤트에 이어 이 화면에도
## 같은 유틸을 재사용, docs/STATUS.md 큐 16 "키보드 조작/단축키" 참고). 캐릭터 카드마다
## "선택" 버튼(개수는 PROFILES 길이만큼, 지금 5개)이 먼저 오고, 그 뒤로 "던전 시작"/
## "업적" 두 화면 공용 버튼이 이어진다 — 카드 목록은 _build_cards()에서 한 번만 만들고
## 이후 카드를 다시 그리지 않으므로(선택은 강조 갱신만 함), 여기서도 한 번만 채우면 된다.
var _shortcut_buttons: Array[Button] = []


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	_build_detail_panel()
	_build_cards()


func _build_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	_card_panels.clear()

	var select_buttons: Array[Button] = []
	# ART-1a(2026-10-07): CARD_HEIGHT(92)를 고정 행 간격으로 썼더니, 패널의 실제
	# 결합 최소 높이(panel 스타일박스 여백 + 내부 버튼/라벨 최소 크기)가 그보다 커서
	# Godot이 자동으로 size를 키우며 다음 행과 겹쳤다. 대신 카드를 추가할 때마다
	# get_combined_minimum_size()로 실제 필요한 높이를 재고 그만큼만 다음 행을 내린다.
	var y := 0.0
	for i in CharacterProfiles.PROFILES.size():
		var profile: Dictionary = CharacterProfiles.PROFILES[i]
		var card := _make_card(profile, select_buttons)
		cards_container.add_child(card)
		card.position = Vector2(0, y)
		var card_height: float = max(CARD_HEIGHT, card.get_combined_minimum_size().y)
		card.size = Vector2(CARD_WIDTH, card_height)
		y += card_height + CARD_GAP
		_card_panels[profile["id"]] = card
	cards_container.custom_minimum_size = Vector2(CARD_WIDTH, max(0.0, y - CARD_GAP))

	_refresh_selection_highlight()
	_refresh_detail_panel()

	_shortcut_buttons = select_buttons
	_shortcut_buttons.append(start_button)
	_shortcut_buttons.append(achievement_button)
	KeyboardShortcuts.apply_hints(_shortcut_buttons)


## 목록 한 행: 작은 초상 + 이름 + "선택" 버튼뿐(INBOX.md 요청대로 "외형과 이름들만
## 간략하게"). 컨셉 설명/시작 다이스/스킬 같은 상세 정보는 더 이상 카드에 없고
## 오른쪽 DetailPanel로 옮겨졌다.
func _make_card(profile: Dictionary, select_buttons: Array[Button]) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(hbox)

	var portrait_holder := Control.new()
	portrait_holder.custom_minimum_size = Vector2(56, CARD_HEIGHT)
	# 원화가 입고된 캐릭터는 상반신 썸네일(CharacterArt.load_thumb)을, 아직 없는
	# 캐릭터는 아래의 도형 플레이스홀더를 그린다(docs/art/ART_RESOURCES.md 4장).
	var thumb := CharacterArt.load_thumb(profile["id"])
	if thumb != null:
		portrait_holder.custom_minimum_size = Vector2(72, CARD_HEIGHT)
		var thumb_rect := TextureRect.new()
		thumb_rect.texture = thumb
		thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		thumb_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_holder.add_child(thumb_rect)
	else:
		_add_placeholder_thumb(portrait_holder, profile)
	hbox.add_child(portrait_holder)

	var name_label := Label.new()
	name_label.text = profile["name"]
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox.add_child(name_label)

	var select_button := Button.new()
	select_button.text = "선택"
	select_button.custom_minimum_size = Vector2(64, 0)
	select_button.pressed.connect(_on_card_selected.bind(profile["id"]))
	hbox.add_child(select_button)
	select_buttons.append(select_button)

	return panel


func _add_placeholder_thumb(portrait_holder: Control, profile: Dictionary) -> void:
	var portrait := CharacterPortraitPlaceholder.new()
	portrait.scale = Vector2(PORTRAIT_SCALE, PORTRAIT_SCALE)
	# 실루엣 그리기 범위는 원본 스케일 기준 x -68~68 / y -108~140(character_portrait_
	# placeholder.gd 참고). PORTRAIT_SCALE(0.32)을 곱하면 x -21.8~21.8 / y -34.6~44.8 —
	# holder(56 x CARD_HEIGHT) 안에서 가로는 중앙(28), 세로는 위/아래 범위 중간이 holder
	# 세로 중앙(CARD_HEIGHT/2)에 오도록 원점을 살짝 위로 올린다((-34.6+44.8)/2 ≈ 5.1).
	portrait.position = Vector2(28, CARD_HEIGHT / 2.0 - 5)
	portrait.set_palette(profile["hair_color"], profile["dress_color"])
	portrait_holder.add_child(portrait)


## 오른쪽 상세 정보 패널의 뼈대(패널 배경 + 제목/초상/설명/시작 다이스/보유 스킬
## 라벨)를 한 번만 만든다. 실제 내용은 _refresh_detail_panel()이 채운다.
func _build_detail_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_color = Color(0.4, 0.4, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	detail_container.add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 28)
	panel.add_child(hbox)

	var portrait_holder := Control.new()
	portrait_holder.custom_minimum_size = Vector2(DETAIL_ART_SIZE.x, 0)
	_detail_portrait = CharacterPortraitPlaceholder.new()
	_detail_portrait.position = Vector2(DETAIL_ART_SIZE.x / 2.0, 120)
	portrait_holder.add_child(_detail_portrait)
	_detail_art = TextureRect.new()
	_detail_art.size = DETAIL_ART_SIZE
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_holder.add_child(_detail_art)
	hbox.add_child(portrait_holder)

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 14)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	_detail_name_label = Label.new()
	_detail_name_label.add_theme_font_size_override("font_size", 30)
	_detail_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	info_vbox.add_child(_detail_name_label)

	_detail_concept_label = _make_detail_body_label()
	info_vbox.add_child(_detail_concept_label)

	_detail_dice_label = _make_detail_body_label()
	info_vbox.add_child(_detail_dice_label)

	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 8)
	_detail_skill_icon = SkillIcon.new()
	_detail_skill_icon.custom_minimum_size = Vector2(28, 28)
	skill_row.add_child(_detail_skill_icon)
	_detail_skill_label = _make_detail_body_label()
	_detail_skill_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_child(_detail_skill_label)
	info_vbox.add_child(skill_row)

	# 이벤트 주사위(INBOX.md 2026-09-15 [미니 기획 B]-4): 공격/방어와 별개인 특수 이벤트
	# 전용 다이스 — 로마 숫자 육각 칩(EventDieVisual)으로 일반 다이스와 구분해서 보여준다.
	# 지금은 5종 전부 D6로 같아 값도 항상 같지만, 필드 구조 자체는 캐릭터별로 열려 있다.
	var event_die_row := HBoxContainer.new()
	event_die_row.add_theme_constant_override("separation", 8)
	_detail_event_die_visual = EventDieVisual.new()
	_detail_event_die_visual.custom_minimum_size = Vector2(28, 28)
	event_die_row.add_child(_detail_event_die_visual)
	_detail_event_die_label = _make_detail_body_label()
	_detail_event_die_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_die_row.add_child(_detail_event_die_label)
	info_vbox.add_child(event_die_row)

	# 시작 스킬 선택([미니 기획 E]-3): 제목 + 슬롯 버튼 목록 + 선택된 스킬 설명.
	# 슬롯 버튼 자체는 후보가 캐릭터마다 다르므로 여기서는 빈 컨테이너만 만들고,
	# 실제 채우기는 _rebuild_starting_skill_slots()가 캐릭터를 고를 때마다 담당한다.
	var skill_choice_title := Label.new()
	skill_choice_title.text = "시작 스킬 (하나만 선택)"
	skill_choice_title.add_theme_font_size_override("font_size", 16)
	skill_choice_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	info_vbox.add_child(skill_choice_title)

	_starting_skill_container = HBoxContainer.new()
	_starting_skill_container.add_theme_constant_override("separation", 10)
	info_vbox.add_child(_starting_skill_container)

	# 잠긴 슬롯 미리보기([대형 기획 5] F-1) — 자물쇠+"잠김" 배지(맨 위) / 효과 설명
	# (기존 _starting_skill_desc_label 재사용, 선택/미리보기 공통) / 해금 조건(노란 계열,
	# 미리보기 중일 때만 보임) 순서로 쌓는다.
	_starting_skill_lock_badge_label = _make_detail_body_label()
	_starting_skill_lock_badge_label.text = "🔒 잠김 (미리보기)"
	_starting_skill_lock_badge_label.add_theme_color_override("font_color", Color(0.85, 0.68, 0.25))
	_starting_skill_lock_badge_label.visible = false
	info_vbox.add_child(_starting_skill_lock_badge_label)

	_starting_skill_desc_label = _make_detail_body_label()
	info_vbox.add_child(_starting_skill_desc_label)

	_starting_skill_unlock_label = _make_detail_body_label()
	_starting_skill_unlock_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
	_starting_skill_unlock_label.visible = false
	info_vbox.add_child(_starting_skill_unlock_label)

	var note_label := Label.new()
	_detail_placeholder_note = note_label
	note_label.text = "※ 플레이스홀더 실루엣 — 실제 일러스트는 추후 작업"
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_label.add_theme_font_size_override("font_size", 12)
	note_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	info_vbox.add_child(note_label)


func _make_detail_body_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	return label


## 선택된 캐릭터가 바뀔 때마다 상세 패널 내용을 갱신한다. "시작 다이스"는 desc의
## 서술형 문장을 다시 파싱하지 않고 attack_count/defense_count에서 직접 만들어
## (DESIGN.md 확정대로 면 개수는 5종 전부 D4) 캐릭터별 수치 변경에 항상 정확하다.
func _refresh_detail_panel() -> void:
	var profile := CharacterProfiles.get_profile(_selected_id)
	_detail_portrait.set_palette(profile["hair_color"], profile["dress_color"])
	var art := CharacterArt.load_full(_selected_id)
	_detail_art.texture = art
	_detail_art.visible = art != null
	_detail_portrait.visible = art == null
	_detail_placeholder_note.visible = art == null
	_detail_name_label.text = profile["name"]
	_detail_concept_label.text = "설명: %s" % String(profile.get("concept", profile.get("desc", "")))
	_detail_dice_label.text = "시작 다이스: 공격 D4 x%d / 방어 D4 x%d" % [
		int(profile.get("attack_count", 3)), int(profile.get("defense_count", 3))
	]
	_detail_skill_label.text = "보유 스킬: %s" % CharacterProfiles.gimmick_label(String(profile.get("gimmick", "")))
	_detail_skill_icon.category = String(profile.get("gimmick", ""))
	var event_sides: int = int(profile.get("event_die_sides", 6))
	_detail_event_die_label.text = "이벤트 주사위: D%d (로마 숫자로 표기, 커스터마이징 불가)" % event_sides
	_detail_event_die_visual.value = 1
	_preview_skill_id = "" # 캐릭터가 바뀌면 이전 캐릭터의 잠긴 슬롯 미리보기는 의미가 없다.
	_rebuild_starting_skill_slots()


## [미니 기획 E]-3: 캐릭터를 고를 때마다 그 캐릭터의 시작 스킬 후보(항상 슬롯 0/1,
## SkillPool.starting_skills_for_character() 등장 순서)로 슬롯 버튼을 다시 그린다.
## 먼저 RunState.chosen_starting_skill_id가 이 캐릭터에서 여전히 유효한지(후보에
## 있고, 잠겨있지 않은지) 검증해 아니면 슬롯 0으로 되돌린다 — 예를 들어 "확장"
## (start_expand)은 견습 모험가의 슬롯 0(항상 해금)이지만 폭발병의 슬롯 1(업적
## 해금 필요)이기도 해서, 같은 id라도 캐릭터가 바뀌면 잠금 상태가 달라질 수 있다.
func _rebuild_starting_skill_slots() -> void:
	# remove_child()로 즉시 트리에서 떼어낸 뒤 queue_free()로 지운다(단순 queue_free()만
	# 쓰면 그 프레임 끝까지 컨테이너 자식 목록에 남아 새로 추가한 버튼과 인덱스가
	# 섞인다 — 이 함수는 같은 프레임 안에서 슬롯 버튼 자신의 pressed 핸들러
	# (_on_starting_skill_selected)에서도 호출되므로, remove_child()로 즉시 떼어내되
	# 실제 메모리 해제는 여전히 queue_free()로 미뤄 시그널 처리 중 해제로 인한
	# 크래시를 피한다).
	for c in _starting_skill_container.get_children():
		_starting_skill_container.remove_child(c)
		c.queue_free()

	var candidates := SkillPool.starting_skills_for_character(_selected_id)
	RunState.chosen_starting_skill_id = _valid_or_default_starting_skill_id(_selected_id, RunState.chosen_starting_skill_id, candidates)

	for i in candidates.size():
		var skill: Dictionary = candidates[i]
		var unlocked: bool = _is_slot_unlocked(_selected_id, i)
		_starting_skill_container.add_child(_make_starting_skill_slot(skill, unlocked, i))

	_update_starting_skill_description(candidates)


## 슬롯 해금 여부를 SkillPool.is_slot_requirement_met() 한 곳에서만 판정한다([대형 기획 5]
## F-1, F-2(a)) — 예전에는 이 파일 안에 "clear_" + id 하드코딩이 두 곳 있었는데, 그 둘을
## 포함해 SkillPool로 단일화했다(마이그레이션 "또는" 판정도 거기서 처리).
func _is_slot_unlocked(character_id: String, slot_index: int) -> bool:
	return SkillPool.is_slot_requirement_met(character_id, slot_index)


## chosen_id가 candidates 안에서 "잠기지 않은" 슬롯을 가리키면 그대로 유지하고,
## 아니면 슬롯 0(candidates[0], 후보가 있는 한 항상 해금 상태)으로 되돌린다.
## 후보가 비어있으면(정의 누락 등 이상 상황) 빈 문자열을 반환한다.
func _valid_or_default_starting_skill_id(character_id: String, chosen_id: String, candidates: Array[Dictionary]) -> String:
	if candidates.is_empty():
		return ""
	for i in candidates.size():
		if candidates[i]["id"] == chosen_id:
			if _is_slot_unlocked(character_id, i):
				return chosen_id
			break
	return candidates[0]["id"]


## 슬롯 하나(PanelContainer 역할을 겸하는 Button)를 만든다. [대형 기획 5] F-1부터는
## 잠긴 슬롯도 클릭 가능하다(disabled=false로 유지) — 클릭하면 chosen_starting_skill_id를
## 바꾸는 대신 "미리보기"(_on_starting_skill_locked_preview)로 빠진다. 잠긴 슬롯은
## 여전히 LockIcon + 흐린 이름표로 구분해 보이지만, "선택 불가"는 이제 스타일이 아니라
## pressed 핸들러의 분기(실제로 chosen을 바꾸는지 여부)로 보장한다.
func _make_starting_skill_slot(skill: Dictionary, unlocked: bool, slot_index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 56)
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(content)

	if unlocked:
		var name_label := Label.new()
		name_label.text = skill["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		content.add_child(name_label)
	else:
		var lock_row := HBoxContainer.new()
		lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		lock_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_row.add_theme_constant_override("separation", 4)
		var lock_icon := LockIcon.new()
		lock_icon.custom_minimum_size = Vector2(16, 16)
		lock_row.add_child(lock_icon)
		var name_label := Label.new()
		name_label.text = skill["name"]
		name_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		lock_row.add_child(name_label)
		content.add_child(lock_row)
		button.tooltip_text = SkillPool.unlock_requirement(_selected_id, slot_index)["text"]

	var is_previewing: bool = not unlocked and skill["id"] == _preview_skill_id
	var selected: bool = unlocked and skill["id"] == RunState.chosen_starting_skill_id
	button.add_theme_stylebox_override("normal", _starting_skill_slot_style(selected, unlocked, is_previewing))
	button.add_theme_stylebox_override("hover", _starting_skill_slot_style(selected, unlocked, is_previewing))
	button.add_theme_stylebox_override("pressed", _starting_skill_slot_style(selected, unlocked, is_previewing))

	if unlocked:
		button.pressed.connect(_on_starting_skill_selected.bind(skill["id"]))
	else:
		button.pressed.connect(_on_starting_skill_locked_preview.bind(skill["id"]))

	return button


## selected(현재 chosen_starting_skill_id와 일치)면 캐릭터 카드 선택과 같은 금테,
## previewing(잠긴 슬롯을 지금 미리보는 중)이면 얇은 노란 테두리로 "보는 중"임을 표시,
## 그 외 잠긴 슬롯은 어두운 배경, 나머지(선택 안 된 해금 슬롯)는 일반 회색 테두리.
func _starting_skill_slot_style(selected: bool, unlocked: bool, previewing: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	if not unlocked:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
		if previewing:
			style.border_color = Color(0.85, 0.68, 0.25)
			style.set_border_width_all(2)
		else:
			style.border_color = Color(0.3, 0.3, 0.3)
			style.set_border_width_all(1)
	elif selected:
		style.bg_color = Color(0.22, 0.19, 0.08, 0.95)
		style.border_color = Color(0.85, 0.68, 0.25)
		style.set_border_width_all(3)
	else:
		style.bg_color = Color(0.14, 0.14, 0.16, 0.9)
		style.border_color = Color(0.35, 0.35, 0.35)
		style.set_border_width_all(1)
	return style


## 해금된 슬롯을 고르면 실제로 선택이 바뀐다 — 미리보기 상태였다면 비운다(이제 선택된
## 스킬 자체가 설명란에 보이므로 미리보기와 구분할 필요가 없다).
func _on_starting_skill_selected(id: String) -> void:
	RunState.chosen_starting_skill_id = id
	_preview_skill_id = ""
	_rebuild_starting_skill_slots()


## 잠긴 슬롯을 클릭([대형 기획 5] F-1)하면 RunState.chosen_starting_skill_id는 그대로
## 두고 "미리보기"만 바꾼다 — 설명란에 그 스킬의 효과 + 해금 조건이 보이지만, 실제
## 시작 스킬(그리고 "던전 시작"이 쓰는 값)은 여전히 해금된 마지막 선택이다.
func _on_starting_skill_locked_preview(id: String) -> void:
	_preview_skill_id = id
	_rebuild_starting_skill_slots()


## 미리보기 중이면(_preview_skill_id != "") 그 스킬의 효과+해금 조건을, 아니면 현재
## chosen_starting_skill_id의 효과만 보여준다. 자물쇠 배지/해금 조건 줄은 미리보기 중일
## 때만 visible=true가 된다(선택된 스킬은 항상 해금 상태이므로 평소엔 숨김).
func _update_starting_skill_description(candidates: Array[Dictionary]) -> void:
	var show_id: String = _preview_skill_id if _preview_skill_id != "" else RunState.chosen_starting_skill_id
	for i in candidates.size():
		var skill: Dictionary = candidates[i]
		if skill["id"] != show_id:
			continue
		_starting_skill_desc_label.text = "효과: %s" % skill["description"]
		if _preview_skill_id != "":
			_starting_skill_lock_badge_label.visible = true
			_starting_skill_unlock_label.text = "해금 조건: %s" % SkillPool.unlock_requirement(_selected_id, i)["text"]
			_starting_skill_unlock_label.visible = true
		else:
			_starting_skill_lock_badge_label.visible = false
			_starting_skill_unlock_label.visible = false
		return
	_starting_skill_desc_label.text = ""
	_starting_skill_lock_badge_label.visible = false
	_starting_skill_unlock_label.visible = false


## 숫자 키(1~9)로 캐릭터 카드 "선택" 버튼(+던전 시작/업적)을 순서대로 누른다
## (dungeon_map.gd의 같은 패턴 재사용). 업적 패널이 열려있을 때는 뒤에 가려진 버튼이
## 함께 눌리면 안 되므로 무시한다.
func _unhandled_input(event: InputEvent) -> void:
	if achievement_panel.visible:
		return
	var idx := KeyboardShortcuts.digit_index(event)
	if idx < 0:
		return
	# get_viewport()는 try_press() 이전에 미리 받아둬야 한다 — "던전 시작" 버튼처럼 눌렸을
	# 때 change_scene_to_file()로 씬을 바꾸는 버튼이면, 이 노드가 try_press() 도중 트리에서
	# 빠져나가 그 뒤의 get_viewport()가 null을 반환해 set_input_as_handled() 호출이
	# 크래시한다(shop.gd에서 실제로 겪고 발견해 5개 화면 공통으로 수정, 2026-09-15).
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press(_shortcut_buttons, idx) and viewport != null:
		viewport.set_input_as_handled()


func _on_card_selected(id: String) -> void:
	_selected_id = id
	_refresh_selection_highlight()
	_refresh_detail_panel()


## 선택된 카드는 금테(업적 패널의 "해금" 카드와 같은 색 언어), 나머지는 회색 테두리로
## 표시해 "지금 무엇이 골라져 있는지"를 한눈에 알 수 있게 한다.
func _refresh_selection_highlight() -> void:
	for id in _card_panels:
		var panel: PanelContainer = _card_panels[id]
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.14, 0.16, 0.9)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		if id == _selected_id:
			style.bg_color = Color(0.22, 0.19, 0.08, 0.95)
			style.border_color = Color(0.85, 0.68, 0.25)
			style.set_border_width_all(3)
		else:
			style.border_color = Color(0.35, 0.35, 0.35)
			style.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", style)


func _on_start_pressed() -> void:
	# INBOX.md [대형 기획 3] 업적 #25 "첫 런 시작" — 던전 시작 버튼을 누른 시점이
	# 가장 확실한 트리거 지점(캐릭터가 몇 종으로 늘어나도 항상 이 버튼을 거쳐감).
	AchievementManager.unlock("first_run_start")
	RunState.reset_run(_selected_id)
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


func _on_achievement_pressed() -> void:
	if achievement_panel.visible:
		achievement_panel.close()
	else:
		achievement_panel.open()


## QA 전용: 클릭을 흉내낼 수 없는 자동 스크린샷에서 버튼 동작을 검증하기 위한 래퍼.
func _debug_start_run() -> void:
	_on_start_pressed()


## QA 전용: 카드 클릭을 흉내내 "광전사" 카드를 고른 상태를 스크린샷으로 검증하기
## 위함. scripts/qa_shot.sh의 GAME_QA_CALL은 인자 없이 메서드를 호출하므로
## (code/qa/visual_qa.gd 참고), 인자가 있는 메서드를 직접 넘기면 GDScript 오류로
## 창이 멈춰버릴 수 있어(2026-09-09 실제로 겪음 — 아래 STATUS.md 알려진 이슈 참고)
## 캐릭터별로 인자 없는 래퍼를 따로 둔다.
func _debug_select_berserker() -> void:
	_on_card_selected("berserker")


## QA 전용: "수호자" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_guardian() -> void:
	_on_card_selected("guardian")


## QA 전용: "폭발병" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_explosive() -> void:
	_on_card_selected("explosive")


## QA 전용: "방패병" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유).
func _debug_select_shieldbearer() -> void:
	_on_card_selected("shieldbearer")


## QA 전용: "광전사"를 고른 채로 실제 던전 시작까지 이어지는 전체 경로를 한 번에
## 검증하기 위한 래퍼(선택 -> 시작 -> dungeon_map 전환까지, 실제 플레이와 동일 경로).
## 던전 맵의 "공격/방어 주머니" 패널에 1/4만 보이는지(force_min_max_faces 효과)로
## 캐릭터 기믹이 실제로 새 런에 반영됐는지 화면에서 확인할 수 있다.
func _debug_start_run_as_berserker() -> void:
	_on_card_selected("berserker")
	_on_start_pressed()


## QA 전용: "수호자"로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). 방어 주머니 다이스 하나만 고정값(3)이고 나머지는 그대로인지 화면에서 확인.
func _debug_start_run_as_guardian() -> void:
	_on_card_selected("guardian")
	_on_start_pressed()


## QA 전용: "폭발병"으로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). explosive_stack은 정적 다이스 개조가 없어(character_profiles.gd 참고)
## 덱 패널에는 다른 캐릭터와 달리 아무 차이가 안 보이는 게 정상 — 실제 효과는
## combat_test.gd의 전투 중 상태(_debug_show_explosive_dice() 참고)로 확인해야 한다.
func _debug_start_run_as_explosive() -> void:
	_on_card_selected("explosive")
	_on_start_pressed()


## QA 전용: "방패병"으로 던전 시작까지 이어지는 전체 경로 검증(_debug_start_run_as_berserker와
## 같은 이유). guard_stack은 explosive_stack과 마찬가지로 정적 다이스 개조가 없어
## 덱 패널에는 아무 차이가 안 보이는 게 정상 — 실제 효과는 combat_test.gd의 전투 중
## 상태(_debug_show_guard_dice() 참고)로 확인해야 한다.
func _debug_start_run_as_shieldbearer() -> void:
	_on_card_selected("shieldbearer")
	_on_start_pressed()


## QA 전용: "곡예사" 카드를 고른 상태 검증용 (_debug_select_berserker와 같은 이유,
## INBOX.md 2026-09-24 [대형 기획 4]-C 신규). 7번째(목록 맨 아래) 카드라 왼쪽 목록
## 스크롤/상세 패널 겹침 여부까지 함께 확인할 수 있다.
func _debug_select_juggler() -> void:
	_on_card_selected("juggler")


## QA 전용: 이전 QA 실행에서 남은 해금 상태가 섞이지 않도록 초기화한 뒤, 업적 하나를
## 미리 해금해 "잠김/해금" 두 상태가 동시에 보이는 화면을 스크린샷으로 검증한다.
func _debug_show_achievements() -> void:
	AchievementManager._debug_reset_for_qa()
	AchievementManager.unlock("first_run_start")
	achievement_panel.open()


## QA 전용: 업적 유형별 아이콘(achievement_icon.gd)이 목록 아래쪽 항목(pip/bag/shop/
## material 카테고리)에서도 겹침/누락 없이 그려지는지 스크린샷으로 확인하기 위해,
## 패널을 연 뒤 스크롤을 맨 아래로 내린다.
func _debug_show_achievements_scrolled() -> void:
	_debug_show_achievements()
	# 목록(ScrollContainer)의 스크롤 범위는 VBoxContainer의 레이아웃 정렬(queue_sort,
	# 다음 프레임에 처리됨)이 끝나야 갱신되므로, 같은 프레임에 바로 스크롤 값을 설정하면
	# 아직 갱신 전인 max_value(0에 가까움)로 클램프돼 무시된다 — call_deferred로 한 프레임
	# 미뤄서 레이아웃이 끝난 뒤에 스크롤하도록 한다.
	achievement_panel.call_deferred("_debug_scroll_to_bottom")


## QA 전용: [미니 기획 E]-3 슬롯 1이 "잠김" 상태(자물쇠 아이콘 + disabled)로 보이는
## 기본 화면을 검증하기 위해, 이전 QA 실행에서 남은 해금 상태를 초기화하고 견습
## 모험가를 선택한다(견습 모험가의 슬롯 1 "정예"가 잠긴 채로 보여야 정상).
func _debug_show_starting_skill_locked() -> void:
	AchievementManager._debug_reset_for_qa()
	_on_card_selected("novice")


## QA 전용: "clear_novice" 업적을 미리 해금해 슬롯 1("정예")이 해금 상태(자물쇠 없이
## 클릭 가능)로 보이는지 검증한다. 실제로 슬롯 1을 골라 chosen_starting_skill_id가
## 바뀌는 것까지 한 번에 확인한다.
func _debug_show_starting_skill_unlocked() -> void:
	AchievementManager._debug_reset_for_qa()
	AchievementManager.unlock("clear_novice")
	_on_card_selected("novice")
	_on_starting_skill_selected("start_lean")


## QA 전용: [대형 기획 5] F-1 — 잠긴 슬롯("정예")을 클릭해 미리보기 상태(자물쇠 배지 +
## 효과 설명 + 노란 해금 조건 줄)가 겹침 없이 보이는지 확인한다. chosen_starting_skill_id는
## 바뀌지 않아야 한다(여전히 슬롯 0 "확장").
func _debug_show_starting_skill_locked_preview() -> void:
	AchievementManager._debug_reset_for_qa()
	_on_card_selected("novice")
	_on_starting_skill_locked_preview("start_lean")


## QA 전용: [대형 기획 5] F-2(b) — 견습 모험가의 3개 슬롯(확장/정예/황금손)이 모두
## 해금된 상태(r1_novice + clear_novice)로 겹침 없이 가로 배치되는지 확인한다. 상세
## 패널 폭(~600px)에서 150px 버튼 3개(+separation 10px x2)가 들어가는지가 핵심
## 검증 지점(F-2(a) 완료 기록 참고 — 그때는 슬롯이 2개뿐이라 이 레이아웃을 아직
## 확인할 수 없었음).
func _debug_show_starting_skill_all_unlocked() -> void:
	AchievementManager._debug_reset_for_qa()
	AchievementManager.unlock("r1_novice")
	AchievementManager.unlock("clear_novice")
	_on_card_selected("novice")


## QA 전용 — 실제 숫자 키 입력이 _unhandled_input()을 거쳐 버튼까지 눌리는 전체 경로를
## 확인하기 위함(dungeon_map.gd의 _debug_press_shortcut_customize와 같은 이유). "2번"은
## PROFILES 순서상 두 번째 카드("광전사")의 "선택" 버튼에 배정되므로, 이 키를 눌렀을 때
## 실제로 광전사 카드가 금테로 강조되는지로 검증한다.
func _debug_press_shortcut_2() -> void:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_2
	_unhandled_input(key)


## QA 전용 — "7번"은 카드 5장 다음에 오는 "던전 시작"/"업적" 중 두 번째("업적")에
## 배정되므로, 이 키를 눌렀을 때 AchievementPanel이 실제로 열리는지로 검증한다.
func _debug_press_shortcut_7() -> void:
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_7
	_unhandled_input(key)


## QA 전용 — 업적 패널을 연 뒤, 패널 자신의 "[1] 닫기" 단축키(achievement_panel.gd의
## _unhandled_input())가 실제 숫자 키 입력으로 패널을 닫는지 끝까지 확인한다(7/7화면
## 완료 검증, docs/STATUS.md 큐 16 "키보드 조작/단축키"). 업적 패널이 character_select의
## 자식 노드라 이 씬의 _unhandled_input()이 먼저 호출돼도 achievement_panel.visible
## 가드로 인해 이 씬은 이벤트를 소비하지 않고 그대로 achievement_panel로 전달된다.
func _debug_press_shortcut_close_achievements() -> void:
	achievement_panel.open()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1
	achievement_panel._unhandled_input(key)
