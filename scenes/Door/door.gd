extends StaticBody2D

# This script can be attached to different scenes as long as they
# have the right shape. It expects a sprite and two collision shapes,
# one (the blocker) connected to a StaticBody2D and one (the unlocker)
# that causes the door to open when the player enters.
# Opening and closing is controlled by triggering an AnimationPlayer.
# The animation moves both the sprite and the blocker out of the player's way.
# Closing just plays the animation in reverse.
# A specific key can be required (or not).

## If not set to 0, the door will only open for keys where the item_value matches this number.
@export var required_key_value := 0

## If set and greater than 0, the door will close again after the player leaves the unlock area.
@export var close_after_seconds := 0.0

## Set to start the door out in an open state
@export var is_open := false

## If true, the key is removed from inventory as the door opens.
@export var single_use_key := true

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


func open():
	if not is_open:
		anim.play("open")
	is_open = true


func close():
	if is_open:
		anim.play_backwards("open")
	is_open = false


func _on_unlock_area_entered(body: Node2D) -> void:
	if body is Player:
		if required_key_value == 0:
			open()
		elif InventoryManager.has_item(InventoryManager.ItemType.key, required_key_value):
			open()
			if single_use_key:
				InventoryManager.remove_item(InventoryManager.ItemType.key, required_key_value)
		else:
			print("Required key not present: ", required_key_value)
		if close_timer:
			close_timer.stop()


func _on_unlock_area_body_exited(body: Node2D) -> void:
	if body is Player and close_timer and is_open:
		close_timer.start()


func _on_close_timer():
	if close_timer != null:
		close()
	close_timer = null
