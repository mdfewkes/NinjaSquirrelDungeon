@tool
extends Area2D
class_name DialogueTrigger
## Triggers dialogue when the player enters and presses the interact key.
##
## Add this as a child of any object that should be talkable. Configure the
## dialogue_file to point to a .bobbin dialogue script.
##
## Requires the DialogueBox autoload to be configured in Project Settings.

signal interaction_started
signal interaction_finished

@export_group("Dialogue")
## Path to the .bobbin dialogue file to play when interacted with.
@export_file("*.bobbin") var dialogue_file: String = ""
## Variables to pass into the dialogue script. Keys become variable names
## accessible via the "extern" keyword in your .bobbin file.
## Example: {"player_health": 3} lets dialogue use {player_health}.
@export var host_state: Dictionary = {}

@export_group("Prompt")
@export var prompt_text: String = "Press E":
	set(value):
		prompt_text = value
		_update_prompt()

@onready var prompt_container: PanelContainer = $PromptContainer
@onready var prompt_label: Label = $PromptContainer/PromptLabel

# Private state (underscore prefix = internal use only)
var _player_in_range: bool = false
var _is_interacting: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Hide prompt initially
	if prompt_container:
		prompt_container.hide()
	if prompt_label:
		prompt_label.text = prompt_text

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Connect to DialogueBox autoload to know when dialogue ends
	if DialogueBox:
		DialogueBox.dialogue_finished.connect(_on_dialogue_finished)
	else:
		push_error("DialogueTrigger: DialogueBox autoload not found. Add it in Project Settings > Autoload.")


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	# Disconnect signal to prevent errors if this node is freed while DialogueBox persists
	if DialogueBox and DialogueBox.dialogue_finished.is_connected(_on_dialogue_finished):
		DialogueBox.dialogue_finished.disconnect(_on_dialogue_finished)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if dialogue_file.is_empty():
		warnings.append("No dialogue file set. Set 'Dialogue File' in the inspector.")

	var has_collision_shape = false
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			has_collision_shape = true
			break

	if not has_collision_shape:
		warnings.append("No CollisionShape2D or CollisionPolygon2D child found. Add one to define the interaction area.")

	return warnings


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not _player_in_range or _is_interacting:
		return

	if event.is_action_pressed("interact"):
		_start_interaction()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player"):
		_player_in_range = true
		_show_prompt()


func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player"):
		_player_in_range = false
		_hide_prompt()


func _start_interaction() -> void:
	if dialogue_file.is_empty():
		push_warning("DialogueTrigger: No dialogue file set")
		return

	if not DialogueBox:
		push_error("DialogueTrigger: DialogueBox autoload not found")
		return

	_is_interacting = true
	_hide_prompt()

	interaction_started.emit()

	DialogueBox.show_dialogue(dialogue_file, host_state)


func _on_dialogue_finished(_path: String) -> void:
	if not _is_interacting:
		return

	_is_interacting = false

	if _player_in_range:
		_show_prompt()

	interaction_finished.emit()


func _show_prompt() -> void:
	if prompt_label:
		prompt_label.text = prompt_text
	if prompt_container:
		prompt_container.show()


func _hide_prompt() -> void:
	if prompt_container:
		prompt_container.hide()


func _update_prompt() -> void:
	# Use get_node_or_null because @onready vars aren't initialized in @tool mode
	var label = get_node_or_null("PromptContainer/PromptLabel")
	if label:
		label.text = prompt_text
