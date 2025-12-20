# Syntax Guide - Interactive Tutorial

## What This Demonstrates

A meta-dialogue that teaches Bobbin syntax through the dialogue system itself. It covers all five core concepts while demonstrating them in action.

## When to Use This Pattern

This is primarily a learning resource, but the pattern of a "self-teaching" dialogue is useful for:

- **In-game tutorials** - Teach mechanics through dialogue
- **Help systems** - Let players ask about game features
- **Codex/lore menus** - Organized information with choices

## The Five Core Concepts

| Concept | Syntax | Purpose |
|---------|--------|---------|
| Text lines | Plain text | Sequential dialogue boxes |
| Choices | `- Choice text` | Player decisions with branching |
| Save | `save x = value` | Persistent variables (survive conversations) |
| Set | `set x = value` | Change a variable's value |
| Extern | `extern x` | Read game-provided variables |
| Display | `{variable}` | Show variable value in text |

## How This Tutorial Works

The Syntax Guide demonstrates persistence by:

1. Declaring `save last_topic = "nothing yet"` at the start
2. Each lesson sets `last_topic` to the current topic name
3. When you return, it greets you with your last topic

This shows `save`, `set`, and `{variable}` display working together.

## Related Examples

- **Storyteller** - Deep dive into multi-line text
- **Merchant** - Deep dive into choice branching
- **Memory Keeper** - Deep dive into save/set variables
- **Oracle** - Deep dive into extern host state
