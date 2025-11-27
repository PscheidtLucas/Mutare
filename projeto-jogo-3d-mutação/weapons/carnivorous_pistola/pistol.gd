class_name Pistol
extends BaseWeapon

const PISTOL = preload("uid://dlrhjlekwwsew")

func _fire()-> void:
	AudioManager.play_sfx(PISTOL, -20, 1.5, 0.3)
	super()
	
