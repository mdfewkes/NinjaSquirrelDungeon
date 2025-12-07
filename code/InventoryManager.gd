extends Node
signal item_added(item: InventoryItem, node: CollectableItem)
signal item_removed(item: InventoryItem)
signal item_collected(item: InventoryItem, node: CollectableItem)

enum ItemType {
	## Item is needed to open certain doors or switches. Item Value controls which doors will accept the key.
	key,
	## Placeholder for future health item. Item Value could reflect how much health you get.
	health,
	## Placeholder for items don't have specific logic or effects attached but might trigger other story elements. Item Value would identify the item to NPCs etc.
	story,
}

class InventoryItem:
	var item_id: int
	var type: ItemType
	var value: int

var next_item_id := 1
var items: Array[InventoryItem] = []


func _make_item(node: CollectableItem) -> InventoryItem:
	var item = InventoryItem.new()
	item.type = node.item_type
	item.value = node.item_value
	item.item_id = next_item_id
	next_item_id += 1
	return item
	
	
func add_item(node: CollectableItem):
	var item = _make_item(node)
	items.append(item)
	emit_signal('item_added', item, node)


func remove_item(item_type: ItemType, item_value: int) -> bool:
	var idx = _get_first_index(item_type, item_value)
	if idx > -1:
		emit_signal('item_removed', items[idx])
		items.remove_at(idx)
		return true
	return false


func emit_item_collected(node: CollectableItem) -> void:
	var item = _make_item(node)
	emit_signal("item_collected", item, node)


func get_items() -> Array[InventoryItem]:
	return items.duplicate()


func has_item(item_type: ItemType, item_value: int) -> bool:
	return _get_first_index(item_type, item_value) > -1


func reset() -> void:
	for item in items:
		emit_signal('item_removed', item)
	items = []


func _get_first_index(item_type: ItemType, item_value: int) -> int:
	for i in range(len(items)):
		if items[i].type == item_type and items[i].value == item_value:
			return i
	return -1


func _get_index(item_id: int) -> int:
	for i in range(len(items)):
		if items[i].item_id == item_id:
			return i
	return -1
