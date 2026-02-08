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

@export var sfx_on_spot_player: AudioSFX

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
@export_range(1.0, 20.0, 0.5, "or_greater") var attack_exit_multiplier: float = 8.5
## Number of prediction iterations (higher = more accurate, 2-3 recommended)
@export_range(0, 5, 1) var prediction_iterations: int = 3
## Random spread applied to aim direction (degrees). 0 = perfect aim.
@export_range(0.0, 45.0, 1.0) var aim_spread_degrees: float = 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer = $AttackTimer
@onready var sprite: Sprite2D = $Sprite2D

enum State {IDLE, MOVE, REPOSITION, ATTACK, STUN, DEATH}
var current_state: State = State.IDLE
var _is_repositioning: bool = false # Hysteresis state for smooth settling
var _facing_direction: Vector2 = Vector2.DOWN

## Debug visualization
@export var debug_draw: bool = true
var _debug_nav_path: PackedVector2Array = []


func _ready() -> void:
	super._ready()
	add_to_group("dartmunks")
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_debug_label()

	match current_state:
		State.IDLE:
			if is_player_in_range():
				AudioManager.PlaySFX(sfx_on_spot_player, self)
				current_state = State.MOVE
		State.MOVE:
			if not is_player_in_range():
				current_state = State.IDLE
			elif not can_see_player():
				current_state = State.REPOSITION
			else:
				_do_boids_movement(delta)
				# Transition to ATTACK when settled and can see player
				if not _is_repositioning:
					_enter_attack_state()
		State.REPOSITION:
			if not is_player_in_range():
				current_state = State.IDLE
			elif can_see_player():
				current_state = State.MOVE
				_is_repositioning = true # Force movement re-evaluation
			else:
				_do_reposition_movement(delta)
		State.ATTACK:
			_do_attack_state(delta)
		State.STUN:
			_do_stun_state(delta)

	_update_animation()


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


## Navigate directly toward player to regain line of sight
func _do_reposition_movement(_delta: float) -> void:
	if player == null:
		return

	# Navigate directly to player position
	nav_agent.target_position = player.global_position
	var nav_direction: Vector2 = global_position.direction_to(nav_agent.get_next_path_position())

	velocity = nav_direction * speed
	move_and_slide()


## Check if repositioning is needed (for ATTACK state exit condition)
func _should_reposition() -> bool:
	var force := _calculate_boids_force()
	return force.length() > move_threshold * attack_exit_multiplier


#region Attack Behavior

func _enter_attack_state() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	_start_attack_animation()
	attack_timer.start(attack_cooldown)


func _start_attack_animation() -> void:
	if player == null:
		return
	# Update facing toward predicted aim point
	var aim_point := _calculate_predicted_position()
	_facing_direction = global_position.direction_to(aim_point)
	var dir_name := _get_direction_name()
	animation_player.play("attack_%s" % dir_name)


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
	var aim_point := _calculate_predicted_position()
	var direction := global_position.direction_to(aim_point)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT # Fallback

	# Apply random spread
	if aim_spread_degrees > 0.0:
		var spread := randf_range(-aim_spread_degrees, aim_spread_degrees)
		direction = direction.rotated(deg_to_rad(spread))

	var dart: Projectile = dart_scene.instantiate()
	get_parent().add_child(dart)
	dart.launch(global_position + direction * dart_spawn_distance, direction, dart_speed)


## Calculate predicted aim point using iterative refinement.
## Each iteration improves accuracy by accounting for updated travel time.
func _calculate_predicted_position() -> Vector2:
	if player == null:
		return global_position  # Safe fallback when no player
	if prediction_iterations == 0:
		return player.global_position

	var predicted_pos: Vector2 = player.global_position
	for i in prediction_iterations:
		var time_to_target := global_position.distance_to(predicted_pos) / dart_speed
		predicted_pos = player.global_position + player.velocity * time_to_target
	return predicted_pos


func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACK and can_see_player():
		_start_attack_animation()
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
	if current_state == State.DEATH:
		return  # Already dead, don't apply knockback
	velocity = hit_box.global_position.direction_to(global_position) * hit_box.knockback * knockback_multiply
	current_state = State.STUN
	attack_timer.stop() # Interrupt attack

