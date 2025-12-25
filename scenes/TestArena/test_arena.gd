@tool
extends Node2D
## Test arena scene for developing and testing enemies.
## Generates a rectangular arena with walls around the perimeter.
##
## Usage: Open this scene in Godot and run it (F6) to test enemy behaviors.

const TILE_SIZE := 64

@export_range(5, 50) var arena_width := 20:  ## Arena width in tiles
	set(value):
		arena_width = value
		if is_node_ready():
			_generate_arena()
			_update_layout()

@export_range(5, 50) var arena_height := 20:  ## Arena height in tiles
	set(value):
		arena_height = value
		if is_node_ready():
			_generate_arena()
			_update_layout()

# Atlas coordinates for wall tiles (from the Auto_tile_Sewer.png tileset)
# Using a simple filled wall tile - coordinate (1,1) is a good center piece
const WALL_ATLAS_COORD := Vector2i(1, 1)

@onready var wall_layer: TileMapLayer = $GroundLayer/WallTileMapLayer
@onready var background: TextureRect = $GroundLayer/Background
@onready var room: Area2D = $Room
@onready var room_collision: CollisionShape2D = $Room/CollisionShape2D
@onready var player: Node2D = $Player
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D


func _ready() -> void:
	_generate_arena()
	_update_layout()

	# At runtime, set this room as current to lock camera
	if not Engine.is_editor_hint() and room:
		room.set_as_current_room()


func _generate_arena() -> void:
	if wall_layer == null:
		push_warning("WallTileMapLayer not found, cannot generate arena")
		return

	wall_layer.clear()

	# Generate walls around the perimeter
	for x in range(arena_width):
		for y in range(arena_height):
			# Place walls on the edges only
			if x == 0 or x == arena_width - 1 or y == 0 or y == arena_height - 1:
				wall_layer.set_cell(Vector2i(x, y), 0, WALL_ATLAS_COORD)


func _update_layout() -> void:
	var arena_pixel_size := Vector2(arena_width * TILE_SIZE, arena_height * TILE_SIZE)
	var center := arena_pixel_size / 2.0

	# Resize background to match arena
	if background:
		background.size = arena_pixel_size

	# Recenter and resize room collision area
	if room_collision:
		room_collision.position = center
		if room_collision.shape is RectangleShape2D:
			room_collision.shape.size = arena_pixel_size

	# Recenter player
	if player:
		player.position = center

	# Update navigation mesh (walkable area inside walls)
	if nav_region:
		_update_navigation_polygon()


func _update_navigation_polygon() -> void:
	var nav_poly := NavigationPolygon.new()

	# Walkable area is inside the walls (1 tile margin)
	var margin := TILE_SIZE
	var walkable_outline := PackedVector2Array([
		Vector2(margin, margin),
		Vector2(arena_width * TILE_SIZE - margin, margin),
		Vector2(arena_width * TILE_SIZE - margin, arena_height * TILE_SIZE - margin),
		Vector2(margin, arena_height * TILE_SIZE - margin)
	])

	nav_poly.add_outline(walkable_outline)

	# Use newer API to bake the navigation polygon
	var source_geometry := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, nav_region)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)

	nav_region.navigation_polygon = nav_poly


## Call this from the editor to manually regenerate the arena.
func regenerate() -> void:
	_generate_arena()
	_update_layout()
