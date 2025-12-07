class_name ExampleCutsceneDirector
extends Node

signal player_directed(input_vector: Vector2)
var timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.one_shot = true
	_move_player_right(1.3)

func _wait(duration: float) -> void:
	timer.wait_time = duration
	timer.start()
	await timer.timeout

func _move_player_right(duration: float) -> void:
	player_directed.emit(Vector2(1,0))
	await _wait(duration)
	_move_player_up(1.2)
	
func _move_player_up(duration: float) -> void:
	player_directed.emit(Vector2(0,-1))
	await _wait(duration)
	_move_player_left(2.8)

func _move_player_left(duration: float) -> void:
	player_directed.emit(Vector2(-1,0))
	await _wait(duration)
	_move_player_down(1.2)
	
func _move_player_down(duration: float) -> void:
	player_directed.emit(Vector2(0,1))
	await _wait(duration)
	_move_player_right(2.8)
