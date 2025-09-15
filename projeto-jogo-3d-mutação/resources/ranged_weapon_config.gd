extends Resource
class_name Ragend_Weapon_Config

@export var name: String

@export var damage_min: int
@export var damage_max: int
@export var fire_rate_min: float
@export var fire_rate_max: float
@export var accuracy_min: float
@export var accuracy_max: float

@export var number_of_projectiles: int
@export var range: float
@export var projectile_speed: float

@export var model: PackedScene

var damage: int
var fire_rate: float
var accuracy: float

func roll_stats(scale: float = 1.0) -> void:
	damage = randi_range(damage_min, damage_max) * scale
	fire_rate = randf_range(fire_rate_min, fire_rate_max) / scale
	accuracy = randf_range(accuracy_min, accuracy_max) * scale
