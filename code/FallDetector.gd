class_name FallDetector
extends Area2D

signal entered_pit(pit: Node2D)
signal exited_pit(pit: Node2D)
signal fell_into_pit

const FALL_ROTATE = 0.0
const FALL_SHRINK = 0.2
const FALL_COLOR = Color.BLACK

## If this is detecting falls for something other than its parent node, you can set it here
@export var target: Node2D

## If enabled, the parent will be spun and shrunk and darkened, then hit and then returned to its last position before falling
@export var default_animation_enabled: bool = true

## If enabled, the signals will be sent even if falling is disabled
@export var signals_enabled: bool = true

## If enabled, the target's position will be tracked and restored after a fall
@export var position_tracking_enabled: bool = true

## If set, this will be played when the target falls
@export var sfx_on_fall: AudioSFX

## If set, the target will be moved towards the center of the pit (whether the default animation is enabled or not)
@export var move_toward_center: bool = true

## How long before the position is reset and the fall signal sent after entering the area
@export var fall_time: float = 1.0

## If false, the object is queued for free after falling rather than being reset back to a safe position
@export var reset_after_fall: bool = true

var falling := false
var active_pits: Array[Node2D] = []
var pit_center: Vector2

var last_safe_position: Vector2
var last_safe_time: int


func _ready() -> void:
	if not target:
		target = get_parent()
	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)


func _process(delta: float) -> void:
	var now = Time.get_ticks_msec()
	if not falling and not active_pits and now > last_safe_time + 1000:
		last_safe_time = now
		last_safe_position = target.position
	if falling and move_toward_center and pit_center:
		var d = target.position.distance_to(pit_center)
		target.position.x = move_toward(target.position.x, pit_center.x, delta * d)
		target.position.y = move_toward(target.position.y, pit_center.y, delta * d)


func _on_area_entered(area: Area2D) -> void:
	_on_entered(area)


func refresh_active_pits() -> void:
	for pit in active_pits:
		_on_entered(pit)


func _on_entered(area_or_body: Node2D) -> void:
	if area_or_body not in active_pits:
		active_pits.append(area_or_body)
	if falling:
		return
	if target.has_method("can_fall") and not target.can_fall(area_or_body):
		return
	falling = true
	if signals_enabled:
		emit_signal("entered_pit", area_or_body)
	if default_animation_enabled:
		call_deferred("_start_target_falling")
	if sfx_on_fall:
		AudioManager.PlaySFX(sfx_on_fall, target)
	pit_center = target.get_parent().to_local(area_or_body.global_position)

	await get_tree().create_timer(fall_time).timeout

	if reset_after_fall:
		target.position = last_safe_position
		falling = false
	else:
		target.queue_free.call_deferred()
	if signals_enabled:
		emit_signal("fell_into_pit")


func _on_area_exited(area: Area2D) -> void:
	active_pits.erase(area)
	if signals_enabled:
		emit_signal("exited_pit", area)


func _start_target_falling() -> void:
	var original_modulate: Color = target.modulate
	var original_scale: Vector2 = target.scale
	var original_rotation_degrees: float = target.rotation_degrees
	
	var t = create_tween()
	t.set_ease(Tween.EASE_IN)
	t.parallel().tween_property(target, "modulate", FALL_COLOR, fall_time)
	t.parallel().tween_property(target, "rotation_degrees", original_rotation_degrees + FALL_ROTATE, fall_time)
	t.parallel().tween_property(target, "scale", original_scale * FALL_SHRINK, fall_time)

	await t.finished
	
	if reset_after_fall:
		target.scale = original_scale
		target.modulate = original_modulate
		target.rotation_degrees = original_rotation_degrees


func _on_body_entered(body) -> void:
	_on_entered(body)


func _on_body_exited(body) -> void:
	active_pits.erase(body)
	if signals_enabled:
		emit_signal("exited_pit", body)
