extends BaseWeapon

const SHOTGUN = preload("uid://bqlbxkqkcyrjb")

# Called when the node enters the scene tree for the first time.
func _fire() -> void:
	AudioManager.play_sfx(SHOTGUN, -18, 0.8, 0.25)
	super()
	
