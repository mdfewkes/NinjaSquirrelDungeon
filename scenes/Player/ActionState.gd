class_name ActionState extends Node

signal enter(player :Player)
signal exit(player :Player)

func enter_state(player :Player) -> void:
	enter.emit(player)

func exit_state(player :Player) -> void:
	exit.emit(player)

func _ready() -> void:
	enter.connect(_action_enter)
	exit.connect(_action_exit)

func process_state(player :Player, delta :float) -> bool:
	return false

func _action_enter(player :Player) -> void:
	pass

func _action_exit(player :Player) -> void:
	pass
