extends Node2D

@onready var hurt_box: HurtBox = $HurtBox
@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _on_hurt(_hitbox: HitBox) -> void:
	point_light_2d.enabled = false
