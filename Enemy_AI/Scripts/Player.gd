extends KinematicBody

onready var camera = $Head_pivot/Camera

export (float) var gravity = -30
export (float) var max_speed = 5
export (float) var mouse_sensitivity = 0.006  # radians/pixel

var movement_enabled = true
var is_sprinting = false
var velocity = Vector3()

var rng = RandomNumberGenerator.new()
var has_breathed = false

func _ready():
	Globals.player = get_node("../Player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	movement_enabled = true

func _process(delta):
	if !Globals.is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func get_input():
	var input_dir = Vector3()
	# desired move in camera direction
	if movement_enabled:
		if Input.is_action_pressed("forward"):
			input_dir += -global_transform.basis.z
		if Input.is_action_pressed("back"):
			input_dir += global_transform.basis.z
		if Input.is_action_pressed("left"):
			input_dir += -global_transform.basis.x
		if Input.is_action_pressed("right"):
			input_dir += global_transform.basis.x
		input_dir = input_dir.normalized()
		return input_dir
	else:
		input_dir = Vector3(0, 0, 0)
		return input_dir

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Head_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		$Head_pivot.rotation.x = clamp($Head_pivot.rotation.x, -1.2, 1.2)

func _physics_process(delta):
	velocity.y += gravity * delta
	var desired_velocity = get_input() * max_speed

	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true)
