class_name Bridge
extends Area2D

const VERTICAL_DISPLACEMENT = 10.0
const HORIZONTAL_CONNECTEDNESS = 2
const FADE_DEPTH = 64.0
const FALL_SPEED = 100.0

@export var can_be_destroyed := false
@export var sfx_on_step: AudioSFX
@export var sfx_on_break: AudioSFX

@onready var template: Area2D = $TemplateLog
@onready var template_shape: CollisionShape2D = $TemplateLog/CollisionShape2D
@onready var collision_shape: CollisionShape2D = $BridgeShape
@onready var hurt_box: HurtBox = $HurtBox
@onready var death_particles: CPUParticles2D = $DeathParticles

var logs: Array[Area2D] = []
var log_objs: Array[Array] = []
var log_width: float
var broken_at_index: int = -1
var x_start: float
var x_end: float

func _ready() -> void:
	# the main collision shape defines the size of the bridge
	var bridge_rect: Rect2 = collision_shape.shape.get_rect()
	var log_rect: Rect2 = template_shape.shape.get_rect()
	# based on the height of rectangle, find the scale factor
	# of an individual log that would match the height of the log
	# to the height of the box
	var y_scale: float = bridge_rect.size.y / log_rect.size.y
	var best_width: float = log_rect.size.x * y_scale
	# then we find the number of logs that would fix the horizontal
	# space at that scale level without any gap
	var num_logs: int = ceil(bridge_rect.size.x / best_width)
	# and find the horizontal scale factor that will make the logs
	# fill the entire space, even if they're not exactly square
	var x_scale: float = bridge_rect.size.x / (best_width * num_logs)
	log_width = best_width * x_scale
	# find the location of the first log
	x_start = collision_shape.position.x + bridge_rect.position.x + log_width / 2.0
	x_end = x_start + log_width * num_logs - log_width
	
	template.scale = Vector2(x_scale, y_scale)
	template.hide()
	
	# create the log objects from the template
	for i in range(num_logs):
		var obj: Node2D = template.duplicate()
		add_child(obj)
		obj.position.x = x_start + log_width * i
		obj.show()
		obj.body_entered.connect(_on_body_entered_log.bind(i))
		obj.body_exited.connect(_on_body_exited_log.bind(i))
		logs.append(obj)
		log_objs.append([])
	
	body_entered.connect(_on_body_entered_bridge)
	body_exited.connect(_on_body_exited_bridge)
	
	if can_be_destroyed:
		hurt_box.add_child(collision_shape.duplicate())
		hurt_box.hurt.connect(_on_hurt)

# these handlers keep the player from falling into the pit
func _on_body_entered_bridge(body: Node2D):
	if broken_at_index < 0 and body.has_method("entered_platform"):
		body.entered_platform()

func _on_body_exited_bridge(body: Node2D):
	if broken_at_index < 0 and body.has_method("exited_platform"):
		body.exited_platform()

# these handlers power the bridge displacement
func _on_body_entered_log(body: Node2D, log_index: int) -> void:
	if broken_at_index < 0:
		log_objs[log_index].append(body)
		AudioManager.PlaySFX_at_position(sfx_on_step, body.global_position)

func _on_body_exited_log(body: Node2D, log_index: int) -> void:
	if broken_at_index < 0:
		log_objs[log_index].erase(body)

# allow the bridge to be destroyed
func _on_hurt(hit_box: HitBox) -> void:
	if broken_at_index < 0 and can_be_destroyed and hit_box.damage > 0:
		var hit_point := to_local(hit_box.global_position)
		broken_at_index = clampi(floor((hit_point.x - x_start) / log_width), 0, logs.size() - 1)
		_on_broken()

func _on_broken():
	ImpactEffects.shake(0.8, 0.4)
	AudioManager.PlaySFX_at_position(sfx_on_break, global_position)
	death_particles.position = logs[broken_at_index].position
	death_particles.emitting = true
	hurt_box.monitorable = false
	hurt_box.monitoring = false
	var objs = {}
	for obj_list in log_objs:
		for obj in obj_list:
			objs[obj] = true
	for body in objs:
		if body.has_method("exited_platform"):
			body.exited_platform()

func _process(delta: float) -> void:
	if broken_at_index < 0:
		_set_in_tact_offsets()
	else:
		_set_falling_offsets(delta)

func _set_falling_offsets(delta: float) -> void:
	for i in range(logs.size()):
		var target: Vector2
		var chain_index: int
		if i < broken_at_index:
			chain_index = i
			target = Vector2(x_start, log_width * chain_index)
		else:
			chain_index = abs(logs.size() - 1 - i)
			target = Vector2(x_end, log_width * chain_index)
		logs[i].position = logs[i].position.move_toward(target, FALL_SPEED * delta)
		logs[i].modulate = lerp(Color.WHITE, Color.TRANSPARENT, clamp(logs[i].position.y, 0.0, FADE_DEPTH) / FADE_DEPTH)
		logs[i].z_index = clamp(5 - chain_index, 0, 5)

func _set_in_tact_offsets() -> void:
	for i in range(logs.size()):
		# is an object (e.g., the player) is on this segment it should be slightly weighed down
		var offset: float = _get_offset(i, 0)
		if offset < 1.0:
			# look a few segments in both directions to see if there's an object close
			# if there is, this segment will be slightly weighed down to simulate the stretch of the bridge
			for j in range(1, HORIZONTAL_CONNECTEDNESS + 1):
				offset = max(offset, _get_offset(i, j), _get_offset(i, -j))

		# if this segment is close to either end of the bridge it can't stretch as far
		# so we scale it back slightly because it can't stretch down quite as far
		var dist_to_end = min(i, logs.size() - i - 1)
		if dist_to_end < HORIZONTAL_CONNECTEDNESS:
			offset = min(offset, 1.0 - _scale_impact(dist_to_end + 1))

		# scale 1.0 up to the number of pixels and apply the displacement
		logs[i].position.y = offset * VERTICAL_DISPLACEMENT

# if an object is on this point i, return 1.0
# otherwise return 0.0
# for j > 0, the return value is scaled down towards 0 to simulate the bridge stretching up
func _get_offset(i: int, j: int) -> float:
	if i + j < 0 or i + j >= log_objs.size():
		return 0.0
	if log_objs[i + j].size() == 0:
		return 0.0
	return _scale_impact(j)

# at j==0, return 1.0
# at j>HORIZONTAL_CONNECTEDNESS, return 0.0
# between those values, it scales down linearly
# so given current values: 0 => 1.0, 1 => 0.666, 2 => 0.333, 3 => 0.0
func _scale_impact(j: int) -> float:
	var k := HORIZONTAL_CONNECTEDNESS + 1
	return clamp(float(k - abs(j)) / float(k), 0.0, 1.0)
