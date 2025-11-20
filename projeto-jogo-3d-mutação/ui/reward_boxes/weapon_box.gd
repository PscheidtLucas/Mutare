class_name WeaponBox extends MarginContainer

const HOVER_MAIN_MENU_1 = preload("uid://c7kbf7cgampxm")
const START_JINGLE = preload("uid://8r8dgcyjjqe3")

var reward = null
var weapon_config_generated : RewardConfig # passada pelo reward screen quando o sinal wave survived é emitido

@export var select_button: Button
@export var reward_screen: RewardManager

signal update_labels(weapon_config: RewardConfig) ## Emitido aqui para atualizar as weapon_stats_label e também as imagens das armas no ImageContainer

@onready var rating_value: Label = %RatingValue


func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
		
	reward_screen.weapons_configured.connect(_on_weapons_configured)
	## Quando esse sinal é chamado, weapon_config já foi settado, emitido no RewardScreen

func _on_weapons_configured() -> void:
	if weapon_config_generated == null:
		push_warning("WeaponBox recebeu sinal de configuração, mas weapon_config_generated é null.")
		return
	calc_and_update_rating(weapon_config_generated)
	update_labels.emit(weapon_config_generated)

func _on_select_button_pressed() -> void:
	AudioManager.play_sfx(START_JINGLE, 10)
	GameEvents.weapon_selected.emit(weapon_config_generated)
	get_tree().paused = false
	
	GameEvents.wave_started.emit()

func calc_and_update_rating(weapon_config: RangedWeaponConfig) -> void:
	var damage_n = (weapon_config.damage - weapon_config.damage_min) / float(weapon_config.damage_max - weapon_config.damage_min)
	var accuracy_n = (weapon_config.accuracy - weapon_config.accuracy_min) / float(weapon_config.accuracy_max - weapon_config.accuracy_min)
	var range_n = (weapon_config.range - weapon_config.min_range) / float(weapon_config.max_range - weapon_config.min_range)
	var fire_rate_n = (weapon_config.fire_rate - weapon_config.fire_rate_min) / float(weapon_config.fire_rate_max - weapon_config.fire_rate_min)
	
	# média simples dos valores normalizados
	var avg = (damage_n + accuracy_n + range_n + fire_rate_n) / 4.0

	# converte para o intervalo 50–100
	var rating = int(round(50 + (avg * 40)))
	
	# exibe na label
	rating_value.text = str(rating)

func _on_select_button_mouse_entered() -> void:
	AudioManager.play_sfx(HOVER_MAIN_MENU_1)
