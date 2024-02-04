extends CharacterBody3D


@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var base_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5
@export var max_velocity: float = 35.0
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0
var from = ""
var health = 100
var shield = 100
var shieldCount = 0
var magic = false
var mode = 0
var hits = false
var mana = 100
var x = 0
var iframes = 0
var attacker
var death = 0
var create = false
var cycle = 1

var FIREBALL : PackedScene = preload('res://scenes/player/fireball.tscn')
var LIGHTNING : PackedScene = preload('res://scenes/player/lightning.tscn')
var ICE : PackedScene = preload('res://scenes/player/ice.tscn')
var BLOCK: PackedScene = preload('res://scenes/player/vertical_block.tscn')
var NUM: PackedScene = preload('res://scenes/player/damage_num.tscn')
var instance
var pause = false
var speed: float = base_speed
var state: String = "normal"  
var gravity: float = 9.8
var camera_fov_extents: Array[float] = [75.0, 85.0,40.0]
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75
var controller_sensitivity = 30

const spawn_locations = [
	Vector3(4.121731, -1.038562, 12.91191), \
	Vector3(16.24989, -0.870576, 11.39177), \
	Vector3(16.42706, -0.878557, -19.82363), \
	Vector3(16.02861, -0.878562, -26.86526), \
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
	$GameOptions.visible = false
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

func start():
	death = 0
	shield = 100
	mana = 100
	health = 100
	global_transform.origin = spawn_locations.pick_random()
	velocity = Vector3(0,0,0)

var end = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		create = not(create)
	if Input.is_action_just_pressed("build1"):
		cycle = 1
	if Input.is_action_just_pressed("build2"):
		cycle = 2
	if Input.is_action_just_pressed("build3"):
		cycle = 3
	if Input.is_action_just_pressed("cyclebuild"):
		cycle += 1
		if cycle > 3:
			cycle = 1
	if get_parent().get_node("results").visible == true and not(end):
		get_parent().game_end()
		end = true
	if not(is_multiplayer_authority()): 
		$Username.visible = true
		return
	else:
		$Username.visible = false
	if get_parent().get_node("Label").text == "0":
		gravity = 9.8
	if get_parent().get_node("Label").text == "2":
		gravity = 2
	get_parent().checkScore(name, death)
	if name == "1" and Input.is_action_just_pressed("options"):
		$GameOptions.visible = not($GameOptions.visible)
	#if $GameOptions.visible:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		##Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#else:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#if not(get_parent().pause):
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#else:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#
	if $GameOptions.visible or get_parent().pause:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	iframes -= 1
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("restart") or health <= 0:
		death += 1
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
		create = false
		if not(magic):
			magic = true
		else:
			if mode == 2:
				mode = 0
			else:
				mode += 1
	if Input.is_action_just_pressed("melee"):
		magic = false
	if not(get_parent().end):
		handle_movement_input(delta)
		handle_controller_camera_movement()
		update_camera(delta)
		#hit()
		if not(create):
			fireball()
			lightning()
			ice()
	if create:
		build()
	if Input.is_action_pressed("move_forward"):
		if not isMoving:
			isMoving = true
			$head/camera/camera_animation.play("head_bob")
	else:
		if isMoving:
			isMoving = false
			$head/camera/camera_animation.stop()
	if mana < 100:
		mana += 0.05
	
	if Input.is_action_just_pressed("record_position"):
		print(position)
		
	if velocity.y > 35:
		velocity.y = max_velocity
		
	#Shield Regen:
	shieldCount += 1
	if shieldCount >= 60:
		if shield < 100:
			shield += 2
		shieldCount = 0
	shield = 100 if shield > 100 else shield

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if not(get_parent().end):
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
		death += 1
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
	
	if Input.is_action_just_pressed("hit") and create and mana >= 20:
		var d
		mana -= 10
		if $head.rotation_degrees.y < 0:
			d = 360 + (int($head.rotation_degrees.y) % 360)
		else:
			d = abs(int($head.rotation_degrees.y) % 360)
		if BLOCK:
			var block = BLOCK.instantiate()
			get_tree().current_scene.add_child(block)
			block.global_position = self.global_position
			if cycle == 1:
				if d <= 45 or d >= 315:
					block.position.z -= 1.5
				elif d <= 135 and d > 45:
					block.position.x -= 1.5
					block.rotation_degrees.y = 90
					#block.rotation.y =90
				elif d <= 225 and d > 135:
					block.position.z += 1.5
				elif d < 315 and d > 225:
					block.position.x += 1.5
					block.rotation_degrees.y = 90
			if cycle == 2:
				block.rotation_degrees.x = 90
				if $head.rotation_degrees.x <= 0:
					block.global_position.y -= 1.5
				if $head.rotation_degrees.x > 0:
					block.global_position.y += 1.5
			if cycle == 3:
				block.rotation_degrees.x = 45
				print(d)
				if d <= 45 or d >= 315:
					block.position.z -= 1.5
					block.rotation_degrees.y += 180
				elif d <= 135 and d > 45:
					block.position.x -= 1.5
					block.rotation_degrees.y = 90
					block.rotation_degrees.y += 180
					#block.rotation.y =90
				elif d <= 225 and d > 135:
					block.position.z += 1.5
				elif d < 315 and d > 225:
					block.position.x += 1.5
					block.rotation_degrees.y = 90

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

func handle_controller_camera_movement() -> void:
	if not is_multiplayer_authority(): return
	
	var input_dir: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if input_dir.y < 0 and $head.rotation.x < 1.5:
		$head.rotation.x += abs(input_dir.y) / controller_sensitivity
	if input_dir.y > 0 and $head.rotation.x > -1.5:
		$head.rotation.x -= abs(input_dir.y) / controller_sensitivity
	if input_dir.x < 0:
		$head.rotation.y += abs(input_dir.x) / controller_sensitivity
	if input_dir.x > 0:
		$head.rotation.y -= abs(input_dir.x) / controller_sensitivity
	'''
	if !world.paused:
		parts["head"].rotation_degrees.y -= input_dir
		parts["head"].rotation_degrees.x -= input_dir
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))
	'''

func spawn_fireball():
	var instance = FIREBALL.instantiate()
	instance.position = $head.global_position
	instance.transform.basis = $head.global_transform.basis
	get_parent().add_child(instance)
	get_parent().areas[instance.get_node("Area3D")] = name
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
	get_parent().areas[instance.get_node("Area3D")] = name
	instance.from = from
	instance.add_to_group(from)
	instance.position.y -= 0.3
	instance.get_node("Area3D").add_to_group(from)
	get_parent().add_child(instance)
	rpc("rpc_spawn_lightning", position, basis, rotation)

@rpc func rpc_spawn_lightning(position, basis, rotation):
	var instance = LIGHTNING.instantiate()
	if is_multiplayer_authority():
		instance.global_position = position
	else:
		instance.position = Vector3(0,0,0)
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
	if not is_multiplayer_authority(): 
		return
	'''
	if area.is_in_group("crowbar"):
		var oppressor = area.get_parent().get_parent().get_parent()
		print(oppressor.name + " df")
		oppressor.attacker = $Username.text
		print("hit")
		oppressor.applyDamage(20)
		print(health)
		oppressor.iframes = 20
	'''
	print(str(get_parent().areas.get(area)) + " " + $Username.text)
	print(not(str(get_parent().areas.get(area)) == $Username.text))
	#attacker = str(get_parent().areas.get(area))
	#attacker = str(area.get_parent().get_parent().get_parent().get_node("Username").text)
	if not(str(get_parent().areas.get(area)) == name):
		if area.is_in_group("fireball"):
			attacker = str(get_parent().areas.get(area))
			applyDamage(45)
			#if health <= 0:
			#	get_parent().add_score(attacker.name, name,"fireball")
			#print(get_parent().get_node(other2+"/head/camera").unproject_position(position))
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),45)
			var knockbackForce = 50
			var knockbackDirection = (position - area.get_parent().position).normalized()
			iframes = 20
			area.get_parent().destroy()
			velocity = knockbackDirection * knockbackForce
		if area.is_in_group("lightning"):
			attacker = str(get_parent().areas.get(area))
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),70)
			area.get_parent().destroy()
			applyDamage(70)
			iframes = 20
			area.get_parent().queue_free()
		if area.is_in_group("ice"):
			attacker = str(get_parent().areas.get(area))
			#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),35)
			area.queue_free()
			applyDamage(35)
			iframes = 20
			area.get_parent().queue_free()
		#get_parent().get_node(other2).num(get_parent().get_node(other2+"/head/camera").unproject_position(position),20)

func spawn_ice(position, basis):
	var instance = ICE.instantiate()
	instance.from = from
	instance.position = position
	instance.transform.basis = basis
	get_parent().areas[instance.get_node("Area3D")] = name
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
