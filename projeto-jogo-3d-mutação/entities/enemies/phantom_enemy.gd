class_name PhantomEnemy
extends Enemy

## Variáveis de Flutuação
@export_group("Floating")
@export var hover_height: float = 2.0   # A que altura do chão ele vai flutuar
@export var hover_force: float = 5.0    # Quão rápido ele corrige a altura
@export var bob_frequency: float = 1.0  # Velocidade da ondulação para cima e para baixo
@export var bob_amplitude: float = 0.25 # Altura da ondulação

var bob_time: float = 0.0

func _ready() -> void:
	super._ready() # Executa o _ready() da classe base (Enemy)
	
	# --- MUDANÇA 1: Desativa a gravidade ---
	# Este modo de movimento ignora a gravidade global do projeto.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	# Reutiliza a lógica de estados (IDLE/CHASE) da classe base
	match current_state:
		State.IDLE:
			_idle_state()
		State.CHASE:
			_chase_state()
	
	# --- MUDANÇA 2: Lógica de Flutuação ---
	var vertical_velocity = 0.0
	
	# 1. Manter a altura (Hover)
	var ray_origin = global_position
	var ray_end = global_position - Vector3.UP * (hover_height + 2.0)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end, self.collision_mask)
	var result = space_state.intersect_ray(query)
	
	if result:
		var distance_from_ground = global_position.distance_to(result.position)
		var height_difference = distance_from_ground - hover_height
		# Aplica uma força para corrigir a altura, de forma suave
		vertical_velocity = -height_difference * hover_force
	
	# 2. Ondulação (Bobbing)
	bob_time += delta * bob_frequency
	vertical_velocity += sin(bob_time) * bob_amplitude
	
	# A velocity horizontal é calculada pelo NavigationAgent (via sinal)
	# Nós apenas adicionamos nossa velocity vertical calculada.
	velocity.y = vertical_velocity
	
	# Reutiliza as funções de olhar para o jogador e mover
	_look_at_player()
	move_and_slide()

# --- MUDANÇA 3: Desativa a Lógica de Pulo ---
# Sobrescrevemos as funções de pulo da classe base para que não façam nada.
func _on_link_reached(_details: Dictionary) -> void:
	pass # O fantasma ignora os links de pulo.

func _jumping_state() -> void:
	pass # O estado de pulo é ignorado.
