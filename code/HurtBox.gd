class_name HurtBox extends Area2D

signal hurt(hitbox: HitBox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not area is HitBox:
		return

	var hitbox := area as HitBox
	if hitbox.signal_disabled:
		return

	# Defer emitting the signal so it happens AFTER physics queries finish
	call_deferred("_emit_hurt", hitbox)


func _emit_hurt(hitbox: HitBox) -> void:
	hurt.emit(hitbox)
