extends Node3D

var SPEED = 30
var x
var from = ""

@onready var mesh = $MeshInstance3D
@onready var particles = $GPUParticles3D
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area3D/CollisionShape3D.disabled = true
	x = 480


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	if x < 478:
		$Area3D/CollisionShape3D.disabled = false
	if x < 0:
		queue_free()

func destroy():
	$Area3D/CollisionShape3D.disabled = true
	mesh.visible = false
	particles.emitting = true
	await get_tree().create_timer(1,0).timeout
	queue_free()

func _on_area_3d_area_entered(area):
	print(area.get_groups())
	print(from)
	print(not(area.is_in_group(from)))
	'''
	if not(area.is_in_group(from)) and not(area.is_in_group("fireball")):
		$Area3D/CollisionShape3D.disabled = true
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(1,0).timeout
		queue_free()
	'''


func _on_area_3d_body_entered(body):
	print(body.name)
	destroy()
