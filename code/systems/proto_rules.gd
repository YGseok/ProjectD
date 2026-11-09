class_name ProtoRules
extends RefCounted
## [대형 기획 18] 코어 플레이 시험판(테스트 전투 전용, RunState.proto_rules) 순수 계산.
##
## 시험판 흐름: 몬스터 쪽을 먼저 굴려 "넘을 숫자"를 보여주고 → 플레이어가 굴린 뒤
## 주사위를 골라 고정하고 나머지를 최대 REROLLS_PER_ROLL번 다시 굴린 다음 → 확정하면
## 기존 보정 체인(_resolve_exchange, pre_*_values 경로)으로 결과를 낸다. 이 파일은
## 물리/UI와 무관한 계산만 담아 dice_test가 결정적으로 검증한다.
##
## 미리보기 함수들은 전투 상태(monster_skill_state)를 절대 바꾸지 않는다 —
## MonsterSkills.modify_monster_roll()/modify_player_roll()은 state를 변경(분노 스택
## 적립, pounce_used 등)하므로 항상 duplicate(true)한 사본으로 계산한다.

## 한 번 굴릴 때(턴마다) 허용되는 다시 굴리기 횟수.
const REROLLS_PER_ROLL := 2


## held[i]가 true인 칸은 values[i]를 그대로 두고, 나머지는 bag.dice[i]의 면 중
## 하나를 새로 뽑는다(DiceBag.roll_detailed()와 같은 방식 — 면 배열에서 균등 추출).
static func reroll_unheld(bag: DiceBag, values: Array, held: Array) -> Array:
	var out: Array = values.duplicate()
	for i in bag.dice.size():
		var is_held: bool = i < held.size() and held[i]
		if is_held and i < out.size():
			continue
		var faces: PackedInt32Array = bag.dice[i]
		var v: int = faces[randi_range(0, faces.size() - 1)]
		if i < out.size():
			out[i] = v
		else:
			out.append(v)
	return out


static func sum_values(values: Array) -> int:
	var total := 0
	for v in values:
		total += int(v)
	return total


## 몬스터 쪽 날 굴림(raw)에 몬스터 자기 보정(steady_guard/pounce/bloodlust/분노 1D20
## 등, MonsterSkills.modify_monster_roll)을 "사본 상태로" 적용한 값 배열.
## ctx는 _resolve_exchange()가 넘기는 것과 같은 키를 쓴다.
static func preview_monster_values(skill_ids: Array, raw_values: Array, state: Dictionary, ctx: Dictionary) -> Array:
	var state_copy: Dictionary = state.duplicate(true)
	return MonsterSkills.modify_monster_roll(skill_ids, raw_values.duplicate(), state_copy, ctx)


static func preview_monster_total(skill_ids: Array, raw_values: Array, state: Dictionary, ctx: Dictionary) -> int:
	return sum_values(preview_monster_values(skill_ids, raw_values, state, ctx))


## 플레이어 현재 값에 몬스터의 부정형 보정(sticky/seal/chill/dull/numb,
## MonsterSkills.modify_player_roll)을 "사본 상태로" 적용한 값 배열 — 확정 전에
## "이대로 확정하면 실제로 몇이 되는지"를 보여준다. 캐릭터 자신의 패시브(charm_flip
## 등)는 확정 시 적용된다(여기에 포함하지 않음).
static func preview_player_values(skill_ids: Array, values: Array, state: Dictionary, ctx: Dictionary) -> Array:
	var state_copy: Dictionary = state.duplicate(true)
	return MonsterSkills.modify_player_roll(skill_ids, values.duplicate(), state_copy, ctx)


static func preview_player_total(skill_ids: Array, values: Array, state: Dictionary, ctx: Dictionary) -> int:
	return sum_values(preview_player_values(skill_ids, values, state, ctx))


## [대형 기획 18] 2단계 — 몬스터 예고(의도). "다음 행동에 실제로 영향을 주는 것"을
## 효과 위주의 짧은 줄로 돌려준다(기믹 수치는 그대로, 보이게만). params는
## monster_skill_params(스킬 id -> {"amount"...}) + 선택 키 "anger_threshold",
## "anger_dice_sides", "fixed_value". state는 읽기만 한다.
static func monster_intent_lines(skill_ids: Array, state: Dictionary, params: Dictionary, monster_hp: int, monster_max_hp: int) -> Array[String]:
	var lines: Array[String] = []
	var half: bool = monster_hp <= monster_max_hp / 2.0
	for id in skill_ids:
		match id:
			"anger_stack":
				if state.get("anger_pending", false):
					lines.append("다음 공격은 %d면체 (분노)" % int(params.get("anger_dice_sides", 20)))
				else:
					lines.append("분노 %d/%d — 차면 다음 공격 %d면체" % [int(state.get("anger_stacks", 0)), int(params.get("anger_threshold", 3)), int(params.get("anger_dice_sides", 20))])
			"pounce":
				if not state.get("pounce_used", false):
					lines.append("첫 공격 +%d (기습)" % int(params.get("pounce", {}).get("amount", 0)))
			"bloodlust":
				lines.append("공격 주사위 +1 (피의 갈망)" if half else "HP 절반 이하면 공격 +1 (피의 갈망)")
			"guard_up":
				lines.append("방어 주사위 +1 (궁지의 방어)" if half else "HP 절반 이하면 방어 +1 (궁지의 방어)")
			"armor":
				lines.append("방어 합계 +%d (방어구)" % int(params.get("armor", {}).get("amount", 0)))
			"steady_guard":
				lines.append("방어 주사위 절반 미만이면 끌어올림 (철벽 방어)")
			"min_max_only":
				lines.append("최소·최대 값만 나옴 (극단)")
			"fixed_value":
				lines.append("항상 %d (고정값)" % int(params.get("fixed_value", 0)) if params.has("fixed_value") else "항상 같은 값 (고정값)")
			"counter":
				lines.append("공격이 완전히 막히면 %d 반사 (반격)" % int(params.get("counter", {}).get("amount", 0)))
			"sticky":
				lines.append("내 공격 최고값 -1 (끈적임)")
			"seal":
				lines.append("내 공격 가장 낮은 주사위 0 (봉인)")
			"chill":
				lines.append("내 공격 최고값 -1 (한기)")
			"numb":
				lines.append("내 방어 최고값 -1 (마비)")
			"dull":
				lines.append("최대값이 나온 내 주사위 -1 (둔화)")
			"drain":
				lines.append("입힌 피해의 절반 회복 (흡수)")
			"revive":
				if not state.get("revive_used", false):
					lines.append("한 번 쓰러져도 부활 (불사)")
	return lines
