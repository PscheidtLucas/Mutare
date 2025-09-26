class_name LongRangeWeapon
extends Node3D

## Propriedades Comuns a Todas as Armas
@export_group("Weapon Stats")
@export var ammunition_scene: PackedScene
@export var shots_per_second: float = 2.0
@export var projectile_speed: float = 20.0
@export var projectile_lifetime: float = 2.0

@export var is_player_weapon: bool = false

var projectile
var cooldown_timer: Timer

func _ready() -> void:
	if not has_node("CooldownTimer"):
		var cooldown_timer_node := Timer.new()
		cooldown_timer_node.name = "CooldownTimer"
		add_child(cooldown_timer_node)
		cooldown_timer = cooldown_timer_node
		
	cooldown_timer.start(1.0 / shots_per_second)
	cooldown_timer.timeout.connect(_fire)

## Função pública para tentar atirar. Scripts do jogador/inimigo devem chamar esta.
func shoot() -> void:
	# Só atira se o timer de cooldown não estiver ativo.
	if cooldown_timer.is_stopped():
		cooldown_timer.start()

## Função de disparo a ser sobrescrita pelas armas filhas.
## A lógica base aqui instancia e posiciona a munição, e a move para frente
func _fire() -> void:
	if not ammunition_scene:
		push_warning("Ammunition scene não está definida em %s" % name)
		return

	# Instancia e posiciona a munição na boca da arma
	projectile = ammunition_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position

	
	var forward := -global_transform.basis.x.normalized()
	
	if projectile is Bullet:
		projectile.velocity = forward * projectile_speed
		projectile.was_shot_from_player = is_player_weapon

	# Configura tempo de vida
	if projectile.has_method("set_lifetime"):
		projectile.set_lifetime(projectile_lifetime)
	# Deixa a lógica de trajetória e velocidade para as classes filhas.
