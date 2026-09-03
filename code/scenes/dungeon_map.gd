extends Node2D
## 던전 맵 허브 씬 (1차 버전).
##
## DESIGN.md 핵심 루프: "방 선택 -> 이벤트 발생 (전투/상점/선택지) -> 보상 -> 다음 방".
## 상점/선택지 이벤트는 아직 내용이 정해지지 않아(DESIGN.md "아직 정해지지 않은 것"),
## 지금은 전투 방 하나만 선택 가능한 최소 스켈레톤이다. combat_test.tscn을 그대로
## "전투 방"으로 재사용한다.
##
## RunState.TOTAL_ROOMS개를 클리어하면 런이 끝난다는 최소 구조를 추가함 (버튼 하나로
## 무한 반복 입장만 가능했던 이전 상태와의 차이).
##
## 방 선택지: INBOX.md 피드백("레벨 디자인된 여러 스테이지... 스텝 바이 스텝으로
## 수평적 선택지를 넓힌다")을 반영해 "전투 방" 하나뿐이던 것을 "전투 방" / "상점" /
## "특수 이벤트" 세 선택지로 넓힘. 어느 쪽을 골라도 방 하나를 소비한 것으로 치고
## (rooms_cleared 증가) 다음 방으로 넘어간다 — 상점/이벤트도 "방"이라는 슬롯을 쓰는
## 선택지로 취급.
##
## "특수 이벤트"는 INBOX.md 피드백("특수한 이벤트에서는 주사위를 늘리는 이벤트를
## 제공한다. 다면체 주사위가 나올 수 있다")을 반영한 무료 방으로, scenes/event.tscn에서
## systems/event_item_pool.gd(EventItemPool)의 D8/D10/D12급 아이템 중 하나를 골라
## 즉시 적용한다 (골드 불필요 — 상점과의 차별점).
##
## 방 선택지 무작위 노출: STATUS.md 다음 할 일 큐("3개 방 선택지가 매번 전부 노출되는
## 대신, 방마다 일부만 무작위로 제시되는 것이 레벨 디자인에 더 가까울 수 있음")를 잠정
## 반영. "전투 방"은 진행을 보장하기 위해 항상 노출하고, 상점/특수 이벤트/스토리
## 이벤트는 방(= RunState.rooms_cleared)마다 결정되는 시드로 각각 독립적으로 등장
## 확률(SHOP_CHANCE/EVENT_CHANCE/STORY_CHANCE)을 굴려 노출 여부를 정한다. 같은
## 방에서는 씬을 다시 그려도(_update_labels 재호출) 같은 결과가 나오도록 rooms_cleared
## 기반 시드를 쓰되, 게임 전체의 randi()/randf()(전투 판정 등)와 섞이지 않도록 별도
## RandomNumberGenerator를 사용한다. 확률 자체는 감으로 잡은 잠정값 — 사람 피드백 필요.
##
## "스토리 이벤트"는 STATUS.md 다음 할 일 큐("순수 텍스트형/스토리형 선택지 이벤트")를
## 반영한 신규 방 종류. 상점/특수 이벤트가 다이스 아이템(DiceItemPool 형식)을 다루는
## 것과 달리, scenes/story_event.tscn은 다이스를 전혀 건드리지 않고 골드만 오가는
## 텍스트 선택지다 (systems/story_event_pool.gd 참고).
##
## 맵 전체 미리보기(MapStrip): INBOX.md 피드백("맵 전체를 봐야할 것 같음")을 반영.
## 방마다 어떤 선택지가 뜰지는 rooms_cleared(방 번호)로 시드가 고정된 결정적 RNG라서
## 아직 도달하지 않은 미래 방도 같은 공식으로 미리 계산할 수 있다 — 그래서 새 상태를
## 따로 들고 다닐 필요 없이(RunState 변경 없음), 이 화면에서 idx=0..TOTAL_ROOMS-1을
## 전부 그 공식으로 계산해 한 줄로 보여주기만 하면 "전체 맵 보기"가 된다.
## 다만 "첫 번째 선택지에 따라 다음 선택지가 어떻게 바뀌는지"(슬더스 스타일 분기 —
## 고른 경로에 따라 이후 노드 구성 자체가 달라지는 것)까지는 아니다: 지금은 방마다
## 노출 여부만 결정적일 뿐 서로 독립적이라, "무엇을 골랐는지"가 "다음 방에 뭐가
## 뜨는지"에 영향을 주지 않는다. 진짜 분기형 맵(노드 그래프 + 경로 선택)은 DESIGN.md가
## 이미 확정한 "일단은 선형으로" 방향을 벗어나는 더 큰 구조 변경이라 별도 설계 확인 후
## 착수하는 게 안전하다고 판단해 이번엔 다루지 않음 (docs/STATUS.md 다음 할 일 큐 참고).

