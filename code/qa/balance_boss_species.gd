extends Node2D
## [대형 기획 16] R-4 3/3(2026-10-27) — 보스 개별 6종의 승률을 R-2
## (`balance_room3_species.gd`)와 같은 방식으로 직접 측정한다.
##
## J-4(2026-10-13)가 남긴 "보스 개별 6종 중 타락한 기사단장만 밴드(35~55%) 미달"
## 관찰은 J-1~J-3 튜닝 과정의 단발 측정값(27.5~28.9%)에 기반했다 — 이 스크립트는
## `MonsterCatalog.boss_roster_ids()` 6종 전부를 `_simulate_combo_boss()`와 같은
## "몬스터 id를 직접 지정" 패턴(`combat_test._build_monster_config(..., is_boss=true)`)
## 으로 room_index=TOTAL_ROOMS-1(보스 방) 난이도에서 재측정해 현재 수치를 고정한다.
## 조건은 R-2가 쓴 것과 동일 — 캐릭터 8종(시작 스킬 슬롯0) x 균형 성장 정책 x
## TRIALS_PER_BOSS_COMBO판. 라운드별 보스 후보 배정(BOSS_ROSTER_BY_ROUND)과 무관하게
## 6종 전부를 라운드 1~3 난이도 각각에서 측정해 "그 보스가 어느 라운드에 걸리든"의
## 평균을 낸다(실제 플레이에서도 보스 2종 중 하나만 그 라운드에 등장하지만, 다른
## 라운드에 걸렸을 때의 체급도 함께 참고용으로 본다).

@onready var result_label: Label = $ResultLabel

const TRIALS_PER_BOSS_COMBO := 250
const MAX_EXCHANGES := 120
const ROOM_INDEX := RunState.TOTAL_ROOMS - 1

var _combat_script := load("res://code/scenes/combat_test.gd")
var _sim_helper = load("res://code/qa/balance_sim.gd").new()


