extends CharacterBody3D


@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var base_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0
var from = ""
var health = 100
var shield = 100
var magic = false
var mode = 0
var hits = false
var mana = 100
var x = 0

var FIREBALL : PackedScene = preload('res://scenes/player/fireball.tscn')
var LIGHTNING : PackedScene = preload('res://scenes/player/lightning.tscn')
var ICE : PackedScene = preload('res://scenes/player/ice.tscn')
var BLOCK: PackedScene = preload('res://scenes/player/vertical_block.tscn')
var NUM: PackedScene = preload('res://scenes/player/damage_num.tscn')
var instance
var pause = false
var speed: float = base_speed
var state: String = "normal"  
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_fov_extents: Array[float] = [75.0, 85.0,40.0]
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75


@onready var parts: Dictionary = {
	"head": $head,
	"camera": $head/camera,
	"camera_animation": $head/camera/camera_animation,
	"body": $body,
	"collision": $collision,
	"crowbar": $head/crowbar
}

@onready var world: SceneTree = get_tree()
var isMoving = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)

func _ready() -> void:
	if not is_multiplayer_authority(): 
		$UI.visible = false
		return
	print(from)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$head/crowbar/Area3D/CollisionShape3D.disabled = false
	parts["camera"].current = true

func _process(delta: float) -> void:
	print(from)
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("restart"):
		global_transform.origin = Vector3(randi_range(-39, 16), 28, randi_range(-59, 14))
	#if mouse:
	#	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	#else:
	#	pass
	if Input.is_action_just_pressed("magic"):
		if not(magic):
			magic = true
		else:
			if mode == 2:
				mode = 0
			else:
				mode += 1
	if Input.is_action_just_pressed("melee"):
		magic = false
	handle_movement_input(delta)
	update_camera(delta)
	hit()
	fireball()
	lightning()
	ice()
	#build()
	if Input.is_action_pressed("move_forward"):
		if not isMoving:
			isMoving = true
			$head/camera/camera_animation.play("head_bob")
	else:
		if isMoving:
			isMoving = false
			$head/camera/camera_animation.stop()
	mana = mana + 0.5 if mana < 100 else 100

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	apply_gravity(delta)
	handle_jump()
	move_character(delta)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		handle_mouse_movement(event)


