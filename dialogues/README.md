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

1. Create a `.bobbin` file in an appropriate folder
2. Add a `DialogueTrigger` node to your scene
3. Set the `dialogue_file` property to your `.bobbin` path
4. (Optional) Pass `host_state` for extern variables

See `scenes/DialogueTrigger/` for the trigger component and `scenes/DialogueBox/` for the UI.

## Testing Dialogues

The Dialogue Museum (`scenes/DialogueMuseum/dialogue_museum.tscn`) is your testing ground. Run it with F6 to:
- See all Bobbin features demonstrated
- Test your own dialogues by temporarily swapping file paths
- Learn patterns from working examples
