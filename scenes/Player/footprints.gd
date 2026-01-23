extends CPUParticles2D

# footprints using particles!

# this script stops emitting when we are motionless
# so we don't leave a black spot when standing still

var prevPos = Vector2(-999,-999)

func _process(_delta):
	var dist = prevPos.distance_to(get_parent().position)
	#print("move dist: "+str(dist))
	emitting = dist > 0
	prevPos = get_parent().position
