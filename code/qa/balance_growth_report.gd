extends Node2D
## [대형 기획 7] F-5(c)(2026-10-08) — docs/BALANCE_GROWTH_REPORT.md 생성기.
##
## F-5(b)가 저장한 qa_out/balance_sim_growth_raw.tsv(576행, 캐릭터 8종 x 시작 스킬
## 슬롯0 고정 x 정책 3종(balanced/attack_heavy/defense_heavy) x {라운드1~3 x
## 방0~4(일반, 방4=보스) + 방1~3(정예)})을 읽어 "global index(지금까지 치른 전투
## 수, 0~14)별 승률 곡선"으로 정리한다. INBOX.md F-5(c) 지시대로 **측정/집계만
## 하고 해석·조정 제안은 쓰지 않는다** — 이 스크립트는 산술 집계 함수만 갖는다.
##
## qa_shot.sh가 "씬을 띄우고 한 프레임 찍는" 구조를 요구하므로(실제 연산은 전부
## _ready()에서 동기적으로 끝남), balance_report.gd와 같은 Node2D+ResultLabel
## 패턴을 그대로 따른다. 재생성: `bash scripts/qa_shot.sh balance_growth_report`.

@onready var result_label: Label = $ResultLabel

## 정예는 방 1~3(첫/마지막 방 제외)에서만 노출되므로, global index도 그 방에
## 해당하는 값만 존재한다. 라운드/방 범위(라운드 1~3 x 방0~4, TOTAL_ROOMS=5)에서
## 직접 계산 — balance_sim.gd의 global_index_for()와 같은 공식(= (round-1)*
## TOTAL_ROOMS + room)을 범위 전체에 펼친 것.
static func _elite_global_indices() -> Array[int]:
	var result: Array[int] = []
	for round_index in range(1, RunState.TOTAL_ROUNDS + 1):
		for room_index in range(1, RunState.TOTAL_ROOMS - 1):
			result.append((round_index - 1) * RunState.TOTAL_ROOMS + room_index)
	return result


## global index -> "R%d·방%d(보스)" 같은 표시용 라벨.
static func _index_label(global_index: int) -> String:
	var round_index := int(global_index / RunState.TOTAL_ROOMS) + 1
	var room_index := global_index % RunState.TOTAL_ROOMS
	var tag := "(보스)" if room_index == RunState.TOTAL_ROOMS - 1 else ""
	return "R%d방%d%s" % [round_index, room_index, tag]


func _ready() -> void:
	var rows := _load_rows()
	if rows.is_empty():
		result_label.text = "[balance_growth_report] qa_out/balance_sim_growth_raw.tsv를 읽지 못했습니다."
		push_error("[balance_growth_report] TSV load failed")
		return

	var policies: Array[String] = []
	for row in rows:
		if not policies.has(row["policy"]):
			policies.append(row["policy"])

	var md := _build_markdown(rows, policies)
	_save_report(md)

	result_label.text = "[balance_growth_report] 완료 — docs/BALANCE_GROWTH_REPORT.md 저장 (%d행, 정책 %d종)" % [rows.size(), policies.size()]
	print(result_label.text)


func _load_rows() -> Array[Dictionary]:
	var abs_path := ProjectSettings.globalize_path("res://qa_out/balance_sim_growth_raw.tsv")
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
		row["global_index"] = int(row["global_index"])
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


func _character_name(character_id: String) -> String:
	return CharacterProfiles.get_profile(character_id).get("name", character_id)


func _policy_name(policy: String) -> String:
	match policy:
		"balanced":
			return "균형"
		"attack_heavy":
			return "공격 몰빵"
		"defense_heavy":
			return "방어 몰빵"
		_:
			return policy


## (policy, character_id, global_index, is_elite) 정확히 일치하는 행 하나를 찾는다.
## 없으면 빈 Dictionary.
func _find_row(rows: Array[Dictionary], policy: String, character_id: String, global_index: int, is_elite: bool) -> Dictionary:
	for r in rows:
		if r["policy"] == policy and r["character_id"] == character_id and r["global_index"] == global_index and r["is_elite"] == is_elite:
			return r
	return {}


