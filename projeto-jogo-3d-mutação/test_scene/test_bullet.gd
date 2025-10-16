# Bullet.gd (versão atualizada com suas preferências)
class_name BulletTest extends Area3D

var velocity: Vector3 = Vector3.ZERO
var was_shot_from_player: bool = false
var damage: float = 1.0

func _physics_process(delta: float) -> void:
	global_translate(velocity * delta)

# Função de setup, chamada pela arma após a bala ser instanciada na cena.
func initialize(start_position: Vector3, direction: Vector3, config: RangedWeaponConfig, shot_from_player: bool):
	self.global_position = start_position
	self.velocity = direction * config.projectile_speed
	self.damage = config.damage
	self.was_shot_from_player = shot_from_player
	
	# Calcula o tempo de vida com base no alcance e velocidade
	var lifetime = config.range / config.projectile_speed
	
	# Garante que o timer seja criado e conectado de forma segura
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _on_body_entered(body: Node3D) -> void:
	# Lógica mantida exatamente como você prefere
	if body is Player and was_shot_from_player:
		return
		
	# Atingiu um inimigo E não foi atirada por um inimigo
	elif body is Enemy and was_shot_from_player:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			printerr("Inimigo acertado por bala não tem o método take_damage esperado!")
		queue_free()
		return

	# Atingiu o jogador E foi atirada por um inimigo
	elif body is Player and not was_shot_from_player:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			printerr("Jogador acertado por bala não tem o método take_damage esperado!")
		queue_free()
		return
	
	# Se colidir com qualquer outra coisa que não seja quem atirou, se destrói
	if body != self and not (body is Player and was_shot_from_player) and not (body is Enemy and not was_shot_from_player):
		print("Bala colidiu com qualquer outra coisa e se destruiu!")
		queue_free()
