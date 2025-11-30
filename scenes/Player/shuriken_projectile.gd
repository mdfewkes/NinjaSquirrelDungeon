extends Node2D

const SPEED = 500.0
const SLOW_FACTOR = 0.8
const STOP_SPEED = 250.0
const RAY_LENGTH = 10.0

@export var velocity: Vector2 = Vector2(500, 0)

@onready var wall_detector: RayCast2D = $WallDetector

func set_direction(dir: Vector2) -> void:
	velocity = dir * SPEED
	wall_detector.target_position = dir * RAY_LENGTH


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if wall_detector.is_colliding():
		var wall_normal := wall_detector.get_collision_normal()
		var cur_direction := velocity.normalized()
		var bounce_direction := cur_direction.bounce(wall_normal)
		var speed := velocity.length()

		print([bounce_direction, wall_normal, cur_direction])
		if bounce_direction.is_equal_approx(wall_normal):
			speed = STOP_SPEED
		else:
			speed *= SLOW_FACTOR
		if speed <= STOP_SPEED:
			_fade_and_free()
		velocity = bounce_direction * speed
		wall_detector.target_position = bounce_direction * RAY_LENGTH


func _fade_and_free():
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.4)
	await tween.finished
	queue_free()
