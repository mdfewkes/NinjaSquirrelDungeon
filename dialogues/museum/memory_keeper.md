# Memory Keeper - Persistent Variables

## What This Demonstrates

Using `save` to declare variables that persist between conversations, and `set` to change their values. The dialogue remembers state across multiple interactions.

## When to Use This Pattern

- **Tracking NPC relationships** - `save friendship = 0`, increment on good choices
- **Quest progress** - `save quest_stage = "not_started"`
- **First-time detection** - `save has_met = false`, then `set has_met = true`
- **Remembering player choices** - What did they pick last time?

## Gotchas

- **Declare before use** - `save` must appear before any `set` or display of that variable
- **No expressions yet** - Bobbin doesn't currently support `set x = x + 1`. Use simple assignments.
- **Persistence scope** - Variables persist while the game runs, but `DialogueBox.clear_saved_state()` resets them. Call this when starting a new game.
- **String values need quotes** - `set name = "Hero"` not `set name = Hero`

## Variable Syntax

```bobbin
# Declare with initial value (runs once, ever)
save shrine_offering = "nothing"

# Change the value
set shrine_offering = "a golden coin"

# Display in text
The shrine holds: {shrine_offering}
```

## Common Patterns

### First Meeting Detection

```bobbin
save has_met = false

# This check would need game code - Bobbin doesn't have conditionals yet
# For now, the variable just tracks state for your game to read
```

### Remembering Choices

```bobbin
save last_gift = "nothing"

What would you like to offer?

- A flower
	set last_gift = "flower"
	How lovely!

- A coin
	set last_gift = "coin"
	Most generous!
```

## Related Examples

- **Oracle** - Use `extern` when the game provides the value instead of the dialogue
- **Syntax Guide** - See `save` and `set` working together in the tutorial
