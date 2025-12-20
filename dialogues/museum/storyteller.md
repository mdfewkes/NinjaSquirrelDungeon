# Storyteller - Multi-line Dialogue

## What This Demonstrates

The simplest Bobbin pattern: sequential lines of text. Each line becomes one dialogue box that the player advances through.

## When to Use This Pattern

- **NPC greetings** - "Welcome to my shop!" followed by flavor text
- **Lore dumps** - Environmental storytelling, history, world-building
- **Tutorials** - Step-by-step explanations (though consider choices for interactivity)
- **Cutscene narration** - Story beats triggered by `DialogueBox.show_dialogue()`

## Gotchas

- **Pacing matters** - Long monologues can feel tedious. Break up with choices or keep it short.
- **No blank lines** - Empty lines in Bobbin are ignored, not pauses. For pacing, use actual text or choices.
- **One thought per line** - Each line is its own dialogue box. Don't cram too much into one line.

## Related Examples

- **Merchant** - Add choices to let players interact instead of just reading
- **Syntax Guide** - See how choices can break up text for better engagement
