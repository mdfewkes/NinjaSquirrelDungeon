extends Button

@export var path_to_scene: String = ""
@export var start_with_focus := false

func _ready() -> void:
	pressed.connect(on_pressed)
	if start_with_focus:
		grab_focus()

func on_pressed() -> void:
	GameManager.change_scene(path_to_scene)
