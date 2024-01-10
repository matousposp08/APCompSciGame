extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$mana.value=0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("magic"):
		$mana.value-=10


func _on_timer_timeout():
	$mana.value+=1
