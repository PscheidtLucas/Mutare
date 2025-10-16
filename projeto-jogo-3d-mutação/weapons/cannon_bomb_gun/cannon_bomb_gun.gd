class_name CannonBombGun
extends BaseWeapon

@onready var tip_of_cannon: Marker3D = %TipOfCannon

@export_group("Cannon Stats")
@export var launch_angle_degrees: float = 60.0 # Ângulo de lançamento em graus


# Sobrescreve a função _fire para lançar a bomba em um arco.
func _fire() -> void:
	super._fire() # A função base já cuida de instanciar a bomba.
	if projectile is Bomb:
		var bomb = projectile

		# Converte o ângulo para radianos uma vez.
		var launch_angle_rad = deg_to_rad(launch_angle_degrees)

		# 1. Calcula a velocidade das componentes horizontal e vertical.
		# Cosseno para a componente adjacente (horizontal).
		var horizontal_speed = cos(launch_angle_rad) * projectile_speed
		# Seno para a componente oposta (vertical).
		var vertical_speed = sin(launch_angle_rad) * projectile_speed

		# 2. Calcula os vetores de velocidade.
		# A velocidade horizontal aponta para a frente da arma (-X).
		var horizontal_velocity = -global_transform.basis.x.normalized() * horizontal_speed
		
		# A velocidade vertical aponta para CIMA no mundo (importante para a gravidade).
		var vertical_velocity = Vector3.UP * vertical_speed

		# 3. A velocidade final é a soma das duas.
		bomb.linear_velocity = horizontal_velocity + vertical_velocity
		
		# Garante que a bomba comece na ponta do canhão.
		bomb.global_position = tip_of_cannon.global_position
		
		if bomb.has_method("set_lifetime"):
			bomb.set_lifetime(projectile_lifetime)
