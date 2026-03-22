extends RefCounted
class_name CardInstance

var data: CardData
var rank: int = 1

func _init(card_data: CardData, initial_rank: int = 1) -> void:
	data = card_data
	rank = max(1, initial_rank)
