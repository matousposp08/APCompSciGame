extends CharacterBody3D


@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var base_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.5
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0
var hits = false
var x = 0

var FIREBALL : PackedScene = preload('res://scenes/player/fireball.tscn')
var LIGHTNING : PackedScene = preload('res://scenes/player/lightning.tscn')
var BLOCK: PackedScene = preload('res://scenes/player/vertical_block.tscn')
var instance

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
var isMoving = false


func _ready() -> void:
	$head/crowbar/Area3D/CollisionShape3D.disabled = false
	parts["camera"].current = true

func _process(delta: float) -> void:
	handle_movement_input(delta)
	update_camera(delta)
	hit()
	#build()
	fireball()
	#lightning()
	if Input.is_action_pressed("move_forward"):
		if not isMoving:
			isMoving = true
			$head/camera/camera_animation.play("head_bob")
	else:
		if isMoving:
			isMoving = false
			$head/camera/camera_animation.stop()

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
	x -= 1
	if x <= 0:
		hits = false
		$head/crowbar/Area3D/CollisionShape3D.disabled = true
		
	if Input.is_action_pressed("hit") and not(hits):
		hits = true
		$head/crowbar/Area3D/CollisionShape3D.disabled = false
		$head/crowbar/AnimationPlayer.play("hit1")
		x = 60
	
	

func build() -> void:
	if Input.is_action_just_pressed("build"):
		if BLOCK:
			var block = BLOCK.instantiate()
			get_tree().current_scene.add_child(block)
			block.global_position = self.global_position
			print($head.rotation_degrees.y)
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
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector2 = input_dir.normalized().rotated(-parts["head"].rotation.y)
	#if is_on_floor():
	velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, direction.y * speed, accel * delta)
	move_and_slide()


func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	if !world.paused:
		parts["head"].rotation_degrees.y -= event.relative.x * sensitivity
		parts["head"].rotation_degrees.x -= event.relative.y * sensitivity
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))

func fireball() -> void:
	if Input.is_action_just_pressed("magic"):
		instance = FIREBALL.instantiate()
		instance.position = $head.global_position
		instance.transform.basis = $head.global_transform.basis
		get_parent().add_child(instance)
		
func lightning() -> void:
	if Input.is_action_just_pressed("magic"):
		instance = LIGHTNING.instantiate()
		instance.position = $head.global_position
		instance.transform.basis = $head.global_transform.basis
		get_parent().add_child(instance)

func _on_area_3d_area_entered(area):
	if area.is_in_group("fireball"):
		var x = position - area.get_parent().position
		velocity = 15*(x/x.length())
