extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var health = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@rpc func rpc_update_health(new_health: int):
	health = new_health

func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	if health <= 0:
		queue_free()


func _on_area_3d_area_entered(area):
	print(area)
	if area.is_in_group("fireball"):
		health -= 45
		print(get_parent().get_node("1/head/camera").unproject_position(position))
		get_parent().get_node("1").num(get_parent().get_node("1/head/camera").unproject_position(position),45)
		var knockbackForce = 50
		var knockbackDirection = (position - area.get_parent().position).normalized()
		area.queue_free()
		velocity = knockbackDirection * knockbackForce
	if area.is_in_group("crowbar"):
		get_parent().get_node("1").num(get_parent().get_node("1/head/camera").unproject_position(position),20)
		print("hit")
		health -= 20
		var x = position - area.get_parent().position
		velocity = 30*(x/x.length())
	if area.is_in_group("lightning"):
		get_parent().get_node("1").num(get_parent().get_node("1/head/camera").unproject_position(position),70)
		health -= 70
		area.queue_free()
	if area.is_in_group("ice"):
		get_parent().get_node("1").num(get_parent().get_node("1/head/camera").unproject_position(position),35)
		health -= 35
		area.queue_free()
	print(get_parent().get_node("1/head/camera"))
