extends RichTextLabel

var x = -20
# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Vector2(2,2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	if x > 0:
		scale.x += 0.5
		scale.y += 0.5
	elif x > -10 :
		scale.x -= 0.8
		scale.y -= 0.8
	else:
		scale = Vector2(2,2)
		visible = false

func damage(pos, num):
	position = pos
	text = str(num)
	visible = true
	x = 20
