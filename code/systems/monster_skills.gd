class_name MonsterSkills
extends RefCounted
## 몬스터 스킬 프레임워크 (INBOX.md [대형 기획 6] G-2/G-3, 2026-10-07).
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
## G-3 범위: 인간형 프리미티브 armor(n)/guard_up/counter(n) + 부정형 프리미티브
## sticky/seal/dull/numb 신설(수치는 전부 잠정값 — F-4 시뮬로 조정). 아직 몬스터
## 카탈로그(`monster_catalog.gd`)의 어느 몬스터도 이 7종을 쓰지 않는다(그건 G-5가
## 몬스터 데이터를 늘릴 때의 일) — 지금은 combat_test.gd가 훅을 항상 호출하도록
## 배선만 해두고(G-2와 같은 방식), 실제 몬스터가 생기기 전까지는 전부 no-op이다.
##
## 훅 4개:
## - on_combat_start(skill_ids, state, ...): 전투당 1회 상태 초기화 + "주머니 자체를
##   바꾸는" 종류(min_max_only/fixed_value) 적용.
## - modify_monster_roll(skill_ids, values, state, ctx): 몬스터 "자신의" 굴림(공격 또는
##   방어) 보정 — steady_guard/guard_up/armor(값 보정) + anger_stack(스택 적립/리셋,
##   값은 안 바꿈).
## - modify_player_roll(skill_ids, values, state, ctx): 플레이어 굴림 보정(부정형 계열
##   sticky/seal/dull/numb, G-3) — 기존 4종에는 해당하는 것이 없어 항상 입력을 그대로
##   반환.
## - on_damage(skill_ids, state, ctx): 피해 확정 후(인간형 counter(n), G-3 + 언데드
##   계열의 drain/revive, G-4가 채울 자리) — 해당하는 스킬이 없으면 빈 Dictionary.
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
## ctx의 추가 키(G-3, 인간형 armor/guard_up용): "monster_hp"/"monster_max_hp"(guard_up의
## "HP 절반 이하" 판정용), "armor_amount"(armor(n)의 n — 몬스터 카탈로그 skill_params에서
## 옴, 해당 스킬이 없으면 0).
static func modify_monster_roll(skill_ids: Array, values: Array, state: Dictionary, ctx: Dictionary) -> Array:
	state.erase("last_event")
	var result := values
	if ctx.get("is_player_attacking", false):
		if skill_ids.has("steady_guard"):
			result = ctx["bag"].apply_steady_guard(result)
		# "guard_up"(인간형, G-3): 몬스터 HP가 최대 HP의 절반 이하일 때만 방어 다이스
		# 결과값 전체 +1 — "궁지에 몰릴수록 단단해진다"는 인간형 계열 공통 컨셉.
		if skill_ids.has("guard_up") and ctx.get("monster_hp", 0) <= ctx.get("monster_max_hp", 0) / 2.0:
			result = ctx["bag"].apply_flat_bonus(result, 1)
		# "armor(n)"(인간형, G-3): 몬스터 방어 "합계" +n(다이스별이 아니라 총합 1회).
		if skill_ids.has("armor"):
			result = ctx["bag"].apply_total_bonus(result, ctx.get("armor_amount", 0))
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


## 플레이어 굴림(공격/방어) 보정 — 부정형 계열 프리미티브(sticky/seal/dull/numb, G-3).
## 기존 4종(anger_stack/fixed_value/min_max_only/steady_guard)에는 해당하는 것이 없어
## skill_ids에 넷 중 하나도 없으면 항상 입력을 그대로 반환한다(동작 보존).
##
## ctx 필요 키:
## - "is_player_attacking": bool. true면 지금 보정할 값이 플레이어의 "공격" 다이스,
##   false면 플레이어의 "방어" 다이스(_do_exchange()의 바깥 is_player_attacking과 같은
##   의미 — 턴을 가리키는 것이지 "누가 공격했는지"가 아님에 유의).
## - "bag": DiceBag. 지금 보정할 그 주머니(RunState.player_attack_bag 등, 또는 폭발/수호
##   스택의 보너스 1D20 임시 주머니일 수도 있음) — dull의 "자신의 최댓값 면" 판정에 씀.
##
## 적용 범위:
## - sticky/seal: 플레이어 "공격" 턴에만(보너스 1D20 턴 포함).
## - numb: 플레이어 "방어" 턴에만.
## - dull: 공격/방어 양쪽 다 — explosive_stack(공격 최댓값 스택)과 guard_stack(방어
##   최댓값 스택) 둘 다의 "스택 조건"을 약화하려는 의도된 카운터이기 때문.
static func modify_player_roll(skill_ids: Array, values: Array, _state: Dictionary, ctx: Dictionary) -> Array:
	var bag: DiceBag = ctx.get("bag")
	if bag == null:
		return values
	var is_player_attacking: bool = ctx.get("is_player_attacking", false)
	var result := values
	if skill_ids.has("dull"):
		result = bag.apply_reduce_max_rolls(result, 1)
	if is_player_attacking:
		if skill_ids.has("sticky"):
			result = bag.apply_reduce_highest(result, 1, 1)
		if skill_ids.has("seal"):
			result = bag.apply_zero_lowest(result)
	else:
		if skill_ids.has("numb"):
			result = bag.apply_reduce_highest(result, 1, 1)
	return result


## 피해 확정 후 훅(흡수/반사/부활 — 언데드 계열의 drain/revive(G-4) + 인간형 "counter(n)"
## (G-3)). 기존 4종에는 해당하는 것이 없으면 빈 Dictionary를 반환한다(동작 보존 — 이
## 함수는 이전까지 아무 것도 하지 않고 반환값도 없었으나, G-3부터 effect dict를 돌려줄
## 필요가 생겨 반환형을 void->Dictionary로 바꿈. 호출부가 반환값을 안 받아도 안전함).
##
## "counter(n)"(인간형, G-3): 플레이어 공격이 몬스터 방어에 완전히 막혀(이번 교환의
## 확정 데미지 dmg==0) 데미지가 0이면, 플레이어에게 amount만큼 반사 피해를 입힌다.
## 이 파일은 player_hp를 모르므로 실제 적용/로그는 반환값({"reflect_damage": int})을
## 받은 호출부(combat_test.gd) 몫이다.
##
## ctx 필요 키(counter에만 해당): "is_player_attacking": bool(true여야 "몬스터가
## 방어턴이었다" = 플레이어가 공격한 턴), "dmg": int(이번 교환 확정 데미지),
## "counter_amount": int(counter(n)의 n).
static func on_damage(skill_ids: Array, _state: Dictionary, ctx: Dictionary) -> Dictionary:
	if skill_ids.has("counter") and ctx.get("is_player_attacking", false) and ctx.get("dmg", -1) == 0:
		var amount: int = ctx.get("counter_amount", 0)
		if amount > 0:
			return {"reflect_damage": amount}
	return {}
