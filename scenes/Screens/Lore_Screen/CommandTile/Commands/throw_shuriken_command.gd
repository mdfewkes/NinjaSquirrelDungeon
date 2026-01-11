class_name ThrowShurikenCommand
extends Node

signal action_selected(action: String)

func run():
	action_selected.emit("action_2")
