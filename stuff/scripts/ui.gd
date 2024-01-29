extends Control

var x = 0
var instance
# Called when the node enters the scene tree for the first time.
func _ready():
	$mana.value=get_parent().mana
	$shield.value=0
	$health.value=100
	x = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_parent().magic and Input.is_action_just_pressed("magic"):
		x = 10
	if x > 0:
		$mana.value-=1
		x -= 1
	$shield.value = get_parent().shield
	$health.value = get_parent().health
	$mana.value=get_parent().mana

func _on_timer_timeout():
	$mana.value+=0.5
	$shield.value+=0.5
