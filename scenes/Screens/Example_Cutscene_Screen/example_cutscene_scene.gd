extends Node2D

func _ready() -> void:
	var label = $CanvasLayer/CutsceneTextLabel
	label.text = _load_from_file()
	var tween = create_tween()
	tween.tween_property(label, "position", Vector2(label.position.x, -1000), 100.0)
	
func _load_from_file():
	var file = FileAccess.open("res://lore.md", FileAccess.READ)
	var content = file.get_as_text()
	return content
