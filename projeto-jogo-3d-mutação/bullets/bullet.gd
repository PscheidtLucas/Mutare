class_name Bullet extends Area3D

@export var player_stats : PlayerStats = null

@export var destroy_at_first: bool = true

var velocity: Vector3 = Vector3.ZERO
var was_shot_from_player: bool = false
var damage: float = 1.0
var _config: RangedWeaponConfig = null


func _ready() -> void:
	GameEvents.wave_survived.connect(func() -> void:
		queue_free())

func _physics_process(delta: float) -> void:
	global_translate(velocity * delta)

# Função de setup, chamada pela arma após a bala ser instanciada na cena.
func initialize(start_position: Vector3, direction: Vector3, config: RangedWeaponConfig, shot_from_player: bool):
	self.global_position = start_position
	self.velocity = direction * config.projectile_speed
	self.damage = config.damage
	_config = config
	
	self.was_shot_from_player = shot_from_player
	look_at(global_position + direction, Vector3.UP)
	# Calcula o tempo de vida com base no alcance e velocidade
	var lifetime = config.range / config.projectile_speed
	
	# Garante que o timer seja criado e conectado de forma segura
	var timer = Timer.new()
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(lifetime)

func _on_body_entered(body: Node3D) -> void:
	# Lógica mantida exatamente como você prefere
	if body is Player and was_shot_from_player:
		return
		
	# Atingiu um inimigo E não foi atirada por um inimigo
	elif body is Enemy and was_shot_from_player:
		if body.has_method("take_damage"):
			calc_player_damage()
			body.take_damage(damage)
		else:
			printerr("Inimigo acertado por bala não tem o método take_damage esperado!")
		if destroy_at_first:
			queue_free()
		return

	# Atingiu o jogador E foi atirada por um inimigo
	elif body is Player and not was_shot_from_player:
		
		## Aumenta o dano conforme o ciclo
		increase_enemy_damage_bullet_based_on_cycle()

		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			printerr("Jogador acertado por bala não tem o método take_damage esperado!")
		queue_free()
		return
	
	# Se colidir com qualquer outra coisa que não seja quem atirou, se destrói
	if body != self and not (body is Player and was_shot_from_player) and not (body is Enemy and not was_shot_from_player):
		queue_free()

# só jogador pode dar critico
func calc_player_damage() -> void:
	if not player_stats:
		printerr("nao identificado player stats na bullet atirada pelo jogador")
		return
	
	## Cálculo do dano:
	damage *= (1 + player_stats.damage_increase)
	
	## Cálculo do crítico:
	if player_stats.crit_chance > 0.0:
		if randf() < player_stats.crit_chance:
			damage *= (1 + player_stats.crit_damage)

func increase_enemy_damage_bullet_based_on_cycle() -> void:
	damage =  min(damage * pow(1.5, GameState.cycle_number - 1), 49)
	printt("Dano do inimigo: ", damage)
