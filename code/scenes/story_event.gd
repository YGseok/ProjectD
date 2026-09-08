extends Node2D
## 스토리 이벤트 방 — 다이스와 무관한 순수 텍스트 선택지 (STATUS.md 큐 1번).
##
## systems/story_event_pool.gd(StoryEventPool)에서 시나리오 하나를 뽑아 두 선택지를
## 보여주고, 고른 결과(골드 증감)를 즉시 반영한 뒤 "계속" 버튼으로 던전 맵에 돌아간다.
## 상점/특수 이벤트와 달리 다이스 주머니는 전혀 건드리지 않는다.

@onready var title_label: Label = $Title
@onready var desc_label: Label = $Description
@onready var choice_a_button: Button = $ChoiceAButton
@onready var choice_b_button: Button = $ChoiceBButton
@onready var result_label: Label = $ResultLabel
@onready var continue_button: Button = $ContinueButton
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var _scenario: Dictionary


func _ready() -> void:
	_scenario = StoryEventPool.random_scenario()
	title_label.text = _scenario["title"]
	desc_label.text = _scenario["description"]
	choice_a_button.text = _scenario["choice_a"]["label"]
	choice_b_button.text = _scenario["choice_b"]["label"]
	choice_a_button.pressed.connect(_on_choice_pressed.bind(_scenario["choice_a"]))
	choice_b_button.pressed.connect(_on_choice_pressed.bind(_scenario["choice_b"]))
	result_label.hide()
	continue_button.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	customize_button.pressed.connect(customize_panel.open)


func _on_choice_pressed(choice: Dictionary) -> void:
	var delta := _resolve_choice(choice)
	var actual_delta := _apply_gold_delta(delta)
	choice_a_button.hide()
	choice_b_button.hide()
	if actual_delta > 0:
		result_label.text = "골드 %d 획득! (보유 %d)" % [actual_delta, RunState.gold]
	elif actual_delta < 0:
		result_label.text = "골드 %d 잃었다... (보유 %d)" % [-actual_delta, RunState.gold]
	else:
		result_label.text = "아무 일도 일어나지 않았다. (보유 %d)" % RunState.gold
	result_label.show()
	continue_button.show()


## RunState.gold에 delta를 적용하고 실제로 변한 양(actual_delta)을 반환한다.
## 손실(delta<0)이 보유 골드보다 크면 0에서 멈추므로, 표시 문구는 요청한 delta가
## 아니라 이 반환값을 써야 한다 — 안 그러면 "10골드 잃었다"라고 뜨는데 실제로는
## 3골드밖에 없어서 3만 잃고 0이 되는 식으로 문구와 결과가 어긋난다(2026-09-09 (26)
## 버그 수정). @onready 노드를 건드리지 않는 순수 로직이라 씬에 add_child하지 않고도
## 테스트 가능하다 (code/scenes/dice_test.gd 참고).
func _apply_gold_delta(delta: int) -> int:
	var gold_before := RunState.gold
	RunState.gold = max(0, RunState.gold + delta)
	return RunState.gold - gold_before


func _resolve_choice(choice: Dictionary) -> int:
	match choice["kind"]:
		"delta":
			return choice["amount"]
		"gamble":
			if randf() < choice["chance"]:
				return choice["win"]
			else:
				return -choice["lose"]
		_:
			return 0


func _on_continue_pressed() -> void:
	RunState.rooms_cleared += 1
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용).
func _debug_pick_choice_a() -> void:
	_on_choice_pressed(_scenario["choice_a"])


## QA 전용: 보유 골드(3)보다 손실 폭(10)이 큰 상황을 강제로 만들어, 결과 문구가
## 요청한 delta가 아니라 실제로 깎인 양(actual_delta)을 보여주는지 확인한다
## ("떠돌이 상인" 시나리오, choice_a가 고정 delta -10).
func _debug_force_low_gold_loss() -> void:
	RunState.gold = 3
	var scenario: Dictionary
	for s in StoryEventPool.SCENARIOS:
		if s["title"] == "떠돌이 상인":
			scenario = s
			break
	_scenario = scenario
	title_label.text = _scenario["title"]
	desc_label.text = _scenario["description"]
	_on_choice_pressed(_scenario["choice_a"])


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적).
func _debug_open_customize() -> void:
	customize_panel.open()