func _ready() -> void:
	var achievements_backup: Dictionary = AchievementManager._unlocked.duplicate(true)
	var character_backup := RunState.character_id
	var chosen_backup := RunState.chosen_starting_skill_id
	var round_backup := RunState.round_index
	var rooms_backup := RunState.rooms_cleared
	var gold_backup := RunState.gold
	var pip_backup: Array[int] = RunState.pip_inventory.duplicate()
	var plan_backup: Array = RunState.monster_plan
	var elite_plan_backup: Array = RunState.elite_plan

	var boss_ids: Array = MonsterCatalog.boss_roster_ids()
	var per_boss_sum: Dictionary = {}
	var per_boss_count: Dictionary = {}
	for id in boss_ids:
		per_boss_sum[id] = 0.0
		per_boss_count[id] = 0

	print("[R-4 보스 개별 측정] 보스 %d종 x 라운드 1~3 x 캐릭터 8종 x %d판 시작" % [boss_ids.size(), TRIALS_PER_BOSS_COMBO])

	for profile in CharacterProfiles.PROFILES:
		var character_id: String = profile["id"]
		var slot0: Dictionary = SkillPool.starting_skills_for_character(character_id)[0]
		var skill_id: String = slot0["id"]
		RunState.chosen_starting_skill_id = skill_id
		RunState.reset_run(character_id)

		for round_index in range(1, RunState.TOTAL_ROUNDS + 1):
			var global_index: int = _sim_helper.global_index_for(round_index, ROOM_INDEX)
			var growth: Dictionary = _sim_helper.growth_config_for("balanced", character_id, global_index)
			_sim_helper.apply_growth(growth)

			for boss_id in boss_ids:
				var win_rate := _simulate_boss(boss_id, round_index)
				per_boss_sum[boss_id] += win_rate
				per_boss_count[boss_id] += 1
				print("%s r%d vs %s: %.1f%%" % [character_id, round_index, boss_id, win_rate * 100.0])

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

	var overall_sum := 0.0
	var overall_count := 0
	var rows: Array[Dictionary] = []
	for boss_id in boss_ids:
		var avg: float = per_boss_sum[boss_id] / per_boss_count[boss_id]
		overall_sum += per_boss_sum[boss_id]
		overall_count += per_boss_count[boss_id]
		rows.append({
			"id": boss_id,
			"name": MonsterCatalog.get_by_id(boss_id).get("name", boss_id),
			"avg": avg,
		})
	rows.sort_custom(func(a, b): return a["avg"] < b["avg"])
	var overall_avg: float = overall_sum / overall_count

	var summary_lines: Array[String] = []
	summary_lines.append("")
	summary_lines.append("## R-4 보스 개별 측정 (고정 기록, 2026-10-27)")
	summary_lines.append("")
	summary_lines.append("> [대형 기획 16] R-4 3/3 — `bash scripts/qa_shot.sh balance_boss_species`로")
	summary_lines.append("> 재실행 가능. 보스 6종 전부를 room_index=%d(라운드 1~3)에서 `_build_monster_config(is_boss=true)`로" % ROOM_INDEX)
	summary_lines.append("> 직접 구성해(실제 플레이의 라운드별 2종 제한과 무관하게 6종 전부 측정) 캐릭터 8종 x")
	summary_lines.append("> 균형 성장 정책 x %d판으로 측정(보스당 24개 cell 평균). 전체 평균 %.1f%%." % [TRIALS_PER_BOSS_COMBO, overall_avg * 100.0])
	summary_lines.append("")
	summary_lines.append("| 보스 | 평균 승률 | 편차(전체 평균 대비) |")
	summary_lines.append("|---|---|---|")
	for r in rows:
		summary_lines.append("| %s | %.1f%% | %+.1f%%p |" % [r["name"], r["avg"] * 100.0, (r["avg"] - overall_avg) * 100.0])
	summary_lines.append("")

	_append_to_log("\n".join(summary_lines))

	result_label.text = "[balance_boss_species] 완료 — 보스 %d종, 전체 평균 %.1f%%\n최저: %s %.1f%% / 최고: %s %.1f%%" % [
		boss_ids.size(), overall_avg * 100.0,
		rows[0]["name"], rows[0]["avg"] * 100.0,
		rows[rows.size() - 1]["name"], rows[rows.size() - 1]["avg"] * 100.0,
	]
	print(result_label.text)
	for line in summary_lines:
		print(line)


func _simulate_boss(boss_id: String, round_index: int) -> float:
	var difficulty: int = ROOM_INDEX + (round_index - 1) * 3
	var profile: Dictionary = MonsterCatalog.get_by_id(boss_id)
	var monster_name: String = profile.get("name", boss_id)

	var wins := 0
	for _trial in TRIALS_PER_BOSS_COMBO:
		RunState.gold = 0
		RunState.pip_inventory = []

		var instance = _combat_script.new()
		var config: Dictionary = instance._build_monster_config(profile, monster_name, difficulty, true)
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

		if instance.battle_over and instance.player_won:
			wins += 1
		instance.free()

	return float(wins) / TRIALS_PER_BOSS_COMBO


## balance_room3_species.gd의 "고정 기록" 방식과 동일 — 재실행마다 끝에 새로 덧붙인다.
func _append_to_log(section_md: String) -> void:
	var abs_path := ProjectSettings.globalize_path("res://docs/BALANCE_TUNING_LOG.md")
	var existing := ""
	if FileAccess.file_exists(abs_path):
		var read_file := FileAccess.open(abs_path, FileAccess.READ)
		if read_file != null:
			existing = read_file.get_as_text()
			read_file.close()

	var body := existing
	if not body.ends_with("\n"):
		body += "\n"
	body += section_md

	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_boss_species] BALANCE_TUNING_LOG.md 저장 실패: %s" % abs_path)
		return
	file.store_string(body)
	file.close()
