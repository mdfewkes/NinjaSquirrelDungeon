extends Node

@export var switch_on_load: bool = true
@export var music_to_play: AudioManager.MusicStates

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if switch_on_load:
		switch_music()

func switch_music() -> void:
	AudioManager.PlayMusic(music_to_play)
