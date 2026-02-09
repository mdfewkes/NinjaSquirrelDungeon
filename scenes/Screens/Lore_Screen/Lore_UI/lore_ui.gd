extends Control

func _ready() -> void:
	var parent = $LoreTextParent
	var label = $LoreTextParent/CutsceneTextLabel
	var tween = create_tween()
	tween.tween_property(parent, "position", Vector2(label.position.x, -1000), 100.0)
	
