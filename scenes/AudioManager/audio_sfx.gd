class_name AudioSFX
extends Resource

@export var stream: AudioStream

@export var maxVoices: int = 4
@export var voiceStealling: bool = true
@export var stealOldest: bool = true
@export var cooldown: float = 0.01

func play(target: Node2D) -> AudioStreamPlayback:
	return AudioManager.PlaySFX(self, target)
