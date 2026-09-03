extends Node2D
## 전투 씬 (플레이어 vs 몬스터).
## 플레이어 HP는 DESIGN.md 확정 그대로 하드코딩(20)이며 매 전투 시작 시 풀피로
## 초기화된다. 공격/방어 다이스 주머니(RunState.player_attack_bag/player_defense_bag)는
## 초기값은 DESIGN.md 확정 수치(D4x3)지만, 승리 보상으로 얻는 다이스 개조 아이템에 따라
## 런이 진행되는 동안 계속 바뀔 수 있다 (_show_reward_ui() 참고).
## 몬스터는 DESIGN.md에 1번째 방(공격 D4x2/방어 D4x1·HP10)만 확정되어 있고, 그 이후
## 방의 몬스터 구성은 아직 미정이라 RunState.rooms_cleared를 기반으로 잠정적인 난이도
## 스케일링(_monster_config_for_room())을 적용한다 (아래 "몬스터 스케일링" 참고).
##
## 판정은 기존 systems/dice_bag.gd(DiceBag), systems/combat_math.gd(CombatMath)를
## 그대로 재사용한다. 물리적으로 굴러가는 dice/die_d4.tscn(Die)은 "손맛" 연출용이며,
## 실제 합계는 DiceBag.roll()의 RNG 결과를 쓴다 (물리 다이스의 착지 면을 읽어 판정하는
## 기능은 아직 없음 — 알려진 이슈로 STATUS.md에 남김). 다만 다이스 "모양"(면 개수)은
## 각 다이스의 실제 face 배열 길이(bag.dice[i].size())에 맞춰 스폰하므로, 개조 아이템으로
## D6/D8 등으로 승급/추가된 다이스는 굴러갈 때도 그 모양으로 보인다.
##
## 교환 결과가 나오면 다이스별 개별 값(DiceBag.roll_detailed())을 면 모양(삼각/사각/
## 오각) 칩(ShapeDieChip)으로 화면에 표시한다 (INBOX.md 2026-09-03: "어떤 주사위에서
## 어떤 값이 나왔는지 이미지로 보이면 좋겠다"). 다만 이 칩도 여전히 RNG 결과를 보여줄
## 뿐, 물리적으로 굴러가는 다이스가 실제로 그 면으로 착지한 것을 읽어오는 것은 아니다.
##
## 다이스가 완전히 멈췄는지 실제로 감지한다 (linear/angular velocity가 임계값 밑으로
## SETTLE_MIN_FRAMES 프레임 연속 유지되면 정지로 판단). **다이스별로 독립적으로
## 판정한다** — 전체 다이스를 하나의 공용 카운터로 묶으면, 다이스 개수가 많을 때
## 서로 맞닿은 접촉 잔진동으로 어느 한 다이스라도 순간적으로 임계값을 넘기면 전체
## 카운터가 리셋되어 사실상 절대 정지 판정을 못 받는 문제가 있었다 (STATUS.md 알려진
## 이슈: 14개 이상에서 항상 SETTLE_MAX_WAIT로 강제 종료). 다이스마다 자기 카운터가
## SETTLE_MIN_FRAMES에 도달하면 그 다이스는 이후 다시 흔들려도 재검사하지 않으므로,
## 다이스 개수가 늘어도 "다른 다이스의 잔진동 때문에 이미 멈춘 다이스까지 계속
## 기다려야 하는" 상황이 없다. 물리 이상 등으로 끝내 멈추지 않는 경우를 대비해
## SETTLE_MAX_WAIT 초과 시 강제로 진행한다 (안전장치).

const DieScene := preload("res://code/dice/die_d4.tscn")

## 다이스 면 개수(sides)에 따른 잠정 재질 배정. 아직 재질을 직접 고르는 획득 시스템이
## 없어서 "개조로 다이스가 커질수록 더 고급 재질처럼 보인다"는 감으로 매핑함(사람
## 피드백 필요, die_d4.gd 클래스 주석 참고). D4/D6은 시작 재질(plastic) 그대로 둔다.
const MATERIAL_WOOD := preload("res://resources/materials/wood.tres")
const MATERIAL_GLASS := preload("res://resources/materials/glass.tres")
const MATERIAL_METAL := preload("res://resources/materials/metal.tres")

