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
var _ally_target_style: StyleBoxFlat
var _end_turn_style: StyleBoxFlat
var _end_turn_disabled_style: StyleBoxFlat

func _ready() -> void:
	if encounter == null:
		push_error("EncounterData is missing on battle scene.")
		return

	_setup_styles()
	_battle.state_updated.connect(_refresh_ui)
	_battle.battle_finished.connect(_on_battle_finished)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	replay_button.pressed.connect(_on_replay_pressed)

	_battle.start_battle(encounter)

func _refresh_ui() -> void:
	_refresh_team_bars()
	turn_label.text = "Tour %d" % _battle.turn_count
	result_label.text = _battle.result_text
	if _battle.is_ally_selection_active():
		result_label.text = "Choisis un allie pour le buff (sinon cible par defaut)."
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
		action_slots_container.add_child(slot_panel)

	var can_end_turn := not _is_resolving_turn and not _battle.is_battle_over and _battle.has_pending_actions()
	end_turn_button.disabled = not can_end_turn
	end_turn_button.add_theme_stylebox_override("normal", _end_turn_style if can_end_turn else _end_turn_disabled_style)
	end_turn_button.add_theme_stylebox_override("hover", _end_turn_style if can_end_turn else _end_turn_disabled_style)
	end_turn_button.add_theme_stylebox_override("pressed", _end_turn_style if can_end_turn else _end_turn_disabled_style)

func _on_card_pressed(index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if not _battle.queue_card_from_hand(index):
		return

	if _battle.are_action_slots_full():
		await _execute_turn()

func _on_end_turn_pressed() -> void:
	await _execute_turn()

func _execute_turn() -> void:
	if _is_resolving_turn:
		return
	if _battle.is_battle_over:
		return
	if not _battle.has_pending_actions():
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
	if card == null or card.data == null or encounter == null or encounter.hero_team.is_empty():
		return ""
	var card_id := String(card.data.id)
	if card_id == "mage_heal":
		return "✚ Soin cible faible"
	if card_id == "mage_focus":
		return "⬆ Buff ATK 2 tours"
	if card_id == "defend":
		return "🛡 Buff defense equipe"
	if card_id == "fireball":
		return "🔥 Zone tous ennemis"
	if card_id == "magic_bolt":
		return "⚔ Tir magique"
	var attacker_index := _battle.get_first_alive_hero_index()
	if attacker_index == -1:
		attacker_index = 0
	if attacker_index < 0 or attacker_index >= encounter.hero_team.size():
		return ""
	var attacker_stats: EntityStats = encounter.hero_team[attacker_index]
	if attacker_stats == null:
		return ""
	var damage := DamageService.compute_damage(card, attacker_stats)
	return "⚔ %d degats" % damage

func _refresh_team_bars() -> void:
	for child in hero_team_container.get_children():
		child.queue_free()
	for child in enemy_team_container.get_children():
		child.queue_free()

	for i in range(encounter.hero_team.size()):
		var stats: EntityStats = encounter.hero_team[i]
		var hp := _battle.hero_hp[i] if i < _battle.hero_hp.size() else 0
		var bar := _build_unit_hp_bar(stats, hp, false, i)
		hero_team_container.add_child(bar)

	for i in range(encounter.enemy_team.size()):
		var stats: EntityStats = encounter.enemy_team[i]
		var hp := _battle.enemy_hp[i] if i < _battle.enemy_hp.size() else 0
		var bar := _build_unit_hp_bar(stats, hp, true, i)
		enemy_team_container.add_child(bar)

func _build_unit_hp_bar(stats: EntityStats, current_hp: int, is_enemy: bool, unit_index: int) -> Panel:
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
	var name := "Inconnu" if stats == null else stats.display_name
	var buff_text := ""
	if not is_enemy:
		buff_text = _battle.get_hero_buff_text(unit_index)
	var separator := "  " if buff_text.is_empty() else "  •  "
	text.text = "%s  %d/%d%s%s" % [name, maxi(0, current_hp), max_hp, separator, buff_text]
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
	if is_enemy and is_alive:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_ARROW if _is_resolving_turn or _battle.is_battle_over else Control.CURSOR_POINTING_HAND
		if unit_index == _battle.selected_enemy_target_index:
			panel.add_theme_stylebox_override("panel", _enemy_target_style)
		panel.gui_input.connect(_on_enemy_target_gui_input.bind(unit_index))
	elif (not is_enemy) and is_alive and _battle.is_ally_selection_active():
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_ARROW if _is_resolving_turn or _battle.is_battle_over else Control.CURSOR_POINTING_HAND
		if unit_index == _battle.get_pending_ally_target_index():
			panel.add_theme_stylebox_override("panel", _ally_target_style)
		panel.gui_input.connect(_on_ally_target_gui_input.bind(unit_index))

	return panel

func _on_enemy_target_gui_input(event: InputEvent, enemy_index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_battle.set_selected_enemy_target(enemy_index)

func _on_ally_target_gui_input(event: InputEvent, hero_index: int) -> void:
	if _is_resolving_turn or _battle.is_battle_over:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_battle.set_pending_ally_target(hero_index)

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
