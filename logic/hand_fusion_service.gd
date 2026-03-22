extends RefCounted
class_name HandFusionService

static func fuse_adjacent_once(hand: Array[CardInstance]) -> bool:
	if hand.size() < 2:
		return false

	for i in range(hand.size() - 1):
		var left := hand[i]
		var right := hand[i + 1]
		if left == null or right == null:
			continue
		if left.data == null or right.data == null:
			continue
		if left.data.id != right.data.id:
			continue
		if left.rank >= left.data.max_rank:
			continue
		if right.rank >= right.data.max_rank:
			continue
		if left.rank != right.rank:
			continue

		left.rank += 1
		hand.remove_at(i + 1)
		return true

	return false

static func fuse_adjacent_until_stable(hand: Array[CardInstance]) -> void:
	while fuse_adjacent_once(hand):
		pass
