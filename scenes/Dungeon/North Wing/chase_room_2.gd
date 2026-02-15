extends Room

@onready var player_marker1: Marker2D = $CutScene/PlayerMarker1
@onready var player_marker2: Marker2D = $CutScene/PlayerMarker2
@onready var boss_trigger: Area2D = $CutScene/BossTrigger
@onready var player_trigger: Area2D = $CutScene/PlayerTrigger
@onready var animation_player: AnimationPlayer = $CutScene/AnimationPlayer

@export var sfx_on_thump: AudioSFX

var player_in_place = false

func _ready() -> void:
	super._ready()
	boss_trigger.area_entered.connect(_on_hitbox_entered_boss_trigger)
	player_trigger.body_entered.connect(_on_body_entered_player_trigger)


func trigger_tail_whip() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	player.playback.travel("TailWhipAction")

func walk_away() -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	player.input_vector = Vector2.RIGHT * 0.4

func fade_out() -> void:
	await GameManager.fade_out(4.0).finished
	GameManager.change_scene("res://scenes/Screens/Credits_Screen/credits_screen.tscn", true)
	
func thump() -> void:
	ImpactEffects.shake(4, 0.4)
	AudioManager.PlaySFX(sfx_on_thump, boss_trigger)

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
		player.hurt_box.set_deferred("monitorable", false)
		player.hurt_box.set_deferred("monitorable", false)

		var cam := player.get_node("Camera2D")
		tween.tween_property(cam, "position", Vector2(-300, 0), 0.5)
		tween.parallel().tween_property(self, 'light_modifier', 0.5, 2.0)


func _on_hitbox_entered_boss_trigger(hit_box: Area2D) -> void:
	if hit_box.get_parent() is ChasingBadger and player_in_place:
		var boss: ChasingBadger = hit_box.get_parent()
		boss.start_final_cut_scene()
		animation_player.play("badger_fall")
