class_name EliteRewardPool
extends RefCounted
## "정예 전투" 승리 보상 풀 (INBOX.md [대형 기획 6] G-7, 2026-10-07).
##
## INBOX.md 원문: "보상은 일반 전투보다 커야 함: 승리 보상 카드 후보를 A급 이상
## 중심으로(기존 등급 시스템 재사용) + 골드 x2." 골드 x2는 combat_test.gd가
## monster_is_elite 분기로 직접 처리하고(GOLD_REWARD_BASE 등 상수가 이 파일 소관이
## 아니므로), 이 파일은 "카드 후보" 쪽만 담당한다.
##
## DiceItemPool.ITEMS(C/B급뿐)만으로는 "A급 이상"을 만들 수 없어, EventItemPool.ITEMS
## (B/A/S급 보유)와 합친 풀에서 등급 가중치로 뽑는다. EventItemPool의 "눈금 주머니
## 획득"(kind="gain_pips")은 제외한다 — combat_test.gd의 승리 보상 카드 적용 로직
## (_show_reward_ui() 등)이 지금 "다이스 적용" 계열 kind(add_die/upgrade_die/
## boost_weak_face/uniform_faces, DiceItemPool.apply()/is_applicable() 기반)만 다루고
## gain_pips(눈금 즉시 획득, event.gd 전용 경로)는 다루지 않기 때문 — 섞으면 그 카드만
## 적용 버튼이 없는 반쪽짜리가 된다.
##
## 등급 가중치(GRADE_WEIGHTS)는 EventItemPool.RISKY_GRADE_WEIGHTS(위험을 감수하기 성공
## 보상, B:A:S = 1:2:3)보다 한 단계 더 상위로 치우치고 C/B급도 완전히 배제하지 않아
## "A급 이상 중심"이되 가끔 낮은 등급도 나올 수 있게 한다 — 전부 잠정값(F-4 시뮬/사람
## 피드백으로 조정).

const GRADE_WEIGHTS := {"C": 1.0, "B": 2.0, "A": 4.0, "S": 5.0}


static func _pool() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	items.append_array(DiceItemPool.ITEMS)
	for item in EventItemPool.ITEMS:
		if item.get("kind", "") != "gain_pips":
			items.append(item)
	return items


## n개의 "서로 다른" 아이템을 등급 가중치로 뽑는다(복원추출 없음 — 뽑을 때마다 후보에서
## 제거해 같은 전투에서 같은 아이템이 두 번 나오지 않게 한다). 풀보다 많이 요청하면
## 있는 만큼만 반환.
static func random_choices(n: int) -> Array[Dictionary]:
	var remaining := _pool()
	var chosen: Array[Dictionary] = []
	for _i in n:
		if remaining.is_empty():
			break
		var picked: Dictionary = _weighted_pick(remaining)
		chosen.append(picked)
		remaining.erase(picked)
	return chosen


static func _weighted_pick(pool: Array[Dictionary]) -> Dictionary:
	var total_weight := 0.0
	for item in pool:
		total_weight += float(GRADE_WEIGHTS.get(item.get("grade", ""), 1.0))
	var roll := randf() * total_weight
	var cumulative := 0.0
	for item in pool:
		cumulative += float(GRADE_WEIGHTS.get(item.get("grade", ""), 1.0))
		if roll < cumulative:
			return item
	return pool[pool.size() - 1]