#endregion


#region Death State

func _on_death() -> void:
	AudioManager.PlaySFX_at_position(sfx_on_death, self.global_position)
	current_state = State.DEATH
	velocity = Vector2.ZERO
	attack_timer.stop()
	# Disable collision so enemy doesn't block player
	set_collision_layer_value(3, false)  # Layer 3 = Enemy
	$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	animation_player.play("death")

#endregion


#region Animation

func _update_animation() -> void:
	# Death state handles its own animation
	if current_state == State.DEATH:
		return

	# Update facing direction based on state
	if current_state == State.ATTACK and player != null:
		# Face toward predicted aim point (same as where darts fire)
		var aim_point := _calculate_predicted_position()
		_facing_direction = global_position.direction_to(aim_point)
	elif velocity.length() > 10:
		_facing_direction = velocity.normalized()

	var dir_name := _get_direction_name()
	var state_name: String = State.keys()[current_state].to_lower()

	if state_name == "reposition":
		# Reposition uses move animations (visually identical)
		state_name = "move"
	elif state_name == "attack":
		# In attack state, only update to idle if not playing attack animation
		# Attack animations are triggered explicitly by _start_attack_animation()
		if not animation_player.current_animation.begins_with("attack_"):
			state_name = "idle"
		else:
			return  # Don't interrupt attack animation

	var anim_name := "%s_%s" % [state_name, dir_name]

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)


func _get_direction_name() -> String:
	if abs(_facing_direction.x) > abs(_facing_direction.y):
		return "left" if _facing_direction.x < 0 else "right"
	else:
		return "down" if _facing_direction.y > 0 else "up"

#endregion


#region Debug
## Debug Visualization Guide:
##
## LABEL (above enemy):
##   Line 1: Current state (IDLE, MOVE, REPOSITION, ATTACK, STUN)
##   Line 2: LOS status (true = can see player, false = blocked)
##
## YELLOW LINES: Navigation path the enemy is following
##   - Shows the complete path from current position to target
##   - Path should curve around walls if agent_radius is set on NavigationPolygon
##
## RED CIRCLE: Target position
##   - In MOVE state: ideal_distance circle around player
##   - In REPOSITION state: player's position (trying to regain LOS)
##
## GREEN CIRCLE: Next waypoint
##   - The immediate point the enemy is moving toward
##   - Enemy moves to this, then advances to the next waypoint

func _update_debug_label() -> void:
	var label: Label = $Label
	var should_show := OS.is_debug_build() and debug_draw

	if label:
		label.visible = should_show
		if should_show:
			var state_name: String = State.keys()[current_state]
			label.text = "%s\nLOS:%s\nHP:%s" % [state_name, can_see_player(), current_hp]
			# Ensure label is properly sized and positioned
			label.reset_size()  # Auto-size to fit content

	if should_show:
		# Cache nav path for drawing
		_debug_nav_path = nav_agent.get_current_navigation_path()
	else:
		# Clear cached path when debug is off
		_debug_nav_path.clear()

	# Always redraw to clear or update debug visuals
	queue_redraw()


func _draw() -> void:
	if not OS.is_debug_build() or not debug_draw:
		return

	# Yellow lines: Full navigation path from current position to target
	if _debug_nav_path.size() > 1:
		for i in range(_debug_nav_path.size() - 1):
			var from_local := to_local(_debug_nav_path[i])
			var to_local_pos := to_local(_debug_nav_path[i + 1])
			draw_line(from_local, to_local_pos, Color.YELLOW, 2.0)

	# Red circle: Final target position (where we ultimately want to be)
	var target_local := to_local(nav_agent.target_position)
	draw_circle(target_local, 8.0, Color.RED)

	# Green circle: Next waypoint (immediate movement target)
	if nav_agent.is_navigation_finished() == false:
		var next_local := to_local(nav_agent.get_next_path_position())
		draw_circle(next_local, 5.0, Color.GREEN)

#endregion
