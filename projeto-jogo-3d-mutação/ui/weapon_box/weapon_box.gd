class_name WeaponBox extends MarginContainer

var reward = null
var weapon_config_generated : RewardConfig # passada pelo reward screen quando o sinal wave survived é emitido

@export var select_button: Button
@export var reward_screen: RewardManager

signal update_labels(weapon_config: RewardConfig) ## Emitido aqui para atualizar as weapon_stats_label

func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
		
	reward_screen.weapons_configured.connect(_on_weapons_configured)
	## Quando esse sinal é chamado, weapon_config já foi settado, emitido no RewardScreen

func _on_weapons_configured() -> void:
	print("weapons were configured in the weapon box, config damage: ", weapon_config_generated.damage)
	update_labels.emit(weapon_config_generated)

func _on_select_button_pressed() -> void:
	GameEvents.weapon_selected.emit(weapon_config_generated)
	get_tree().paused = false
	
	GameEvents.wave_started.emit() ## TODO vai ter problema se eu tiver 2 escolhas, perna e depois arma, caso a perna tbm use esse codigo!

func setup_information() -> void:
	pass
