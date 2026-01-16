class_name RollCommand
extends Node

signal roll_command_selected()

func run():
	roll_command_selected.emit()
