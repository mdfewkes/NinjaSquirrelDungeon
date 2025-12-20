@tool
extends Control
class_name SyntaxReference
## SyntaxReference - A visual quick-reference card for Bobbin syntax.
##
## Displays formatted syntax examples in categorized sections.
## Uses RichTextLabel for BBCode formatting support.
##
## Place this in the Dialogue Museum as a reference area players can read.

@onready var variables_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VariablesSection/Content
@onready var choices_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ChoicesSection/Content
@onready var display_label: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DisplaySection/Content


func _ready() -> void:
	_populate_content()


func _populate_content() -> void:
	# Use get_node_or_null for @tool compatibility
	var vars_lbl = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VariablesSection/Content")
	var choices_lbl = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ChoicesSection/Content")
	var display_lbl = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/DisplaySection/Content")

	if vars_lbl:
		vars_lbl.text = """[code]save x = 0[/code]
Persistent variable

[code]set x = 1[/code]
Change value

[code]extern x[/code]
From game code"""

	if choices_lbl:
		choices_lbl.text = """[code]- Choice text[/code]
    Response here

[code]- Another[/code]
    [code]- Nested[/code]
        Deep response"""

	if display_lbl:
		display_lbl.text = """[code]{variable}[/code]
Show value in text

[code]You have {gold} gold[/code]
Works with all types"""
