extends StaticBody2D

@onready var fire_efx: Node2D = $FireEFX
@onready var trigger: Area2D = $ActivationTrigger

@export var activated := false

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
	StateManager.set_key("respawn_point", player.global_position)
