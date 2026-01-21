extends Room

var timer: Timer
var has_entered = false

const rock_scene = preload("res://scenes/Projectiles/rock_projectile.tscn")

func _ready() -> void:
	super._ready()
	timer = Timer.new()
	timer.timeout.connect(_on_timer)
	add_child(timer)
	_set_random_time()

func _set_random_time() -> void:
	timer.start(randf_range(1.0, 3.0))

func _on_timer() -> void:
	_set_random_time()
	if Level.current_room == self:
		ImpactEffects.shake(randf_range(0.5, 2.0), randf_range(0.4, 0.8))

func _on_rocks_trigger_body_entered(body: Node2D) -> void:
	if has_entered:
		return
	has_entered = true
	var rocks_point: Marker2D = get_node_or_null("RocksPoint")
	if rocks_point:
		for i in range(3):
			var rock = rock_scene.instantiate()
			var offset = Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0))
			rock.position = rocks_point.position + offset
			rock.damage_to_destroy = 10
			add_child.call_deferred(rock)