const SHOP_CHANCE := 0.6
const EVENT_CHANCE := 0.5
const STORY_CHANCE := 0.5
const BUTTON_TOP_START := 320.0
const BUTTON_SPACING := 70.0
const BUTTON_HEIGHT := 50.0

@onready var rooms_cleared_label: Label = $RoomsClearedLabel
@onready var gold_label: Label = $GoldLabel
@onready var enter_combat_button: Button = $EnterCombatButton
@onready var enter_shop_button: Button = $EnterShopButton
@onready var enter_event_button: Button = $EnterEventButton
@onready var enter_story_button: Button = $EnterStoryButton
@onready var map_strip: Control = $MapStrip
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var _shop_available := true
var _event_available := true
var _story_available := true
var _map_line: ColorRect
var _map_hbox: HBoxContainer


func _ready() -> void:
	enter_combat_button.pressed.connect(_on_combat_button_pressed)
	enter_shop_button.pressed.connect(_on_shop_button_pressed)
	enter_event_button.pressed.connect(_on_event_button_pressed)
	enter_story_button.pressed.connect(_on_story_button_pressed)
	customize_button.pressed.connect(customize_panel.open)
	_setup_map_strip()
	_roll_room_choices()
	_update_labels()


## 현재 방(rooms_cleared) 기준으로 상점/특수 이벤트/스토리 이벤트 노출 여부를 결정한다.
## 전투 판정에 쓰이는 전역 randi()/randf()와 섞이지 않도록 별도 RNG를 씀.
func _roll_room_choices() -> void:
	var opts := _room_options_for_index(RunState.rooms_cleared)
	_shop_available = opts.shop
	_event_available = opts.event
	_story_available = opts.story


