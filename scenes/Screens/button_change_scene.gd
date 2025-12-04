extends Button

@export var path_to_scene: String = ""

func _ready() -> void:
	pressed.connect(on_pressed)

func on_pressed() -> void:
	GameManager.change_scene(path_to_scene)
