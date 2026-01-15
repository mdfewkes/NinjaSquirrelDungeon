class_name SwingingTrap
extends Node2D

## A list of switches or other triggers that will make it swing
@export var triggers: Array[SwitchTrigger] = []

## If >0 the trap will trigger regularly on a timer
@export var trigger_on_timer_seconds := 0.0

## Start out coming from the left? (subsequent triggers will alternate)
@export var from_left: bool = true

@export var sfx_on_trigger: AudioSFX

@onready var anim_player: AnimationPlayer = $AnimationPlayer


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
	if from_left:
		anim_player.play("swing")
		from_left = false
	else:
		anim_player.play_backwards("swing")
		from_left = true
