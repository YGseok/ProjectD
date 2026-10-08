extends Node2D
## [대형 기획 5] F-4b(2026-10-07) — 밸런스 자동 시뮬레이션 러너.
##
## F-4a가 연 헤드리스 경로(combat_test.gd의 _select_exchange_bags()/_resolve_exchange(),
## 물리/UI 노드에 전혀 의존하지 않음)를 그대로 호출해 전투 한 판을 계산한다. "시뮬
## 전용으로 규칙을 복붙하면 의미 없다"는 F-4a 원칙을 지키기 위해, combat_test.gd를
## script.new()로 인스턴스만 만들고(씬 트리에 add_child 안 함 — code/scenes/dice_test.gd가
## 이미 쓰는 패턴, 1485행 주석 참고) production 함수를 그대로 부른다. UI 노드(@onready)는
## 건드리지 않는다 — 몬스터/플레이어 전투 상태 초기화도 combat_test.gd의 _apply_monster_
## config()/_reset_player_battle_state()(F-4b가 _ready()에서 뽑아낸 순수 부분)를 그대로
## 재사용해 이중 구현을 피한다.
##
## 범위(INBOX.md [대형 기획 6] G-1~G-9 완료 후 확정된 지시 — "F-4a~c의 '기본 몬스터
## 5종 x 방 0~4'는 G 완료 후 '계획된 몬스터 + 정예 + 보스, 라운드 1~3'으로 범위를
## 넓힐 것"): 캐릭터 7종 x 시작 스킬 슬롯 3개(해금 가정 — 3개 전부 부여) x
## {라운드 1~3 x 방 0~4(일반, 방4=보스) + 라운드 1~3 x 방 1~3(정예, G-7과 같은 범위)}
## x TRIALS_PER_COMBO판. 아이템/상점 없이 "시작 구성 그대로"의 기준선만 본다(매 trial마다
## RunState.gold/pip_inventory를 0/빈 배열로 되돌려 "황금손"/"수집가" 같은 경제 의존
## 시작 스킬이 유리해지지 않게 한다).
##
## 캐릭터/스킬 간 비교가 "같은 몬스터를 상대했는가"로 공정하려면 몬스터 뽑기 자체도
## 고정해야 한다 — MonsterCatalog.build_monster_plan()/build_elite_plan()을 매 조합마다
## RunState.reset_run()이 새로 굴리는 난수 시드 대신 FIXED_PLAN_SEED 하나로 고정해
## 모든 캐릭터×스킬 조합이 동일한 라운드별 몬스터 배정을 상대한다(F-4c "시뮬 재현
## 가능하게 난수 시드를 고정/기록" 요구를 몬스터 선택 쪽에 적용 — 다이스 굴림 자체는
## 조합마다 TRIALS_PER_COMBO번 독립적으로 다시 굴러야 하므로 고정하지 않는다).
##
## 출력: 조합별 승률/평균 턴 수/승리 시 평균 남은 HP를 result_label(스크린샷 확인용,
## 조합이 많아 화면 밖으로 넘칠 수 있지만 "실행됐다"만 확인하면 충분)과 stdout(print,
## 실제 수치 확인/다음 조각 F-4c가 참고할 로그) 양쪽에 낸다. 숫자의 해석(이상치 판정,
## 조정 제안)은 F-4c 몫 — 여기서는 측정만 한다.
##
## AchievementManager.unlock()이 _resolve_exchange()를 통해 실제로 user://achievements.json에
## 쓰므로, 시뮬 시작 전 백업하고 끝나면 복원한다(F-3 E2E 테스트가 쓴 패턴과 동일,
## dice_test.gd의 _check_f3_e2e_flow 참고).

@onready var result_label: Label = $ResultLabel

## 느리면 줄여도 되지만 최소 100판(INBOX.md F-4b 지시) — 줄였다면 F-4c 보고서에 명시.
const TRIALS_PER_COMBO := 100
## 한 판이 끝없이 이어지는 것(방어가 공격을 항상 완전히 막는 교착 등)을 막는 안전장치.
## 교환 1회(공격턴 또는 방어턴 하나)를 1로 센다 — 정상적인 전투는 보통 10~20 안쪽에서 끝난다.
const MAX_EXCHANGES := 120
## 몬스터 뽑기를 캐릭터/스킬 조합과 무관하게 고정해 "같은 몬스터를 상대했는가"를 보장한다.
const FIXED_PLAN_SEED := 20261007
const ELITE_SEED_OFFSET := 104729

