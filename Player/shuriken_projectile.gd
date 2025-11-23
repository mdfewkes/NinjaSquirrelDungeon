extends Node2D

@export var velocity: Vector2 = Vector2(500, 0)

func _process(delta: float) -> void:
	position += velocity * delta
