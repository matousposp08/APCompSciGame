extends CharacterBody3D

@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0

var magic = false
var mode = 0
var hits = false
var mana = 100
var x = 0

var FIREBALL : PackedScene = preload('res://scenes/player/fireball.tscn')
var LIGHTNING : PackedScene = preload('res://scenes/player/lightning.tscn')
var BLOCK: PackedScene = preload('res://scenes/player/vertical_block.tscn')
var instance

var base_speed: float = 5.0
var state: String = "normal"  
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_fov_extents: Array[float] = [75.0, 85.0] 
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var body = $body
@onready var collision = $CollisionShape3D

@onready var world: SceneTree = get_tree()

var speed: float = base_speed
var isMoving = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	if not is_multiplayer_authority(): return
	
	$Camera3D/crowbar/Area3D/CollisionShape3D.disabled = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("magic"):
		#if not(magic):
			#magic = true
		#else:
			#if mode == 1:
				#mode = 0
			#else:
				#mode = 1
	if Input.is_action_just_pressed("melee"):
		magic = false
	handle_movement_input(delta)
	update_camera(delta)
	hit()
	#fireball()
	#lightning()
	#build()
	#if Input.is_action_pressed("move_forward"):
	#	if not isMoving:
	#		isMoving = true
	#		$head/camera/camera_animation.play("head_bob")
	#else:
	#	if isMoving:
	#		isMoving = false
	#		$head/camera/camera_animation.stop()
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	apply_gravity(delta)
	handle_jump()
	move_character(delta)
	
	move_and_slide()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#handle_mouse_movement(event)

func handle_movement_input(delta: float) -> void:
	if not is_multiplayer_authority(): return
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
	camera.fov = lerp(camera.fov, camera_fov_extents[1], 10 * delta)
	
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
			camera.fov = lerp(camera.fov, camera_fov_extents[1], 10 * delta)
		"normal":
			camera.fov = lerp(camera.fov, camera_fov_extents[0], 10 * delta)
			
func apply_crouch_transform(delta: float) -> void:
	if not is_multiplayer_authority(): return
	body.scale.y = lerp(body.scale.y, crouch_player_y_scale, 10 * delta)
	collision.scale.y = lerp(collision.scale.y, crouch_player_y_scale, 10 * delta)
	
func reset_transforms(delta: float) -> void:
	if not is_multiplayer_authority(): return
	body.scale.y = lerp(body.scale.y, base_player_y_scale, 10 * delta)
	collision.scale.y = lerp(collision.scale.y, base_player_y_scale, 10 * delta)
	
func apply_gravity(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= gravity * delta	

func handle_jump() -> void:
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity

func hit() -> void:
	if not is_multiplayer_authority(): return
	x -= 1
	if x <= 0:
		hits = false
		$Camera3D/crowbar/Area3D/CollisionShape3D.disabled = true
		
	if Input.is_action_pressed("hit") and not(hits) and not(magic):
		print(Input.is_action_pressed("hit"))
		hits = true
		$Camera3D/crowbar/Area3D/CollisionShape3D.disabled = false
		$Camera3D/crowbar/AnimationPlayer.play("hit1")
		x = 60

#func build() -> void:
	#if Input.is_action_just_pressed("build"):
		#if BLOCK:
			#var block = BLOCK.instantiate()
			#get_tree().current_scene.add_child(block)
			#block.global_position = self.global_position
			#print($head.rotation_degrees.y)
			#if $head.rotation_degrees.y < 45 or $head.rotation_degrees.y > 314:
				#block.position.z -= 5
			#elif $head.rotation_degrees.y < 135 or $head.rotation_degrees.y > 44:
				#block.position.x -= 5
				#block.rotation.y =90
			#elif $head.rotation_degrees.y < 225 or $head.rotation_degrees.y > 134:
				#block.position.z += 5
			#elif $head.rotation_degrees.y < 315 or $head.rotation_degrees.y > 224:
				#block.position.x += 5
				#block.rotation.y =90

func move_character(delta: float) -> void:
	if not is_multiplayer_authority: return
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


#This is basically handle mouse movement
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

#func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	#if !world.paused:
		#camera.rotation_degrees.y -= event.relative.x * sensitivity
		#camera.rotation_degrees.x -= event.relative.y * sensitivity
		#camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
func fireball() -> void:
	if Input.is_action_just_pressed("hit") and magic and mode == 1:
		instance = FIREBALL.instantiate()
		instance.position = $".".global_position
		instance.transform.basis = $".".global_transform.basis
		get_parent().add_child(instance)
	if Input.is_action_just_pressed("magic") and mana >= 10:
		mana -= 10
		instance = FIREBALL.instantiate()
		instance.position = $".".global_position
		instance.transform.basis = $".".global_transform.basis
		get_parent().add_child(instance)

