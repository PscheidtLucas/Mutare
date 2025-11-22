class_name HeadSlot extends TextureRect

var head_config: HeadRewardConfig

@export var slot_number := 1
@export var fade_duration: float = 0.2 # Tempo do fade-in/out em segundos

# --- Referências dos Nós ---
# O nó do Tooltip (assumindo que é um PanelContainer com o mesmo nome)
@onready var tooltip: PanelContainer = $HeadTooltip

# As duas labels filhas do Tooltip (com os mesmos nomes)
@onready var stat_name_label: Label = $HeadTooltip/StatNames
@onready var stat_value_label: Label = $HeadTooltip/StatValues

var fade_tween: Tween


func _ready() -> void:
	GameEvents.start_perma_buff_label_animation.connect(_spawn_evo_popup)
	GameEvents.evolution_completed.connect(_on_evolution_completed)
	texture = null
	# Esconde o tooltip no início e o deixa totalmente transparente
	tooltip.visible = false
	tooltip.modulate.a = 0.0
	
	# Conecta os sinais do mouse para o fade
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# Esta é a função que seu Player/UI chama para equipar a cabeça
func equip_head(head_cfg: HeadRewardConfig):
	head_config = head_cfg
	

	texture = head_config.image
	
	# Chama a nova função para preencher os valores do tooltip
	_update_tooltip_labels()

# --- Lógica do Tooltip ---

func _update_tooltip_labels():
	# Garante que temos uma cabeça e que ela é do tipo correto
	if not head_config or not (head_config is HeadRewardConfig):
		stat_name_label.text = ""
		stat_value_label.text = ""
		return

	var cfg := head_config as HeadRewardConfig
	var buffs := cfg.array_of_buffs
	var stat_names_enum := PlayerStats.BuffableStats.keys()

	var names_text := ""
	var values_text := ""

	# 1. Itera pelos buffs dinâmicos da cabeça
	for buff: StatBuff in buffs:
		# Nome do Stat
		var buff_name : String = stat_names_enum[buff.stat].capitalize().replace("_", " ")
		names_text += buff_name + ":\n"

		# Valor do Stat
		var display_value := buff.buff_amount
		var suffix := ""
		if buff.buff_type == StatBuff.BuffType.MULTIPLY:
			display_value = buff.buff_amount * 100.0
			suffix = "%"
		
		var _sign := "+"
		if display_value < 0.0:
			_sign = "" # Deixa o formatador de número lidar com o sinal de menos

		values_text += _sign + _format_number(display_value, 1) + suffix + "\n"
	
	# 2. Adiciona o buff permanente (Evo), já que HeadRewardConfig também herda de RewardConfig
	var bonus_pct := cfg.perma_buff_amount * 100.0
	var evo_buff_name := _format_buff_name(cfg.perma_buff_type)
	
	names_text += "Evo:"
	values_text += "+" + _format_number(bonus_pct, 1) + "% " + evo_buff_name

	# Define o texto final
	stat_name_label.text = names_text
	stat_value_label.text = values_text


func _on_mouse_entered():
	# Se o slot não tiver uma cabeça, não mostra o tooltip
	if not head_config:
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

# --- Funções de Formatação (Copiadas do WeaponSlot) ---

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
	var _name : String = RewardConfig.PermaBuffType.keys()[buff_type]
	_name = _name.to_lower().capitalize()
	_name = _name.replace("_", " ")
	return _name

func _on_evolution_completed() -> void:
	# Limpa o slot de cabeça completamente
	head_config = null
	texture = null
	
	# Esconde e reseta o tooltip
	if fade_tween:
		fade_tween.kill()
	tooltip.visible = false
	
	# Limpa os textos do tooltip
	stat_name_label.text = ""
	stat_value_label.text = ""

@export var delay: float 
const EVO_POPUP_LABEL = preload("uid://cfjq54op7tnwd")
@onready var reward_manager_screen: RewardManager = $"../../../../../../../../.."
func _spawn_evo_popup() -> void:

	print("--- DEBUG POPUP ---")
	print("1. Função chamada no slot: ", name)
	
	# Verificação de segurança
	if not head_config:
		print("ERRO: head_config é null! O slot já foi limpo?")
		return

	var bonus_pct := head_config.perma_buff_amount * 100.0
	var buff_name := _format_buff_name(head_config.perma_buff_type)
	var text_to_show := "%s +%s%%" % [buff_name.to_upper(), _format_number(bonus_pct, 1)]
	
	print("2. Texto gerado: ", text_to_show)
	
	var popup = EVO_POPUP_LABEL.instantiate() as EvoPopupLabel
	popup.z_index = 100

	reward_manager_screen.add_child(popup)
	
	var spawn_pos = Vector2(196, 446)
	
	print("3. Popup instanciado na Posição Global: ", spawn_pos)
	print("4. Z-Index do popup: ", popup.z_index)
	
	# Inicia
	popup.setup_and_animate(spawn_pos, text_to_show, delay)
	print("--- FIM DEBUG ---")
