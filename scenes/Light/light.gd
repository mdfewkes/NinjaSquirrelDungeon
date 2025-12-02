extends Node2D

@onready var hurt_box: HurtBox = $HurtBox
@onready var point_light_2d: PointLight2D = $PointLight2D

var target_energy = 1.0
var flicker_cooldown = 0

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _process(delta: float) -> void:
	flicker_cooldown -= delta
	point_light_2d.energy = lerp(point_light_2d.energy, target_energy, 0.1)
	if flicker_cooldown <= 0:
		target_energy = 1.25 - randf() * randf() * 0.75
		flicker_cooldown = (1 - randf() * randf()) * 0.25

func _on_hurt(_hitbox: HitBox) -> void:
	point_light_2d.enabled = false
