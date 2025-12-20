@tool
extends EditorPlugin
## Dialogue Tools Plugin - Enables View Source functionality for DialogueBox.
##
## When the game is running (F5), clicking "View Source" in the DialogueBox
## sends a message to this plugin, which opens the .bobbin file in the editor.
##
## Enable this plugin in Project Settings → Plugins to use this feature.
## The DialogueBox will fall back to copying the path to clipboard if the
## plugin is not enabled.


class DialogueDebugger extends EditorDebuggerPlugin:
	## Handles messages from the running game with the "dialogue_tools" prefix.

	func _has_capture(prefix: String) -> bool:
		return prefix == "dialogue_tools"

	func _capture(message: String, data: Array, _session_id: int) -> bool:
		if message == "dialogue_tools:open_file":
			var path: String = data[0] if data.size() > 0 else ""
			if path.is_empty():
				return true

			# Open the file in the editor
			if ResourceLoader.exists(path):
				var resource = load(path)
				if resource:
					EditorInterface.edit_resource(resource)
					EditorInterface.set_main_screen_editor("Script")
					print("[DialogueTools] Opened: ", path)
			else:
				push_warning("[DialogueTools] File not found: ", path)

			return true

		return false


var _debugger: DialogueDebugger = null


func _enter_tree() -> void:
	_debugger = DialogueDebugger.new()
	add_debugger_plugin(_debugger)


func _exit_tree() -> void:
	if _debugger:
		remove_debugger_plugin(_debugger)
		_debugger = null
