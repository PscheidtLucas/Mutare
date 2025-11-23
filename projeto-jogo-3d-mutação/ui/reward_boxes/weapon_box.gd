class_name WeaponBox extends MarginContainer

const HOVER_MAIN_MENU_1 = preload("uid://c7kbf7cgampxm")
const START_JINGLE = preload("uid://8r8dgcyjjqe3")

# --- NOVO: Tempo de trava individual ---
@export var input_lock_time: float = .75
# ---------------------------------------

var reward = null
var weapon_config_generated : RewardConfig 

@export var select_button: Button
@export var reward_screen: RewardManager

signal update_labels(weapon_config: RewardConfig)

@onready var rating_value: Label = %RatingValue


func _ready() -> void:
	if not select_button.pressed.is_connected(_on_select_button_pressed):
		select_button.pressed.connect(_on_select_button_pressed)
		
	reward_screen.weapons_configured.connect(_on_weapons_configured)

func _on_weapons_configured() -> void:
	if weapon_config_generated == null:
		push_warning("WeaponBox recebeu sinal de configuração, mas weapon_config_generated é null.")
		return
	
	calc_and_update_rating(weapon_config_generated)
	update_labels.emit(weapon_config_generated)
	
	# --- APLICA A TRAVA QUANDO OS DADOS CHEGAM ---
	apply_input_lock()
	# ---------------------------------------------

# --- NOVA FUNÇÃO DE TRAVA ---
func apply_input_lock() -> void:
	# 1. Desabilita visualmente e funcionalmente
	select_button.disabled = true
	select_button.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignora o mouse (sem som de hover)
	#modulate.a = 0.5 # Fica meio transparente (feedback visual importante)
	
	# 2. Espera o tempo seguro
	await get_tree().create_timer(input_lock_time).timeout
	
	# 3. Reabilita (verifica se o botão ainda existe para evitar erros se a tela fechou)
	if is_instance_valid(select_button):
		select_button.disabled = false
		select_button.mouse_filter = Control.MOUSE_FILTER_STOP # Volta a aceitar mouse
		
		# Animação suave voltando a cor normal
		#var tween = create_tween()
		#tween.tween_property(self, "modulate:a", 1.0, 0.2)
# ----------------------------

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
	
	var avg = (damage_n + accuracy_n + range_n + fire_rate_n) / 4.0
	var rating = int(round(50 + (avg * 50)))
	
	rating_value.text = str(rating)

func _on_select_button_mouse_entered() -> void:
	# Só toca o som se o botão não estiver travado/desabilitado
	if not select_button.disabled:
		AudioManager.play_sfx(HOVER_MAIN_MENU_1)
