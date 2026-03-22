extends RefCounted
class_name BattleService

signal state_updated
signal battle_finished(result_text: String)

const ACTION_SLOT_COUNT := 3
const HAND_TARGET_SIZE := 5

class QueuedAction extends RefCounted:
	var card: CardInstance
	var source_hero_index: int = -1
	var target_ally_index: int = -1

	func _init(card_instance: CardInstance, hero_index: int, ally_index: int = -1) -> void:
		card = card_instance
		source_hero_index = hero_index
		target_ally_index = ally_index

var encounter: EncounterData
var hero_hp: Array[int] = []
var enemy_hp: Array[int] = []
var hero_attack_buff_bonus: Array[int] = []
var hero_attack_buff_turns: Array[int] = []
var hero_defense_buff_value: Array[int] = []
var hero_defense_buff_turns: Array[int] = []
var hand: Array[CardInstance] = []
var action_slots: Array = []
var is_battle_over: bool = false
var result_text: String = ""
var selected_enemy_target_index: int = -1
var turn_count: int = 1
var pending_ally_selection_slot_index: int = -1

var _draw_pile: Array[CardData] = []
var _rng := RandomNumberGenerator.new()

func start_battle(encounter_data: EncounterData) -> void:
	encounter = encounter_data
	is_battle_over = false
	result_text = ""
	selected_enemy_target_index = -1
	turn_count = 1
	hero_hp.clear()
	enemy_hp.clear()
	hero_attack_buff_bonus.clear()
	hero_attack_buff_turns.clear()
	hero_defense_buff_value.clear()
	hero_defense_buff_turns.clear()
	hand.clear()
	action_slots = _create_empty_slots()

	if encounter == null or encounter.hero_team.is_empty() or encounter.enemy_team.is_empty():
		is_battle_over = true
		result_text = "Erreur de donnees de combat"
		_emit_state()
		battle_finished.emit(result_text)
		return

	for hero in encounter.hero_team:
		hero_hp.append(0 if hero == null else hero.max_hp)
		hero_attack_buff_bonus.append(0)
		hero_attack_buff_turns.append(0)
		hero_defense_buff_value.append(0)
		hero_defense_buff_turns.append(0)
	for enemy in encounter.enemy_team:
		enemy_hp.append(0 if enemy == null else enemy.max_hp)

	_rng.seed = encounter.combat_seed
	_reset_draw_pile()
	_normalize_hand_state()
	selected_enemy_target_index = _first_alive_enemy_index()
	_emit_state()

func has_pending_actions() -> bool:
	for card in action_slots:
		if card != null:
			return true
	return false

func are_action_slots_full() -> bool:
	for card in action_slots:
		if card == null:
			return false
	return true

func queue_card_from_hand(hand_index: int) -> bool:
	if is_battle_over:
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var slot_index := _first_empty_slot_index()
	if slot_index == -1:
		return false

	var action := _build_queued_action(hand[hand_index])
	if action == null:
		return false

	action_slots[slot_index] = action
	if _requires_manual_ally_target(action.card):
		pending_ally_selection_slot_index = slot_index
	hand.remove_at(hand_index)
	_normalize_hand_state()
	_emit_state()
	return true

func is_ally_selection_active() -> bool:
	if pending_ally_selection_slot_index < 0 or pending_ally_selection_slot_index >= action_slots.size():
		return false
	var action: QueuedAction = action_slots[pending_ally_selection_slot_index] as QueuedAction
	return action != null and action.card != null and _requires_manual_ally_target(action.card)

func set_pending_ally_target(hero_index: int) -> bool:
	if not is_ally_selection_active():
		return false
	if not is_hero_alive(hero_index):
		return false
	var action: QueuedAction = action_slots[pending_ally_selection_slot_index] as QueuedAction
	if action == null:
		return false
	action.target_ally_index = hero_index
	pending_ally_selection_slot_index = -1
	_emit_state()
	return true

func get_pending_ally_target_index() -> int:
	if not is_ally_selection_active():
		return -1
	var action: QueuedAction = action_slots[pending_ally_selection_slot_index] as QueuedAction
	return -1 if action == null else action.target_ally_index

func set_selected_enemy_target(enemy_index: int) -> bool:
	if is_battle_over:
		return false
	if not is_enemy_alive(enemy_index):
		return false
	selected_enemy_target_index = enemy_index
	_emit_state()
	return true

func get_alive_enemy_indices() -> Array[int]:
	var alive: Array[int] = []
	for i in range(enemy_hp.size()):
		if is_enemy_alive(i):
			alive.append(i)
	return alive

func is_enemy_alive(index: int) -> bool:
	if index < 0 or index >= enemy_hp.size():
		return false
	return enemy_hp[index] > 0

