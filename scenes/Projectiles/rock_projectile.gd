class_name RockProjectile
extends RigidBody2D

const MIN_SPEED = 500.0

@export var damage_to_destroy := 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var physics_shape: CollisionShape2D = $PhysicsCollisionShape
@onready var hit_box: HitBox = $HitBox
@onready var fall_detector: FallDetector = $FallDetector
@onready var hurt_box: HurtBox = $HurtBox

const death_scene = preload("res://scenes/Effects/death_particles.tscn")

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	sprite.rotation = randf_range(0, 2 * PI)
	sprite.modulate = Color.WHITE.darkened(randf_range(0.0, 0.3))

func _process(_delta: float) -> void:
	if linear_velocity.length() < MIN_SPEED and not hit_box.signal_disabled:
		hit_box.monitorable = false
		hit_box.monitoring = false
		hit_box.signal_disabled = true
		fall_detector.refresh_active_pits()

func _on_hurt(other_hit_box: HitBox) -> void:
	if other_hit_box.damage >= damage_to_destroy:
		var particles: CPUParticles2D = death_scene.instantiate()
		add_sibling(particles)
		particles.global_position = global_position
		particles.emitting = true
		queue_free.call_deferred()

func can_fall(_pit) -> bool:
	return linear_velocity.length() < MIN_SPEED

func set_size(scale_factor: float) -> void:
	var scale_vector := Vector2.ONE * scale_factor
	sprite.scale = scale_vector
	physics_shape.scale = scale_vector
	hit_box.scale = scale_vector
	fall_detector.scale = scale_vector

func set_tint(color: Color) -> void:
	modulate = color.lightened(randf_range(0.0, 0.5))
	modulate.s -= randf_range(0, 0.2)
