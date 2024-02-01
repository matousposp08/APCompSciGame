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
var iframes = 0
var attacker

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

const spawn_locations = [
	Vector3(4.121731, -1.038562, 12.91191), \
	Vector3(16.24989, -0.870576, 11.39177), \
	Vector3(16.42706, -0.878557, -19.82363), \
	Vector3(16.02861, -0.878562, -26.86526), \
	Vector3(7.222768, 5.265378, -60.38696), \
	Vector3(7.222768, 5.265378, -60.38696), \
	Vector3(-6.01243, 17.14531, -29.05025), \
	Vector3(-5.615685, 17.14533, -8.284218), \
	Vector3(-15.0209, 17.145, -14.26368), \
	Vector3(-22.55212, 17.145, -9.914391), \
	Vector3(-40.84739, 33.94482, -30.63957), \
	Vector3(-19.32512, 39.26546, -30.26815), \
	Vector3(-21.28779, 34.74911, -39.77757), \
	Vector3(-5.987343, 25.33743, -53.40427), \
	Vector3(0.590306, 25.33705, -33.05113), \
	Vector3(-7.198435, 4.449413, -15.32865), \
	Vector3(-35.40859, 0.761239, 2.176908), \
	Vector3(-42.76019, -0.262714, -36.18311), \
	Vector3(-40.32557, 12.22985, -30.78641), \
	Vector3(-39.14805, 7.321252, -30.83821) \
]

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
	$Username.billboard = true
	var username = get_parent().get_node("CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Username").text
	if(username != ""):
		if not is_multiplayer_authority(): return
		$Username.text = username
		$Username.billboard = true
	else:
		if not is_multiplayer_authority(): return
		$Username.text = "guest"+str(get_parent().ps)
		$Username.billboard = true

func _ready() -> void:
	if not is_multiplayer_authority(): 
		print("no ui")
		$UI.visible = false
		return
	get_parent().areas[$head/crowbar/Area3D] = $Username.text
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$head/crowbar/Area3D/CollisionShape3D.disabled = false
	parts["camera"].current = true
	$Username.billboard = true
	global_transform.origin = spawn_locations.pick_random()

func _process(delta: float) -> void:
	iframes -= 1
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("restart") or health <= 0:
		shield = 100
		mana = 100
		health = 100
		global_transform.origin = spawn_locations.pick_random()
		velocity.y = 0
	#if mo`:
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
	if mana < 100:
		mana += 1
	
	if Input.is_action_just_pressed("record_position"):
		print(position)

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
		position = spawn_locations.pick_random()
	
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
	get_parent().areas[instance.get_node("Area3D")] = $Username.text
	#print(from)
	instance.get_node("Area3D").add_to_group(from)
	instance.from = from
	rpc("rpc_spawn_fireball", instance.position, instance.transform.basis)

@rpc func rpc_spawn_fireball(pos, bas):
	var instance = FIREBALL.instantiate()
	instance.position = pos
	instance.transform.basis = bas
	print(str(position) + " " + str(instance.position))
	get_parent().add_child(instance)

func fireball():
	if not is_multiplayer_authority(): return

	if Input.is_action_just_pressed("hit") and magic and mode == 1 and mana >= 30:
		spawn_fireball()
		mana -= 30
		
func spawn_lightning(position, basis, rotation):
	if not is_multiplayer_authority(): return
	var instance = LIGHTNING.instantiate()
	instance.position = position
	instance.transform.basis = basis
	instance.rotation.z = rotation.z
	#print(from)
	get_parent().areas[instance.get_node("Area3D")] = $Username.text
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
	instance.rotation.z = rotation.z
	add_child(instance)

func lightning() -> void:
	#if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("hit") and magic and mode == 0 and mana >= 40:
		print(global_position)
		var pos = global_position
		var bas = $head.global_transform.basis
		#var rotation = randf()
		spawn_lightning(position, bas, rotation)
		mana -= 40
	
func _on_area_3d_area_entered(area):
	if iframes > 0:
		return
	if not is_multiplayer_authority(): return
	print(str(get_parent().areas.get(area)) + " " + $Username.text)
	print(not(str(get_parent().areas.get(area)) == $Username.text))
	attacker = str(get_parent().areas.get(area))
	if attacker == "<null>":
		attacker = str(area.get_parent().get_parent().get_parent().get_node("Username").text)
	if not(str(get_parent().areas.get(area)) == $Username.text):
		if area.is_in_group("fireball"):
			applyDamage(45)
			#print(get_parent().get_node(other2+"/head/camera").unproject_position(position))
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),45)
			var knockbackForce = 50
			var knockbackDirection = (position - area.get_parent().position).normalized()
			iframes = 20
			#area.queue_free()
			velocity = knockbackDirection * knockbackForce
		if area.is_in_group("lightning"):
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),70)
			area.queue_free()
			applyDamage(70)
			iframes = 20
		if area.is_in_group("ice"):
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),35)
			area.queue_free()
			applyDamage(35)
			iframes = 20
		#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),20)
		if area.is_in_group("crowbar"):
			print("hit")
			var x = position - area.get_parent().position
			applyDamage(20)
			print(health)
			velocity = 10*(x/x.length())
			iframes = 20

func spawn_ice(position, basis):
	var instance = ICE.instantiate()
	instance.from = from
	instance.position = position
	instance.transform.basis = basis
	get_parent().areas[instance.get_node("Area3D")] = $Username.text
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

func applyDamage(damage) -> void:
	var q = damage
	if shield < damage:
		q -= shield
		health -= q
		shield = 0
		print(attacker +  " schooled "+$Username.text)
	else: 
		shield -= damage
	
	
func num(pos, num) -> void:
	if not is_multiplayer_authority(): return
	
	get_node("UI/damageNum").damage(pos,num)
