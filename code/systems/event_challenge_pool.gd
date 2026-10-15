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
		"special_choice": {
			"requires_character": ["enchantress"],
			"label": "매혹의 시선으로 숨은 보물까지 홀린다",
			"description": "매혹사만의 방식 — 안전한 선택지보다 더 좋은 등급의 보물을 확정으로 얻는다.",
			"reward": {"type": "item_grade", "grades": ["B", "A"], "weights": {"B": 1.0, "A": 1.5}},
		},
	},
	{
		"id": "gambling",
		"subtitle": "적게 걸까, 크게 걸까?",
		"prompt": "뒷골목에서 수상한 도박판이 벌어지고 있다. 적게 걸고 안전하게 뺄 것인가, 크게 걸고 승부를 볼 것인가?",
		"safe_reward": {"type": "gold", "min": 4, "max": 6},
		"success_reward": {"type": "gold", "min": 10, "max": 16},
		"crit_reward": {"type": "gold", "min": 24, "max": 32},
		"fail_penalty": {"type": "gold_loss", "min": 2, "max": 4},
		"special_choice": {
			"requires_character": ["novice"],
			"label": "다재다능하게 승부를 가른다",
			"description": "견습 모험가만의 방식 — 안전한 선택지보다 더 큰 골드를 확정으로 얻는다.",
			"reward": {"type": "gold", "min": 10, "max": 14},
		},
	},
	{
		"id": "exploration",
		"subtitle": "익숙한 길로 갈까, 샛길을 탐색할까?",
		"prompt": "두 갈래 샛길이 보인다. 익숙한 길로 돌아갈 것인가, 낯선 샛길을 탐색해볼 것인가?",
		"safe_reward": {"type": "pips", "min": 1, "max": 2},
		"success_reward": {"type": "pips", "min": 3, "max": 5},
		"crit_reward": {"type": "pips", "min": 7, "max": 9},
		"fail_penalty": {"type": "none"},
		"special_choice": {
			"requires_character": ["shieldbearer"],
			"label": "저주의 눈으로 샛길의 함정까지 꿰뚫는다",
			"description": "주술사만의 방식 — 안전한 선택지보다 더 많은 눈금을 확정으로 얻는다.",
			"reward": {"type": "pips", "min": 4, "max": 6},
		},
	},
	{
		"id": "trap_disarm",
		"subtitle": "돌아갈까, 함정을 해체할까?",
		"prompt": "바닥에 낡은 함정 장치가 보인다. 건드리지 않고 돌아갈 것인가, 해체해서 안에 든 것을 챙길 것인가?",
		"safe_reward": {"type": "pips", "min": 1, "max": 2},
		"success_reward": {"type": "item_grade", "grades": ["B", "A", "S"], "weights": {"B": 2.0, "A": 2.0, "S": 1.0}},
		"crit_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 1.0, "S": 3.0}},
		"fail_penalty": {"type": "gold_loss", "min": 3, "max": 5},
		"special_choice": {
			"requires_character": ["explosive"],
			"label": "화약으로 통째로 날려버린다",
			"description": "폭발병만의 방식 — 안전한 선택지보다 훨씬 많은 눈금을 확정으로 얻는다.",
			"reward": {"type": "pips", "min": 5, "max": 7},
		},
	},
	{
		"id": "treasure_map",
		"subtitle": "낡은 보물 지도 — 해적만이 읽을 수 있는 표식이다.",
		"prompt": "선장만이 알아볼 수 있는 해도의 표식이 방 안쪽을 가리킨다. 표식을 따라갈 것인가, 그냥 둘러보고 지나칠 것인가?",
		"only_characters": ["pirate"],
		"safe_reward": {"type": "gold", "min": 6, "max": 10},
		"success_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 2.0, "S": 2.0}},
		"crit_reward": {"type": "item_grade", "grades": ["S"], "weights": {"S": 1.0}},
		"fail_penalty": {"type": "none"},
	},
	{
		"id": "circus_master",
		"subtitle": "서커스 단장의 내기 — 곡예사라면 낯익은 얼굴이다.",
		"prompt": "낯익은 서커스 단장이 그리운 눈빛으로 내기를 건다. '옛 솜씨가 죽지 않았다면, 보여줘 보거라.' 조용히 지나칠 것인가, 묘기를 보여줄 것인가?",
		"only_characters": ["juggler"],
		"safe_reward": {"type": "pips", "min": 2, "max": 3},
		"success_reward": {"type": "item_grade", "grades": ["B", "A", "S"], "weights": {"B": 1.0, "A": 2.0, "S": 2.0}},
		"crit_reward": {"type": "item_grade", "grades": ["S"], "weights": {"S": 1.0}},
		"fail_penalty": {"type": "none"},
	},
	{
		"id": "duel_arena",
		"subtitle": "결투장의 부름 — 광전사의 피가 끓어오른다.",
		"prompt": "싸움을 원하는 거친 외침이 들려온다. 한 걸음 물러설 것인가, 결투에 응할 것인가?",
		"only_characters": ["berserker"],
		"safe_reward": {"type": "gold", "min": 5, "max": 8},
		"success_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 2.0, "S": 1.0}},
		"crit_reward": {"type": "item_grade", "grades": ["S"], "weights": {"S": 1.0}},
		"fail_penalty": {"type": "gold_loss", "min": 2, "max": 4},
	},
	{
		"id": "ancient_oath",
		"subtitle": "오래된 성소의 수호 서약 — 수호자만이 받을 수 있는 맹세다.",
		"prompt": "낡은 성소가 수호자의 기운을 알아보고 조용히 열린다. 그냥 지나칠 것인가, 서약을 받을 것인가?",
		"only_characters": ["guardian"],
		"safe_reward": {"type": "pips", "min": 2, "max": 3},
		"success_reward": {"type": "item_grade", "grades": ["B", "A", "S"], "weights": {"B": 1.0, "A": 2.0, "S": 1.0}},
		"crit_reward": {"type": "item_grade", "grades": ["A", "S"], "weights": {"A": 1.0, "S": 2.0}},
		"fail_penalty": {"type": "none"},
	},
]

