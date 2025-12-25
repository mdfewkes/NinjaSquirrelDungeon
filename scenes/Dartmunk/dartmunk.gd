class_name Dartmunk
extends EnemyBase

## Dartmunk enemy - surrounds the player using boids-style movement.

# Boids parameters (speed and view_range inherited from EnemyBase)
## Circle radius around player
@export_range(50.0, 500.0, 10.0, "or_greater") var ideal_distance: float = 250.0
## Dartmunks closer than this distance will push apart.
@export_range(100.0, 2000.0, 50.0, "or_greater") var separation_radius: float = 1000.0
## Multiplier on separation force. Higher = spread out more aggressively, Lower = prioritize ideal_distance.
@export_range(0.0, 2.0, 0.1, "or_greater") var separation_weight: float = 0.5
## Force threshold to START moving. Must exceed this to begin repositioning.
## Higher = more "dead zone" before reacting. Prevents jitter from tiny forces.
@export_range(0.01, 1.0, 0.01, "or_greater") var move_threshold: float = 0.1
## Force threshold to STOP moving. Must drop below this to halt.
## Lower than move_threshold creates hysteresis - prevents start/stop flickering.
@export_range(0.01, 1.0, 0.01, "or_greater") var stop_threshold: float = 0.05

@export_group("Attack")
## PackedScene for dart projectile (assign in editor)
@export var dart_scene: PackedScene
## Time between dart shots (seconds)
@export_range(0.1, 10.0, 0.1, "or_greater") var attack_cooldown: float = 2.0
## Speed of fired darts (pixels/sec)
@export_range(100.0, 1000.0, 10.0, "or_greater") var dart_speed: float = 400.0
## Distance from center to spawn dart (avoids self-collision)
@export_range(5.0, 100.0, 5.0, "or_greater") var dart_spawn_distance: float = 20.0
## Multiplier on move_threshold when deciding to leave ATTACK state.
## Higher = attacking Dartmunks are more "sticky" and won't reposition as easily.
## Example: 2.0 means force must be 2x stronger to interrupt an attack than to start moving.
@export_range(1.0, 20.0, 0.5, "or_greater") var attack_exit_multiplier: float = 7.5

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer = $AttackTimer

enum State {IDLE, MOVE, ATTACK, STUN}
var current_state: State = State.IDLE
var _is_repositioning: bool = false # Hysteresis state for smooth settling


func _ready() -> void:
	super._ready()
	add_to_group("dartmunks")
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	match current_state:
		State.IDLE:
			if is_player_in_range():
				current_state = State.MOVE
		State.MOVE:
			if not is_player_in_range():
				current_state = State.IDLE
			else:
				_do_boids_movement(delta)
				# Transition to ATTACK when settled and can see player
				if not _is_repositioning and can_see_player():
					_enter_attack_state()
		State.ATTACK:
			_do_attack_state(delta)
		State.STUN:
			_do_stun_state(delta)


## Returns combined boids force (radial + separation)
func _calculate_boids_force() -> Vector2:
	if player == null:
		return Vector2.ZERO

	# 1. Calculate ideal position on circle around player
	var player_pos: Vector2 = player.global_position
	var to_player: Vector2 = player_pos - global_position
	var distance_to_player: float = to_player.length()
	var ideal_pos: Vector2 = player_pos - to_player.normalized() * ideal_distance

	# 2. Get navigation direction (handles walls/obstacles)
	nav_agent.target_position = ideal_pos
	var nav_direction: Vector2 = global_position.direction_to(nav_agent.get_next_path_position())

	# 3. Calculate separation from other Dartmunks
	var separation := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("dartmunks"):
		if other == self:
			continue
		var other_pos: Vector2 = other.global_position
		var diff: Vector2 = global_position - other_pos
		var dist: float = diff.length()
		if dist < separation_radius and dist > 0:
			# Stronger separation the closer they are (1 at dist=0, 0 at separation_radius)
			var strength: float = 1.0 - (dist / separation_radius)
			separation += diff.normalized() * strength

	# 4. Blend directions - use separation more when at ideal distance
	var distance_factor: float = clamp(abs(distance_to_player - ideal_distance) / 100.0, 0.0, 1.0)
	# When far from ideal: prioritize nav_direction. When at ideal: prioritize separation
	return nav_direction * distance_factor + separation * separation_weight


func _do_boids_movement(_delta: float) -> void:
	var combined := _calculate_boids_force()

	# Apply hysteresis to prevent jitter at equilibrium
	# Use different thresholds for starting vs stopping movement
	var force_magnitude := combined.length()
	if _is_repositioning:
		# Currently moving - keep going unless force drops very low
		if force_magnitude < stop_threshold:
			_is_repositioning = false
			velocity = Vector2.ZERO
		else:
			velocity = combined.normalized() * speed
	else:
		# Currently stopped - only start if force is significant
		if force_magnitude > move_threshold:
			_is_repositioning = true
			velocity = combined.normalized() * speed
		else:
			velocity = Vector2.ZERO
	move_and_slide()


## Check if repositioning is needed (for ATTACK state exit condition)
func _should_reposition() -> bool:
	var force := _calculate_boids_force()
	return force.length() > move_threshold * attack_exit_multiplier


#region Attack Behavior

func _enter_attack_state() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	_fire_dart()
	attack_timer.start(attack_cooldown)


func _do_attack_state(_delta: float) -> void:
	# Check exit conditions
	if not can_see_player() or _should_reposition():
		attack_timer.stop()
		current_state = State.MOVE
		return
	# Stay still but maintain physics
	velocity = Vector2.ZERO
	move_and_slide()


func _fire_dart() -> void:
	if dart_scene == null or player == null:
		return
	var direction := global_position.direction_to(player.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT # Fallback

	var dart: Projectile = dart_scene.instantiate()
	get_parent().add_child(dart)
	dart.launch(global_position + direction * dart_spawn_distance, direction, dart_speed)


func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACK and can_see_player():
		_fire_dart()
		attack_timer.start(attack_cooldown)

#endregion


#region Stun State

func _do_stun_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()
	if velocity.length() < 10.0:
		current_state = State.MOVE
		_is_repositioning = true # Force re-evaluation of position


func _on_hurt(hit_box: HitBox) -> void:
	super._on_hurt(hit_box)
	velocity = hit_box.global_position.direction_to(global_position) * hit_box.knockback * knockback_multiply
	current_state = State.STUN
	attack_timer.stop() # Interrupt attack

#endregion
