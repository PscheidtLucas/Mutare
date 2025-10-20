extends Area3D

@export var array_of_enemy_types : Array[PackedScene]

@onready var spawn_timer: Timer = %SpawnTimer

# Parâmetros ajustáveis do spawn
@export var base_spawn_time: float = 7.0		# Tempo base entre spawns
@export var time_reduction_rate: float = 0.98	# Redução do tempo a cada wave (0.8 = 20% mais rápido)
@export var enemies_per_wave_growth: float = 0.4	# Crescimento de inimigos por wave
@export var min_spawn_time: float = 2.0		# Tempo mínimo entre spawns

var game_time: float = 0.0
var current_wave: int = 0
var collision_shapes: Array[CollisionShape3D] = []

func _ready() -> void:
	GameEvents.wave_survived.connect(func() -> void:
		current_wave += 1
		print("aumentando current wave para: ", current_wave))
	GameEvents.wave_started.connect(on_wave_started)
	
	# Coleta todas as CollisionShape3D filhas
	for child in get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
	
	if collision_shapes.is_empty():
		printerr("ERRO: Nenhuma CollisionShape3D encontrada!")
		return
	
	# Spawn inicial
	spawn_enemies(1)
	# Configura timer para próximos spawns
	spawn_timer.wait_time = base_spawn_time
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func on_wave_started() -> void:
	spawn_timer.start()

func _process(delta: float) -> void:
	game_time += delta

func _on_spawn_timer_timeout() -> void:

	# Calcula quantos inimigos spawnar nesta wave
	var enemies_to_spawn = calculate_enemies_for_wave(current_wave)
	spawn_enemies(enemies_to_spawn)
	
	# Calcula próximo tempo de spawn (cada vez mais rápido)
	var next_spawn_time = calculate_next_spawn_time(current_wave)
	spawn_timer.wait_time = max(next_spawn_time, min_spawn_time)
	
	print("Wave ", current_wave, ": ", enemies_to_spawn, " inimigos spawned. Próximo spawn em ", spawn_timer.wait_time, "s")

func calculate_enemies_for_wave(wave: int) -> int:
	# Fórmula: 1 + (wave * crescimento)
	return max(1, int(1.0 + (wave * enemies_per_wave_growth)))

func calculate_next_spawn_time(wave: int) -> float:
	# Fórmula: tempo_base * (taxa_redução ^ wave)
	# Cada wave fica mais rápida exponencialmente
	return base_spawn_time * pow(time_reduction_rate, wave)

func spawn_enemies(count: int) -> void:
	for i in count:
		var spawn_position = get_random_spawn_position()
		if spawn_position != Vector3.ZERO:
			var enemy = array_of_enemy_types.pick_random().instantiate()
			
			get_tree().current_scene.call_deferred("add_child", enemy)
			enemy.set_deferred("global_position", spawn_position)

func get_random_spawn_position() -> Vector3:
	if collision_shapes.is_empty():
		return Vector3.ZERO
	
	# Escolhe uma CollisionShape3D aleatória
	var random_shape = collision_shapes[randi() % collision_shapes.size()]
	
	# Pega a forma da colisão (assumindo BoxShape3D)
	var shape = random_shape.shape as BoxShape3D
	if shape == null:
		print("ERRO: CollisionShape3D deve usar BoxShape3D!")
		return Vector3.ZERO
	
	# Gera posição aleatória dentro da caixa
	var half_extents = shape.size * 0.5
	var random_offset = Vector3(
		randf_range(-half_extents.x, half_extents.x),
		0.0,  # Y fixo (assumindo spawn no chão)
		randf_range(-half_extents.z, half_extents.z)
	)
	
	# Converte para posição global
	return random_shape.global_position + random_offset
