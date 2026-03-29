extends Control

@export var encounter: EncounterData = preload("res://data/test/encounter_demo.tres")

@onready var background: Panel = $Background
@onready var hero_team_container: HBoxContainer = %HeroTeamContainer
@onready var enemy_team_container: HBoxContainer = %EnemyTeamContainer
@onready var turn_label: Label = %TurnLabel
@onready var hand_container: HBoxContainer = %HandContainer
@onready var action_slots_container: HBoxContainer = %ActionSlotsContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var result_label: Label = %ResultLabel
@onready var replay_button: Button = %ReplayButton

var _battle := BattleService.new()
var _is_resolving_turn: bool = false
var _base_card_style: StyleBoxFlat
var _hover_card_style: StyleBoxFlat
var _selected_card_style: StyleBoxFlat
var _slot_empty_style: StyleBoxFlat
var _zone_style: StyleBoxFlat
var _background_style: StyleBoxFlat
var _enemy_target_style: StyleBoxFlat
var _enemy_pending_style: StyleBoxFlat
var _ally_target_style: StyleBoxFlat
var _end_turn_style: StyleBoxFlat
var _end_turn_disabled_style: StyleBoxFlat

var _journal_entries: Array[String] = []
var _journal_overlay: Panel
var _journal_scroll: ScrollContainer
var _journal_vbox: VBoxContainer

func _ready() -> void:
	if encounter == null:
		push_error("EncounterData is missing on battle scene.")
		return

	_setup_styles()
	_build_journal_overlay()
	_build_journal_button()
	_battle.state_updated.connect(_refresh_ui)
	_battle.battle_finished.connect(_on_battle_finished)
	_battle.battle_event.connect(_on_battle_event)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	replay_button.pressed.connect(_on_replay_pressed)

	_battle.start_battle(encounter)

# ── Rafraîchissement UI ────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	_refresh_team_bars()
	turn_label.text = "Tour %d" % _battle.turn_count
	result_label.text = _battle.result_text

	if _battle.is_waiting_for_target():
		match _battle.get_pending_target_type():
			CardData.TargetType.SINGLE_ENEMY:
				result_label.text = "Sélectionne une cible ennemie."
			CardData.TargetType.ALLY_SINGLE:
				result_label.text = "Sélectionne un allié cible."

	replay_button.visible = _battle.is_battle_over

	for child in hand_container.get_children():
		child.queue_free()

	for i in range(BattleService.HAND_TARGET_SIZE):
		var card: CardInstance = _battle.hand[i] if i < _battle.hand.size() else null
		var panel := _build_card_panel(card, false)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		panel.custom_minimum_size = Vector2(110, 132)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.modulate = Color.WHITE if card != null else Color(1, 1, 1, 0.45)
		if card != null:
			var disabled := _is_resolving_turn or _battle.is_battle_over
			panel.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
			panel.gui_input.connect(_on_hand_card_gui_input.bind(i))
			panel.mouse_entered.connect(_on_card_hover_changed.bind(panel, true))
			panel.mouse_exited.connect(_on_card_hover_changed.bind(panel, false))
		hand_container.add_child(panel)

	for child in action_slots_container.get_children():
		child.queue_free()

	for i in range(BattleService.ACTION_SLOT_COUNT):
		var slot_action: BattleService.QueuedAction = _battle.action_slots[i] as BattleService.QueuedAction
		var slot_card: CardInstance = null if slot_action == null else slot_action.card
		var is_filled := slot_card != null
		var slot_panel := _build_card_panel(slot_card, true)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot_panel.custom_minimum_size = Vector2(96, 92)
		if not is_filled:
			slot_panel.add_theme_stylebox_override("panel", _slot_empty_style)
		# Indicateur visuel sur le slot en attente de cible
		elif slot_action != null and slot_action.needs_target_confirmation:
			var waiting_style := _selected_card_style.duplicate() as StyleBoxFlat
			waiting_style.border_color = Color(1.0, 0.6, 0.2)
			slot_panel.add_theme_stylebox_override("panel", waiting_style)
		action_slots_container.add_child(slot_panel)

	var can_end_turn := not _is_resolving_turn and not _battle.is_battle_over \
		and _battle.has_pending_actions() and not _battle.is_waiting_for_target()
	end_turn_button.disabled = not can_end_turn
	end_turn_button.add_theme_stylebox_override("normal", _end_turn_style if can_end_turn else _end_turn_disabled_style)
	end_turn_button.add_theme_stylebox_override("hover", _end_turn_style if can_end_turn else _end_turn_disabled_style)
	end_turn_button.add_theme_stylebox_override("pressed", _end_turn_style if can_end_turn else _end_turn_disabled_style)

