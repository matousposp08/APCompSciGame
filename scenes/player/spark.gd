extends Sprite3D

var x
# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 0.8
	x = 20 # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	rotation.z += 0.5
	if x < 0:
		queue_free()