static func _material_for_sides(sides: int) -> DiceMaterial:
	match sides:
		8:
			return MATERIAL_WOOD
		10:
			return MATERIAL_GLASS
		12, 20:
			return MATERIAL_METAL
		_:
			return null # null이면 die_d4.tscn 기본값(plastic)을 그대로 씀

const SETTLE_LIN_THRESHOLD := 0.08
const SETTLE_ANG_THRESHOLD := 0.5
const SETTLE_MIN_FRAMES := 10
const SETTLE_MAX_WAIT := 4.0
const EXCHANGE_PAUSE_TIME := 0.8
const MAX_LOG_LINES := 6

## 다이스 개수가 아이템(다이스 추가/승급)으로 늘어나도 바닥 벽(x ±2.45 부근) 밖으로
## 스폰되지 않도록, 한 줄에 최대 이만큼만 놓고 그 이상은 z축으로 다음 줄에 놓는다
## (알려진 이슈: 큐 2 "다이스 개수가 늘어나면 재검증 필요" 반영).
const DICE_SPAWN_PER_ROW := 4
const DICE_SPAWN_COL_SPACING := 0.45
const DICE_SPAWN_ROW_SPACING := 0.5

@onready var player_hp_label: Label = $PlayerHPLabel
@onready var monster_hp_label: Label = $MonsterHPLabel
@onready var turn_label: Label = $TurnLabel
@onready var log_label: Label = $LogLabel
@onready var dice_root: Node3D = $DiceViewportContainer/DiceViewport/DiceRoot
@onready var next_button: Button = $NextButton
@onready var player_portrait: CharacterPortraitPlaceholder = $PlayerPortrait
@onready var monster_portrait: MonsterPortraitPlaceholder = $MonsterPortrait
@onready var deck_toggle_button: Button = $DeckToggleButton
@onready var deck_panel: DeckPanel = $DeckPanel
@onready var customize_toggle_button: Button = $CustomizeToggleButton
@onready var customize_panel: CustomizePanel = $CustomizePanel

var player_hp := 20
const PLAYER_MAX_HP := 20

var monster_hp: int
var monster_max_hp: int
var monster_attack_bag: DiceBag
var monster_defense_bag: DiceBag
var monster_name := "몬스터"
var monster_color := Color(1, 1, 1, 0)

var battle_over := false
var player_won := false
var _log_lines: Array[String] = []
var _reward_ui: Array[Node] = []
var _reward_items: Array[Dictionary] = []

## 이번 교환에서 어떤 다이스가 어떤 값을 냈는지 보여주는 칩(ShapeDieChip). 매 교환마다
## 지우고 새로 그린다 (INBOX.md 2026-09-03: "전투 시 어떤 주사위에서 어떤 값이
## 나왔는지 이미지로 보이면 좋겠다").
var _exchange_chip_nodes: Array[Node] = []
const EXCHANGE_CHIP_SIZE := 34.0
const EXCHANGE_CHIP_GAP := 6.0
const EXCHANGE_CHIP_Y := 505.0

## 커스터마이징(눈금 교환)은 이제 code/scenes/customize_panel.gd(CustomizePanel)
## 하나로 통합됨 — 승리 보상 화면의 "커스터마이징" 버튼도 이 화면 전용 로직 대신 그
## 공용 오버레이를 그대로 연다 (_open_customize_from_reward 참고). INBOX.md
## 피드백(2026-09-03) "인벤토리 창에 눈금이 쌓이고, 해당 눈금과 주사위 눈금이
## 교환되는 형태"를 반영한 상호작용 모델 변경으로, 기존에 이 파일에 있던 자체
## 다이스/면/값 선택 체인(자유 입력 방식)은 제거함.

