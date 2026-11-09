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