var _combat_script := load("res://code/scenes/combat_test.gd")


## [대형 기획 7] F-5(a)(2026-10-08) — "성장 정책" 3종. INBOX.md 2026-10-08 지시: F-4
## 기준선(아이템 없이 시작 구성 그대로)은 후반 난이도 절벽이 "기대된 결과"인지 판단할
## 근거가 없다 — "런 중 실제로 강해지면 절벽이 완화되는가"를 보려고 전투 직전
## RunState 주머니를 "지금까지 몇 번째 전투인가"(global index)에 따라 단순 규칙으로
## 키운 뒤 같은 _resolve_exchange() 경로로 돌린다. F-4b의 기준선 루프(_ready()/
## _simulate_combo(), 위)는 손대지 않고 그대로 유지 — 비교 기준이 바뀌면 안 되므로
## "none" 정책은 항상 성장 없음(기존 기준선과 동일)을 뜻한다. 시뮬 실행/TSV 저장(b)은
## 아래 _run_growth_simulation()/_simulate_growth_combo()(2026-10-08 추가, qa_out/
## balance_sim_growth_raw.tsv 산출) — 리포트 생성기(c)는 다음 조각.
const GROWTH_POLICY_NONE := "none"
const GROWTH_POLICY_BALANCED := "balanced"
const GROWTH_POLICY_ATTACK_HEAVY := "attack_heavy"
const GROWTH_POLICY_DEFENSE_HEAVY := "defense_heavy"
const GROWTH_POLICIES: Array[String] = [
	GROWTH_POLICY_NONE, GROWTH_POLICY_BALANCED, GROWTH_POLICY_ATTACK_HEAVY, GROWTH_POLICY_DEFENSE_HEAVY,
]


## global index = 지금까지 치른 전투 수(0부터 시작) = (round_index-1)*TOTAL_ROOMS +
## room_index. F-4b와 같은 라운드/방 범위(라운드 1~3 x 방 0~4)를 그대로 쓰므로 0~14.
static func global_index_for(round_index: int, room_index: int) -> int:
	return (round_index - 1) * RunState.TOTAL_ROOMS + room_index


## 세 정책 공통: global index 5 이후 D4->D6, 10 이후 D8("한 라운드에 아이템 3~4개
## 얻는 정도의 성장" 가정, INBOX.md 원문 — 실제 상점/보상 픽과 완전히 같을 필요는
## 없음). "none"(기존 기준선)은 성장 자체가 없으므로 항상 캐릭터 기본 면 개수(4)를
## 반환한다.
static func growth_sides_for(policy: String, global_index: int) -> int:
	if policy == GROWTH_POLICY_NONE:
		return 4
	if global_index >= 10:
		return 8
	if global_index >= 5:
		return 6
	return 4


## 공격/방어 다이스 "개수" 성장 — 세 정책 모두 같은 속도(전투 2번마다 1개)로 늘지만
## 배분 방향이 다르다: balanced=공격/방어 번갈아 / attack_heavy=공격만 / defense_heavy=
## 방어만. DiceBag.MAX_DICE로 상한(그 이상은 더 안 늘어남 — 캡 도달을 "성장 끝"으로
## 취급, 새 상한 체계를 만들지 않음).
static func growth_counts_for(policy: String, base_attack: int, base_defense: int, global_index: int) -> Dictionary:
	var attack_count := base_attack
	var defense_count := base_defense
	if policy != GROWTH_POLICY_NONE:
		var additions := int(global_index / 2.0)
		for i in additions:
			match policy:
				GROWTH_POLICY_BALANCED:
					if i % 2 == 0:
						attack_count += 1
					else:
						defense_count += 1
				GROWTH_POLICY_ATTACK_HEAVY:
					attack_count += 1
				GROWTH_POLICY_DEFENSE_HEAVY:
					defense_count += 1
	return {
		"attack_count": clampi(attack_count, 1, DiceBag.MAX_DICE),
		"defense_count": clampi(defense_count, 1, DiceBag.MAX_DICE),
	}


## growth_sides_for()/growth_counts_for()를 합쳐 그 캐릭터·정책·global_index에서
## 적용할 전체 구성을 돌려준다(test_battle_setup.gd._apply_growth()가 받는 것과 같은
## 모양의 Dictionary — "attack_count"/"defense_count"/"sides").
static func growth_config_for(policy: String, character_id: String, global_index: int) -> Dictionary:
	var profile := CharacterProfiles.get_profile(character_id)
	var counts := growth_counts_for(policy, profile.get("attack_count", 3), profile.get("defense_count", 3), global_index)
	counts["sides"] = growth_sides_for(policy, global_index)
	return counts