## 승리 시 골드 보상. INBOX.md 피드백 "승리하면 골드를 주며, 상점 이벤트에서 사용할 수
## 있다"를 반영. 방이 진행될수록 조금씩 더 주는 잠정값 (밸런스는 사람 피드백 필요).
const GOLD_REWARD_BASE := 8
const GOLD_REWARD_PER_ROOM := 2

## 승리 시 커스터마이징용 "눈금" 보상. 값은 PIP_REWARD_MIN..(PIP_REWARD_MAX_BASE +
## rooms_cleared * PIP_REWARD_MAX_PER_ROOM) 범위에서 무작위 1개 — 방이 진행될수록
## 더 큰 눈금이 나올 여지가 커지는 잠정값(밸런스는 사람 피드백 필요).
const PIP_REWARD_MIN := 1
const PIP_REWARD_MAX_BASE := 4
const PIP_REWARD_MAX_PER_ROOM := 1

## 몬스터별 이름/다이스 색 (시각 구분용, 능력치와는 무관). room_index를 이 배열 길이로
## 나눈 나머지로 순환시키고, 배열을 다 돌면 이름 앞에 "강화"를 붙여 재사용한다
## (DESIGN.md에는 몬스터별 모양/색 자체가 아직 미정이라 잠정 목록).
const MONSTER_PROFILES := [
	{"name": "슬라임", "color": Color(0.35, 0.85, 0.4)},
	{"name": "고블린", "color": Color(0.75, 0.55, 0.25)},
	{"name": "해골 전사", "color": Color(0.85, 0.85, 0.8)},
	{"name": "오크", "color": Color(0.3, 0.55, 0.3)},
	{"name": "다크 나이트", "color": Color(0.55, 0.25, 0.75)},
]


## 잠정 난이도 스케일링 (DESIGN.md 미확정 — 1번째 방만 확정 수치 그대로 유지).
## room_index: 0부터 시작 (RunState.rooms_cleared와 동일한 기준, 즉 몇 번째 몬스터인지).
## room_index=0 -> 공격 2D4 / 방어 1D4 / HP10 (DESIGN.md 확정값과 동일).
func _monster_config_for_room(room_index: int) -> Dictionary:
	var profile: Dictionary = MONSTER_PROFILES[room_index % MONSTER_PROFILES.size()]
	var cycle := int(room_index / float(MONSTER_PROFILES.size()))
	var name_text: String = profile["name"]
	if cycle > 0:
		name_text = "강화 ".repeat(cycle) + name_text
	return {
		"attack_count": 2 + int(room_index / 2.0),
		"defense_count": 1 + int(room_index / 3.0),
		"max_hp": 10 + room_index * 3,
		"name": name_text,
		"color": profile["color"],
	}


func _ready() -> void:
	var config := _monster_config_for_room(RunState.rooms_cleared)
	monster_attack_bag = DiceBag.new(4, config["attack_count"])
	monster_defense_bag = DiceBag.new(4, config["defense_count"])
	monster_max_hp = config["max_hp"]
	monster_hp = monster_max_hp
	monster_name = config["name"]
	monster_color = config["color"]
	monster_portrait.set_body_color(monster_color if monster_color.a > 0 else Color(0.5, 0.5, 0.5))

	next_button.pressed.connect(_on_next_button_pressed)
	deck_toggle_button.pressed.connect(_on_deck_toggle_pressed)
	customize_toggle_button.pressed.connect(customize_panel.open)
	customize_panel.closed.connect(_on_customize_panel_closed)
	_update_labels()
	_run_battle()


## INBOX.md 피드백(2026-09-03) "내 공격 덱과 방어 덱이 ... 항상 떠있으면 좋겠다
## (전투 중에도)"의 "전투 중에도" 부분. combat_test는 다이스 뷰포트/초상화/로그로
## 화면이 이미 꽉 차 있어 dungeon_map 등처럼 상시 표시 패널을 놓을 자리가 없어서,
## 대신 버튼으로 여닫는 오버레이로 구현한다 (STATUS.md 큐 0번 "접이식/토글 버튼"
## 대안 채택).
func _on_deck_toggle_pressed() -> void:
	deck_panel.visible = not deck_panel.visible
	deck_toggle_button.text = "덱 닫기" if deck_panel.visible else "덱 보기"


