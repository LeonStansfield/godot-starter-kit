extends KinematicBody

#movement vars
export (float) var speed = 1.5
export (float) var accel = 1.5
var rotation_speed = 1
var velocity = Vector3.ZERO
var direction
var movement = Vector3()

#target vars
onready var Last_seen_pos = get_parent().get_node("Last_seen_pos")
export var reached_last_seen_pos = false

#state machine vars
export var player_seen = false
var player_seen_recently
var player_in_line
var player_in_fov
var player_in_sound_range
var attack

var not_seen_started #runs for one frame when player is out of vision

#enabled
var enabled = true

#pathfinding
var path = []
var path_node = 0
var target = null
var threshold = 0.1
onready var nav = get_node("../../")

#vision
onready var raycast = $RayCast

#RNG
var rng = RandomNumberGenerator.new()

func _process(delta):
	if enabled:
		look_at(global_transform.origin - Vector3(velocity.x, 0, velocity.z).normalized(), Vector3.UP)
		vision()
		ray_collision()
		states(delta)
		
		#triggers weather player has been seen recently or not
		if player_seen:
			not_seen_started = false
			player_seen_recently = true
		elif not_seen_started == false and reached_last_seen_pos:
			player_not_seen()

func states(delta):
	if !player_seen_recently and !attack:
		print("idle")
		#idle
		
	if (player_seen_recently and player_seen and !attack) || player_in_sound_range:
		move_to_target(delta)
		#chase
	
	if player_seen_recently and !reached_last_seen_pos and !attack:
		move_to_target(delta)
		#chase
		
	if player_seen_recently and reached_last_seen_pos and !attack:
		pass
		#search
		
	elif attack:
		pass
		#attack

func vision(): #Checks if the player is seen or not
	if player_in_line and player_in_fov:
		player_seen = true
	else:
		player_seen = false

func ray_collision(): #Checks ray for collisions
	#Detects what ray is colliding with
	var collision_object = raycast.get_collider()
	if collision_object != null:
		if collision_object.is_in_group("Player"):
			player_in_line = true
		else:
			player_in_line = false
	else:
		player_in_line = false

func move_to_target(delta): #Moves to the target
	if path_node >= path.size(): #sets velocity to 0 if no target for animations
		velocity = Vector3(0,0,0)
		return
	
	#checks if distance to next node is larger than threshhold
	if path_node < path.size():
		var direction = (path[path_node] - global_transform.origin)
		if direction.length() < 1:
			path_node += 1
		else:
			velocity = velocity.linear_interpolate(direction.normalized() * speed, accel * delta)
			move_and_slide(velocity, Vector3.UP)

func player_not_seen():
	not_seen_started = true
	yield(get_tree().create_timer(5), "timeout")
	print("not seen recently")
	player_seen_recently = false

#Uses Ger_simple_path to get the path to the target
func get_target_path(target_pos):
	path = nav.get_simple_path(global_transform.origin, target_pos)
	path_node = 0

#Updates the pathfinding path every second
func _on_Nav_timer_timeout():
	print("target path made")
	get_target_path(Last_seen_pos.global_transform.origin)
	
	if direction == null:
		direction = Vector3(0,0,0)

#Checks if player is inside the FOV of enemy
func _on_FOV_body_entered(body):
	if body.is_in_group("Player"):
		print("player in fov")
		player_in_fov = true
		
#Checks if player is inside the FOV of enemy
func _on_FOV_body_exited(body):
	if body.is_in_group("Player"):
		print("player out of fov")
		player_in_fov = false


func _on_Sound_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_sound_range = true


func _on_Sound_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_sound_range = false
