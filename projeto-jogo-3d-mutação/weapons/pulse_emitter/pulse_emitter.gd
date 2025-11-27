extends BaseWeapon

const PULSE_EMITTER = preload("uid://bexc62uo28b3a")


func _fire() -> void:
	AudioManager.play_sfx(PULSE_EMITTER, -18)
	super()
	
