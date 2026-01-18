class_name RockProjectile
extends RigidBody2D

const MIN_SPEED = 500.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var physics_shape: CollisionShape2D = $PhysicsCollisionShape
@onready var hit_box: HitBox = $HitBox
@onready var fall_detector: FallDetector = $FallDetector

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if linear_velocity.length() < MIN_SPEED and not hit_box.signal_disabled:
		hit_box.monitorable = false
		hit_box.monitoring = false
		hit_box.signal_disabled = true
		fall_detector.refresh_active_pits()

func can_fall(_pit) -> bool:
	return linear_velocity.length() < MIN_SPEED

func set_size(scale_factor: float) -> void:
	var scale_vector := Vector2.ONE * scale_factor
	sprite.scale = scale_vector
	physics_shape.scale = scale_vector
	hit_box.scale = scale_vector
	fall_detector.scale = scale_vector
