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
		"name": "다이스 승급 (-> D6)",
		"description": "D6 다이스 1개를 인벤토리로 획득합니다. 커스터마이징에서 원하는 다이스와 나중에 교체할 수 있습니다.",
		"kind": "upgrade_die",
		"new_sides": 6,
	},
	{
		"name": "약한 면 강화",
		"description": "선택한 주머니에서 가장 낮은 면 값 하나를 그 다이스의 최댓값으로 올립니다.",
		"kind": "boost_weak_face",
	},
	{
		"name": "모든 면 통일 (최댓값)",
		"description": "선택한 주머니에서 가장 개선이 필요한 다이스 1개를 골라, 그 다이스의 모든 면을 최댓값으로 맞춥니다.",
		"kind": "uniform_faces",
	},
]


## n개의 서로 다른 아이템을 무작위로 뽑아 반환한다 (목록보다 많이 요청하면 있는 만큼만).
##
## attack_bag/defense_bag을 넘기면 두 주머니 모두에 적용 불가능한 아이템(2026-09-09부터는
## "add_die"인데 두 주머니가 전부 MAX_DICE 캡에 도달한 경우가 해당)은 후보에서 우선
## 제외한다 — 부족해지면(applicable.size() < n) 원래 목록으로 폴백해 빈 슬롯이 생기지
## 않게 한다(2026-09-07 도입 패턴 그대로 유지). 두 인자를 생략하면 필터링 없이 전체
## 목록에서 뽑는다.
static func random_choices(n: int, attack_bag: DiceBag = null, defense_bag: DiceBag = null) -> Array[Dictionary]:
	var items := ITEMS.duplicate(true)
	if attack_bag != null and defense_bag != null:
		var applicable: Array[Dictionary] = []
		for item in items:
			if is_applicable(item, attack_bag) or is_applicable(item, defense_bag):
				applicable.append(item)
		if applicable.size() >= n:
			items = applicable
	items.shuffle()
	return items.slice(0, min(n, items.size()))


static func apply(item: Dictionary, bag: DiceBag) -> void:
	match item["kind"]:
		"add_die":
			if bag.is_full():
				return
			bag.add_die(item["sides"])
		"boost_weak_face":
			_boost_weakest_face(bag)
		"uniform_faces":
			_uniformize_worst_die(bag)
		# "upgrade_die"는 여기서 다루지 않는다 — apply_upgrade_gain() 참고.


## "다이스 승급"류 아이템(kind=upgrade_die) 전용 획득 함수. INBOX.md 피드백
## (2026-09-09) "다이스 승급 이벤트에서, 면 개수가 가장 작은것 교체가 아닌 획득으로
## 바꾼다. ... 인벤토리로 들어와서 교체하도록 한다"를 반영해, 예전처럼 apply(item, bag)로
## 즉시 어느 주머니의 어느 다이스를 자동으로 골라 교체하지 않는다. 대신 RunState.
## die_inventory(정수 "면 개수" 목록)에 새 다이스 하나를 쌓아두기만 하고, 실제로 어느
## 주머니의 어느 슬롯과 바꿀지는 code/scenes/customize_panel.gd에서 플레이어가 나중에
## 직접 고른다. bag을 필요로 하지 않으므로(어느 주머니 것도 아직 아님) apply(item, bag)와
## 달리 대상 주머니 인자가 없다 — 항상 성공하므로 is_applicable() 대상도 아니다.
static func apply_upgrade_gain(item: Dictionary) -> void:
	RunState.die_inventory.append(item["new_sides"])


