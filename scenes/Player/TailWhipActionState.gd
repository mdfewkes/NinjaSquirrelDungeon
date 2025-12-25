extends ActionState

@export var sfx_on_start: AudioSFX
@export var sfx_on_pull_wall: AudioSFX
@export var sfx_on_pull_obj: AudioSFX

var wall_ray: RayCast2D
var obj_ray: RayCast2D
var tail: Tail
var player: Player

var hook_point: Vector2 = Vector2.INF
var hook_obj: Node
var hook_obj_pull_factor: float

# this controls how far away you can grab the wall
const RAY_LENGTH = Vector2(450.0, 350.0)
# this is the initial speed once you start pulling
const PULL_VELOCITY = 500.0
# this is the acceleration (px/sec) over the course of the pull
# the animiation still controls how long the pull happens, so
# this is played out over ~300ms
const PULL_ACCEL = 1600.0

# The distance where we stop pulling so they don't run into us
const MIN_OBJ_PULL_DIST = 50.0

func process_state(_player :Player, delta: float) -> bool:
	# allow cancelling the pull with other actions
	player._check_and_set_action_state()
	
	if hook_point != Vector2.INF:
		player.move_and_slide()
		player.velocity += player.velocity.normalized() * PULL_ACCEL * delta
	if hook_obj and hook_obj.global_position.distance_to(obj_ray.global_position) > MIN_OBJ_PULL_DIST:
		if hook_obj.has_method("move_and_slide"):
			hook_obj.velocity = hook_obj.global_position.direction_to(obj_ray.global_position) * PULL_VELOCITY * hook_obj_pull_factor
			hook_obj.move_and_slide()
		else:
			hook_obj.global_position.x = move_toward(hook_obj.global_position.x, obj_ray.global_position.x, PULL_VELOCITY * hook_obj_pull_factor * delta)
			hook_obj.global_position.y = move_toward(hook_obj.global_position.y, obj_ray.global_position.y, PULL_VELOCITY * hook_obj_pull_factor * delta)

	return player.playback.get_current_node() != "TailWhipAction"


func _action_enter(_player: Player) -> void:
	player = _player
	wall_ray = player.get_node("TailHookWallRay")
	obj_ray = player.get_node("TailHookObjectRay")
	tail = player.tail
	player.playback.travel("TailWhipAction")
	if sfx_on_start:
		AudioManager.call_deferred("PlaySFX", sfx_on_start, player)


func _action_exit(_player: Player) -> void:
	hook_point = Vector2.INF
	hook_obj = null
	tail.clear_tip_position()
	player.set_collision_mask_value(8, true)


func cast_hook_ray(_dir: Vector2) -> void:
	# The original version of this only allowed the tail whip
	# in the 4 cardinal directions. This version instead casts the
	# ray in the direction the player was moving. This will allow
	# more expressive movement but may be too funky or allow the
	# player to get into too many weird out of bounds spots. If we
	# need to go back to just the 4 directions, comment out the below
	# two lines and use the passed in _dir param instead.
	var dir: Vector2 = player.animation_tree.get("parameters/StateMachine/TailWhipAction/blend_position")
	dir.y = -dir.y
	
	wall_ray.target_position = dir * RAY_LENGTH
	obj_ray.target_position = dir * RAY_LENGTH


func start_hook_pull() -> void:
	var is_wall = wall_ray.is_colliding()
	var is_obj = obj_ray.is_colliding()
	
	if is_wall and is_obj:
		var wall_dist = wall_ray.get_collision_point().distance_to(player.global_position)
		var obj_dist = obj_ray.get_collision_point().distance_to(player.global_position)
		if wall_dist < obj_dist:
			is_obj = false
		else:
			is_wall = false

	if is_wall:
		hook_point = wall_ray.get_collision_point()
		player.velocity = player.global_position.direction_to(hook_point - wall_ray.position) * PULL_VELOCITY
		tail.set_tip_position(hook_point)
		player.set_collision_mask_value(8, false)

		var smoke: CPUParticles2D = player.get_node("TailHookSmoke")
		smoke.global_position = hook_point
		smoke.rotation = wall_ray.get_collision_normal().angle()
		smoke.emitting = true

		if sfx_on_pull_wall:
			AudioManager.call_deferred("PlaySFX", sfx_on_pull_wall, player)

	if is_obj:
		var obj = obj_ray.get_collider()
		if obj.has_method("can_be_pulled") and obj.can_be_pulled():
			hook_obj_pull_factor = obj.pull_speed_coefficient
			hook_obj = obj.can_be_pulled()
			tail.set_tip_position(obj_ray.get_collision_point())

		var smoke: CPUParticles2D = player.get_node("TailHookSmoke")
		smoke.global_position = obj_ray.get_collision_point()
		smoke.rotation = obj_ray.get_collision_normal().angle()
		smoke.emitting = true

		if sfx_on_pull_obj:
			AudioManager.call_deferred("PlaySFX", sfx_on_pull_obj, player)


func release_hook() -> void:
	tail.clear_tip_position()
	var sparks: CPUParticles2D = player.get_node("TailHookSparks")
	sparks.global_position = hook_point
	sparks.emitting = true
