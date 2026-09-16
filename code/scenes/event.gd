extends Node2D
## 특수 이벤트 방 (INBOX.md [미니 기획 B] 2~3번, 2026-09-16).
##
## 예전에는 무작위 2개 중 하나를 무료로 골라 즉시 획득하는 방식이었는데(리스크 없음),
## 이제 선택지를 항상 2개로 통일한다 — "안전하게 넘어가기"(리스크 없음, 확정 C급 아이템)
## / "위험을 감수하기"(RunState.event_die_sides를 1회 굴려 DC와 비교, 성공하면 A/S급
## 무작위 1개, 실패하면 보상 없음). DC = min(5, 3 + room_index / 2) — DESIGN.md에
## 명시된 정수 나눗셈 공식 그대로(room_index는 RunState.rooms_cleared와 동일 기준).
##
## systems/event_item_pool.gd(EventItemPool)의 등급(grade) 필터로 안전/위험 풀을
## 나누고, apply()는 DiceItemPool.apply()를 그대로 재사용한다(item dict 형식이 같음).
## 아이템을 실제로 주머니에 넣거나 인벤토리에 담는 로직(_apply_pick/_apply_pips/
## _apply_upgrade, _on_pick_* 핸들러)은 예전 구현을 그대로 유지했다 — dice_test.gd의
## 기존 회귀 테스트가 이 함수들을 직접 호출해 이중 실행 가드를 검증하므로, 시그니처와
## 동작을 바꾸지 않아야 그 테스트들이 계속 유효하다.

@onready var items_root: Node2D = $ItemsRoot
@onready var roll_root: Node2D = $RollRoot
@onready var customize_button: Button = $CustomizeButton
@onready var customize_panel: CustomizePanel = $CustomizePanel
@onready var prompt_label: Label = $PromptLabel
@onready var safe_button: Button = $SafeButton
@onready var risky_button: Button = $RiskyButton
@onready var fail_label: Label = $FailLabel
@onready var continue_button: Button = $ContinueButton

## 안전/위험 중 하나를 이미 골랐는지(중복 클릭으로 두 선택지가 동시에 진행되는 것을
## 막음) — _picked(아래, 아이템 적용/실패 계속 단계의 이중 실행 가드)와는 별개 지점이라
## 별도 플래그가 필요하다.
var _choice_made := false
## 아이템 적용(_apply_pick/_apply_pips/_apply_upgrade) 또는 실패 후 "계속"의 이중 실행
## 방지 가드 — 예전 event.gd의 _picked와 동일한 이름/역할을 유지(테스트 호환).
var _picked := false

var _dc: int
var _row_ui: Array[Node] = []
var _shortcut_buttons: Array[Button] = []


func _ready() -> void:
	_dc = difficulty_for_room(RunState.rooms_cleared)
	prompt_label.text = "이상한 기운이 느껴지는 방이다. 안전하게 지나칠 것인가, 위험을 무릅쓸 것인가?"
	safe_button.text = "안전하게 넘어가기 (확정 C급 획득)"
	risky_button.text = "위험을 감수하기 (이벤트 주사위 D%d, %d 이상 성공)" % [RunState.event_die_sides, _dc]
	safe_button.pressed.connect(_on_safe_pressed)
	risky_button.pressed.connect(_on_risky_pressed)
	customize_button.pressed.connect(customize_panel.open)
	fail_label.hide()
	continue_button.hide()
	continue_button.pressed.connect(_on_continue_after_fail_pressed)
	_refresh_shortcuts([safe_button, risky_button, customize_button])


## DC 공식(DESIGN.md [미니 기획 B]-3): 방 0~1은 DC3, 2~3은 DC4, 4 이상은 DC5(상한).
## room_index는 RunState.rooms_cleared와 같은 기준(0부터 시작, 몇 번째 몬스터/방인지).
static func difficulty_for_room(room_index: int) -> int:
	return min(5, 3 + room_index / 2)


