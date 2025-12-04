class_name Player
extends CharacterBody2D

@export var speed: float = 300
@export var roll_speed: float = 600
@export var max_hp: int = 4
var current_hp: int = max_hp

@export var sound_hurt: AudioStream

@export var action_1: ActionState
@export var action_2: ActionState
var current_action_state = null

var input_vector: Vector2 = Vector2.ZERO
var last_input_vector: Vector2 = Vector2.DOWN

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var shuriken_spawn: Node2D = $ShurikenSpawn

const shuriken_projectile_scene = preload("shuriken-projectile.tscn")
var shuriken_cooldown_time = 0.5
var shuriken_cooldown = 0.0

const hit_effect = preload("res://scenes/Effects/hit_effect.tscn")

signal update_health(current_health, max_health)
signal player_death
signal direction_changed(new_direction)
signal shuriken_throw

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	hit_box.hit.connect(_on_hit)
	player_death.connect(_on_player_death)

func _physics_process(delta: float) -> void:
	shuriken_cooldown -= delta
	
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
	var state = playback.get_current_node()
	match state:
		"MoveState":
			move_state()
		"RollState":
			roll_state()
		"ActionState":
			action_state(delta)
	
	if input_vector != Vector2.ZERO:
		update_blend_positions()
		last_input_vector = input_vector
	move_and_slide()


func move_state() -> void:
	velocity = input_vector * speed

	# melee attack with katana sword / punch
	if Input.is_action_just_pressed("roll"):
		velocity = last_input_vector * roll_speed
		playback.travel("RollState")
	# dodge roll crouch slide move
	if Input.is_action_just_pressed("action_1"):
		current_action_state = action_1
		action_1.enter_state(self)
	# projectile shuriken / potion / bomb 
	if Input.is_action_just_pressed("action_2"):
		current_action_state = action_2
		action_2.enter_state(self)


func action_state(delta: float) -> void:
	if current_action_state == null: return
	if current_action_state.process_state(self, delta): 
		current_action_state.exit_state(self)
		current_action_state = null


func roll_state() -> void:
	if Input.is_action_just_pressed("action_1"):
		current_action_state = action_1
		action_1.enter_state(self)

	if Input.is_action_just_pressed("roll"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		if input_vector != Vector2.ZERO:
			velocity = input_vector * velocity.length()


func _die() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.start()
	await timer.timeout
	emit_signal("player_death")
	# later you can add queue_free or disable collisions here

func _on_player_death() -> void:
	get_tree().reload_current_scene()

func update_blend_positions() -> void:
	if input_vector == last_input_vector: return
	
	var direction_vector := Vector2(input_vector.x, -input_vector.y)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/ActionState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)
	direction_changed.emit(direction_vector)


func _on_hurt(hitbox: HitBox) -> void:
	current_hp -= hitbox.damage
	update_health.emit(current_hp, max_hp)
	effect_animation_player.play("blink")
	if sound_hurt != null:
		AudioManager.PlaySFX(sound_hurt, self)

	if current_hp <= 0:
		call_deferred("_die")  # extra safe; now definitely outside physics


func _on_hit(hurtbox: HurtBox):
	if hit_effect != null:
		var hit_effect_instance = hit_effect.instantiate()
		get_tree().current_scene.add_child(hit_effect_instance)
		hit_effect_instance.global_position = hurtbox.global_position


func throw_shuriken() -> void:
	if shuriken_cooldown > 0: return
	shuriken_cooldown = shuriken_cooldown_time
	shuriken_throw.emit()
	
	# spawn a shuriken that flies in the direction we are facing
	var dir := Vector2(last_input_vector.x, last_input_vector.y).normalized()
	var ninjastar = shuriken_projectile_scene.instantiate()
	get_parent().add_child(ninjastar)
	ninjastar.global_position = shuriken_spawn.global_position
	ninjastar.set_direction(dir)
