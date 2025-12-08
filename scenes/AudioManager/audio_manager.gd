extends Node

var active_voices = {}

func _unhandled_input(event: InputEvent) -> void:
	if FeatureFlags.is_enabled("mute_toggle"):
		if event.is_action_pressed("mute"):
			toggle_mute()
			get_viewport().set_input_as_handled()


func toggle_mute() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, not AudioServer.is_bus_mute(master_bus))


func PlaySFX(sfx: AudioSFX, target: Node2D) -> AudioStreamPlayback:
	if sfx == null or target == null:
		return null
	
	var freshAudioSource = AudioStreamPlayer2D.new()
	freshAudioSource.global_position = target.global_position
	target.add_child(freshAudioSource)
	
	freshAudioSource.bus = "SFX"
	freshAudioSource.stream = sfx.stream
	freshAudioSource.play()
	
	freshAudioSource.finished.connect(freshAudioSource.queue_free)
	
	
	return freshAudioSource.get_stream_playback()

func _check_for_open_voice() -> bool:
	return false
