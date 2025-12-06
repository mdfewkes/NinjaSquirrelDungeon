class_name FloorSwitch
extends Area2D

signal triggered(trigger: FloorSwitch)

@onready var reset_timer: Timer = $ResetTimer

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	reset_timer.connect("timeout", _on_timeout)

func _on_body_entered(body: Node2D):
	if body is Player:
		call_deferred("disable")
		emit_signal("triggered", self)

func _on_timeout():
	call_deferred("enable")

func enable():
	monitoring = true
	show() # TODO: this can be an animation player

func disable():
	monitoring = false
	hide()
	reset_timer.start()
