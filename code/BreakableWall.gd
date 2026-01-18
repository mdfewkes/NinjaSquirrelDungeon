class_name BreakableWall
extends HurtBox

@export var tilemap_layer : TileMapLayer
@export var damage_threshold := 10.0
@export var num_rocks := 10
@export var min_scale := 0.3
@export var max_scale := 1.0
@export var min_speed := 500.0
@export var max_speed := 1000.0
@export var min_degrees := -90.0
@export var max_degrees := 90.0

const rock_scene = preload("res://scenes/Projectiles/rock_projectile.tscn")
const death_particles = preload("res://scenes/Effects/death_particles.tscn")

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
		queue_free.call_deferred()

func _destroy_tiles() -> void:
	if not tilemap_layer:
		return
	var rect: Rect2 = _get_cs().shape.get_rect()
	var p1_global: Vector2 = _get_cs().to_global(rect.position)
	var p2_global: Vector2 = p1_global + rect.size
	
	var particles: CPUParticles2D = death_particles.instantiate()
	add_sibling(particles)
	particles.global_position = _get_cs().to_global(rect.get_center())
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = rect.size / 2
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 5.0
	particles.emitting = true
	
	var p1_tile: Vector2 = tilemap_layer.local_to_map(tilemap_layer.to_local(p1_global))
	var p2_tile: Vector2 = tilemap_layer.local_to_map(tilemap_layer.to_local(p2_global))
	for x in range(p1_tile.x, p2_tile.x + 1):
		for y in range(p1_tile.y, p2_tile.y + 1):
			tilemap_layer.set_cell(Vector2i(x, y), -1)

func _launch_rocks() -> void:
	var rect: Rect2 = _get_cs().shape.get_rect()
	var p1_global: Vector2 = _get_cs().to_global(rect.position)
	var p2_global: Vector2 = p1_global + rect.size
	for i in range(num_rocks):
		var rock: RockProjectile = rock_scene.instantiate()
		var speed := randf_range(min_speed, max_speed)
		var degrees : = randf_range(min_degrees, max_degrees)
		var angle : = degrees * PI / 180.0
		var scale_factor := randf_range(min_scale, max_scale)
		rock.global_position = Vector2(
			randf_range(p1_global.x, p2_global.x),
			randf_range(p1_global.y, p2_global.y)
		)
		rock.linear_velocity = Vector2.from_angle(angle) * speed
		rock.set_size.call_deferred(scale_factor)
		print("launching:", [rock.linear_velocity, degrees, scale_factor])
		add_sibling(rock)
