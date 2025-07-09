extends CharacterBody3D

@export var speed := 5.0
@export var crouch_speed := 2.0
@export var mouse_sensitivity := 0.1
@export var gravity := 12.0
@export var jump_velocity := 7.0

@export var crouch_camera_y := 0.4
@export var stand_camera_y := 0.8

var rotation_x := 0.0
var is_crouched := false
var camera_target_y := stand_camera_y

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_crouch(false)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		$Camera3D.rotation.x = rotation_x

func set_crouch(state : bool):
	is_crouched = state
	$CollisionShape3D_Standing.disabled = state
	$CollisionShape3D_Crouched.disabled = not state
	camera_target_y = crouch_camera_y if state else stand_camera_y

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

	var current_speed = crouch_speed if is_crouched else speed

	# Crouch logique avec RayCast3D plafond
	if Input.is_action_pressed("crouch"):
		set_crouch(true)
	elif is_crouched:
		if not $RayCeiling.is_colliding():
			set_crouch(false)
		# sinon reste accroupi

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

	# Animation douce caméra
	$Camera3D.position.y = lerp($Camera3D.position.y, camera_target_y, 0.2)
