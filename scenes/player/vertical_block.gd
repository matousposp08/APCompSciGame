extends StaticBody3D
var x = 900
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	if x <= 0:
		queue_free()


func _on_area_3d_area_entered(area):
	if area.is_in_group("fireball") or area.is_in_group("lightning") or area.is_in_group("ice"):
		queue_free()
