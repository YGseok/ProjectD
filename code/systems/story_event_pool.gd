class_name StoryEventPool
extends RefCounted
## "스토리 이벤트" 방 전용 시나리오 후보 목록.
##
## STATUS.md 다음 할 일 큐("스토리/선택형 이벤트 — 전투도 상점도 아닌, 다이스와 무관한
## 텍스트 선택지")를 반영. 상점(shop.gd)/특수 이벤트(event.gd)는 둘 다 결국 DiceItemPool
## 형식의 다이스 아이템을 적용하는 데 반해, 이 방은 다이스를 전혀 건드리지 않고 골드만
## 오가는 순수 텍스트 선택지다 — 세 방 종류가 서로 다른 자원(다이스 구성 vs 골드)을
## 다루도록 의도적으로 분리함.
##
## 시나리오 하나는 title/description과 choice_a/choice_b 두 선택지로 구성된다. 각
## 선택지는 kind로 효과를 정의한다:
## - "none": 아무 효과 없음 (안전한 선택)
## - "delta": amount만큼 골드 증감 (고정값)
## - "gamble": chance 확률로 win만큼 획득, 실패하면 lose만큼 손실
## 골드/확률 값은 감으로 잡은 잠정값 — 사람 피드백 필요.

const SCENARIOS: Array[Dictionary] = [
	{
		"title": "낡은 보물상자",
		"description": "먼지 쌓인 상자를 발견했다. 함정일 수도 있다.",
		"choice_a": {"label": "상자를 연다", "kind": "gamble", "chance": 0.6, "win": 25, "lose": 10},
		"choice_b": {"label": "그냥 지나간다", "kind": "none"},
	},
	{
		"title": "떠돌이 상인",
		"description": "지친 상인이 여비를 빌려달라 부탁한다.",
		"choice_a": {"label": "도와준다 (골드 -10)", "kind": "delta", "amount": -10},
		"choice_b": {"label": "무시한다", "kind": "none"},
	},
	{
		"title": "휴식처",
		"description": "안전해 보이는 공터에서 짐을 정비했다.",
		"choice_a": {"label": "짐을 정비한다 (골드 +5)", "kind": "delta", "amount": 5},
		"choice_b": {"label": "서둘러 지나간다", "kind": "none"},
	},
	{
		"title": "수상한 도박꾼",
		"description": "골드를 걸고 내기를 하자는 낯선 이를 만났다.",
		"choice_a": {"label": "내기를 받는다 (10골드 베팅)", "kind": "gamble", "chance": 0.5, "win": 20, "lose": 10},
		"choice_b": {"label": "거절한다", "kind": "none"},
	},
	{
		"title": "무너진 제단",
		"description": "오래된 제단에 동전을 바치면 소원이 이루어진다는 전설이 있다.",
		"choice_a": {"label": "동전을 바친다 (골드 -5)", "kind": "delta", "amount": -5},
		"choice_b": {"label": "미신을 무시한다", "kind": "none"},
	},
	{
		"title": "숨겨진 샛길",
		"description": "지도에 없는 샛길을 발견했다. 지름길일 수도, 함정일 수도 있다.",
		"choice_a": {"label": "샛길로 들어간다", "kind": "gamble", "chance": 0.5, "win": 15, "lose": 15},
		"choice_b": {"label": "정석대로 간다", "kind": "none"},
	},
	{
		"title": "부상당한 여행자",
		"description": "길가에 쓰러진 여행자가 도움을 요청한다.",
		"choice_a": {"label": "치료해준다 (골드 -8)", "kind": "delta", "amount": -8},
		"choice_b": {"label": "모른 척 지나간다", "kind": "none"},
	},
	{
		"title": "버려진 야영지",
		"description": "누군가 급히 떠난 듯한 야영지에 짐이 흩어져 있다.",
		"choice_a": {"label": "뒤져본다", "kind": "gamble", "chance": 0.55, "win": 18, "lose": 8},
		"choice_b": {"label": "손대지 않는다", "kind": "none"},
	},
]


static func random_scenario() -> Dictionary:
	return SCENARIOS[randi() % SCENARIOS.size()]
