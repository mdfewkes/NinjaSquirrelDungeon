# Dialogue Tools

Developer tools for the Bobbin dialogue system.

## Features

### View Source Button

When playing from the editor, a **View Source** button appears in the DialogueBox. Clicking it opens the current `.bobbin` file directly in the Script editor.

## Installation

1. Go to **Project → Project Settings → Plugins**
2. Find **Dialogue Tools** and check **Enable**

That's it! The button will now show "Opened!" when clicked, and the file opens in the editor.

## How It Works

This plugin uses Godot's `EditorDebuggerPlugin` system to communicate between the running game and the editor:

1. When you click "View Source", the game sends a message via `EngineDebugger.send_message()`
2. The editor plugin receives this message and calls `EditorInterface.edit_resource()`
3. The `.bobbin` file opens in the Script tab

## Fallback Behavior

- **Plugin enabled**: Button shows "Opened!", file opens in editor
- **Plugin disabled**: Button shows "Copied!", path copied to clipboard
- **Exported build**: Button is hidden entirely

## Files

- `plugin.cfg` - Plugin metadata
- `plugin.gd` - EditorDebuggerPlugin implementation
