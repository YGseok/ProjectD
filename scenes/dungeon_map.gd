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
## 수평적 선택지를 넓힌다")을 반영해 "전투 방" 하나뿐이던 것을 "전투 방" / "상점" 두
## 선택지로 넓힘. 어느 쪽을 골라도 방 하나를 소비한 것으로 치고(rooms_cleared 증가)
## 다음 방으로 넘어간다 — 상점도 "방"이라는 슬롯을 쓰는 선택지로 취급.

@onready var rooms_cleared_label: Label = $RoomsClearedLabel
@onready var gold_label: Label = $GoldLabel
@onready var enter_combat_button: Button = $EnterCombatButton
@onready var enter_shop_button: Button = $EnterShopButton


func _ready() -> void:
	enter_combat_button.pressed.connect(_on_combat_button_pressed)
	enter_shop_button.pressed.connect(_on_shop_button_pressed)
	_update_labels()


func _update_labels() -> void:
	gold_label.text = "보유 골드: %d" % RunState.gold
	if RunState.is_run_complete():
		rooms_cleared_label.text = "던전 클리어! (%d / %d 방 격파)" % [RunState.rooms_cleared, RunState.TOTAL_ROOMS]
		enter_combat_button.text = "새 런 시작"
		enter_shop_button.hide()
	else:
		rooms_cleared_label.text = "클리어한 방: %d / %d" % [RunState.rooms_cleared, RunState.TOTAL_ROOMS]
		enter_combat_button.text = "전투 방 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_shop_button.text = "상점 입장 (%d번째 방)" % (RunState.rooms_cleared + 1)
		enter_shop_button.show()


func _on_combat_button_pressed() -> void:
	if RunState.is_run_complete():
		RunState.reset_run()
		_update_labels()
	else:
		get_tree().change_scene_to_file("res://scenes/combat_test.tscn")


func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
