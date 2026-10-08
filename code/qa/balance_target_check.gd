extends Node2D
## [대형 기획 10] J-1(2026-10-08) — 몬스터 난이도 튜닝 목표 밴드 체크 도구.
##
## INBOX.md 2026-10-08 지시: BALANCE_GROWTH_REPORT.md(F-5c)가 보여준 절벽(일반 방3
## 급락/보스 거의 불가/정예 들쭉날쭉)을 J-2~J-4에서 손잡이를 움직여 완화하기 전에,
## "항목(일반 방0~2/방3/정예/보스) x 라운드별 실제 평균 vs 목표 밴드, 통과/미달/초과"를
## 숫자로 뽑는 체크 도구가 먼저 필요하다 — 이 스크립트가 그 도구다. **균형 정책만
## 판정**(INBOX.md 지시 — 몰빵 2종은 참고용 열로만 보여줌), 재실행 때마다 같은 기준으로
## 비교할 수 있도록 목표 밴드는 상수로 고정한다. 해석/조정은 하지 않고(이 스크립트는
## 숫자만 낸다) J-2/J-3/J-4가 이 표를 보고 실제로 손잡이를 움직인다.
##
## [대형 기획 10] J-2(2026-10-08) 수정 — 원래 이 도구가 쓰는 섹션 이름이 "튜닝 전
## 기준선"이었는데, J-2가 손잡이를 바꾸고 시뮬을 재실행한 뒤 이 도구를 다시 돌리면
## "튜닝 전" 기준선이 매번 "지금(튜닝 후) 상태"로 조용히 덮어써지는 문제가 있었다
## (J-1 기준선인 보스 1.5%가 J-2 1차 시도 후 재실행 한 번으로 사라짐 — 실제로
## BALANCE_TUNING_LOG.md에서 발생함). 그래서 섹션 이름을 "최신 측정"으로 바꿔
## 의미를 맞췄다 — 이 섹션은 항상 "지금 코드/데이터 기준 최신 상태"를 보여주고,
## 변하지 않는 J-1 원본 기준선은 BALANCE_TUNING_LOG.md 맨 위에 손으로 고정해 둔
## 별도 섹션("고정 기록")에 보존한다(이 스크립트는 그 섹션을 건드리지 않음 — 아래
## _append_to_log()가 찾는 헤더 문자열이 다름).
## qa_shot.sh가 "씬을 띄우고 한 프레임 찍는" 구조를 요구하므로(실제 연산은 전부
## _ready()에서 동기적으로 끝남), balance_growth_report.gd와 같은 Node2D+ResultLabel
## 패턴을 그대로 따른다. 재생성: `bash scripts/qa_shot.sh balance_target_check`.

@onready var result_label: Label = $ResultLabel

## 판정 대상은 "균형" 정책뿐 — 몰빵 2종은 참고용 열로만 표에 곁들인다(INBOX.md 지시:
## "균형 정책만 판정(몰빵은 참고용 열로)").
const JUDGED_POLICY := "balanced"
const REFERENCE_POLICIES: Array[String] = ["attack_heavy", "defense_heavy"]

## 목표 밴드(INBOX.md [대형 기획 10] 원문, 균형 성장 정책·8캐릭터 평균·100판 기준).
## [min, max] — 둘 다 포함(>=min and <=max면 통과).
const TARGET_BANDS := {
	"normal_0_2": {"label": "일반 방0~2", "min": 0.85, "max": 1.00},
	"normal_3": {"label": "일반 방3", "min": 0.75, "max": 0.85},
	"elite": {"label": "정예", "min": 0.55, "max": 0.70},
	"boss": {"label": "보스", "min": 0.35, "max": 0.55},
}
## 표시 순서(Dictionary는 순서가 선언 순이지만 명시적으로 고정해 문서가 안정적이게 함).
const CATEGORY_ORDER: Array[String] = ["normal_0_2", "normal_3", "elite", "boss"]

