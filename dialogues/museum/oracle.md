# Oracle - External Host State

## What This Demonstrates

Using `extern` to access variables passed from your game code. This lets dialogue display dynamic game state like player health, inventory counts, or NPC names.

## When to Use This Pattern

- **Displaying game state** - "You have {player_health} HP remaining"
- **Dynamic NPC names** - "Thank you, {player_name}!"
- **Quest-aware dialogue** - Reference current objectives or progress
- **Inventory checks** - "You're carrying {gold} gold coins"

## Gotchas

- **Read-only** - You cannot `set` an extern variable from dialogue. It's provided by the game.
- **Must be passed in** - If the game doesn't pass the variable, you'll see `{undefined}` or an error.
- **Update timing** - Pass host_state when starting dialogue, not before. See the Oracle NPC code for the pattern.

## How It Works

### In Your Dialogue (.bobbin)

```bobbin
extern player_health
extern player_name

Hello, {player_name}!
I sense you have {player_health} health remaining.
```

### In Your Game Code (.gd)

```gdscript
# Using DialogueTrigger
dialogue_trigger.host_state = {
    "player_name": player.name,
    "player_health": player.current_hp
}

# Or calling DialogueBox directly
DialogueBox.show_dialogue("res://dialogues/oracle.bobbin", {
    "player_name": "Shadowtail",
    "player_health": 3
})
```

### Dynamic Updates (Oracle Pattern)

The Oracle NPC updates host_state right before dialogue starts:

```gdscript
func _on_oracle_interaction() -> void:
    # Update host_state with current values just before dialogue runs
    oracle_trigger.host_state = {
        "player_health": player.current_hp
    }
```

## Related Examples

- **Memory Keeper** - Use `save`/`set` when the dialogue itself tracks state
- **Syntax Guide** - Overview of all variable types
