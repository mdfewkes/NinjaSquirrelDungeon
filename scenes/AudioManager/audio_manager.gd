extends Node

@export var listening_range: float = 1000.0

var active_voices = {} # Dict AudioSFX : Array[AudioStreamPlayback]

func _unhandled_input(event: InputEvent) -> void:
	if FeatureFlags.is_enabled("mute_toggle"):
		if event.is_action_pressed("mute"):
			toggle_mute()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var dead_voices = []
	for voice in active_voices:
		var dead_source = []
		for i in range(active_voices[voice].size()):
			if not is_instance_valid(active_voices[voice][i]):
				dead_source.push_front(i)
				
		for i in range(dead_source.size()):
			active_voices[voice].remove_at(i)
			
		if active_voices[voice].size() == 0:
			dead_voices.push_back(voice)
			
	for i in range(dead_voices.size()):
		active_voices.erase(dead_voices[i])


func toggle_mute() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, not AudioServer.is_bus_mute(master_bus))


func PlaySFX(sfx: AudioSFX, target: Node2D) -> AudioStreamPlayer2D:
	if sfx == null or target == null:
		return null
	if not sfx.trigger_if_out_of_range:
		var center = Vector2.ZERO
		var viewport = get_viewport()
		if viewport:
			if viewport.get_audio_listener_2d():
				center = viewport.get_audio_listener_2d().global_position
			elif viewport.get_camera_2d():
				center = viewport.get_camera_2d().get_screen_center_position()
		var distance = center.distance_to(target.global_position)
		print(distance)
		if distance > listening_range:
			return
	if not _open_voice_available(sfx):
		return null
	
	var freshAudioSource = AudioStreamPlayer2D.new()
	freshAudioSource.global_position = target.global_position
	target.add_child(freshAudioSource)
	
	freshAudioSource.bus = "SFX"
	freshAudioSource.volume_db = sfx.volume_dB
	freshAudioSource.stream = sfx.stream
	freshAudioSource.play()
	
	_add_voice(sfx, freshAudioSource)
	
	freshAudioSource.finished.connect(freshAudioSource.queue_free)
	
	return freshAudioSource

func _open_voice_available(sfx: AudioSFX) -> bool:
	if Time.get_ticks_msec() - sfx.last_play_time < sfx.cooldown_time_msec:
		return false
	
	if active_voices.has(sfx):
		if sfx.max_voices > active_voices[sfx].size() or sfx.voice_stealling:
			return true
		else:
			return false
	
	return true

func _add_voice(sfx: AudioSFX, source: AudioStreamPlayer2D) -> void:
	sfx.last_play_time = Time.get_ticks_msec()
	
	if active_voices.has(sfx):
		if sfx.max_voices > active_voices[sfx].size():
			active_voices[sfx].push_back(source)
		elif sfx.voice_stealling:
			if sfx.steal_oldest:
				active_voices[sfx].pop_front().stop()
				active_voices[sfx].push_back(source)
			else:
				active_voices[sfx].pop_back().stop()
				active_voices[sfx].push_back(source)
	else:
		active_voices[sfx] = []
		active_voices[sfx].push_back(source)
