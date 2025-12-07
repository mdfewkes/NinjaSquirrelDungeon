class_name SwingingTrap
extends Node2D

## A list of switches or other triggers that will make it swing
@export var triggers: Array[SwitchTrigger] = []

## If >0 the trap will trigger regularly on a timer
@export var trigger_on_timer_seconds := 0.0

## Start out coming from the left? (subsequent triggers will alternate)
@export var from_left: bool = true

@onready var player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	player.play("RESET")
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
	if player.is_playing():
		return
	if from_left:
		player.play("swing")
		from_left = false
	else:
		player.play_backwards("swing")
		from_left = true
