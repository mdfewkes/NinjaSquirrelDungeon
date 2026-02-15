extends StaticBody2D

@onready var fire_efx: Node2D = $FireEFX
@onready var trigger: Area2D = $ActivationTrigger

@export var activated := false
@export var sfx_activate: AudioSFX
@export var sfx_loop: AudioSFX

var sfx_playback_loop: AudioStreamPlayer2D

func _ready() -> void:
	fire_efx.hide()
	trigger.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not activated and body is Player:
		activate(body)
		body.heal()


func activate(player: Player) -> void:
	fire_efx.show()
	activated = true
	AudioManager.PlaySFX(sfx_activate, self)
	sfx_playback_loop = AudioManager.PlaySFX(sfx_loop, self)
	StateManager.set_key("respawn_point", player.global_position)
