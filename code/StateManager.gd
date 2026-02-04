extends Node

# player
	# field1 => val1
	# field2 => val2
# res://scenes/abc.tscn
	# $Path/$To/$Node
		# field1 => val1
		# field2 => val2

var state := {}


func reset() -> void:
	state = {}


func manage_node(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	if key in data:
		node.restore_persisted_state(data[key])
	else:
		data[key] = node.get_persisted_state()
	node.connect("persisted_state_changed", _on_state_update.bind(key, parent_key))
	#print("managing: ", [key, parent_key, data[key]])


func manage_scene(scene_path: String) -> void:
	#print("managing scene: ", scene_path)
	for node in get_tree().get_nodes_in_group("persisted"):
		manage_node(node, node.get_path(), scene_path)


func has_key(key: String, parent_key = "") -> bool:
	var data = _get_dict(parent_key)
	return key in data

func get_key(key: String, parent_key = "") -> Variant:
	var data = _get_dict(parent_key)
	return data.get(key)

func set_key(key: String, val: Variant, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data[key] = val
	#if key == "respawn_point":
		#print("set respawn: ", val, ", parent=", parent_key)

func clear_key(key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data.erase(key)
	#if key == "respawn_point":
		#print("clear respawn, parent=", parent_key)


func _get_dict(parent_key: String) -> Dictionary:
	if parent_key == "":
		return state
	if not parent_key in state:
		state[parent_key] = {}
	return state[parent_key]


func _on_state_update(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data[key] = node.get_persisted_state()
	#print("update: ", [key, parent_key, data[key]])
