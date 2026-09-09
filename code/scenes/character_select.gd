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

## CARD_WIDTH_MAX: 캐릭터 수가 적을 때(지금 4종) 카드가 이보다 넓어지지 않게 하는 상한.
## ROW_MARGIN: 카드 줄 좌우로 남겨두는 여백 — 이 안쪽 폭(1280 - ROW_MARGIN*2)을 카드
## 개수만큼 나눠 카드 폭을 정하므로, 캐릭터가 늘어나도(5종까지 예정, docs/STATUS.md
## 다음 할 일 큐 14번) 카드가 화면 밖으로 밀려나지 않는다(4종째부터 실제로 1280px를
## 넘겨 화면 오른쪽이 잘리던 버그를 이번에 고침 — 폭발병 카드 QA 스크린샷에서 발견).
const CARD_WIDTH_MAX := 360.0
const CARD_HEIGHT := 500.0
const CARD_GAP := 20.0
const ROW_MARGIN := 20.0

@onready var cards_container: Control = $CardsContainer
@onready var start_button: Button = $StartButton
@onready var achievement_button: Button = $AchievementButton
@onready var achievement_panel: AchievementPanel = $AchievementPanel

var _selected_id: String = CharacterProfiles.PROFILES[0]["id"]
var _card_panels: Dictionary = {} # id -> PanelContainer (선택 강조 갱신용)


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	achievement_button.pressed.connect(_on_achievement_pressed)
	_build_cards()


func _build_cards() -> void:
	for c in cards_container.get_children():
		c.queue_free()
	_card_panels.clear()

	var count := CharacterProfiles.PROFILES.size()
	var available_width := 1280.0 - ROW_MARGIN * 2.0
	var card_width: float = min(CARD_WIDTH_MAX, (available_width - (count - 1) * CARD_GAP) / count)
	var total_width := count * card_width + (count - 1) * CARD_GAP
	var start_x := (1280.0 - total_width) / 2.0

	for i in count:
		var profile: Dictionary = CharacterProfiles.PROFILES[i]
		var card := _make_card(profile, card_width)
		card.position = Vector2(start_x + i * (card_width + CARD_GAP), 0)
		cards_container.add_child(card)
		_card_panels[profile["id"]] = card

	_refresh_selection_highlight()


func _make_card(profile: Dictionary, card_width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(card_width, CARD_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var portrait_holder := Control.new()
	portrait_holder.custom_minimum_size = Vector2(card_width, 260)
	var portrait := CharacterPortraitPlaceholder.new()
	# 실루엣 그리기 범위(대략 position 기준 y -108 ~ +140, character_portrait_placeholder.gd
	# _draw() 참고, 폭은 최대 ~136px로 card_width보다 항상 작음)가 holder 높이(260) 안에
	# 들어오도록 y를 114로 둠 — VBoxContainer는 Node2D의 실제 그려지는 범위를 모르고
	# holder의 custom_minimum_size만 공간으로 예약하므로, 여기서 안 맞추면 아래 이름
	# 라벨과 겹친다.
	portrait.position = Vector2(card_width / 2.0, 114)
	portrait.set_palette(profile["hair_color"], profile["dress_color"])
	portrait_holder.add_child(portrait)
	vbox.add_child(portrait_holder)

	var name_label := Label.new()
	name_label.text = profile["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = profile["desc"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(card_width - 40, 0)
	desc_label.add_theme_font_size_override("font_size", 15)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	var note_label := Label.new()
	note_label.text = "※ 플레이스홀더 실루엣 — 실제 일러스트는 추후 작업"
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_label.custom_minimum_size = Vector2(card_width - 40, 0)
	note_label.add_theme_font_size_override("font_size", 12)
	note_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(note_label)

	var select_button := Button.new()
	select_button.text = "선택"
	select_button.pressed.connect(_on_card_selected.bind(profile["id"]))
	vbox.add_child(select_button)

	return panel


func _on_card_selected(id: String) -> void:
	_selected_id = id
	_refresh_selection_highlight()


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


## QA 전용: 이전 QA 실행에서 남은 해금 상태가 섞이지 않도록 초기화한 뒤, 업적 하나를
## 미리 해금해 "잠김/해금" 두 상태가 동시에 보이는 화면을 스크린샷으로 검증한다.
func _debug_show_achievements() -> void:
	AchievementManager._debug_reset_for_qa()
	AchievementManager.unlock("first_run_start")
	achievement_panel.open()
