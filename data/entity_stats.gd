extends Resource
class_name EntityStats

@export var id: StringName
@export var display_name: String = ""
@export var max_hp: int = 1
@export var attack_stat: int = 0
@export var base_energy_per_turn: int = 1
@export var portrait: Texture2D
@export var tags: PackedStringArray = PackedStringArray()
@export var special_energy_gain: int = 20
@export var special_card: CardData
