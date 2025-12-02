class_name CollectableItem;
extends Area2D
signal item_collected(node: CollectableItem)

# This script can be attached to any scene with an Area2D,
# a Sprite2d and a CollisionShape2D. It can be used for keys,
# collectible lore items (e.g. "take this map to Old Joe..."),
# or single-use buffs (e.g. health).
# The sprite will move up and down in a sine wave at a controllable
# speed and amount (set to 0 for no movement) and disappear when
# the player collides with it.

## Controls how the item behaves in the game
@export var item_type: InventoryManager.ItemType

## Controls
@export var item_value := 0

## How many seconds it takes for the item to go through one cycle of up and down
@export var bounce_speed := 0.6

## Controls how many pixels in either direction the item moves as it bounces
@export var bounce_amount := 5.0

## If true, the item will be added to the player's inventory. If not, the "item_collected" signal will still be emitted and the item removed. Single use item behaviors can be connected to the signal.
@export var add_to_inventory := true

@onready var sprite: Sprite2D = $Sprite2D

# randomized to make sure items don't all bounce in lockstep
var bounce_differentiator: int


func trigger_collection() -> void:
	if add_to_inventory:
		InventoryManager.add_item(self)
	InventoryManager.emit_item_collected(self)
	emit_signal("item_collected", self)
	queue_free()


func _ready() -> void:
	bounce_differentiator = randf_range(0.0, 2 * PI)


func _process(delta: float) -> void:
	if sprite:
		sprite.offset.y = sin(bounce_speed * 2 * PI * Time.get_ticks_msec() / 1000.0) * bounce_amount


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		trigger_collection()
