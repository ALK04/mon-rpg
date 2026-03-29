extends Control

const MAX_TEAM_SIZE := 3

@export var base_encounter: EncounterData = preload("res://data/test/encounter_demo.tres")

var _available_heroes: Array[EntityStats] = [
	preload("res://data/test/hero_knight.tres"),
	preload("res://data/test/hero_mage.tres"),
	preload("res://data/entities/hero_sorcier.tres"),
]
var _team_slots: Array = []

@onready var slots_title: Label = %SlotsTitleLabel
@onready var slots_container: VBoxContainer = %SlotsContainer
@onready var hero_list_container: VBoxContainer = %HeroListContainer
@onready var combat_button: Button = %CombatButton

var _hero_card_style: StyleBoxFlat
var _slot_filled_style: StyleBoxFlat
var _slot_empty_style: StyleBoxFlat
var _combat_btn_style: StyleBoxFlat
var _combat_btn_disabled_style: StyleBoxFlat

func _ready() -> void:
	_team_slots.resize(MAX_TEAM_SIZE)
	_team_slots.fill(null)
	_setup_styles()
	combat_button.pressed.connect(_on_combat_pressed)
	_refresh_ui()

func _setup_styles() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("1a1a2e")
	$Background.add_theme_stylebox_override("panel", bg_style)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.11, 0.2, 0.7)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.7, 0.7, 0.8, 0.2)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	$Background/RootMargin/MainVBox/ContentHBox/SlotsPanel.add_theme_stylebox_override("panel", panel_style)
	$Background/RootMargin/MainVBox/ContentHBox/HeroListPanel.add_theme_stylebox_override("panel", panel_style)

	_hero_card_style = StyleBoxFlat.new()
	_hero_card_style.bg_color = Color("16213e")
	_hero_card_style.border_color = Color("e2b04a")
	_hero_card_style.border_width_left = 2
	_hero_card_style.border_width_right = 2
	_hero_card_style.border_width_top = 2
	_hero_card_style.border_width_bottom = 2
	_hero_card_style.corner_radius_top_left = 10
	_hero_card_style.corner_radius_top_right = 10
	_hero_card_style.corner_radius_bottom_left = 10
	_hero_card_style.corner_radius_bottom_right = 10

	_slot_filled_style = _hero_card_style.duplicate() as StyleBoxFlat
	_slot_filled_style.border_color = Color(0.45, 0.95, 1.0)

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

	_combat_btn_style = StyleBoxFlat.new()
	_combat_btn_style.bg_color = Color("e2b04a")
	_combat_btn_style.corner_radius_top_left = 10
	_combat_btn_style.corner_radius_top_right = 10
	_combat_btn_style.corner_radius_bottom_left = 10
	_combat_btn_style.corner_radius_bottom_right = 10

	_combat_btn_disabled_style = StyleBoxFlat.new()
	_combat_btn_disabled_style.bg_color = Color(0.5, 0.45, 0.35, 0.6)
	_combat_btn_disabled_style.corner_radius_top_left = 10
	_combat_btn_disabled_style.corner_radius_top_right = 10
	_combat_btn_disabled_style.corner_radius_bottom_left = 10
	_combat_btn_disabled_style.corner_radius_bottom_right = 10

	combat_button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	combat_button.add_theme_font_size_override("font_size", 22)

	var title := $Background/RootMargin/MainVBox/TitleLabel as Label
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("e2b04a"))

	slots_title.add_theme_font_size_override("font_size", 16)
	slots_title.add_theme_color_override("font_color", Color.WHITE)

	var hero_list_title := $Background/RootMargin/MainVBox/ContentHBox/HeroListPanel/HeroListMargin/HeroListVBox/HeroListTitleLabel as Label
	hero_list_title.add_theme_font_size_override("font_size", 16)
	hero_list_title.add_theme_color_override("font_color", Color.WHITE)

# ── Rafraîchissement UI ────────────────────────────────────────────────────────

func _refresh_ui() -> void:
	_rebuild_slots()
	_rebuild_hero_list()
	_refresh_combat_button()

