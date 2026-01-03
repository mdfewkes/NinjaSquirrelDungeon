class_name StopCommand
extends Node

@export var amount_of_time_to_wait: float

signal player_directed(input_vector: Vector2)

func run():
	player_directed.emit(Vector2.ZERO)
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = amount_of_time_to_wait
	timer.one_shot = true
	timer.start()
	await timer.timeout
