extends Node3D

const SPEED = 30

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D
var y = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area3D/CollisionShape3D.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	y *= -2
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	position.y -= y
	add_to_group("player")
	if ray.is_colliding():
		$Area3D/CollisionShape3D.disabled = false
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(1,0).timeout
		queue_free()
