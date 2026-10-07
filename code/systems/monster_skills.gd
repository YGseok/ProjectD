class_name MonsterSkills
extends RefCounted
## 몬스터 스킬 프레임워크 (INBOX.md [대형 기획 6] G-2, 2026-10-07).
##
## 몬스터 수십 종을 각각 코드로 짜지 않기 위한 "재사용 가능한 프리미티브" 레이어 —
## 일반 몬스터는 스킬 1개, 정예는 2개, 보스는 3개(G-7/G-8 이후)를 조합해 행동을 구성한다.
## 몬스터별 스킬 로직은 combat_test.gd에 흩어 넣지 않고 여기 순수 함수로 모아
## dice_test.gd가 같은 코드를 직접 호출해 검증할 수 있게 한다.
##
## G-2 범위: 기존 4종 기믹(anger_stack/fixed_value/min_max_only/steady_guard)을
## 이 구조로 옮긴다 — **이식 전후 같은 입력이면 같은 결과**(동작 보존, 전투 수치는
## 전혀 바뀌지 않음). DiceBag 쪽 헬퍼(force_fixed_value/force_min_max_faces/
## apply_steady_guard/count_max_rolls)는 그대로 호출만 한다(새 다이스 연산 없음).
##
## 훅 4개(INBOX.md 원문 — 몬스터가 늘어날 G-3 이후부터 실제로 쓰이기 시작하고, G-2에선
## 기존 4종이 쓰는 것만 채워져 있다):
## - on_combat_start(skill_ids, state, ...): 전투당 1회 상태 초기화 + "주머니 자체를
##   바꾸는" 종류(min_max_only/fixed_value) 적용.
## - modify_monster_roll(skill_ids, values, state, ctx): 몬스터 "자신의" 굴림(공격 또는
##   방어) 보정 — steady_guard(값 보정) + anger_stack(스택 적립/리셋, 값은 안 바꿈).
## - modify_player_roll(skill_ids, values, state, ctx): 플레이어 굴림 보정(부정형 계열,
##   G-3의 sticky/seal/dull/numb가 쓸 자리) — 기존 4종에는 해당하는 것이 없어 항상
##   입력을 그대로 반환.
## - on_damage(skill_ids, state, ctx): 피해 확정 후(언데드 계열의 drain/revive, G-4가
##   쓸 자리) — 기존 4종에는 해당하는 것이 없어 아무 것도 하지 않는다.
##
## 위 4개 외에 should_use_bonus_attack_dice()가 하나 더 있다 — anger_stack이 "다음
## 공격은 1D20으로 굴린다"를 결정하는 시점은 다이스를 물리적으로 스폰하기 **전**이라
## (실제 굴림 결과가 나오기 전에 어떤 주머니를 굴릴지부터 정해야 함) "굴린 결과를
## 보정"하는 modify_monster_roll 호출보다 앞서 별도로 질의해야 한다. 분노 보너스 다이스
## 자체(1D20)를 실제로 스폰하는 것은 여전히 combat_test.gd 몫 — 기존 ANGER_DICE_SIDES
## 상수를 그대로 쓴다(이 파일은 "스폰"을 모른다).


## 전투 시작(= combat_test.gd _ready()) 시 1회 호출. state(해당 전투 한정 Dictionary)를
## 초기화하고, 주머니 자체의 면 값을 영구히 바꾸는 종류(min_max_only/fixed_value)를
## 여기서 적용한다 — 기존 _ready()의 if/elif 블록과 완전히 동일한 조건/순서.
static func on_combat_start(skill_ids: Array, state: Dictionary, attack_bag: DiceBag, defense_bag: DiceBag, fixed_value_amount: int) -> void:
	state.clear()
	state["anger_stacks"] = 0
	state["anger_pending"] = false
	if skill_ids.has("min_max_only"):
		attack_bag.force_min_max_faces()
		defense_bag.force_min_max_faces()
	elif skill_ids.has("fixed_value"):
		attack_bag.force_fixed_value(fixed_value_amount)
		defense_bag.force_fixed_value(fixed_value_amount)