func _run_battle() -> void:
	while not battle_over:
		await _do_exchange(true)
		if battle_over:
			break
		await _do_exchange(false)


## is_player_attacking == true  -> 내 공격턴 (플레이어 공격 주머니 vs 몬스터 방어 주머니)
## is_player_attacking == false -> 몬스터 공격턴 (몬스터 공격 주머니 vs 플레이어 방어 주머니)
func _do_exchange(is_player_attacking: bool) -> void:
	var atk_bag: DiceBag = RunState.player_attack_bag if is_player_attacking else monster_attack_bag
	var def_bag: DiceBag = monster_defense_bag if is_player_attacking else RunState.player_defense_bag

	turn_label.text = "내 공격턴" if is_player_attacking else "몬스터 공격턴 (내 방어턴)"

	var default_color := Color(1, 1, 1, 0)
	var atk_color := monster_color if not is_player_attacking else default_color
	var def_color := monster_color if is_player_attacking else default_color

	_clear_dice()
	_spawn_dice(atk_bag, -1.4, atk_color)
	_spawn_dice(def_bag, 1.4, def_color)

	await _wait_for_dice_to_settle()

	var atk_values := atk_bag.roll_detailed()
	var def_values := def_bag.roll_detailed()
	var atk_total := 0
	for v in atk_values:
		atk_total += v
	var def_total := 0
	for v in def_values:
		def_total += v
	var dmg := CombatMath.calculate_damage(atk_total, def_total)

	_show_exchange_dice_chips(atk_bag, atk_values, def_bag, def_values, atk_color, def_color)

	if is_player_attacking:
		monster_hp = max(0, monster_hp - dmg)
		_append_log("플레이어 공격 %d vs 몬스터 방어 %d -> 데미지 %d (몬스터 HP %d)" % [atk_total, def_total, dmg, monster_hp])
		player_portrait.set_expression("happy")
		monster_portrait.set_expression("hurt" if dmg > 0 else "neutral")
	else:
		player_hp = max(0, player_hp - dmg)
		_append_log("몬스터 공격 %d vs 플레이어 방어 %d -> 데미지 %d (플레이어 HP %d)" % [atk_total, def_total, dmg, player_hp])
		monster_portrait.set_expression("happy")
		player_portrait.set_expression("hurt" if dmg > 0 else "neutral")

	_update_labels()

	if monster_hp <= 0:
		battle_over = true
		player_won = true
		turn_label.text = "승리! (몬스터 처치)"
		var gold_gain := GOLD_REWARD_BASE + RunState.rooms_cleared * GOLD_REWARD_PER_ROOM
		RunState.gold += gold_gain
		_append_log("골드 획득: +%d (보유 %d)" % [gold_gain, RunState.gold])
		var pip_max := PIP_REWARD_MAX_BASE + RunState.rooms_cleared * PIP_REWARD_MAX_PER_ROOM
		var pip_gain := randi_range(PIP_REWARD_MIN, pip_max)
		RunState.pip_inventory.append(pip_gain)
		_append_log("눈금 획득: [%d] (커스터마이징에서 다이스 면과 교환 가능)" % pip_gain)
		player_portrait.set_expression("happy")
		monster_portrait.set_expression("sad")
	elif player_hp <= 0:
		battle_over = true
		player_won = false
		turn_label.text = "패배... (플레이어 사망)"
		player_portrait.set_expression("angry" if randi() % 2 == 0 else "sad")
		monster_portrait.set_expression("happy")

	await get_tree().create_timer(EXCHANGE_PAUSE_TIME).timeout

	if battle_over:
		if player_won:
			next_button.text = "던전으로 돌아가기"
			_show_reward_ui()
		else:
			next_button.text = "처음부터 다시"
			next_button.show()