## growth_config_for()의 결과를 실제 RunState 주머니에 적용한다
## (test_battle_setup.gd._apply_growth()와 같은 재구성 방식 — 다이스를 새로 만들고
## 캐릭터 기믹을 재적용). (b)(시뮬 실행)가 매 전투 직전에 이 함수를 부른다.
static func apply_growth(growth: Dictionary) -> void:
	RunState.player_attack_bag = DiceBag.new(growth["sides"], growth["attack_count"])
	RunState.player_defense_bag = DiceBag.new(growth["sides"], growth["defense_count"])
	RunState._apply_character_gimmick()


## [대형 기획 7] F-5(b)(2026-10-08) — 실제로 돌릴 정책은 3종(균형/공격 몰빵/방어
## 몰빵)뿐이다. "none"(성장 없음)은 이미 F-4 기준선(docs/BALANCE_REPORT.md)으로
## 측정이 끝나 있어 다시 돌리지 않는다(INBOX.md 대상 범위 원문: "정책 3종").
const GROWTH_SIM_POLICIES: Array[String] = [
	GROWTH_POLICY_BALANCED, GROWTH_POLICY_ATTACK_HEAVY, GROWTH_POLICY_DEFENSE_HEAVY,
]


func _ready() -> void:
	var lines: PackedStringArray = []
	lines.append("[F-4b 밸런스 시뮬] 조합당 %d판, 몬스터 배정 시드=%d (고정, 조합 간 공정 비교용)" % [TRIALS_PER_COMBO, FIXED_PLAN_SEED])
	lines.append("")

	var achievements_backup: Dictionary = AchievementManager._unlocked.duplicate(true)
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var round_backup := RunState.round_index
	var rooms_backup := RunState.rooms_cleared
	var gold_backup := RunState.gold
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	var plan_backup: Array = RunState.monster_plan
	var elite_plan_backup: Array = RunState.elite_plan

	var fixed_monster_plan: Array = MonsterCatalog.build_monster_plan(FIXED_PLAN_SEED, RunState.TOTAL_ROUNDS, RunState.TOTAL_ROOMS)
	var fixed_elite_plan: Array = MonsterCatalog.build_elite_plan(FIXED_PLAN_SEED + ELITE_SEED_OFFSET, RunState.TOTAL_ROUNDS, RunState.TOTAL_ROOMS)

	var rows: Array[Dictionary] = []
	for profile in CharacterProfiles.PROFILES:
		var character_id: String = profile["id"]
		for slot in SkillPool.starting_skills_for_character(character_id):
			var skill_id: String = slot["id"]
			RunState.chosen_starting_skill_id = skill_id
			RunState.reset_run(character_id)
			RunState.monster_plan = fixed_monster_plan
			RunState.elite_plan = fixed_elite_plan
			for round_index in range(1, RunState.TOTAL_ROUNDS + 1):
				for room_index in range(RunState.TOTAL_ROOMS):
					var stats := _simulate_combo(character_id, skill_id, round_index, room_index, false)
					rows.append(stats)
					var row_line := _format_row(stats)
					lines.append(row_line)
					print(row_line)
				# 정예는 방 1~3(첫/마지막 방 제외, G-7과 같은 범위)에서만 추가 선택지로 노출.
				for room_index in range(1, RunState.TOTAL_ROOMS - 1):
					var elite_stats := _simulate_combo(character_id, skill_id, round_index, room_index, true)
					rows.append(elite_stats)
					var elite_row_line := _format_row(elite_stats)
					lines.append(elite_row_line)
					print(elite_row_line)

	AchievementManager._unlocked = achievements_backup
	AchievementManager._save()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	RunState.round_index = round_backup
	RunState.rooms_cleared = rooms_backup
	RunState.gold = gold_backup
	RunState.pip_inventory = pip_backup
	RunState.monster_plan = plan_backup
	RunState.elite_plan = elite_plan_backup

	lines.append("")
	lines.append("[조합 수] %d (x %d판 = 전투 %d판)" % [rows.size(), TRIALS_PER_COMBO, rows.size() * TRIALS_PER_COMBO])
	_save_raw_tsv(rows)

	print("[balance_sim] 완료 — 조합 %d개 x %d판, qa_out/balance_sim_raw.tsv 저장" % [rows.size(), TRIALS_PER_COMBO])

	var growth_summary := _run_growth_simulation(fixed_monster_plan, fixed_elite_plan)
	lines.append("")
	lines.append(growth_summary)

	result_label.text = "\n".join(lines)


