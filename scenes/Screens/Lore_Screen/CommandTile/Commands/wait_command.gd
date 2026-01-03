class_name WaitCommand
extends Node

func run():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.start()
	await timer.timeout