## 추가 지표(참고, 통과 못 해도 실패 아님 — INBOX.md 원문).
const ROUND_TREND_TOLERANCE := 0.05  ## ±5%p
const CHARACTER_OUTLIER_THRESHOLD := 0.15  ## ±15%p


func _ready() -> void:
	var rows := _load_rows()
	if rows.is_empty():
		result_label.text = "[balance_target_check] qa_out/balance_sim_growth_raw.tsv를 읽지 못했습니다."
		push_error("[balance_target_check] TSV load failed")
		return

	var md := _build_markdown(rows)
	_append_to_log(md)

	result_label.text = "[balance_target_check] 완료 — docs/BALANCE_TUNING_LOG.md에 '최신 측정' 섹션 기록 (%d행)" % rows.size()
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


## 한 행이 어느 카테고리(일반 방0~2/방3/정예/보스)에 속하는지. 그 외(없음)는 빈 문자열.
static func _category_for(row: Dictionary) -> String:
	if row["is_elite"]:
		return "elite" if row["room_index"] >= 1 and row["room_index"] <= 3 else ""
	if row["room_index"] >= 0 and row["room_index"] <= 2:
		return "normal_0_2"
	if row["room_index"] == 3:
		return "normal_3"
	if row["room_index"] == 4:
		return "boss"
	return ""


static func _average_win_rate(rows: Array[Dictionary], policy: String, category: String, round_index: int) -> Variant:
	var sum := 0.0
	var count := 0
	for r in rows:
		if r["policy"] != policy:
			continue
		if round_index > 0 and r["round_index"] != round_index:
			continue
		if _category_for(r) != category:
			continue
		sum += r["win_rate"]
		count += 1
	if count == 0:
		return null
	return sum / count


static func _status_for(value: Variant, band: Dictionary) -> String:
	if value == null:
		return "-"
	var v: float = float(value)
	if v < band["min"]:
		return "미달"
	if v > band["max"]:
		return "초과"
	return "통과"


static func _format_cell(value: Variant) -> String:
	if value == null:
		return "-"
	return "%.1f%%" % (float(value) * 100.0)


