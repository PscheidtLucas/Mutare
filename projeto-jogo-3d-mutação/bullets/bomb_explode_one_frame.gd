extends Bomb


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true
