extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$"Round-orange2".rotate(0.01)
	$"Round-orange".rotate(0.01)
	$"Round-orange3".rotate(0.01)
