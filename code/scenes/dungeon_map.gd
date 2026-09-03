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

var _shop_available := true
var _event_available := true
var _story_available := true


func _ready() -> void:
	enter_combat_button.pressed.connect(_on_combat_button_pressed)
	enter_shop_button.pressed.connect(_on_shop_button_pressed)
	enter_event_button.pressed.connect(_on_event_button_pressed)
	enter_story_button.pressed.connect(_on_story_button_pressed)
	_roll_room_choices()
	_update_labels()


## 현재 방(rooms_cleared) 기준으로 상점/특수 이벤트/스토리 이벤트 노출 여부를 결정한다.
## 전투 판정에 쓰이는 전역 randi()/randf()와 섞이지 않도록 별도 RNG를 씀.
func _roll_room_choices() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RunState.rooms_cleared * 104729 + 7
	_shop_available = rng.randf() < SHOP_CHANCE
	_event_available = rng.randf() < EVENT_CHANCE
	_story_available = rng.randf() < STORY_CHANCE


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


## 상점/이벤트가 숨겨져도 버튼 사이에 빈 틈이 남지 않도록, 보이는 버튼만 순서대로
## 다시 세로 배치한다 (전투 방은 항상 첫 자리).
func _layout_visible_buttons() -> void:
	var visible_buttons: Array[Button] = [enter_combat_button]
	if enter_shop_button.visible:
		visible_buttons.append(enter_shop_button)
	if enter_event_button.visible:
		visible_buttons.append(enter_event_button)
	if enter_story_button.visible:
		visible_buttons.append(enter_story_button)

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
