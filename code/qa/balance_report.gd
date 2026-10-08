extends Node2D
## [대형 기획 5] F-4c(2026-10-08) — docs/BALANCE_REPORT.md 생성기.
##
## F-4b가 저장한 qa_out/balance_sim_raw.tsv(504행, 캐릭터 7종 x 시작 스킬 슬롯 3개 x
## {라운드1~3 x 방0~4(일반) + 라운드1~3 x 방1~3(정예)})을 읽어 표로 정리하고, 전체
## 평균 승률 대비 ±15%p 이상 벗어난 조합을 이상치로 뽑는다. INBOX.md F-4c 지시대로
## **측정/집계만 하고 해석·조정 제안은 쓰지 않는다** — 이 스크립트는 산술 집계
## 함수만 갖고, "왜 이런 수치가 나왔는지"는 전혀 판단하지 않는다.
##
## qa_shot.sh가 "씬을 띄우고 한 프레임 찍는" 구조를 요구하므로(실제 연산은 전부
## _ready()에서 동기적으로 끝남), balance_sim.gd와 같은 Node2D+ResultLabel 패턴을
## 그대로 따른다. 재생성: `bash scripts/qa_shot.sh balance_report`.

@onready var result_label: Label = $ResultLabel

const OUTLIER_THRESHOLD := 0.15  ## 15%p


func _ready() -> void:
	var rows := _load_rows()
	if rows.is_empty():
		result_label.text = "[balance_report] qa_out/balance_sim_raw.tsv를 읽지 못했습니다."
		push_error("[balance_report] TSV load failed")
		return

	var overall_avg := _average(rows, "win_rate")
	var outliers := _find_outliers(rows, overall_avg)
	var md := _build_markdown(rows, overall_avg, outliers)
	_save_report(md)

	result_label.text = "[balance_report] 완료 — docs/BALANCE_REPORT.md 저장 (%d개 조합, 전체 평균 승률 %.1f%%, 이상치 %d개)" % [rows.size(), overall_avg * 100.0, outliers.size()]
	print(result_label.text)


func _load_rows() -> Array[Dictionary]:
	var abs_path := ProjectSettings.globalize_path("res://qa_out/balance_sim_raw.tsv")
	var file := FileAccess.open(abs_path, FileAccess.READ)
	if file == null:
		return []
	var header := file.get_line().split("\t")
	var rows: Array[Dictionary] = []
	while not file.eof_reached():
		var line := file.get_line()
		if line.is_empty():
			continue
		var cols := line.split("\t")
		if cols.size() != header.size():
			continue
		var row: Dictionary = {}
		for i in header.size():
			row[header[i]] = cols[i]
		row["round_index"] = int(row["round_index"])
		row["room_index"] = int(row["room_index"])
		row["is_elite"] = row["is_elite"] == "true"
		row["trials"] = int(row["trials"])
		row["wins"] = int(row["wins"])
		row["timeouts"] = int(row["timeouts"])
		row["win_rate"] = float(row["win_rate"])
		row["avg_turns"] = float(row["avg_turns"])
		row["avg_hp_on_win"] = float(row["avg_hp_on_win"])
		rows.append(row)
	file.close()
	return rows


func _average(rows: Array, key: String) -> float:
	if rows.is_empty():
		return 0.0
	var sum := 0.0
	for row in rows:
		sum += row[key]
	return sum / rows.size()


func _find_outliers(rows: Array[Dictionary], overall_avg: float) -> Array[Dictionary]:
	var outliers: Array[Dictionary] = []
	for row in rows:
		var deviation: float = row["win_rate"] - overall_avg
		if absf(deviation) >= OUTLIER_THRESHOLD:
			var tagged := row.duplicate()
			tagged["deviation"] = deviation
			outliers.append(tagged)
	outliers.sort_custom(func(a, b): return absf(a["deviation"]) > absf(b["deviation"]))
	return outliers


func _character_name(character_id: String) -> String:
	return CharacterProfiles.get_profile(character_id).get("name", character_id)


func _skill_name(skill_id: String) -> String:
	var skill := SkillPool.find_skill(skill_id)
	return skill.get("name", skill_id) if not skill.is_empty() else skill_id


