# BulletPool.gd
extends Node

const INITIAL_POOL_SIZE := 200
const MAX_POOL_SIZE := 400
var enemy_bullet_scene: PackedScene = null
var available_bullets: Array[Bullet] = []
var active_bullets: Array[Bullet] = []

func _ready() -> void:
	GameEvents.wave_survived.connect(clear_all_bullets)

func _ensure_pool_initialized(scene: PackedScene) -> void:
	if enemy_bullet_scene != null:
		return

	enemy_bullet_scene = scene
	for i in range(INITIAL_POOL_SIZE):
		var bullet = scene.instantiate() as Bullet
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(bullet) # agora o pool é o parent das balas inativas
		bullet.hide()
		available_bullets.append(bullet)

	print("BulletPool inicializado com ", INITIAL_POOL_SIZE, " balas")

func get_bullet(scene: PackedScene) -> Bullet:
	_ensure_pool_initialized(scene)
	
	var bullet: Bullet
	
	if available_bullets.is_empty():
		if active_bullets.size() < MAX_POOL_SIZE:
			bullet = scene.instantiate() as Bullet
			print("⚠️ Pool vazio! Criando nova bala. Total ativo: ", active_bullets.size() + 1)
		else:
			bullet = active_bullets.pop_front()
			if not is_instance_valid(bullet):
				bullet = scene.instantiate() as Bullet
			else:
				bullet.reset()
	else:
		bullet = available_bullets.pop_back()
		while not is_instance_valid(bullet) and not available_bullets.is_empty():
			bullet = available_bullets.pop_back()
		
		if not is_instance_valid(bullet):
			bullet = scene.instantiate() as Bullet
	
	active_bullets.append(bullet)
	bullet.show()
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	bullet.monitoring = true
	return bullet

func return_bullet(bullet: Bullet) -> void:
	if not is_instance_valid(bullet):
		return

	if bullet not in active_bullets:
		return

	active_bullets.erase(bullet)
	available_bullets.append(bullet)

	# === REMOVE DA CENA (deferred corretamente) ===
	if bullet.get_parent():
		call_deferred("clear_bullet_parent", bullet)
	
	bullet.hide()
	bullet.set_deferred("monitoring", false)
	bullet.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	bullet.position = Vector3(0, -1000, 0)

func clear_bullet_parent(bullet):
	if not is_instance_valid(bullet):
		return
	var p = bullet.get_parent()
	if p:
		p.remove_child(bullet)

func clear_all_bullets() -> void:
	print("🧹 Limpando bullets. Ativos: ", active_bullets.size())
	
	# Copia o array pra evitar problemas de modificação durante iteração
	var bullets_to_return = active_bullets.duplicate()
	
	for bullet in bullets_to_return:
		if is_instance_valid(bullet):
			return_bullet(bullet)
	
	# Limpa arrays
	available_bullets = available_bullets.filter(func(b): return is_instance_valid(b))
	active_bullets.clear()
	
	print("✅ Limpeza concluída. Disponíveis: ", available_bullets.size())

func get_stats() -> Dictionary:
	return {
		"active": active_bullets.size(),
		"available": available_bullets.size(),
		"total": active_bullets.size() + available_bullets.size()
	}
