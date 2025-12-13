extends CharacterBody2D

@export var view_range: = 300
@export var speed: = 200
@export var knockback_multiply = 2
@export var knockback_friction = 1000
@export var max_hp = 7
var current_hp = max_hp

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

const destroy_effect = preload("res://scenes/Effects/hit_effect.tscn")

var player = null

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	player = get_tree().get_nodes_in_group("player")[0]


func _physics_process(_delta: float) -> void:
	$Label.text = str(current_hp)
	var state = playback.get_current_node()
	match state:
		"idleState":
			idle_state()
		"chaseState":
			chase_state()
		"knockbackState":
			knockback_state(_delta)


func idle_state():
	if current_hp <= 0:
		die()


func chase_state():
	navigation_agent_2d.target_position = player.global_position
	var next_point = navigation_agent_2d.get_next_path_position()
	velocity = global_position.direction_to(next_point) * speed
	sprite_2d.scale.x = sign(velocity.x)
	move_and_slide()


func knockback_state(delta):
	if current_hp <= 0:
		die()
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()


func is_player_in_range() -> bool:
	if player == null:
		return false
	var distance = global_position.distance_to(player.global_position)
	return distance <= view_range


func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	if player == null:
		return false
	if player.is_cloaked():
		return false

	ray_cast_2d.target_position = player.global_position - global_position
	return not ray_cast_2d.is_colliding()


func die() -> void:
	if destroy_effect != null:
		var destroy_effect_inastance = destroy_effect.instantiate()
		get_tree().current_scene.add_child(destroy_effect_inastance)
		destroy_effect_inastance.global_position = global_position
	queue_free()


func _on_hurt(hit_box: HitBox):
	velocity = hit_box.global_position.direction_to(global_position).normalized() * hit_box.knockback * knockback_multiply
	current_hp -= hit_box.damage
	playback.start("knockbackState")
