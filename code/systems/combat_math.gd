class_name CombatMath
extends RefCounted
## DESIGN.md 공식: 최종 데미지 = max(0, 공격 합계 - 방어 합계)


static func calculate_damage(attack_total: int, defense_total: int) -> int:
	return max(0, attack_total - defense_total)