## 하나의 (캐릭터, 시작 스킬, 라운드, 방, 정예 여부) 조합에 대해 TRIALS_PER_COMBO판을
## 독립적으로 치르고 집계한다. RunState.monster_plan/elite_plan/character_id/skill_flags는
## 이미 호출부가 맞춰둔 상태라고 가정(이 함수는 그 설정을 바꾸지 않음) — 매 trial마다
## 바뀌는 것은 RunState.gold/pip_inventory(0/빈 배열로 리셋, "기준선" 조건)와 다이스
## RNG 결과뿐이다.
func _simulate_combo(character_id: String, skill_id: String, round_index: int, room_index: int, is_elite: bool) -> Dictionary:
	var wins := 0
	var timeouts := 0
	var total_turns := 0
	var hp_sum_on_win := 0
	var monster_name := ""

	for _trial in TRIALS_PER_COMBO:
		RunState.gold = 0
		RunState.pip_inventory = []

		var instance = _combat_script.new()
		var config: Dictionary = instance._monster_config_for_elite(round_index, room_index) if is_elite \
			else instance._monster_config_for_plan(round_index, room_index)
		if monster_name == "":
			monster_name = config.get("name", "")
		instance._apply_monster_config(config)
		instance._reset_player_battle_state()

		var exchanges := 0
		var is_player_attacking := true
		while not instance.battle_over and exchanges < MAX_EXCHANGES:
			var selection: Dictionary = instance._select_exchange_bags(is_player_attacking)
			instance._resolve_exchange(
				is_player_attacking, selection["atk_bag"], selection["def_bag"],
				selection["used_explosive_dice"], selection["used_guard_dice"], selection["used_anger_dice"]
			)
			exchanges += 1
			is_player_attacking = not is_player_attacking

		if not instance.battle_over:
			timeouts += 1
		elif instance.player_won:
			wins += 1
			hp_sum_on_win += instance.player_hp
		total_turns += exchanges
		instance.free()

	return {
		"character_id": character_id,
		"skill_id": skill_id,
		"round_index": round_index,
		"room_index": room_index,
		"is_elite": is_elite,
		"monster_name": monster_name,
		"trials": TRIALS_PER_COMBO,
		"wins": wins,
		"timeouts": timeouts,
		"win_rate": float(wins) / TRIALS_PER_COMBO,
		"avg_turns": float(total_turns) / TRIALS_PER_COMBO,
		"avg_hp_on_win": (float(hp_sum_on_win) / wins) if wins > 0 else 0.0,
	}


func _format_row(stats: Dictionary) -> String:
	var elite_tag := " [정예]" if stats["is_elite"] else ""
	var timeout_tag := " (타임아웃 %d)" % stats["timeouts"] if stats["timeouts"] > 0 else ""
	return "%s/%s r%d방%d%s vs %s: 승률 %.0f%% (%d/%d) 평균턴 %.1f 승리시평균HP %.1f%s" % [
		stats["character_id"], stats["skill_id"], stats["round_index"], stats["room_index"], elite_tag,
		stats["monster_name"], stats["win_rate"] * 100.0, stats["wins"], stats["trials"],
		stats["avg_turns"], stats["avg_hp_on_win"], timeout_tag,
	]


