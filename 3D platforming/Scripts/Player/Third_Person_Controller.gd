extends KinematicBody

#movement variables
var speed = 5
export (float) var run_speed = 4.5
export (float) var sprint_speed = 7
export (float) var crouch_speed = 1
export (float) var crouch_jump_speed = 12

#acceleration
export (float) var  ACCEL_DEFAULT = 10
export (float) var  ACCEL_AIR = 5
onready var accel = ACCEL_DEFAULT

#jump
export (float) var gravity = 30
export (float) var jump = 15

#physics
var player_velocity
export (int) var inertia = 200
var movement_enabled = true
var gravity_enabled = true
var is_falling
var on_edge

#camera
var cam_accel = 40
export (float) var mouse_sense = 0.1
var snap
var angular_velocity = 15

#Vectors
var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

#references
onready var mesh = $Player_mesh
onready var collider = $CollisionShape
onready var head = $Head
onready var head_pos = head.transform
onready var campivot = $Head/Cam_Pivot
onready var camera = $Head/CamPivot/ClippedCamera

onready var down_edge_ray = $Edge_rays/Down_ray
onready var accros_edge_ray = $Edge_rays/Accros_ray

func _ready():
	#mesh no longer inherits rotation of parent, allowing it to rotate freely
	mesh.set_as_toplevel(true)
	set_process_input(true)

func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(delta):
	if !Globals.is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#turns body in the direction of movement
	if direction != Vector3.ZERO:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(-direction.x, -direction.z), angular_velocity * delta)
	
	#walk/run/crouch
	if Input.is_action_pressed("run") and is_on_floor():
		scale.y = 1
		speed = sprint_speed
	elif Input.is_action_pressed("crouch") and is_on_floor():
		scale.y = 1
		speed = crouch_speed
	elif is_on_floor():
		scale.y = 1
		speed = run_speed
	else:
		scale.y = 1
	
	if movement.y < -0.1:
		is_falling = true
	elif movement.y > -0.1:
		is_falling = false
	
	physics_interpolation(delta)
	edge_detection()

func _physics_process(delta):
	movement(delta)

func physics_interpolation(delta):
	#physics interpolation to reduce jitter on high refresh-rate monitors
	var fps = Engine.get_frames_per_second()
	if fps > Engine.iterations_per_second:
		campivot.set_as_toplevel(true)
		campivot.global_transform.origin = campivot.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		campivot.rotation.y = rotation.y
		campivot.rotation.x = head.rotation.x
		mesh.global_transform.origin = mesh.global_transform.origin.linear_interpolate(global_transform.origin, cam_accel * delta)
	else:
		campivot.set_as_toplevel(false)
		campivot.global_transform = head.global_transform
		mesh.global_transform.origin = global_transform.origin

func movement(delta):
	#get keyboard input
	direction = Vector3.ZERO
	if !on_edge:
		var h_rot = global_transform.basis.get_euler().y
		var f_input = Input.get_action_strength("back") - Input.get_action_strength("forward")
		var h_input = Input.get_action_strength("right") - Input.get_action_strength("left")
		direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	elif is_on_ceiling():
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
		
	#jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Input.is_action_pressed("crouch"):
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	#crouch jump
	elif Input.is_action_just_pressed("jump") and is_on_floor() and Input.is_action_pressed("crouch"):
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
		speed = crouch_jump_speed
	
	#on edge
	if on_edge:
		gravity_enabled = false
	else:
		gravity_enabled = true
	
	#make it move#
	if movement_enabled:
		velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	
	if gravity_enabled:
		movement = velocity + gravity_vec
	else:
		movement = velocity
	
	move_and_slide_with_snap(movement, snap, Vector3.UP ,false, 4, PI/4, false)
	
	#Rigidbody collisions
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group("Bodies"):
			collision.collider.apply_central_impulse(-collision.normal * inertia)

func edge_detection():
	var down_ray_pos
	var accros_ray_pos
	
	if is_falling:
		down_edge_ray.enabled = true
	else:
		down_edge_ray.enabled = false
	
	if down_edge_ray.is_colliding() and !on_edge:
		accros_ray_pos = accros_edge_ray.get_collision_point()
		down_ray_pos = down_edge_ray.get_collision_point()
		
		translation = accros_ray_pos
		translation.y = down_ray_pos.y
		#look_at(Vector3(pos_x, pos_y, pos_z), Vector3.UP)
		on_edge = true
	
	if on_edge && Input.is_action_just_pressed("jump"):
		gravity_vec = Vector3.UP * jump
		on_edge = false
