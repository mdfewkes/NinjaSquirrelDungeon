@tool
extends Control
class_name InfoPlaque
## InfoPlaque - An in-scene documentation panel for the Dialogue Museum.
##
## Displays formatted text explaining what a nearby NPC demonstrates.
## Uses RichTextLabel to support BBCode formatting for syntax highlighting.
##
## Usage:
##   1. Instance this scene near an NPC
##   2. Set the title and content in the inspector
##   3. Use BBCode in content for formatting: [b]bold[/b], [code]code[/code], etc.

@export var title: String = "Info":
	set(value):
		title = value
		_update_content()

@export_multiline var content: String = "":
	set(value):
		content = value
		_update_content()

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/ContentLabel


func _ready() -> void:
	_update_content()


func _update_content() -> void:
	# Use get_node_or_null because @onready vars aren't initialized in @tool mode
	var title_lbl = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/TitleLabel")
	var content_lbl = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ContentLabel")

	if title_lbl:
		title_lbl.text = title
	if content_lbl:
		content_lbl.text = content
