class_name Level
extends Node2D

@export var lighting_gradient: Gradient

@onready var rooms_parent_node = $Rooms
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var rooms: Array[Room]
var current_room: Room = null
static var light_level = 1

func _ready() -> void:
	call_deferred("_setup")

func _process(_delta: float) -> void:
	var lights = get_tree().get_nodes_in_group("present_lights")
	var lights_lit = 0.0
	for light in lights:
		if light.lit:
			lights_lit += 1.0
	light_level = lights_lit / lights.size()
	
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", lighting_gradient.sample(light_level), 0.5)
	#canvas_modulate.color = lighting_gradient.sample(light_level)

func _setup() -> void:
	for child in rooms_parent_node.get_children():
		if child is Room:
			rooms.push_back(child)
	
	var last_saw_player = null
	for room in rooms:
		room.player_entered_room.connect(_on_player_entered_room)
		room.remove_as_current_room()
		if room.has_had_player:
			last_saw_player = room
	_set_current_room(last_saw_player)

func _set_current_room(room: Room) -> void:
	if current_room:
		current_room.remove_as_current_room()
	
	if room:
		room.set_as_current_room()
	
	current_room = room

func _on_player_entered_room(room: Room) -> void:
	_set_current_room(room)
