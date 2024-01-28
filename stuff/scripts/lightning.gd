extends Node3D

const SPEED = 200

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
var x = 100
var SPARK : PackedScene = preload('res://scenes/player/spark.tscn')
# Called when the node enters the scene tree for the first time.
func _ready():
	$Area3D/CollisionShape3D.disabled = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	x -= 1
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	spark()
	#if ray.is_colliding():
	#	$Area3D/CollisionShape3D.disablexd = false
	#	mesh.visible = false
	#	await get_tree().create_timer(1,0).timeout
	#	queue_free()
	if x < 0:
		queue_free()



func spark() -> void:
	var instance = SPARK.instantiate()
	instance.position = global_position
	instance.transform.basis = global_transform.basis
	instance.scale = Vector3(0.2,0.2,0.2)
	instance.rotation.z = randf()
	get_parent().add_child(instance)


func _on_area_3d_area_entered(area):
	print(area.get_groups())
	if not(area.is_in_group("player")) and not(area.is_in_group("lightning")):
		$Area3D/CollisionShape3D.disabled = true
		queue_free()
