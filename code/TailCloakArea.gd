class_name TailCloakArea
extends Area2D

## Controls the coloring of the tail when cloaked
@export var tail_gradient: GradientTexture2D

## How many seconds does the player need to remain still for cloaking to start?
@export var wait_time: float = 3.0


func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)
	set_collision_mask_value(2, true)
	if not tail_gradient:
		print("WARNING: TailCloakArea won't work without a gradient set: " + get_path().get_concatenated_names())


func _on_body_entered(body: Node2D):
	if body is Player:
		body.set_cloakable_gradient(tail_gradient, wait_time)


func _on_body_exited(body: Node2D):
	if body is Player:
		body.clear_cloakable_gradient()
