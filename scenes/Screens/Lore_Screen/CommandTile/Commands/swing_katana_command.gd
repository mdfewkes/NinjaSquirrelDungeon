class_name SwingKatanaCommand
extends Node

signal action_selected(action: String)

func run():
	action_selected.emit("action_1")
