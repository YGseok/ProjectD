class_name EventChallengePool
extends RefCounted
## [대형 기획 14] N-5(b)(INBOX.md 2026-10-15): 특수 이벤트 "안전하게 넘어가기/위험을
## 감수하기" 선택지가 지금까지 단 하나의 상황(보물, event.gd의 기존 EventItemPool
## 직결 흐름)에만 쓰여서, 캐릭터별 event_die_sides 차등(N-5(a), 곡예사 D12)이 체감되는
## 지점이 그 하나뿐이었다. 여기에 도박/탐색/함정 해체 3종을 더해 이벤트 주사위 판정이
## 쓰이는 "상황"을 데이터 표로 늘린다 — event.gd는 이 표의 항목 하나를 방마다 무작위로
## 골라(_ready()) 제목/문구/보상만 바꿔 끼우고, 판정 로직(공용 함수 tier_for_roll()/
## roll_reward())은 종류와 무관하게 전부 공유한다. 새 종류를 추가하려면 CHALLENGES에
## 항목 하나만 늘리면 되고, event.gd/dice_test.gd를 건드릴 필요가 없다(하드코딩 금지
## 원칙).
##
## "대성공"(critical success, INBOX N-5(b) 신규): 굴림값이 DC + CRIT_MARGIN 이상이면
## success_reward 대신 더 좋은 crit_reward를 준다. CRIT_MARGIN은 모든 종류가 공유하는
## 단일 값이라 "큰 다이스일수록 대성공이 쉬워진다"는 효과가 종류별 설정 없이 자동으로
## 성립한다 — 예: DC=5(방 4 이상)일 때 대성공 기준은 8 이상. D6 클래스는 최댓값이
## 6이라 대성공이 "항상 불가능"(0%)인 반면, 곡예사(D12)는 8~12가 유효해 확률이
## (12-8+1)/12 ≈ 41.7%로 의미 있게 열린다 — dice_test.gd의 N-5(b) 확률 비교 검증 참고.
const CRIT_MARGIN := 3

## 보상/패널티 "명세"(spec)의 type별 의미 — roll_reward()가 이 하나의 규칙으로 전부
## 해석한다(challenge id로 분기하지 않음):
##   "item_grade": grades(등급 배열)로 거른 EventItemPool.ITEMS 중 weights 가중 무작위 1개.
##   "gold": min~max 범위의 골드 정수 1개.
##   "pips": min~max 범위의 "개수" 정수 1개(실제 눈금 값 1~6은 호출부가 추첨).
##   "gold_loss": min~max 범위의 골드 손실 정수 1개(실패 패널티 전용 관례, 강제하지 않음).
##   그 외/누락: 아무 효과 없음("none").
const CHALLENGES: Array[Dictionary] = [
	{
		"id": "treasure",
		"subtitle": "안전하게 넘어갈까, 위험을 감수할까?",
		"prompt": "이상한 기운이 느껴지는 방이다. 안전하게 지나칠 것인가, 위험을 무릅쓸 것인가?",
		"safe_reward": {"type": "item_grade", "grades": ["C", "B"], "weights": {"C": 5.0, "B": 1.0}},
		"success_reward": {"type": "item_grade", "grades": ["B", "A", "S"], "weights": {"B": 1.0, "A": 2.0, "S": 3.0}},
		"crit_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 1.0, "S": 2.0}},
		"fail_penalty": {"type": "none"},
	},
	{
		"id": "gambling",
		"subtitle": "적게 걸까, 크게 걸까?",
		"prompt": "뒷골목에서 수상한 도박판이 벌어지고 있다. 적게 걸고 안전하게 뺄 것인가, 크게 걸고 승부를 볼 것인가?",
		"safe_reward": {"type": "gold", "min": 4, "max": 6},
		"success_reward": {"type": "gold", "min": 10, "max": 16},
		"crit_reward": {"type": "gold", "min": 24, "max": 32},
		"fail_penalty": {"type": "gold_loss", "min": 2, "max": 4},
	},
	{
		"id": "exploration",
		"subtitle": "익숙한 길로 갈까, 샛길을 탐색할까?",
		"prompt": "두 갈래 샛길이 보인다. 익숙한 길로 돌아갈 것인가, 낯선 샛길을 탐색해볼 것인가?",
		"safe_reward": {"type": "pips", "min": 1, "max": 2},
		"success_reward": {"type": "pips", "min": 3, "max": 5},
		"crit_reward": {"type": "pips", "min": 7, "max": 9},
		"fail_penalty": {"type": "none"},
	},
	{
		"id": "trap_disarm",
		"subtitle": "돌아갈까, 함정을 해체할까?",
		"prompt": "바닥에 낡은 함정 장치가 보인다. 건드리지 않고 돌아갈 것인가, 해체해서 안에 든 것을 챙길 것인가?",
		"safe_reward": {"type": "pips", "min": 1, "max": 2},
		"success_reward": {"type": "item_grade", "grades": ["B", "A", "S"], "weights": {"B": 2.0, "A": 2.0, "S": 1.0}},
		"crit_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 1.0, "S": 3.0}},
		"fail_penalty": {"type": "gold_loss", "min": 3, "max": 5},
	},
]