func handle_movement_input(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if position.y <= -5:
		position = Vector3(randi_range(-10, 10),5,randi_range(-10, 10))
	
	if Input.is_action_pressed("move_sprint") and !Input.is_action_pressed("move_crouch") and sprint_enabled:
		if !$crouch_roof_detect.is_colliding(): 
			enter_sprint_state(delta)
	elif Input.is_action_pressed("move_crouch") and !Input.is_action_pressed("move_sprint") and crouch_enabled:
		enter_crouch_state(delta)
	else:
		if !$crouch_roof_detect.is_colliding():
			enter_normal_state(delta)

func enter_sprint_state(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	state = "sprinting"
	speed = sprint_speed
	parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)

func enter_crouch_state(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	state = "crouching"
	speed = crouch_speed
	apply_crouch_transform(delta)

func enter_normal_state(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	state = "normal"
	speed = base_speed
	reset_transforms(delta)

func update_camera(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	match state:
		"sprinting":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)
		"normal":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[0], 10 * delta)
		"crouching":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[2], 10 * delta)


func apply_crouch_transform(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	parts["body"].scale.y = lerp(parts["body"].scale.y, crouch_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, crouch_player_y_scale, 10 * delta)

func reset_transforms(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	parts["body"].scale.y = lerp(parts["body"].scale.y, base_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, base_player_y_scale, 10 * delta)


func apply_gravity(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity
		
	elif Input.is_action_pressed("move_jump") and is_on_wall_only():
		velocity.y += 0.5

func hit() -> void:
	if not is_multiplayer_authority(): return
	
	x -= 1
	if x <= 0:
		hits = false
		$head/crowbar/Area3D/CollisionShape3D.disabled = true
		
	if Input.is_action_pressed("hit") and not(hits) and not(magic):
		hits = true
		$head/crowbar/Area3D/CollisionShape3D.disabled = false
		$head/crowbar/AnimationPlayer.play("hit1")
		x = 60
	
	

func build() -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("build"):
		if BLOCK:
			var block = BLOCK.instantiate()
			get_tree().current_scene.add_child(block)
			block.global_position = self.global_position
			if $head.rotation_degrees.y < 45 or $head.rotation_degrees.y > 314:
				block.position.z -= 5
			elif $head.rotation_degrees.y < 135 or $head.rotation_degrees.y > 44:
				block.position.x -= 5
				block.rotation.y =90
			elif $head.rotation_degrees.y < 225 or $head.rotation_degrees.y > 134:
				block.position.z += 5
			elif $head.rotation_degrees.y < 315 or $head.rotation_degrees.y > 224:
				block.position.x += 5
				block.rotation.y =90

func move_character(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector2 = input_dir.normalized().rotated(-parts["head"].rotation.y)
	#if is_on_floor():
	velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, direction.y * speed, accel * delta)
	move_and_slide()


func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	if not is_multiplayer_authority(): return
	
	if !world.paused:
		parts["head"].rotation_degrees.y -= event.relative.x * sensitivity
		parts["head"].rotation_degrees.x -= event.relative.y * sensitivity
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))

func spawn_fireball():
	var instance = FIREBALL.instantiate()
	instance.position = $head.global_position
	instance.transform.basis = $head.global_transform.basis
	get_parent().add_child(instance)
	#print(from)
	instance.get_node("Area3D").add_to_group(from)
	instance.from = from
	rpc("rpc_spawn_fireball", instance.position, instance.transform.basis)

@rpc func rpc_spawn_fireball(position, basis):
	var instance = FIREBALL.instantiate()
	instance.position = position
	instance.transform.basis = basis
	get_parent().add_child(instance)

func fireball():
	if not is_multiplayer_authority(): return

	if Input.is_action_just_pressed("hit") and magic and mode == 1 and mana >= 30:
		spawn_fireball()
		mana -= 30
		
func spawn_lightning(position, basis, rotation):
	var instance = LIGHTNING.instantiate()
	instance.position = position
	instance.transform.basis = basis
	instance.rotation.z = rotation
	#print(from)
	instance.from = from
	instance.add_to_group(from)
	instance.position.y -= 0.3
	instance.get_node("Area3D").add_to_group(from)
	get_parent().add_child(instance)
	rpc("rpc_spawn_lightning", position, basis, rotation)

@rpc func rpc_spawn_lightning(position, basis, rotation):
	var instance = LIGHTNING.instantiate()
	instance.position = position
	instance.transform.basis = basis
	instance.rotation.z = rotation
	add_child(instance)

func lightning() -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("hit") and magic and mode == 0 and mana >= 40:
		var position = $head.global_position
		var basis = $head.global_transform.basis
		var rotation = randf()
		spawn_lightning(position, basis, rotation)
		mana -= 40
	
func _on_area_3d_area_entered(area):
	if not is_multiplayer_authority(): return

	#print(area.get_groups())
	var other
	var other2
	if not(area.is_in_group('crowbar')):
		other = str(area.get_parent().from)
		other2 = str(area.get_parent().name)
	else:
		other = str(area.get_parent().get_parent().get_parent().from)
		other2 = str(area.get_parent().get_parent().get_parent().name)
	
	#print(other)
	#print(other2)
	#print(from)
	if not(other == from):
		if area.is_in_group("fireball") and not(area.is_in_group(from)):
			health -= 45
			#print(get_parent().get_node(other2+"/head/camera").unproject_position(position))
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),45)
			var knockbackForce = 50
			var knockbackDirection = (position - area.get_parent().position).normalized()
			area.queue_free()
			velocity = knockbackDirection * knockbackForce
		if area.is_in_group("crowbar") and not(area.is_in_group(from)):
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),20)
			print("hit")
			health -= 20
			var x = position - area.get_parent().position
			velocity = 30*(x/x.length())
		if area.is_in_group("lightning") and not(area.is_in_group(from)):
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),70)
			health -= 70
			area.queue_free()
		if area.is_in_group("ice") and not(area.is_in_group(from)):
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),35)
			health -= 35
			area.queue_free()

func spawn_ice(position, basis):
	var instance = ICE.instantiate()
	instance.from = from
	instance.position = position
	instance.transform.basis = basis
	print(from)
	instance.get_node("Area3D").add_to_group(from)
	instance.add_to_group(from)
	get_parent().add_child(instance)
	rpc("rpc_spawn_ice", position, basis)

@rpc func rpc_spawn_ice(position, basis):
	spawn_ice(position, basis)

func ice() -> void:
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("hit") and magic and mode == 2 and mana >= 15:
		spawn_ice($head.global_position, $head.global_transform.basis)
		mana -= 15


func num(pos, num) -> void:
	if not is_multiplayer_authority(): return
	
	get_node("UI/damageNum").damage(pos,num)
