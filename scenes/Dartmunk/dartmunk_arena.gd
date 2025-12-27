extends Node2D
## Dartmunk arena scene for developing and testing the Dartmunk enemy.
##
## Usage: Open this scene in Godot and run it (F6) to test Dartmunk behaviors.
## Press F1 to toggle the Dartmunk tuning panel.

@onready var room: Area2D = $Room
@onready var player: CharacterBody2D = $Player

var tuning_panel: DartmunkTuningPanel


func _ready() -> void:
	if room:
		room.set_as_current_room()

	# Enable god mode for testing
	if player:
		player.god_mode = true

	# Create tuning panel (debug builds only)
	if OS.is_debug_build():
		_create_tuning_panel()


func _create_tuning_panel() -> void:
	# Wrap in CanvasLayer so it renders on top of game view
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to be on top
	add_child(canvas_layer)

	tuning_panel = DartmunkTuningPanel.new()
	canvas_layer.add_child(tuning_panel)


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F1:
			if tuning_panel:
				tuning_panel.toggle_visibility()
			get_viewport().set_input_as_handled()
