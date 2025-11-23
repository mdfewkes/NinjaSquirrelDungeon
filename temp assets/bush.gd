extends StaticBody2D

@export var destroy_effect:PackedScene

@onready var hurt_box: HurtBox = $HurtBox

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _on_hurt(hit_box: HitBox):
	if hit_box.damage <= 0: return
	
	if destroy_effect != null:
		var destroy_effect_inastance = destroy_effect.instantiate()
		get_tree().current_scene.add_child(destroy_effect_inastance)
		destroy_effect_inastance.global_position = global_position
	queue_free()
