extends Resource
class_name CardEffect

enum EffectType {
	DAMAGE  = 0,
	HEAL    = 1,
	POISON  = 2,
	WEAKEN  = 3,
	ATK_BUFF = 4,
	DEF_BUFF = 5,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var value_by_rank: PackedInt32Array = PackedInt32Array([0, 0, 0])
@export var duration: int = 0
