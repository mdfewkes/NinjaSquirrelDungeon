class_name Player
extends CharacterBody2D

@export var speed: float = 300
@export var roll_speed: float = 600
@export var max_hp: int = 4
var current_hp: int = max_hp

var input_vector: Vector2 = Vector2.ZERO
var last_input_vector: Vector2 = Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var hurt_box: HurtBox = $HurtBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var shuriken_spawn: Node2D = $ShurikenSpawn

const shuriken_projectile_scene = preload("shuriken-projectile.tscn")
var shuriken_cooldown_time = 0.5
var shuriken_cooldown = 0.0


signal update_health(current_health, max_health)

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
	shuriken_cooldown -= delta
	
	var state = playback.get_current_node()
	match state:
		"MoveState":
			move_state()
		"RollState":
			roll_state()
		"ActionState":
			action_state()


func move_state() -> void:
	velocity = Vector2.ZERO

	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		update_blend_positions()

	velocity = input_vector * speed
	move_and_slide()

	# melee attack with katana sword / punch
	if Input.is_action_just_pressed("action_1"):
		velocity = last_input_vector * roll_speed
		playback.travel("RollState")
	# dodge roll crouch slide move
	if Input.is_action_just_pressed("action_2"):
		playback.travel("ActionState")
	# projectile shuriken / potion / bomb 
	if Input.is_action_just_pressed("action_3"):
		throw_shuriken()


func action_state() -> void:
	pass


func roll_state() -> void:
	move_and_slide()

	if Input.is_action_just_pressed("action_1"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if input_vector != Vector2.ZERO:
			last_input_vector = input_vector
			update_blend_positions()
		playback.travel("ActionState")

	if Input.is_action_just_pressed("action_2"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if input_vector != Vector2.ZERO:
			velocity = input_vector * velocity.length()


func _die() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	# later you can add queue_free or disable collisions here


func update_blend_positions() -> void:
	var direction_vector := Vector2(input_vector.x, -input_vector.y)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/ActionState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)


func _on_hurt(hitbox: HitBox) -> void:
	current_hp -= hitbox.damage
	update_health.emit(current_hp, max_hp)
	effect_animation_player.play("blink")

	if current_hp <= 0:
		call_deferred("_die")  # extra safe; now definitely outside physics

func throw_shuriken() -> void:
	if shuriken_cooldown > 0: return
	shuriken_cooldown = shuriken_cooldown_time
	
	# spawn a shuriken that flies in the direction we are facing
	var dir := Vector2(last_input_vector.x, last_input_vector.y).normalized()
	var ninjastar = shuriken_projectile_scene.instantiate()
	get_parent().add_child(ninjastar)
	ninjastar.global_position = shuriken_spawn.global_position 
	ninjastar.velocity.x = 0
	ninjastar.velocity.y = 0
	if (dir.x>0): ninjastar.velocity.x = 500
	if (dir.x<0): ninjastar.velocity.x = -500
	if (dir.y>0): ninjastar.velocity.y = 500
	if (dir.y<0): ninjastar.velocity.y = -500
