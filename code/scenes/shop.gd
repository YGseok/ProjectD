extends Node2D
## 상점 방. INBOX.md 피드백("승리하면 골드를 주며, 상점 이벤트에서 사용할 수 있다")을
## 반영한 최소 버전.
##
## 새 아이템을 따로 만들지 않고 기존 systems/dice_item_pool.gd(DiceItemPool)의 아이템
## 3종을 그대로 재사용해서, 승리 보상(무료)과 상점(골드 소모)이 같은 아이템 풀을 공유하게
## 했다. 가격(ITEM_COSTS)은 잠정값 — 실제로 플레이해보고 비싼지/싼지는 사람 피드백 필요.
##
## 상점도 "방"이므로 나갈 때 RunState.rooms_cleared를 1 증가시킨다 (dungeon_map.gd 참고
## — 전투든 상점이든 방 하나를 소비하고 다음 방으로 넘어가는 구조).

const ITEM_COSTS := {
	"add_die": 15,
	"upgrade_die": 20,
	"boost_weak_face": 10,
}

@onready var gold_label: Label = $GoldLabel
@onready var leave_button: Button = $LeaveButton
@onready var items_root: Node2D = $ItemsRoot

var _row_ui: Array[Node] = []


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)
	_rebuild_items()


func _rebuild_items() -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()

	gold_label.text = "보유 골드: %d" % RunState.gold

	var y := 0.0
	for item in DiceItemPool.ITEMS:
		var cost: int = ITEM_COSTS.get(item["kind"], 15)
		var afford := RunState.gold >= cost

		var name_label := Label.new()
		name_label.text = "%s (%d 골드)\n%s" % [item["name"], cost, item["description"]]
		name_label.position = Vector2(0, y)
		name_label.size = Vector2(680, 50)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		items_root.add_child(name_label)
		_row_ui.append(name_label)

		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 구매" if afford else "골드 부족"
		atk_btn.disabled = not afford
		atk_btn.position = Vector2(0, y + 55)
		atk_btn.size = Vector2(220, 40)
		atk_btn.pressed.connect(_on_buy_pressed.bind(item, cost, "attack"))
		items_root.add_child(atk_btn)
		_row_ui.append(atk_btn)

		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 구매" if afford else "골드 부족"
		def_btn.disabled = not afford
		def_btn.position = Vector2(240, y + 55)
		def_btn.size = Vector2(220, 40)
		def_btn.pressed.connect(_on_buy_pressed.bind(item, cost, "defense"))
		items_root.add_child(def_btn)
		_row_ui.append(def_btn)

		y += 130.0


func _on_buy_pressed(item: Dictionary, cost: int, target: String) -> void:
	if RunState.gold < cost:
		return
	RunState.gold -= cost
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	_rebuild_items()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용 — 클릭을
## 흉내낼 수 없는 자동 QA로 구매 흐름이 실제로 골드를 깎고 다이스에 반영되는지 확인).
func _debug_buy_first_for_attack() -> void:
	var item: Dictionary = DiceItemPool.ITEMS[0]
	_on_buy_pressed(item, ITEM_COSTS.get(item["kind"], 15), "attack")


func _on_leave_pressed() -> void:
	RunState.rooms_cleared += 1
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")
