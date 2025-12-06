extends Node2D

## Pixels / second
@export var dart_speed := 500.0

## Number of seconds between darts. 0 means triggering will be manual.
@export var fire_wait_time := 1.0

## If one or more switches is linked, they trigger the firing instead of the timer
@export var switches: Array[FloorSwitch] = []

@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var template: Dart = $DartTemplate
@onready var timer: Timer = $FireTimer


func _ready():
	for switch in switches:
		switch.connect("triggered", _on_switch_triggered)

	timer.connect("timeout", fire)
	if fire_wait_time > 0.0:
		timer.wait_time = fire_wait_time
	else:
		timer.stop()

	template.hide()


func fire():
	if not template:
		return
	fire_particles.emitting = true
	var dart = template.duplicate(DUPLICATE_USE_INSTANTIATION)
	get_parent().add_child(dart)
	# normalize the dart's rotation and position to include the parent's rotation
	# so it's pointed the same direction when it's added to the parent node.
	# the bounce logic gets really weird if we leave it as a child of this trap
	# and the trap has any of its own rotation.
	dart.rotation += rotation
	dart.velocity = Vector2.from_angle(dart.rotation) * dart_speed
	dart.global_position = template.global_position
	dart.show()


func _on_switch_triggered(_switch: FloorSwitch):
	call_deferred("fire")
