extends EnemyBase

@onready var playback := animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	super._ready()
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if current_hp <= 0:
		velocity = Vector2.ZERO
		return

	var state := playback.get_current_node()
	match state:
		"idleState":
			idle_state()
		"chaseState":
			chase_state()
		"knockbackState":
			knockback_state(delta)
			
func idle_state():
	pass

func chase_state():
	navigation_agent_2d.target_position = player.global_position
	var next_point := navigation_agent_2d.get_next_path_position()
	velocity = global_position.direction_to(next_point) * speed
	sprite_2d.scale.x = sign(velocity.x)
	move_and_slide()

func knockback_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()

func is_player_in_range() -> bool:
	if player == null:
		return false

	var distance := global_position.distance_to(player.global_position)

	return distance <= view_range * (1.0 - Level.light_level)

func _on_hurt(hit_box: HitBox) -> void:
	super._on_hurt(hit_box)
	
	playback.start("knockbackState")
