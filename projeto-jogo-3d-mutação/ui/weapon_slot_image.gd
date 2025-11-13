class_name WeaponSlot extends TextureRect

var weapon_config: RangedWeaponConfig

@export var slot_number := 1
@export var fade_duration: float = 0.2 # Tempo do fade-in/out em segundos

# --- Referências dos Nós ---
# O nó do Tooltip (assumindo que é um Control ou Panel)
@onready var tooltip: PanelContainer = $WeaponTooltip

# As duas labels filhas do Tooltip
@onready var stat_name_label: Label = $WeaponTooltip/StatNames
@onready var stat_value_label: Label = $WeaponTooltip/StatValues

var fade_tween: Tween


func _ready() -> void:
	GameEvents.evolution_completed.connect(_on_evolution_completed)
	texture = null
	# Esconde o tooltip no início e o deixa totalmente transparente
	tooltip.visible = false
	tooltip.modulate.a = 0.0
	
	# Conecta os sinais do mouse para o fade
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Preenche o label de nomes, já que ele é estático
	stat_name_label.text = """Dmg:
	Projectiles:
	Fire Rate:
	Accuracy:
	Proj Speed:
	Range:
	Evo:"""

# Esta é a função que o seu RewardManager chama
func equip_weapon(weapon_cfg: RangedWeaponConfig):
	weapon_config = weapon_cfg
	texture = weapon_config.image
	
	# Chama a nova função para preencher os valores do tooltip
	_update_tooltip_labels()

# --- Lógica do Tooltip ---

func _update_tooltip_labels():
	# Garante que temos uma arma e que ela é do tipo correto
	if not weapon_config or not (weapon_config is RangedWeaponConfig):
		stat_value_label.text = "" # Limpa os valores se não houver arma
		return

	# Converte para o tipo certo para o Godot saber quais propriedades existem
	var cfg := weapon_config as RangedWeaponConfig

	# Constrói o string de valores usando as funções de formatação
	var values_text := ""
	values_text += _format_number(cfg.damage, 1) + "\n"
	values_text += str(int(cfg.number_of_projectiles)) + "\n"
	values_text += _format_number(cfg.fire_rate, 2) + " /s\n"
	values_text += _format_number(cfg.accuracy * 100.0, 1) + "%\n"
	values_text += _format_number(cfg.projectile_speed, 1) + " m/s\n"
	values_text += _format_number(cfg.range, 1) + " m\n"
	
	var bonus_pct := cfg.perma_buff_amount * 100.0
	var buff_name := _format_buff_name(cfg.perma_buff_type)
	values_text += "+" + _format_number(bonus_pct, 1) + "% " + buff_name

	stat_value_label.text = values_text

func _on_mouse_entered():
	print("Mouse entered in this slot: ", slot_number)
	# Se o slot não tiver uma arma, não mostra o tooltip
	if not weapon_config:
		return
		
	# Mata qualquer tween anterior para evitar conflitos
	if fade_tween:
		fade_tween.kill()

	tooltip.visible = true # Torna o nó visível ANTES de começar o fade
	fade_tween = create_tween()
	fade_tween.tween_property(tooltip, "modulate:a", 1.0, fade_duration)

func _on_mouse_exited():
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(tooltip, "modulate:a", 0.0, fade_duration)
	# Quando o fade-out terminar, esconde o nó para não bloquear o mouse
	fade_tween.tween_callback(tooltip.hide)

# --- Funções de Formatação (Copiadas do seu WeaponStatsLabel) ---

# Arredonda e converte pra string com 'decimals' casas decimais.
func _format_number(value: float, decimals: int = 1) -> String:
	var mult := pow(10.0, float(decimals))
	var rounded := roundf(value * mult) / mult
	var s := str(rounded)
	
	# Esta formatação garante o número de casas decimais (ex: 5.0)
	if decimals > 0:
		var fmt := "%"
		fmt += "." + str(decimals)
		fmt += "f"
		s = fmt % rounded
	else:
		# Se for 0 casas decimais, retorna o número inteiro
		s = str(int(rounded))
		
	return s

func _format_buff_name(buff_type: int) -> String:
	# Acessa o enum PermaBuffType que está dentro da classe RewardConfig
	var name : String = RewardConfig.PermaBuffType.keys()[buff_type]
	name = name.to_lower().capitalize()
	name = name.replace("_", " ")
	return name

func _on_evolution_completed() -> void:
	# Limpa o slot de arma completamente
	weapon_config = null
	texture = null
	
	# Esconde e reseta o tooltip
	if fade_tween:
		fade_tween.kill()
	tooltip.visible = false
	tooltip.modulate.a = 0.0
	
	# Limpa os textos do tooltip
	stat_value_label.text = ""
	# Como o stat_name_label é fixo, mantemos o texto padrão
