class_name HitBox extends Area2D

@export var damage = 1

signal hit(hurtbox: HurtBox)

func  _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area):
	if area is HurtBox: hit.emit(area)