func _build_markdown(rows: Array[Dictionary], overall_avg: float, outliers: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	lines.append("# F-4c 밸런스 리포트")
	lines.append("")
	lines.append("> 자동 생성 문서(`code/qa/balance_report.gd`, `bash scripts/qa_shot.sh")
	lines.append("> balance_report`로 재생성 가능). 원자료: `qa_out/balance_sim_raw.tsv`")
	lines.append("> (F-4b, 504개 조합 x 100판). 측정/집계만 하고 해석·조정 제안은 쓰지")
	lines.append("> 않는다(INBOX.md F-4c 지시) — 조정은 이 숫자를 보고 사람이 판단한다.")
	lines.append("")
	lines.append("## 시뮬 조건 (재현용)")
	lines.append("")
	lines.append("- 캐릭터 7종 x 시작 스킬 슬롯 3개(해금 가정, 전부 부여) x {라운드 1~3 x 방")
	lines.append("  0~4(일반, 방4=보스) + 라운드 1~3 x 방 1~3(정예)} = %d개 조합 x 100판/조합" % rows.size())
	lines.append("  (전투 %d판)." % (rows.size() * 100))
	lines.append("- 몬스터 배정은 `FIXED_PLAN_SEED=20261007`(정예는 `+104729`)로 고정 — 모든")
	lines.append("  캐릭터x스킬 조합이 같은 라운드별 몬스터를 상대한다(공정 비교용).")
	lines.append("- 다이스 굴림(RNG)은 조합마다 100판 독립적으로 다시 굴림 — 재실행하면 승률")
	lines.append("  등 수치는 소폭 달라질 수 있다(시드 고정 대상이 아님).")
	lines.append("- 아이템/상점 없이 \"시작 구성 그대로\"의 기준선만 측정(매 trial마다 골드/")
	lines.append("  눈금 인벤토리를 초기화).")
	lines.append("- 교환 120회(`MAX_EXCHANGES`)를 넘기면 타임아웃으로 집계(승리/패배 아님).")
	lines.append("")
	lines.append("## 전체 평균 (%d개 조합)" % rows.size())
	lines.append("")
	lines.append("- 평균 승률: **%.2f%%**" % (overall_avg * 100.0))
	lines.append("- 평균 턴수: %.2f" % _average(rows, "avg_turns"))
	lines.append("- 평균 승리 시 HP: %.2f" % _average(rows, "avg_hp_on_win"))
	lines.append("- 이상치 기준: 전체 평균 승률 대비 **±15%p**(= ±0.15) 이상 벗어난 조합")
	lines.append("")
	lines.append("## 이상치 목록 (%d개)" % outliers.size())
	lines.append("")
	if outliers.is_empty():
		lines.append("(없음)")
	else:
		lines.append("| 캐릭터 | 스킬 | 라운드 | 방 | 유형 | 몬스터 | 승률 | 편차 |")
		lines.append("|---|---|---|---|---|---|---|---|")
		for row in outliers:
			lines.append("| %s | %s | %d | %d | %s | %s | %.1f%% | %+.1f%%p |" % [
				_character_name(row["character_id"]), _skill_name(row["skill_id"]),
				row["round_index"], row["room_index"],
				"정예" if row["is_elite"] else "일반", row["monster_name"],
				row["win_rate"] * 100.0, row["deviation"] * 100.0,
			])
	lines.append("")
	lines.append("## 캐릭터별 상세 표 (캐릭터 x 시작 스킬 x 방)")
	lines.append("")

	for profile in CharacterProfiles.PROFILES:
		var character_id: String = profile["id"]
		var char_rows: Array = rows.filter(func(r): return r["character_id"] == character_id)
		if char_rows.is_empty():
			continue
		lines.append("### %s (`%s`)" % [_character_name(character_id), character_id])
		lines.append("")
		lines.append("| 스킬 | 라운드 | 방 | 유형 | 몬스터 | 승률 | 평균턴 | 승리시평균HP | 타임아웃 |")
		lines.append("|---|---|---|---|---|---|---|---|---|")
		var skill_ids: Array[String] = []
		for r in char_rows:
			if not skill_ids.has(r["skill_id"]):
				skill_ids.append(r["skill_id"])
		for skill_id in skill_ids:
			for round_index in range(1, 4):
				for room_index in range(5):
					var normal_row := _find_row(char_rows, skill_id, round_index, room_index, false)
					if not normal_row.is_empty():
						lines.append(_table_row(_skill_name(skill_id), normal_row))
					if room_index >= 1 and room_index <= 3:
						var elite_row := _find_row(char_rows, skill_id, round_index, room_index, true)
						if not elite_row.is_empty():
							lines.append(_table_row(_skill_name(skill_id), elite_row))
		lines.append("")

	return "\n".join(lines)


func _find_row(rows: Array, skill_id: String, round_index: int, room_index: int, is_elite: bool) -> Dictionary:
	for r in rows:
		if r["skill_id"] == skill_id and r["round_index"] == round_index and r["room_index"] == room_index and r["is_elite"] == is_elite:
			return r
	return {}


func _table_row(skill_name: String, row: Dictionary) -> String:
	var timeout_text := ("%d" % row["timeouts"]) if row["timeouts"] > 0 else "-"
	return "| %s | %d | %d | %s | %s | %.1f%% | %.1f | %.1f | %s |" % [
		skill_name, row["round_index"], row["room_index"],
		"정예" if row["is_elite"] else "일반", row["monster_name"],
		row["win_rate"] * 100.0, row["avg_turns"], row["avg_hp_on_win"], timeout_text,
	]


func _save_report(md: String) -> void:
	var abs_path := ProjectSettings.globalize_path("res://docs/BALANCE_REPORT.md")
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_report] BALANCE_REPORT.md 저장 실패: %s" % abs_path)
		return
	file.store_string(md)
	file.close()
