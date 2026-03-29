extends RefCounted
class_name BattleService

signal state_updated
signal battle_finished(result_text: String)
signal battle_event(text: String)

const ACTION_SLOT_COUNT := 3
const HAND_TARGET_SIZE := 5

class QueuedAction extends RefCounted:
	var card: CardInstance
	var source_hero_index: int = -1
	var target_ally_index: int = -1
	var target_enemy_index: int = -1
	var needs_target_confirmation: bool = false

	func _init(card_instance: CardInstance, hero_index: int) -> void:
		card = card_instance
		source_hero_index = hero_index

var encounter: EncounterData
var hero_hp: Array[int] = []
var enemy_hp: Array[int] = []
var hero_attack_buff_bonus: Array[int] = []
var hero_attack_buff_turns: Array[int] = []
var hero_defense_buff_value: Array[int] = []
var hero_defense_buff_turns: Array[int] = []
var enemy_debuff_turns: Array[int] = []
var enemy_poison_turns: Array[int] = []
var hand: Array[CardInstance] = []
var action_slots: Array = []
var is_battle_over: bool = false
var result_text: String = ""
var selected_enemy_target_index: int = -1
var turn_count: int = 1
var pending_target_slot_index: int = -1

var _draw_pile: Array[CardData] = []
var _rng := RandomNumberGenerator.new()

# ── Initialisation ─────────────────────────────────────────────────────────────

func start_battle(encounter_data: EncounterData) -> void:
	encounter = encounter_data
	is_battle_over = false
	result_text = ""
	selected_enemy_target_index = -1
	turn_count = 1
	pending_target_slot_index = -1
	hero_hp.clear()
	enemy_hp.clear()
	hero_attack_buff_bonus.clear()
	hero_attack_buff_turns.clear()
	hero_defense_buff_value.clear()
	hero_defense_buff_turns.clear()
	enemy_debuff_turns.clear()
	enemy_poison_turns.clear()
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
		enemy_debuff_turns.append(0)
		enemy_poison_turns.append(0)

	_rng.seed = encounter.combat_seed
	_reset_draw_pile()
	_normalize_hand_state()
	selected_enemy_target_index = _first_alive_enemy_index()
	_emit_state()

# ── Gestion des slots d'action ─────────────────────────────────────────────────

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

	var card := hand[hand_index]
	if card == null or card.data == null:
		return false

	var hero_index := _first_alive_hero_index()
	if hero_index == -1:
		return false

	var action := QueuedAction.new(card, hero_index)

	var needs_confirm := _requires_target_confirmation(card)
	action.needs_target_confirmation = needs_confirm
	if needs_confirm:
		# La cible sera confirmée par le joueur via confirm_target()
		action.target_enemy_index = -1
		action.target_ally_index = -1
	else:
		# Cibles auto-assignées
		action.target_enemy_index = selected_enemy_target_index
		action.target_ally_index = _first_alive_hero_index()

	action_slots[slot_index] = action

	if needs_confirm and pending_target_slot_index == -1:
		pending_target_slot_index = slot_index

	hand.remove_at(hand_index)
	_normalize_hand_state()
	_emit_state()
	return true

# ── Système de ciblage manuel ──────────────────────────────────────────────────

func is_waiting_for_target() -> bool:
	return pending_target_slot_index >= 0

func get_pending_target_type() -> CardData.TargetType:
	if not is_waiting_for_target():
		return CardData.TargetType.SELF
	var action: QueuedAction = action_slots[pending_target_slot_index] as QueuedAction
	if action == null or action.card == null or action.card.data == null:
		return CardData.TargetType.SELF
	return action.card.data.target_type as CardData.TargetType

func get_pending_target_index() -> int:
	if not is_waiting_for_target():
		return -1
	var action: QueuedAction = action_slots[pending_target_slot_index] as QueuedAction
	if action == null:
		return -1
	if action.card.data.target_type == CardData.TargetType.SINGLE_ENEMY:
		return action.target_enemy_index
	return action.target_ally_index

func confirm_target(index: int) -> bool:
	if not is_waiting_for_target():
		return false
	var action: QueuedAction = action_slots[pending_target_slot_index] as QueuedAction
	if action == null:
		return false

	var target_type := action.card.data.target_type
	if target_type == CardData.TargetType.SINGLE_ENEMY:
		if not is_enemy_alive(index):
			return false
		action.target_enemy_index = index
		selected_enemy_target_index = index
	elif target_type == CardData.TargetType.ALLY_SINGLE:
		if not is_hero_alive(index):
			return false
		action.target_ally_index = index
	else:
		return false

	action.needs_target_confirmation = false
	pending_target_slot_index = -1

	# Cherche le prochain slot en attente de confirmation
	for i in range(action_slots.size()):
		var a: QueuedAction = action_slots[i] as QueuedAction
		if a != null and a.needs_target_confirmation:
			pending_target_slot_index = i
			break

	_emit_state()
	return not is_waiting_for_target()

func set_selected_enemy_target(enemy_index: int) -> bool:
	if is_battle_over:
		return false
	if not is_enemy_alive(enemy_index):
		return false
	selected_enemy_target_index = enemy_index
	_emit_state()
	return true

