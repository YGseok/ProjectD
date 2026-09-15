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
## 방식으로 개편)의 한 행 크기. 예전에는 카드 폭을 캐릭터 수에 맞춰 동적으로 계산했지만
## (화면 폭을 5등분), 이제는 카드가 세로로 쌓이는 목록이라 폭이 고정이어도 캐릭터가
## 늘어나도(6종째부터는 CardsContainer 높이를 넘어 스크롤이 필요해질 수 있음 — 지금
## 5종까지는 문제 없음) 문제가 없다.
const CARD_WIDTH := 360.0
const CARD_HEIGHT := 92.0
const CARD_GAP := 12.0
## PORTRAIT_SCALE: CharacterPortraitPlaceholder는 원래 카드 전체(약 136x248px)를 채우는
## 크기로 그려지므로, 목록의 작은 초상 칸에 맞추려면 축소해야 한다(Node2D.scale 사용 —
## _draw() 좌표 자체를 다시 계산하지 않고 그대로 축소).
const PORTRAIT_SCALE := 0.32

@onready var cards_container: Control = $CardsContainer
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
var _detail_name_label: Label
var _detail_concept_label: Label
var _detail_dice_label: Label
var _detail_skill_label: Label

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
	for i in CharacterProfiles.PROFILES.size():
		var profile: Dictionary = CharacterProfiles.PROFILES[i]
		var card := _make_card(profile, select_buttons)
		card.position = Vector2(0, i * (CARD_HEIGHT + CARD_GAP))
		cards_container.add_child(card)
		_card_panels[profile["id"]] = card

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
	var portrait := CharacterPortraitPlaceholder.new()
	portrait.scale = Vector2(PORTRAIT_SCALE, PORTRAIT_SCALE)
	# 실루엣 그리기 범위는 원본 스케일 기준 x -68~68 / y -108~140(character_portrait_
	# placeholder.gd 참고). PORTRAIT_SCALE(0.32)을 곱하면 x -21.8~21.8 / y -34.6~44.8 —
	# holder(56 x CARD_HEIGHT) 안에서 가로는 중앙(28), 세로는 위/아래 범위 중간이 holder
	# 세로 중앙(CARD_HEIGHT/2)에 오도록 원점을 살짝 위로 올린다((-34.6+44.8)/2 ≈ 5.1).
	portrait.position = Vector2(28, CARD_HEIGHT / 2.0 - 5)
	portrait.set_palette(profile["hair_color"], profile["dress_color"])
	portrait_holder.add_child(portrait)
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
	portrait_holder.custom_minimum_size = Vector2(160, 0)
	_detail_portrait = CharacterPortraitPlaceholder.new()
	_detail_portrait.position = Vector2(80, 120)
	portrait_holder.add_child(_detail_portrait)
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

	_detail_skill_label = _make_detail_body_label()
	info_vbox.add_child(_detail_skill_label)

	var note_label := Label.new()
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
	_detail_name_label.text = profile["name"]
	_detail_concept_label.text = "설명: %s" % String(profile.get("concept", profile.get("desc", "")))
	_detail_dice_label.text = "시작 다이스: 공격 D4 x%d / 방어 D4 x%d" % [
		int(profile.get("attack_count", 3)), int(profile.get("defense_count", 3))
	]
	_detail_skill_label.text = "보유 스킬: %s" % CharacterProfiles.gimmick_label(String(profile.get("gimmick", "")))


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
