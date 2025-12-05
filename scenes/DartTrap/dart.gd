class_name Dart
extends Node2D

# TODO: we should be able to combine this with the shuriken
const DEFAULT_SPEED = 500.0
const SLOW_FACTOR = 0.8
const STOP_SPEED = 250.0
const RAY_LENGTH = 8.0
const FADE_SPEED = 0.2

@onready var sparks: CPUParticles2D = $Sparks
@onready var wall_detector: RayCast2D = $WallDetector
@onready var hit_box: HitBox = $HitBox

var velocity: Vector2
var fading := false


func set_speed(speed: float) -> void:
	var dir = Vector2.from_angle(rotation)
	velocity = dir * speed
	wall_detector.target_position = dir * RAY_LENGTH


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if wall_detector.is_colliding() and wall_detector.get_collider() is TileMapLayer:
		var wall_normal := wall_detector.get_collision_normal()
		var cur_direction := velocity.normalized()
		var bounce_direction := cur_direction.bounce(wall_normal)
		var speed := velocity.length()

		if bounce_direction.is_equal_approx(wall_normal):
			speed = STOP_SPEED
		else:
			speed *= SLOW_FACTOR
		position = wall_detector.get_collision_point()
		velocity = bounce_direction * speed
		rotation = bounce_direction.angle()
		sparks.emitting = true
		wall_detector.enabled = false

		if speed <= STOP_SPEED:
			_fade_and_free()

		await get_tree().create_timer(0.05).timeout
		wall_detector.enabled = !fading


func _fade_and_free():
	fading = true
	hit_box.monitoring = false
	hit_box.monitorable = false
	wall_detector.enabled = false
	var tween := create_tween()
	tween.parallel()
	tween.tween_property(self, "rotation_degrees", self.rotation_degrees + randf_range(-500.0, 500.0), FADE_SPEED)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), FADE_SPEED)
	await tween.finished
	queue_free()
