extends Node2D 

@export var spin_speed: float = 1.0

func _process(delta):
    rotation_degrees += spin_speed * delta * 60.0