## 이번 몬스터 공격턴에 평소 공격 주머니 대신 분노 보너스 1D20을 굴려야 하는지 — 실제
## 다이스 스폰 전에 물어야 하므로 modify_monster_roll과 분리된 질의 함수. 기존
## `monster_dice_gimmick == "anger_stack" and monster_anger_pending` 조건과 동일.
static func should_use_bonus_attack_dice(skill_ids: Array, state: Dictionary) -> bool:
	return skill_ids.has("anger_stack") and state.get("anger_pending", false)


## 몬스터 "자신의" 굴림(공격 또는 방어, ctx.is_player_attacking으로 구분) 결과를 굴린
## 직후 보정한다. 호출할 때마다 state["last_event"]를 먼저 지우고, 로그에 남길 일이
## 있으면 다시 채운다(호출부가 읽어서 _append_log()로 문구를 만든다 — 이 함수는 UI/로그를
## 모른다).
##
## ctx 필요 키:
## - "is_player_attacking": bool. true면 지금 굴린 건 몬스터의 "방어"(플레이어 공격턴),
##   false면 몬스터의 "공격"(몬스터 공격턴).
## - "bag": DiceBag. 이번에 실제로 굴린 주머니(steady_guard의 면 개수 계산,
##   anger_stack의 count_max_rolls()에 씀).
## - "used_bonus_dice": bool (is_player_attacking==false일 때만 의미 있음). 이번
##   공격이 이미 분노 보너스 1D20였는지 — true면 스택을 리셋만 하고 새로 세지 않는다
##   (기존 "used_anger_dice" 분기와 동일).
## - "anger_threshold": int. 분노 스택 임계치(기존 ANGER_STACK_THRESHOLD).
static func modify_monster_roll(skill_ids: Array, values: Array, state: Dictionary, ctx: Dictionary) -> Array:
	state.erase("last_event")
	var result := values
	if ctx.get("is_player_attacking", false):
		if skill_ids.has("steady_guard"):
			result = ctx["bag"].apply_steady_guard(result)
	else:
		if skill_ids.has("anger_stack"):
			_update_anger_stack(state, ctx.get("used_bonus_dice", false), ctx["bag"], result, ctx.get("anger_threshold", 3))
	return result


static func _update_anger_stack(state: Dictionary, used_bonus_dice: bool, bag: DiceBag, values: Array, threshold: int) -> void:
	if used_bonus_dice:
		state["anger_stacks"] = 0
		state["anger_pending"] = false
		state["last_event"] = {"type": "anger_reset"}
		return
	var max_hits: int = bag.count_max_rolls(values)
	if max_hits <= 0:
		return
	var new_stacks: int = state.get("anger_stacks", 0) + max_hits
	state["anger_stacks"] = new_stacks
	var activated: bool = new_stacks >= threshold
	if activated:
		state["anger_pending"] = true
	state["last_event"] = {"type": "anger_gain", "amount": max_hits, "stacks": new_stacks, "activated": activated}


## 플레이어 굴림(공격/방어) 보정 — 부정형 계열(sticky/seal/dull/numb, G-3이 채울 자리).
## 기존 4종(anger_stack/fixed_value/min_max_only/steady_guard) 중 플레이어 주사위를
## 건드리는 것은 없으므로 G-2에서는 항상 입력을 그대로 반환한다.
static func modify_player_roll(_skill_ids: Array, values: Array, _state: Dictionary, _ctx: Dictionary) -> Array:
	return values


## 피해 확정 후 훅(흡수/반사/부활 — 언데드 계열의 drain/revive, G-4가 채울 자리).
## 기존 4종에는 해당하는 것이 없으므로 G-2에서는 아무 것도 하지 않는다.
static func on_damage(_skill_ids: Array, _state: Dictionary, _ctx: Dictionary) -> void:
	pass
