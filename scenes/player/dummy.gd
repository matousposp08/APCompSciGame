extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var health = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


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
		print(int(3*(abs(1/(position.x-area.get_parent().position.x))+abs(1/(position.y-area.get_parent().position.y))+abs(1/(position.z-area.get_parent().position.z))/3)))
		health -= int(3*(abs(1/(position.x-area.get_parent().position.x))+abs(1/(position.y-area.get_parent().position.y))+abs(1/(position.z-area.get_parent().position.z))/3))
		var x = position - area.get_parent().position
		print(100*(x/x.length()))
		velocity = 50*(x/x.length())
	if area.is_in_group("crowbar"):
		print("hit")
		health -= 20
		var x = position - area.get_parent().position
		velocity = 30*(x/x.length())
		