## idx번째 방(0부터 시작)에서 상점/특수 이벤트/스토리 이벤트가 노출될지를 결정적으로
## 계산한다. rooms_cleared 대신 임의의 idx를 받을 수 있어 아직 도달하지 않은 미래
## 방의 미리보기(MapStrip)에도 그대로 쓸 수 있다 — 실제로 그 방에 도달했을 때
## _roll_room_choices()가 계산하는 값과 완전히 동일한 공식이라 미리보기와 실제 결과가
## 어긋나지 않는다.
func _room_options_for_index(idx: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 104729 + 7
	return {
		"shop": rng.randf() < SHOP_CHANCE,
		"event": rng.randf() < EVENT_CHANCE,
		"story": rng.randf() < STORY_CHANCE,
	}


func _update_labels() -> void:
	gold_label.text = "보유 골드: %d" % RunState.gold
	if RunState.is_run_complete():
		rooms_cleared_label.text = "던전 클리어! (%d / %d 방 격파)" % [RunState.rooms_cleared, RunState.TOTAL_ROOMS]
		enter_combat_button.text = "새 런 시작"
		enter_shop_button.hide()
		enter_event_button.hide()
		enter_story_button.hide()
	else:
		rooms_cleared_label.text = "클리어한 방: %d / %d" % [RunState.rooms_cleared, RunState.TOTAL_ROOMS]
		enter_combat_button.text = "전투 방 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_shop_button.text = "상점 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_event_button.text = "특수 이벤트 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_story_button.text = "스토리 이벤트 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_shop_button.visible = _shop_available
		enter_event_button.visible = _event_available
		enter_story_button.visible = _story_available
	_layout_visible_buttons()
	_build_map_strip()


## MapStrip 안에 배경 연결선(ColorRect) + 노드를 담을 HBoxContainer를 한 번만 세팅한다.
func _setup_map_strip() -> void:
	_map_line = ColorRect.new()
	_map_line.color = Color(0.35, 0.35, 0.4, 0.6)
	_map_line.anchor_left = 0.0
	_map_line.anchor_right = 1.0
	_map_line.anchor_top = 0.5
	_map_line.anchor_bottom = 0.5
	_map_line.offset_top = -1.5
	_map_line.offset_bottom = 1.5
	_map_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_strip.add_child(_map_line)

	_map_hbox = HBoxContainer.new()
	_map_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_map_hbox.add_theme_constant_override("separation", 16)
	map_strip.add_child(_map_hbox)


## 런 전체(TOTAL_ROOMS개)를 한 줄로 그려서 "지나온 방 / 지금 방 / 앞으로 나올 방의
## 선택지"를 한눈에 보여준다 (INBOX.md "맵 전체를 봐야할 것 같음" 반영).
func _build_map_strip() -> void:
	for c in _map_hbox.get_children():
		c.queue_free()
	for idx in range(RunState.TOTAL_ROOMS):
		_map_hbox.add_child(_make_map_node(idx))


func _make_map_node(idx: int) -> Control:
	var is_cleared := idx < RunState.rooms_cleared
	var is_current := idx == RunState.rooms_cleared and not RunState.is_run_complete()

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 130)
	var style := StyleBoxFlat.new()
	if is_current:
		style.bg_color = Color(0.25, 0.22, 0.12, 0.95)
		style.border_color = Color(0.9, 0.75, 0.2)
		style.set_border_width_all(3)
	elif is_cleared:
		style.bg_color = Color(0.12, 0.16, 0.12, 0.85)
		style.border_color = Color(0.3, 0.45, 0.3)
		style.set_border_width_all(1)
	else:
		style.bg_color = Color(0.12, 0.12, 0.15, 0.85)
		style.border_color = Color(0.3, 0.3, 0.35)
		style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(1, 1, 1, 0.55 if is_cleared else 1.0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = ("%d번째 방 (완료)" % (idx + 1)) if is_cleared else ("%d번째 방" % (idx + 1))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4) if is_current else Color(0.8, 0.8, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	var opts := _room_options_for_index(idx)
	vbox.add_child(_make_type_chip("전투", Color(0.5, 0.2, 0.2)))
	if opts.shop:
		vbox.add_child(_make_type_chip("상점", Color(0.5, 0.42, 0.15)))
	if opts.event:
		vbox.add_child(_make_type_chip("특수 이벤트", Color(0.35, 0.22, 0.5)))
	if opts.story:
		vbox.add_child(_make_type_chip("스토리 이벤트", Color(0.18, 0.4, 0.4)))

	return panel


func _make_type_chip(text: String, color: Color) -> Control:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	return chip


## 상점/이벤트가 숨겨져도 버튼 사이에 빈 틈이 남지 않도록, 보이는 버튼만 순서대로
## 다시 세로 배치한다 (전투 방은 항상 첫 자리). "커스터마이징" 버튼은 방 선택지가
## 아니라 언제든 열 수 있는 별도 기능(STATUS.md 큐 0번 "어디서든 덱 열람 +
## 커스터마이징")이라 항상 보이는 버튼으로 취급하고 맨 마지막 자리에 둔다.
func _layout_visible_buttons() -> void:
	var visible_buttons: Array[Button] = [enter_combat_button]
	if enter_shop_button.visible:
		visible_buttons.append(enter_shop_button)
	if enter_event_button.visible:
		visible_buttons.append(enter_event_button)
	if enter_story_button.visible:
		visible_buttons.append(enter_story_button)
	visible_buttons.append(customize_button)

	var y := BUTTON_TOP_START
	for btn in visible_buttons:
		btn.offset_top = y
		btn.offset_bottom = y + BUTTON_HEIGHT
		y += BUTTON_SPACING


func _on_combat_button_pressed() -> void:
	if RunState.is_run_complete():
		RunState.reset_run()
		_roll_room_choices()
		_update_labels()
	else:
		get_tree().change_scene_to_file("res://code/scenes/combat_test.tscn")


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/shop.tscn")


func _on_event_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/event.tscn")


func _on_story_button_pressed() -> void:
	get_tree().change_scene_to_file("res://code/scenes/story_event.tscn")


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. 실제 전투 승리를 끝까지
## 거쳐야만 rooms_cleared가 늘어나는데, MapStrip의 "완료/현재/미래" 표시가 방이 실제로
## 진행됐을 때 제대로 갱신되는지 확인하려고 몇 방을 건너뛰어 본다.
func _debug_advance_rooms(count: int = 2) -> void:
	RunState.rooms_cleared = min(RunState.rooms_cleared + count, RunState.TOTAL_ROOMS)
	_roll_room_choices()
	_update_labels()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. CustomizePanel은
## dungeon_map의 자식 노드라 GAME_QA_CALL(현재 씬 루트에서만 호출 가능)이 직접 열 수
## 없으므로, 씬 루트(이 스크립트)에 얇은 래퍼를 둔다.
func _debug_open_customize() -> void:
	customize_panel.open()


## QA 전용 — 1단계(다이스 선택)를 거치지 않고 바로 2단계(면 선택) 화면을 열어
## 그 단계의 레이아웃(면 칩 나열)을 확인하기 위함 (combat_test.gd의
## _debug_open_face_picker와 같은 목적).
func _debug_open_customize_face() -> void:
	customize_panel.open()
	customize_panel._show_face_picker(RunState.player_attack_bag, 0)
