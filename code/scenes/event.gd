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
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var _offered: Array[Dictionary] = []
var _row_ui: Array[Node] = []
var _picked := false

## 던전 맵/스토리 이벤트와 같은 패턴(KeyboardShortcuts) — 카드 버튼들 + 커스터마이징
## 버튼을 화면에 나타나는 순서대로 담아 숫자 1~9 키로 누를 수 있게 한다(INBOX.md
## 2026-09-14). 아이템이 매번 다시 뽑히지 않는 한 카드 구성은 안 바뀌므로 dungeon_map처럼
## 매 프레임 갱신할 필요는 없고, _rebuild_items()가 호출될 때만 다시 만든다.
var _shortcut_buttons: Array[Button] = []


func _ready() -> void:
	_offered = EventItemPool.random_choices(2, RunState.player_attack_bag, RunState.player_defense_bag)
	customize_button.pressed.connect(customize_panel.open)
	_rebuild_items()


func _rebuild_items() -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()
	_shortcut_buttons.clear()

	var card_width := 320.0
	var card_height := 300.0
	var card_x := [0.0, 360.0]
	for i in _offered.size():
		var item: Dictionary = _offered[i]
		var built := ItemCardStyle.build_card(item)
		var card: PanelContainer = built["card"]
		card.position = Vector2(card_x[i], 0.0)
		card.size = Vector2(card_width, card_height)
		items_root.add_child(card)
		_row_ui.append(card)

		var button_row: VBoxContainer = built["button_row"]

		if item.get("kind", "") == "gain_pips":
			var pip_btn := Button.new()
			pip_btn.text = "눈금 획득"
			pip_btn.custom_minimum_size = Vector2(0, 38)
			pip_btn.pressed.connect(_on_pick_pips.bind(item))
			button_row.add_child(pip_btn)
			_shortcut_buttons.append(pip_btn)
			continue

		if item.get("kind", "") == "upgrade_die":
			var upgrade_btn := Button.new()
			upgrade_btn.text = "다이스 획득 (인벤토리)"
			upgrade_btn.custom_minimum_size = Vector2(0, 38)
			upgrade_btn.pressed.connect(_on_pick_upgrade.bind(item))
			button_row.add_child(upgrade_btn)
			_shortcut_buttons.append(upgrade_btn)
			continue

		var atk_preview := ItemCardStyle.build_effect_preview(item, RunState.player_attack_bag)
		if atk_preview:
			button_row.add_child(atk_preview)
		var atk_applicable := DiceItemPool.is_applicable(item, RunState.player_attack_bag)
		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용" if atk_applicable else DiceItemPool.unavailable_reason(item)
		atk_btn.disabled = not atk_applicable
		atk_btn.custom_minimum_size = Vector2(0, 38)
		atk_btn.pressed.connect(_on_pick_pressed.bind(item, "attack"))
		button_row.add_child(atk_btn)
		_shortcut_buttons.append(atk_btn)

		var def_preview := ItemCardStyle.build_effect_preview(item, RunState.player_defense_bag)
		if def_preview:
			button_row.add_child(def_preview)
		var def_applicable := DiceItemPool.is_applicable(item, RunState.player_defense_bag)
		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용" if def_applicable else DiceItemPool.unavailable_reason(item)
		def_btn.disabled = not def_applicable
		def_btn.custom_minimum_size = Vector2(0, 38)
		def_btn.pressed.connect(_on_pick_pressed.bind(item, "defense"))
		button_row.add_child(def_btn)
		_shortcut_buttons.append(def_btn)

	_shortcut_buttons.append(customize_button)
	KeyboardShortcuts.apply_hints(_shortcut_buttons)


## 숫자 키(1~9)로 지금 보이는 카드 버튼(+커스터마이징)을 순서대로 누른다. dungeon_map.gd와
## 같은 이유로 커스터마이징 패널이 열려있을 때는 뒤에 가려진 버튼이 함께 눌리지 않도록
## 무시한다.
func _unhandled_input(event: InputEvent) -> void:
	if customize_panel.visible:
		return
	var idx := KeyboardShortcuts.digit_index(event)
	if idx < 0:
		return
	# get_viewport()는 try_press() 이전에 미리 받아둬야 한다 — 아이템 픽 버튼처럼 눌렸을 때
	# change_scene_to_file()로 씬을 바꾸는 버튼이면, 이 노드가 try_press() 도중 트리에서
	# 빠져나가 그 뒤의 get_viewport()가 null을 반환해 set_input_as_handled() 호출이
	# 크래시한다(shop.gd에서 실제로 겪고 발견해 5개 화면 공통으로 수정, 2026-09-15).
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press(_shortcut_buttons, idx) and viewport != null:
		viewport.set_input_as_handled()


