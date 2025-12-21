extends ActionState

@export var sfx: AudioSFX


func process_state(player :Player, _delta: float) -> bool:
	return player.playback.get_current_node() != "ActionState"

func _action_enter(player :Player) -> void:
	player.velocity = Vector2.ZERO
	player.playback.travel("ActionState")
	if sfx:
		AudioManager.call_deferred("PlaySFX", sfx, player)
