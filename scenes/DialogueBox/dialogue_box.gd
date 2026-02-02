extends CanvasLayer
## DialogueBox - Modal dialogue UI overlay.
##
## This is an AUTOLOAD singleton that displays dialogue text and choices.
## It pauses the game while dialogue is active.
##
## Usage:
##   DialogueBox.show_dialogue("res://dialogues/example.bobbin")
##
## For async usage (waits for dialogue to complete):
##   await DialogueBox.show_dialogue_async("res://dialogues/example.bobbin")
##
## Requires the Bobbin dialogue addon (see addons/bobbin/).

signal dialogue_started(path: String)
signal dialogue_finished(path: String)

@onready var background: ColorRect = $Background
@onready var panel: PanelContainer = $Panel
@onready var text_label: RichTextLabel = $Panel/VBox/TextLabel
@onready var choices_container: VBoxContainer = $Panel/VBox/ChoicesContainer
@onready var prompt_label: Label = $PromptLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var view_source_button: Button = $ViewSourceButton

# Private state (underscore prefix = internal use only)
var _runtime: BobbinRuntime = null
var _current_path: String = ""
var _input_cooldown: float = 0.0
var _awaiting_completion: bool = false

const INPUT_COOLDOWN_TIME: float = 0.1
const CONTINUE_PROMPT: String = "Press X to continue"
const CHOICE_BUTTON_FONT_SIZE: int = 30
const VIEW_SOURCE_NOTIFICATION_TIME: float = 2.0

# Persistent storage for dialogue "save" variables (keyed by dialogue path).
# Survives across conversations but not game restarts. Call clear_saved_state()
# when starting a new game if you need to reset dialogue memory.
var _variable_storage: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hide_ui()
	_setup_view_source_button()


func _setup_view_source_button() -> void:
	# Only show View Source button when running from editor (not in exported builds)
	if not OS.has_feature("editor"):
		view_source_button.hide()
		return

	view_source_button.pressed.connect(_on_view_source_pressed)


func _on_view_source_pressed() -> void:
	if _current_path.is_empty():
		return

	var opened_in_editor := false

	# Try to open in editor via debugger plugin (if plugin is enabled)
	if EngineDebugger.is_active():
		EngineDebugger.send_message("dialogue_tools:open_file", [_current_path])
		opened_in_editor = true

	# Always copy to clipboard as fallback
	DisplayServer.clipboard_set(_current_path)

	# Show notification
	var original_text = view_source_button.text
	if opened_in_editor:
		view_source_button.text = "Opened!"
	else:
		view_source_button.text = "Copied!"
	view_source_button.disabled = true

	# Restore after delay
	await get_tree().create_timer(VIEW_SOURCE_NOTIFICATION_TIME).timeout
	view_source_button.text = original_text
	view_source_button.disabled = false


func _process(delta: float) -> void:
	if _input_cooldown > 0:
		_input_cooldown -= delta


