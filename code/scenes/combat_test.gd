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
@onready var player_hp_bar_fill: ColorRect = $PlayerHPBarFill
@onready var monster_hp_bar_fill: ColorRect = $MonsterHPBarFill
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

## INBOX.md 피드백(2026-09-09) "체력바 추가 등 정보를 텍스트보다 이미지로 표현하는게
## 좋을 듯" — HP를 텍스트 라벨뿐 아니라 채워진 정도로 보여주는 막대(ColorRect 2장,
## combat_test.tscn 참고)를 추가한다. 너비는 각 Bg/Fill의 tscn 초기 크기와 맞춰둠.
const PLAYER_HP_BAR_WIDTH := 380.0
const MONSTER_HP_BAR_WIDTH := 340.0
## 체력 비율에 따라 초록(넉넉) -> 주황(경고) -> 빨강(위험)으로 막대 색이 바뀐다 —
## "쪼이는 맛"(위기감)을 색으로도 드러내기 위함.
const HP_BAR_COLOR_HIGH := Color(0.35, 0.85, 0.35)
const HP_BAR_COLOR_MID := Color(0.95, 0.75, 0.25)
const HP_BAR_COLOR_LOW := Color(0.9, 0.25, 0.25)

var monster_hp: int
var monster_max_hp: int
var monster_attack_bag: DiceBag
var monster_defense_bag: DiceBag
var monster_name := "몬스터"
var monster_color := Color(1, 1, 1, 0)

var battle_over := false
var player_won := false
var _room_advanced := false
var _reward_resolved := false
var _log_lines: Array[String] = []
var _reward_ui: Array[Node] = []
var _reward_items: Array[Dictionary] = []

## 이번 교환에서 어떤 다이스가 어떤 값을 냈는지 보여주는 칩(ShapeDieChip). 매 교환마다
## 지우고 새로 그린다 (INBOX.md 2026-09-03: "전투 시 어떤 주사위에서 어떤 값이
## 나왔는지 이미지로 보이면 좋겠다").
var _exchange_chip_nodes: Array[Node] = []
## INBOX.md 피드백(2026-09-09) "전투의 재미가 없다. 다이스 값이 잘 안보여서 쪼이는 맛이
## 덜하다" — 칩 크기를 34 -> 44로 키워 값이 더 잘 보이게 함(라벨 폰트 크기는
## ShapeDieChip이 size.y 비례로 자동 조정하므로 숫자도 함께 커짐). Y좌표는 다이스
## 개수가 많을 때(최대 한 줄) LogLabel(y=556)과 안 겹치도록 같이 조정.
const EXCHANGE_CHIP_SIZE := 44.0
const EXCHANGE_CHIP_GAP := 7.0
const EXCHANGE_CHIP_Y := 504.0

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


## 몬스터 다이스 면 개수(sides) 스케일링. 지금까지 몬스터 주머니는 방과 무관하게 항상
## DiceBag.new(4, ...)(D4 고정)이라 개수만 늘어날 뿐 다이스 "모양"은 절대 안 바뀌는
## 간극이 있었음 (STATUS.md 큐 1 "몬스터별로 의도적으로 다른 다이스 형태를 쓰게 할지는
## 아직 미정"에서 제안된 방향을 그대로 적용). room_index가 늘수록 D4 -> D6 -> D8로
## 커지게 해 "던전이 진행될수록 몬스터가 강해진다"는 체감을 다이스 개수뿐 아니라
## 다이스 모양(과 그에 딸린 재질/색, _material_for_sides() 참고)으로도 드러낸다.
## 값 자체는 감으로 잡은 잠정값 — 이 스케일링이 기존 개수/HP 스케일링과 겹쳐 후반
## 난이도가 과도해지는 건 아닌지 사람 피드백 필요.
func _monster_dice_sides_for_room(room_index: int) -> int:
	if room_index >= 4:
		return 8
	if room_index >= 2:
		return 6
	return 4


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
		"dice_sides": _monster_dice_sides_for_room(room_index),
		"max_hp": 10 + room_index * 3,
		"name": name_text,
		"color": profile["color"],
	}


