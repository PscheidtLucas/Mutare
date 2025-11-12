class_name StatValue extends Label

@export var player_stats: PlayerStats
@export var stat_type: PlayerStats.BuffableStats

func _ready() -> void:
	set_text_based_on_stat_type()
	GameEvents.head_selected.connect(set_text_based_on_stat_type)

func set_text_based_on_stat_type(head_config: HeadRewardConfig = null) -> void:
	if not player_stats:
		text = "N/A"
		return
	
	var value: float = 0.0
	var is_percentage: bool = false
	var show_plus: bool = false
	var decimal_places: int = 1
	
	match stat_type:
		PlayerStats.BuffableStats.MAX_HEALTH:
			value = player_stats.max_health
			decimal_places = 1
		
		PlayerStats.BuffableStats.HP5:
			value = player_stats.hp5
			decimal_places = 1
		
		PlayerStats.BuffableStats.DAMAGE_INCREASE:
			value = player_stats.damage_increase
			is_percentage = true
			show_plus = value != 0
			decimal_places = 1
		
		PlayerStats.BuffableStats.SPEED_INCREASE:
			value = player_stats.speed_increase
			is_percentage = true
			show_plus = value != 0
			decimal_places = 1
		
		PlayerStats.BuffableStats.CRIT_CHANCE:
			value = player_stats.crit_chance
			is_percentage = true
			decimal_places = 1
		
		PlayerStats.BuffableStats.CRIT_DAMAGE_INCREASE:
			value = player_stats.crit_damage
			is_percentage = true
			decimal_places = 1
		
		PlayerStats.BuffableStats.FIRE_RATE_INCREASE:
			value = player_stats.fire_rate_increase
			is_percentage = true
			show_plus = value != 0
			decimal_places = 1
		
		PlayerStats.BuffableStats.COLLECT_AREA_INCREASE:
			value = player_stats.collect_area_increase
			is_percentage = true
			show_plus = true
			decimal_places = 1
		
		PlayerStats.BuffableStats.DAMAGE_REDUCTION_PERC:
			value = player_stats.damage_reduction_perc
			is_percentage = true
			decimal_places = 1
	
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
