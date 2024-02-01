extends Control

var timer = false
var mode = 0
var game = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	game = get_parent().get_parent().game
	if game:
		$Button3.disabled = true
		$Button5.disabled = false
	else:
		$Button3.disabled = false
		$Button5.disabled = true


func _on_button_pressed():
	mode = 2


func _on_button_2_pressed():
	mode = 1


func _on_button_3_pressed():
	if not(game):
		get_parent().get_parent().game_start(mode, timer)


func _on_button_4_pressed():
	mode = 0

func _on_button_5_pressed():
	if game:
		get_parent().get_parent().game = false

func _on_check_button_toggled(toggled_on):
	timer = toggled_on