## id로 항목을 찾는다. 없으면(설정 실수) 0번(treasure)로 폴백해 빈 Dictionary를 돌려주지
## 않는다 — event.gd의 QA 훅들이 "항상 treasure로 결정적으로 고정"할 때 이 함수를 쓴다.
static func get_challenge(id: String) -> Dictionary:
	for c in CHALLENGES:
		if c["id"] == id:
			return c
	return CHALLENGES[0]


## 공용 판정 함수 — roll/dc만으로 "fail"/"success"/"crit" 중 하나를 결정한다. 종류별
## 하드코딩 없이 전부 이 규칙 하나를 공유한다(CRIT_MARGIN도 공유).
static func tier_for_roll(roll: int, dc: int) -> String:
	if roll >= dc + CRIT_MARGIN:
		return "crit"
	if roll >= dc:
		return "success"
	return "fail"


## roll >= dc(성공, 대성공 포함)가 될 확률 — sides면체 1회 굴림 기준. 이론적 확률이라
## 샘플링 없이 정확하다(dice_test.gd의 D6 vs D12 비교 검증이 그대로 사용).
static func success_probability(dc: int, sides: int) -> float:
	if dc > sides:
		return 0.0
	return float(sides - max(dc, 1) + 1) / float(sides)


## roll >= dc + CRIT_MARGIN(대성공)이 될 확률 — success_probability()와 동일한 이유로
## 이론적 계산.
static func crit_probability(dc: int, sides: int) -> float:
	return success_probability(dc + CRIT_MARGIN, sides)


## spec(보상/패널티 명세)을 한 번 추첨해 결과 payload를 돌려준다. RunState를 직접
## 건드리지 않는 순수 추첨 함수 — 실제 골드/눈금 반영이나 카드 표시는 호출부(event.gd)가
## 결과의 "type"을 보고 담당한다(역시 challenge id가 아니라 type으로 분기).
static func roll_reward(spec: Dictionary) -> Dictionary:
	match String(spec.get("type", "none")):
		"item_grade":
			var grades: Array[String] = []
			for g in spec.get("grades", []):
				grades.append(String(g))
			var pool := EventItemPool.items_of_grade(grades)
			if pool.is_empty():
				pool = EventItemPool.ITEMS
			return {"type": "item", "item": EventItemPool.weighted_pick(pool, spec.get("weights", {}))}
		"gold":
			return {"type": "gold", "amount": randi_range(int(spec.get("min", 0)), int(spec.get("max", 0)))}
		"pips":
			return {"type": "pips", "count": randi_range(int(spec.get("min", 0)), int(spec.get("max", 0)))}
		"gold_loss":
			return {"type": "gold_loss", "amount": randi_range(int(spec.get("min", 0)), int(spec.get("max", 0)))}
		_:
			return {"type": "none"}


## "안전하게 넘어가기" 버튼의 괄호 설명 — spec의 type으로만 분기해 어떤 challenge든
## 추가 코드 없이 자동으로 알맞은 문구를 만든다.
static func reward_blurb(spec: Dictionary) -> String:
	match String(spec.get("type", "none")):
		"item_grade":
			var grade_strs: PackedStringArray = []
			for g in spec.get("grades", []):
				grade_strs.append(String(g))
			return "%s급 무작위 획득" % "/".join(grade_strs)
		"gold":
			return "골드 %d~%d 확정 획득" % [int(spec.get("min", 0)), int(spec.get("max", 0))]
		"pips":
			return "눈금 %d~%d개 확정 획득" % [int(spec.get("min", 0)), int(spec.get("max", 0))]
		_:
			return "없음"
