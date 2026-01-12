extends EnemyBase

enum States {IDLE, HOP, STUN, DYING}

@export var max_hop_distance = 400
@export var min_hop_distance = 50
@export var short_hop_cuttoff = 150

var state := States.IDLE

var hop_start:Vector2
var hop_end:Vector2

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_hp <= 0:
		return

	match state:
		States.IDLE:
			idle_state()
		States.HOP:
			hop_state()
		States.STUN:
			stun_state(delta)

func idle_state():
	var hop_direction = Vector2(randf_range(-1, 1), randf_range(-1,1)).normalized()
	if can_see_player():
		hop_direction = lerp(hop_direction, global_position.direction_to(player.global_position), 0.75)
	hop_direction = hop_direction * max_hop_distance * randf()	
	
	var hop_target = global_position + hop_direction
	navigation_agent_2d.target_position = hop_target
	if hop_direction.length() < min_hop_distance or !navigation_agent_2d.is_target_reachable() or !Level.current_room.collision_shape_2d.shape.get_rect().has_point(hop_target):
		return
	
	if hop_direction.length() <= short_hop_cuttoff:
		animation_player.play("Hop_Short")
	else:
		animation_player.play("Hop_Long")
	hop_start = global_position
	hop_end = hop_target
	state = States.HOP
	
	sprite_2d.flip_h = hop_start.x > hop_end.x

func hop_state():
	if !animation_player.is_playing() or hop_start == null or hop_end == null:
		animation_player.play("Idle")
		state = States.IDLE
	
	var t = animation_player.current_animation_position / animation_player.current_animation_length
	if t > 0:
		global_position = lerp(hop_start, hop_end, t)

func stun_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	sprite_2d.flip_h = velocity.x < 0
	move_and_slide()
	if velocity.length() <= 0.01:
		velocity = Vector2.ZERO
		state = States.IDLE

func _on_hurt(hit_box: HitBox) -> void:
	super._on_hurt(hit_box)
	state = States.STUN

func _on_death() -> void:
	super._on_death()
	state = States.DYING
