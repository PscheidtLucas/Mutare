extends BaseWeapon

const PISTOL_SOUND__1_ = preload("uid://c4n8ngm8u0vkh")

func _fire() -> void:
	super()
	AudioManager.play_sfx(PISTOL_SOUND__1_, -10.2, 2.5, .3)
