class_name AudioSFX
extends Resource

@export var stream: AudioStream

@export var maxVoices: int = 4
@export var voiceStealling: bool = true
@export var stealOldest: bool = true
@export var cooldown_time_msec: float = 10

var last_play_time:float = 0

func play(target: Node2D) -> AudioStreamPlayer2D:
	return AudioManager.PlaySFX(self, target)
