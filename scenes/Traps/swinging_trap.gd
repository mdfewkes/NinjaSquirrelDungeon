class_name SwingingTrap
extends Node2D

enum SwingDir { left, right, up, down, random }

## A list of switches or other triggers that will make it swing
@export var triggers: Array[SwitchTrigger] = []

## If >0 the trap will trigger regularly on a timer
@export var trigger_on_timer_seconds := 0.0

## Which direction does it come from? Left/right and up/down will alternate back and forth.
@export var direction: SwingDir = SwingDir.left

@export var sfx_on_trigger: AudioSFX

@onready var anim_player: AnimationPlayer = $AnimationPlayer

const next_dir = {
	SwingDir.left: SwingDir.right,
	SwingDir.right: SwingDir.left,
	SwingDir.up: SwingDir.down,
	SwingDir.down: SwingDir.up,
	SwingDir.random: SwingDir.random,
}
const rand_dirs = [SwingDir.left, SwingDir.right, SwingDir.up, SwingDir.down]

func _ready() -> void:
	anim_player.play("RESET")
	hide()
	for trigger in triggers:
		trigger.connect("triggered", _on_triggered)
	if trigger_on_timer_seconds > 0:
		var t = Timer.new()
		add_child(t)
		t.wait_time = trigger_on_timer_seconds
		t.start()
		t.connect("timeout", _on_timer)


func _on_timer() -> void:
	call_deferred("swing")
	
	
func _on_triggered(_switch: SwitchTrigger) -> void:
	call_deferred("swing")


func swing() -> void:
	show()
	if anim_player.is_playing():
		return

	ImpactEffects.shake(0.2, 1.0)
	if sfx_on_trigger:
		AudioManager.PlaySFX(sfx_on_trigger, self)

	var dir: SwingDir = direction
	if dir == SwingDir.random:
		var dir_i := randi_range(0, rand_dirs.size() - 1)
		dir = rand_dirs[dir_i]
		print("rand:", [dir_i, dir])
	direction = next_dir[direction]
	match dir:
		SwingDir.left:
			anim_player.play("swing")
		SwingDir.right:
			anim_player.play_backwards("swing")
		SwingDir.up:
			anim_player.play("swing_down")
		SwingDir.down:
			anim_player.play_backwards("swing_down")
