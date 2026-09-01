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
## 다이스가 완전히 멈췄는지 감지하는 기능이 아직 없어서(STATUS.md 알려진 이슈),
## 매 굴림마다 고정 시간(EXCHANGE_SETTLE_TIME)만큼 기다린 뒤 결과를 계산한다.

const DieD4Scene := preload("res://dice/die_d4.tscn")

const EXCHANGE_SETTLE_TIME := 2.2
const EXCHANGE_PAUSE_TIME := 0.8
const MAX_LOG_LINES := 7

@onready var player_hp_label: Label = $PlayerHPLabel
@onready var monster_hp_label: Label = $MonsterHPLabel
@onready var turn_label: Label = $TurnLabel
@onready var log_label: Label = $LogLabel
@onready var dice_root: Node3D = $DiceViewportContainer/DiceViewport/DiceRoot

var player_hp := 20
var monster_hp := 10
const PLAYER_MAX_HP := 20
const MONSTER_MAX_HP := 10

var player_attack_bag := DiceBag.new(4, 3)
var player_defense_bag := DiceBag.new(4, 3)
var monster_attack_bag := DiceBag.new(4, 2)
var monster_defense_bag := DiceBag.new(4, 1)

var battle_over := false
var _log_lines: Array[String] = []


func _ready() -> void:
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

	await get_tree().create_timer(EXCHANGE_SETTLE_TIME).timeout

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
		turn_label.text = "승리! (몬스터 처치)"
	elif player_hp <= 0:
		battle_over = true
		turn_label.text = "패배... (플레이어 사망)"

	await get_tree().create_timer(EXCHANGE_PAUSE_TIME).timeout


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
