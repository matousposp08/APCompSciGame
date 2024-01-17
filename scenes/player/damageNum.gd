extends RichTextLabel

var x = 30
# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Vector2(10,10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	if x > 0:
		scale.x += 0.1
		scale.y += 0.1
	elif x > -30 :
		scale.x -= 0.2
		scale.y -= 0.2
	else:
		queue_free()