func _on_pick_pressed(item: Dictionary, target: String) -> void:
	if not _apply_pick(item, target):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## shop.gd의 이중 구매 방지(이터레이션 45)와 같은 이유로 필요한 가드다. shop은
## "골드 부족"으로 자연스럽게 재검증되지만, 이 방은 무료라 그런 재검증 수단이 없어서
## 별도 플래그가 필요하다 — change_scene_to_file()이 그 프레임 안에서 즉시 씬을 바꾸지
## 않으므로, 버튼 더블클릭 등으로 같은 프레임에 이 핸들러가 두 번 불리면 가드 없이는
## 아이템이 중복 적용되고 rooms_cleared가 2 증가해 방 하나를 건너뛸 수 있었다.
## 씬 전환과 분리해둔 이유: dice_test.gd 회귀 테스트가 실제 event.tscn을 인스턴스화해
## 이 함수를 직접 호출해 가드를 검증하는데, _on_pick_pressed를 그대로 호출하면
## change_scene_to_file()이 QA 중인 dice_test 씬 자체를 바꿔버려 스크린샷이 깨진다.
## 반환값(true=이번 호출이 실제로 적용됨)으로 테스트가 부작용 없이 결과를 검증할 수 있다.
func _apply_pick(item: Dictionary, target: String) -> bool:
	if _picked:
		return false
	_picked = true
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	RunState.rooms_cleared += 1
	return true


## gain_pips 아이템(공격/방어 어느 주머니에도 속하지 않고 RunState.pip_inventory에
## 바로 쌓임) 전용 픽 핸들러. _on_pick_pressed/_apply_pick과 대칭 구조 — attack/defense
## 대상 선택이 필요 없어서 별도 함수로 분리했다(같은 _picked 플래그를 공유해 이중 실행
## 가드도 그대로 재사용됨).
func _on_pick_pips(item: Dictionary) -> void:
	if not _apply_pips(item):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (_apply_pick과 동일한 이중 실행 방지 이유).
## pip_min..pip_max 개수만큼, 각각 1..6 범위의 무작위 값을 RunState.pip_inventory에
## 추가한다(전투 승리 보상 1개짜리 눈금과 값 범위는 별개 — "여러 개를 한 번에"가 이
## 아이템의 핵심이라 개수 쪽에 무게를 둠).
func _apply_pips(item: Dictionary) -> bool:
	if _picked:
		return false
	_picked = true
	var count := randi_range(item["pip_min"], item["pip_max"])
	for i in count:
		RunState.pip_inventory.append(randi_range(1, 6))
	RunState.rooms_cleared += 1
	return true


## upgrade_die 아이템(공격/방어 어느 주머니에도 즉시 속하지 않고 RunState.die_inventory에
## 바로 쌓임) 전용 픽 핸들러. _on_pick_pips/_apply_pips와 대칭 구조 — attack/defense
## 대상 선택이 필요 없어서 별도 함수로 분리했다(같은 _picked 플래그를 공유해 이중 실행
## 가드도 그대로 재사용됨).
func _on_pick_upgrade(item: Dictionary) -> void:
	if not _apply_upgrade(item):
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (_apply_pick/_apply_pips와 동일한 이유).
func _apply_upgrade(item: Dictionary) -> bool:
	if _picked:
		return false
	_picked = true
	DiceItemPool.apply_upgrade_gain(item)
	RunState.rooms_cleared += 1
	return true


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용).
func _debug_pick_first_for_attack() -> void:
	_on_pick_pressed(_offered[0], "attack")


