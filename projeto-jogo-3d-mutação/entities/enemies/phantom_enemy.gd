class_name PhantomEnemy
extends Enemy

## Variáveis de Flutuação
@export_group("Floating")
@export var hover_height: float = 2.0   # A que altura do chão ele vai flutuar
@export var hover_force: float = 5.0    # Quão rápido ele corrige a altura
@export var bob_frequency: float = 1.0  # Velocidade da ondulação para cima e para baixo
@export var bob_amplitude: float = 0.25 # Altura da ondulação

@export var node_to_float: Node3D

var bob_time: float = 0.0

func _ready() -> void:
	super._ready() # Executa o _ready() da classe base (Enemy)
	
	# --- MUDANÇA 1: Desativa a gravidade ---
	# Este modo de movimento ignora a gravidade global do projeto.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	start_float_tween()

func _physics_process(delta: float) -> void:
	if player == null:
		return
	
	# Reutiliza a lógica de estados (IDLE/CHASE) da classe base
	match current_state:
		State.IDLE:
			_idle_state()
		State.CHASE:
			_chase_state(delta)
	
	# Reutiliza as funções de olhar para o jogador e mover
	_look_at_player()
	move_and_slide()

# --- MUDANÇA 3: Desativa a Lógica de Pulo ---
# Sobrescrevemos as funções de pulo da classe base para que não façam nada.
func _on_link_reached(_details: Dictionary) -> void:
	pass # O fantasma ignora os links de pulo.

func _jumping_state() -> void:
	pass # O estado de pulo é ignorado.

func start_float_tween() -> void:
	var float_offset := 0.12
	var tween_duration := .7
	var start_y := node_to_float.position.y
	var tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node_to_float, "position:y", start_y+float_offset, tween_duration)
	tween.tween_property(node_to_float, "position:y", start_y-float_offset, tween_duration)
