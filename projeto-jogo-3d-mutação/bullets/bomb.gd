class_name Bomb extends RigidBody3D

# Variáveis para receber os stats da arma
var config: RangedWeaponConfig
var is_player_weapon: bool = false

# Flag para garantir que a explosão só ocorra uma vez
var has_exploded: bool = false

# Nodes for the explosion effect
@onready var debris: GPUParticles3D = $Debris
@onready var smoke: GPUParticles3D = $Smoke
@onready var fire: GPUParticles3D = $Fire
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionSound
@onready var explosion_area_3d: Area3D = $ExplosionArea3D

@export var array_of_meshes : Array[MeshInstance3D]

func _ready() -> void:
	GameEvents.wave_survived.connect(func() -> void:
		queue_free())
	
	# 2. Configuramos o RigidBody para detectar o primeiro contato
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(on_contact)

# Esta nova função é chamada no primeiro contato do corpo
func on_contact(body: Node3D):
	# Ignora a colisão se já explodiu
	if has_exploded:
		return
		
	# Ignora a colisão com o próprio jogador que atirou
	if body is Player and is_player_weapon:
		return
	
	# Trava a flag e explode
	has_exploded = true
	explode()

func explode():
	# (Opcional) Congela o corpo para que ele pare de se mover ao explodir
	linear_velocity = Vector3.ZERO
	freeze = true 
	
	hide_mashes()
	_cause_damage() # Renomeado para convenção de função "privada"
	debris.emitting = true
	smoke.emitting = true
	fire.emitting = true

	explosion_sound.play()
	
	# Damos tempo para os efeitos sonoros e de partícula tocarem antes de liberar a cena
	await get_tree().create_timer(2).timeout
	queue_free()

func _cause_damage():
	var damage_to_deal : float
	# Garante que o config foi passado antes de tentar ler o dano
	if not config:
		printerr("Bomba explodiu sem um RangedWeaponConfig!")
		return
	
	if is_player_weapon:
		if PlayerManager.player == null:
			return
		var player_stats : PlayerStats = PlayerManager.player.stats
	
		damage_to_deal = config.damage * (1 + player_stats.damage_increase)
	else:
		damage_to_deal = config.damage
	
	await get_tree().physics_frame
	for body in explosion_area_3d.get_overlapping_bodies():
		
		# --- CORREÇÃO AQUI ---
		# Se o corpo na área de explosão é o Jogador E a bomba foi atirada pelo Jogador,
		# pule para o próximo corpo (não cause dano).
		if body is Player and is_player_weapon:
			continue # Pula para o próximo 'body' no loop
		
		if body.has_method("take_damage"):
			body.take_damage(Damage.new(damage_to_deal, false)) 
	
	await get_tree().create_timer(0.1).timeout
	explosion_area_3d.monitoring = false

func hide_mashes()->void:
	for mesh in array_of_meshes:
		mesh.hide()
