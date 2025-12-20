# Merchant - Choice Branching

## What This Demonstrates

Player choices using the `-` syntax. Each choice can have its own response text, and choices can be nested for dialogue trees.

## When to Use This Pattern

- **Shop menus** - Buy/Sell/Leave options
- **Conversation branches** - Ask about different topics
- **Decision points** - Player choices that affect the story
- **Interactive tutorials** - Let players choose what to learn about

## Gotchas

- **Indentation is critical** - Use spaces (not tabs). Everything indented under a choice belongs to that choice.
- **Choices don't loop** - After a choice resolves, dialogue continues forward. For menus that repeat, you need game code to re-trigger the dialogue.
- **Keep choices scannable** - Short, clear choice text. Details go in the response.
- **3-4 choices max** - More than 4 choices can overwhelm players.

## Choice Syntax

```bobbin
Question text here

- First choice
    Response to first choice
    More response text

- Second choice
    Response to second choice
```

## Nested Choices

Choices can contain more choices:

```bobbin
What interests you?

- Combat
    - Weapons
        We have swords and bows.
    - Armor
        Full plate or leather?

- Magic
    Spellbooks are in the back.
```

## Related Examples

- **Storyteller** - When you don't need player input
- **Memory Keeper** - Combine choices with variables to remember what was chosen
