extends Node2D
## 전투 씬 1차 버전 (플레이어 vs 테스트 몬스터).
## DESIGN.md 확정 수치를 그대로 하드코딩: 플레이어 공격/방어 D4x3·HP20,
## 몬스터 공격 D4x2/방어 D4x1·HP10.
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
var monster_hp := 10
const PLAYER_MAX_HP := 20
const MONSTER_MAX_HP := 10

var player_attack_bag := DiceBag.new(4, 3)
var player_defense_bag := DiceBag.new(4, 3)
var monster_attack_bag := DiceBag.new(4, 2)
var monster_defense_bag := DiceBag.new(4, 1)

var battle_over := false
var player_won := false
var _log_lines: Array[String] = []


func _ready() -> void:
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
	var atk_bag: DiceBag = player_attack_bag if is_player_attacking else monster_attack_bag
	var def_bag: DiceBag = monster_defense_bag if is_player_attacking else player_defense_bag

	turn_label.text = "내 공격턴" if is_player_attacking else "몬스터 공격턴 (내 방어턴)"

	_clear_dice()
	_spawn_dice(atk_bag.count, -1.4)
	_spawn_dice(def_bag.count, 1.4)

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
		next_button.text = "던전으로 돌아가기" if player_won else "처음부터 다시"
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


func _spawn_dice(count: int, base_x: float) -> void:
	for i in count:
		var die := DieD4Scene.instantiate()
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
	monster_hp_label.text = "몬스터 HP: %d / %d" % [monster_hp, MONSTER_MAX_HP]


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
