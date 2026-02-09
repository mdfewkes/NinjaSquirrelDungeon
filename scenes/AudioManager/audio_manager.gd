extends Node

@onready var sfx_template: AudioStreamPlayer2D = $SFXTemplate
@onready var ui_template: AudioStreamPlayer = $UITemplate
@onready var texture_rect: Sprite2D = $TextureRect
@onready var music: AudioStreamPlayer = $Music

@export var listening_range: float = 1000.0

enum MusicStates {Title, Game, FinalRoom, FinalChase, Finale}
var music_state = MusicStates.Title

var interactive_music_player: AudioStreamPlaybackInteractive

var active_voices = {} # Dict String : Array[AudioStreamPlayback]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()

func _ready() -> void:
	interactive_music_player = music.get_stream_playback() as AudioStreamPlaybackInteractive
	interactive_music_player.switch_to_clip_by_name(MusicStates.keys()[music_state])

func _process(_delta: float) -> void:
	var dead_voices = []
	for voice in active_voices:
		var dead_source = []
		for i in range(active_voices[voice].size()):
			if not is_instance_valid(active_voices[voice][i]):
				dead_source.push_front(active_voices[voice][i])
				
		for i in range(dead_source.size()):
			active_voices[voice].erase(dead_source[i])
			
		if active_voices[voice].size() == 0:
			dead_voices.push_back(voice)
			
	for i in range(dead_voices.size()):
		active_voices.erase(dead_voices[i])


func toggle_mute() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, not AudioServer.is_bus_mute(master_bus))


func PlayMusic(new_track: MusicStates) -> void:
	if new_track != music_state:
		music_state = new_track
		interactive_music_player.switch_to_clip_by_name(MusicStates.keys()[music_state])


func PlaySFX(sfx: AudioSFX, target: Node2D) -> AudioStreamPlayer2D:
	if sfx == null or target == null:
		return null
	if not sfx.trigger_when_out_of_range:
		var center = _get_listening_center()
		var distance = center.distance_to(target.global_position)
		if distance > listening_range:
			return null
	if not _open_voice_available(sfx):
		return null
	
	var freshAudioSource = sfx_template.duplicate()
	target.add_child(freshAudioSource)
	freshAudioSource.global_position = target.global_position
	
	freshAudioSource.volume_db = sfx.volume_dB
	freshAudioSource.stream = sfx.stream
	freshAudioSource.play()
	
	_add_voice(sfx, freshAudioSource)
	
	freshAudioSource.finished.connect(freshAudioSource.queue_free)
	
	texture_rect.global_position = freshAudioSource.global_position
	
	return freshAudioSource

func PlaySFX_at_position(sfx: AudioSFX, position: Vector2) -> AudioStreamPlayer2D:
	var freshNode = Node2D.new()
	add_child(freshNode)
	freshNode.global_position = position
	
	var freshAudioSource = PlaySFX(sfx, freshNode)
	
	if freshAudioSource != null:
		freshAudioSource.finished.connect(freshNode.queue_free)
	
	return freshAudioSource

func PlayUI(sfx: AudioSFX) -> AudioStreamPlayer:
	if sfx == null:
		return null
	if not _open_voice_available(sfx):
		return null
	
	var freshAudioSource = ui_template.duplicate()
	add_child(freshAudioSource)
	
	freshAudioSource.volume_db = sfx.volume_dB
	freshAudioSource.stream = sfx.stream
	freshAudioSource.play()
	
	freshAudioSource.finished.connect(freshAudioSource.queue_free)
	
	# Add Voice
	sfx.last_play_time = Time.get_ticks_msec()
	var group = sfx.resource_path if sfx.concurrency_group.is_empty() else sfx.concurrency_group
	if active_voices.has(group):
		if active_voices[group].size() < sfx.max_voices:
			active_voices[group].push_back(freshAudioSource)
			return
			
		if sfx.voice_stealling:
			if active_voices[group][0]:
				active_voices[group].pop_front().emit_signal("finished")
			active_voices[group].push_back(freshAudioSource)
				
	else:
		active_voices[group] = []
		active_voices[group].push_back(freshAudioSource)
	
	return freshAudioSource

func _open_voice_available(sfx: AudioSFX) -> bool:
	if Time.get_ticks_msec() - sfx.last_play_time < sfx.cooldown_time_msec:
		return false
	
	var group = sfx.resource_path if sfx.concurrency_group.is_empty() else sfx.concurrency_group
	
	if active_voices.has(group):
		if sfx.max_voices > active_voices[group].size() or sfx.voice_stealling:
			return true
		else:
			return false
	
	return true

func _add_voice(sfx: AudioSFX, source: AudioStreamPlayer2D) -> void:
	sfx.last_play_time = Time.get_ticks_msec()
	
	var group = sfx.resource_path if sfx.concurrency_group.is_empty() else sfx.concurrency_group
	
	if active_voices.has(group):
		if active_voices[group].size() < sfx.max_voices:
			active_voices[group].push_back(source)
			return
			
		if sfx.voice_stealling:
			match sfx.steal_strategy:
				AudioSFX.StealStrategy.Oldest:
					active_voices[group].pop_front().emit_signal("finished")
					active_voices[group].push_back(source)
				AudioSFX.StealStrategy.Furthest:
					active_voices[group].push_back(source)
					
					var center = _get_listening_center()
					var furthest_playback = -1
					var furthest_distance = center.distance_to(source.global_position)
					for playback in range(active_voices[group].size()):
						var distance = center.distance_to(active_voices[group][playback].global_position)
						if distance > furthest_distance:
							furthest_playback = playback
							furthest_distance = distance
					active_voices[group][furthest_playback].emit_signal("finished")
					active_voices[group].remove_at(furthest_playback)
	else:
		active_voices[group] = []
		active_voices[group].push_back(source)

func _get_listening_center() -> Vector2:
	var center = Vector2.ZERO
	var viewport = get_viewport()
	if viewport:
		if viewport.get_audio_listener_2d():
			center = viewport.get_audio_listener_2d().global_position
		elif viewport.get_camera_2d():
			center = viewport.get_camera_2d().get_screen_center_position()
	return center
