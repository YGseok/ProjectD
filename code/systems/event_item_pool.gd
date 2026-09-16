class_name EventItemPool
extends RefCounted
## "특수 이벤트" 방 전용 아이템 후보 목록.
##
## INBOX.md 피드백("특수한 이벤트에서는 주사위를 늘리는 이벤트를 제공한다. 다면체
## 주사위가 나올 수 있다")을 반영. 상점/전투 보상(DiceItemPool)이 D4->D6 수준의
## 잠정 아이템만 다루던 것과 달리, 여기는 D8/D10/D12/D20처럼 더 큰 다면체를 다룬다.
## apply()는 DiceItemPool.apply()와 동일한 item dict 형식(kind/sides/new_sides)을
## 그대로 쓰므로 로직을 새로 만들지 않고 재사용한다.

## "grade"(S/A/B/C) 배정 기준은 dice_item_pool.gd DiceItemPool.ITEMS 주석 참고 — 같은
## "잠정값" 원칙(면 개수가 클수록 고급)을 그대로 적용.
##
## "flavor" 필드(2026-09-16, INBOX.md [미니 기획 B] 1번)는 1~2문장짜리 상황 설명
## 문구다 — "트랩에 손을 뻗어 D20을 집는다" 같은 상황극이 아직 없다는 간극(DESIGN.md
## "특수 이벤트" 절 참고)을 메운다. item_card_style.gd의 build_card()가 이 필드가
## 있으면 제목 아래(등급 배지 줄 다음, 다이스 미리보기 이미지 전)에 표시한다 — 없으면
## (DiceItemPool.ITEMS처럼) 아무것도 그리지 않으므로 다른 화면(상점/전투 보상)에는
## 영향 없음. 아직 "안전/위험" 선택지 구조([미니 기획 B] 2~3번)는 없어서, 지금은
## "이 아이템을 얻게 된 상황"을 묘사하는 수준에 그친다 — 2~3번이 구현되면 이 문구가
## "위험을 감수하기"를 선택했을 때 보상 카드에 그대로 남아 자연스럽게 이어질 것.
const ITEMS: Array[Dictionary] = [
	{
		"name": "다면체 주사위 획득 (D8)",
		"description": "선택한 주머니에 D8 다이스를 1개 추가합니다.",
		"flavor": "구석에서 낯선 팔각 주사위가 은은하게 빛난다. 조심스레 손을 뻗는다.",
		"kind": "add_die",
		"sides": 8,
		"grade": "B",
	},
	{
		"name": "다면체 주사위 획득 (D12)",
		"description": "선택한 주머니에 D12 다이스를 1개 추가합니다.",
		"flavor": "제단 위에 놓인 정교한 다면체 주사위가 눈길을 끈다. 값을 매길 수 없어 보인다.",
		"kind": "add_die",
		"sides": 12,
		"grade": "A",
	},
	{
		"name": "다이스 대승급 (-> D10)",
		"description": "D10 다이스 1개를 인벤토리로 획득합니다. 커스터마이징에서 원하는 다이스와 나중에 교체할 수 있습니다.",
		"flavor": "정체 모를 상인이 다듬어진 주사위 하나를 건넨다. \"이걸로 바꿔보게.\"",
		"kind": "upgrade_die",
		"new_sides": 10,
		"grade": "A",
	},
	{
		"name": "다면체 주사위 획득 (D20)",
		"description": "선택한 주머니에 D20 다이스를 1개 추가합니다.",
		"flavor": "번쩍이는 결정 조각 안에 스무 개의 면이 새겨진 주사위가 갇혀 있다.",
		"kind": "add_die",
		"sides": 20,
		"grade": "S",
	},
	{
		"name": "눈금 주머니 획득",
		"description": "눈금 3~5개를 한 번에 인벤토리에 추가합니다. 커스터마이징에서 원하는 다이스에 나중에 사용할 수 있습니다.",
		"flavor": "바닥에 흩어진 작은 눈금 조각들을 주머니 가득 쓸어 담는다.",
		"kind": "gain_pips",
		"pip_min": 3,
		"pip_max": 5,
		"grade": "C",
	},
]


## n개의 서로 다른 아이템을 무작위로 뽑아 반환한다 (목록보다 많이 요청하면 있는 만큼만).
##
## attack_bag/defense_bag은 systems/dice_item_pool.gd의 DiceItemPool.random_choices()와
## 같은 시그니처를 맞추기 위해 남겨뒀다 — DiceItemPool.is_applicable()이 이제 항상
## true를 반환하므로(다이스 승급류가 즉시 적용 대신 인벤토리 획득으로 바뀌어 "대상 없음"
## 개념 자체가 사라짐, 2026-09-09) 실질적인 필터링 효과는 없다. 두 인자를 생략해도
## 결과는 동일하다.
static func random_choices(n: int, attack_bag: DiceBag = null, defense_bag: DiceBag = null) -> Array[Dictionary]:
	var items := ITEMS.duplicate(true)
	if attack_bag != null and defense_bag != null:
		var applicable: Array[Dictionary] = []
		for item in items:
			if DiceItemPool.is_applicable(item, attack_bag) or DiceItemPool.is_applicable(item, defense_bag):
				applicable.append(item)
		if applicable.size() >= n:
			items = applicable
	items.shuffle()
	return items.slice(0, min(n, items.size()))
