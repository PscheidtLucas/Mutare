class_name Bullet extends Area3D

var damage := 1
var velocity: Vector3 = Vector3.ZERO
var lifetime: float = 2.0
var origin = null

var was_shot_from_player: bool = false

func _physics_process(delta: float) -> void:
	global_translate(velocity * delta)


func _on_body_entered(body: Node3D) -> void:
	if body is Enemy or body is Player:
		if body is Player and was_shot_from_player:
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
			call_deferred("queue_free")
	else:
		print("body entered")
		call_deferred("queue_free")


func set_lifetime(new_lifetime) -> void:
	lifetime = new_lifetime
	await get_tree().create_timer(lifetime).timeout
	call_deferred("queue_free")
