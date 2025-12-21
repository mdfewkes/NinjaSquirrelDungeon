class_name Room
extends Area2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var lights_parent_node = $Lights
@onready var enemies_parent_node = $Enemies
@onready var environment_parent_node = $Environment


var lights: Array
var has_had_player = false

signal player_entered_room(room)

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	
	lights = lights_parent_node.get_children()

func set_as_current_room() -> void:
	for light in lights:
		light.point_light_2d.enabled = light.lit
		light.add_to_group("present_lights")
	
	var camera = get_viewport().get_camera_2d()
	var shape = collision_shape_2d.shape.get_rect()
	camera.limit_top = collision_shape_2d.global_position.y - shape.size.y/2
	camera.limit_bottom = collision_shape_2d.global_position.y + shape.size.y/2
	camera.limit_left = collision_shape_2d.global_position.x - shape.size.x/2
	camera.limit_right = collision_shape_2d.global_position.x + shape.size.x/2
	
	enemies_parent_node.process_mode = Node.PROCESS_MODE_INHERIT
	enemies_parent_node.visible = true
	environment_parent_node.process_mode = Node.PROCESS_MODE_INHERIT

func remove_as_current_room() -> void:
	for light in lights:
		light.point_light_2d.enabled = false
		light.remove_from_group("present_lights")
	
	enemies_parent_node.process_mode = Node.PROCESS_MODE_DISABLED
	enemies_parent_node.visible = false
	environment_parent_node.process_mode = Node.PROCESS_MODE_DISABLED

func _on_body_entered(body: Node2D):
	if body is Player:
		has_had_player = true
		player_entered_room.emit(self)
