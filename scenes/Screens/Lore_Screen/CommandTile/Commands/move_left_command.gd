class_name MoveLeftCommand
extends Node

signal player_directed(input_vector: Vector2)

func run():
	player_directed.emit(Vector2(-1,0))
