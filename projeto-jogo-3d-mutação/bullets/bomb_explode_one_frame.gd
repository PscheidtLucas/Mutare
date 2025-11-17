extends Bomb


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
	await get_tree().create_timer(0.6).timeout
	queue_free()
