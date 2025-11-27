class_name DnaMoney extends RigidBody3D

var velocity: Vector3 = Vector3.ZERO
var delay_timer: float = 0.0
var chase_timer: float = 0.0 

var player : Player = null
var should_move_to_player : bool = false

const DISTANCE_TO_DISAPEAR := 0.8 
const PLAYER_Y_OFFSET := 1.5

@export var acceleration: float = 80.0
@export var max_speed: float = 60.0
@export var initial_pop_force: float = 5.0

# Aumenta a agressividade com o tempo para evitar órbita
@export var chase_ramp_up: float = 30.0 

@onready var dna_detection_area_3d: Area3D = %DnaDetectionArea3D

func _ready() -> void:
	GameEvents.wave_started.connect(queue_free)
	
	dna_detection_area_3d.body_entered.connect(_on_body_entered)
	player = PlayerManager.player

func _process(delta: float) -> void:
	if should_move_to_player and player:
		var target_pos = player.global_position + Vector3(0, PLAYER_Y_OFFSET, 0)
		var distance = global_position.distance_to(target_pos)
		
		# Delay inicial do "pop"
		if delay_timer > 0:
			delay_timer -= delta
			velocity.y -= 20.0 * delta  # Gravidade leve
			global_position += velocity * delta
			return 

		# --- CORREÇÃO DE ÓRBITA ---
		chase_timer += delta
		
		# Aumenta a aceleração e velocidade máxima com o tempo
		var current_accel = acceleration + (chase_timer * chase_ramp_up * 2.0)
		var current_max_speed = max_speed + (chase_timer * chase_ramp_up)
		
		# Se estiver muito perto, curva fechada agressiva
		if distance < 3.0:
			current_accel *= 3.0 

		var direction_to_player = global_position.direction_to(target_pos)
		
		velocity = velocity.move_toward(direction_to_player * current_max_speed, current_accel * delta)
		global_position += velocity * delta
		
		if distance < DISTANCE_TO_DISAPEAR:
			collected()
	
const COLLECT_UP_SOUND = preload("uid://df6g5y8oert3e")
func collected() -> void:
	AudioManager.play_sfx(COLLECT_UP_SOUND, 0, 3.5, .3)
	GameEvents.player_collected_dna.emit()
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is Player and not should_move_to_player:
		should_move_to_player = true
		
		# Trava a física para o RigidBody não interferir no movimento manual
		freeze = true 
		
		# Calcula vetor oposto
		var direction_to_player = global_position.direction_to(player.global_position + Vector3(0, PLAYER_Y_OFFSET, 0))
		var oposite_dir = -direction_to_player
		oposite_dir.y = 0 # Zera altura para sair horizontalmente
		
		# Normalizei para garantir que a força seja consistente independente do ângulo
		velocity = oposite_dir.normalized() * initial_pop_force
		
		delay_timer = 0.20 # Tempo do pop
