extends Node2D

@onready var queue_free_timer: Timer = $QueueFreeTimer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_queue_free_timer_timeout() -> void:
	queue_free()
	
