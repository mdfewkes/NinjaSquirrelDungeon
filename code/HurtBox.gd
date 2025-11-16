class_name HurtBox extends Area2D

signal hurt(hitbox: HitBox)

func  _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area):
	if area is HitBox: hurt.emit(area)
