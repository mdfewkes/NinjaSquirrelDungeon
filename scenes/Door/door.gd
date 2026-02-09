extends StaticBody2D

# This script can be attached to different scenes as long as they
# have the right shape. It expects a sprite and two collision shapes,
# one (the blocker) connected to a StaticBody2D and one (the unlocker)
# that causes the door to open when the player enters.
# Opening and closing is controlled by triggering an AnimationPlayer.
# The animation moves both the sprite and the blocker out of the player's way.
# Closing just plays the animation in reverse.
# A specific key can be required (or not).

signal door_open()
signal door_close()

## If not set to 0, the door will only open for keys where the item_value matches this number.
@export var required_key_value := 0

## If set and greater than 0, the door will close again after the player leaves the unlock area.
@export var close_after_seconds := 0.0

## Set to start the door out in an open state
@export var is_open := false

## If true, the key is removed from inventory as the door opens.
@export var single_use_key := true

## If one or more switches is linked, they open the door instead of the normal unlock area
@export var switches: Array[SwitchTrigger] = []

@export var sfx_on_open: AudioSFX
@export var sfx_on_close: AudioSFX

@onready var sprite := $Sprite2D
@onready var blocker := $Blocker
@onready var anim := $AnimationPlayer

var close_timer: Timer


func _ready() -> void:
	if is_open:
		anim.play("open")
	else:
		anim.play("RESET")

	if close_after_seconds > 0:
		close_timer = Timer.new()
		close_timer.one_shot = true
		close_timer.autostart = false
		close_timer.wait_time = close_after_seconds
		close_timer.connect("timeout", close)
		add_child(close_timer)
		
	for switch in switches:
		switch.connect("triggered", _on_switch_triggered)


func open():
	if not is_open:
		anim.play("open")
		door_open.emit()
		if sfx_on_open:
			AudioManager.PlaySFX(sfx_on_open, self)
	is_open = true
	persisted_state_changed.emit(self)

func close():
	if is_open:
		anim.play_backwards("open")
		door_close.emit()
		if sfx_on_close:
			AudioManager.PlaySFX(sfx_on_close, self)
	is_open = false
	persisted_state_changed.emit(self)


func _on_unlock_area_entered(body: Node2D) -> void:
	if body is Player:
		if close_timer:
			close_timer.stop()
		if not is_open:
			if required_key_value == 0 and len(switches) == 0:
				open()
			elif InventoryManager.has_item(InventoryManager.ItemType.key, required_key_value):
				open()
				if single_use_key:
					InventoryManager.remove_item(InventoryManager.ItemType.key, required_key_value)
			else:
				print("Required key not present: ", required_key_value)


func _on_unlock_area_body_exited(body: Node2D) -> void:
	if body is Player and close_timer and is_open:
		close_timer.start()


func _on_switch_triggered(_switch: SwitchTrigger):
	call_deferred("open")
	if close_timer:
		close_timer.call_deferred("start")


signal persisted_state_changed(obj: Node)

func get_persisted_state() -> Dictionary:
	return {
		"is_open": is_open
	}
	
func restore_persisted_state(data: Dictionary) -> void:
	if "is_open" in data:
		is_open = data["is_open"]
		if is_open:
			anim.play("open", -1, 10)
		else:
			anim.play("RESET")