func _build_markdown(rows: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	lines.append("## 최신 측정 (자동 생성, 재실행마다 이 섹션만 갱신)")
	lines.append("")
	lines.append("> `code/qa/balance_target_check.gd` 생성, `bash scripts/qa_shot.sh")
	lines.append("> balance_target_check`로 재실행 가능. 원자료: `qa_out/")
	lines.append("> balance_sim_growth_raw.tsv`(F-5b, 손잡이를 바꾼 뒤 `bash scripts/qa_shot.sh")
	lines.append("> balance_sim`으로 먼저 재생성할 것). **균형 정책만 판정**하고 공격/방어")
	lines.append("> 몰빵은 참고용 열로만 둔다(INBOX.md [대형 기획 10] 지시). 측정만 하고")
	lines.append("> 해석·조정 제안은 쓰지 않는다 — 조정은 J-2~J-4가 이 표를 보고 진행한다.")
	lines.append("> **이 섹션은 \"지금\" 상태를 보여줄 뿐 고정 기준선이 아니다** — 재실행마다")
	lines.append("> 통째로 교체된다. 변하지 않는 J-1 원본 기준선은 이 파일 맨 위 \"고정 기록\"")
	lines.append("> 섹션 참고, 시도별 변화 추이는 \"J-2 보스 튜닝 시도 로그\" 섹션 참고.")
	lines.append("")
	lines.append("### 목표 밴드 대비 (균형 정책, 라운드별 평균, 8캐릭터 평균)")
	lines.append("")
	lines.append("| 항목 | 목표 밴드 | R1 | R2 | R3 | 전체 평균 | 판정(전체) |")
	lines.append("|---|---|---|---|---|---|---|")
	for category in CATEGORY_ORDER:
		var band: Dictionary = TARGET_BANDS[category]
		var band_text := "%.0f~%.0f%%" % [band["min"] * 100.0, band["max"] * 100.0]
		var r1: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 1)
		var r2: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 2)
		var r3: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 3)
		var overall: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 0)
		lines.append("| %s | %s | %s | %s | %s | %s | %s |" % [
			band["label"], band_text, _format_cell(r1), _format_cell(r2), _format_cell(r3),
			_format_cell(overall), _status_for(overall, band),
		])
	lines.append("")

	lines.append("### 참고용 — 몰빵 정책 열 (판정 대상 아님)")
	lines.append("")
	lines.append("| 항목 | 정책 | R1 | R2 | R3 | 전체 평균 |")
	lines.append("|---|---|---|---|---|---|")
	for category in CATEGORY_ORDER:
		var band: Dictionary = TARGET_BANDS[category]
		for policy in REFERENCE_POLICIES:
			var r1: Variant = _average_win_rate(rows, policy, category, 1)
			var r2: Variant = _average_win_rate(rows, policy, category, 2)
			var r3: Variant = _average_win_rate(rows, policy, category, 3)
			var overall: Variant = _average_win_rate(rows, policy, category, 0)
			lines.append("| %s | %s | %s | %s | %s | %s |" % [
				band["label"], _policy_name(policy), _format_cell(r1), _format_cell(r2),
				_format_cell(r3), _format_cell(overall),
			])
	lines.append("")

	lines.append("### 추가 지표 (참고, 통과 못 해도 실패 아님)")
	lines.append("")
	lines.append("**라운드 경향 (R1>=R2>=R3, 허용오차 ±%.0f%%p, 균형 정책):**" % (ROUND_TREND_TOLERANCE * 100.0))
	lines.append("")
	for category in CATEGORY_ORDER:
		var band: Dictionary = TARGET_BANDS[category]
		var r1: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 1)
		var r2: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 2)
		var r3: Variant = _average_win_rate(rows, JUDGED_POLICY, category, 3)
		lines.append("- %s: %s" % [band["label"], _trend_text(r1, r2, r3)])
	lines.append("")

	lines.append("**캐릭터별 평균 이상치 (전체 평균 ±%.0f%%p 이상 벗어난 캐릭터, 균형 정책, 전체 항목 평균):**" % (CHARACTER_OUTLIER_THRESHOLD * 100.0))
	lines.append("")
	var char_outliers := _character_outliers(rows)
	if char_outliers.is_empty():
		lines.append("(없음)")
	else:
		lines.append("| 캐릭터 | 평균 승률 | 편차 |")
		lines.append("|---|---|---|")
		for entry in char_outliers:
			lines.append("| %s | %s | %+.1f%%p |" % [
				_character_name(entry["character_id"]), _format_cell(entry["avg"]), entry["deviation"] * 100.0,
			])
	lines.append("")

	return "\n".join(lines)


static func _trend_text(r1: Variant, r2: Variant, r3: Variant) -> String:
	if r1 == null or r2 == null or r3 == null:
		return "- (데이터 없음)"
	var v1: float = float(r1)
	var v2: float = float(r2)
	var v3: float = float(r3)
	var ok12 := v1 >= v2 - ROUND_TREND_TOLERANCE
	var ok23 := v2 >= v3 - ROUND_TREND_TOLERANCE
	var verdict := "유지" if (ok12 and ok23) else "위반"
	return "%s (R1 %.1f%% / R2 %.1f%% / R3 %.1f%%)" % [verdict, v1 * 100.0, v2 * 100.0, v3 * 100.0]


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


