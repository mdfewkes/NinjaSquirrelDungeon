class_name MultiCommandTile
extends Area2D

signal player_directed(input_vector: Vector2)

@export var trigger_direction = Vector2.ZERO

func _ready() -> void:
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node2D):
	if body is Player:
		await _run_commands()

func _run_commands():
	for command in get_children():
		if command.has_method("run"):
			await command.run()
