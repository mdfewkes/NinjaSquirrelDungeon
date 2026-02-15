extends Room

## If set, this dialog will play before the cut scene starts
@export var dialog_script_path: String
@export var sfx_thud: AudioSFX
@export var sfx_boss_step: AudioSFX
@export var sfx_boss_grab: AudioSFX
@export var sfx_boss_chomp: AudioSFX
@export var sfx_boss_grow: AudioSFX

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var cut_scene_badger: StaticBody2D = $Enemies/CutSceneBadger

func _start_cut_scene() -> void:
	if dialog_script_path:
		DialogueBox.show_dialogue(dialog_script_path, {})
		await DialogueBox.dialogue_finished
	
	# TODO: start music
	
	var player: Player = get_tree().get_first_node_in_group("player")
	player.velocity = Vector2.ZERO
	player.last_input_vector = Vector2.ZERO
	player.input_vector = Vector2.ZERO
	player.is_cutscene_squirrel = true
	anim.play("enter")

func _shake(amount: float, time: float) -> void:
	ImpactEffects.hit(amount, time, ImpactEffects.FlashType.Stark, 0.2)

func _finish_scene():
	var player: Player = get_tree().get_first_node_in_group("player")
	var marker: Marker2D = $PlayerEndingPoint
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(player, "global_position", marker.global_position, 1.5)
	await t.finished
	player.is_cutscene_squirrel = false

func play_sfx_thud() -> void:
	AudioManager.PlaySFX(sfx_thud, cut_scene_badger)

func play_sfx_step() -> void:
	AudioManager.PlaySFX(sfx_boss_step, cut_scene_badger)

func play_sfx_grab() -> void:
	AudioManager.PlaySFX(sfx_boss_grab, cut_scene_badger)

func play_sfx_chomp() -> void:
	AudioManager.PlaySFX(sfx_boss_chomp, cut_scene_badger)

func play_sfx_grow() -> void:
	AudioManager.PlaySFX(sfx_boss_grow, cut_scene_badger, 0.25)
