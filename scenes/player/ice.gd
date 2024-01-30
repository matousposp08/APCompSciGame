extends Node3D

var x
var from = ""
# Called when the node enters the scene tree for the first time.
func _ready():
	x = 20
	$GPUParticles3D.emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	if x < 0:
		queue_free()
