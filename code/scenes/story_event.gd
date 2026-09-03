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


func _on_choice_pressed(choice: Dictionary) -> void:
	var delta := _resolve_choice(choice)
	RunState.gold = max(0, RunState.gold + delta)
	choice_a_button.hide()
	choice_b_button.hide()
	if delta > 0:
		result_label.text = "골드 %d 획득! (보유 %d)" % [delta, RunState.gold]
	elif delta < 0:
		result_label.text = "골드 %d 잃었다... (보유 %d)" % [-delta, RunState.gold]
	else:
		result_label.text = "아무 일도 일어나지 않았다. (보유 %d)" % RunState.gold
	result_label.show()
	continue_button.show()


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
