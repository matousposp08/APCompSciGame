extends TextureButton
signal hovr
signal nothovr

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", Callable(self, "_on_button_hover"))
	connect("mouse_exited", Callable(self, "_on_button_hover_off"))
	connect("pressed", Callable(self, "button_pressed"))
	set_process(false)

func _on_button_hover():
	emit_signal("hovr")

func _on_button_hover_off():
	emit_signal("nothovr")


func button_pressed():
	get_tree().change_scene_to_file("res://MULTIPLAYER STUFF DON'T TOUCH/AP GAME ONLY/scenes/world2.tscn")

func _process(delta):
	pass


