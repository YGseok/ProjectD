class_name EventItemPool
extends RefCounted
## "특수 이벤트" 방 전용 아이템 후보 목록.
##
## INBOX.md 피드백("특수한 이벤트에서는 주사위를 늘리는 이벤트를 제공한다. 다면체
## 주사위가 나올 수 있다")을 반영. 상점/전투 보상(DiceItemPool)이 D4->D6 수준의
## 잠정 아이템만 다루던 것과 달리, 여기는 D8/D10/D12처럼 더 큰 다면체를 다룬다.
## apply()는 DiceItemPool.apply()와 동일한 item dict 형식(kind/sides/new_sides)을
## 그대로 쓰므로 로직을 새로 만들지 않고 재사용한다.

const ITEMS: Array[Dictionary] = [
	{
		"name": "다면체 주사위 획득 (D8)",
		"description": "선택한 주머니에 D8 다이스를 1개 추가합니다.",
		"kind": "add_die",
		"sides": 8,
	},
	{
		"name": "다면체 주사위 획득 (D12)",
		"description": "선택한 주머니에 D12 다이스를 1개 추가합니다.",
		"kind": "add_die",
		"sides": 12,
	},
	{
		"name": "다이스 대승급 (가장 작은 다이스 -> D10)",
		"description": "선택한 주머니에서 면 개수가 가장 작은 다이스 1개를 D10으로 교체합니다.",
		"kind": "upgrade_die",
		"new_sides": 10,
	},
]


## n개의 서로 다른 아이템을 무작위로 뽑아 반환한다 (목록보다 많이 요청하면 있는 만큼만).
static func random_choices(n: int) -> Array[Dictionary]:
	var items := ITEMS.duplicate(true)
	items.shuffle()
	return items.slice(0, min(n, items.size()))
