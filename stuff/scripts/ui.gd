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
	#$Label.text = "Score: " + str(get_parent().get_parent().score[get_parent().name])
	if Input.is_action_just_pressed("magic") or Input.is_action_just_pressed("melee"):
		x = 10
	if x > 0:
		$AnimatedSprite2D.scale = Vector2(1.3,1.3)
		x -= 1
	else:
		$AnimatedSprite2D.scale = Vector2(1,1)
	$shield.value = get_parent().shield
	$health.value = get_parent().health
	$mana.value=get_parent().mana
	if not(get_parent().magic):
		$AnimatedSprite2D.play("crowbar")
	else:
		if get_parent().mode == 0:
			$AnimatedSprite2D.play("lightning")
		if get_parent().mode == 1:
			$AnimatedSprite2D.play("fireball")
		if get_parent().mode == 2:
			$AnimatedSprite2D.play("ice")

#func _on_timer_timeout():
#	$mana.value+=0.5
#	$shield.value+=0.5
