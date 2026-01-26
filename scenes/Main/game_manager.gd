extends Node
class_name GameManager

static var _instance: GameManager

@export var current_scene: Node

func _ready() -> void:
	if _instance == null:
		_instance = self
	if not current_scene:
		current_scene = get_child(0)


static func change_scene(scene_path: String, keep_state = false, fade = true) -> void:
	if _instance:
		_instance._change_scene.call_deferred(scene_path, keep_state, fade)

func _change_scene(scene_path: String, keep_state = false, fade = true) -> void:
	if scene_path == current_scene.get_scene_file_path(): return
	if scene_path == "reload":
		scene_path = current_scene.get_scene_file_path()
	print("changing to ", scene_path, " keep state=", keep_state)
		
	var new_scene = load(scene_path).instantiate()

	if fade:
		await fade_out().finished
	remove_child(current_scene)
	current_scene.queue_free()

	add_child(new_scene)
	current_scene = new_scene

	if not keep_state:
		StateManager.reset()
		InventoryManager.reset()
	else:
		StateManager.clear_key("respawn_point")
	StateManager.set_key("current_scene", scene_path)
	StateManager.manage_scene(scene_path)

	if fade:
		await fade_in().finished


static func fade_out(time = 0.5):
	if _instance:
		var world_env: WorldEnvironment = _instance.get_tree().get_first_node_in_group("world_environment")
		if world_env:
			var tween = _instance.create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(world_env.environment, "glow_bloom", 1.0, time / 2)
			tween.tween_property(world_env.environment, "adjustment_brightness", 0.0, time)
			tween.tween_property(world_env.environment, "adjustment_contrast", 2.0, time)
			return tween


static func fade_in(time = 0.5):
	if _instance:
		var world_env: WorldEnvironment = _instance.get_tree().get_first_node_in_group("world_environment")
		if world_env:
			var tween = _instance.create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_property(world_env.environment, "glow_bloom", 0.0, time)
			tween.tween_property(world_env.environment, "adjustment_brightness", 1.0, time)
			tween.tween_property(world_env.environment, "adjustment_contrast", 1.0, time)
			return tween
	

static func restore_persistant_state(player: Player) -> void:
	if _instance:
		StateManager.manage_node(player, "player")
		if StateManager.has_key("respawn_point"):
			player.global_position = StateManager.get_key("respawn_point")
		player.tail.instant_tail_update = true


static func restart_after_death() -> void:
	if _instance:
		var hp = StateManager.get_key("max_hp", "player")
		StateManager.set_key("current_hp", hp, "player")
		_instance._change_scene("reload", true)
