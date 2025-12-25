class_name Dartmunk
extends EnemyBase

## Dartmunk enemy - surrounds the player using boids-style movement.

# Boids parameters (speed and view_range inherited from EnemyBase)
@export var ideal_distance: float = 250.0 ## Circle radius around player
## Dartmunks closer than this distance will push apart.
@export var separation_radius: float = 1000.0
## Multiplier on separation force. Higher = spread out more aggressively, Lower = prioritize ideal_distance.
@export var separation_weight: float = 0.5
## Force threshold to START moving. Must exceed this to begin repositioning.
## Higher = more "dead zone" before reacting. Prevents jitter from tiny forces.
@export var move_threshold: float = 0.1
## Force threshold to STOP moving. Must drop below this to halt.
## Lower than move_threshold creates hysteresis - prevents start/stop flickering.
@export var stop_threshold: float = 0.05

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

enum State {IDLE, MOVE}
var current_state: State = State.IDLE
var _is_repositioning: bool = false # Hysteresis state for smooth settling


func _ready() -> void:
	super._ready()
	add_to_group("dartmunks")


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


func _do_boids_movement(_delta: float) -> void:
	if player == null:
		return

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
	var combined: Vector2 = nav_direction * distance_factor + separation * separation_weight

	# 5. Apply hysteresis to prevent jitter at equilibrium
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
