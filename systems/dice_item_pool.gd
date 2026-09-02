class_name DiceItemPool
extends RefCounted
## 전투 승리 보상으로 제시할 다이스 개조 아이템 후보 목록.
##
## DESIGN.md "빌드업(다이스 개조)" 섹션의 예시 3가지를 그대로 구현한 최소 버전이다:
## 특정 면의 값 올리기 / 다이스 교체(면 개수 증가) / 새 다이스 추가.
## 구체적인 아이템 종류·밸런스는 DESIGN.md에 아직 미정이라(다음 할 일 큐 참고) 이 목록은
## 잠정값이다. 아이템은 어느 주머니(공격/방어)에 적용할지 플레이어가 고를 수 있어야
## 한다는 DESIGN.md 규칙에 맞춰, 아이템 자체는 대상 주머니를 미리 정하지 않고
## apply(item, bag) 시점에 넘겨받은 bag에 적용한다.

const ITEMS: Array[Dictionary] = [
	{
		"name": "다이스 추가 (D4)",
		"description": "선택한 주머니에 D4 다이스를 1개 추가합니다.",
		"kind": "add_die",
		"sides": 4,
	},
	{
		"name": "다이스 승급 (가장 작은 다이스 -> D6)",
		"description": "선택한 주머니에서 면 개수가 가장 작은 다이스 1개를 D6으로 교체합니다.",
		"kind": "upgrade_die",
		"new_sides": 6,
	},
	{
		"name": "약한 면 강화",
		"description": "선택한 주머니에서 가장 낮은 면 값 하나를 그 다이스의 최댓값으로 올립니다.",
		"kind": "boost_weak_face",
	},
]


## n개의 서로 다른 아이템을 무작위로 뽑아 반환한다 (목록보다 많이 요청하면 있는 만큼만).
static func random_choices(n: int) -> Array[Dictionary]:
	var items := ITEMS.duplicate(true)
	items.shuffle()
	return items.slice(0, min(n, items.size()))


static func apply(item: Dictionary, bag: DiceBag) -> void:
	match item["kind"]:
		"add_die":
			bag.add_die(item["sides"])
		"upgrade_die":
			var idx := _find_smallest_die(bag)
			if idx >= 0:
				bag.replace_die(idx, item["new_sides"])
		"boost_weak_face":
			_boost_weakest_face(bag)


static func _find_smallest_die(bag: DiceBag) -> int:
	var best_idx := -1
	var best_size := 999999
	for i in bag.dice.size():
		if bag.dice[i].size() < best_size:
			best_size = bag.dice[i].size()
			best_idx = i
	return best_idx


static func _boost_weakest_face(bag: DiceBag) -> void:
	var best_die := -1
	var best_face := -1
	var best_value := 999999
	for di in bag.dice.size():
		var faces: PackedInt32Array = bag.dice[di]
		for fi in faces.size():
			if faces[fi] < best_value:
				best_value = faces[fi]
				best_die = di
				best_face = fi
	if best_die < 0:
		return
	var faces: PackedInt32Array = bag.dice[best_die]
	var max_val: int = faces[0]
	for v in faces:
		max_val = max(max_val, v)
	bag.set_face_value(best_die, best_face, max_val)
