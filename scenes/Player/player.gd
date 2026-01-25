class_name Player
extends CharacterBody2D

## Set this to true to make this a non-interactable version for use in cutscenes.
@export var is_cutscene_squirrel = false
## God mode - player takes no damage when enabled
@export var god_mode: bool = false
@export var speed: float = 300
@export var roll_speed: float = 600
@export var max_hp: int = 4
@export var knockback_friction := 1000.0

var current_hp: int

enum PlayerSFX {hurt, footstep, effort}
@export var sfx_hurt: AudioSFX
@export var sfx_footstep: AudioSFX
@export var sfx_effort_low: AudioSFX
@export var sfx_effort_medium: AudioSFX
@export var sfx_effort_high: AudioSFX

@export var action_1: ActionState
@export var action_2: ActionState
@export var action_3: ActionState
var current_action_state = null
var action_selected_by_cutscene = null

enum PlayerState {Move, Roll, Action, Cloaked, Falling, Dying, Knockback}
var current_state = PlayerState.Move
var received_roll_command = false

var input_vector: Vector2 = Vector2.ZERO
var last_input_vector: Vector2 = Vector2.DOWN

var cloak_wait_seconds := 5.0
var cloak_gradient: GradientTexture2D
var cloak_area_counter := 0
var last_action_time: float
var is_on_platform := false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $HitBox
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var shuriken_spawn: Node2D = $ShurikenSpawn
@onready var tail: Tail = $Tail
@onready var fall_detector: FallDetector = $FallDetector
@onready var hit_effect: CPUParticles2D = $KatanaHitEffect

signal update_health(current_health, max_health)
signal player_death
signal direction_changed(new_direction)

func _ready() -> void:
	animation_tree.active = true
	hurt_box.hurt.connect(_on_hurt)
	hit_box.hit.connect(_on_hit)
	player_death.connect(_on_player_death)
	fall_detector.entered_pit.connect(_on_fall_start)
	fall_detector.fell_into_pit.connect(_on_fall_complete)
	InventoryManager.item_collected.connect(_on_collected_item)
	GameManager.restore_persistant_state(self)
	update_health.emit(current_hp, max_hp)

func _physics_process(delta: float) -> void:
	if not is_cutscene_squirrel:
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	if current_state == PlayerState.Falling or current_state == PlayerState.Dying:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		current_state = PlayerState.Dying
		call_deferred("_die")

	match current_state:
		PlayerState.Move:
			_move_state()
		PlayerState.Roll:
			_roll_state()
		PlayerState.Action:
			_action_state(delta)
		PlayerState.Cloaked:
			_cloaked_state()
		PlayerState.Knockback:
			_knockback_state(delta)
	
	if input_vector != Vector2.ZERO:
		_update_blend_positions()
		_clear_cloaked_state()
		last_input_vector = input_vector
	else:
		_process_cloaking(delta)

	move_and_slide()


func _move_state() -> void:
	velocity = input_vector * speed

	if _should_roll():
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

func _should_roll() -> bool:
	if is_cutscene_squirrel:
		return received_roll_command
	return Input.is_action_just_pressed("roll")

func _roll_state() -> void:
	_check_and_set_action_state()

	if _should_roll():
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
		play_sfx_effort()
		if input_vector != Vector2.ZERO:
			velocity = input_vector * velocity.length()
		received_roll_command = false
		return
	
	if playback.get_current_node() != "RollState":
		current_state = PlayerState.Move
		return

func _cloaked_state() -> void:
	_check_and_set_action_state()

func _knockback_state(delta: float) -> void:
	move_and_slide()
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if velocity == Vector2.ZERO:
		current_state = PlayerState.Move

func _die() -> void:
	ImpactEffects.hit(1.5, 1.0, ImpactEffects.FlashType.Stark, 0.2)
	while playback.get_current_node() != "death":
		await get_tree().physics_frame

	tail.set_cloak_gradient(tail.death_gradient)
	create_tween().tween_method(tail.set_cloak_amount, 0.0, 1.0, 1.0)

	await animation_tree.animation_finished
	emit_signal("player_death")

func _update_blend_positions() -> void:
	if input_vector == last_input_vector: return
	
	var direction_vector := Vector2(input_vector.x, -input_vector.y)
	animation_tree.set("parameters/StateMachine/MoveState/IdleState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/KatanaActionState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/TailWhipAction/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/RollState/blend_position", direction_vector)
	if input_vector != Vector2.ZERO:
		hit_box.reflection_direction = input_vector.normalized()
	direction_changed.emit(direction_vector)

func _set_action_state(state: ActionState) -> void:
	action_selected_by_cutscene = null
	if state == null: return
	if not state.can_enter(): return
	
	_clear_cloaked_state()
	current_state = PlayerState.Action
	current_action_state = state
	current_action_state.enter_state(self)

func  _set_roll_state() -> void:
	velocity = last_input_vector * roll_speed
	playback.travel("RollState")
	current_state = PlayerState.Roll
	play_sfx_effort()