## [대형 기획 14] N-6(2026-10-16, INBOX.md "남은 이슈" 최종 조각): 캐릭터 전용
## 이벤트 + 특별 선택지. 두 축 모두 이벤트별/캐릭터별 하드코딩 없이 위 CHALLENGES
## 데이터 표 + 아래 공용 순수 함수만으로 처리한다(N-5(b)가 먼저 세운 패턴 그대로):
##   "only_characters": [id,...]  (challenge 수준, CHALLENGES에 새로 추가) — 비어있지
##     않으면 그 배열에 든 캐릭터에게만 풀에 들어가는 "전용 이벤트"(위 treasure_map/
##     circus_master/duel_arena/ancient_oath 4종).
##   "special_choice": {requires_character, label, description, reward}  (challenge
##     수준, 기존 보물/도박/탐색/함정 해체 4종에 추가) — requires_character에 든
##     캐릭터에게는 "활성"(실행 가능, reward가 그 challenge의 safe_reward보다 같은
##     type 기준으로 더 크다), 그 외 캐릭터에게는 "잠김"(event.gd가 자물쇠 문구로
##     보여주되 pressed를 연결하지 않아 실행되지 않음)으로 렌더링된다.
## 전용 이벤트가 소유 캐릭터의 "위험을 감수하기" 풀에서 기존 공용 챌린지를 대체할
## 확률(INBOX 제안 20~30% 범위) — event.gd가 run_seed+방 번호로 시드한
## RandomNumberGenerator를 pick_challenge()에 넘겨, 같은 런의 같은 방이면 항상 같은
## 결과가 나오게 한다(테스트 전투/QA 시드에서도 재현 가능해야 한다는 지시 반영).
const EXCLUSIVE_EVENT_CHANCE := 0.25