# ── Interactions joueur ────────────────────────────────────────────────────────

func _on_card_pressed(index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if not _battle.queue_card_from_hand(index):
		return
	# Auto-execute uniquement si tous les slots sont remplis ET aucune cible en attente
	if _battle.are_action_slots_full() and not _battle.is_waiting_for_target():
		await _execute_turn()

func _on_end_turn_pressed() -> void:
	if _battle.is_waiting_for_target():
		return
	await _execute_turn()

func _execute_turn() -> void:
	if _is_resolving_turn or _battle.is_battle_over or not _battle.has_pending_actions():
		return
	_is_resolving_turn = true
	_refresh_ui()
	await _battle.execute_turn(get_tree())
	_is_resolving_turn = false
	_refresh_ui()

func _on_battle_finished(_text: String) -> void:
	_refresh_ui()

func _on_replay_pressed() -> void:
	_is_resolving_turn = false
	_clear_journal()
	_battle.start_battle(encounter)

func _on_hand_card_gui_input(event: InputEvent, hand_index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_card_pressed(hand_index)

func _on_card_hover_changed(panel: Panel, is_hovered: bool) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", _hover_card_style if is_hovered else _base_card_style)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(1.03, 1.03) if is_hovered else Vector2.ONE, 0.12)

func _on_enemy_target_gui_input(event: InputEvent, enemy_index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _battle.is_waiting_for_target() and \
					_battle.get_pending_target_type() == CardData.TargetType.SINGLE_ENEMY:
				var all_done := _battle.confirm_target(enemy_index)
				if all_done and _battle.are_action_slots_full():
					await _execute_turn()
			else:
				_battle.set_selected_enemy_target(enemy_index)

func _on_ally_target_gui_input(event: InputEvent, hero_index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _battle.is_waiting_for_target() and \
					_battle.get_pending_target_type() == CardData.TargetType.ALLY_SINGLE:
				var all_done := _battle.confirm_target(hero_index)
				if all_done and _battle.are_action_slots_full():
					await _execute_turn()

# ── Construction UI ────────────────────────────────────────────────────────────

func _build_card_panel(card: CardInstance, is_mini: bool) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _selected_card_style if is_mini and card != null else _base_card_style)

	var margin := MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 8.0
	margin.offset_top = 8.0
	margin.offset_right = -8.0
	margin.offset_bottom = -8.0
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 16 if not is_mini else 13)
	name_label.text = card.data.display_name if card != null and card.data != null else "Slot vide"
	vbox.add_child(name_label)

	var stars_label := Label.new()
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stars_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stars_label.add_theme_color_override("font_color", Color("e2b04a"))
	stars_label.add_theme_font_size_override("font_size", 28 if not is_mini else 20)
	stars_label.text = _rank_to_stars(card.rank) if card != null else ""
	vbox.add_child(stars_label)

	var damage_label := Label.new()
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	damage_label.add_theme_font_size_override("font_size", 14 if not is_mini else 12)
	damage_label.text = _get_damage_text(card)
	vbox.add_child(damage_label)

	return panel

func _get_damage_text(card: CardInstance) -> String:
	if card == null or card.data == null:
		return ""

	var attacker_index := _battle.get_first_alive_hero_index()
	if attacker_index < 0:
		attacker_index = 0
	var attacker_stats: EntityStats = null
	if encounter != null and attacker_index < encounter.hero_team.size():
		attacker_stats = encounter.hero_team[attacker_index]

	var parts: Array[String] = []
	for effect in card.data.effects:
		var rank_index := card.rank - 1
		var base := effect.value_by_rank[rank_index] if rank_index < effect.value_by_rank.size() else 0
		match effect.effect_type:
			CardEffect.EffectType.DAMAGE:
				var dmg := base + (attacker_stats.attack_stat if attacker_stats != null else 0)
				parts.append("⚔ %d dégâts" % dmg)
			CardEffect.EffectType.HEAL:
				var h := base + (attacker_stats.attack_stat if attacker_stats != null else 0)
				parts.append("✚ +%d PV" % h)
			CardEffect.EffectType.POISON:
				parts.append("☠ Poison (%d tours)" % effect.duration)
			CardEffect.EffectType.WEAKEN:
				parts.append("⬇ -30%% ATK (%d tours)" % effect.duration)
			CardEffect.EffectType.ATK_BUFF:
				parts.append("⬆ +%d%% ATK (%d tours)" % [base, effect.duration])
			CardEffect.EffectType.DEF_BUFF:
				parts.append("🛡 +%d%% DEF (%d tours)" % [base, effect.duration])

	if parts.is_empty():
		# Fallback pour les cartes sans effets déclarés
		if attacker_stats != null:
			var dmg := DamageService.compute_damage(card, attacker_stats)
			if dmg > 0:
				return "⚔ %d dégâts" % dmg
		return "..."

	return " | ".join(parts)

func _refresh_team_bars() -> void:
	for child in hero_team_container.get_children():
		child.queue_free()
	for child in enemy_team_container.get_children():
		child.queue_free()

	for i in range(encounter.hero_team.size()):
		var stats: EntityStats = encounter.hero_team[i]
		var hp := _battle.hero_hp[i] if i < _battle.hero_hp.size() else 0
		hero_team_container.add_child(_build_unit_hp_bar(stats, hp, false, i))

	for i in range(encounter.enemy_team.size()):
		var stats: EntityStats = encounter.enemy_team[i]
		var hp := _battle.enemy_hp[i] if i < _battle.enemy_hp.size() else 0
		enemy_team_container.add_child(_build_unit_hp_bar(stats, hp, true, i))

func _build_unit_hp_bar(stats: EntityStats, current_hp: int, is_enemy: bool, unit_index: int) -> Control:
	if not is_enemy:
		var wrapper := VBoxContainer.new()
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrapper.add_theme_constant_override("separation", 3)
		wrapper.add_child(_build_hp_panel(stats, current_hp, false, unit_index))
		wrapper.add_child(_build_energy_bar(unit_index))
		return wrapper
	return _build_hp_panel(stats, current_hp, true, unit_index)

func _build_energy_bar(hero_index: int) -> ProgressBar:
	var energy := _battle.hero_special_energy[hero_index] if hero_index < _battle.hero_special_energy.size() else 0
	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = energy
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.08, 0.02, 0.9)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e2b04a") if energy < 100 else Color(1.0, 1.0, 0.4)
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_hp_panel(stats: EntityStats, current_hp: int, is_enemy: bool, unit_index: int) -> Panel:
	var panel := Panel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 44)
	panel.add_theme_stylebox_override("panel", _zone_style)

	var margin := MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 6.0
	margin.offset_top = 6.0
	margin.offset_right = -6.0
	margin.offset_bottom = -6.0
	panel.add_child(margin)

	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var max_hp := 1 if stats == null else maxi(1, stats.max_hp)
	bar.max_value = max_hp
	bar.value = maxi(0, current_hp)
	margin.add_child(bar)

	var text := Label.new()
	text.anchors_preset = Control.PRESET_CENTER
	text.anchor_left = 0.5
	text.anchor_top = 0.5
	text.anchor_right = 0.5
	text.anchor_bottom = 0.5
	text.offset_left = -140.0
	text.offset_top = -10.0
	text.offset_right = 140.0
	text.offset_bottom = 10.0
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var unit_name := "Inconnu" if stats == null else stats.display_name
	var status_text := _battle.get_hero_buff_text(unit_index) if not is_enemy \
		else _battle.get_enemy_status_text(unit_index)
	var separator := "  " if status_text.is_empty() else "  •  "
	text.text = "%s  %d/%d%s%s" % [unit_name, maxi(0, current_hp), max_hp, separator, status_text]
	text.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(text)

	var ratio: float = clampf(float(maxi(0, current_hp)) / float(max_hp), 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	bg.corner_radius_top_left = 8
	bg.corner_radius_top_right = 8
	bg.corner_radius_bottom_left = 8
	bg.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0 - ratio, ratio, 0.2, 1.0)
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_left = 8
	fill.corner_radius_bottom_right = 8
	bar.add_theme_stylebox_override("fill", fill)

	var is_alive := current_hp > 0
	panel.modulate = Color.WHITE if is_alive else Color(0.55, 0.55, 0.55, 0.85)

	var is_pending_enemy := _battle.is_waiting_for_target() and \
		_battle.get_pending_target_type() == CardData.TargetType.SINGLE_ENEMY
	var is_pending_ally := _battle.is_waiting_for_target() and \
		_battle.get_pending_target_type() == CardData.TargetType.ALLY_SINGLE

	if is_enemy and is_alive:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var interactive := not _is_resolving_turn and not _battle.is_battle_over
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
		if is_pending_enemy:
			# Tous les ennemis vivants sont surlignés comme cibles valides
			panel.add_theme_stylebox_override("panel", _enemy_pending_style)
		elif unit_index == _battle.selected_enemy_target_index:
			panel.add_theme_stylebox_override("panel", _enemy_target_style)
		panel.gui_input.connect(_on_enemy_target_gui_input.bind(unit_index))

	elif not is_enemy and is_alive and is_pending_ally:
		# Tous les alliés vivants sont surlignés comme cibles valides
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.add_theme_stylebox_override("panel", _ally_target_style)
		panel.gui_input.connect(_on_ally_target_gui_input.bind(unit_index))

	return panel

