class_name EnemyCopy
extends CharacterBody3D

enum State { IDLE, CHASE, JUMPING }
var current_state: State = State.CHASE

var health := 3
var player: Player = null

@export var move_speed: float = 3.0
@export var stop_distance: float = 14.0

## Variáveis para o pulo animado
@export_group("Jump")
@export var jump_duration: float = 0.8 # Duração do pulo em segundos. Menor = mais rápido.
@export var jump_height: float = 3.0   # Altura máxima do arco do pulo.
@export var jump_pause: float = 0.5    # Pausa antes de iniciar o pulo.

# Usado pelo Tween para animar o progresso do pulo de 0.0 a 1.0
@onready var jump_progress: float = 0.0
@onready var ray_cast_3d: RayCast3D = %RayCast3D

var jump_start_position: Vector3
var jump_target_position: Vector3

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	player = PlayerManager.player
	navigation_agent_3d.link_reached.connect(_on_link_reached)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	# O estado JUMPING agora tem sua própria lógica de movimento (sem move_and_slide)
	if current_state == State.JUMPING:
		_jumping_state()
		return
		
	match current_state:
		State.IDLE:
			_idle_state()
		State.CHASE:
			_chase_state()

	_look_at_player()
	move_and_slide()

## Estados da IA

func _idle_state():
	velocity = Vector3.ZERO
	if global_position.distance_to(player.global_position) > stop_distance:
		current_state = State.CHASE

func _chase_state():
	if global_position.distance_to(player.global_position) <= stop_distance:
		current_state = State.IDLE
		return

	navigation_agent_3d.target_position = player.global_position
	var next_path_position = navigation_agent_3d.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	var new_velocity = direction * move_speed
	navigation_agent_3d.velocity = new_velocity

func _jumping_state():
	# Calcula a nova posição baseada no progresso do pulo (animado pelo Tween)
	var new_pos = jump_start_position.lerp(jump_target_position, jump_progress)
	
	# Fórmula da parábola para criar o arco do pulo
	var arc = 4.0 * jump_height * jump_progress * (1.0 - jump_progress)
	new_pos.y += arc
	
	global_position = new_pos

## Funções de Navegação e Combate

# A função agora é 'async' para podermos usar 'await' para a pausa.
func _on_link_reached(details: Dictionary) -> void:
	current_state = State.JUMPING
	velocity = Vector3.ZERO # Para o inimigo completamente
	
	# Armazena as posições inicial e final do pulo
	jump_start_position = global_position
	jump_target_position = details[&"link_exit_position"]
	
	# Pausa antes de pular
	await get_tree().create_timer(jump_pause).timeout
	
	# Cria e configura o Tween para animar o pulo
	var tween = create_tween()
	# Anima a variável 'jump_progress' de 0.0 para 1.0 durante 'jump_duration'
	tween.tween_property(self, "jump_progress", 1.0, jump_duration).set_trans(Tween.TRANS_LINEAR)
	# Quando o tween terminar, chama a função para finalizar o pulo
	tween.finished.connect(_on_jump_finished)

func _on_jump_finished() -> void:
	# Reseta o progresso e volta ao estado de perseguição
	jump_progress = 0.0
	current_state = State.CHASE

func _look_at_player():
	var to_player = player.global_position - global_position
	to_player.y = 0
	if to_player.length_squared() > 0.01:
		look_at(global_position + to_player, Vector3.UP)

func take_damage(damage: int) -> void:
	health -= damage
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
