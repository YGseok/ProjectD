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

	result_label.text = "\n".join(lines)
	print("[balance_sim] 완료 — 조합 %d개 x %d판, qa_out/balance_sim_raw.tsv 저장" % [rows.size(), TRIALS_PER_COMBO])


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
