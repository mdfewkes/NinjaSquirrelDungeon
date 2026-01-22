extends Room

## If set, this dialog will play before the cut scene starts
@export var dialog_script_path: String

@onready var anim: AnimationPlayer = $AnimationPlayer

func _start_cut_scene() -> void:
	if dialog_script_path:
		DialogueBox.show_dialogue(dialog_script_path, {})
		await DialogueBox.dialogue_finished
	
	# TODO: start music
	
	var player: Player = get_tree().get_first_node_in_group("player")
	player.velocity = Vector2.ZERO
	player.last_input_vector = Vector2.ZERO
	player.input_vector = Vector2.ZERO
	player.is_cutscene_squirrel = true
	anim.play("enter")

func _shake(amount: float, time: float) -> void:
	ImpactEffects.hit(amount, time, ImpactEffects.FlashType.Stark, 0.2)

func _finish_scene():
	var player: Player = get_tree().get_first_node_in_group("player")
	var marker: Marker2D = $PlayerEndingPoint
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(player, "global_position", marker.global_position, 1.5)
	await t.finished
	player.is_cutscene_squirrel = false
