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

signal update_health(current_health, max_health)

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)


func _physics_process(_delta: float) -> void:
	var state = playback.get_current_node()
	match state:
		"MoveState":
			move_state()
		"ActionState":
			action_state()
		"RollState":
			roll_state()


func move_state() -> void:
	velocity = Vector2.ZERO

	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		update_blend_positions()

	velocity = input_vector * speed
	move_and_slide()

	if Input.is_action_just_pressed("action_1"):
		playback.travel("ActionState")
	if Input.is_action_just_pressed("action_2"):
		velocity = last_input_vector * roll_speed
		playback.travel("RollState")


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