func _check_and_set_action_state() -> void:
	if Input.is_action_just_pressed("action_1") or action_selected_by_cutscene == "action_1":
		_set_action_state(action_1)
		return
	if Input.is_action_just_pressed("action_2") or action_selected_by_cutscene == "action_2":
		_set_action_state(action_2)
		return
	if Input.is_action_just_pressed("action_3") or action_selected_by_cutscene == "action_3":
		_set_action_state(action_3)
		return


func _on_hurt(hitbox: HitBox) -> void:
	if god_mode or current_state == PlayerState.Dying or current_state == PlayerState.Knockback:
		return
	current_hp -= hitbox.damage
	update_health.emit(current_hp, max_hp)
	
	effect_animation_player.play("blink")
	ImpactEffects.hit(0.7, 0.3, ImpactEffects.FlashType.Bland)
	play_sfx_hurt()
	
	var knockback_dir := hitbox.global_position.direction_to(global_position)
	velocity = knockback_dir * hitbox.knockback
	current_state = PlayerState.Knockback

	if current_hp <= 0:
		current_state = PlayerState.Dying
		call_deferred("_die")  # extra safe; now definitely outside physics

func _on_hit(hurtbox: HurtBox):
	if hit_effect:
		hit_effect.global_position = hurtbox.global_position
		hit_effect.rotation = last_input_vector.angle()
		hit_effect.emitting = true
		

func _on_player_death() -> void:
	GameManager.restart_after_death()

func _on_player_directed(vector: Vector2) -> void:
	input_vector = vector

func _on_action_selected(action: String) -> void:
	action_selected_by_cutscene = action

func _on_roll_command_received() -> void:
	received_roll_command = true

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
	modulate = Color.WHITE
	if current_state == PlayerState.Cloaked:
		current_state = PlayerState.Move

func _process_cloaking(_delta:float) -> void:
	if current_state != PlayerState.Cloaked and cloak_gradient:
		var idle_seconds: float = (Time.get_ticks_msec() - last_action_time) / 1000.0
		if idle_seconds < cloak_wait_seconds:
			tail.set_cloak_amount(idle_seconds / cloak_wait_seconds)
			modulate = lerp(Color.WHITE, cloak_gradient.gradient.colors[0].lightened(0.4), idle_seconds/cloak_wait_seconds)
		elif current_state != PlayerState.Cloaked:
			tail.set_cloak_amount(1.0)
			current_state = PlayerState.Cloaked


func is_cloaked() -> bool:
	return current_state == PlayerState.Cloaked


func _play_sfx(player_sfx: PlayerSFX) -> void:
	match player_sfx:
		PlayerSFX.hurt:
			AudioManager.PlaySFX(sfx_hurt, self)
		PlayerSFX.footstep:
			AudioManager.PlaySFX_at_position(sfx_footstep, global_position)
		PlayerSFX.effort:
			if float(current_hp) / float(max_hp) <= 0.25:
				AudioManager.PlaySFX(sfx_effort_high, self)
			elif float(current_hp) / float(max_hp) <= 0.5:
				AudioManager.PlaySFX(sfx_effort_medium, self)
			else:
				AudioManager.PlaySFX(sfx_effort_low, self)

func play_sfx_hurt() -> void:
	_play_sfx(PlayerSFX.hurt)

func play_sfx_footstep() -> void:
	_play_sfx(PlayerSFX.footstep)

func play_sfx_effort() -> void:
	_play_sfx(PlayerSFX.effort)


func can_fall(_area: Node2D) -> bool:
	return not is_on_platform and current_action_state != $"Tail Whip ActionState"


func _on_fall_start(_pit: Node2D) -> void:
	current_state = PlayerState.Falling
	# it looks better if we rotate so the player's head points
	# in the direction they were moving. that way they're more
	# likely to be firmly inside the pit and not overlapping the
	# outside edges
	rotation = input_vector.angle() + PI / 2.0
	velocity = Vector2.ZERO
	input_vector = Vector2.ZERO
	tail.hide()
	ImpactEffects.shake(0.5, 0.2)
	if not fall_detector.sfx_on_fall:
		play_sfx_hurt()


func _on_fall_complete() -> void:
	current_state = PlayerState.Move
	rotation = 0
	tail.call_deferred("show")
	if god_mode:
		return
	current_hp -= 1
	update_health.emit(current_hp, max_hp)
	effect_animation_player.play("blink")
	if current_hp <= 0:
		current_state = PlayerState.Dying
		call_deferred("_die")  # extra safe; now definitely outside physics

func entered_platform() -> void:
	is_on_platform = true

func exited_platform() -> void:
	is_on_platform = false
	fall_detector.refresh_active_pits()


func _on_collected_item(item: InventoryManager.InventoryItem, _node: CollectableItem) -> void:
	match item.type:
		InventoryManager.ItemType.health:
			max_hp += item.value
			current_hp = max_hp
			update_health.emit(current_hp, max_hp)
