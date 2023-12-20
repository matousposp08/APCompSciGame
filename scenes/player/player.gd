extends CharacterBody3D


@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var base_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0

var BLOCK: PackedScene = preload('res://scenes/player/vertical_block.tscn')

var speed: float = base_speed
var state: String = "normal"  
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_fov_extents: Array[float] = [75.0, 85.0] 
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75


@onready var parts: Dictionary = {
	"head": $head,
	"camera": $head/camera,
	"camera_animation": $head/camera/camera_animation,
	"body": $body,
	"collision": $collision
}
@onready var world: SceneTree = get_tree()

func _ready() -> void:
	parts["camera"].current = true

func _process(delta: float) -> void:
	handle_movement_input(delta)
	update_camera(delta)
	hit()
	build()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	move_character(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_movement(event)


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
	parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)

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
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)
		"normal":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[0], 10 * delta)


func apply_crouch_transform(delta: float) -> void:
	parts["body"].scale.y = lerp(parts["body"].scale.y, crouch_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, crouch_player_y_scale, 10 * delta)

func reset_transforms(delta: float) -> void:
	parts["body"].scale.y = lerp(parts["body"].scale.y, base_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, base_player_y_scale, 10 * delta)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity

func hit() -> void:
	if Input.is_action_pressed("hit"):
		$head/katana/AnimationPlayer.play("k1")
		$head/katana2/AnimationPlayer.play("k2")
		$head/GUN/AnimationPlayer.play("SPIN")
		$head/gun/AnimationPlayer.play("shot")
	if Input.is_action_pressed("hit2"):
		$head/katana2/AnimationPlayer.play("k2")


func build() -> void:
	if Input.is_action_just_pressed("build"):
		print("pluh")
		if BLOCK:
			print("bluh")
			var block = BLOCK.instantiate()
			get_tree().current_scene.add_child(block)
			block.global_position = self.global_position
			block.position.x += 5
			block.position.z += 5

func move_character(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector2 = input_dir.normalized().rotated(-parts["head"].rotation.y)
	if is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.y * speed, accel * delta)
	move_and_slide()


func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	if !world.paused:
		parts["head"].rotation_degrees.y -= event.relative.x * sensitivity
		parts["head"].rotation_degrees.x -= event.relative.y * sensitivity
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))
