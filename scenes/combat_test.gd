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
## 그대로 재사용한다. 물리적으로 굴러가는 dice/die_d4.tscn(DieD4)은 "손맛" 연출용이며,
## 실제 합계는 DiceBag.roll()의 RNG 결과를 쓴다 (물리 다이스의 착지 면을 읽어 판정하는
## 기능은 아직 없음 — 알려진 이슈로 STATUS.md에 남김).
##
## 다이스가 완전히 멈췄는지 실제로 감지한다 (linear/angular velocity가 임계값 밑으로
## SETTLE_MIN_FRAMES 프레임 연속 유지되면 정지로 판단). 물리 이상 등으로 끝내 멈추지
## 않는 경우를 대비해 SETTLE_MAX_WAIT 초과 시 강제로 진행한다 (안전장치).

const DieD4Scene := preload("res://dice/die_d4.tscn")

const SETTLE_LIN_THRESHOLD := 0.05
const SETTLE_ANG_THRESHOLD := 0.3
const SETTLE_MIN_FRAMES := 15
const SETTLE_MAX_WAIT := 4.0
const EXCHANGE_PAUSE_TIME := 0.8
const MAX_LOG_LINES := 7

@onready var player_hp_label: Label = $PlayerHPLabel
@onready var monster_hp_label: Label = $MonsterHPLabel
@onready var turn_label: Label = $TurnLabel
@onready var log_label: Label = $LogLabel
@onready var dice_root: Node3D = $DiceViewportContainer/DiceViewport/DiceRoot
@onready var next_button: Button = $NextButton

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

## 커스터마이징(직접 눈금 강화)으로 면 하나를 올릴 때마다 더하는 양. INBOX.md 피드백
## "사기 주사위를 만드는 재미" 반영 — 반복 적용 시 상한 없이 계속 누적되어 후반에는
## 노골적으로 과한 다이스를 만들 수 있게 하는 것이 의도.
const FACE_BOOST_AMOUNT := 3

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

	next_button.pressed.connect(_on_next_button_pressed)
	_update_labels()
	_run_battle()


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
	_spawn_dice(atk_bag.count, -1.4, atk_color)
	_spawn_dice(def_bag.count, 1.4, def_color)

	await _wait_for_dice_to_settle()

	var atk_total := atk_bag.roll()
	var def_total := def_bag.roll()
	var dmg := CombatMath.calculate_damage(atk_total, def_total)

	if is_player_attacking:
		monster_hp = max(0, monster_hp - dmg)
		_append_log("플레이어 공격 %d vs 몬스터 방어 %d -> 데미지 %d (몬스터 HP %d)" % [atk_total, def_total, dmg, monster_hp])
	else:
		player_hp = max(0, player_hp - dmg)
		_append_log("몬스터 공격 %d vs 플레이어 방어 %d -> 데미지 %d (플레이어 HP %d)" % [atk_total, def_total, dmg, player_hp])

	_update_labels()

	if monster_hp <= 0:
		battle_over = true
		player_won = true
		turn_label.text = "승리! (몬스터 처치)"
	elif player_hp <= 0:
		battle_over = true
		player_won = false
		turn_label.text = "패배... (플레이어 사망)"

	await get_tree().create_timer(EXCHANGE_PAUSE_TIME).timeout

	if battle_over:
		if player_won:
			next_button.text = "던전으로 돌아가기"
			_show_reward_ui()
		else:
			next_button.text = "처음부터 다시"
			next_button.show()


## 씬에 있는 모든 다이스가 정지했다고 판단될 때까지 기다린다.
func _wait_for_dice_to_settle() -> void:
	var elapsed := 0.0
	var settled_frames := 0
	while true:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		if _all_dice_settled():
			settled_frames += 1
			if settled_frames >= SETTLE_MIN_FRAMES:
				return
		else:
			settled_frames = 0
		if elapsed >= SETTLE_MAX_WAIT:
			return


func _all_dice_settled() -> bool:
	for child in dice_root.get_children():
		if child is RigidBody3D:
			if child.linear_velocity.length() > SETTLE_LIN_THRESHOLD:
				return false
			if child.angular_velocity.length() > SETTLE_ANG_THRESHOLD:
				return false
	return true


