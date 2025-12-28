class_name Light
extends Node2D

@export var lit = true

@onready var hurt_box: HurtBox = $HurtBox
@onready var point_light_2d: PointLight2D = $PointLight2D

var target_energy = 1.0
var flicker_cooldown = 0

func _ready() -> void:
	if lit:
		turn_on_light()
	else:
		turn_off_light()
	
	hurt_box.hurt.connect(_on_hurt)

func _process(delta: float) -> void:
	flicker_cooldown -= delta
	point_light_2d.energy = lerp(point_light_2d.energy, target_energy, 0.1)
	if flicker_cooldown <= 0:
		target_energy = 1.25 - randf() * randf() * 0.8
		flicker_cooldown = (1 - randf() * randf()) * 0.25

func turn_off_light() -> void:
	point_light_2d.enabled = false
	lit = false
	
func turn_on_light() -> void:
	point_light_2d.enabled = true
	lit = true

func _on_hurt(hit_box: HitBox) -> void:
	if hit_box.damage > 0: return
	turn_off_light()
