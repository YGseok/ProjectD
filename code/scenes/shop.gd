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
	"uniform_faces": 25,
}

@onready var gold_label: Label = $GoldLabel
@onready var leave_button: Button = $LeaveButton
@onready var items_root: Node2D = $ItemsRoot
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var _row_ui: Array[Node] = []


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_pressed)
	customize_button.pressed.connect(customize_panel.open)
	_rebuild_items()


func _rebuild_items() -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()

	gold_label.text = "보유 골드: %d" % RunState.gold

	var card_width := 320.0
	var card_height := 240.0
	# 카드 실제 높이(240)와 별개로, 2행 그리드의 행 간격은 그보다 살짝 좁게 잡는다.
	# boost_weak_face/uniform_faces 카드는 이제 버튼 옆에 효과 미리보기(build_effect_preview)가
	# 붙어 자연 높이가 240을 넘는데(PanelContainer가 내용물 최소 높이에 맞춰 자동으로
	# 커짐), 기존처럼 row_step=card_height+20(=260)을 그대로 쓰면 2행 카드 하단이 화면
	# 하단의 "던전으로 돌아가기"/"커스터마이징" 버튼(y=650)과 거의 맞닿는다. 1행 카드는
	# 원래도 240보다 여유가 있으므로(자연 높이 ~213) row_step을 줄여도 1행과 2행이
	# 겹치지 않는다.
	var row_step := 235.0
	var card_x := [0.0, 360.0]
	for i in DiceItemPool.ITEMS.size():
		var item: Dictionary = DiceItemPool.ITEMS[i]
		var cost: int = ITEM_COSTS.get(item["kind"], 15)
		var afford := RunState.gold >= cost

		var built := ItemCardStyle.build_card(item, "%d 골드" % cost)
		var card: PanelContainer = built["card"]
		card.position = Vector2(card_x[i % 2], floor(i / 2.0) * row_step)
		card.size = Vector2(card_width, card_height)
		items_root.add_child(card)
		_row_ui.append(card)

		var button_row: VBoxContainer = built["button_row"]

		if item.get("kind", "") == "upgrade_die":
			var upgrade_btn := Button.new()
			upgrade_btn.text = "구매 (인벤토리로 획득)" if afford else "골드 부족"
			upgrade_btn.disabled = not afford
			upgrade_btn.custom_minimum_size = Vector2(0, 38)
			upgrade_btn.pressed.connect(_on_buy_upgrade_pressed.bind(item, cost))
			button_row.add_child(upgrade_btn)
			continue

		var atk_preview := ItemCardStyle.build_effect_preview(item, RunState.player_attack_bag)
		if atk_preview:
			button_row.add_child(atk_preview)
		var atk_applicable := DiceItemPool.is_applicable(item, RunState.player_attack_bag)
		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 구매" if (afford and atk_applicable) else ("골드 부족" if not afford else DiceItemPool.unavailable_reason(item))
		atk_btn.disabled = not (afford and atk_applicable)
		atk_btn.custom_minimum_size = Vector2(0, 38)
		atk_btn.pressed.connect(_on_buy_pressed.bind(item, cost, "attack"))
		button_row.add_child(atk_btn)

		var def_preview := ItemCardStyle.build_effect_preview(item, RunState.player_defense_bag)
		if def_preview:
			button_row.add_child(def_preview)
		var def_applicable := DiceItemPool.is_applicable(item, RunState.player_defense_bag)
		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 구매" if (afford and def_applicable) else ("골드 부족" if not afford else DiceItemPool.unavailable_reason(item))
		def_btn.disabled = not (afford and def_applicable)
		def_btn.custom_minimum_size = Vector2(0, 38)
		def_btn.pressed.connect(_on_buy_pressed.bind(item, cost, "defense"))
		button_row.add_child(def_btn)


func _on_buy_pressed(item: Dictionary, cost: int, target: String) -> void:
	if RunState.gold < cost:
		return
	RunState.gold -= cost
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	_rebuild_items()


## "다이스 승급" 아이템(kind=upgrade_die) 전용 구매 핸들러. attack/defense 대상 선택이
## 필요 없다 — 어느 다이스와 바꿀지는 인벤토리에 쌓인 뒤 커스터마이징에서 정한다.
func _on_buy_upgrade_pressed(item: Dictionary, cost: int) -> void:
	if RunState.gold < cost:
		return
	RunState.gold -= cost
	DiceItemPool.apply_upgrade_gain(item)
	_rebuild_items()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용 — 클릭을
## 흉내낼 수 없는 자동 QA로 구매 흐름이 실제로 골드를 깎고 다이스에 반영되는지 확인).
func _debug_buy_first_for_attack() -> void:
	var item: Dictionary = DiceItemPool.ITEMS[0]
	_on_buy_pressed(item, ITEM_COSTS.get(item["kind"], 15), "attack")


func _on_leave_pressed() -> void:
	RunState.rooms_cleared += 1
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. "다이스 승급 (-> D6)"
## 아이템을 구매해 화면에 "구매 (인벤토리로 획득)" 단일 버튼이 정상 표시되고, 실제로
## RunState.die_inventory에 쌓이는지 확인하기 위함(2026-09-09, INBOX.md 피드백 반영 —
## 예전에는 승급 대상이 없으면 버튼이 비활성화됐지만 이제 즉시 적용 대상이 없어
## 항상 구매 가능하다).
func _debug_buy_upgrade_item() -> void:
	RunState.gold = 999
	var item: Dictionary = DiceItemPool.ITEMS[1]  # "다이스 승급 (-> D6)"
	_on_buy_upgrade_pressed(item, ITEM_COSTS.get(item["kind"], 15))


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적).
func _debug_open_customize() -> void:
	customize_panel.open()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅. DiceBag.MAX_DICE 캡
## (2026-09-09)에 도달했을 때 "다이스 추가 (D4)" 카드의 두 버튼이 "주머니 가득 참
## (최대 N개)" 문구로 비활성화되는 것을 실제 화면에서 눈으로 확인하기 위함 —
## 정상 플레이로는 6개까지 다이스를 사려면 여러 방을 거쳐야 해서 우회함.
func _debug_show_maxed_attack_bag() -> void:
	RunState.gold = 999
	while not RunState.player_attack_bag.is_full():
		RunState.player_attack_bag.add_die(4)
	_rebuild_items()
