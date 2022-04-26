extends Spatial

var last_seen_coords
onready var Enemy = get_parent().get_node("Enemy")

func _ready():
	last_seen_coords = Vector3(0, 0, 0)

func _process(delta):
	if Enemy.player_seen == true:
		global_transform.origin = Globals.player.global_transform.origin
		last_seen_coords = Globals.player.global_transform.origin
		print (Globals.player.global_transform.origin)
		print (last_seen_coords)
	else:
		translation = last_seen_coords


func _on_Area_body_entered(body):
	if body.is_in_group("Enemy"):
		Enemy.reached_last_seen_pos = true

func _on_Area_body_exited(body):
	if body.is_in_group("Enemy"):
		Enemy.reached_last_seen_pos = false