func _refresh_shortcuts(buttons: Array[Button]) -> void:
	_shortcut_buttons = buttons
	KeyboardShortcuts.apply_hints(_shortcut_buttons)


## dungeon_map.gd 등과 같은 이유(2026-09-15) — 씬을 바꾸는 버튼(아이템 획득/커스터마이징
## 없음이므로 여기선 해당 없지만 패턴 일관성을 위해 동일하게 get_viewport()를 try_press()
## 이전에 미리 받아둔다.
func _unhandled_input(event: InputEvent) -> void:
	if customize_panel.visible:
		return
	var idx := KeyboardShortcuts.digit_index(event)
	if idx < 0:
		return
	var viewport := get_viewport()
	if KeyboardShortcuts.try_press(_shortcut_buttons, idx) and viewport != null:
		viewport.set_input_as_handled()


func _on_safe_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(EventItemPool.random_safe_item())


func _on_risky_pressed() -> void:
	if _choice_made:
		return
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(randi_range(1, RunState.event_die_sides))


## roll을 인자로 받아 QA에서 결정적으로 강제할 수 있게 한다(아래 _debug_force_risky_*).
func _resolve_risky(roll: int) -> void:
	var success := roll >= _dc
	_show_roll_result(roll, success)
	if success:
		_show_item_offer(EventItemPool.random_risky_item())
	else:
		_show_fail()


## 로마 숫자 육각 칩(EventDieVisual) + 결과 문구를 roll_root 아래에 만든다. 화면당
## 한 번만 호출되므로(다시 굴리는 경로가 없음) 기존 자식을 지우는 처리는 필요 없다.
func _show_roll_result(roll: int, success: bool) -> void:
	var visual := EventDieVisual.new()
	visual.custom_minimum_size = Vector2(56, 56)
	visual.position = Vector2(0, 0)
	roll_root.add_child(visual)
	visual.value = roll

	var label := Label.new()
	label.position = Vector2(70, 14)
	label.text = "이벤트 주사위 결과: %s (%d) — DC %d 이상 필요 → %s" % [
		EventDieVisual._to_roman(roll), roll, _dc, "성공!" if success else "실패..."
	]
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.95, 0.6) if success else Color(0.9, 0.5, 0.45))
	roll_root.add_child(label)


func _show_fail() -> void:
	fail_label.text = "아쉽게도 손에 넣지 못했다... 이번 기회는 여기서 끝이다."
	fail_label.show()
	continue_button.show()
	_refresh_shortcuts([continue_button, customize_button])


