extends ActionState

@export var cooldown_time_msec := 500.0
@export var sfx_throw: AudioSFX

const shuriken_projectile_scene = preload("res://scenes/Projectiles/shuriken.tscn")
var last_throw_time = 0.0

signal shuriken_throw

func _action_enter(player :Player) -> void:
	if Time.get_ticks_msec() - last_throw_time < cooldown_time_msec: return
	last_throw_time = Time.get_ticks_msec()
	shuriken_throw.emit()

	sfx_throw.play(player)

	# spawn a shuriken that flies in the direction we are facing
	var dir := Vector2(player.last_input_vector.x, player.last_input_vector.y).normalized()
	var ninjastar = shuriken_projectile_scene.instantiate()
	player.get_parent().add_child(ninjastar)
	ninjastar.global_position = player.shuriken_spawn.global_position
	ninjastar.set_direction(dir)
