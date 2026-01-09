extends Node

const SHAKE_SPEED = 1.0
const STRENGTH_MULTIPLIER = 16.0 # convert 1.0 strength to pixels

@onready var noise := FastNoiseLite.new()

var shake_strength: float = 0.0
var shake_decay: float = 1.0

enum FlashType { None, Neutral, Light, Dark, Stark, Bland }
var flash_tween: Tween


func hit(intensity: float, seconds: float, flash_type = FlashType.Neutral, flash_intensity_ratio = 1.0) -> void:
	shake(intensity, seconds)
	if flash_type != FlashType.None:
		flash(intensity * flash_intensity_ratio, seconds, flash_type)


func shake(intensity: float, seconds: float) -> void:
	var new_strength = intensity * STRENGTH_MULTIPLIER
	if new_strength <= shake_strength or seconds <= 0.0:
		return
	shake_strength = new_strength
	shake_decay = new_strength / seconds

	var weak_vibes := 0.0
	var strong_vibes := 0.0
	if intensity >= 0.5:
		strong_vibes = clampf((intensity - 0.5) * 2.0, 0.0, 1.0)
	else:
		weak_vibes = clampf(intensity * 2.0, 0.0, 1.0)
	Input.start_joy_vibration(0, weak_vibes, strong_vibes, seconds)


# TODO: implement this with either a shader or a ColorRect in the UI layer
# There are probably also cooler things we could do here if we added a WorldEnvironment node 
# (e.g. with bloom or treating some sprites or layers differently, etc)
func flash(intensity: float, seconds: float, type: FlashType) ->void:
	var env: WorldEnvironment = get_tree().get_first_node_in_group("world_environment")
	if env and type != FlashType.None:
		if flash_tween and flash_tween.is_running():
			flash_tween.stop()
		flash_tween = create_tween()
		flash_tween.set_parallel(true)
		flash_tween.set_ease(Tween.EASE_OUT)
		env.environment.glow_bloom = intensity
		match type:
			FlashType.Light:
				env.environment.adjustment_brightness = 2.0 * intensity
			FlashType.Dark:
				env.environment.glow_bloom = 0.0 # bloom doesn't look nice with this one
				env.environment.adjustment_brightness = 1.0 - intensity * 0.7
			FlashType.Stark:
				env.environment.adjustment_contrast = 2.0 * intensity
				env.environment.adjustment_saturation = 2.0 * intensity
			FlashType.Bland:
				env.environment.adjustment_saturation = 1.0 - intensity
		flash_tween.tween_property(env.environment, "glow_bloom", 0.0, seconds)
		flash_tween.tween_property(env.environment, "adjustment_brightness", 1.0, seconds)
		flash_tween.tween_property(env.environment, "adjustment_contrast", 1.0, seconds)
		flash_tween.tween_property(env.environment, "adjustment_saturation", 1.0, seconds)


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
				shake(0.5, 0.5)
			KEY_2:
				hit(1.0, 0.5, FlashType.Neutral)
			KEY_3:
				hit(1.0, 0.5, FlashType.Light)
			KEY_4:
				hit(1.0, 0.5, FlashType.Dark)
			KEY_5:
				hit(1.0, 0.5, FlashType.Stark)
			KEY_6:
				hit(1.0, 0.5, FlashType.Bland)
