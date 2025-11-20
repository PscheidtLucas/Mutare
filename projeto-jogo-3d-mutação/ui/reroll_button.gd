extends TextureButton


# --- Configuração de Cores ---
const COLOR_HOVER := Color(1.5, 1.5, 1.5)
const COLOR_DISABLED := Color(0.6, 0.6, 0.6)
const COLOR_NORMAL := Color(1.0, 1.0, 1.0)

var reroll_cost: int = 5
var _is_hovering: bool = false

@export var node_to_change_color: MarginContainer
@export var reroll_price_label: Label

func _ready() -> void:
	# Conecta os sinais do mouse para controlar o hover
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Atualiza o texto inicial
	reroll_price_label.text = str(reroll_cost)
	
	# Faz uma checagem inicial de estado
	_check_affordability()
	GameEvents.wave_survived.connect(_check_affordability)
	_update_color()

# O _process garante que o botão bloqueie/desbloqueie assim que o dinheiro mudar
func _process(_delta: float) -> void:
	_check_affordability()

func _on_pressed() -> void:
	# O próprio botão disabled impede o click, mas checamos novamente por segurança
	var can_buy := DnaManager.try_spend_dna(reroll_cost)
	
	if can_buy:
		increase_reroll_price()
		GameEvents.do_reroll.emit()
		
		# Força uma atualização visual imediata após gastar o dinheiro
		_check_affordability()
		_update_color()

func increase_reroll_price() -> void:
	reroll_cost = int(ceil(reroll_cost * 1.11))
	reroll_price_label.text = str(reroll_cost)

# --- LÓGICA DE ESTADO E CORES ---

func _check_affordability() -> void:
	var player_money = DnaManager.current_dna 
	
	var can_afford = player_money >= reroll_cost
	
	# Se o estado de 'disabled' mudou, precisamos atualizar a cor
	if disabled == can_afford: # Se disabled é true e can_afford é true, algo está errado (deveria ser false)
		disabled = not can_afford
		_update_color()

func _update_color() -> void:
	if node_to_change_color == null:
		return

	# Prioridade 1: Se estiver desativado (sem dinheiro)
	if disabled:
		node_to_change_color.modulate = COLOR_DISABLED
	
	# Prioridade 2: Se o mouse estiver em cima (e não estiver disabled)
	elif _is_hovering:
		node_to_change_color.modulate = COLOR_HOVER
		
	# Prioridade 3: Estado normal
	else:
		node_to_change_color.modulate = COLOR_NORMAL

# Sinais do mouse apenas pedem para atualizar a cor baseada no estado atual
func _on_mouse_entered() -> void:
	_is_hovering = true
	_update_color()

func _on_mouse_exited() -> void:
	_is_hovering = false
	_update_color()
