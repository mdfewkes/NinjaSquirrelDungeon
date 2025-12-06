# Contributing

We use trunk-based development — push directly to main, no branches or PRs.

## Feature Flags

**This system is completely optional.** If you don't create a `feature_flags.json` file, all flags default to off and the game runs normally. This is just a convenience for developing experimental features without affecting others.

### Quick Start

1. Copy `feature_flags.example.json` to `feature_flags.json` (gitignored)
2. Set `"enabled": true` for flags you want active locally
3. Use `FeatureFlags.is_enabled("flag_name")` in code

### JSON Format

```json
{
    "my_feature": {
        "enabled": true,
        "description": "What this feature does"
    }
}
```

### Usage in Code

```gdscript
if FeatureFlags.is_enabled("new_combat"):
    _new_combat_logic()
else:
    _old_combat_logic()
```

### Usage in Scenes

Add a `FeatureFlaggedNode` as a child of any node you want to conditionally include:

```
EnemyNode
  └── FeatureFlaggedNode (flag_name = "new_enemy_ai")
```

If the flag is disabled, the parent node is removed at runtime.

### Adding a New Flag

1. Add the flag to `feature_flags.example.json` with `"enabled": false`
2. Commit the example file so teammates know the flag exists
3. Enable it locally in your `feature_flags.json`

### Removing a Flag

Search for usages:

```bash
grep -r "is_enabled(\"flag_name\")" --include="*.gd" .
```
