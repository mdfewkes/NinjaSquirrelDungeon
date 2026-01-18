class_name BreakableWall
extends HurtBox

@export var tilemap_layer : TileMapLayer
@export var damage_threshold := 1.0

#@onready var collision_shape := $CollisionShape2D

func _ready() -> void:
	super._ready()
	hurt.connect(_on_hurt)

func _get_cs() -> CollisionShape2D:
	# TODO: make this smarter
	return get_child(0)

func _on_hurt(hit_box: HitBox) -> void:
	if hit_box.damage >= damage_threshold:
		_destroy_tiles()
		_launch_rocks()
		monitorable = false
		monitoring = false
		_get_cs().disabled = true

func _destroy_tiles() -> void:
	if not tilemap_layer:
		return
	var rect: Rect2 = _get_cs().shape.get_rect()
	var p1_global: Vector2 = _get_cs().to_global(rect.position)
	var p2_global: Vector2 = p1_global + rect.size
	var p1_tile: Vector2 = tilemap_layer.local_to_map(tilemap_layer.to_local(p1_global))
	var p2_tile: Vector2 = tilemap_layer.local_to_map(tilemap_layer.to_local(p2_global))
	for x in range(p1_tile.x, p2_tile.x + 1):
		for y in range(p1_tile.y, p2_tile.y + 1):
			tilemap_layer.set_cell(Vector2i(x, y), -1)

func _launch_rocks() -> void:
	pass
