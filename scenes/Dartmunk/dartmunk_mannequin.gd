class_name DartmunkMannequin
extends Dartmunk

## A purely visual Dartmunk that only plays idle animation.
## Not added to "dartmunks" group, so other Dartmunks ignore it.


func _ready() -> void:
	# Don't call super._ready() - we don't want group registration
	# Minimal setup for display only
	attack_timer.stop()
	current_state = State.IDLE
	animation_player.play("idle_down")

	# Disable hurtbox so it can't be damaged
	$HurtBox/CollisionShape2D.disabled = true

	# Disable body collision so player walks through
	$CollisionShape2D.disabled = true


func _physics_process(_delta: float) -> void:
	# No behavior - just let AnimationPlayer run
	pass
