extends Control

var x = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	$mana.value=get_parent().mana
	$shield.value=0
	$health.value=100
	x = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
<<<<<<< HEAD
	if get_parent().magic and Input.is_action_just_pressed("magic"):
		x = 10
	if x > 0:
		$mana.value-=1
		x -= 1
		$Sprite2D.rotation += 0.314
=======
	$mana.value=get_parent().mana

>>>>>>> 0cad7d5b68cbe1f401367aed56144188bd38416c

func _on_timer_timeout():
	$mana.value+=0.5
	$shield.value+=0.5