func is_hero_alive(index: int) -> bool:
	if index < 0 or index >= hero_hp.size():
		return false
	return hero_hp[index] > 0

func get_first_alive_hero_index() -> int:
	return _first_alive_hero_index()

func get_first_alive_enemy_index() -> int:
	return _first_alive_enemy_index()

func execute_turn(scene_tree: SceneTree) -> void:
	if is_battle_over or encounter == null:
		return
	if scene_tree == null:
		return
	if not has_pending_actions():
		return
	pending_ally_selection_slot_index = -1
	_emit_state()

	for i in range(action_slots.size()):
		var action: QueuedAction = action_slots[i] as QueuedAction
		if action == null or action.card == null:
			continue

		await _execute_player_action(action, scene_tree)
		if _check_battle_end():
			return

	for enemy_index in range(enemy_hp.size()):
		if not is_enemy_alive(enemy_index):
			continue
		var hero_target := _first_alive_hero_index()
		if hero_target == -1:
			break
		var enemy_stats: EntityStats = encounter.enemy_team[enemy_index]
		var incoming_damage: int = 0
		if enemy_stats != null:
			incoming_damage = enemy_stats.attack_stat
		var reduced_damage := maxi(0, incoming_damage - hero_defense_buff_value[hero_target])
		hero_hp[hero_target] = maxi(0, hero_hp[hero_target] - reduced_damage)
		_emit_state()
		if _check_battle_end():
			return
		await scene_tree.create_timer(0.5).timeout

	_cleanup_after_turn()
	_emit_state()

func _cleanup_after_turn() -> void:
	action_slots = _create_empty_slots()
	_reduce_hero_buffs_on_end_turn()
	turn_count += 1
	pending_ally_selection_slot_index = -1
	_normalize_hand_state()

func _normalize_hand_state() -> void:
	var changed := true
	while changed:
		changed = false

		if HandFusionService.fuse_adjacent_once(hand):
			changed = true
			continue

		if hand.size() < HAND_TARGET_SIZE and _draw_one_card_to_hand():
			changed = true

func _draw_one_card_to_hand() -> bool:
	if _draw_pile.is_empty():
		_reset_draw_pile()
		if _draw_pile.is_empty():
			return false
	var data: CardData = _draw_pile.pop_back() as CardData
	if data == null:
		return false
	hand.append(CardInstance.new(data, 1))
	return true

func _create_empty_slots() -> Array:
	var slots: Array = []
	for _i in range(ACTION_SLOT_COUNT):
		slots.append(null)
	return slots

