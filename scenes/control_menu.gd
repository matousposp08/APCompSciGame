extends Node2D
var master_bus = AudioServer.get_bus_index("Master")

# Called when the node enters the scene tree for the first time.
func _ready():
	$HSlider.value = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Prup.rotate(0.01)
	$Prup2.rotate(0.01)
	$Prup3.rotate(0.01)



func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(master_bus, value)
	if value == -30:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