# ── Requêtes d'état ────────────────────────────────────────────────────────────

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

func get_hero_buff_text(hero_index: int) -> String:
	if hero_index < 0 or hero_index >= hero_attack_buff_turns.size():
		return ""
	var buff_lines: Array[String] = []
	if hero_attack_buff_turns[hero_index] > 0:
		buff_lines.append("⚔ attaque+ (%d tours)" % hero_attack_buff_turns[hero_index])
	if hero_defense_buff_turns[hero_index] > 0:
		buff_lines.append("🛡 defense (%d tours)" % hero_defense_buff_turns[hero_index])
	return " | ".join(buff_lines)

func get_enemy_status_text(enemy_index: int) -> String:
	if enemy_index < 0 or enemy_index >= enemy_hp.size():
		return ""
	var parts: Array[String] = []
	if enemy_index < enemy_debuff_turns.size() and enemy_debuff_turns[enemy_index] > 0:
		parts.append("⬇ affaibli (%d tours)" % enemy_debuff_turns[enemy_index])
	if enemy_index < enemy_poison_turns.size() and enemy_poison_turns[enemy_index] > 0:
		parts.append("☠ poison (%d tours)" % enemy_poison_turns[enemy_index])
	return " | ".join(parts)

# ── Exécution du tour ──────────────────────────────────────────────────────────

func execute_turn(scene_tree: SceneTree) -> void:
	if is_battle_over or encounter == null:
		return
	if scene_tree == null:
		return
	if not has_pending_actions():
		return
	if is_waiting_for_target():
		return
	pending_target_slot_index = -1
	_emit_state()

	# Phase 1 : actions du joueur
	for i in range(action_slots.size()):
		var action: QueuedAction = action_slots[i] as QueuedAction
		if action == null or action.card == null:
			continue
		await _execute_player_action(action, scene_tree)
		if _check_battle_end():
			return

	# Phase 2 : ticks de poison
	for enemy_index in range(enemy_hp.size()):
		if not is_enemy_alive(enemy_index):
			continue
		if enemy_index >= enemy_poison_turns.size() or enemy_poison_turns[enemy_index] <= 0:
			continue
		var enemy_data: EntityStats = encounter.enemy_team[enemy_index]
		var max_hp := 1 if enemy_data == null else maxi(1, enemy_data.max_hp)
		var elapsed := 3 - enemy_poison_turns[enemy_index] + 1
		var poison_damage := roundi(0.02 * max_hp * elapsed)
		enemy_hp[enemy_index] = maxi(0, enemy_hp[enemy_index] - poison_damage)
		battle_event.emit("Tour %d — ☠ Poison : %s perd %d PV" % [turn_count, _enemy_name(enemy_index), poison_damage])
		_emit_state()
		if _check_battle_end():
			return
		await scene_tree.create_timer(0.3).timeout

	# Phase 3 : attaques ennemies
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
		var is_debuffed := enemy_index < enemy_debuff_turns.size() and enemy_debuff_turns[enemy_index] > 0
		if is_debuffed:
			incoming_damage = roundi(incoming_damage * 0.7)
		var reduced_damage := maxi(0, incoming_damage - hero_defense_buff_value[hero_target])
		hero_hp[hero_target] = maxi(0, hero_hp[hero_target] - reduced_damage)

		var event_text := "Tour %d — %s attaque %s : %d dégâts" % [turn_count, _enemy_name(enemy_index), _hero_name(hero_target), reduced_damage]
		var notes: Array[String] = []
		if is_debuffed:
			notes.append("affaibli")
		if hero_defense_buff_value[hero_target] > 0 and hero_defense_buff_turns[hero_target] > 0:
			notes.append("réduit par défense")
		if not notes.is_empty():
			event_text += " (%s)" % " | ".join(notes)
		battle_event.emit(event_text)

		_emit_state()
		if _check_battle_end():
			return
		await scene_tree.create_timer(0.5).timeout

	_cleanup_after_turn()
	_emit_state()

func _cleanup_after_turn() -> void:
	action_slots = _create_empty_slots()
	_reduce_hero_buffs_on_end_turn()
	_reduce_enemy_status_on_end_turn()
	turn_count += 1
	pending_target_slot_index = -1
	_normalize_hand_state()

# ── Exécution des actions joueur ───────────────────────────────────────────────

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
	var rank := action.card.rank

	for effect in action.card.data.effects:
		_apply_effect(effect, action, rank, effective_attack)

	_emit_state()
	await scene_tree.create_timer(0.5).timeout