## QA 전용 — GAME_QA_ROOM_OVERRIDE 환경변수(정수)가 있으면 RunState.rooms_cleared
## 대신 그 room_index로 몬스터를 구성한다. RunState 자체는 건드리지 않아(다른 화면/
## 다음 판에 영향 없음) 순수 QA 검증용. 방마다 몬스터 다이스 개수/모양(sides)이 실제
## "정지 감지가 끝난 뒤" 물리적으로 벽(combat_test.tscn Wall*) 안에 잘 들어와
## 있는지를, freeze로 고정한 스냅샷이 아니라 정상 플레이와 동일한 경로
## (_run_battle() -> _do_exchange() -> _wait_for_dice_to_settle())로 검증하기 위함
## (여러 방을 실제로 깨야만 후반 몬스터 다이스를 볼 수 있어 느린 문제를 우회).
func _room_index_for_monster_config() -> int:
	var override_env := OS.get_environment("GAME_QA_ROOM_OVERRIDE")
	if override_env.is_valid_int():
		return override_env.to_int()
	return RunState.rooms_cleared


func _ready() -> void:
	var config := _monster_config_for_room(_room_index_for_monster_config())
	var monster_sides: int = config["dice_sides"]
	monster_attack_bag = DiceBag.new(monster_sides, config["attack_count"])
	monster_defense_bag = DiceBag.new(monster_sides, config["defense_count"])
	monster_max_hp = config["max_hp"]
	monster_hp = monster_max_hp
	monster_name = config["name"]
	monster_color = config["color"]
	monster_portrait.set_body_color(monster_color if monster_color.a > 0 else Color(0.5, 0.5, 0.5))

	next_button.pressed.connect(_on_next_button_pressed)
	deck_toggle_button.pressed.connect(_on_deck_toggle_pressed)
	customize_toggle_button.pressed.connect(_on_customize_toggle_pressed)
	customize_toggle_button.visible = false
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


## INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다" — 이전
## 이터레이션이 "어디서든 커스터마이징"을 위해 combat_test에도 상시 토글 버튼을
## 붙였던 것을 사용자가 되돌리라고 지시함. 버튼 자체를 battle_over가 될 때까지 숨겨서
## (_ready()/_do_exchange() 참고) 보통은 누를 수조차 없지만, QA의 GAME_QA_CALL처럼
## 시그널을 직접 emit해 visible 체크를 우회하는 경로까지 막기 위해 핸들러에서도
## battle_over를 한 번 더 확인한다.
func _on_customize_toggle_pressed() -> void:
	if not battle_over:
		return
	customize_panel.open()


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

	# INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다" — 전투가
	# 끝난 뒤에만 상단 토글 버튼을 보여준다 (battle_over가 막 true가 된 시점에 맞춰 동기화).
	customize_toggle_button.visible = battle_over

	await get_tree().create_timer(EXCHANGE_PAUSE_TIME).timeout

	if battle_over:
		# INBOX.md 피드백(2026-09-09) "결과 화면이 나왔을 때, 덱 보기 토글이 열려있다면
		# 닫힌다" — 결과 화면(보상/패배)이 덱 패널과 겹쳐 보이지 않도록 강제로 닫는다.
		if deck_panel.visible:
			deck_panel.visible = false
			deck_toggle_button.text = "덱 보기"
		if player_won:
			next_button.text = "다음"
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
	_update_hp_bar(player_hp_bar_fill, PLAYER_HP_BAR_WIDTH, player_hp, PLAYER_MAX_HP)
	_update_hp_bar(monster_hp_bar_fill, MONSTER_HP_BAR_WIDTH, monster_hp, monster_max_hp)


## fill(ColorRect)의 너비를 hp/max_hp 비율만큼 줄이고(왼쪽 기준 고정, 오른쪽부터
## 닳는 형태), 남은 비율에 따라 초록->주황->빨강으로 색을 바꾼다.
func _update_hp_bar(fill: ColorRect, full_width: float, hp: int, max_hp: int) -> void:
	var ratio: float = clamp(float(hp) / max_hp, 0.0, 1.0) if max_hp > 0 else 0.0
	fill.size.x = full_width * ratio
	if ratio > 0.5:
		fill.color = HP_BAR_COLOR_HIGH
	elif ratio > 0.25:
		fill.color = HP_BAR_COLOR_MID
	else:
		fill.color = HP_BAR_COLOR_LOW