## [대형 기획 7] F-5(b)(2026-10-08) — 성장 정책 시뮬 실행. 기존 F-4b 기준선 루프
## (_ready() 위쪽 본문, _simulate_combo())는 전혀 건드리지 않고, 완전히 분리된 이
## 함수가 독립적으로 자기 백업/복원을 수행한다. 범위(INBOX.md 2026-10-08 원문):
## 캐릭터 7종 x **시작 스킬 슬롯 0만**(기준선처럼 3슬롯 전부가 아니라 "정책 효과"만
## 보기 위해 스킬 변수를 고정) x 정책 3종 x {라운드1~3 x 방0~4(일반, 방4=보스) +
## 라운드1~3 x 방1~3(정예)} x TRIALS_PER_COMBO판. fixed_monster_plan/fixed_elite_plan은
## 호출부(_ready())가 이미 만들어둔 것을 그대로 받아써서 기준선과 같은 몬스터 배정을
## 상대하게 한다(공정 비교).
func _run_growth_simulation(fixed_monster_plan: Array, fixed_elite_plan: Array) -> String:
	var achievements_backup: Dictionary = AchievementManager._unlocked.duplicate(true)
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var round_backup := RunState.round_index
	var rooms_backup := RunState.rooms_cleared
	var gold_backup := RunState.gold
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	var plan_backup: Array = RunState.monster_plan
	var elite_plan_backup: Array = RunState.elite_plan

	var rows: Array[Dictionary] = []
	for profile in CharacterProfiles.PROFILES:
		var character_id: String = profile["id"]
		var slot0: Dictionary = SkillPool.starting_skills_for_character(character_id)[0]
		var skill_id: String = slot0["id"]
		for policy in GROWTH_SIM_POLICIES:
			RunState.chosen_starting_skill_id = skill_id
			RunState.reset_run(character_id)
			RunState.monster_plan = fixed_monster_plan
			RunState.elite_plan = fixed_elite_plan
			for round_index in range(1, RunState.TOTAL_ROUNDS + 1):
				for room_index in range(RunState.TOTAL_ROOMS):
					var stats := _simulate_growth_combo(character_id, skill_id, policy, round_index, room_index, false)
					rows.append(stats)
					print(_format_growth_row(stats))
				for room_index in range(1, RunState.TOTAL_ROOMS - 1):
					var elite_stats := _simulate_growth_combo(character_id, skill_id, policy, round_index, room_index, true)
					rows.append(elite_stats)
					print(_format_growth_row(elite_stats))

	AchievementManager._unlocked = achievements_backup
	AchievementManager._save()
	RunState.character_id = character_backup
	RunState.chosen_starting_skill_id = chosen_backup
	RunState.reset_run(character_backup)
	RunState.round_index = round_backup
	RunState.rooms_cleared = rooms_backup
	RunState.gold = gold_backup
	RunState.pip_inventory = pip_backup
	RunState.monster_plan = plan_backup
	RunState.elite_plan = elite_plan_backup

	_save_growth_raw_tsv(rows)
	var summary := "[F-5b 성장 정책 시뮬] 조합 %d개 x %d판 = 전투 %d판, qa_out/balance_sim_growth_raw.tsv 저장" % [rows.size(), TRIALS_PER_COMBO, rows.size() * TRIALS_PER_COMBO]
	print("[balance_sim] " + summary)
	return summary


## _simulate_combo()와 같은 구조(공정 비교를 위해 전투 1판 계산 경로는 완전히 동일)에
## "policy" 축과 global_index 기반 apply_growth() 호출만 추가한 버전. 성장 구성은 이
## 조합(캐릭터/정책/라운드/방) 안에서 TRIALS_PER_COMBO판 내내 동일하게 유지된다 —
## _simulate_combo()도 라운드/방 조합마다 플레이어 주머니를 trial별로 다시 만들지
## 않으므로(최초 reset_run() 결과를 그대로 재사용) 같은 전제를 따른다.
func _simulate_growth_combo(character_id: String, skill_id: String, policy: String, round_index: int, room_index: int, is_elite: bool) -> Dictionary:
	var global_index := global_index_for(round_index, room_index)
	var growth := growth_config_for(policy, character_id, global_index)
	apply_growth(growth)

	var wins := 0
	var timeouts := 0
	var total_turns := 0
	var hp_sum_on_win := 0
	var monster_name := ""

	for _trial in TRIALS_PER_COMBO:
		RunState.gold = 0
		RunState.pip_inventory = []

		var instance = _combat_script.new()
		var config: Dictionary = instance._monster_config_for_elite(round_index, room_index) if is_elite \
			else instance._monster_config_for_plan(round_index, room_index)
		if monster_name == "":
			monster_name = config.get("name", "")
		instance._apply_monster_config(config)
		instance._reset_player_battle_state()

		var exchanges := 0
		var is_player_attacking := true
		while not instance.battle_over and exchanges < MAX_EXCHANGES:
			var selection: Dictionary = instance._select_exchange_bags(is_player_attacking)
			instance._resolve_exchange(
				is_player_attacking, selection["atk_bag"], selection["def_bag"],
				selection["used_explosive_dice"], selection["used_guard_dice"], selection["used_anger_dice"]
			)
			exchanges += 1
			is_player_attacking = not is_player_attacking

		if not instance.battle_over:
			timeouts += 1
		elif instance.player_won:
			wins += 1
			hp_sum_on_win += instance.player_hp
		total_turns += exchanges
		instance.free()

	return {
		"character_id": character_id,
		"skill_id": skill_id,
		"policy": policy,
		"global_index": global_index,
		"round_index": round_index,
		"room_index": room_index,
		"is_elite": is_elite,
		"monster_name": monster_name,
		"trials": TRIALS_PER_COMBO,
		"wins": wins,
		"timeouts": timeouts,
		"win_rate": float(wins) / TRIALS_PER_COMBO,
		"avg_turns": float(total_turns) / TRIALS_PER_COMBO,
		"avg_hp_on_win": (float(hp_sum_on_win) / wins) if wins > 0 else 0.0,
	}


