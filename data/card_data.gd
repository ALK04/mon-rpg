extends Resource
class_name CardData

enum TargetType {
	SELF,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SINGLE_ALLY,
	ALL_ALLIES,
	ALLY_SINGLE
}

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_rank: int = 3
@export var damage_by_rank: PackedInt32Array = PackedInt32Array([0, 0, 0])
@export var energy_cost: int = 1
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var rarity: Rarity = Rarity.COMMON
@export var art: Texture2D
