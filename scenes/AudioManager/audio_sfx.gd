class_name AudioSFX
extends Resource

enum StealStrategy {Oldest, Furthest}

@export var volume_dB: float = 0
@export var stream: AudioStream

@export var max_voices: int = 4
@export var voice_stealling: bool = true
@export var steal_strategy: StealStrategy = StealStrategy.Oldest
@export var cooldown_time_msec: float = 10
@export var trigger_when_out_of_range:bool = false
@export var concurrency_group:String = ""

var last_play_time:float = 0
