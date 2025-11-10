extends Area3D

## TODO REFATORAR ISSO PARA BALANCEAR MAIS O COMEÇO

@export var array_of_enemy_types : Array[PackedScene]

@onready var spawn_timer: Timer = %SpawnTimer

# Curvas configuráveis no editor
@export var spawn_time_curve: Curve				# controla tempo de spawn por wave
@export var enemies_per_wave_curve: Curve		# controla número de inimigos por wave

@export var min_spawn_time: float = 2.0			# limite inferior pro tempo de spawn

var game_time: float = 0.0
var current_wave: int = 0
var collision_shapes: Array[CollisionShape3D] = []

func _ready() -> void:
	GameEvents.wave_survived.connect(func() -> void:
		current_wave += 1
		)
	GameEvents.wave_started.connect(on_wave_started)
	
	# Coleta todas as CollisionShape3D filhas
	for child in get_children():
		if child is CollisionShape3D:
			collision_shapes.append(child)
	
	if collision_shapes.is_empty():
		printerr("ERRO: Nenhuma CollisionShape3D encontrada!")
		return
	
	# Exibe prévia das waves 1–10
	#print("===== Prévia de dificuldade (Waves 1–10) =====")
	for wave in range(1, 11):
		var enemies := calculate_enemies_for_wave(wave)
		var spawn_time := calculate_next_spawn_time(wave)
		#print("Wave ", wave, " → Inimigos: ", enemies, " | Spawn time: ", spawn_time)

	spawn_timer.wait_time = calculate_next_spawn_time(current_wave)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func on_wave_started() -> void:
	_on_spawn_timer_timeout()
	
func _process(delta: float) -> void:
	game_time += delta

func _on_spawn_timer_timeout() -> void:
	for n in range(3):
		var enemies_to_spawn = calculate_enemies_for_wave(current_wave)
		spawn_enemies(enemies_to_spawn)
		
		var next_spawn_time = calculate_next_spawn_time(current_wave)
		spawn_timer.wait_time = max(next_spawn_time, min_spawn_time)
		
		#print("Wave ", current_wave, ": ", enemies_to_spawn, " inimigos spawned. Próximo spawn em ", spawn_timer.wait_time, "s")

func calculate_enemies_for_wave(wave: int) -> int:
	if enemies_per_wave_curve:
		# Avalia curva entre 0 e 1 (normaliza wave 1–10)
		var t : float = clamp(float(wave - 1) / 9.0, 0.0, 1.0)
		return max(1, int(round(enemies_per_wave_curve.sample(t))))
	else:
		return 1

func calculate_next_spawn_time(wave: int) -> float:
	if spawn_time_curve:
		var t : float = clamp(float(wave - 1) / 9.0, 0.0, 1.0)
		return spawn_time_curve.sample(t)
	else:
		return 5.0

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
	
	var random_shape = collision_shapes[randi() % collision_shapes.size()]
	var shape = random_shape.shape as BoxShape3D
	if shape == null:
		print("ERRO: CollisionShape3D deve usar BoxShape3D!")
		return Vector3.ZERO
	
	var half_extents = shape.size * 0.5
	var random_offset = Vector3(
		randf_range(-half_extents.x, half_extents.x),
		0.0,
		randf_range(-half_extents.z, half_extents.z)
	)
	
	return random_shape.global_position + random_offset
