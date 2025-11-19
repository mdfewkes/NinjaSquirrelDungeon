class_name HitBox extends Area2D

@export var signal_disabled: bool = false
@export var damage = 1

signal hit(hurtbox: HurtBox)

func  _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if signal_disabled: return
	if not area is HurtBox: return
	var hurt_box = area as HurtBox
	
	hit.emit(hurt_box)