func _append_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)


## event.gd의 _on_pick_pressed/_apply_pick(이터레이션 46)와 같은 이유로 이중 실행
## 가드가 필요하다: change_scene_to_file()은 그 프레임 안에서 즉시 씬을 바꾸지 않으므로,
## NextButton을 더블클릭하면 같은 프레임에 이 핸들러가 두 번 불려 rooms_cleared가 2
## 증가(방 스킵)하거나 reset_run()이 중복 호출될 수 있었다. 상태 변경(_apply_room_advance)과
## 씬 전환(_on_next_button_pressed)을 분리한 이유도 동일 — 회귀 테스트가 change_scene_to_file
## 없이 가드만 검증할 수 있게 하기 위함.
func _on_next_button_pressed() -> void:
	if not _apply_room_advance():
		return
	get_tree().change_scene_to_file("res://code/scenes/dungeon_map.tscn")


## 반환값 = 이번 호출이 실제로 적용됐는지 (이미 적용됐으면 false, 아무 것도 안 함).
func _apply_room_advance() -> bool:
	if _room_advanced:
		return false
	_room_advanced = true
	if player_won:
		RunState.rooms_cleared += 1
	else:
		RunState.reset_run()
	return true


## 승리 시 다이스 개조 아이템 2개를 제시하고, 어느 주머니(공격/방어)에 적용할지
## 고르게 한다. 다이스 뷰포트가 차지하던 영역(140,120)-(1140,540) 위에 반투명 배경과
## 함께 그려서 전투가 끝난 뒤 화면을 재활용한다. NextButton은 아이템을 고르거나
## 건너뛰기 전까지는 숨겨서 보상을 먼저 보게 한다.
func _show_reward_ui() -> void:
	if _reward_items.is_empty():
		_reward_items = DiceItemPool.random_choices(2, RunState.player_attack_bag, RunState.player_defense_bag)

	_clear_reward_ui()
	next_button.hide()
	_add_reward_frame("승리 보상 — 다이스 아이템을 고르고 적용할 주머니를 선택하세요")

	# INBOX.md 피드백(2026-09-09) "덱보기 토글 또는 결과 선택지의 위치를 조정해서 ...
	# 겹치지 않도록 한다" — 덱 패널(DeckPanel, x=980~1240)이 결과 화면 도중 다시
	# 열리더라도 겹치지 않도록, 보상 카드 영역을 x=980 앞(140~960)에서 끝나게 좁힌다.
	var card_width := 380.0
	var card_height := 260.0
	var card_y := 185.0
	var card_x := [160.0, 560.0]
	for i in _reward_items.size():
		var item: Dictionary = _reward_items[i]
		var built := ItemCardStyle.build_card(item)
		var card: PanelContainer = built["card"]
		card.position = Vector2(card_x[i], card_y)
		card.size = Vector2(card_width, card_height)
		add_child(card)
		_reward_ui.append(card)

		var button_row: VBoxContainer = built["button_row"]

		var atk_preview := ItemCardStyle.build_effect_preview(item, RunState.player_attack_bag)
		if atk_preview:
			button_row.add_child(atk_preview)
		var atk_applicable := DiceItemPool.is_applicable(item, RunState.player_attack_bag)
		var atk_btn := Button.new()
		atk_btn.text = "공격 주머니에 적용" if atk_applicable else "승급 대상 없음"
		atk_btn.disabled = not atk_applicable
		atk_btn.custom_minimum_size = Vector2(0, 38)
		atk_btn.pressed.connect(_on_reward_chosen.bind(item, "attack"))
		button_row.add_child(atk_btn)

		var def_preview := ItemCardStyle.build_effect_preview(item, RunState.player_defense_bag)
		if def_preview:
			button_row.add_child(def_preview)
		var def_applicable := DiceItemPool.is_applicable(item, RunState.player_defense_bag)
		var def_btn := Button.new()
		def_btn.text = "방어 주머니에 적용" if def_applicable else "승급 대상 없음"
		def_btn.disabled = not def_applicable
		def_btn.custom_minimum_size = Vector2(0, 38)
		def_btn.pressed.connect(_on_reward_chosen.bind(item, "defense"))
		button_row.add_child(def_btn)

	var custom_btn := Button.new()
	custom_btn.text = "커스터마이징: 눈금 교환"
	custom_btn.position = Vector2(160, card_y + card_height + 15)
	custom_btn.size = Vector2(340, 40)
	custom_btn.pressed.connect(_open_customize_from_reward)
	add_child(custom_btn)
	_reward_ui.append(custom_btn)

	var skip_btn := Button.new()
	skip_btn.text = "건너뛰기"
	skip_btn.position = Vector2(560, card_y + card_height + 15)
	skip_btn.size = Vector2(160, 40)
	skip_btn.pressed.connect(_on_reward_skipped)
	add_child(skip_btn)
	_reward_ui.append(skip_btn)


