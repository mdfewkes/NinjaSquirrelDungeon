class_name Level
extends Node2D

@export var level_name: String
@export var lighting_gradient: Gradient
@export var spawn_points: Dictionary[String, Node2D]
@export var default_spawn: Node2D

@onready var rooms_parent_node = $Rooms
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

var rooms: Array[Room]
static var current_room: Room = null
static var last_room: Room = null
static var last_level: String = ""
static var light_level: float = 1

var player

func _ready() -> void:
	call_deferred("_setup")

func _process(_delta: float) -> void:
	var lights = get_tree().get_nodes_in_group("present_lights")
	var lights_lit = 0.0
	for light in lights:
		if light.lit:
			lights_lit += 1.0
	light_level = lights_lit / (lights.size() + 1)
	if current_room:
		light_level *= current_room.light_modifier
	
	var tween := create_tween()
	tween.tween_property(canvas_modulate, "color", lighting_gradient.sample(light_level), 0.5)

func load_level(scene_path_to_level: String) -> void: 
	last_level = level_name
	StateManager.clear_key("respawn_point")
	GameManager.change_scene.call_deferred(scene_path_to_level, true)


func _setup() -> void:
	if not is_inside_tree():
		await tree_entered
	var players := get_tree().get_nodes_in_group("player")
	player = players[0] if players.size() > 0 else null
	if not StateManager.has_key("respawn_point"):
		var spawn_point = default_spawn
		if spawn_points.has(last_level):
			spawn_point = spawn_points[last_level]
		if spawn_point:
			StateManager.set_key("respawn_point", spawn_point.global_position)
		for _player in players:
			if spawn_point != null:
				_player.global_position = spawn_point.global_position
				_player.tail.instant_tail_update = true

	for child in rooms_parent_node.get_children():
		if child is Room:
			rooms.push_back(child)
	
	for room in rooms:
		room.player_entered_room.connect(_on_player_entered_room)
		room.player_exited_room.connect(_on_player_exited_room)
		room.remove_as_current_room()
		
	_set_current_room(_locate_player())


func _locate_player() -> Room:
	var last_saw_player = null
	for room in rooms:
		if player and room.collision_shape_2d.shape.get_rect().has_point(player.global_position):
			last_saw_player = room
	return last_saw_player


func _set_current_room(room: Room) -> void:
	last_room = current_room
	current_room = room
	
	if last_room:
		last_room.remove_as_current_room()
	
	if current_room:
		current_room.set_as_current_room()

func _on_player_entered_room(room: Room) -> void:
	if room != current_room:
		_set_current_room(room)

func _on_player_exited_room(room: Room) -> void:
	if room == current_room:
		_set_current_room(_locate_player())
		print("they've escapped!")
