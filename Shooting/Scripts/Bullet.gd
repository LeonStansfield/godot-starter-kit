extends Area

signal exploded

export var muzzle_velocity = 75
export var g = Vector3.DOWN * 0

var velocity = Vector3.ZERO

export (PackedScene) var Bullet_hit
export (PackedScene) var Small_explosion

func _ready():
	yield(get_tree().create_timer(3), "timeout")
	queue_free()

func _physics_process(delta):
	velocity += g * delta
	look_at(transform.origin + velocity.normalized(), Vector3.UP)
	transform.origin += velocity * delta

func _on_Bullet_body_entered(body):
	velocity = Vector3.ZERO
	if body.is_in_group("Enemy"):
		body.hit()
		#that enemies health - 1
	emit_signal("exploded", transform.origin)
	queue_free()
	

func _on_Bullet_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	velocity = Vector3.ZERO
	emit_signal("exploded", transform.origin)
	queue_free()


#shoot code
	#var b = Bullet.instance()
	#get_parent().add_child(b)
	#b.transform = $Turret/fire_point.global_transform
	#b.velocity = -b.transform.basis.z * b.muzzle_velocity
	#$Audio/Gunshot_sfx.play()
