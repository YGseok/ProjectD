extends Node2D
## 던전 맵 허브 씬 (1차 버전).
##
## DESIGN.md 핵심 루프: "방 선택 -> 이벤트 발생 (전투/상점/선택지) -> 보상 -> 다음 방".
## 상점/선택지 이벤트는 아직 내용이 정해지지 않아(DESIGN.md "아직 정해지지 않은 것"),
## 지금은 전투 방 하나만 선택 가능한 최소 스켈레톤이다. combat_test.tscn을 그대로
## "전투 방"으로 재사용한다.

@onready var rooms_cleared_label: Label = $RoomsClearedLabel
@onready var enter_combat_button: Button = $EnterCombatButton


func _ready() -> void:
	enter_combat_button.pressed.connect(_on_enter_combat_pressed)
	_update_labels()


func _update_labels() -> void:
	rooms_cleared_label.text = "클리어한 방: %d" % RunState.rooms_cleared


func _on_enter_combat_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/combat_test.tscn")
