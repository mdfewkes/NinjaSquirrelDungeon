class_name Projectile
extends Node2D

@export var default_speed := 500.0

## Each time the projectile hits a wall it slows a little bit
@export var slow_on_bounce := 0.8

## If the speed gets to this value after bouncing the projectile will die/fade
@export var stop_speed := 250.0

## How quickly does it fade out after hitting a wall?
@export var fade_speed := 0.2

## If true, the node will rotate to face the direction it's headed (including after a bounce)
@export var rotate_with_direction := true

@onready var sparks: CPUParticles2D = $Sparks
@onready var wall_detector: RayCast2D = $WallDetector
@onready var hit_box: HitBox = $HitBox

var velocity: Vector2
var fading := false


func _ready() -> void:
	# start off at the default speed in the direction indicated by our current rotation
	#set_speed(default_speed)
	pass


func set_speed(speed: float) -> void:
	var dir = Vector2.from_angle(rotation)
	velocity = dir * speed
	_point_at(dir)


func set_direction(dir: Vector2) -> void:
	velocity = dir * default_speed
	_point_at(dir)


func _point_at(dir: Vector2) -> void:
	if rotate_with_direction:
		rotation = dir.angle()
	elif wall_detector:
		wall_detector.target_position = dir * wall_detector.target_position.length()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if wall_detector and wall_detector.is_colliding() and wall_detector.get_collider() is TileMapLayer:
		_handle_wall_collision(wall_detector.get_collision_point(), wall_detector.get_collision_normal())


func _handle_wall_collision(collision_point: Vector2, wall_normal: Vector2):
		var new_speed := velocity.length()
		var new_direction := velocity.normalized().bounce(wall_normal)
		
		# If we're striking the wall at approximately a right angle, the
		# projectile stops immediately. Otherwise we slow a little bit 
		# on each bounce and fade at a certain threshold (the defaults give
		# it 3 bounces).
		if new_direction.is_equal_approx(wall_normal):
			new_speed = stop_speed
		else:
			new_speed *= slow_on_bounce

		# we don't need to update the wall_detector here, because we're changing
		# the rotation of the whole node, so it'll rotate as well
		# we move immediately to the collision point so it doesn't look like the bounce
		# happens away from the wall. this can be a little jumpy at times. we may want
		# to set a very short timer here or something, but I think it's ok as is for now
		position = collision_point
		velocity = new_direction * new_speed
		_point_at(new_direction)
		
		if sparks:
			sparks.emitting = true
		if new_speed <= stop_speed:
			_fade_and_free()

		# Temporarily disable bouncing so we don't risk glitching back and forth
		# right around the moment of the bounce. I saw this happen in different
		# configurations of tiles around the bounce point.
		wall_detector.enabled = false
		await get_tree().create_timer(0.05).timeout
		wall_detector.enabled = !fading


func _fade_and_free():
	fading = true
	hit_box.monitoring = false
	if wall_detector:
		wall_detector.enabled = false
	if fade_speed > 0.0:
		var tween := create_tween()
		tween.parallel()
		tween.tween_property(self, "rotation_degrees", self.rotation_degrees + randf_range(-500.0, 500.0), fade_speed)
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), fade_speed)
		await tween.finished
	queue_free()
