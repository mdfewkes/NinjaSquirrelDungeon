class_name Player extends CharacterBody2D

@export var speed = 300;
@export var roll_speed = 600;
@export var max_hp = 5
var current_hp = max_hp

var input_vector: = Vector2.ZERO
var last_input_vector: = Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var hurt_box: HurtBox = $HurtBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer

func _ready():
	Globals.player = self
	hurt_box.area_entered.connect(_on_hurt)

func _physics_process(_delta: float) -> void:
	var state = playback.get_current_node()
	match state:
		"MoveState":
			move_state()
		"ActionState":
			action_state()
		"RollState":
			roll_state()

func move_state():
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

func action_state():
	pass

func roll_state():
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

func _die():
	process_mode = Node.PROCESS_MODE_DISABLED

func update_blend_positions() -> void:
	var direction_vector = Vector2(input_vector.x, -input_vector.y)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/ActionState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)
	

func _on_hurt(hitbox: HitBox):
	current_hp -= hitbox.damage
	effect_animation_player.play("blink")
	if current_hp <= 0:
		_die()
