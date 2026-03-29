extends RefCounted
class_name DamageService

static func compute_damage(card: CardInstance, attacker: EntityStats) -> int:
	if card == null or card.data == null or attacker == null:
		return 0

	var rank_index := card.rank - 1

	# Priorité au premier effet DAMAGE défini sur la carte
	for effect in card.data.effects:
		if effect.effect_type == CardEffect.EffectType.DAMAGE:
			if rank_index >= 0 and rank_index < effect.value_by_rank.size():
				return effect.value_by_rank[rank_index] + attacker.attack_stat
			return attacker.attack_stat

	# Fallback : damage_by_rank pour les cartes sans effets définis
	if rank_index < 0 or rank_index >= card.data.damage_by_rank.size():
		return attacker.attack_stat
	return card.data.damage_by_rank[rank_index] + attacker.attack_stat
