extends TextureButton
signal hovr1
signal nothovr1

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", Callable(self, "_on_button_hover"))
	connect("mouse_exited", Callable(self, "_on_button_hover_off"))
	connect("pressed", Callable(self, "button_pressed"))
	set_process(false)

func _on_button_hover():
	emit_signal("hovr1")

func _on_button_hover_off():
	emit_signal("nothovr1")


func button_pressed():
	get_tree().change_scene_to_file("res://scenes/control_menu.tscn")

func _process(delta):
	pass
