extends CharacterBody3D

@export var speed := 5.0
@export var crouch_speed := 2.0
@export var mouse_sensitivity := 0.1
@export var gravity := 12.0
@export var jump_velocity := 7.0

@export var crouch_camera_y := 0.4
@export var stand_camera_y := 0.8
@export var carry_range := 3.0  # Distance max pour attraper un objet

var rotation_x := 0.0
var is_crouched := false
var camera_target_y := stand_camera_y

var carried_object : RigidBody3D = null
var carried_object_last_valid_pos : Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_crouch(false)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity * 0.01)
		rotation_x -= event.relative.y * mouse_sensitivity * 0.01
		rotation_x = clamp(rotation_x, deg_to_rad(-90), deg_to_rad(90))
		$Camera3D.rotation.x = rotation_x

	if event.is_action_pressed("interact"):
		if carried_object:
			carried_object.set("mode", 0) # 0 = RIGID
			carried_object = null
		else:
			var from = $Camera3D.global_transform.origin
			var to = from + -$Camera3D.global_transform.basis.z * carry_range
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collide_with_areas = false
			query.exclude = [self]
			var result = space_state.intersect_ray(query)
			if result and result.collider is RigidBody3D:
				carried_object = result.collider
				carried_object.set("mode", 2) # 2 = KINEMATIC
				carried_object_last_valid_pos = carried_object.global_transform.origin

func set_crouch(state : bool):
	is_crouched = state
	$CollisionShape3D_Standing.disabled = state
	$CollisionShape3D_Crouched.disabled = not state
	camera_target_y = crouch_camera_y if state else stand_camera_y

func _physics_process(delta):
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
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Crouch logique avec RayCast3D plafond
	if Input.is_action_pressed("crouch"):
		set_crouch(true)
	elif is_crouched:
		if not $RayCeiling.is_colliding():
			set_crouch(false)

	# Gravité
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# Animation douce caméra
	$Camera3D.position.y = lerp($Camera3D.position.y, camera_target_y, 0.2)

	# Placement avancé de l'objet porté (shape cast et mémorisation dernière position valide)
	if carried_object:
		var anchor_pos = $Camera3D/CarryAnchor.global_transform.origin
		var space_state = get_world_3d().direct_space_state
		var found_shape = false

		for c in carried_object.get_children():
			if c is CollisionShape3D and c.shape is BoxShape3D:
				var shape_query = PhysicsShapeQueryParameters3D.new()
				shape_query.shape = c.shape
				shape_query.transform = Transform3D(Basis(), anchor_pos)
				shape_query.collision_mask = carried_object.collision_mask
				shape_query.exclude = [self, carried_object]
				var collisions = space_state.intersect_shape(shape_query)
				if collisions.size() == 0:
					# Aucun obstacle, avance vers l'anchor et mémorise cette position
					carried_object.global_transform.origin = carried_object.global_transform.origin.lerp(anchor_pos, 0.5)
					carried_object_last_valid_pos = carried_object.global_transform.origin
				else:
					# Collision : reste parfaitement à la dernière position valide
					carried_object.global_transform.origin = carried_object_last_valid_pos
				carried_object.global_transform.basis = Basis()
				carried_object.linear_velocity = Vector3.ZERO
				carried_object.angular_velocity = Vector3.ZERO
				found_shape = true
				break

		if not found_shape:
			carried_object.global_transform.origin = carried_object.global_transform.origin.lerp(anchor_pos, 0.5)
			carried_object_last_valid_pos = carried_object.global_transform.origin
			carried_object.global_transform.basis = Basis()
			carried_object.linear_velocity = Vector3.ZERO
			carried_object.angular_velocity = Vector3.ZERO