## QA 전용 — 실제 숫자 키 입력이 _unhandled_input()을 거쳐 커스터마이징 버튼까지 눌리는
## 전체 경로를 확인하기 위함(dungeon_map.gd/story_event.gd의 _debug_press_shortcut_*와
## 같은 목적). 커스터마이징 버튼은 항상 _shortcut_buttons의 마지막 자리라 카드 구성(아이템
## 종류에 따라 카드당 버튼이 1~2개로 달라짐)과 무관하게 인덱스를 동적으로 계산한다.
func _debug_press_shortcut_customize() -> void:
	var idx := _shortcut_buttons.size() - 1
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_1 + idx
	_unhandled_input(key)


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적).
func _debug_open_customize() -> void:
	customize_panel.open()


## QA 전용: D20 아이템을 강제로 목록 맨 앞에 노출시킨다. 아이템은 무작위 2개만 뽑혀
## 보이므로, 화면에서 실제로 정상 표시되는지 확인하려면 무작위 뽑기에 의존하지 않고
## 직접 강제할 방법이 필요해서 추가함.
## kind+sides로 직접 찾는 이유: 예전에는 D20이 EventItemPool.ITEMS의 마지막 항목이라
## "마지막 항목"으로 가정해 찾았는데, 이후 "눈금 주머니 획득"(gain_pips)이 더 뒤에
## 추가되면서 그 가정이 깨져 이 훅이 실제로는 D20이 아니라 gain_pips를 보여주고 있었다
## (2026-09-15 발견 — 카드 이미지/텍스트 레이아웃 개편 중 이 훅으로 D20의 20칸짜리
## 미리보기가 카드 안에 안 겹치고 들어가는지 확인하려다가 실제로는 다른 아이템이
## 뜨는 것을 보고 알아챔).
func _debug_force_offer_d20() -> void:
	_offered = [_find_item_by_sides(20), EventItemPool.ITEMS[0]]
	_rebuild_items()


func _find_item_by_sides(sides: int) -> Dictionary:
	for it in EventItemPool.ITEMS:
		if it.get("kind", "") == "add_die" and it.get("sides", -1) == sides:
			return it
	return EventItemPool.ITEMS[0]


## QA 전용: D20 아이템을 공격 주머니에 적용했을 때 실제로 sides=20 다이스가 하나
## 추가되는지 콘솔로 검증한다 (_debug_force_offer_d20과 짝 — 화면 표시 확인과
## 별개로 apply() 로직 자체를 확인).
func _debug_verify_d20_pickup() -> void:
	var item: Dictionary = _find_item_by_sides(20)
	var bag := RunState.player_attack_bag
	var before_count := bag.dice.size()
	DiceItemPool.apply(item, bag)
	var after_count := bag.dice.size()
	var added_sides := bag.dice[after_count - 1].size() if after_count > before_count else -1
	print("[qa] d20 pickup: before=%d after=%d added_sides=%d" % [before_count, after_count, added_sides])


## QA 전용: 새로 추가한 "눈금 주머니 획득" 아이템(gain_pips)을 강제로 목록 맨 앞에
## 노출시킨다. _debug_force_offer_d20과 같은 이유 — 무작위 2개 중 하나로만 뽑히므로
## 화면에서 "획득" 버튼 하나짜리 카드가 정상 표시되는지 확인하려면 직접 강제해야 한다.
func _debug_force_offer_pips() -> void:
	var pip_item: Dictionary = {}
	for it in EventItemPool.ITEMS:
		if it["kind"] == "gain_pips":
			pip_item = it
			break
	_offered = [pip_item, EventItemPool.ITEMS[0]]
	_rebuild_items()


## QA 전용: "다이스 대승급 (-> D10)" 아이템(upgrade_die)을 강제로 목록 맨 앞에
## 노출시킨다. _debug_force_offer_pips와 같은 이유 — 화면에서 "다이스 획득 (인벤토리)"
## 단일 버튼 카드가 정상 표시되는지 확인하기 위함(2026-09-09, 즉시 적용 대신 인벤토리
## 획득으로 바뀐 뒤 새로 필요해진 QA 훅).
func _debug_force_offer_upgrade() -> void:
	var upgrade_item: Dictionary = {}
	for it in EventItemPool.ITEMS:
		if it["kind"] == "upgrade_die":
			upgrade_item = it
			break
	_offered = [upgrade_item, EventItemPool.ITEMS[0]]
	_rebuild_items()
