extends Sprite2D

# this script just floats back and forth
# one spritesheet frame per direction

@export var firstFrame = 18
@export var lastFrame = 12
@export var hspeed = 0.5
@export var hdistance = 128.0
@export var vspeed = 3.5
@export var vdistance = 10.0

var start_pos: Vector2
var prev_pos: Vector2

func _ready():
	start_pos = position
	prev_pos = position

func _process(delta):
	# Calculate offset using sine wave
	var hoffset = sin(Time.get_ticks_msec() / 1000.0 * hspeed) * hdistance
	var voffset = sin(Time.get_ticks_msec() / 1000.0 * vspeed) * vdistance
	# float back and forth and up and down
	position.x = start_pos.x + hoffset
	position.y = start_pos.y + voffset
	# switch frame depending on what direction we're moving
	if prev_pos.x < position.x:
		set_frame(firstFrame)
	else:
		set_frame(lastFrame)
	prev_pos = position
	
