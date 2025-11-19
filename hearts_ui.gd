extends Control

@onready var empty_hearts: TextureRect = $EmptyHearts
@onready var full_hearts: TextureRect = $FullHearts

func _ready() -> void:
	var player_group = get_tree().get_nodes_in_group("player")
	var player = null
	if player_group.size() > 0 and player_group[0] is Player: player = player_group[0] as Player
	if player != null:
		player.update_health.connect(set_health)
		set_current_hp(player.current_hp)
		set_max_hp(player.max_hp)

func set_current_hp(value):
	full_hearts.size.x = value * 32;
	
func set_max_hp(value):
	empty_hearts.size.x = value * 32;

func set_health(current_hp, max_hp):
	set_current_hp(current_hp)
	set_max_hp(max_hp)
