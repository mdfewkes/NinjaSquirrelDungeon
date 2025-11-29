extends Node2D

@export var attachement: CharacterBody2D
@export var responsiveness: float = 0.3
@export var display_padding: float = 50
@export var tail_start_offset: Vector2 = Vector2()
@export var tail_motion_strength: float = 150.

# Direction index values
enum Direction {
	LEFT = 0,
	RIGHT = 1,
	UP = 2,
	DOWN = 3,
}

# Converts the given direction into a pose index for the tail
const direction_to_index_lut = [
	# x = -1 (LEFT) 0 (NEUTRAL X) 1 (RIGHT)
	[Direction.DOWN, Direction.UP, Direction.DOWN],
	[Direction.RIGHT, Direction.RIGHT, Direction.RIGHT],
	[Direction.LEFT, Direction.LEFT, Direction.LEFT],
]

"""
The relative position of each tail segment at the given direction index values.
The first position is relative to the global position of the @attachement member plus the offset defined by @tail_start_offset
All other positions are relative to the previous segment.
"""
var tail_poses = [
	# LEFT
	[{ "position": Vector2(0.0, 0.0), "size": 6.0 }, { "position": Vector2(30.0, -35.0), "size": 6.0 }, { "position": Vector2(10.0, -15.0), "size": 15.0 }, { "position": Vector2(-5., -20.), "size": 25.0 }, { "position": Vector2(12.0, -20.0), "size": 25.0 }, { "position": Vector2(17.0, -5.), "size": 25.0 }, { "position": Vector2(15.0, 9.0), "size": 20.0 }, { "position": Vector2(2.0, 23.0), "size": 2.0 }],
	# RIGHT
	[{ "position": Vector2(0.0, 0.0), "size": 6.0 }, { "position": Vector2(-30.0, -35.0), "size": 6.0 }, { "position": Vector2(-3.0, -15.0), "size": 15.0 }, { "position": Vector2(-5., -20.), "size": 25.0 }, { "position": Vector2(-10, -20.0), "size": 25.0 }, { "position": Vector2(-20.0, -5.), "size": 25.0 }, { "position": Vector2(-10.0, 7.0), "size": 20.0 }, { "position": Vector2(-3.0, 25.0), "size": 2.0 }],
	# UP
	[{"position": Vector2(-0.0, 10.0), "size": 6.}, {"position": Vector2(3.0, -11.0), "size": 6.},{"position": Vector2(10.0, -12.0), "size": 15.},{"position": Vector2(14.0, -13.0), "size": 25},{"position": Vector2(-2.0, -18.0), "size": 25.},{"position": Vector2(-23.0, -10.0), "size": 25.0},{"position": Vector2(-9.0, 8.0), "size": 20.0},{"position": Vector2(-4.0, 24.0), "size": 2.},],
	# DOWN
	[{ "position": Vector2(0.0, 0.0), "size": 6.0 }, { "position": Vector2(-10, -20.0), "size": 6.0 }, { "position": Vector2(-10.0, -15.0), "size": 15.0 }, { "position": Vector2(-10.0, -25.0), "size": 25.0 }, { "position": Vector2(-10.0, -15.0), "size": 25.0 }, { "position": Vector2(-10.0, -20.0), "size": 25.0 }, { "position": Vector2(-10.0, -20.0), "size": 20.0 }, { "position": Vector2(-10.0, -35.0), "size": 2.0 }],
]

var tail_shape = []
var selected_pose = Direction.UP
var direction: Vector2 = Vector2(0., -1.)

func _ready() -> void:
	for segment in tail_poses[selected_pose]:
		var shape = CollisionShape2D.new()
		shape.position = segment.position
		shape.shape = CircleShape2D.new()
		shape.shape.radius = segment.size
		tail_shape.push_back(shape)
		add_child(shape)

@export var editing = false
@export var print_pose = false
func _process(_delta: float) -> void:
	
	"""
	To refine tail pose: start game, and set the @editing flag to true in the editor. Modify the positions and sizes of the tail segments.
	To print the results, set the @print_pose flag to true. The tail will be updated, and the pose value to set in @tail_poses 
	will be printed to the console.
	"""
	if print_pose:
		var previous_position = attachement.get_global_position() + tail_start_offset
		var output = "["
		for i in range(tail_poses[selected_pose].size()):
			tail_poses[selected_pose][i].position = tail_shape[i].position
			output += "{\"position\": Vector2%s, \"size\": %s }" % [(tail_shape[i].position - previous_position).round(), tail_shape[i].shape.radius]
			previous_position = tail_shape[i].position
		output += "]"
		print(output)
		print_pose = false

	# Set each tail segment to strive for the active pose
	var target_position = attachement.get_global_position() + tail_start_offset
	var shader_data: PackedVector3Array = []
	var min_pos = Vector2(10000, 10000)
	var max_pos = Vector2(-10000, -10000)
	for i in range(tail_poses[selected_pose].size()):
		var ideal_position = target_position + tail_poses[selected_pose][i].position
		var result_position = lerp(ideal_position, tail_shape[i].get_global_position(), responsiveness)
		var distance_modifier = (target_position - ideal_position).length() / (target_position - result_position).length()
		if not editing:
			tail_shape[i].set_global_position(result_position)
			tail_shape[i].shape.radius = tail_poses[selected_pose][i].size * clamp(distance_modifier, 0.7, 1.3)
		min_pos.x = min(min_pos.x, result_position.x - tail_shape[i].shape.radius - display_padding)
		min_pos.y = min(min_pos.y, result_position.y - tail_shape[i].shape.radius - display_padding)
		max_pos.x = max(max_pos.x, result_position.x + tail_shape[i].shape.radius + display_padding)
		max_pos.y = max(max_pos.y, result_position.y + tail_shape[i].shape.radius + display_padding)
		target_position = result_position

	# Collect display data for the tail
	for tail_segment in tail_shape:
		var normalizer = max_pos - min_pos
		var normalized_position = (tail_segment.get_global_position() - min_pos) / normalizer
		shader_data.append(Vector3(normalized_position.x, normalized_position.y, tail_segment.shape.radius / normalizer.x))
	
	# Set display data for the tail segments
	$display.set_global_position(min_pos)
	$display.set_size(max_pos - min_pos)
	$display.material.set_shader_parameter("point_count", tail_poses[selected_pose].size())
	$display.material.set_shader_parameter("points", shader_data)

func _on_player_direction_changed(new_direction: Variant) -> void:
	selected_pose = direction_to_index_lut[round(new_direction.x)][round(new_direction.y)]
	direction = Vector2(new_direction.x, -new_direction.y)
	match selected_pose:
		Direction.UP:
			z_index = 11
		Direction.LEFT, Direction.RIGHT, Direction.DOWN:
			z_index = 9


func _on_player_shuriken_throw() -> void:
	var segment_throwing_shuriken = 4
	for i in range(1, segment_throwing_shuriken):
		var wave_strength = tail_motion_strength * (1. - i/segment_throwing_shuriken)
		create_tween().tween_property(tail_shape[i], "position", tail_shape[i].get_position() + direction * wave_strength, 0.1)
