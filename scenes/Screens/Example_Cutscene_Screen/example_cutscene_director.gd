class_name ExampleCutsceneDirector
extends Node

signal player_directed(input_vector: Vector2)
var timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.one_shot = true

func wait(duration: float) -> void:
	timer.wait_time = duration
	timer.start()
	await timer.timeout

func move_player_right() -> void:
	player_directed.emit(Vector2(1,0))
	
func move_player_up() -> void:
	player_directed.emit(Vector2(0,-1))

func move_player_left() -> void:
	player_directed.emit(Vector2(-1,0))
	
func move_player_down() -> void:
	player_directed.emit(Vector2(0,1))

func stop_player() -> void:
	player_directed.emit(Vector2(0,0))
