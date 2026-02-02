extends Control

func _ready() -> void:
	var parent = $LoreTextParent
	var label = $LoreTextParent/CutsceneTextLabel
	label.text = _load_from_file()
	var tween = create_tween()
	tween.tween_property(parent, "position", Vector2(label.position.x, -1000), 100.0)
	
func _load_from_file():
	var file = FileAccess.open("res://opening_lore_scroll.md", FileAccess.READ)
	var content = file.get_as_text()
	return content
