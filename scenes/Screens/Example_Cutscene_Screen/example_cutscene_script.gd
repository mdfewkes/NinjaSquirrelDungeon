class_name ExampleCutsceneScript
extends Node

@onready var cutscene_director = $CutsceneDirector

func _ready() -> void:
	cutscene_director.move_player_right()
	#await cutscene_director.wait(10.0)
	#cutscene_director.stop_player()
	#await cutscene_director.wait(3.0)
	#cutscene_director.move_player_right()
	#await cutscene_director.wait(0.5)
	#cutscene_director.move_player_up()
	#await cutscene_director.wait(10.0)
	#cutscene_director.stop_player()
