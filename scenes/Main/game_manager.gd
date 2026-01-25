extends Node
class_name GameManager

static var _instance: GameManager

@export var current_scene: Node

var max_hp: int
var current_hp: int
var respawn_point: Vector2

func _ready() -> void:
	if _instance == null:
		_instance = self
	if not current_scene:
		current_scene = get_child(0)
	_reset_persistant_state()


static func change_scene(scene_path: String, keep_state = false) -> void:
	if _instance:
		_instance._change_scene.call_deferred(scene_path, keep_state)

func _change_scene(scene_path: String, keep_state = false) -> void:
	if scene_path == current_scene.get_scene_file_path(): return
	if scene_path == "reload":
		scene_path = current_scene.get_scene_file_path()
	print("changing to", scene_path)
	print("keep state:", keep_state)
	
	var new_scene = load(scene_path).instantiate()

	remove_child(current_scene)
	current_scene.queue_free()

	add_child(new_scene)
	current_scene = new_scene

	if not keep_state:
		_reset_persistant_state()
	else:
		# Assumption: when entering a new area, we want that to act
		# like a barrel checkpoint, so we fall back to the level's start point
		respawn_point = Vector2.INF


static func restore_persistant_state(player: Player) -> void:
	if _instance:
		print("restoring persistent player state")
		player.max_hp = _instance.max_hp
		player.current_hp = _instance.current_hp
		if _instance.respawn_point != Vector2.INF:
			player.global_position = _instance.respawn_point
		player.update_health.connect(_instance._on_health_change)
		player.tail.instant_tail_update = true

func _on_health_change(_current_hp: int, _max_hp: int):
	current_hp = _current_hp
	max_hp = _max_hp

func _reset_persistant_state() -> void:
	print("resetting persistent state")
	max_hp = 4
	current_hp = max_hp
	respawn_point = Vector2.INF
	InventoryManager.reset()


static func set_respawn_point(global_pos: Vector2) -> void:
	if _instance:
		print("updating respawn:", global_pos)
		_instance.respawn_point = global_pos


static func has_respawn_point() -> bool:
	return _instance and _instance.respawn_point != Vector2.INF


static func clear_respawn_point() -> void:
	if _instance:
		print("clearing respawn")
		_instance.respawn_point = Vector2.INF


static func restart_after_death() -> void:
	if _instance:
		_instance.current_hp = _instance.max_hp
		_instance._change_scene("reload", true)
