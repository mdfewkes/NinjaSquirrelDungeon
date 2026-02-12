extends Node2D


@export var bush_particles:PackedScene
@export var sfx_on_break: AudioSFX

@onready var hurt_box: HurtBox = $HurtBox

func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)

func _on_hurt(hit_box: HitBox):
	if hit_box.damage <= 0: return
	
	AudioManager.PlaySFX_at_position(sfx_on_break, global_position)
	
	if bush_particles != null:
		var bush_particles_instance = bush_particles.instantiate()
		bush_particles_instance.position = global_position
		get_tree().current_scene.add_child(bush_particles_instance)
		queue_free()
