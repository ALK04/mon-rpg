extends RefCounted
class_name DamageService

static func compute_damage(card: CardInstance, attacker: EntityStats) -> int:
	if card == null or card.data == null or attacker == null:
		return 0

	var rank_index := card.rank - 1
	if rank_index < 0 or rank_index >= card.data.damage_by_rank.size():
		return attacker.attack_stat

	return card.data.damage_by_rank[rank_index] + attacker.attack_stat
