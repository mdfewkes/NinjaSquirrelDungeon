class_name WaitCommand
extends Node

@export var amount_of_time_to_wait: float

func run():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = amount_of_time_to_wait
	timer.one_shot = true
	timer.start()
	await timer.timeout
