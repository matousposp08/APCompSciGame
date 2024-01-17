extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$mana.value=get_parent().mana
	$shield.value=0
	$health.value=100


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$mana.value=get_parent().mana


func _on_timer_timeout():
	$mana.value+=0.5
	$shield.value+=0.5
