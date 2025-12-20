# Error Examples - Debugging Guide

## What This Demonstrates

Common Bobbin errors and how to debug them. This NPC teaches troubleshooting rather than demonstrating broken code.

## Common Errors and Solutions

### 1. Indentation Errors (Most Common!)

**Symptom**: Dialogue doesn't parse, choices don't work, or responses appear at wrong times.

**Cause**: Using tabs instead of spaces. Bobbin requires spaces.

**Fix**:
1. In Godot: **Edit → Indentation → Convert Indent to Spaces**
2. Check bottom-right corner of editor - it shows current indentation mode
3. Set your editor to use spaces by default for `.bobbin` files

### 2. Undefined Variable

**Symptom**: `{variable}` shows as blank or causes an error.

**Cause**: Variable used before declaration.

**Fix**: Ensure `save`, `temp`, or `extern` appears BEFORE any `{variable}` display or `set` command.

```bobbin
# Wrong - using before declaring
You have {gold} gold.
save gold = 100

# Right - declare first
save gold = 100
You have {gold} gold.
```

### 3. Missing Extern Value

**Symptom**: `{extern_var}` is empty even though you declared it.

**Cause**: Game code didn't pass the variable in `host_state`.

**Fix**: Check your DialogueTrigger or DialogueBox.show_dialogue() call:

```gdscript
# Make sure you're passing the variable
DialogueBox.show_dialogue("path.bobbin", {
    "player_health": player.current_hp  # Must match extern name exactly
})
```

### 4. Dialogue Won't Load

**Symptom**: Nothing happens when triggering dialogue, or immediate end.

**Causes**:
- File path typo (check `dialogue_file` property)
- Syntax error in .bobbin file
- File not saved

**Debug**: Check the Godot console (bottom panel) for error messages.

### 5. Choices Not Appearing

**Symptom**: Expected choices don't show up.

**Causes**:
- Missing space after dash: `-Choice` instead of `- Choice`
- No response text under choice
- Wrong indentation level

**Fix**:
```bobbin
# Wrong
-Buy item
Response here

# Right
- Buy item
    Response here
```

## Debugging Tips

1. **Always check the console** - Bobbin errors appear in Godot's Output panel
2. **Use View Source button** - During dialogue, click "View Source" to copy the file path
3. **Test in Dialogue Museum** - Use the museum scene to test dialogues in isolation
4. **Start simple** - If a complex dialogue breaks, simplify until it works, then add back complexity

## Related Examples

- **Syntax Guide** - Review the correct syntax patterns
- **dialogues/README.md** - Full syntax reference