func _spawn_dice(count: int, base_x: float, color: Color = Color(1, 1, 1, 0)) -> void:
	for i in count:
		var die := DieD4Scene.instantiate()
		die.color_override = color
		dice_root.add_child(die)
		var x := base_x + (i - (count - 1) / 2.0) * 0.45
		var z := randf_range(-0.3, 0.3)
		var y := 1.4 + i * 0.35
		die.transform = Transform3D(Basis(), Vector3(x, y, z))
		die.linear_velocity = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		die.angular_velocity = Vector3(randf_range(2.0, 5.0), randf_range(2.0, 5.0), randf_range(2.0, 5.0))


func _clear_dice() -> void:
	for child in dice_root.get_children():
		child.queue_free()


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
	get_tree().change_scene_to_file("res://scenes/dungeon_map.tscn")


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
	custom_btn.text = "커스터마이징: 다이스 눈금 직접 강화"
	custom_btn.position = Vector2(200, y + 10)
	custom_btn.size = Vector2(340, 40)
	custom_btn.pressed.connect(_show_customize_picker)
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
## 면 선택 — 모두 이 위에 그려서 화면을 재활용한다).
func _add_reward_frame(title_text: String) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(1000, 420)
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


## 커스터마이징 1단계: 공격/방어 주머니의 다이스 중 하나를 고른다.
## INBOX.md 피드백 "커스터마이징하면 내 덱의 특정 주사위 1개의 한 면 눈금을 바꿀 수
## 있다"를 반영 — 기존 무작위 아이템(_reward_items)과 별개로 언제든 고를 수 있는
## 세 번째 선택지다.
func _show_customize_picker() -> void:
	_clear_reward_ui()
	_add_reward_frame("강화할 다이스를 고르세요")

	var y := 190.0
	y = _add_die_picker_rows("공격 주머니", RunState.player_attack_bag, y)
	y = _add_die_picker_rows("방어 주머니", RunState.player_defense_bag, y)

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + 10)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_reward_ui)
	add_child(back_btn)
	_reward_ui.append(back_btn)


func _add_die_picker_rows(bag_label: String, bag: DiceBag, y: float) -> float:
	for i in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[i]
		var values := PackedStringArray()
		for v in faces:
			values.append(str(v))
		var btn := Button.new()
		btn.text = "%s 다이스 %d  [%s]" % [bag_label, i + 1, ", ".join(values)]
		btn.position = Vector2(200, y)
		btn.size = Vector2(600, 36)
		btn.pressed.connect(_show_face_picker.bind(bag, i))
		add_child(btn)
		_reward_ui.append(btn)
		y += 44.0
	return y


## 커스터마이징 2단계: 고른 다이스의 면 하나를 골라 값을 FACE_BOOST_AMOUNT만큼 올린다.
func _show_face_picker(bag: DiceBag, die_index: int) -> void:
	_clear_reward_ui()
	_add_reward_frame("강화할 면을 고르세요 (값이 +%d 됩니다)" % FACE_BOOST_AMOUNT)

	var faces: PackedInt32Array = bag.dice[die_index]
	var y := 190.0
	var x := 200.0
	for fi in faces.size():
		var btn := Button.new()
		btn.text = "면 %d: %d -> %d" % [fi + 1, faces[fi], faces[fi] + FACE_BOOST_AMOUNT]
		btn.position = Vector2(x, y)
		btn.size = Vector2(180, 40)
		btn.pressed.connect(_on_face_boosted.bind(bag, die_index, fi))
		add_child(btn)
		_reward_ui.append(btn)
		x += 190.0
		if x > 900.0:
			x = 200.0
			y += 50.0

	var back_btn := Button.new()
	back_btn.text = "뒤로"
	back_btn.position = Vector2(200, y + 60)
	back_btn.size = Vector2(160, 40)
	back_btn.pressed.connect(_show_customize_picker)
	add_child(back_btn)
	_reward_ui.append(back_btn)


## qa/visual_qa.gd의 GAME_QA_CALL로 호출하기 위한 인자 없는 래퍼 (QA 전용 — 클릭을
## 흉내낼 수 없는 자동 스크린샷에서 면 선택 화면을 직접 열어보기 위함).
func _debug_open_face_picker() -> void:
	_show_face_picker(RunState.player_attack_bag, 0)


func _on_face_boosted(bag: DiceBag, die_index: int, face_index: int) -> void:
	var faces: PackedInt32Array = bag.dice[die_index]
	var new_value: int = faces[face_index] + FACE_BOOST_AMOUNT
	bag.set_face_value(die_index, face_index, new_value)
	_append_log("커스터마이징: 다이스 %d의 면 %d -> %d" % [die_index + 1, face_index + 1, new_value])
	_clear_reward_ui()
	next_button.show()
