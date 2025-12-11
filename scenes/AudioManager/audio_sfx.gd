class_name AudioSFX
extends Resource

@export var volume_dB: float = 0
@export var stream: AudioStream

@export var max_voices: int = 4
@export var voice_stealling: bool = true
@export var steal_oldest: bool = true
@export var cooldown_time_msec: float = 10
@export var trigger_if_out_of_range:bool = false

var last_play_time:float = 0
