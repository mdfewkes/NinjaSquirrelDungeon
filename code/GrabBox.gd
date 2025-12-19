class_name GrabBox
extends Area2D

## Affects how well the player can pull this object towards them
## Higher values mean the player will pull faster (object appears lighter)
## Lower values mean the player will pull slower (object appears heavier)
## Zero means the player can't pull at all (smoke and sparks but no motion)
@export var pull_speed_coefficient := 1.0

func can_be_pulled() -> Node:
	if pull_speed_coefficient != 0.0:
		return get_parent()
	return null
