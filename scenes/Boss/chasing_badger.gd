extends Node2D

enum State { idle, charging, rebound }

@export var charge_accel := 1500.0
@export var charge_seconds := 5.0
@export var idle_seconds := 1.0
@export var rebound_seconds := 0.5
@export var rebound_amount := 2000.0
@export var starting_point : Marker2D

@onready var hit_box: HitBox = $HitBox
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state = State.idle
var velocity := Vector2.ZERO
var last_state_change: int

func _ready() -> void:
	hit_box.hit.connect(_on_hit)
	on_screen_notifier.screen_exited.connect(_on_left_screen)
	
	if not starting_point:
		starting_point = Marker2D.new()
		get_parent().add_child.call_deferred(starting_point)
		starting_point.global_position = global_position

	_reset()


func _reset() -> void:
	state = State.idle
	last_state_change = Time.get_ticks_msec()
	global_position = starting_point.global_position
	velocity = Vector2.ZERO
	show()


func _physics_process(delta: float) -> void:
	match state:
		State.charging:
			_process_charging(delta)
		State.idle:
			_process_idle(delta)
		State.rebound:
			_process_rebound(delta)


func _start_charging() -> void:
	state = State.charging
	last_state_change = Time.get_ticks_msec()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		velocity = global_position.direction_to(player.global_position)
	print("charging:", velocity)


func _process_charging(delta: float) -> void:
	velocity += velocity.normalized() * charge_accel * delta
	position += velocity * delta
	if Time.get_ticks_msec() > last_state_change + charge_seconds * 1000:
		_start_idle()


func _start_idle() -> void:
	state = State.idle
	last_state_change = Time.get_ticks_msec()
	print("idle")


func _process_idle(_delta: float) -> void:
	if Time.get_ticks_msec() > last_state_change + idle_seconds * 1000:
		_start_charging()


func _start_rebound() -> void:
	state = State.rebound
	last_state_change = Time.get_ticks_msec()
	velocity = global_position.direction_to(starting_point.global_position) * rebound_amount * rebound_seconds
	print("rebound:", velocity)


func _process_rebound(delta: float) -> void:
	if Time.get_ticks_msec() > last_state_change + rebound_seconds * 1000:
		_start_idle()
	position += velocity * delta


func _on_hit(body: Node2D) -> void:
	if body is BreakableWall and state != State.rebound:
		_start_rebound()

func _on_left_screen() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.x > player.global_position.x:
		print("left screen, resetting", global_position.x, player.global_position.x)
		global_position = starting_point.global_position
		_start_charging()
