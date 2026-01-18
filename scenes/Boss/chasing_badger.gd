extends Node2D

enum State { idle, charging }

@export var charge_seconds := 5.0
@export var charge_accel := 400.0
@export var charge_backoff := 500.0
@export var starting_point : Marker2D

@onready var hit_box : HitBox = $HitBox
@onready var charge_timer : Timer = $ChargeTimer

var state = State.idle
var velocity := Vector2.ZERO


func _ready() -> void:
	charge_timer.wait_time = charge_seconds
	charge_timer.timeout.connect(_start_charging)
	hit_box.hit.connect(_on_hit)
	
	if not starting_point:
		starting_point = Marker2D.new()
		get_parent().add_child.call_deferred(starting_point)
		starting_point.global_position = global_position

	_reset()


func _reset() -> void:
	state = State.idle
	global_position = starting_point.global_position
	velocity = Vector2.ZERO
	charge_timer.start()
	show()


func _physics_process(delta: float) -> void:
	match state:
		State.charging:
			_process_charging(delta)


func _start_charging() -> void:
	print("charging")
	state = State.charging
	var player = get_tree().get_first_node_in_group("player")
	if player:
		velocity = global_position.direction_to(player.global_position)


func _process_charging(delta: float) -> void:
	velocity += velocity.normalized() * charge_accel * delta
	position += velocity * delta


func _stop_charging() -> void:
	print("stop_charging")
	state = State.idle


func _on_hit(body: Node2D) -> void:
	print("hit:", body)
	if body is BreakableWall:
		_stop_charging()
