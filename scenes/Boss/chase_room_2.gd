extends Room

@onready var player_marker1: Marker2D = $PlayerMarker1
@onready var player_marker2: Marker2D = $PlayerMarker2
@onready var boss_trigger: Area2D = $CutSceneTriggerBoss
@onready var player_trigger: Area2D = $CutSceneTriggerPlayer

var player_in_place = false

func _ready() -> void:
	super._ready()
	boss_trigger.area_entered.connect(_on_hitbox_entered_boss_trigger)
	player_trigger.body_entered.connect(_on_body_entered_player_trigger)


func _on_body_entered_player_trigger(player: Node2D) -> void:
	if player is Player:
		player_in_place = true
		var tween = create_tween()
		tween.tween_property(player, "global_position", player_marker1.global_position, 0.5)
		player.velocity = Vector2.ZERO
		player.last_input_vector = Vector2.ZERO
		player.input_vector = Vector2.LEFT
		player._update_blend_positions()
		player.input_vector = Vector2.ZERO
		player.is_cutscene_squirrel = true


func _on_hitbox_entered_boss_trigger(hit_box: Area2D) -> void:
	if hit_box.get_parent() is ChasingBadger and player_in_place:
		get_tree().paused = true
