extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_control_hovr_1():
	visible = true


func _on_control_nothovr_1():
	visible = false