# ── Journal de combat ──────────────────────────────────────────────────────────

func _on_battle_event(text: String) -> void:
	_journal_entries.append(text)

func _build_journal_button() -> void:
	var btn := Button.new()
	btn.text = "Journal"
	btn.custom_minimum_size = Vector2(100, 36)
	btn.anchor_left = 0.0
	btn.anchor_top = 0.0
	btn.anchor_right = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = 16.0
	btn.offset_top = 16.0
	btn.offset_right = 116.0
	btn.offset_bottom = 52.0
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("16213e")
	btn_style.border_color = Color("e2b04a")
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_color_override("font_color", Color("e2b04a"))
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_toggle_journal)
	add_child(btn)

func _build_journal_overlay() -> void:
	_journal_overlay = Panel.new()
	_journal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_journal_overlay.visible = false
	var overlay_bg := StyleBoxFlat.new()
	overlay_bg.bg_color = Color(0.04, 0.04, 0.10, 0.95)
	_journal_overlay.add_theme_stylebox_override("panel", overlay_bg)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer_margin.add_theme_constant_override("margin_left", 40)
	outer_margin.add_theme_constant_override("margin_top", 40)
	outer_margin.add_theme_constant_override("margin_right", 40)
	outer_margin.add_theme_constant_override("margin_bottom", 40)
	_journal_overlay.add_child(outer_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	outer_margin.add_child(main_vbox)

	var header := HBoxContainer.new()
	main_vbox.add_child(header)
	var title_lbl := Label.new()
	title_lbl.text = "Journal de combat"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_color_override("font_color", Color("e2b04a"))
	title_lbl.add_theme_font_size_override("font_size", 22)
	header.add_child(title_lbl)
	var close_btn := Button.new()
	close_btn.text = "✕ Fermer"
	close_btn.add_theme_color_override("font_color", Color("e2b04a"))
	close_btn.add_theme_font_size_override("font_size", 16)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("16213e")
	close_style.border_color = Color("e2b04a")
	close_style.border_width_left = 1
	close_style.border_width_right = 1
	close_style.border_width_top = 1
	close_style.border_width_bottom = 1
	close_style.corner_radius_top_left = 6
	close_style.corner_radius_top_right = 6
	close_style.corner_radius_bottom_left = 6
	close_style.corner_radius_bottom_right = 6
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	close_btn.pressed.connect(_toggle_journal)
	header.add_child(close_btn)

	main_vbox.add_child(HSeparator.new())

	_journal_scroll = ScrollContainer.new()
	_journal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_journal_scroll)

	_journal_vbox = VBoxContainer.new()
	_journal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_vbox.add_theme_constant_override("separation", 6)
	_journal_scroll.add_child(_journal_vbox)

	add_child(_journal_overlay)

