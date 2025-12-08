extends CharacterBody2D

enum States {IDLE, PATROL, CHASE, STUN}

@export var view_range: = 300
@export var speed: = 200
@export var knockback_friction = 1000
@export var max_hp = 7
var current_hp = max_hp

@export_group("Patrol")
@export var random_patrol := false # whether the patrolling is random. if false, then it is cyclical
@export var patrol_point_radius := 10 # how close the enemy gets to its destination patrol point to stop moving
@export var patrol_points : Array[PatrolPointData] = [] 
var current_patrol_point := 0:
	set(val):
		if (val < 0):
			current_patrol_point = patrol_points.size() - 1
		elif (val >= patrol_points.size()):
			current_patrol_point = 0
		else:
			current_patrol_point = val

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var patrol_timer: Timer = $PatrolTimer
@onready var animation_tree: AnimationTree = $AnimationTree


var state := States.IDLE
var chase:  bool
var patrol: bool

var player = null

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	player = get_tree().get_nodes_in_group("player")[0]
	patrol_timer.wait_time = patrol_points.get(current_patrol_point).duration
	animation_tree.active = true
	
func _physics_process(_delta: float) -> void:
	$Label.text = str(current_hp)
	match state:
		States.IDLE:
			idle_state()
		States.PATROL:
			patrol_state()
		States.CHASE:
			chase_state()
		States.STUN:
			knockback_state(_delta)
			
	if chase:
		animation_tree.set("parameters/conditions/is_chase", true)
		animation_tree.set("parameters/conditions/is_patrol", false)
		
	if patrol:
		animation_tree.set("parameters/conditions/is_chase", false)
		animation_tree.set("parameters/conditions/is_patrol", true)
		
	
	animation_tree.set("parameters/Chase/blend_position", velocity.normalized())
	animation_tree.set("parameters/Patrol/blend_position", velocity.normalized())

	
func idle_state():
	if current_hp <= 0:
		queue_free()
	if can_see_player():
		state = States.CHASE
	elif not at_patrol_point():
		state = States.PATROL


func chase_state():
	velocity = global_position.direction_to(player.global_position).normalized() * speed
	#sprite_2d.scale.x = sign(velocity.x)
	chase = true
	patrol = false
	move_and_slide()
	if not can_see_player():
		state = States.IDLE


func patrol_state():
	var target_coordinates : Vector2 = patrol_points.get(current_patrol_point).coordinates
	patrol = true
	chase = false
	if not at_patrol_point():
		velocity = global_position.direction_to(target_coordinates) * speed
		patrol = true
		chase = false
		#sprite_2d.scale.x = sign(velocity.x)
		move_and_slide()
	if can_see_player():
		state = States.CHASE
	elif at_patrol_point():
		state = States.IDLE


func knockback_state(delta):
	if current_hp <= 0:
		queue_free()
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

	ray_cast_2d.target_position = player.global_position - global_position
	return not ray_cast_2d.is_colliding()


func at_patrol_point() -> bool:
	var target_coordinates : Vector2 = patrol_points.get(current_patrol_point).coordinates
	return global_position.distance_to(target_coordinates) <= patrol_point_radius


func _on_hurt(hit_box: HitBox):
	velocity = hit_box.global_position.direction_to(global_position) * 1000
	current_hp -= hit_box.damage
	print(hit_box.name)


func _on_patrol_timer_timeout() -> void:
	if random_patrol:
		current_patrol_point = randi_range(0, patrol_points.size())
	else:
		current_patrol_point += 1
	patrol_timer.wait_time = patrol_points.get(current_patrol_point).duration
	