## item이 bag에 적용했을 때 실제 효과가 있는지 확인한다. boost_weak_face/uniform_faces는
## 주머니에 다이스가 하나라도 있으면(항상 그렇다) 언제나 효과가 있으므로 항상 true.
## upgrade_die는 더 이상 bag에 즉시 적용되지 않고(항상 인벤토리로 획득되기만 하므로,
## apply_upgrade_gain() 참고) 대상 유무와 무관하게 항상 획득 가능. add_die만 예외 —
## 2026-09-09부터 DiceBag.MAX_DICE 캡이 생겨(성장 방식을 "계속 늘어남"에서 "고정 풀 안
## 교체"로 바꾸는 첫 조각, INBOX.md 참고) bag이 이미 캡에 도달했으면 더 넣을 자리가
## 없으므로 false.
static func is_applicable(item: Dictionary, bag: DiceBag) -> bool:
	if item.get("kind", "") == "add_die":
		return not bag.is_full()
	return true


## is_applicable()이 false일 때 버튼에 보여줄 이유 문구. add_die는 "승급 대상 없음"이
## 의미가 안 맞아(승급이 아니라 추가 아이템이므로) 별도 문구가 필요해서 분리했다.
static func unavailable_reason(item: Dictionary) -> String:
	if item.get("kind", "") == "add_die":
		return "주머니 가득 참 (최대 %d개)" % DiceBag.MAX_DICE
	return "승급 대상 없음"


## boost_weak_face/uniform_faces가 공통으로 쓰는 "가장 개선이 필요한 다이스/면" 탐색.
## bag에 다이스가 하나도 없으면 die=-1을 반환한다(실제로는 항상 다이스가 최소 1개 있음).
static func _locate_weakest_face(bag: DiceBag) -> Dictionary:
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
	return {"die": best_die, "face": best_face, "value": best_value}


static func _max_face_value(faces: PackedInt32Array) -> int:
	var max_val: int = faces[0]
	for v in faces:
		max_val = max(max_val, v)
	return max_val


static func _boost_weakest_face(bag: DiceBag) -> void:
	var loc := _locate_weakest_face(bag)
	if loc["die"] < 0:
		return
	var faces: PackedInt32Array = bag.dice[loc["die"]]
	bag.set_face_value(loc["die"], loc["face"], _max_face_value(faces))


## DESIGN.md 빌드업 예시("모든 면을 6으로 만들기")를 구현한다. _boost_weakest_face와
## 같은 방식(가장 낮은 면 값 하나를 기준)으로 "가장 개선이 필요한 다이스"를 고른 뒤,
## 그 다이스의 모든 면을 자신의 최댓값으로 맞춰 균일화한다.
static func _uniformize_worst_die(bag: DiceBag) -> void:
	var loc := _locate_weakest_face(bag)
	if loc["die"] < 0:
		return
	var faces: PackedInt32Array = bag.dice[loc["die"]]
	var max_val := _max_face_value(faces)
	for fi in faces.size():
		bag.set_face_value(loc["die"], fi, max_val)


## boost_weak_face/uniform_faces는 카드 생성 시점(대상 주머니가 아직 안 정해짐)엔 결과를
## 확정할 수 없어 `_build_result_die_preview()`가 처리하지 못했다(STATUS.md 큐 3번에
## 남아있던 간극). 다만 "이 주머니(공격 또는 방어)에 적용한다면"이 정해지면 그 순간
## 결과는 완전히 결정적이다 — apply()와 같은 탐색(_locate_weakest_face)을 bag을
## 바꾸지 않고 미리 계산해, 버튼 옆에 "이 주머니에 적용하면 이렇게 바뀐다" 미리보기를
## 붙일 수 있게 한다. add_die/upgrade_die는 이미 카드 레벨에서 처리되므로 여기선 다루지
## 않는다(null 반환).
static func preview_effect(item: Dictionary, bag: DiceBag):
	var loc := _locate_weakest_face(bag)
	if loc["die"] < 0:
		return null
	var faces: PackedInt32Array = bag.dice[loc["die"]]
	var max_val := _max_face_value(faces)
	match item.get("kind", ""):
		"boost_weak_face":
			return {
				"shape_sides": faces.size(),
				"before": loc["value"],
				"after": max_val,
			}
		"uniform_faces":
			return {
				"shape_sides": faces.size(),
				"value": max_val,
				"face_count": faces.size(),
			}
		_:
			return null
