extends CharacterBody2D

@export var view_range: = 300
@export var speed: = 200
@export var knockback_friction = 1000
@export var max_hp = 2
var current_hp = max_hp

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var hurt_box: HurtBox = $HurtBox

func _ready() -> void:
	hurt_box.area_entered.connect(_on_hurt)

func _physics_process(_delta: float) -> void:
	var state = playback.get_current_node()
	match state:
		"idleState": idle_state()
		"chaseState": chase_state()
		"knockbackState": knockback_state(_delta)

func idle_state():
	if current_hp <= 0: queue_free()

func chase_state():
	velocity = global_position.direction_to(Globals.player.global_position) * speed
	sprite_2d.scale.x = sign(velocity.x)
	move_and_slide()

func knockback_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()


func is_player_in_range() -> bool:
	if Globals.player == null: return false
	var result = false
	var distance = global_position.distance_to(Globals.player.global_position)
	if distance <= view_range: result = true
	return result

func can_see_player() -> bool:
	if not is_player_in_range(): return false
	if Globals.player == null: return false
	
	ray_cast_2d.target_position = Globals.player.global_position - global_position
	return not ray_cast_2d.is_colliding()


func _on_hurt(hitbox: HitBox):
	velocity = hitbox.global_position.direction_to(global_position) * 1000
	current_hp -= hitbox.damage
	playback.start("knockbackState")
