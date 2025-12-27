class_name DartmunkSpawnButton
extends Area2D

## A floor button that spawns a Dartmunk when the player steps on it.
## Includes a mannequin Dartmunk above the button as a visual indicator.

@export var dartmunk_scene: PackedScene
@export var pressed_color: Color = Color(0.2, 0.8, 0.2)  # Green
@export var normal_color: Color = Color(0.5, 0.5, 0.5)   # Gray
@export var button_radius: float = 64.0

@onready var spawn_point: Marker2D = $SpawnPoint

var _is_pressed: bool = false
var _current_color: Color


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_current_color = normal_color
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, button_radius, _current_color)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_press()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_release()


func _press() -> void:
	if _is_pressed:
		return
	_is_pressed = true
	_current_color = pressed_color
	queue_redraw()
	# Defer spawn to avoid physics query flushing error
	call_deferred("_spawn_dartmunk")


func _release() -> void:
	_is_pressed = false
	_current_color = normal_color
	queue_redraw()


func _spawn_dartmunk() -> void:
	if dartmunk_scene == null:
		return
	var dartmunk = dartmunk_scene.instantiate()

	# Find Enemies node under Room and spawn there
	var enemies_node := _find_enemies_node()
	if enemies_node:
		enemies_node.add_child(dartmunk)
	else:
		get_parent().add_child(dartmunk)  # Fallback

	dartmunk.global_position = spawn_point.global_position

	# Apply tuning values if panel exists
	var tuning_panel := _get_tuning_panel()
	if tuning_panel:
		tuning_panel.apply_to_dartmunk(dartmunk)


func _find_enemies_node() -> Node:
	# Walk up to find a node with Enemies child
	var node := get_parent()
	while node:
		if node.has_node("Enemies"):
			return node.get_node("Enemies")
		node = node.get_parent()
	return null


func _get_tuning_panel() -> DartmunkTuningPanel:
	var nodes := get_tree().get_nodes_in_group("dartmunk_tuning_panel")
	if nodes.size() > 0:
		return nodes[0] as DartmunkTuningPanel
	return null
