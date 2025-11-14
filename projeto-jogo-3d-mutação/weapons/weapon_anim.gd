class_name WeaponAnim extends AnimationPlayer

@export var weapon: BaseWeapon

func _ready() -> void:
	weapon.shot_emitted.connect(func() -> void:
		stop(false)
		play("shoot"))