func _toggle_journal() -> void:
	_journal_overlay.visible = not _journal_overlay.visible
	if _journal_overlay.visible:
		_rebuild_journal_content()

func _rebuild_journal_content() -> void:
	for child in _journal_vbox.get_children():
		child.queue_free()
	for entry in _journal_entries:
		_add_journal_entry_label(entry)
	_journal_scroll.call_deferred("set_v_scroll", 999999)

func _add_journal_entry_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	lbl.add_theme_font_size_override("font_size", 14)
	_journal_vbox.add_child(lbl)

func _clear_journal() -> void:
	_journal_entries.clear()
	if _journal_vbox != null:
		for child in _journal_vbox.get_children():
			child.queue_free()

# ── Styles ─────────────────────────────────────────────────────────────────────

func _setup_styles() -> void:
	_background_style = StyleBoxFlat.new()
	_background_style.bg_color = Color("1a1a2e")
	background.add_theme_stylebox_override("panel", _background_style)

	_zone_style = StyleBoxFlat.new()
	_zone_style.bg_color = Color(0.11, 0.11, 0.2, 0.7)
	_zone_style.border_width_left = 1
	_zone_style.border_width_right = 1
	_zone_style.border_width_top = 1
	_zone_style.border_width_bottom = 1
	_zone_style.border_color = Color(0.7, 0.7, 0.8, 0.2)
	_zone_style.corner_radius_top_left = 10
	_zone_style.corner_radius_top_right = 10
	_zone_style.corner_radius_bottom_left = 10
	_zone_style.corner_radius_bottom_right = 10
	$Background/RootMargin/MainVBox/EnemyZone.add_theme_stylebox_override("panel", _zone_style)
	$Background/RootMargin/MainVBox/ActionZone.add_theme_stylebox_override("panel", _zone_style)
	$Background/RootMargin/MainVBox/PlayerZone.add_theme_stylebox_override("panel", _zone_style)

	_base_card_style = StyleBoxFlat.new()
	_base_card_style.bg_color = Color("16213e")
	_base_card_style.border_color = Color("e2b04a")
	_base_card_style.border_width_left = 2
	_base_card_style.border_width_right = 2
	_base_card_style.border_width_top = 2
	_base_card_style.border_width_bottom = 2
	_base_card_style.corner_radius_top_left = 12
	_base_card_style.corner_radius_top_right = 12
	_base_card_style.corner_radius_bottom_left = 12
	_base_card_style.corner_radius_bottom_right = 12

	_hover_card_style = _base_card_style.duplicate() as StyleBoxFlat
	_hover_card_style.border_color = Color(1.0, 0.86, 0.45)

	_selected_card_style = _base_card_style.duplicate() as StyleBoxFlat
	_selected_card_style.border_color = Color(1.0, 0.95, 0.6)
	_selected_card_style.border_width_left = 3
	_selected_card_style.border_width_right = 3
	_selected_card_style.border_width_top = 3
	_selected_card_style.border_width_bottom = 3

	_slot_empty_style = StyleBoxFlat.new()
	_slot_empty_style.bg_color = Color(0.08, 0.08, 0.13, 0.45)
	_slot_empty_style.border_color = Color(0.85, 0.85, 0.9, 0.35)
	_slot_empty_style.border_width_left = 2
	_slot_empty_style.border_width_right = 2
	_slot_empty_style.border_width_top = 2
	_slot_empty_style.border_width_bottom = 2
	_slot_empty_style.corner_radius_top_left = 10
	_slot_empty_style.corner_radius_top_right = 10
	_slot_empty_style.corner_radius_bottom_left = 10
	_slot_empty_style.corner_radius_bottom_right = 10

	_enemy_target_style = _zone_style.duplicate() as StyleBoxFlat
	_enemy_target_style.border_color = Color("e2b04a")
	_enemy_target_style.border_width_left = 2
	_enemy_target_style.border_width_right = 2
	_enemy_target_style.border_width_top = 2
	_enemy_target_style.border_width_bottom = 2

	# Style "en attente de confirmation" : or plus vif + bordure plus épaisse
	_enemy_pending_style = _zone_style.duplicate() as StyleBoxFlat
	_enemy_pending_style.border_color = Color(1.0, 0.9, 0.3)
	_enemy_pending_style.border_width_left = 3
	_enemy_pending_style.border_width_right = 3
	_enemy_pending_style.border_width_top = 3
	_enemy_pending_style.border_width_bottom = 3

	_ally_target_style = _zone_style.duplicate() as StyleBoxFlat
	_ally_target_style.border_color = Color(0.45, 0.95, 1.0)
	_ally_target_style.border_width_left = 2
	_ally_target_style.border_width_right = 2
	_ally_target_style.border_width_top = 2
	_ally_target_style.border_width_bottom = 2

	_end_turn_style = StyleBoxFlat.new()
	_end_turn_style.bg_color = Color("e2b04a")
	_end_turn_style.corner_radius_top_left = 10
	_end_turn_style.corner_radius_top_right = 10
	_end_turn_style.corner_radius_bottom_left = 10
	_end_turn_style.corner_radius_bottom_right = 10

	_end_turn_disabled_style = StyleBoxFlat.new()
	_end_turn_disabled_style.bg_color = Color(0.5, 0.45, 0.35, 0.6)
	_end_turn_disabled_style.corner_radius_top_left = 10
	_end_turn_disabled_style.corner_radius_top_right = 10
	_end_turn_disabled_style.corner_radius_bottom_left = 10
	_end_turn_disabled_style.corner_radius_bottom_right = 10

	end_turn_button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	end_turn_button.add_theme_font_size_override("font_size", 22)
	replay_button.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_font_size_override("font_size", 24)
	result_label.add_theme_color_override("font_color", Color("e2b04a"))
	turn_label.add_theme_font_size_override("font_size", 26)
	turn_label.add_theme_color_override("font_color", Color("e2b04a"))
	$Background/RootMargin/MainVBox/EnemyZone/EnemyZoneMargin/EnemyVBox/EnemyTitleLabel.add_theme_color_override("font_color", Color.WHITE)
	$Background/RootMargin/MainVBox/ActionZone/ActionZoneMargin/ActionVBox/ActionSlotsTitleLabel.add_theme_color_override("font_color", Color.WHITE)
	$Background/RootMargin/MainVBox/PlayerZone/PlayerZoneMargin/PlayerVBox/PlayerTitleLabel.add_theme_color_override("font_color", Color.WHITE)
	$Background/RootMargin/MainVBox/PlayerZone/PlayerZoneMargin/PlayerVBox/HandTitleLabel.add_theme_color_override("font_color", Color.WHITE)

func _rank_to_stars(rank: int) -> String:
	var safe_rank := maxi(1, rank)
	return "★".repeat(safe_rank)
