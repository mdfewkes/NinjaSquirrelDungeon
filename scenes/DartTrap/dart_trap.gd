extends Node2D

## Pixels / second
@export var dart_speed := 500.0

## Number of seconds between darts. 0 means triggering will be manual.
@export var fire_wait_time := 1.0

@onready var fire_particles: CPUParticles2D = $FireParticles
@onready var template: Dart = $DartTemplate
@onready var timer: Timer = $FireTimer

func _ready():
	timer.connect("timeout", fire)
	if fire_wait_time > 0.0:
		timer.wait_time = fire_wait_time
	else:
		timer.stop()
	template.hide()

func fire():
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