func _apply_effect(effect: CardEffect, action: QueuedAction, rank: int, effective_attack: int) -> void:
	var base_value := _get_effect_value(effect, rank)
	var hero_name := _hero_name(action.source_hero_index)
	var card_name := action.card.data.display_name

	match effect.effect_type:
		CardEffect.EffectType.DAMAGE:
			var damage := base_value + effective_attack
			if action.card.data.target_type == CardData.TargetType.ALL_ENEMIES:
				for i in range(enemy_hp.size()):
					if is_enemy_alive(i):
						enemy_hp[i] = maxi(0, enemy_hp[i] - damage)
				battle_event.emit("Tour %d — %s utilise %s (zone) : %d dégâts par cible" % [turn_count, hero_name, card_name, damage])
			else:
				var target := _resolve_action_enemy_target(action)
				if target != -1:
					enemy_hp[target] = maxi(0, enemy_hp[target] - damage)
					battle_event.emit("Tour %d — %s utilise %s sur %s : %d dégâts" % [turn_count, hero_name, card_name, _enemy_name(target), damage])
					if not is_enemy_alive(target):
						selected_enemy_target_index = _first_alive_enemy_index()

		CardEffect.EffectType.HEAL:
			var heal := base_value + effective_attack
			var target := _hero_with_lowest_hp_ratio_index()
			if target != -1:
				var max_hp := encounter.hero_team[target].max_hp if encounter.hero_team[target] != null else 1
				hero_hp[target] = mini(max_hp, hero_hp[target] + heal)
				battle_event.emit("Tour %d — %s utilise %s sur %s : +%d PV" % [turn_count, hero_name, card_name, _hero_name(target), heal])

		CardEffect.EffectType.ATK_BUFF:
			var target := action.target_ally_index
			if not is_hero_alive(target):
				target = _first_alive_hero_index()
			if target != -1:
				hero_attack_buff_bonus[target] = base_value
				hero_attack_buff_turns[target] = effect.duration
				battle_event.emit("Tour %d — Buff : %s ATK+%d via %s (%d tours)" % [turn_count, _hero_name(target), base_value, card_name, effect.duration])

		CardEffect.EffectType.DEF_BUFF:
			for i in range(hero_hp.size()):
				if is_hero_alive(i):
					hero_defense_buff_value[i] = base_value
					hero_defense_buff_turns[i] = effect.duration
			battle_event.emit("Tour %d — Buff : Défense équipe +%d via %s (%d tours)" % [turn_count, base_value, card_name, effect.duration])

		CardEffect.EffectType.WEAKEN:
			var target := _resolve_action_enemy_target(action)
			if target != -1:
				enemy_debuff_turns[target] = effect.duration
				battle_event.emit("Tour %d — Debuff : %s affaibli via %s (%d tours, -30%% dégâts)" % [turn_count, _enemy_name(target), card_name, effect.duration])

		CardEffect.EffectType.POISON:
			var target := _resolve_action_enemy_target(action)
			if target != -1:
				enemy_poison_turns[target] = effect.duration
				battle_event.emit("Tour %d — Debuff : %s empoisonné via %s (%d tours)" % [turn_count, _enemy_name(target), card_name, effect.duration])

# ── Helpers privés ─────────────────────────────────────────────────────────────

func _get_effect_value(effect: CardEffect, rank: int) -> int:
	var rank_index := rank - 1
	if rank_index < 0 or rank_index >= effect.value_by_rank.size():
		return 0
	return effect.value_by_rank[rank_index]

func _resolve_action_enemy_target(action: QueuedAction) -> int:
	if action.target_enemy_index >= 0 and is_enemy_alive(action.target_enemy_index):
		return action.target_enemy_index
	return _resolve_current_enemy_target()

func _resolve_current_enemy_target() -> int:
	if is_enemy_alive(selected_enemy_target_index):
		return selected_enemy_target_index
	selected_enemy_target_index = _first_alive_enemy_index()
	return selected_enemy_target_index

func _requires_target_confirmation(card: CardInstance) -> bool:
	if card == null or card.data == null:
		return false
	return card.data.target_type == CardData.TargetType.SINGLE_ENEMY or \
		   card.data.target_type == CardData.TargetType.ALLY_SINGLE

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

func _reduce_enemy_status_on_end_turn() -> void:
	for i in range(enemy_debuff_turns.size()):
		if enemy_debuff_turns[i] > 0:
			enemy_debuff_turns[i] -= 1
	for i in range(enemy_poison_turns.size()):
		if enemy_poison_turns[i] > 0:
			enemy_poison_turns[i] -= 1

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

func _check_battle_end() -> bool:
	if _first_alive_enemy_index() == -1:
		is_battle_over = true
		result_text = "Victoire !"
		selected_enemy_target_index = -1
		pending_target_slot_index = -1
		_emit_state()
		battle_finished.emit(result_text)
		return true
	if _first_alive_hero_index() == -1:
		is_battle_over = true
		result_text = "Defaite !"
		selected_enemy_target_index = -1
		pending_target_slot_index = -1
		_emit_state()
		battle_finished.emit(result_text)
		return true
	return false

func _emit_state() -> void:
	state_updated.emit()

func _hero_name(index: int) -> String:
	if index < 0 or encounter == null or index >= encounter.hero_team.size():
		return "Héros"
	var stats: EntityStats = encounter.hero_team[index]
	return "Héros" if stats == null else stats.display_name

func _enemy_name(index: int) -> String:
	if index < 0 or encounter == null or index >= encounter.enemy_team.size():
		return "Ennemi"
	var stats: EntityStats = encounter.enemy_team[index]
	return "Ennemi" if stats == null else stats.display_name
