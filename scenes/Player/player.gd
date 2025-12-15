class_name Player
extends CharacterBody2D

## Set this to true to make this a non-interactable version for use in cutscenes.
@export var is_cutscene_squirrel = false
@export var speed: float = 300
@export var roll_speed: float = 600
@export var max_hp: int = 4
var current_hp: int = max_hp

@export var sfx_hurt: AudioSFX

@export var action_1: ActionState
@export var action_2: ActionState
@export var action_3: ActionState
var current_action_state = null

enum PlayerState {Move, Roll, Action, Cloaked}
var current_state = PlayerState.Move

var input_vector: Vector2 = Vector2.ZERO
var last_input_vector: Vector2 = Vector2.DOWN

var cloak_wait_seconds := 5.0
var cloak_gradient: GradientTexture2D
var cloak_area_counter := 0
var last_action_time: float

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var shuriken_spawn: Node2D = $ShurikenSpawn
@onready var tail: Tail = $Tail

const hit_effect = preload("res://scenes/Effects/hit_effect.tscn")

signal update_health(current_health, max_health)
signal player_death
signal direction_changed(new_direction)

func _ready() -> void:
	animation_tree.active = true
	hurt_box.hurt.connect(_on_hurt)
	hit_box.hit.connect(_on_hit)
	player_death.connect(_on_player_death)
	InventoryManager.reset()

func _physics_process(delta: float) -> void:
	if not is_cutscene_squirrel:
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
	match current_state:
		PlayerState.Move:
			_move_state()
		PlayerState.Roll:
			_roll_state()
		PlayerState.Action:
			_action_state(delta)
		PlayerState.Cloaked:
			_cloaked_state()
	
	if input_vector != Vector2.ZERO:
		_update_blend_positions()
		_clear_cloaked_state()
		last_input_vector = input_vector
	else:
		_process_cloaking(delta)

	move_and_slide()


func _move_state() -> void:
	velocity = input_vector * speed

	if Input.is_action_just_pressed("roll"):
		_set_roll_state()
		return
		
	_check_and_set_action_state()


func _action_state(delta: float) -> void:
	if current_action_state == null: 
		current_state = PlayerState.Move
		return

	if current_action_state.process_state(self, delta): 
		current_action_state.exit_state(self)
		current_action_state = null
		current_state = PlayerState.Move


func _roll_state() -> void:
	_check_and_set_action_state()

	if Input.is_action_just_pressed("roll"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if input_vector != Vector2.ZERO:
			velocity = input_vector * velocity.length()
		return
	
	if playback.get_current_node() != "RollState":
		current_state = PlayerState.Move
		return

func _cloaked_state() -> void:
	_check_and_set_action_state()

func _die() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	emit_signal("player_death")
	# later you can add queue_free or disable collisions here

func _update_blend_positions() -> void:
	if input_vector == last_input_vector: return
	
	var direction_vector := Vector2(input_vector.x, -input_vector.y)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/ActionState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)
	direction_changed.emit(direction_vector)

func _set_action_state(state: ActionState) -> void:
	if state == null: return
	
	_clear_cloaked_state()
	current_state = PlayerState.Action
	current_action_state = state
	current_action_state.enter_state(self)

func  _set_roll_state() -> void:
	velocity = last_input_vector * roll_speed
	playback.travel("RollState")
	current_state = PlayerState.Roll

func _check_and_set_action_state() -> void:
	if Input.is_action_just_pressed("action_1"):
		_set_action_state(action_1)
		return
	if Input.is_action_just_pressed("action_2"):
		_set_action_state(action_2)
		return
	if Input.is_action_just_pressed("action_3"):
		_set_action_state(action_3)
		return

func _on_hurt(hitbox: HitBox) -> void:
	current_hp -= hitbox.damage
	update_health.emit(current_hp, max_hp)
	effect_animation_player.play("blink")
	AudioManager.PlaySFX(sfx_hurt, self)

	if current_hp <= 0:
		call_deferred("_die")  # extra safe; now definitely outside physics

func _on_hit(hurtbox: HurtBox):
	if hit_effect != null:
		var hit_effect_instance = hit_effect.instantiate()
		get_tree().current_scene.add_child(hit_effect_instance)
		hit_effect_instance.global_position = hurtbox.global_position

func _on_player_death() -> void:
	get_tree().reload_current_scene()

func _on_player_directed(vector: Vector2) -> void:
	input_vector = vector


func set_cloakable_gradient(gradient: GradientTexture2D, wait_time: float) -> void:
	cloak_gradient = gradient
	cloak_wait_seconds = wait_time
	tail.set_cloak_gradient(gradient)
	cloak_area_counter += 1


func clear_cloakable_gradient() -> void:
	cloak_area_counter -= 1
	if cloak_area_counter <= 0:
		cloak_area_counter = 0
		_clear_cloaked_state()
		tail.set_cloak_gradient(null)
		cloak_gradient = null


func _clear_cloaked_state() -> void:
	last_action_time = Time.get_ticks_msec()
	tail.set_cloak_amount(0.0)
	if current_state == PlayerState.Cloaked:
		current_state = PlayerState.Move


func _process_cloaking(_delta:float) -> void:
	if current_state != PlayerState.Cloaked and cloak_gradient:
		var idle_seconds: float = (Time.get_ticks_msec() - last_action_time) / 1000.0
		if idle_seconds < cloak_wait_seconds:
			tail.set_cloak_amount(idle_seconds / cloak_wait_seconds)
		elif current_state != PlayerState.Cloaked:
			tail.set_cloak_amount(1.0)
			current_state = PlayerState.Cloaked

func is_cloaked() -> bool:
	return current_state == PlayerState.Cloaked