## item_grade 보상의 "기대값" 비교용 등급 점수 — reward_expected_value()가 쓴다.
const GRADE_VALUE := {"C": 1.0, "B": 2.0, "A": 3.0, "S": 4.0}


## challenge의 "전용 이벤트" 소유 캐릭터 목록. 없으면(비전용, 모든 캐릭터 공용) 빈 배열.
static func only_characters(challenge: Dictionary) -> Array:
	return challenge.get("only_characters", [])


static func is_exclusive(challenge: Dictionary) -> bool:
	return not only_characters(challenge).is_empty()


## 모든 캐릭터에게 노출될 수 있는 공용 풀(only_characters가 비어있는 challenge들).
static func common_challenges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in CHALLENGES:
		if only_characters(c).is_empty():
			result.append(c)
	return result


## character_id 전용 challenge 목록(없으면 빈 배열).
static func exclusive_challenges_for(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in CHALLENGES:
		if only_characters(c).has(character_id):
			result.append(c)
	return result


## event.gd._ready()가 쓰는 공용 선택 함수 — "전용 이벤트 대체 여부 + 최종 챌린지
## 선택"까지 전부 rng(호출부가 run_seed+방 번호로 시드해서 넘김) 하나로 결정한다.
## 전용 이벤트가 있든 없든 매번 똑같이 randf() 1회 + randi_range() 1회를 소비해(있으면
## 전용 풀에서, 없으면 공용 풀에서) RNG 소비 패턴이 캐릭터에 따라 달라지지 않는다.
static func pick_challenge(character_id: String, rng: RandomNumberGenerator, exclusive_chance: float = EXCLUSIVE_EVENT_CHANCE) -> Dictionary:
	var exclusives := exclusive_challenges_for(character_id)
	var roll_exclusive := rng.randf()
	if not exclusives.is_empty() and roll_exclusive < exclusive_chance:
		return exclusives[rng.randi_range(0, exclusives.size() - 1)]
	var common := common_challenges()
	return common[rng.randi_range(0, common.size() - 1)]


## challenge에 "특별 선택지"가 있는지.
static func has_special_choice(challenge: Dictionary) -> bool:
	return challenge.has("special_choice") and not challenge["special_choice"].is_empty()


## 특별 선택지를 활성화할 수 있는 캐릭터 목록(없으면 빈 배열).
static func special_choice_requires(challenge: Dictionary) -> Array:
	return challenge.get("special_choice", {}).get("requires_character", [])


static func special_choice_active_for(challenge: Dictionary, character_id: String) -> bool:
	return special_choice_requires(challenge).has(character_id)


## character_id가 "활성" 상태로 가질 수 있는 특별 선택지가 있는 challenge 목록.
static func special_choice_challenges_for(character_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in CHALLENGES:
		if special_choice_active_for(c, character_id):
			result.append(c)
	return result


## 보상 spec의 "기대값"(비교 전용 추정치 — roll_reward()의 실제 추첨 로직과는 무관).
## item_grade는 등급(C~S)을 1~4로 매긴 가중 평균, gold/pips는 min~max의 평균. "특별
## 선택지가 안전한 선택지보다 실제로 크다"를 숫자로 검증하기 위한 것이라, 항상 같은
## type끼리 비교한다는 전제로 설계됐다(각 special_choice.reward는 그 challenge의
## safe_reward와 같은 type을 쓴다 — 데이터 표 작성 시 지킨 관례, 강제 검증은 안 함).
static func reward_expected_value(spec: Dictionary) -> float:
	match String(spec.get("type", "none")):
		"item_grade":
			var weights: Dictionary = spec.get("weights", {})
			var total_w := 0.0
			var total_v := 0.0
			for g in spec.get("grades", []):
				var w: float = float(weights.get(g, 1.0))
				total_w += w
				total_v += w * float(GRADE_VALUE.get(String(g), 0.0))
			return (total_v / total_w) if total_w > 0.0 else 0.0
		"gold", "pips":
			return (float(spec.get("min", 0)) + float(spec.get("max", 0))) / 2.0
		_:
			return 0.0


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