## 정책 평균 곡선: 같은 (policy, global_index, is_elite)에서 캐릭터 전원의
## win_rate를 평균. 정예는 해당 global index에만 존재(캐릭터 수만큼의 표본).
func _average_win_rate(rows: Array[Dictionary], policy: String, global_index: int, is_elite: bool) -> Variant:
	var sum := 0.0
	var count := 0
	for r in rows:
		if r["policy"] == policy and r["global_index"] == global_index and r["is_elite"] == is_elite:
			sum += r["win_rate"]
			count += 1
	if count == 0:
		return null
	return sum / count


func _format_cell(value: Variant) -> String:
	if value == null:
		return "-"
	return "%.1f%%" % (float(value) * 100.0)


## global index 0~14를 열로 삼은 한 줄짜리 "곡선" 표를 만든다. get_value(gi)가
## null을 돌려주면 "-"로 표시(정예가 없는 index 등).
func _curve_table(row_labels: Array[String], get_value_funcs: Array[Callable]) -> Array[String]:
	var lines: Array[String] = []
	var header_cells: Array[String] = ["구간"]
	for gi in range(15):
		header_cells.append(_index_label(gi))
	lines.append("| " + " | ".join(header_cells) + " |")
	lines.append("|" + "---|".repeat(header_cells.size()))
	for i in row_labels.size():
		var cells: Array[String] = [row_labels[i]]
		for gi in range(15):
			cells.append(_format_cell(get_value_funcs[i].call(gi)))
		lines.append("| " + " | ".join(cells) + " |")
	return lines


