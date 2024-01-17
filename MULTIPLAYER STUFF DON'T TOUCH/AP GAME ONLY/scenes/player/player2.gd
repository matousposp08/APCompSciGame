extends CharacterBody3D

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer

const SPEED = 10.0
const JUMP_VELOCITY = 10.0

var gravity = 20.0

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
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
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
