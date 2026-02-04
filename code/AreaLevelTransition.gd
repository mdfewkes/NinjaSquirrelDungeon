extends Area2D

@export var path_to_level: String

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _get_parent_level() -> Level:
	var parent = get_parent()
	while parent and not parent is Level:
		parent = parent.get_parent()
	return parent

func _on_body_entered(body: Node2D):
	if body is Player and path_to_level != "":
		StateManager.clear_key("respawn_point")
		_get_parent_level().load_level(path_to_level)
