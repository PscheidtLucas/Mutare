class_name HeadRewardConfig extends RewardConfig

@export var name: String
@export var scene_uid: String
@export var array_of_buffs: Array[StatBuff]
@export var image: Texture2D

func roll_stats(damage_scale: float = 1.0) -> void:
	# 1. Define a sorte geral do Capacete
	var luck_roll := randf()
	
	var pct_min: float = 0.0
	var pct_max: float = 1.0
	var tier_name: String = "NORMAL"
	
	# 2. Define o Tier (Sem o Tier "Ruim")
	if luck_roll >= 0.995:
		# [1%] PERFEITO
		pct_min = 1.0
		pct_max = 1.0
		tier_name = "PERFECT (1%)"
		
	elif luck_roll >= 0.98:
		# [2%] LENDÁRIO
		pct_min = 0.9
		pct_max = 0.99
		tier_name = "LEGENDARY (2%)"
		
	elif luck_roll <= 0.01:
		# [1%] LIXO
		pct_min = 0.0
		pct_max = 0.1
		tier_name = "TRASH (1%)"
		
	else:
		# [96%] NORMAL (O resto do intervalo: 0.01 até 0.97)
		pct_min = 0.0
		pct_max = 1.0
		tier_name = "NORMAL"

	# --- DEBUG HEADER ---
	print("\n--- HEAD ROLL: %s ---" % name)
	print("Luck Roll: %.4f | Tier: %s" % [luck_roll, tier_name])

	# 3. Aplica a sorte para CADA buff dentro do array
	for stat: StatBuff in array_of_buffs:
		# Rola a porcentagem individual deste stat respeitando os limites do Tier
		var stat_percent = randf_range(pct_min, pct_max)
		
		# Calcula o valor final usando lerp
		stat.buff_amount = lerp(stat.min_buff_amount, stat.max_buff_amount, stat_percent)
		
		# Print de debug para cada stat
		# (Assumindo que StatBuff tem uma prop 'stat_type' ou similar para mostrar nome, senão use só index)
		print(" > Stat Roll: %.2f (%.0f%% do max)" % [stat.buff_amount, stat_percent * 100])

	# 4. Aplica a mesma sorte para o Buff Permanente (Evo)
	var buff_percent = randf_range(pct_min, pct_max)
	perma_buff_amount = lerp(perma_buff_percent_min, perma_buff_percent_max, buff_percent)
	perma_buff_type = PermaBuffType.values().pick_random()
	
	print(" > Evo Roll: %.1f%% (%.0f%% do max)" % [perma_buff_amount * 100, buff_percent * 100])
	print("-----------------------")
