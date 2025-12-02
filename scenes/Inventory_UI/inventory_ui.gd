class_name InventoryUI
extends Control

@onready var template_container := $TemplateContainer

var nodes_by_item_id: Dictionary[int, Node] = {}


func _ready():
	template_container.hide()
	template_container.get_child(0).queue_free()
	InventoryManager.item_added.connect(_on_item_added)
	InventoryManager.item_removed.connect(_on_item_removed)


func _on_item_added(item: InventoryManager.InventoryItem, n: CollectableItem):
	var copy_node = n.duplicate()
	copy_node.bounce_amount = 0
	copy_node.position = Vector2(16, 16)
	copy_node.scale = Vector2(0.5, 0.5)

	var copy_container = template_container.duplicate()
	copy_container.add_child(copy_node)
	copy_container.show()

	call_deferred("add_child", copy_container)
	nodes_by_item_id[item.item_id] = copy_container


func _on_item_removed(item: InventoryManager.InventoryItem):
	if item.item_id in nodes_by_item_id:
		nodes_by_item_id[item.item_id].queue_free()
		call_deferred("_forget_item_id", item.item_id)


func _forget_item_id(item_id: int):
	nodes_by_item_id.erase(item_id)
