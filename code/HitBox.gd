class_name HitBox extends Area2D

@export var signal_disabled: bool = false
@export var damage = 1
@export var knockback = 500
@export var affect_lanterns: bool = true

signal hit(hurtbox: HurtBox)

## Primarily used for the player's sword. But could also be used for anything that might
## cause a projectile to ricochet or otherwise have a directional affect (maybe knockback too?)
@export var reflection_direction: Vector2 = Vector2.ZERO


func  _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area):
	if signal_disabled: return
	if not area is HurtBox: return
	var hurt_box = area as HurtBox
	
	call_deferred("_emit_hit", hurt_box)


func _emit_hit(hurt_box: HurtBox) -> void:
	hit.emit(hurt_box)
