extends Node2D
## [대형 기획 16] R-2(2026-10-26) 1단계 — "일반 방3 풀에 걸리는 17종" 개별 승률을
## 직접 측정해 평균을 끌어내리는 아웃라이어 몬스터를 찾는다.
##
## R-1 재측정(BALANCE_TUNING_LOG.md "R-1 로스터 정리 후 재측정")의 68.7%는
## FIXED_PLAN_SEED 고정 시드가 라운드당 "방3에 걸린 몬스터 1종(셔플 후 슬라이스 결과)"만
## 우연히 뽑아 측정한 것이라, 17종 전체의 방3 성능을 대표하지 못한다 — 이 스크립트는
## MonsterCatalog.normal_roster_ids() 17종 전부를 room_index=3 난이도(라운드 1~3,
## difficulty=3/6/9)에서 combat_test._build_monster_config()로 직접 구성해(보스 측정이
## balance_sim.gd._simulate_combo_boss()에서 쓰는 것과 같은 "몬스터 id를 직접 지정"
## 패턴) 몬스터별 평균 승률을 낸다. 조건은 J-3/J-4가 판정에 쓴 것과 동일하게 맞춘다 —
## 캐릭터 8종(시작 스킬 슬롯0) x 균형 성장 정책(balance_sim.gd의 growth_config_for()/
## apply_growth()를 인스턴스 경유로 그대로 재사용 — 이중 구현 금지) x
## TRIALS_PER_MONSTER_COMBO판(INBOX.md 지시 "조합당 200~300판"으로 기존 100보다 키운
## 표본, 노이즈도 함께 확인). 해석/조정 제안은 쓰지 않는다 — 다음 단계가 이 표를 보고
## 손잡이를 움직인다.

@onready var result_label: Label = $ResultLabel

const TRIALS_PER_MONSTER_COMBO := 250
const MAX_EXCHANGES := 120
const ROOM_INDEX := 3

var _combat_script := load("res://code/scenes/combat_test.gd")
## balance_sim.gd의 growth_config_for()/apply_growth()/global_index_for()는 static이지만
## class_name이 없어 인스턴스 경유로 호출한다(씬 트리에 add_child 안 함 — 같은 파일이
## combat_test.gd에 쓰는 패턴과 동일, 클래스 주석 참고).
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

	var monster_ids: Array = MonsterCatalog.normal_roster_ids()
	var per_monster_sum: Dictionary = {}
	var per_monster_count: Dictionary = {}
	for id in monster_ids:
		per_monster_sum[id] = 0.0
		per_monster_count[id] = 0

	print("[R-2 방3 몬스터별 측정] 몬스터 %d종 x 라운드 1~3 x 캐릭터 8종 x %d판 시작" % [monster_ids.size(), TRIALS_PER_MONSTER_COMBO])

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

			for monster_id in monster_ids:
				var win_rate := _simulate_monster(monster_id, round_index)
				per_monster_sum[monster_id] += win_rate
				per_monster_count[monster_id] += 1
				print("%s r%d vs %s: %.1f%%" % [character_id, round_index, monster_id, win_rate * 100.0])

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
	for monster_id in monster_ids:
		var avg: float = per_monster_sum[monster_id] / per_monster_count[monster_id]
		overall_sum += per_monster_sum[monster_id]
		overall_count += per_monster_count[monster_id]
		rows.append({
			"id": monster_id,
			"name": MonsterCatalog.get_by_id(monster_id).get("name", monster_id),
			"avg": avg,
		})
	rows.sort_custom(func(a, b): return a["avg"] < b["avg"])
	var overall_avg: float = overall_sum / overall_count

	var summary_lines: Array[String] = []
	summary_lines.append("")
	summary_lines.append("## R-2 방3 몬스터별 측정 (고정 기록, 2026-10-26)")
	summary_lines.append("")
	summary_lines.append("> [대형 기획 16] R-2 1단계 — `bash scripts/qa_shot.sh balance_room3_species`로")
	summary_lines.append("> 재실행 가능. 17종 전부를 room_index=3(라운드 1~3, difficulty 3/6/9)에서")
	summary_lines.append("> `_build_monster_config()`로 직접 구성해(R-1 측정처럼 셔플 결과에 의존하지")
	summary_lines.append("> 않음) 캐릭터 8종 x 균형 성장 정책 x %d판으로 측정(몬스터당 24개 cell 평균," % TRIALS_PER_MONSTER_COMBO)
	summary_lines.append("> 기존 100판보다 키운 표본). **전체 평균 %.1f%%** — R-1 재측정의 68.7%%(라운드당" % (overall_avg * 100.0))
	summary_lines.append("> 고정 시드로 뽑힌 1종만 반영)와는 조건이 달라(여긴 17종 전부를 동일 비중으로")
	summary_lines.append("> 측정) 직접 비교용 숫자는 아니고, \"아웃라이어가 있는가\"를 보는 참고 표다.")
	summary_lines.append("")
	summary_lines.append("| 몬스터 | 평균 승률 | 편차(전체 평균 대비) |")
	summary_lines.append("|---|---|---|")
	for r in rows:
		summary_lines.append("| %s | %.1f%% | %+.1f%%p |" % [r["name"], r["avg"] * 100.0, (r["avg"] - overall_avg) * 100.0])
	summary_lines.append("")

	_append_to_log("\n".join(summary_lines))

	result_label.text = "[balance_room3_species] 완료 — 몬스터 %d종, 전체 평균 %.1f%%\n최저: %s %.1f%% / 최고: %s %.1f%%" % [
		monster_ids.size(), overall_avg * 100.0,
		rows[0]["name"], rows[0]["avg"] * 100.0,
		rows[rows.size() - 1]["name"], rows[rows.size() - 1]["avg"] * 100.0,
	]
	print(result_label.text)
	for line in summary_lines:
		print(line)


func _simulate_monster(monster_id: String, round_index: int) -> float:
	var difficulty: int = ROOM_INDEX + (round_index - 1) * 3
	var profile: Dictionary = MonsterCatalog.get_by_id(monster_id)
	var monster_name: String = profile.get("name", monster_id)

	var wins := 0
	for _trial in TRIALS_PER_MONSTER_COMBO:
		RunState.gold = 0
		RunState.pip_inventory = []

		var instance = _combat_script.new()
		var config: Dictionary = instance._build_monster_config(profile, monster_name, difficulty, false)
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

	return float(wins) / TRIALS_PER_MONSTER_COMBO


## balance_target_check.gd의 "최신 측정" 교체 방식과 달리, 이 섹션은 "고정 기록"이라
## 재실행마다 끝에 새로 덧붙인다(J-1/R-1 고정 기록 섹션들과 같은 성격 — 교체 금지).
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
		push_error("[balance_room3_species] BALANCE_TUNING_LOG.md 저장 실패: %s" % abs_path)
		return
	file.store_string(body)
	file.close()
