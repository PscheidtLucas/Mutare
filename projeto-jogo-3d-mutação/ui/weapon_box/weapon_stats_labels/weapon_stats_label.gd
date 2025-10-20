class_name WeaponStatsLabel
extends Label

enum StatType { 
	DAMAGE, 
	PROJ_COUNT, 
	FIRE_RATE, 
	ACCURACY, 
	PROJ_SPEED, 
	RANGE, 
	TRAN_BONUS 
}

@export var weapon_box: WeaponBox
@export var stat_type: StatType

func _ready() -> void:
	if weapon_box and not weapon_box.update_labels.is_connected(_on_update_labels):
		weapon_box.update_labels.connect(_on_update_labels)

# Arredonda e converte pra string com 'decimals' casas decimais.
func _format_number(value: float, decimals: int = 1) -> String:
	var mult := pow(10.0, float(decimals))
	# usa roundf para segurança de tipo
	var rounded := roundf(value * mult) / mult
	# remove trailing zeros desnecessários (ex: "2.0" -> "2")
	var s := str(rounded)
	if decimals > 0:
		# Garantir sempre que tenhamos pelo menos 'decimals' casas quando desejado
		# Ex: 2 -> "2.0" se decimals == 1
		# Usamos formatação simples com % (C-style) que funciona no GDScript:
		var fmt := "%"
		if decimals > 0:
			fmt += "." + str(decimals)
		fmt += "f"
		s = fmt % rounded
	return s

func _on_update_labels(weapon_config: RewardConfig) -> void:
	if weapon_config == null:
		text = "—"
		return

	if not (weapon_config is RangedWeaponConfig):
		text = "N/A"
		return

	weapon_config = weapon_config as RangedWeaponConfig

	match stat_type:
		StatType.DAMAGE:
			# damage é float; mostrar 1 casa decimal por padrão
			text = _format_number(weapon_config.damage, 1) 

		StatType.PROJ_COUNT:
			text = str(int(weapon_config.number_of_projectiles)) 

		StatType.FIRE_RATE:
			# tiros por segundo, 2 casas decimais costuma ficar melhor
			text = _format_number(weapon_config.fire_rate, 2) + " /s"

		StatType.ACCURACY:
			# accuracy fica entre 0.0 e 1.0 — converte para porcentagem
			var pct = weapon_config.accuracy * 100.0
			text = _format_number(pct, 1) + "%"

		StatType.PROJ_SPEED:
			#var proj_speed_stata = weapon_config.projectile_speed 
			#if proj_speed_stata <= 0.1:
				#get_parent().hide()
				#return
			
			text = _format_number(weapon_config.projectile_speed, 1) + " m/s"

		StatType.RANGE:
			text = _format_number(weapon_config.range, 1) + " m"

		StatType.TRAN_BONUS:
			# perma_buff_amount guarda um multiplicador tipo 0.14 -> 14%
			var bonus_pct := weapon_config.perma_buff_amount  * 100.0
			var buff_name := _format_buff_name(weapon_config.perma_buff_type)
			text = "+" + _format_number(bonus_pct, 1) + "% " + buff_name

		_:
			text = "—"

func _format_buff_name(buff_type: int) -> String:
	var name : String = RewardConfig.PermaBuffType.keys()[buff_type]
	name = name.to_lower().capitalize()
	name = name.replace("_", " ")
	return name
