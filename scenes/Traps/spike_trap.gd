class_name SpikeTrap
extends Node2D

## Starting state. Are the spikes out or retracted?
@export var active: bool = true

## If false, the spikes will show empty holes when retracted
@export var hide_when_inactive: bool = false

## Number of seconds between the trap toggling between active states. 0 means triggering will be manual.
@export var toggle_interval := 0.0

## How long after being triggered should we wait before the spikes come up?
@export var preactivate_delay := 0.0

## How long after the spikes come up before they retract? If 0 they will never retract
@export var deactivate_delay := 0.0

## If one or more switches is linked, they trigger activation instead of the timer
@export var switches: Array[SwitchTrigger] = []

@export var sfx_on_activate: AudioSFX
@export var sfx_on_deactivate: AudioSFX

@onready var timer: Timer = $ActivateTimer
@onready var hit_box: HitBox = $HitBox
@onready var texture: TextureRect = $TextureRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var pre_timer: Timer
var post_timer: Timer

func _ready() -> void:
	for switch in switches:
		switch.connect("triggered", _on_switch_triggered)

	timer.connect("timeout", _on_timer_timeout)
	if toggle_interval > 0.0:
		timer.wait_time = toggle_interval
	else:
		timer.stop()
	if preactivate_delay > 0.0:
		pre_timer = Timer.new()
		pre_timer.autostart = false
		pre_timer.one_shot = true
		pre_timer.wait_time = preactivate_delay
		add_child(pre_timer)
	if deactivate_delay > 0.0:
		post_timer = Timer.new()
		post_timer.autostart = false
		post_timer.one_shot = true
		post_timer.wait_time = deactivate_delay
		post_timer.connect("timeout", _on_timer_timeout)
		add_child(post_timer)
		
	call_deferred("set_active", active, true)


func trigger():
	if active:
		set_active(false)
	else:
		if pre_timer:
			pre_timer.start()
			await pre_timer.timeout
		set_active(true)
		if post_timer:
			post_timer.start()


func set_active(value: bool, silent: bool = false):
	active = value
	if not texture:
		await ready
	if value:
		if hide_when_inactive:
			texture.show()
		anim_player.play("activate")
		if not silent and sfx_on_activate:
			AudioManager.PlaySFX(sfx_on_activate, self)
	else:
		anim_player.play_backwards("activate")
		if not silent and sfx_on_deactivate:
			AudioManager.PlaySFX(sfx_on_deactivate, self)
		if hide_when_inactive:
			await anim_player.animation_finished
			texture.hide()


func _on_switch_triggered(_switch: SwitchTrigger):
	call_deferred("trigger")


func _on_timer_timeout():
	call_deferred("trigger")
	