func _unhandled_input(event: InputEvent) -> void:
	if _runtime == null:
		return

	if _input_cooldown > 0:
		return

	if _runtime.is_waiting_for_choice():
		# Navigate choices with W/S or arrow keys
		if event.is_action_pressed("move_up"):
			_navigate_choices(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_navigate_choices(1)
			get_viewport().set_input_as_handled()
		# Select choice with action key
		elif event.is_action_pressed("action_1"):
			_select_focused_choice()
			get_viewport().set_input_as_handled()
	else:
		# Advance dialogue with action key
		if event.is_action_pressed("action_1"):
			_advance()
			get_viewport().set_input_as_handled()


func show_dialogue(path: String, host_state: Dictionary = {}, commands: Dictionary = {}) -> void:
	if _runtime != null:
		push_warning("DialogueBox: Already showing dialogue, ignoring new request")
		return

	_current_path = path

	# Create Bobbin runtime from dialogue file with saved state, host state, and commands
	var saved_vars: Dictionary = _variable_storage.get(path, {})
	_runtime = Bobbin.create(path, saved_vars, host_state, commands)

	if _runtime == null:
		push_error("DialogueBox: Failed to load dialogue from: " + path)
		return

	# Pause game and show UI
	get_tree().paused = true
	_show_ui()

	dialogue_started.emit(path)

	# Display first line
	_display_current()


func show_dialogue_async(path: String, host_state: Dictionary = {}, commands: Dictionary = {}) -> void:
	_awaiting_completion = true
	show_dialogue(path, host_state, commands)

	# Wait for dialogue to finish
	while _awaiting_completion and _runtime != null:
		await get_tree().process_frame

	_awaiting_completion = false


## Clears all saved dialogue variables. Call this when starting a new game
## to reset any remembered state from previous playthroughs.
func clear_saved_state() -> void:
	_variable_storage.clear()


func get_saved_state() -> Dictionary:
	return _variable_storage.duplicate_deep()

func _advance() -> void:
	if _runtime == null:
		return

	_input_cooldown = INPUT_COOLDOWN_TIME

	# Check if there's more content before advancing
	if not _runtime.has_more():
		_end_dialogue()
		return

	_runtime.advance()
	_display_current()


func _select_choice(index: int) -> void:
	if _runtime == null:
		return

	_input_cooldown = INPUT_COOLDOWN_TIME
	_runtime.select_choice(index)
	_display_current()


func _display_current() -> void:
	if _runtime == null:
		return

	# Display current line
	text_label.text = _runtime.current_line()

	# Clear old choice buttons
	_clear_choices()

	# Show choices or continue prompt
	if _runtime.is_waiting_for_choice():
		prompt_label.hide()
		var choices = _runtime.current_choices()
		for i in range(choices.size()):
			var button = Button.new()
			button.text = choices[i]
			button.add_theme_font_size_override("font_size", CHOICE_BUTTON_FONT_SIZE)
			button.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(button)

			# Focus first button so keyboard/controller can navigate immediately.
			# call_deferred is needed because the button isn't fully in the tree yet.
			if i == 0:
				button.call_deferred("grab_focus")

		# Set up focus neighbors AFTER all buttons exist (deferred for same reason)
		_setup_choice_focus_neighbors.call_deferred()
	else:
		prompt_label.show()
		prompt_label.text = CONTINUE_PROMPT


func _setup_choice_focus_neighbors() -> void:
	var buttons = choices_container.get_children()
	for i in range(buttons.size()):
		var button = buttons[i]
		if i > 0:
			button.focus_neighbor_top = buttons[i - 1].get_path()
			button.focus_previous = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			button.focus_neighbor_bottom = buttons[i + 1].get_path()
			button.focus_next = buttons[i + 1].get_path()


func _on_choice_pressed(index: int) -> void:
	_select_choice(index)


func _navigate_choices(direction: int) -> void:
	var buttons = choices_container.get_children()
	if buttons.is_empty():
		return

	# Find currently focused button
	var focused_index = -1
	for i in range(buttons.size()):
		if buttons[i].has_focus():
			focused_index = i
			break

	# Calculate new index with wrapping
	var new_index = focused_index + direction
	if new_index < 0:
		new_index = buttons.size() - 1
	elif new_index >= buttons.size():
		new_index = 0

	buttons[new_index].grab_focus()


func _select_focused_choice() -> void:
	var buttons = choices_container.get_children()
	for i in range(buttons.size()):
		if buttons[i].has_focus():
			_select_choice(i)
			return

	# Fallback: if nothing focused, select first choice
	if not buttons.is_empty():
		_select_choice(0)


func _end_dialogue() -> void:
	var path = _current_path

	# Save variables before cleaning up runtime
	_save_variables(path)

	# Clean up runtime
	_runtime = null
	_current_path = ""
	_awaiting_completion = false

	# Hide UI and unpause
	_hide_ui()
	get_tree().paused = false

	dialogue_finished.emit(path)


func _restore_variables(path: String) -> void:
	if _runtime == null:
		return
	if not _variable_storage.has(path):
		return
	var saved_vars: Dictionary = _variable_storage[path]
	for var_name in saved_vars:
		_runtime.set_variable(var_name, saved_vars[var_name])


func _save_variables(path: String) -> void:
	if _runtime == null:
		return
	var vars: Dictionary = _runtime.get_all_variables()
	if not vars.is_empty():
		_variable_storage[path] = vars


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()


func _show_ui() -> void:
	show()
	background.show()
	panel.show()
	animation_player.play("blur")


func _hide_ui() -> void:
	animation_player.play("RESET")
	background.hide()
	panel.hide()
	prompt_label.hide()
	hide()

	_clear_choices()
