extends Label

@export var player_stats: PlayerStats

func _ready() -> void:
	player_stats.health_changed.connect(set_text_based_on_stat_type)

func set_text_based_on_stat_type(head_config: HeadRewardConfig = null) -> void:
	if not player_stats:
		text = "N/A"
		return
	
	var value: float = player_stats.health
	var is_percentage: bool = false
	var show_plus: bool = false
	var decimal_places: int = 1
	
	# Converte para porcentagem se necessário
	if is_percentage:
		value *= 100.0

	# Formata o texto
	var formatted_value: String = ""
	
	if show_plus:
		if value > 0:
			formatted_value = "+"
		elif value < 0:
			formatted_value = "-"
	
	formatted_value += str(abs(snapped(value, 0.1)))
	
	if is_percentage:
		formatted_value += " %"
	
	text = formatted_value
