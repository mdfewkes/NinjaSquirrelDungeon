class_name EnemyBase

extends CharacterBody2D

## Exported (Instance) Variables
@export_category("Enemy Details")
@export var view_range := 300
@export var speed := 200
@export var knockback_multiply := 1
@export var knockback_friction := 1000
@export var max_hp := 2

## On Ready Variables
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var animation_tree: AnimationTree = $AnimationTree

## Class variables
var current_hp := max_hp
var player = null

## Lifecycle Functions
func _ready() -> void:
	hurt_box.hurt.connect(_on_hurt)
	$Label.text = str(current_hp)
	player = get_tree().get_nodes_in_group("player")[0]

func _physics_process(_delta: float) -> void:
	$Label.text = str(current_hp)

## Common Functions
func is_player_in_range() -> bool:
	if player == null:
		return false

	var distance := global_position.distance_to(player.global_position)

	return distance <= view_range

func can_see_player() -> bool:
	if not is_player_in_range():
		return false
	if player == null:
		return false
	if player.is_cloaked():
		return false
	
	ray_cast_2d.target_position = player.global_position - global_position
	return not ray_cast_2d.is_colliding()
	
## Events
func _on_hurt(hit_box: HitBox) -> void:
	current_hp -= hit_box.damage
