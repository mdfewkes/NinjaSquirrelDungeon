class_name HurtBox extends Area2D

@export var signal_disabled: bool = false

signal hurt(hitbox: HitBox)

func  _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area):
	if signal_disabled: return
	if not area is HitBox: return
	var hit_box = area as HitBox
	
	hurt.emit(hit_box)
