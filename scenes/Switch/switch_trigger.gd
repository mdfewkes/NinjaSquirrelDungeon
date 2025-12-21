class_name SwitchTrigger
extends Area2D

signal triggered(trigger: SwitchTrigger)

## Will the player trigger the switch just by entering the area? (collision mask to layer 2)
@export var player_trigger := true

## Will hitboxes (such as projectiles or the katana) trigger the switch? (collision mask to the correct layer for player vs enemy projectiles)
@export var hitbox_trigger := true

## Will any body that enteres the area trigger the switch? (still subject to collision mask)
@export var all_bodies_trigger := false

## If checked, there will be no visible indication of a switch
@export var invisible := false

@export var sfx_on_trigger: AudioSFX = preload("res://scenes/Switch/default_switch_sfx.tres")

@onready var reset_timer: Timer = $ResetTimer


func _ready() -> void:
	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)
	if reset_timer:
		reset_timer.connect("timeout", _on_reset_timeout)
	enable()


func _on_body_entered(body: Node2D):
	if body is Player and player_trigger:
		call_deferred("trigger")
	elif all_bodies_trigger:
		call_deferred("trigger")


func _on_area_entered(area: Area2D):
	if area is HitBox and hitbox_trigger:
		call_deferred("trigger")
		

func _on_reset_timeout():
	call_deferred("enable")


func trigger() -> void:
	disable()
	emit_signal("triggered", self)
	if sfx_on_trigger:
		AudioManager.PlaySFX(sfx_on_trigger, self)


func enable():
	monitoring = true
	# TODO: we'll probably want this to be an animation player for more complex press animation states
	if invisible:
		hide()
	else:
		show()


func disable():
	monitoring = false
	hide()
	if reset_timer:
		reset_timer.start()
