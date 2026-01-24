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

func process_state(_player :Player, _delta: float) -> bool:
	return true

func can_enter() -> bool:
	return true

func _action_enter(_player :Player) -> void:
	pass

func _action_exit(_player :Player) -> void:
	pass