func _rebuild_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()

	var filled := _team_slots.filter(func(s): return s != null).size()
	slots_title.text = "Équipe de combat (%d/%d)" % [filled, MAX_TEAM_SIZE]

	for i in range(MAX_TEAM_SIZE):
		var hero: EntityStats = _team_slots[i] as EntityStats
		slots_container.add_child(_build_slot_panel(hero, i))

func _build_slot_panel(hero: EntityStats, slot_index: int) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 72)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _slot_filled_style if hero != null else _slot_empty_style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", Color.WHITE if hero != null else Color(0.5, 0.5, 0.5))
	name_label.add_theme_font_size_override("font_size", 16)

	if hero != null:
		name_label.text = hero.display_name
		var stats_label := Label.new()
		stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		stats_label.add_theme_font_size_override("font_size", 13)
		stats_label.text = "PV %d  ATK %d" % [hero.max_hp, hero.attack_stat]

		var remove_btn := Button.new()
		remove_btn.text = "✕"
		remove_btn.add_theme_font_size_override("font_size", 14)
		remove_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		remove_btn.pressed.connect(_on_slot_remove_pressed.bind(slot_index))

		hbox.add_child(name_label)
		hbox.add_child(stats_label)
		hbox.add_child(remove_btn)
	else:
		name_label.text = "Slot vide"
		hbox.add_child(name_label)

	return panel

func _rebuild_hero_list() -> void:
	for child in hero_list_container.get_children():
		child.queue_free()

	for i in range(_available_heroes.size()):
		hero_list_container.add_child(_build_hero_card(_available_heroes[i], i))

func _build_hero_card(hero: EntityStats, hero_index: int) -> Panel:
	var in_team := _team_slots.has(hero)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 72)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := _hero_card_style.duplicate() as StyleBoxFlat
	if in_team:
		style.bg_color = Color(0.08, 0.18, 0.08, 0.7)
		style.border_color = Color(0.3, 0.7, 0.3)
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(0.7, 0.7, 0.7, 0.85) if in_team else Color.WHITE

	if not in_team:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(_on_hero_card_gui_input.bind(hero_index))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.text = hero.display_name
	vbox.add_child(name_label)

	var stats_label := Label.new()
	stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.text = "PV %d  ATK %d" % [hero.max_hp, hero.attack_stat]
	vbox.add_child(stats_label)

	if in_team:
		var status_label := Label.new()
		status_label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4))
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.text = "✓ Dans l'équipe"
		vbox.add_child(status_label)

	return panel

# ── Interactions ───────────────────────────────────────────────────────────────

func _on_hero_card_gui_input(event: InputEvent, hero_index: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_add_hero_to_team(hero_index)

func _add_hero_to_team(hero_index: int) -> void:
	var hero: EntityStats = _available_heroes[hero_index]
	if _team_slots.has(hero):
		return
	var first_empty := _team_slots.find(null)
	if first_empty == -1:
		return
	_team_slots[first_empty] = hero
	_refresh_ui()

func _on_slot_remove_pressed(slot_index: int) -> void:
	_team_slots[slot_index] = null
	_refresh_ui()

func _refresh_combat_button() -> void:
	var has_hero := _team_slots.any(func(s): return s != null)
	combat_button.disabled = not has_hero
	var style := _combat_btn_style if has_hero else _combat_btn_disabled_style
	combat_button.add_theme_stylebox_override("normal", style)
	combat_button.add_theme_stylebox_override("hover", style)
	combat_button.add_theme_stylebox_override("pressed", style)

func _on_combat_pressed() -> void:
	var selected_heroes: Array[EntityStats] = []
	for slot in _team_slots:
		if slot != null:
			selected_heroes.append(slot as EntityStats)
	if selected_heroes.is_empty():
		return

	var encounter := EncounterData.new()
	encounter.id = &"pre_battle_encounter"
	encounter.display_name = base_encounter.display_name
	encounter.hero_team = selected_heroes
	encounter.enemy_team = base_encounter.enemy_team
	encounter.starting_deck = base_encounter.starting_deck
	encounter.starting_hand_size = base_encounter.starting_hand_size
	encounter.combat_seed = base_encounter.combat_seed

	var battle_scene: PackedScene = load("res://ui/battle_scene.tscn")
	var battle := battle_scene.instantiate() as Control
	battle.encounter = encounter
	get_tree().root.add_child(battle)
	queue_free()