## 씬에 있는 모든 다이스가 정지했다고 판단될 때까지 기다린다.
## 다이스마다 독립적인 "연속 정지 프레임" 카운터를 두고, 한 번 SETTLE_MIN_FRAMES에
## 도달한 다이스는 이후 다시 검사하지 않는다 (위 클래스 주석 참고).
func _wait_for_dice_to_settle() -> void:
	var quiet_frames: Dictionary = {}
	for child in dice_root.get_children():
		if child is RigidBody3D:
			quiet_frames[child] = 0

	var elapsed := 0.0
	while true:
		await get_tree().physics_frame
		# QA 하네스가 캡처 직후 get_tree().quit()을 호출하면 이 await가 재개되는
		# 시점에는 이미 dice_root와 그 자식들이 해제된 상태일 수 있다 (셧다운 중
		# 프리즈된 인스턴스를 타입 있는 for 루프 변수에 대입하면
		# "Trying to assign invalid previously freed instance" 에러가 남).
		if not is_instance_valid(dice_root):
			return
		elapsed += get_physics_process_delta_time()

		var all_settled := true
		for die in quiet_frames.keys():
			if not is_instance_valid(die):
				continue
			if quiet_frames[die] >= SETTLE_MIN_FRAMES:
				continue
			var is_quiet: bool = die.linear_velocity.length() <= SETTLE_LIN_THRESHOLD \
				and die.angular_velocity.length() <= SETTLE_ANG_THRESHOLD
			quiet_frames[die] = quiet_frames[die] + 1 if is_quiet else 0
			if quiet_frames[die] < SETTLE_MIN_FRAMES:
				all_settled = false

		if all_settled:
			return
		if elapsed >= SETTLE_MAX_WAIT:
			return


## visual_qa.gd(GAME_QA_SETTLE=1)가 스크린샷을 찍기 전에 폴링하는 훅 (DESIGN.md
## "다이스 정지 감지 후 스크린샷을 찍는 정확한 타이밍/방식" 항목 반영). 위
## `_wait_for_dice_to_settle()`과 같은 임계값을 재사용해, "지금 이 순간 다이스가
## 눈에 띄게 구르고 있는가"만 독립적으로 판단한다 (게임 로직의 정지 대기 상태와는
## 무관 — dice_root가 비어 있으면(스폰 전/후) 트리비얼하게 정지로 간주).
func _qa_is_settled() -> bool:
	if not is_instance_valid(dice_root):
		return true
	for child in dice_root.get_children():
		if child is RigidBody3D:
			if child.linear_velocity.length() > SETTLE_LIN_THRESHOLD \
				or child.angular_velocity.length() > SETTLE_ANG_THRESHOLD:
				return false
	return true


