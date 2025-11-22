extends Sprite2D

@export var previous: Node2D
@export_range(1., 100.) var ideal_size = 10.
@export_range(1., 50.) var joint_distance = 2.
@export_range(0.001, 1.0) var tail_swiftness = 0.5

func _ready() -> void:
	texture.set_width(ideal_size)
	texture.set_height(ideal_size)

func _process(delta: float) -> void:
	var previous_position = previous.get_global_position()
	var ideal_position = previous_position + (get_global_position() - previous_position).normalized() * joint_distance
	var position_diff_ratio = clamp(joint_distance / (previous_position - get_global_position()).length(), 0.1, 1.5)
	set_global_position(lerp(get_global_position(), ideal_position, tail_swiftness))
	texture.set_width(position_diff_ratio * ideal_size)
	texture.set_height(position_diff_ratio * ideal_size)
