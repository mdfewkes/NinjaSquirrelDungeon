extends Node


func PlaySFX(audio_stream: AudioStream, target: Node2D) -> AudioStreamPlayback:
	var freshAudioSource = AudioStreamPlayer2D.new()
	freshAudioSource.global_position = target.global_position
	target.add_child(freshAudioSource)
	
	freshAudioSource.bus = "SFX"
	freshAudioSource.stream = audio_stream
	freshAudioSource.play()
	
	freshAudioSource.finished.connect(freshAudioSource.queue_free)
	
	return freshAudioSource.get_stream_playback()
