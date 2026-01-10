class_name ShockWave
extends Node2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func fire(speed = 1.0) -> void:
	anim_player.speed_scale = speed
	anim_player.play("shock")
