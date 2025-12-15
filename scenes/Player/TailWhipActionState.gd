extends ActionState

var ray: RayCast2D
var tail: Tail
var player: Player

var hook_point: Vector2 = Vector2.INF
var hook_obj: Node

const RAY_LENGTH = 500.0
const PULL_VELOCITY = 500.0
const PULL_ACCEL = 1.1

func process_state(_player :Player, _delta: float) -> bool:
	if hook_point != Vector2.INF:
		player.move_and_slide()
	return player.playback.get_current_node() != "TailWhipAction"


func _action_enter(_player: Player) -> void:
	player = _player
	ray = player.get_node("TailHookTargetRay")
	tail = player.tail
	player.playback.travel("TailWhipAction")


func _action_exit(_player: Player) -> void:
	hook_point = Vector2.INF
	tail.clear_tip_position()


func cast_hook_ray(dir: Vector2) -> void:
	ray.target_position = dir * 500.0


func start_hook_pull() -> void:
	if ray.is_colliding():
		var obj = ray.get_collider()
		if obj is TileMapLayer:
			hook_point = ray.get_collision_point()
			hook_obj = obj
			player.velocity = player.global_position.direction_to(hook_point) * 500.0
			tail.set_tip_position(hook_point)
			var smoke: CPUParticles2D = player.get_node("TailHookSmoke")
			smoke.global_position = hook_point
			smoke.rotation = ray.get_collision_normal().angle()
			smoke.emitting = true


func release_hook() -> void:
	tail.clear_tip_position()
	var sparks: CPUParticles2D = player.get_node("TailHookSparks")
	sparks.global_position = hook_point
	sparks.emitting = true
