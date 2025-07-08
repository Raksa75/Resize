extends CharacterBody3D

@export var speed := 5.0
@export var crouch_speed := 2.0
@export var mouse_sensitivity := 0.1
@export var gravity := 12.0
@export var jump_velocity := 7.0

@export var crouch_height := 1.0  # Hauteur du capsule accroupi
@export var stand_height := 1.8   # Hauteur du capsule debout
@export var crouch_camera_y := 0.4 # Y caméra accroupi
@export var stand_camera_y := 0.8  # Y caméra debout

var rotation_x := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		$Camera3D.rotation.x = rotation_x

func can_stand_up() -> bool:
	var collider = $CollisionShape3D.shape
	var current_height = collider.height
	var stand_diff = stand_height - current_height
	if stand_diff < 0.01:
		return true # Déjà debout
	var up = Vector3.UP * (stand_diff * 0.5)
	return not test_move(global_transform, up)

func _physics_process(_delta):
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	direction.y = 0
	direction = direction.normalized()

	# Crouch logic
	var is_crouching = Input.is_action_pressed("crouch")
	var current_speed = crouch_speed if is_crouching else speed
	
	var wants_to_stand = not Input.is_action_pressed("crouch")
	var can_stand = can_stand_up()

	var target_height : float
	var target_cam_y : float

	if wants_to_stand and can_stand:
		# Autorisé à se relever, on lerp vers debout
		target_height = stand_height
		target_cam_y = stand_camera_y
	elif wants_to_stand and not can_stand:
		# On veut se relever mais plafond : on force accroupi
		target_height = crouch_height
		target_cam_y = crouch_camera_y
	else:
		# On veut rester accroupi
		target_height = crouch_height
		target_cam_y = crouch_camera_y
	
	$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, target_height, 0.2)
	$Camera3D.position.y = lerp($Camera3D.position.y, target_cam_y, 0.2)
	
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Gravité
	if not is_on_floor():
		velocity.y -= gravity * _delta
	else:
		velocity.y = 0.0

	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