## 공통 배경+제목 프레임을 그린다 (보상 화면의 3단계 — 아이템 선택 / 다이스 선택 /
## 면 선택 — 모두 이 위에 그려서 화면을 재활용한다). D8~D12처럼 면이 많은 다이스는
## 얼굴 그리드가 두 줄이 될 수 있어 height를 늘려 부를 수 있게 함(기본 420).
func _add_reward_frame(title_text: String, height: float = 420.0) -> void:
	# INBOX.md 피드백(2026-09-09) — 폭을 980(DeckPanel 왼쪽 끝)보다 좁게 잡아 덱 패널이
	# 결과 화면 중에 다시 열려도 겹치지 않게 한다 (위 card_x 주석 참고).
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.position = Vector2(140, 120)
	bg.size = Vector2(820, height)
	add_child(bg)
	_reward_ui.append(bg)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(170, 140)
	title.size = Vector2(760, 30)
	add_child(title)
	_reward_ui.append(title)


func _clear_reward_ui() -> void:
	for node in _reward_ui:
		node.queue_free()
	_reward_ui.clear()


## shop.gd/event.gd(이터레이션 45)와 같은 이유의 이중 실행 가드. _clear_reward_ui()가
## queue_free()로 카드/버튼을 지우는데 이는 그 프레임 끝까지 실제로는 트리에 남아있어
## 클릭 가능한 상태다 — 가드 없이는 버튼을 빠르게 두 번 누르면(더블클릭 등) 같은
## 아이템이 두 번 적용되거나(dict가 bind()로 같은 item/target을 물고 있음) 골드/눈금
## 보상과 달리 재검증 수단(예: shop의 "골드 부족")이 없어 조용히 중복 적용될 수 있었다.
## _apply_room_advance()/_apply_pick()과 같은 패턴으로 상태 변경(_apply_reward_choice)과
## UI 갱신(_on_reward_chosen)을 분리해, @onready 노드 없이도(script.new()) 가드만
## 회귀 테스트로 검증할 수 있게 한다. "선택"과 "건너뛰기"는 이 보상 단계의 한 번뿐인
## 결정을 같은 플래그로 공유한다.
func _apply_reward_choice(item: Dictionary, target: String) -> bool:
	if _reward_resolved:
		return false
	_reward_resolved = true
	var bag: DiceBag = RunState.player_attack_bag if target == "attack" else RunState.player_defense_bag
	DiceItemPool.apply(item, bag)
	return true


func _apply_reward_skip() -> bool:
	if _reward_resolved:
		return false
	_reward_resolved = true
	return true


func _on_reward_chosen(item: Dictionary, target: String) -> void:
	if not _apply_reward_choice(item, target):
		return
	_append_log("아이템 획득: %s (%s 주머니)" % [item["name"], "공격" if target == "attack" else "방어"])
	_clear_reward_ui()
	next_button.show()


func _on_reward_skipped() -> void:
	if not _apply_reward_skip():
		return
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


