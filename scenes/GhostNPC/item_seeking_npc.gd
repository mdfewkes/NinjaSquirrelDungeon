class_name ItemSeekingNpc
extends Node2D

## This is the type of item the player needs to have for the interaction
@export var item_type: InventoryManager.ItemType = InventoryManager.ItemType.story
## This is the other field that identifies the item the player needs to have for the interaction. It can be used to differentiate different types of story/quest items
@export var item_value: int = 0
## Should the needed item be removed from the player's inventory when the interaction is complete (after this npc gives its item to the player)
@export var remove_from_inventory: bool = true

## An item to give to the player after they bring the desired item to this npc
## If not set, no item will be given but the other item can still be collected (e.g. in exchange for lore)
@export var item_to_give: CollectableItem

@onready var trigger: DialogueTrigger = $DialogueTrigger

func _ready() -> void:
	if not item_to_give:
		for item in get_children():
			if item is CollectableItem:
				item_to_give = item
				break
	if item_to_give:
		item_to_give.hide()
		item_to_give.monitoring = false
	_refresh_state()
	trigger.commands_requested.connect(_on_commands_requested)
	InventoryManager.item_collected.connect(_on_item_collected)

func _refresh_state() -> void:
	trigger.host_state["has_needed_item"] = InventoryManager.has_item(item_type, item_value)

func _on_item_collected(_item: InventoryManager.InventoryItem, _node: CollectableItem) -> void:
	_refresh_state()

func _on_commands_requested(commands: Dictionary) -> void:
	_refresh_state()  # Ensure host_state is current before dialogue starts
	commands["give_reward"] = func(_args): _give_reward()

func _give_reward() -> void:
	if item_to_give:
		item_to_give.show()
		item_to_give.trigger_collection()
	if remove_from_inventory:
		InventoryManager.remove_item(item_type, item_value)
		_refresh_state()  # Keep state consistent after inventory change