## 캐릭터별로 균형 정책 전체 행(일반/정예/보스 전부 포함, 참고 카테고리 아닌 것도 포함)의
## win_rate 평균을 내고, 전체(8캐릭터) 평균 대비 ±threshold를 벗어난 캐릭터를 뽑는다.
func _character_outliers(rows: Array[Dictionary]) -> Array[Dictionary]:
	var balanced_rows: Array[Dictionary] = []
	for r in rows:
		if r["policy"] == JUDGED_POLICY:
			balanced_rows.append(r)
	if balanced_rows.is_empty():
		return []

	var overall_sum := 0.0
	for r in balanced_rows:
		overall_sum += r["win_rate"]
	var overall_avg := overall_sum / balanced_rows.size()

	var character_ids: Array[String] = []
	for r in balanced_rows:
		if not character_ids.has(r["character_id"]):
			character_ids.append(r["character_id"])

	var outliers: Array[Dictionary] = []
	for character_id in character_ids:
		var sum := 0.0
		var count := 0
		for r in balanced_rows:
			if r["character_id"] == character_id:
				sum += r["win_rate"]
				count += 1
		if count == 0:
			continue
		var avg := sum / count
		var deviation := avg - overall_avg
		if absf(deviation) >= CHARACTER_OUTLIER_THRESHOLD:
			outliers.append({"character_id": character_id, "avg": avg, "deviation": deviation})
	outliers.sort_custom(func(a, b): return absf(a["deviation"]) > absf(b["deviation"]))
	return outliers


const LATEST_SECTION_HEADER := "## 최신 측정 (자동 생성, 재실행마다 이 섹션만 갱신)"


## docs/BALANCE_TUNING_LOG.md에 이 결과를 "최신 측정" 섹션으로 기록한다. 파일이
## 없으면 새로 만들고(INBOX.md J-1 지시), 있으면 기존 내용 위에 이어 붙인다(덮어쓰지
## 않음 — J-1 고정 기록/J-2 시도 로그 등 사람이 손으로 쌓아가는 다른 섹션은 그대로
## 보존). 다만 "최신 측정" 섹션 자체는 재실행할 때마다 통째로 교체한다(다음 "## "
## 헤더 또는 파일 끝까지) — 이 섹션은 "지금 상태"만 보여주는 자리이기 때문
## (J-2(2026-10-08)에서 섹션 이름을 "튜닝 전 기준선"에서 바꿈 — 원래 이름 그대로
## 뒀다면 J-2가 손잡이를 바꾸고 재실행할 때마다 "튜닝 전" 기준선이 "튜닝 후" 숫자로
## 조용히 덮어써지는 문제가 있었음, 위 클래스 주석 참고).
func _append_to_log(section_md: String) -> void:
	var abs_path := ProjectSettings.globalize_path("res://docs/BALANCE_TUNING_LOG.md")
	var existing := ""
	if FileAccess.file_exists(abs_path):
		var read_file := FileAccess.open(abs_path, FileAccess.READ)
		if read_file != null:
			existing = read_file.get_as_text()
			read_file.close()

	var header := "# BALANCE_TUNING_LOG.md — 몬스터 난이도 튜닝 기록 ([대형 기획 10])\n\n" + \
		"> J-1~J-4 진행 중 \"무엇을 바꿨고 그 결과가 어땠는지\"를 시간순으로 쌓는 로그.\n" + \
		"> 섹션을 덮어쓰지 않고 이어 붙인다 — 맨 위가 가장 오래된 기록(J-1 기준선)이다.\n\n"

	var body: String
	var start := existing.find(LATEST_SECTION_HEADER)
	if start == -1:
		body = existing if not existing.is_empty() else header
		if not body.ends_with("\n"):
			body += "\n"
		body += "\n" + section_md
	else:
		var next_header := existing.find("\n## ", start + LATEST_SECTION_HEADER.length())
		var after := existing.substr(next_header) if next_header != -1 else ""
		body = existing.substr(0, start) + section_md
		if not body.ends_with("\n"):
			body += "\n"
		body += after

	var file := FileAccess.open(abs_path, FileAccess.WRITE)
	if file == null:
		push_error("[balance_target_check] BALANCE_TUNING_LOG.md 저장 실패: %s" % abs_path)
		return
	file.store_string(body)
	file.close()