## bag의 다이스별 실제 면 개수(faces.size())에 맞춰 다이스 모양(D4/D6/D8/...)을
## 스폰한다 (Die.sides는 add_child()로 트리에 들어가 _ready()가 도는 시점에 이미
## 메시를 만드므로, 반드시 add_child() 이전에 설정해야 함).
func _spawn_dice(bag: DiceBag, base_x: float, color: Color = Color(1, 1, 1, 0)) -> void:
	var count := bag.count
	var total_rows := int(ceil(float(count) / DICE_SPAWN_PER_ROW))
	for i in count:
		var die := DieScene.instantiate()
		die.sides = bag.dice[i].size()
		die.color_override = color
		var material := _material_for_sides(die.sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		var row := i / DICE_SPAWN_PER_ROW
		var row_start := row * DICE_SPAWN_PER_ROW
		var cols_in_row: int = min(DICE_SPAWN_PER_ROW, count - row_start)
		var col := i - row_start
		var x: float = base_x + (col - (cols_in_row - 1) / 2.0) * DICE_SPAWN_COL_SPACING
		var z := (row - (total_rows - 1) / 2.0) * DICE_SPAWN_ROW_SPACING + randf_range(-0.15, 0.15)
		var y := 1.4 + i * 0.35
		die.transform = Transform3D(Basis(), Vector3(x, y, z))
		die.linear_velocity = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		die.angular_velocity = Vector3(randf_range(2.0, 5.0), randf_range(2.0, 5.0), randf_range(2.0, 5.0))


func _clear_dice() -> void:
	for child in dice_root.get_children():
		child.queue_free()


## 이번 교환의 공격/방어 다이스 결과를 각각 화면 좌/우에서 안쪽으로 나열해 보여준다.
## NextButton(x540-740, 전투 진행 중에는 hidden)과 겹치는 중앙부는 비워 둔다.
func _show_exchange_dice_chips(atk_bag: DiceBag, atk_values: Array, def_bag: DiceBag, def_values: Array, atk_tint: Color, def_tint: Color) -> void:
	_clear_exchange_dice_chips()
	_layout_dice_chip_row(atk_bag, atk_values, 150.0, atk_tint, false)
	_layout_dice_chip_row(def_bag, def_values, 1130.0, def_tint, true)


func _layout_dice_chip_row(bag: DiceBag, values: Array, x_start: float, tint: Color, right_align: bool) -> void:
	var border := tint if tint.a > 0 else Color(0.15, 0.12, 0.08)
	var x := x_start
	for i in bag.dice.size():
		var sides: int = bag.dice[i].size()
		var chip := ShapeDieChip.new()
		chip.custom_minimum_size = Vector2(EXCHANGE_CHIP_SIZE, EXCHANGE_CHIP_SIZE)
		chip.size = Vector2(EXCHANGE_CHIP_SIZE, EXCHANGE_CHIP_SIZE)
		chip.shape_sides = ShapeDieChip.shape_sides_for_dice_sides(sides)
		chip.border_color = border
		chip.value = values[i]
		if right_align:
			x -= EXCHANGE_CHIP_SIZE
		chip.position = Vector2(x, EXCHANGE_CHIP_Y)
		add_child(chip)
		_exchange_chip_nodes.append(chip)
		x += -EXCHANGE_CHIP_GAP if right_align else EXCHANGE_CHIP_SIZE + EXCHANGE_CHIP_GAP


func _clear_exchange_dice_chips() -> void:
	for node in _exchange_chip_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_exchange_chip_nodes.clear()


func _update_labels() -> void:
	player_hp_label.text = "플레이어 HP: %d / %d" % [player_hp, PLAYER_MAX_HP]
	monster_hp_label.text = "%s HP: %d / %d" % [monster_name, monster_hp, monster_max_hp]


func _append_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


func _on_next_button_pressed() -> void:
	if player_won:
		RunState.rooms_cleared += 1
	else:
		RunState.reset_run()
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 승리 시 다이스 개조 아이템 2개를 제시하고, 어느 주머니(공격/방어)에 적용할지
## 고르게 한다. 다이스 뷰포트가 차지하던 영역(140,120)-(1140,540) 위에 반투명 배경과
## 함께 그려서 전투가 끝난 뒤 화면을 재활용한다. NextButton은 아이템을 고르거나
## 건너뛰기 전까지는 숨겨서 보상을 먼저 보게 한다.
func _show_reward_ui() -> void:
	if _reward_items.is_empty():
		_reward_items = DiceItemPool.random_choices(2)

	_clear_reward_ui()
	next_button.hide()
	_add_reward_frame("승리 보상 — 다이스 아이템을 고르고 적용할 주머니를 선택하세요")

	var y := 190.0
	for item in _reward_items:
		var name_label := Label.new()
		name_label.text = "%s\n%s" % [item["name"], item["description"]]
		name_label.position = Vector2(200, y)
		name_label.size = Vector2(880, 50)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(name_label)
		_reward_ui.append(name_label)

		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용"
		atk_btn.position = Vector2(200, y + 55)
		atk_btn.size = Vector2(220, 40)
		atk_btn.pressed.connect(_on_reward_chosen.bind(item, "attack"))
		add_child(atk_btn)
		_reward_ui.append(atk_btn)

		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용"
		def_btn.position = Vector2(440, y + 55)
		def_btn.size = Vector2(220, 40)
		def_btn.pressed.connect(_on_reward_chosen.bind(item, "defense"))
		add_child(def_btn)
		_reward_ui.append(def_btn)

		y += 130.0

	var custom_btn := Button.new()
	custom_btn.text = "커스터마이징: 눈금 교환"
	custom_btn.position = Vector2(200, y + 10)
	custom_btn.size = Vector2(340, 40)
	custom_btn.pressed.connect(_open_customize_from_reward)
	add_child(custom_btn)
	_reward_ui.append(custom_btn)

	var skip_btn := Button.new()
	skip_btn.text = "건너뛰기"
	skip_btn.position = Vector2(560, y + 10)
	skip_btn.size = Vector2(160, 40)
	skip_btn.pressed.connect(_on_reward_skipped)
	add_child(skip_btn)
	_reward_ui.append(skip_btn)


## 공통 배경+제목 프레임을 그린다 (보상 화면의 3단계 — 아이템 선택 / 다이스 선택 /
## 면 선택 — 모두 이 위에 그려서 화면을 재활용한다). D8~D12처럼 면이 많은 다이스는
## 얼굴 그리드가 두 줄이 될 수 있어 height를 늘려 부를 수 있게 함(기본 420).
func _add_reward_frame(title_text: String, height: float = 420.0) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(1000, height)
	add_child(bg)
	_reward_ui.append(bg)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(170, 140)
	title.size = Vector2(940, 30)
	add_child(title)
	_reward_ui.append(title)


func _clear_reward_ui() -> void:
	for node in _reward_ui:
		node.queue_free()
	_reward_ui.clear()


func _on_reward_chosen(item: Dictionary, target: String) -> void:
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	_append_log("아이템 획득: %s (%s 주머니)" % [item["name"], "공격" if target == "attack" else "방어"])
	_clear_reward_ui()
	next_button.show()


func _on_reward_skipped() -> void:
	_clear_reward_ui()
	next_button.show()


## 승리 보상 화면에서 "커스터마이징" 버튼을 누르면 다른 화면들과 동일한 공용
## CustomizePanel 오버레이를 그대로 연다 (더 이상 이 화면만의 별도 다이스/면/값 선택
## 체인을 두지 않음). 보상 아이템 버튼들은 미리 치워두고, 패널이 닫히면(closed 시그널)
## _on_customize_panel_closed()가 next_button을 다시 보여줘 보상 흐름을 마무리한다.
func _open_customize_from_reward() -> void:
	_clear_reward_ui()
	customize_panel.open()


## customize_panel.closed 시그널 핸들러. 전투 중(승패 전) 상단 토글 버튼으로 열고
## 닫을 때도 이 시그널이 발생하지만, 그때는 battle_over가 false이므로 아무 일도
## 일어나지 않는다 — 승리 보상 화면에서 연 경우에만 next_button을 다시 보여준다.
func _on_customize_panel_closed() -> void:
	if battle_over and player_won:
		next_button.show()


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 QA 전용 훅 (dungeon_map.gd의
## _debug_open_customize와 같은 목적 — 전투 중 언제든 열 수 있는 CustomizePanel
## 오버레이가 실제로 열리는지 확인).
func _debug_open_customize() -> void:
	customize_panel.open()


## QA 전용 — INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능하다"
## 조사용. GAME_QA_CALL은 메서드를 직접 호출할 뿐 실제 마우스 클릭을 흉내내지 않으므로,
## _debug_open_customize()(= customize_panel.open() 직접 호출)만으로는 실제 버튼의
## disabled/visible/mouse_filter 상태나 시그널 연결 자체에 문제가 있어도 걸러내지 못한다.
## 그래서 여기서는 버튼 상태를 점검하고 실제 pressed 시그널을 발생시켜 본다.
func _debug_verify_customize_button_during_battle() -> void:
	print("[customize_btn_check] visible=%s disabled=%s mouse_filter=%s battle_over=%s" % [
		customize_toggle_button.visible, customize_toggle_button.disabled,
		customize_toggle_button.mouse_filter, battle_over,
	])
	customize_toggle_button.emit_signal("pressed")
	print("[customize_btn_check] panel_visible_after_press=%s" % customize_panel.visible)


## QA 전용 — 실제 플레이로 승리해 얻은 진짜 눈금 보상으로 커스터마이징 화면을 열어
## 보이는지 확인하기 위함 (frame을 충분히 늦게 잡아 승리 보상 화면이 이미 떠 있는
## 상태에서 호출됨을 전제로 함).
func _debug_open_reward_customize() -> void:
	_open_customize_from_reward()


## QA 전용 — 승리 보상 화면에서 커스터마이징을 열고 닫았을 때 next_button이 다시
## 나타나는지(보상 흐름 복귀)는 스크린샷 한 장으로 보이지 않는 시점 차이라 콘솔로 검증.
func _debug_verify_reward_customize_flow() -> void:
	battle_over = true
	player_won = true
	next_button.hide()
	_open_customize_from_reward()
	var hidden_while_open := not next_button.visible
	customize_panel.close()
	print("[reward_customize_check] hidden_while_open=%s visible_after_close=%s (기대: true, true)" % [hidden_while_open, next_button.visible])


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 정상
## 플레이로는 다이스가 D6/D8/D10으로 섞이려면 승리 보상을 여러 번 받아야 해서 확인이
## 느리므로, 공격 주머니 다이스 3개를 강제로 D6/D8/D10으로 바꾸고 즉시 다시 스폰해
## 물리 다이스 모양이 실제 면 개수를 따라가는지(Die.sides 배선) 스크린샷 한 장으로
## 바로 확인하기 위함.
func _debug_show_mixed_dice_shapes() -> void:
	RunState.player_attack_bag.replace_die(0, 6)
	RunState.player_attack_bag.replace_die(1, 8)
	RunState.player_attack_bag.replace_die(2, 10)
	_clear_dice()
	_spawn_dice(RunState.player_attack_bag, -1.4)
	_spawn_dice(RunState.player_defense_bag, 1.4)
	# QA 캡처는 스폰 직후 1프레임만 지나 찍히므로(물리가 정지할 시간이 없음), 다이스가
	# 낙하/회전 중인 흐릿한 모습 대신 모양을 또렷이 보이도록 그 자리에서 얼린다.
	var i := 0
	for child in dice_root.get_children():
		if child is RigidBody3D:
			child.freeze = true
			child.rotation = Vector3(0.4, i * 0.6, 0.3)
			i += 1


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용). 다이스가
## 여럿 뒤섞인 `_debug_show_mixed_dice_shapes()`는 다이스끼리 겹쳐 보여서 개별 모양
## (특히 새로 추가한 D10)이 뚜렷이 구별되는지 확인하기 어려우므로, D10 하나만 화면
## 중앙에 크게 띄워 지오메트리(면 개수/구멍 유무)를 또렷이 확인하기 위함.
func _debug_show_single_d10() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 10
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — `_debug_show_single_d10()`과 같은 패턴으로 D12(정십이면체) 하나를
## 화면 중앙에 크게 띄워 위상 오류(구멍, 뒤집힌 면) 없이 렌더링되는지 육안 확인한다.
func _debug_show_single_d12() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 12
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — `_debug_show_single_d10()`/`_debug_show_single_d12()`와 같은
## 패턴으로 D20(정이십면체) 하나를 화면 중앙에 크게 띄워 위상 오류(구멍, 뒤집힌 면)
## 없이 렌더링되는지 육안 확인한다.
func _debug_show_single_d20() -> void:
	_clear_dice()
	var die := DieScene.instantiate()
	die.sides = 20
	die.die_size = 0.6
	dice_root.add_child(die)
	die.transform = Transform3D(Basis(), Vector3(0, 1.0, 0))
	die.freeze = true
	die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 전용 래퍼 — 패배 시 표정(플레이어 분노, 몬스터 기쁨)을 스크린샷으로 확인하기
## 위함. randi() 기반 분노/슬픔 분기 중 "분노" 쪽을 강제로 보여준다.
func _debug_show_defeat_expressions() -> void:
	player_portrait.set_expression("angry")
	monster_portrait.set_expression("happy")


