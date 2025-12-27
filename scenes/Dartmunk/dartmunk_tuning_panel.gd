class_name DartmunkTuningPanel
extends Control

## Runtime tuning panel for Dartmunk enemy parameters.
## Press F1 to toggle visibility. Only works in debug builds.
## Changes apply to newly spawned Dartmunks. Use "Apply All" for existing ones.

signal values_changed

## Current tuning values - SpawnButton reads from this
var tuning_values: Dictionary = {}

## Default values from Dartmunk class (for reset button)
var _default_values: Dictionary = {}

## References to UI controls for updating values
var _controls: Dictionary = {}

## Reference to player for invulnerability toggle
var _player: Player = null

## Property definitions: name -> {type, min, max, step, category, tooltip}
const PROPERTY_DEFS: Dictionary = {
	# Movement
	"ideal_distance": {"type": "float", "min": 50.0, "max": 500.0, "step": 10.0, "category": "Movement",
		"tooltip": "Circle radius around player where Dartmunk tries to position itself"},
	"separation_radius": {"type": "float", "min": 100.0, "max": 2000.0, "step": 50.0, "category": "Movement",
		"tooltip": "Distance threshold for boids separation force between Dartmunks"},
	"separation_weight": {"type": "float", "min": 0.0, "max": 2.0, "step": 0.1, "category": "Movement",
		"tooltip": "Multiplier on separation force (higher = spread out more aggressively)"},
	"move_threshold": {"type": "float", "min": 0.01, "max": 1.0, "step": 0.01, "category": "Movement",
		"tooltip": "Force threshold to START moving (hysteresis lower bound)"},
	"stop_threshold": {"type": "float", "min": 0.01, "max": 1.0, "step": 0.01, "category": "Movement",
		"tooltip": "Force threshold to STOP moving (hysteresis upper bound)"},
	"speed": {"type": "int", "min": 50, "max": 500, "step": 10, "category": "Movement",
		"tooltip": "Movement speed in pixels per second"},
	"view_range": {"type": "int", "min": 100, "max": 600, "step": 25, "category": "Movement",
		"tooltip": "How far the Dartmunk can detect the player"},
	# Attack
	"attack_cooldown": {"type": "float", "min": 0.1, "max": 10.0, "step": 0.1, "category": "Attack",
		"tooltip": "Time between dart shots in seconds"},
	"dart_speed": {"type": "float", "min": 100.0, "max": 1000.0, "step": 10.0, "category": "Attack",
		"tooltip": "Speed of fired darts in pixels per second"},
	"dart_spawn_distance": {"type": "float", "min": 5.0, "max": 100.0, "step": 5.0, "category": "Attack",
		"tooltip": "Distance from center to spawn dart (avoids self-collision)"},
	"attack_exit_multiplier": {"type": "float", "min": 1.0, "max": 20.0, "step": 0.5, "category": "Attack",
		"tooltip": "Multiplier on move_threshold when leaving ATTACK state (higher = more 'sticky')"},
	"prediction_iterations": {"type": "int", "min": 0, "max": 5, "step": 1, "category": "Attack",
		"tooltip": "Aim prediction iterations (higher = more accurate, 2-3 recommended)"},
	"aim_spread_degrees": {"type": "float", "min": 0.0, "max": 45.0, "step": 1.0, "category": "Attack",
		"tooltip": "Random spread applied to aim direction (0 = perfect aim)"},
	# Combat
	"max_hp": {"type": "int", "min": 1, "max": 20, "step": 1, "category": "Combat",
		"tooltip": "Maximum health points"},
	"knockback_multiply": {"type": "int", "min": 0, "max": 10, "step": 1, "category": "Combat",
		"tooltip": "Multiplier on knockback when hit"},
	"knockback_friction": {"type": "int", "min": 100, "max": 2000, "step": 100, "category": "Combat",
		"tooltip": "Friction applied during knockback (deceleration)"},
	# Debug
	"debug_draw": {"type": "bool", "category": "Debug",
		"tooltip": "Toggle debug visualization (nav path, target circles, state labels)"},
}


func _ready() -> void:
	add_to_group("dartmunk_tuning_panel")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_defaults_from_dartmunk()
	_find_player()
	_build_ui()
	visible = false


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as Player


func _load_defaults_from_dartmunk() -> void:
	var dartmunk_scene := preload("res://scenes/Dartmunk/dartmunk.tscn")
	var temp := dartmunk_scene.instantiate()

	for prop_name in PROPERTY_DEFS.keys():
		if prop_name in temp:
			_default_values[prop_name] = temp.get(prop_name)
			tuning_values[prop_name] = temp.get(prop_name)

	temp.free()


func _build_ui() -> void:
	# Setup control anchoring (left side, full height)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 1.0
	offset_right = 380

	# Panel container with dark background
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Scroll container for overflow
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	# Main vertical layout
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header
	_add_header(vbox)

	# Group properties by category
	var categories: Dictionary = {}
	for prop_name in PROPERTY_DEFS.keys():
		var def: Dictionary = PROPERTY_DEFS[prop_name]
		var category: String = def.category
		if category not in categories:
			categories[category] = []
		categories[category].append(prop_name)

	# Build UI for each category
	for category in ["Movement", "Attack", "Combat", "Debug"]:
		if category in categories:
			_add_category_section(vbox, category, categories[category])

	# Add Player section (separate from Dartmunk properties)
	_add_player_section(vbox)


