extends Node2D
## 특수 이벤트 방 (INBOX.md: "특수한 이벤트에서는 주사위를 늘리는 이벤트를 제공한다.
## 다면체 주사위가 나올 수 있다").
##
## 상점(shop.gd)과 달리 골드를 쓰지 않는다 — 무작위로 제시된 2개 중 하나를 무료로 골라
## 공격/방어 주머니 중 원하는 쪽에 적용하면 그 자리에서 방을 소비하고 던전 맵으로
## 돌아간다 (전투 승리 보상 화면과 비슷한 "2개 중 1개 선택" 형식을 재사용).
##
## systems/event_item_pool.gd(EventItemPool)의 아이템을 사용하며, apply()는
## DiceItemPool.apply()를 그대로 재사용한다 (item dict 형식이 같음).

@onready var items_root: Node2D = $ItemsRoot

var _offered: Array[Dictionary] = []
var _row_ui: Array[Node] = []


func _ready() -> void:
	_offered = EventItemPool.random_choices(2)
	_rebuild_items()


func _rebuild_items() -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()

	var y := 0.0
	for item in _offered:
		var name_label := Label.new()
		name_label.text = "%s\n%s" % [item["name"], item["description"]]
		name_label.position = Vector2(0, y)
		name_label.size = Vector2(680, 50)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		items_root.add_child(name_label)
		_row_ui.append(name_label)

		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용"
		atk_btn.position = Vector2(0, y + 55)
		atk_btn.size = Vector2(220, 40)
		atk_btn.pressed.connect(_on_pick_pressed.bind(item, "attack"))
		items_root.add_child(atk_btn)
		_row_ui.append(atk_btn)

		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용"
		def_btn.position = Vector2(240, y + 55)
		def_btn.size = Vector2(220, 40)
		def_btn.pressed.connect(_on_pick_pressed.bind(item, "defense"))
		items_root.add_child(def_btn)
		_row_ui.append(def_btn)

		y += 130.0


func _on_pick_pressed(item: Dictionary, target: String) -> void:
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	RunState.rooms_cleared += 1
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용).
func _debug_pick_first_for_attack() -> void:
	_on_pick_pressed(_offered[0], "attack")
