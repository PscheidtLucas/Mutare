class_name WeaponBox extends MarginContainer

var reward = null
var weapon_config_generated : RewardConfig # passada pelo reward screen quando o sinal wave survived é emitido

@export var select_button: Button
@export var reward_screen: RewardManager

signal update_labels(weapon_config: RewardConfig) ## Emitido aqui para atualizar as weapon_stats_label e também as imagens das armas no ImageContainer


func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
		
	reward_screen.weapons_configured.connect(_on_weapons_configured)
	## Quando esse sinal é chamado, weapon_config já foi settado, emitido no RewardScreen

func _on_weapons_configured() -> void:
	if weapon_config_generated == null:
		push_warning("WeaponBox recebeu sinal de configuração, mas weapon_config_generated é null.")
		return
	update_labels.emit(weapon_config_generated)

func _on_select_button_pressed() -> void:
	GameEvents.weapon_selected.emit(weapon_config_generated)
	get_tree().paused = false
	
	GameEvents.wave_started.emit()
