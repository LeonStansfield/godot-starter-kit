extends Camera

#camera shake
onready var initial_rotation = rotation_degrees as Vector3

var trauma = 0
var time = 0
export (float) var trauma_reduction_rate = 0.9

export var noise : OpenSimplexNoise
export var noise_speed = 50

export var max_x = 10
export var max_y = 10
export var max_z = 5

func _ready():
	Globals.Camera = get_node("../Camera")

func _process(delta):
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0)
	
	rotation_degrees.x = initial_rotation.x + max_x * get_shake_intensity() * get_noise_from_seed(1)
	rotation_degrees.y = initial_rotation.y + max_x * get_shake_intensity() * get_noise_from_seed(0)
	rotation_degrees.z = initial_rotation.z + max_x * get_shake_intensity() * get_noise_from_seed(2)

func _physics_process(delta):
	trauma = max(trauma - delta * trauma_reduction_rate, 0)

func add_trauma(trauma_amount : float):
	trauma = clamp(trauma + trauma_amount, 0, 1)
	print(trauma)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed : int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)
