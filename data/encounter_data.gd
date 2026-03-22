extends Resource
class_name EncounterData

@export var id: StringName
@export var display_name: String = ""
@export var hero_team: Array[EntityStats] = []
@export var enemy_team: Array[EntityStats] = []
@export var starting_deck: Array[CardData] = []
@export var starting_hand_size: int = 3
@export var combat_seed: int = 0