func _format_growth_row(stats: Dictionary) -> String:
	var elite_tag := " [정예]" if stats["is_elite"] else ""
	var timeout_tag := " (타임아웃 %d)" % stats["timeouts"] if stats["timeouts"] > 0 else ""
	return "%s/%s/%s idx%d r%d방%d%s vs %s: 승률 %.0f%% (%d/%d) 평균턴 %.1f 승리시평균HP %.1f%s" % [
		stats["character_id"], stats["skill_id"], stats["policy"], stats["global_index"],
		stats["round_index"], stats["room_index"], elite_tag,
		stats["monster_name"], stats["win_rate"] * 100.0, stats["wins"], stats["trials"],
		stats["avg_turns"], stats["avg_hp_on_win"], timeout_tag,
	]


## F-5(c)(다음 조각, docs/BALANCE_GROWTH_REPORT.md 작성)가 godot을 다시 돌리지 않고도
## 숫자를 참고할 수 있도록 원자료를 TSV로 남긴다. 기존 balance_sim_raw.tsv(기준선)와는
## 별개 파일 — 열이 다르고(policy/global_index 추가) 기준선 값을 덮어쓰면 안 된다.
func _save_growth_raw_tsv(rows: Array[Dictionary]) -> void:
	var abs_path := ProjectSettings.globalize_path("res://qa_out/balance_sim_growth_raw.tsv")
	var dir_err := DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("[balance_sim] 출력 디렉토리 생성 실패: %s" % abs_path.get_base_dir())
		return
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_sim] growth TSV 저장 실패: %s" % abs_path)
		return
	file.store_line("character_id\tskill_id\tpolicy\tglobal_index\tround_index\troom_index\tis_elite\tmonster_name\ttrials\twins\ttimeouts\twin_rate\tavg_turns\tavg_hp_on_win")
	for row in rows:
		file.store_line("%s\t%s\t%s\t%d\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%.4f\t%.2f\t%.2f" % [
			row["character_id"], row["skill_id"], row["policy"], row["global_index"],
			row["round_index"], row["room_index"], str(row["is_elite"]), row["monster_name"],
			row["trials"], row["wins"], row["timeouts"],
			row["win_rate"], row["avg_turns"], row["avg_hp_on_win"],
		])
	file.close()


## F-4c(다음 조각, docs/BALANCE_REPORT.md 작성)가 godot을 다시 돌리지 않고도 숫자를
## 참고할 수 있도록 원자료를 TSV로 남긴다. qa_out/은 QA 산출물 전용 폴더라 resources/나
## docs/art/와 달리 Work 쪽이 자유롭게 쓰고 지울 수 있다.
func _save_raw_tsv(rows: Array[Dictionary]) -> void:
	var abs_path := ProjectSettings.globalize_path("res://qa_out/balance_sim_raw.tsv")
	var dir_err := DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("[balance_sim] 출력 디렉토리 생성 실패: %s" % abs_path.get_base_dir())
		return
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_sim] TSV 저장 실패: %s" % abs_path)
		return
	file.store_line("character_id\tskill_id\tround_index\troom_index\tis_elite\tmonster_name\ttrials\twins\ttimeouts\twin_rate\tavg_turns\tavg_hp_on_win")
	for row in rows:
		file.store_line("%s\t%s\t%d\t%d\t%s\t%s\t%d\t%d\t%d\t%.4f\t%.2f\t%.2f" % [
			row["character_id"], row["skill_id"], row["round_index"], row["room_index"],
			str(row["is_elite"]), row["monster_name"], row["trials"], row["wins"], row["timeouts"],
			row["win_rate"], row["avg_turns"], row["avg_hp_on_win"],
		])
	file.close()
