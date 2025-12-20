# Dialogues

This folder contains all dialogue scripts for Legend of Shadowtail, written in [Bobbin](../addons/bobbin/README.md) format.

## Folder Structure

```
dialogues/
├── README.md          # This file
└── museum/            # Dialogue Museum demo dialogues (learning examples)
    ├── storyteller.bobbin    # Multi-line dialogue
    ├── merchant.bobbin       # Choice branching with -
    ├── memory_keeper.bobbin  # save/set variables
    ├── oracle.bobbin         # extern host state
    └── syntax_guide.bobbin   # Interactive syntax tutorial
```

## Quick Start

1. **Run the Dialogue Museum** - Open `scenes/DialogueMuseum/dialogue_museum.tscn` and press F6 to see dialogues in action
2. **Read the examples** - Each `.bobbin` file in `museum/` demonstrates a specific feature
3. **Create your own** - Copy a museum example as a starting point

## Bobbin Syntax Reference

### Basic Text
Lines of text are displayed sequentially:
```bobbin
Hello, traveler!
Welcome to my shop.
```

### Choices
Use `-` to create player choices. Indent responses under each choice:
```bobbin
What would you like?
- Buy something
    Here's your item!
- Leave
    Goodbye!
```

### Variables

**save** - Persists across conversations (remembers between talks):
```bobbin
save has_met = false
set has_met = true
```

**temp** - Only exists during this conversation:
```bobbin
temp mood = "happy"
```

**extern** - Provided by the game (read-only):
```bobbin
extern player_health
You have {player_health} HP.
```

### Displaying Variables
Use `{variable_name}` to show a variable's value in text:
```bobbin
save gold = 100
You have {gold} gold coins.
```

## Adding Dialogues to Your Game

### Using DialogueTrigger (player-activated)

Best for NPCs and interactive objects:

1. Create a `.bobbin` file in an appropriate folder
2. Add a `DialogueTrigger` node to your scene
3. Set the `dialogue_file` property to your `.bobbin` path
4. (Optional) Pass `host_state` for extern variables

See `scenes/DialogueTrigger/` for the trigger component.

### Triggering from Code (cutscenes, events)

For story beats, cutscenes, or any programmatic trigger, call `DialogueBox` directly:

```gdscript
# Simple trigger
DialogueBox.show_dialogue("res://dialogues/intro.bobbin")

# With game variables for extern access
DialogueBox.show_dialogue("res://dialogues/boss_defeated.bobbin", {
    "boss_name": "Shadow King",
    "player_level": player.level
})

# Async version - waits for dialogue to complete before continuing
await DialogueBox.show_dialogue_async("res://dialogues/cutscene.bobbin")
print("Dialogue finished, continue with next scene...")
```

Use `show_dialogue_async()` when you need to wait for the dialogue to finish before executing more code (common in cutscenes and scripted sequences).

See `scenes/DialogueBox/` for the UI implementation.

## Testing Dialogues

The Dialogue Museum (`scenes/DialogueMuseum/dialogue_museum.tscn`) is your testing ground. Run it with F6 to:
- See all Bobbin features demonstrated
- Test your own dialogues by temporarily swapping file paths
- Learn patterns from working examples

## Developer Tools

### View Source Button

When running from the editor (F5/F6), a **View Source** button appears in the DialogueBox. Clicking it opens the current `.bobbin` file directly in the editor.

**To enable this feature:**

1. Go to **Project → Project Settings → Plugins**
2. Find **Dialogue Tools** and check **Enable**

Once enabled, clicking "View Source" instantly opens the file. If the plugin isn't enabled, the button still works — it copies the file path to your clipboard so you can open it with Ctrl+P.

> **Note:** The View Source button is automatically hidden in exported builds.
