extends Node

const SHAKE_SPEED = 1.0
const STRENGTH_MULTIPLIER = 20.0 # convert 1.0 strength to pixels

@onready var noise := FastNoiseLite.new()

var shake_strength: float = 0.0
var shake_decay: float = 1.0


func shake(intensity: float, seconds: float) -> void:
	var new_strength = intensity * STRENGTH_MULTIPLIER
	if new_strength <= shake_strength or seconds <= 0.0:
		return
	shake_strength = new_strength
	shake_decay = new_strength / seconds

	# TODO: convert intensity into weak and strong values
	Input.start_joy_vibration(0, 0, 1, seconds)


# TODO: implement this with either a shader or a ColorRect in the UI layer
# There are probably also cooler things we could do here if we added a WorldEnvironment node 
# (e.g. with bloom or treating some sprites or layers differently, etc)
func flash(intensity: float, seconds: float, color: Color) ->void:
	pass


func _process(delta: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if not cam: return
	if shake_strength > 0.0:
		shake_strength = move_toward(shake_strength, 0.0, shake_decay * delta)
		var noise_idx := Time.get_ticks_msec() * SHAKE_SPEED
		var shake_offset := Vector2(
			noise.get_noise_2d(1, noise_idx),
			noise.get_noise_2d(100, noise_idx),
		)
		cam.offset = shake_offset * shake_strength


# This is just for testing. We should remove it before release
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.physical_keycode:
			KEY_1:
				shake(0.25, 0.5)
			KEY_2:
				shake(0.5, 1.0)
			KEY_3:
				shake(1.0, 2.0)
				flash(1.0, 2.0, Color.BLACK)
			KEY_4:
				shake(0.75, 1.0)
				flash(1.0, 1.0, Color.RED)
