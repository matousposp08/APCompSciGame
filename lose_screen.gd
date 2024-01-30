extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label/AnimationPlayer.play("14")
	$Button/AnimationPlayer.play("15")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
