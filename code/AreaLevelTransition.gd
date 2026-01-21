extends Area2D

@export var path_to_level: String

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player and path_to_level != "":
		var level = get_parent()
		while level.get_script().get_global_name() != "Level":
			level = level.get_parent()
		level.load_level(path_to_level)
