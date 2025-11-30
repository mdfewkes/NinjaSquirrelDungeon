extends Node2D

const SPEED = 500.0
const STOP_SPEED = 250.0

@export var velocity: Vector2 = Vector2(500, 0)

@onready var wall_detector: RayCast2D = $WallDetector

func set_direction(dir: Vector2) -> void:
	velocity = dir * SPEED
	wall_detector.target_position = dir * 10


func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	if wall_detector.is_colliding():
		var wall_normal := wall_detector.get_collision_normal()
		velocity = wall_normal * STOP_SPEED
		_fade_and_free()

func _fade_and_free():
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	await tween.finished
	queue_free()
