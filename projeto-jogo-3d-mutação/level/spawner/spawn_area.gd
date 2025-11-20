class_name SpawnArea extends Area3D

@export var game_state: GameState

@export var array_of_enemy_types : Array[PackedScene]

@onready var spawn_timer: Timer = %SpawnTimer

# Curvas configuráveis no editor
@export var spawn_time_curve: Curve 
## Quanto maior o Y, mais fácil (demora mais para aparecer inimigos)
## x = 0.1 significa wave cycle 1, 0.9 wave cycle 9...

@export var enemies_per_wave_curve: Curve
## Quanto maior o Y, mais difícil (spawna mais inimigos por spawn)
## x = 0.1 significa wave cycle 1, 0.9 cycle wave 9...

@export var min_spawn_time: float = 0.5

@export_group("Cycle Scaling")
@export var enemy_count_scale: float = 1.1
@export var spawn_time_scale: float = 1.1

var game_time: float = 0.0
var collision_shapes: Array[CollisionShape3D] = []

### CONFIGURAÇÃO DE SPAWN POR WAVE (1-10)
# A ordem dos números no array corresponde à ordem em 'array_of_enemy_types'
## Wave number: [Basic, Phantom, Pyramid]
var wave_spawn_weights: Dictionary = {
	1: [100, 0, 0],   # Wave 1: Só Tipo 1
	2: [80, 20, 0],   # Wave 2: 80 % do tipo 1 e 20% do tipo 2
	3: [50, 50, 0],
	4: [0, 100, 0],   
	5: [40, 40, 20], 
	6: [30, 40, 30],
	7: [40, 30, 30],
	8: [30, 30, 40],
	9: [20, 20, 60],
	10: [0, 0, 100]  
}

func _ready() -> void:	
	GameEvents.wave_started.connect(on_wave_started)
	
	for child in get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
	
	if collision_shapes.is_empty():
		printerr("ERRO: Nenhuma CollisionShape3D encontrada!")
		return
	
	if game_state == null:
		printerr("ERRO: GameState não foi atribuído ao SpawnArea no inspetor!")
		return
		
	var initial_wave = game_state.get_wave_in_cycle()
	spawn_timer.wait_time = calculate_next_spawn_time(initial_wave)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func on_wave_started() -> void:
	var wave_in_cycle = game_state.get_wave_in_cycle()
	spawn_timer.wait_time = calculate_next_spawn_time(wave_in_cycle)
	spawn_timer.start()
	_on_spawn_timer_timeout()
	
func _process(delta: float) -> void:
	game_time += delta

func _on_spawn_timer_timeout() -> void:
	var wave_in_cycle = game_state.get_wave_in_cycle()
	
	var enemies_to_spawn = calculate_enemies_for_wave(wave_in_cycle)
	spawn_enemies(enemies_to_spawn)
	
	var next_spawn_time = calculate_next_spawn_time(wave_in_cycle)
	spawn_timer.wait_time = max(next_spawn_time, min_spawn_time)

func calculate_enemies_for_wave(wave_in_cycle: int) -> int:
	if enemies_per_wave_curve:
		var t : float = clamp(float(wave_in_cycle - 1) / 9.0, 0.0, 1.0)
		var base_enemies = enemies_per_wave_curve.sample(t)
		var cycle_multiplier = pow(enemy_count_scale, game_state.cycle_number - 1)
		return max(1, int(round(base_enemies * cycle_multiplier)))
	else:
		return 1

func calculate_next_spawn_time(wave_in_cycle: int) -> float:
	if spawn_time_curve:
		var t : float = clamp(float(wave_in_cycle - 1) / 9.0, 0.0, 1.0) ## Converte o número da wave (1 a 10) para uma posição percentual (0.0 a 1.0)
		var base_time = spawn_time_curve.sample(t)
		var cycle_multiplier = pow(spawn_time_scale, game_state.cycle_number - 1)
		return base_time / cycle_multiplier
	else:
		return 5.0

func spawn_enemies(count: int) -> void:
	var wave_in_cycle = game_state.get_wave_in_cycle()
	
	for i in range(count):
		var spawn_position = get_random_spawn_position()
		if spawn_position != Vector3.ZERO:
			
			### LÓGICA NOVA DE SELEÇÃO ###
			var enemy_scene = get_enemy_scene_by_wave_probability(wave_in_cycle)
			##############################
			
			if enemy_scene == null:
				printerr("ERRO: Não foi possível selecionar um inimigo.")
				continue
				
			var enemy = enemy_scene.instantiate()
			
			if enemy.has_method("scale_stats_for_cycle"):
				enemy.scale_stats_for_cycle(game_state.cycle_number)
			
			enemy.position = spawn_position
			get_tree().current_scene.call_deferred("add_child", enemy)


### NOVA FUNÇÃO: Sorteio Ponderado ###
func get_enemy_scene_by_wave_probability(wave_num: int) -> PackedScene:
	# 1. Pega o array de pesos da wave atual (se não tiver configurado, usa padrão)
	# Se você esquecer de configurar uma wave, ele vai assumir chances iguais para todos
	var weights: Array = wave_spawn_weights.get(wave_num, [])
	
	# Validação básica se os pesos batem com o número de inimigos
	if weights.is_empty() or weights.size() != array_of_enemy_types.size():
		# Fallback: retorna aleatório puro se a config estiver errada
		#printerr("Aviso: Configuração de pesos da wave ", wave_num, " está ausente ou incorreta.")
		return array_of_enemy_types.pick_random()

	# 2. Calcula o peso total
	var total_weight: float = 0.0
	for w in weights:
		total_weight += w
	
	# 3. Sorteia um número entre 0 e o total
	var random_val = randf_range(0.0, total_weight)
	var current_sum: float = 0.0
	
	# 4. Percorre o array para achar quem ganhou
	for i in range(weights.size()):
		current_sum += weights[i]
		if random_val <= current_sum:
			return array_of_enemy_types[i]
	
	# Segurança: retorna o último (caso erros de arredondamento float)
	return array_of_enemy_types.back()

func get_random_spawn_position() -> Vector3:
	if collision_shapes.is_empty():
		return Vector3.ZERO

	var space_state = get_world_3d().direct_space_state

	for attempt in range(10): 
		var random_shape = collision_shapes[randi() % collision_shapes.size()]
		var box_shape = random_shape.shape as BoxShape3D
		if box_shape == null:
			printerr("ERRO: CollisionShape3D deve usar BoxShape3D!")
			return Vector3.ZERO

		var half_extents = box_shape.size * 0.5
		var random_offset = Vector3(
			randf_range(-half_extents.x, half_extents.x),
			0.0,
			randf_range(-half_extents.z, half_extents.z)
		)
		var spawn_position = random_shape.global_position + random_offset

		var test_shape = SphereShape3D.new()
		test_shape.radius = 0.6

		var params = PhysicsShapeQueryParameters3D.new()
		params.shape = test_shape
		params.transform = Transform3D(Basis(), spawn_position)
		
		var result : Array = space_state.intersect_shape(params, 1) 

		if result.is_empty():
			return spawn_position

	return Vector3.ZERO
