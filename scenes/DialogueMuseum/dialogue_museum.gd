extends Node2D
## DialogueMuseum - Interactive demo scene for testing the dialogue system.
##
## This scene showcases different Bobbin dialogue features:
## - Storyteller: Multi-line dialogue
## - Merchant: Choice branching
## - Memory Keeper: save/set variables
## - Oracle: extern host state (reads player health)
##
## Run this scene directly (F6) to test dialogue without playing the full game.

@onready var player: Player = $Player
@onready var oracle_npc: StaticBody2D = $NPCs/Oracle
@onready var oracle_trigger: DialogueTrigger = $NPCs/Oracle/DialogueTrigger


func _ready() -> void:
	# Auto-trigger intro dialogue on scene load.
	# call_deferred ensures DialogueBox autoload is fully initialized.
	_trigger_intro.call_deferred()

	# Connect Oracle's interaction signal to update host_state dynamically
	oracle_trigger.interaction_started.connect(_on_oracle_interaction)


func _trigger_intro() -> void:
	# DialogueBox is an autoload singleton defined in Project Settings > Autoload
	DialogueBox.show_dialogue("res://dialogues/museum/intro.bobbin")


func _on_oracle_interaction() -> void:
	# Pass current player health to the dialogue so it can display it.
	# The dialogue accesses this via: extern player_health
	var health = player.current_hp if player else 3
	oracle_trigger.host_state = {
		"player_health": health
	}
