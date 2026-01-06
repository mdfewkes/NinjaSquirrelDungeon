class_name MoveUpCommand
extends Node

signal player_directed(input_vector: Vector2)

func run():
	player_directed.emit(Vector2(0,-1))
