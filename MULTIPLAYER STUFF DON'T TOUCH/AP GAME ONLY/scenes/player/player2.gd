extends CharacterBody3D

@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var body = $body
@onready var collision = $CollisionShape3D
@onready var base_speed: float = 5.0

var speed: float = base_speed
var sprint_speed: float = 8.0
var crouch_speed: float = 3.0
const JUMP_VELOCITY: float = 10.0
var hits = false
var x = 0

var gravity = 20.0

var state: String = "normal"  
var camera_fov_extents: Array[float] = [75.0, 85.0] 
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _process(delta: float) -> void:
	handle_movement_input(delta)
	update_camera(delta)
	hit()
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	apply_gravity(delta)
	

	# Handle Jump.
	handle_jump()
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	move_character(delta)

	move_and_slide()

func handle_jump() -> void:
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func apply_gravity(delta: float) -> void:
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= gravity * delta

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

func handle_movement_input(delta: float) -> void:
	if Input.is_action_pressed("move_sprint") and !Input.is_action_pressed("move_crouch") and sprint_enabled:
		if !$crouch_roof_detect.is_colliding(): 
			enter_sprint_state(delta)
	elif Input.is_action_pressed("move_crouch") and !Input.is_action_pressed("move_sprint") and crouch_enabled:
		enter_crouch_state(delta)
	else:
		if !$crouch_roof_detect.is_colliding():
			enter_normal_state(delta)
			
func enter_sprint_state(delta: float) -> void:
	state = "sprinting"
	speed = sprint_speed
	camera.fov = lerp(camera.fov, camera_fov_extents[1], 10 * delta)

func enter_crouch_state(delta: float) -> void:
	state = "crouching"
	speed = crouch_speed
	apply_crouch_transform(delta)
	
func enter_normal_state(delta: float) -> void:
	state = "normal"
	speed = base_speed
	reset_transforms(delta)

func update_camera(delta: float) -> void:
	match state:
		"sprinting":
			camera.fov = lerp(camera.fov, camera_fov_extents[1], 10 * delta)
		"normal":
			camera.fov = lerp(camera.fov, camera_fov_extents[0], 10 * delta)

func apply_crouch_transform(delta: float) -> void:
	body.scale.y = lerp(body.scale.y, crouch_player_y_scale, 10 * delta)
	collision.scale.y = lerp(collision.scale.y, crouch_player_y_scale, 10 * delta)
	
func reset_transforms(delta: float) -> void:
	body.scale.y = lerp(body.scale.y, base_player_y_scale, 10 * delta)
	collision.scale.y = lerp(collision.scale.y, base_player_y_scale, 10 * delta)

func hit() -> void:
	if not is_multiplayer_authority(): return
	x -= 1
	if x <= 0:
		hits = false
		$Camera3D/crowbar/Area3D/CollisionShape3D.disabled = true
	if Input.is_action_pressed("hit") and not(hits):
		print(Input.is_action_pressed("hit"))
		hits = true
		$Camera3D/crowbar/Area3D/CollisionShape3D.disabled = false
		$Camera3D/crowbar/AnimationPlayer.play("hit1")
		x = 60
