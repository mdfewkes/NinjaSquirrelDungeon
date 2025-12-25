extends Node2D
## Test arena scene for developing and testing enemies.
##
## Usage: Open this scene in Godot and run it (F6) to test enemy behaviors.

@onready var room: Area2D = $Room


func _ready() -> void:
	if room:
		room.set_as_current_room()
