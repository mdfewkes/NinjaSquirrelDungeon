extends Node2D

@onready var queue_free_timer: Timer = $QueueFreeTimer

func _on_queue_free_timer_timeout() -> void:
	queue_free()
