class_name HpContainer extends MarginContainer

@onready var hp_backroung: TextureRect = %HpBackroung

@export var player_stats: PlayerStats

# Cores para a animação
const HEAL_COLOR: Color = Color(0.24, 1.0, 0.379) # Verde
const DAMAGE_COLOR: Color = Color(1.366, 0.383, 0.383) # Vermelho
const ORIGINAL_COLOR: Color = Color(1, 1, 1) # Cor original do seu TextureRect

var current_health: float = 0.0 # Para rastrear a mudança de vida
var _tween: Tween = null # Para controlar a animação

func _ready() -> void:
	player_stats.health_changed.connect(_on_player_health_changed)
	# Inicializa current_health com o valor atual do player_stats
	current_health = player_stats.health
	# Garante que a cor inicial seja a original, caso tenha alguma cor definida no editor
	hp_backroung.modulate = ORIGINAL_COLOR

func _on_player_health_changed() -> void:
	var new_health = player_stats.health

	# Calcula se foi cura ou dano
	if new_health > current_health:
		_animate_flash(HEAL_COLOR)
	elif new_health < current_health:
		_animate_flash(DAMAGE_COLOR)
	
	current_health = new_health # Atualiza a vida para o próximo ciclo

func _animate_flash(flash_color: Color) -> void:
	# Para qualquer animação anterior para evitar bugs
	if _tween and _tween.is_running():
		_tween.kill()
		_tween = null

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 1. Pisca para a cor de flash
	_tween.tween_property(hp_backroung, "modulate", flash_color, 0.1) # Duração curta para o flash

	# 2. Volta para a cor original
	_tween.tween_property(hp_backroung, "modulate", ORIGINAL_COLOR, 0.3) # Duração um pouco maior para retornar suavemente
	
	# Garante que o tween seja liberado da memória após terminar
	_tween.tween_callback(func(): _tween = null)
