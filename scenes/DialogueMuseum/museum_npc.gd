@tool
extends StaticBody2D
## MuseumNPC - A talkable NPC with a name label and description.
##
## This is a reusable NPC template for the Dialogue Museum demo.
## Configure the exported properties in the inspector to set up each NPC.
##
## Properties:
##   npc_name: Displayed above the NPC's head
##   description: Smaller text below the name explaining what this NPC demonstrates
##   dialogue_file: Path to the .bobbin dialogue file
##   host_state: Variables to pass into the dialogue (for "extern" access)

@export var npc_name: String = "NPC":
	set(value):
		npc_name = value
		_update_labels()

@export var description: String = "":
	set(value):
		description = value
		_update_labels()

@export_file("*.bobbin") var dialogue_file: String = ""
@export var host_state: Dictionary = {}

@onready var name_label: Label = $InfoContainer/NameLabel
@onready var description_label: Label = $InfoContainer/DescriptionLabel
@onready var dialogue_trigger: DialogueTrigger = $DialogueTrigger


func _ready() -> void:
	_update_labels()

	if Engine.is_editor_hint():
		return

	# Pass dialogue configuration to the trigger component
	dialogue_trigger.dialogue_file = dialogue_file
	dialogue_trigger.host_state = host_state


func _update_labels() -> void:
	# Use get_node_or_null because @onready vars aren't initialized in @tool mode
	var name_lbl = get_node_or_null("InfoContainer/NameLabel")
	var desc_lbl = get_node_or_null("InfoContainer/DescriptionLabel")
	if name_lbl:
		name_lbl.text = npc_name
	if desc_lbl:
		desc_lbl.text = description
