class_name Pistol
extends Weapon

@onready var pistol_timer: Timer = %PistolTimer

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 20.0
@export var bullet_lifetime: float = 2.0
@export var seconds_to_shot: float = 1.0

func _ready() -> void:
	pistol_timer.wait_time = seconds_to_shot
	pistol_timer.timeout.connect(_on_pistol_timer_timeout)

func _on_pistol_timer_timeout() -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Spawna na posição e rotação da pistola
	bullet.global_position = global_position

	# Calcula direção para frente do cano
	var forward := -global_transform.basis.x.normalized()

	# Adiciona velocity como propriedade da bala
	if bullet is Bullet:
		bullet.velocity = forward * bullet_speed
	else:
		bullet.set("velocity", forward * bullet_speed)

	# Configura tempo de vida
	if bullet.has_method("set_lifetime"):
		bullet.set_lifetime(bullet_lifetime)
	
