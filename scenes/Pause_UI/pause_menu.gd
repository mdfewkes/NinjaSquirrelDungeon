extends Control

@onready var menu_panel: Control = $"."
@onready var resume_btn: Button = %Resume

func _ready() -> void:
	get_tree().paused = false
	menu_panel.hide()
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$AnimationPlayer.play("RESET")


func set_paused(paused: bool) -> void:
	get_tree().paused = paused

	if paused:
		# Enable menu visually + input
		menu_panel.show()
		menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		$AnimationPlayer.play("blur")
		resume_btn.grab_focus()
	else:
		# Disable menu visually + input
		menu_panel.hide()
		menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$AnimationPlayer.play_backwards("blur")


func pause() -> void:
	set_paused(true)


func resume() -> void:
	set_paused(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(!get_tree().paused)
		get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	resume()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_restart_pressed() -> void:
	set_paused(false)
	get_tree().reload_current_scene()
