extends RayCast

onready var Enemy = get_parent()

func _process(delta):
	if Enemy.enabled:
		set_cast_to(to_local(Globals.player.global_transform.origin))
		force_raycast_update()