func _add_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()

	var title := Label.new()
	title.text = "Dartmunk Tuning"
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var apply_btn := Button.new()
	apply_btn.text = "Apply All"
	apply_btn.pressed.connect(apply_to_all_dartmunks)
	header.add_child(apply_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(reset_to_defaults)
	header.add_child(reset_btn)

	parent.add_child(header)

	var sep := HSeparator.new()
	parent.add_child(sep)


func _add_category_section(parent: VBoxContainer, category: String, properties: Array) -> void:
	var label := Label.new()
	label.text = category
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	parent.add_child(label)

	for prop_name in properties:
		var def: Dictionary = PROPERTY_DEFS[prop_name]
		var row: HBoxContainer
		if def.type == "bool":
			row = _create_bool_row(prop_name, def)
		else:
			row = _create_numeric_row(prop_name, def)
		parent.add_child(row)

	var sep := HSeparator.new()
	parent.add_child(sep)


func _add_player_section(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Player"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))  # Gold color
	parent.add_child(label)

	# God mode toggle
	var row := HBoxContainer.new()
	row.tooltip_text = "Player takes no damage when enabled"

	var god_mode_label := Label.new()
	god_mode_label.text = "God Mode"
	god_mode_label.custom_minimum_size.x = 140
	god_mode_label.tooltip_text = "Player takes no damage when enabled"
	row.add_child(god_mode_label)

	var checkbox := CheckBox.new()
	checkbox.button_pressed = _player.god_mode if _player else true
	checkbox.toggled.connect(_on_god_mode_toggled)
	row.add_child(checkbox)

	parent.add_child(row)


func _on_god_mode_toggled(enabled: bool) -> void:
	if _player:
		_player.god_mode = enabled
		print("Player god mode: %s" % ("ON" if enabled else "OFF"))


func _create_numeric_row(prop_name: String, def: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Row_" + prop_name
	row.tooltip_text = def.get("tooltip", "")

	# Label
	var label := Label.new()
	label.text = prop_name.replace("_", " ").capitalize()
	label.custom_minimum_size.x = 140
	label.tooltip_text = def.get("tooltip", "")
	row.add_child(label)

	# SpinBox
	var spinbox := SpinBox.new()
	spinbox.min_value = def.min
	spinbox.max_value = def.max
	spinbox.step = def.step
	spinbox.value = tuning_values.get(prop_name, def.min)
	spinbox.custom_minimum_size.x = 80
	spinbox.value_changed.connect(_on_value_changed.bind(prop_name))
	row.add_child(spinbox)

	# Slider
	var slider := HSlider.new()
	slider.min_value = def.min
	slider.max_value = def.max
	slider.step = def.step
	slider.value = tuning_values.get(prop_name, def.min)
	slider.custom_minimum_size.x = 100
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Sync slider with spinbox
	slider.value_changed.connect(func(v): spinbox.value = v)
	spinbox.value_changed.connect(func(v): slider.value = v)
	row.add_child(slider)

	_controls[prop_name] = spinbox
	return row


func _create_bool_row(prop_name: String, def: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Row_" + prop_name
	row.tooltip_text = def.get("tooltip", "")

	var label := Label.new()
	label.text = prop_name.replace("_", " ").capitalize()
	label.custom_minimum_size.x = 140
	label.tooltip_text = def.get("tooltip", "")
	row.add_child(label)

	var checkbox := CheckBox.new()
	checkbox.button_pressed = tuning_values.get(prop_name, false)
	checkbox.toggled.connect(_on_value_changed.bind(prop_name))
	row.add_child(checkbox)

	_controls[prop_name] = checkbox
	return row


func _on_value_changed(new_value, prop_name: String) -> void:
	tuning_values[prop_name] = new_value
	values_changed.emit()


func apply_to_dartmunk(dartmunk: Node) -> void:
	## Apply current tuning values to a single Dartmunk instance
	for prop_name in tuning_values.keys():
		if prop_name in dartmunk:
			dartmunk.set(prop_name, tuning_values[prop_name])


func apply_to_all_dartmunks() -> void:
	## Apply current values to all existing Dartmunks in scene
	var count := 0
	for dartmunk in get_tree().get_nodes_in_group("dartmunks"):
		apply_to_dartmunk(dartmunk)
		count += 1
	print("Applied tuning to %d Dartmunks" % count)


func reset_to_defaults() -> void:
	## Reset all values to Dartmunk class defaults
	for prop_name in _default_values.keys():
		tuning_values[prop_name] = _default_values[prop_name]
		_update_control(prop_name, _default_values[prop_name])
	print("Reset tuning to defaults")


func _update_control(prop_name: String, value) -> void:
	if prop_name in _controls:
		var control = _controls[prop_name]
		if control is SpinBox:
			control.value = value
		elif control is CheckBox:
			control.button_pressed = value


func toggle_visibility() -> void:
	visible = !visible