func _build_markdown(rows: Array[Dictionary], policies: Array[String]) -> String:
	var elite_indices := _elite_global_indices()
	var lines: Array[String] = []

	lines.append("# F-5(c) 성장 정책 밸런스 리포트")
	lines.append("")
	lines.append("> 자동 생성 문서(`code/qa/balance_growth_report.gd`, `bash scripts/qa_shot.sh")
	lines.append("> balance_growth_report`로 재생성 가능). 원자료: `qa_out/")
	lines.append("> balance_sim_growth_raw.tsv`(F-5b, %d행). 측정/집계만 하고 해석·조정" % rows.size())
	lines.append("> 제안은 쓰지 않는다(INBOX.md F-5c 지시) — 조정은 이 숫자를 보고 사람이")
	lines.append("> 판단한다.")
	lines.append("")
	lines.append("## 성장 가정")
	lines.append("")
	lines.append("아이템 없이 시작 구성 그대로만 보는 F-4 기준선(`docs/BALANCE_REPORT.md`)과")
	lines.append("달리, 이 리포트는 \"런 중 실제로 강해지면 후반 난이도 절벽이 완화되는가\"를")
	lines.append("보려고 전투 직전 주머니를 \"지금까지 몇 번째 전투인가\"(global index =")
	lines.append("(라운드-1) x %d + 방번호, 0~14)에 따라 단순 규칙으로 키운다. 정책은 3종 —" % RunState.TOTAL_ROOMS)
	lines.append("**균형**(전투 2번마다 공격/방어 다이스를 번갈아 +1개), **공격 몰빵**")
	lines.append("(전투 2번마다 공격만 +1개), **방어 몰빵**(전투 2번마다 방어만 +1개) —")
	lines.append("세 정책 모두 `DiceBag.MAX_DICE`(6)에서 그 주머니의 개수 성장이 멈춘다.")
	lines.append("다이스 면 개수는 세 정책 공통으로 global index 5부터 D4->D6, 10부터")
	lines.append("D8로 승급한다(\"한 라운드에 아이템 3~4개 얻는 정도의 성장\"이라는 가정 —")
	lines.append("실제 상점/보상 픽과 완전히 같을 필요는 없음). 시작 스킬은 캐릭터별")
	lines.append("**슬롯 0만** 고정 부여(정책 효과만 보기 위해 스킬 변수를 고정) — F-4")
	lines.append("기준선처럼 매 trial마다 골드/눈금 인벤토리는 0/빈 배열로 초기화한다.")
	lines.append("")
	lines.append("## 시뮬 조건 (재현용)")
	lines.append("")
	lines.append("- 캐릭터 8종 x 시작 스킬 슬롯 0 x 정책 3종(균형/공격 몰빵/방어 몰빵) x")
	lines.append("  {라운드 1~3 x 방 0~4(일반, 방4=보스) + 라운드 1~3 x 방 1~3(정예)} =")
	lines.append("  %d개 조합 x 100판/조합 (전투 %d판)." % [rows.size(), rows.size() * 100])
	lines.append("- 몬스터 배정 시드는 F-4b와 동일(`FIXED_PLAN_SEED=20261007`, 정예는")
	lines.append("  `+104729`)로 고정 — 기준선과 같은 라운드별 몬스터를 상대한다.")
	lines.append("- 다이스 굴림(RNG)은 조합마다 100판 독립적으로 다시 굴림 — 재실행하면")
	lines.append("  수치는 소폭 달라질 수 있다(시드 고정 대상이 아님).")
	lines.append("- 교환 120회(`MAX_EXCHANGES`)를 넘기면 타임아웃으로 집계(승리/패배 아님).")
	lines.append("")

	# --- 정책별 평균 곡선 ---
	lines.append("## 정책별 평균 곡선 (글로벌 인덱스 0~14, 캐릭터 8종 평균)")
	lines.append("")
	for policy in policies:
		lines.append("### %s" % _policy_name(policy))
		lines.append("")
		var normal_fn := func(gi: int): return _average_win_rate(rows, policy, gi, false)
		var elite_fn := func(gi: int): return _average_win_rate(rows, policy, gi, true)
		for line in _curve_table(["일반 평균승률", "정예 평균승률"], [normal_fn, elite_fn]):
			lines.append(line)
		lines.append("")

	# --- 정책x캐릭터별 상세 곡선 ---
	lines.append("## 정책x캐릭터별 승률 곡선 (글로벌 인덱스 0~14)")
	lines.append("")
	for policy in policies:
		lines.append("### 정책: %s" % _policy_name(policy))
		lines.append("")
		for profile in CharacterProfiles.PROFILES:
			var character_id: String = profile["id"]
			var has_any := rows.any(func(r): return r["policy"] == policy and r["character_id"] == character_id)
			if not has_any:
				continue
			lines.append("**%s** (`%s`)" % [_character_name(character_id), character_id])
			lines.append("")
			var normal_fn := func(gi: int):
				var r := _find_row(rows, policy, character_id, gi, false)
				return r["win_rate"] if not r.is_empty() else null
			var elite_fn := func(gi: int):
				var r := _find_row(rows, policy, character_id, gi, true)
				return r["win_rate"] if not r.is_empty() else null
			for line in _curve_table(["일반 승률", "정예 승률"], [normal_fn, elite_fn]):
				lines.append(line)
			lines.append("")

	# --- 라운드 경계 / 보스 직전·직후 낙폭 ---
	lines.append("## 라운드 경계 / 보스 직전·직후 구간의 낙폭 (정책별 평균 곡선 기준)")
	lines.append("")
	lines.append("| 정책 | 구간 | 승률(이전) | 승률(이후) | 낙폭(%p) |")
	lines.append("|---|---|---|---|---|")
	var boundary_pairs := [
		[3, 4, "R1 방3 -> R1 보스(방4)"],
		[4, 5, "R1 보스(방4) -> R2 방0"],
		[8, 9, "R2 방3 -> R2 보스(방4)"],
		[9, 10, "R2 보스(방4) -> R3 방0"],
		[13, 14, "R3 방3 -> R3 보스(방4)"],
	]
	for policy in policies:
		for pair in boundary_pairs:
			var from_gi: int = pair[0]
			var to_gi: int = pair[1]
			var label: String = pair[2]
			var from_rate = _average_win_rate(rows, policy, from_gi, false)
			var to_rate = _average_win_rate(rows, policy, to_gi, false)
			if from_rate == null or to_rate == null:
				continue
			var drop := (float(to_rate) - float(from_rate)) * 100.0
			lines.append("| %s | %s | %s | %s | %+.1f |" % [
				_policy_name(policy), label, _format_cell(from_rate), _format_cell(to_rate), drop,
			])
	lines.append("")
	lines.append("(정예 global index: %s — 방 1~3에서만 존재하므로 보스 경계 낙폭 표에는" % str(elite_indices))
	lines.append("포함하지 않음.)")

	return "\n".join(lines)


func _save_report(md: String) -> void:
	var abs_path := ProjectSettings.globalize_path("res://docs/BALANCE_GROWTH_REPORT.md")
	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_growth_report] BALANCE_GROWTH_REPORT.md 저장 실패: %s" % abs_path)
		return
	file.store_string(md)
	file.close()