func _on_continue_after_fail_pressed() -> void:
	if not _apply_fail():
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 실패 시에도 "방을 하나 소비했다"는 진행은 그대로 인정한다(DESIGN.md — "페널티는
## 이번 기회를 놓침 그 자체로 충분"). _apply_pick/_apply_pips/_apply_upgrade와 동일한
## _picked 가드를 공유해 더블클릭으로 방이 두 번 소비되지 않게 한다.
func _apply_fail() -> bool:
	if _picked:
		return false
	_picked = true
	RunState.rooms_cleared += 1
	return true


## 안전/위험 성공 양쪽이 공유하는 단일 아이템 카드 표시. 예전 _rebuild_items()가 2개
## 아이템을 나란히 보여주던 것을 1개짜리로 단순화했을 뿐, 카드 구성/버튼 배선 로직
## 자체는 그대로다.
func _show_item_offer(item: Dictionary) -> void:
	for node in _row_ui:
		node.queue_free()
	_row_ui.clear()

	var built := ItemCardStyle.build_card(item)
	var card: PanelContainer = built["card"]
	card.position = Vector2(0.0, 0.0)
	card.size = Vector2(320.0, 300.0)
	items_root.add_child(card)
	_row_ui.append(card)

	var button_row: VBoxContainer = built["button_row"]
	var offer_buttons: Array[Button] = []

	if item.get("kind", "") == "gain_pips":
		var pip_btn := Button.new()
		pip_btn.text = "눈금 획득"
		pip_btn.custom_minimum_size = Vector2(0, 38)
		pip_btn.pressed.connect(_on_pick_pips.bind(item))
		button_row.add_child(pip_btn)
		offer_buttons.append(pip_btn)
	elif item.get("kind", "") == "upgrade_die":
		var upgrade_btn := Button.new()
		upgrade_btn.text = "다이스 획득 (인벤토리)"
		upgrade_btn.custom_minimum_size = Vector2(0, 38)
		upgrade_btn.pressed.connect(_on_pick_upgrade.bind(item))
		button_row.add_child(upgrade_btn)
		offer_buttons.append(upgrade_btn)
	else:
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
		offer_buttons.append(atk_btn)

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
		offer_buttons.append(def_btn)

	offer_buttons.append(customize_button)
	_refresh_shortcuts(offer_buttons)


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


func _find_item_by_sides(sides: int) -> Dictionary:
	for it in EventItemPool.ITEMS:
		if it.get("kind", "") == "add_die" and it.get("sides", -1) == sides:
			return it
	return EventItemPool.ITEMS[0]


func _find_item_by_kind(kind: String) -> Dictionary:
	for it in EventItemPool.ITEMS:
		if it.get("kind", "") == kind:
			return it
	return EventItemPool.ITEMS[0]


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 안전
## 선택지를 눌러 확정 C급 아이템(지금은 gain_pips 하나뿐) 카드까지 화면에 나오는지
## 확인한다.
func _debug_pick_safe() -> void:
	_on_safe_pressed()


## QA 전용: 실제 randi_range() 대신 항상 최댓값(event_die_sides)을 굴린 것으로 강제해
## "위험을 감수하기" 성공 경로(A/S급 카드 표시까지)를 결정적으로 재현한다. DC가 아무리
## 커져도(최대 5) 이벤트 다이스 최댓값은 항상 DC 이상이므로 반드시 성공한다.
func _debug_force_risky_success() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(RunState.event_die_sides)


## QA 전용: 항상 최솟값(1)을 굴린 것으로 강제해 실패 경로("아쉽게도..." + 계속 버튼)를
## 결정적으로 재현한다. DC는 항상 3 이상이므로 1은 반드시 실패한다.
func _debug_force_risky_failure() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_resolve_risky(1)


## QA 전용: D20 아이템(위험 성공 풀의 S급)이 카드에 안 겹치고 표시되는지 확인하기 위해
## 안전/위험 선택 없이 곧바로 카드를 강제로 띄운다.
func _debug_force_show_d20() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_sides(20))


## QA 전용: "눈금 주머니 획득"(gain_pips, 안전 선택지의 유일한 C급) 카드가 정상
## 표시되는지 확인.
func _debug_force_show_pips() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_kind("gain_pips"))


## QA 전용: "다이스 대승급 (-> D10)"(upgrade_die, 위험 성공 풀의 A급) 카드가 정상
## 표시되는지 확인.
func _debug_force_show_upgrade() -> void:
	_choice_made = true
	safe_button.hide()
	risky_button.hide()
	_show_item_offer(_find_item_by_kind("upgrade_die"))


## QA 전용: D20 아이템을 공격 주머니에 적용했을 때 실제로 sides=20 다이스가 하나
## 추가되는지 콘솔로 검증한다 (apply() 로직 자체를 확인, 화면 표시와는 별개).
func _debug_verify_d20_pickup() -> void:
	var item: Dictionary = _find_item_by_sides(20)
	var bag := RunState.player_attack_bag
	var before_count := bag.dice.size()
	DiceItemPool.apply(item, bag)
	var after_count := bag.dice.size()
	var added_sides := bag.dice[after_count - 1].size() if after_count > before_count else -1
	print("[qa] d20 pickup: before=%d after=%d added_sides=%d" % [before_count, after_count, added_sides])


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
