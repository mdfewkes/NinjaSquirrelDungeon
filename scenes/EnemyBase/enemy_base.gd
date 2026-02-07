class_name EnemyBase

extends CharacterBody2D

## Exported (Instance) Variables
@export_category("Enemy Details")
## View range at maximum light
@export var view_range: float = 300
## View range with no light
@export var min_view_range: float = 20
## 0.0: can't see behind at all (even at min_view_range), 1.0: can see in all directions equally
@export var peripheral_vision: float = 1.0
@export var speed := 200
@export var knockback_multiply := 1
@export var knockback_friction := 1000
@export var max_hp := 2

## On Ready Variables
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var animation_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

@export var sfx_on_death : AudioSFX
@export var sfx_on_hurt : AudioSFX

var animation_tree_playback: AnimationNodeStateMachinePlayback

## Class variables
var current_hp := max_hp
var player = null
var facing_direction: Vector2 = Vector2.ZERO
var resetting_position: Vector2 = Vector2.ZERO

## Lifecycle Functions
func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	resetting_position = global_position
	var players := get_tree().get_nodes_in_group("player")
	player = players[0] if players.size() > 0 else null
	if animation_tree:
		animation_tree_playback = animation_tree.get("parameters/StateMachine/playback")

func _physics_process(_delta: float) -> void:
	$Label.text = "HP:" + str(current_hp) + ", View:" + str(get_view_range())

## Common Functions

func get_view_range() -> float:
	var max_range = view_range * Level.light_level if Level.light_level > 0.0 else min_view_range
	var peripheral_loss: float = 0.0
	if facing_direction != Vector2.ZERO:
		var player_angle := global_position.direction_to(player.global_position)
		var angle_diff := facing_direction.angle_to(player_angle)
		# now PI is fully behind us, so if peripheral vision = 0 our range should also be 0 as the angle approaches PI
		# this value should scale between 0.0 (fully in front) and 1.0 (fully behind)
		var peripheral_use: float = abs(angle_diff) / PI
		# this is how much of their range they'll lose
		peripheral_loss = peripheral_use * (1.0 - peripheral_vision) * max_range
	return max_range - peripheral_loss


func is_player_in_range() -> bool:
	if player == null:
		return false

	var distance := global_position.distance_to(player.global_position)
	var max_range := get_view_range()

	return distance <= max_range

func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	if player == null:
		return false
	if player.is_cloaked():
		return false
	
	ray_cast_2d.target_position = player.global_position - global_position
	return not ray_cast_2d.is_colliding()

func reset_position() -> void:
	global_position = resetting_position

## Events
func _on_hurt(hit_box: HitBox) -> void:
	current_hp -= hit_box.damage
	if current_hp <= 0:
		_on_death()
	else:
		AudioManager.PlaySFX(sfx_on_hurt, self)
	
	ImpactEffects.flash(0.4, 0.3, ImpactEffects.FlashType.Neutral)
	velocity = hit_box.global_position.direction_to(global_position).normalized() * hit_box.knockback * knockback_multiply


## Called when HP reaches 0. Override in subclasses for custom death behavior.
func _on_death() -> void:
	if $HitBox:
		$HitBox.monitoring = false
		$HitBox.monitorable = false
	if animation_tree_playback and animation_tree.get("parameters/StateMachine/death"):
		var timeout := 120
		while animation_tree_playback.get_current_node() != "death" and timeout > 0:
			timeout -= 1
			await get_tree().physics_frame
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	AudioManager.PlaySFX_at_position(sfx_on_death, self.global_position)
	queue_free()
