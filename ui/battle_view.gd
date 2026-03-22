extends Control
class_name BattleView

@export var hero_name_label: Label
@export var enemy_name_label: Label

func set_names(hero_name: String, enemy_name: String) -> void:
	if hero_name_label != null:
		hero_name_label.text = hero_name
	if enemy_name_label != null:
		enemy_name_label.text = enemy_name
