class_name DnaDetectionArea extends Area3D

var player : Player = null
var should_move_to_player : bool = false
const _distance_to_disapear = 0.5 ## Aumentei um pouco para garantir que coleta antes de atravessar a câmera

# --- Configurações de Movimento ---
@export var acceleration: float = 40.0    # Quão rápido ele ganha velocidade
@export var max_speed: float = 30.0       # Velocidade máxima
@export var initial_pop_force: float = 8.0 # Força do "pulo" inicial (efeito oposto)

var velocity: Vector3 = Vector3.ZERO
var delay_timer: float = 0.0

func _ready() -> void:
	player = PlayerManager.player
	
	# Opcional: Dar uma rotação aleatória inicial para ficar bonito
	rotation_degrees = Vector3(randf()*360, randf()*360, randf()*360)

func _process(delta: float) -> void:
	# Faz o DNA girar um pouco enquanto espera ou voa (efeito visual)
	rotate_y(2.0 * delta)
	
	if should_move_to_player and player:
		# Lógica de movimento "Magnético"
		var direction_to_player = global_position.direction_to(player.global_position + Vector3(0, 1.0, 0)) # + Vector3(0, 1, 0) mira no peito/cabeça, não no pé
		
		# Se tiver um delay (efeito de pop inicial), esperamos um pouco antes de atrair totalmente
		if delay_timer > 0:
			delay_timer -= delta
			# Aplica gravidade leve durante o "pop"
			velocity.y -= 20.0 * delta 
		else:
			# Acelera em direção ao jogador
			velocity = velocity.move_toward(direction_to_player * max_speed, acceleration * delta)
		
		# Aplica o movimento
		global_position += velocity * delta
		
		# Checa distância para coletar
		if global_position.distance_to(player.global_position + Vector3(0, 1.0, 0)) < _distance_to_disapear:
			collected()

func collected() -> void:
	GameEvents.player_collected_dna.emit()
	# Toca um som aqui se quiser
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player and not should_move_to_player:
		should_move_to_player = true
		
		# --- O Segredo do Movimento Prazeroso ---
		# Ao invés de ir direto, damos um empurrãozinho aleatório para cima/lados
		# Isso cria aquele efeito de "absorção" onde o item parece resistir por um milissegundo
		var random_dir = Vector3(randf_range(-1, 1), randf_range(0.5, 1.5), randf_range(-1, 1)).normalized()
		velocity = random_dir * initial_pop_force
		
		# Um pequeno delay para o jogador ver o item "pulando" antes de ser sugado
		delay_timer = 0.15