## QA 전용 — INBOX.md 피드백(2026-09-03) "커스터마이징은 전투 중에는 불가능해야 한다"
## 검증용. 이전(2026-09-03 (10)) 조사 당시에는 이 훅이 "버튼이 실수로 안 열리는 게
## 아닌지" 확인하는 용도였지만, 이번에 사용자가 요구사항을 뒤집어 이제는 반대로
## "battle_over=false일 때 정말로 안 열리는지"를 확인하는 용도로 쓴다. GAME_QA_CALL은
## 메서드를 직접 호출할 뿐 실제 마우스 클릭을 흉내내지 않으므로, visible만으로는
## "숨겨서 못 누르게 함"과 "핸들러 자체가 막음"을 구별 못 한다 — 그래서 emit_signal로
## pressed를 강제로 발생시켜서, 핸들러의 battle_over 체크가 실제로 막는지까지 확인한다.
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


## QA 전용 — INBOX.md 피드백(2026-09-09) "덱보기 토글 또는 결과 선택지의 위치를
## 조정해서 ... 겹치지 않도록 한다" 검증용. 정상 플레이로 승리 보상 화면까지 도달한
## 뒤 덱 패널을 다시 여는 것은 물리 정지 대기 때문에 느리므로, 보상 화면을 강제로
## 띄우고 덱 패널을 곧바로 연 상태로 스크린샷 한 장에서 겹침 여부를 확인한다.
func _debug_show_reward_with_deck_open() -> void:
	battle_over = true
	player_won = true
	_show_reward_ui()
	deck_panel.visible = true
	deck_toggle_button.text = "덱 닫기"


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


## QA 디버그 전용 — 재질별 시각 색(visual_color) 추가 검증용. D4(플라스틱)/D8(나무)/
## D10(유리)/D12(철제) 하나씩을 나란히 띄우고 `_material_for_sides()`로 실제 게임과
## 동일하게 재질을 배정해, 네 재질이 눈으로 뚜렷이 구별되는지 한 장으로 확인한다.
func _debug_show_material_swatch() -> void:
	_clear_dice()
	var sides_list := [4, 8, 10, 12]
	for i in sides_list.size():
		var die := DieScene.instantiate()
		die.sides = sides_list[i]
		die.die_size = 0.5
		var material := _material_for_sides(die.sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		die.transform = Transform3D(Basis(), Vector3(-1.8 + i * 1.2, 1.0, 0))
		die.freeze = true
		die.rotation = Vector3(0.5, 0.6, 0.0)


## QA 디버그 전용 — 몬스터 다이스 면 개수(sides) 스케일링(_monster_dice_sides_for_room())
## 검증용. GAME_QA_CALL은 _ready() 이후(즉 몬스터 주머니가 이미 room 0 기준으로
## 만들어진 뒤)에, 그리고 settle 대기보다 나중에 실행되므로, 새로 스폰한 다이스는
## 떨어지는 도중일 수 있다 — _debug_show_material_swatch()와 같은 패턴으로 freeze=true를
## 줘서 낙하 중간 프레임이 찍히지 않고 항상 같은 자세로 보이게 한다.
func _debug_show_monster_dice_for_room(room_index: int) -> void:
	var config := _monster_config_for_room(room_index)
	var sides: int = config["dice_sides"]
	monster_attack_bag = DiceBag.new(sides, config["attack_count"])
	_clear_dice()
	var count: int = config["attack_count"]
	for i in count:
		var die := DieScene.instantiate()
		die.sides = sides
		die.color_override = config["color"]
		var material := _material_for_sides(sides)
		if material != null:
			die.material = material
		dice_root.add_child(die)
		die.transform = Transform3D(Basis(), Vector3(-1.0 + i * 1.0, 1.0, 0))
		die.freeze = true
		die.rotation = Vector3(0.5, 0.6, 0.0)


## GAME_QA_CALL은 인자 없는 메서드만 호출할 수 있어 각 room_index별로 래퍼를 둔다.
func _debug_show_monster_dice_room4() -> void:
	_debug_show_monster_dice_for_room(4)


## QA 전용 래퍼 — 패배 시 표정(플레이어 분노, 몬스터 기쁨)을 스크린샷으로 확인하기
## 위함. randi() 기반 분노/슬픔 분기 중 "분노" 쪽을 강제로 보여준다.
func _debug_show_defeat_expressions() -> void:
	player_portrait.set_expression("angry")
	monster_portrait.set_expression("happy")


