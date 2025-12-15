extends EnemyBase

@onready var playback := animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

const destroy_effect: PackedScene = preload("res://scenes/Effects/hit_effect.tscn")

func _ready() -> void:
	super._ready()
	
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	var state := playback.get_current_node()
	match state:
		"idleState":
			idle_state()
		"chaseState":
			chase_state()
		"knockbackState":
			knockback_state(delta)
			
func idle_state():
	if current_hp <= 0:
		die()

func chase_state():
	navigation_agent_2d.target_position = player.global_position
	var next_point := navigation_agent_2d.get_next_path_position()
	velocity = global_position.direction_to(next_point) * speed
	sprite_2d.scale.x = sign(velocity.x)
	move_and_slide()

func knockback_state(delta):
	if current_hp <= 0:
		die()
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()

func die() -> void:
	if destroy_effect != null:
		var destroy_effect_inastance := destroy_effect.instantiate()
		get_tree().current_scene.add_child(destroy_effect_inastance)
		destroy_effect_inastance.global_position = global_position
	queue_free()

func can_see_player() -> bool:
	return super.can_see_player()

func _on_hurt(hit_box: HitBox) -> void:
	super._on_hurt(hit_box)
	
	velocity = hit_box.global_position.direction_to(global_position).normalized() * hit_box.knockback * knockback_multiply
	playback.start("knockbackState")