func _reset_draw_pile() -> void:
	_draw_pile.clear()
	if encounter == null:
		return
	for card_data in encounter.starting_deck:
		_draw_pile.append(card_data)
	for i in range(_draw_pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := _draw_pile[i]
		_draw_pile[i] = _draw_pile[j]
		_draw_pile[j] = tmp

func _first_empty_slot_index() -> int:
	for i in range(action_slots.size()):
		if action_slots[i] == null:
			return i
	return -1

func _first_alive_enemy_index() -> int:
	for i in range(enemy_hp.size()):
		if enemy_hp[i] > 0:
			return i
	return -1

func _first_alive_hero_index() -> int:
	for i in range(hero_hp.size()):
		if hero_hp[i] > 0:
			return i
	return -1

func _build_queued_action(card: CardInstance) -> QueuedAction:
	if card == null or card.data == null:
		return null
	var hero_index := _first_alive_hero_index()
	if hero_index == -1:
		return null
	var ally_index := -1
	if _requires_manual_ally_target(card):
		ally_index = _first_alive_hero_index()
	return QueuedAction.new(card, hero_index, ally_index)

func _execute_player_action(action: QueuedAction, scene_tree: SceneTree) -> void:
	var attacker_index := action.source_hero_index
	if not is_hero_alive(attacker_index):
		attacker_index = _first_alive_hero_index()
	if attacker_index == -1:
		return
	var attacker_stats: EntityStats = encounter.hero_team[attacker_index]
	if attacker_stats == null:
		return
	var effective_attack := attacker_stats.attack_stat + hero_attack_buff_bonus[attacker_index]
	var card_id := String(action.card.data.id)

	if card_id == "mage_heal":
		var heal_amount := _resolve_card_base_value(action.card) + effective_attack
		var heal_target := _hero_with_lowest_hp_ratio_index()
		if heal_target != -1:
			var max_hp := encounter.hero_team[heal_target].max_hp
			hero_hp[heal_target] = mini(max_hp, hero_hp[heal_target] + heal_amount)
		_emit_state()
		await scene_tree.create_timer(0.5).timeout
		return

	if card_id == "mage_focus":
		var ally_target := action.target_ally_index
		if not is_hero_alive(ally_target):
			ally_target = _first_alive_hero_index()
		if ally_target != -1:
			hero_attack_buff_bonus[ally_target] = _resolve_card_base_value(action.card)
			hero_attack_buff_turns[ally_target] = 2
		_emit_state()
		await scene_tree.create_timer(0.5).timeout
		return

	if card_id == "defend":
		for i in range(hero_hp.size()):
			if not is_hero_alive(i):
				continue
			hero_defense_buff_value[i] = 5
			hero_defense_buff_turns[i] = 2
		_emit_state()
		await scene_tree.create_timer(0.5).timeout
		return

	if action.card.data.target_type == CardData.TargetType.ALL_ENEMIES:
		for enemy_index in range(enemy_hp.size()):
			if not is_enemy_alive(enemy_index):
				continue
			var aoe_damage := _compute_damage_with_attack(action.card, effective_attack)
			enemy_hp[enemy_index] = maxi(0, enemy_hp[enemy_index] - aoe_damage)
		_emit_state()
		await scene_tree.create_timer(0.5).timeout
		return

	var target_index := _resolve_current_enemy_target()
	if target_index == -1:
		return

	var damage := _compute_damage_with_attack(action.card, effective_attack)
	enemy_hp[target_index] = maxi(0, enemy_hp[target_index] - damage)
	if not is_enemy_alive(target_index):
		selected_enemy_target_index = _first_alive_enemy_index()
	_emit_state()
	await scene_tree.create_timer(0.5).timeout

func _resolve_current_enemy_target() -> int:
	if is_enemy_alive(selected_enemy_target_index):
		return selected_enemy_target_index
	selected_enemy_target_index = _first_alive_enemy_index()
	return selected_enemy_target_index

func _compute_damage_with_attack(card: CardInstance, effective_attack: int) -> int:
	if card == null or card.data == null:
		return 0
	return _resolve_card_base_value(card) + effective_attack

func _resolve_card_base_value(card: CardInstance) -> int:
	if card == null or card.data == null:
		return 0
	var rank_index := card.rank - 1
	if rank_index < 0 or rank_index >= card.data.damage_by_rank.size():
		return 0
	return card.data.damage_by_rank[rank_index]

func _hero_with_lowest_hp_ratio_index() -> int:
	var best_index := -1
	var best_ratio := 2.0
	for i in range(hero_hp.size()):
		if not is_hero_alive(i):
			continue
		var stats: EntityStats = encounter.hero_team[i]
		if stats == null:
			continue
		var ratio := float(hero_hp[i]) / float(maxi(1, stats.max_hp))
		if ratio < best_ratio:
			best_ratio = ratio
			best_index = i
	return best_index

func get_hero_buff_text(hero_index: int) -> String:
	if hero_index < 0 or hero_index >= hero_attack_buff_turns.size():
		return ""
	var buff_lines: Array[String] = []
	if hero_attack_buff_turns[hero_index] > 0:
		buff_lines.append("⚔ attaque+ (%d tours)" % hero_attack_buff_turns[hero_index])
	if hero_defense_buff_turns[hero_index] > 0:
		buff_lines.append("🛡 defense (%d tours)" % hero_defense_buff_turns[hero_index])
	return " | ".join(buff_lines)

func _reduce_hero_buffs_on_end_turn() -> void:
	for i in range(hero_attack_buff_turns.size()):
		if hero_attack_buff_turns[i] <= 0:
			hero_attack_buff_bonus[i] = 0
		else:
			hero_attack_buff_turns[i] -= 1
			if hero_attack_buff_turns[i] <= 0:
				hero_attack_buff_bonus[i] = 0
		if hero_defense_buff_turns[i] <= 0:
			hero_defense_buff_value[i] = 0
		else:
			hero_defense_buff_turns[i] -= 1
			if hero_defense_buff_turns[i] <= 0:
				hero_defense_buff_value[i] = 0

func _requires_manual_ally_target(card: CardInstance) -> bool:
	if card == null or card.data == null:
		return false
	return card.data.target_type == CardData.TargetType.ALLY_SINGLE

func _check_battle_end() -> bool:
	if _first_alive_enemy_index() == -1:
		is_battle_over = true
		result_text = "Victoire !"
		selected_enemy_target_index = -1
		pending_ally_selection_slot_index = -1
		_emit_state()
		battle_finished.emit(result_text)
		return true
	if _first_alive_hero_index() == -1:
		is_battle_over = true
		result_text = "Defaite !"
		selected_enemy_target_index = -1
		pending_ally_selection_slot_index = -1
		_emit_state()
		battle_finished.emit(result_text)
		return true
	return false

func _emit_state() -> void:
	state_updated.emit()
