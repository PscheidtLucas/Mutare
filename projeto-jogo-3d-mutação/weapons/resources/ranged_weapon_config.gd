extends RewardConfig
class_name RangedWeaponConfig

@export var scene_uid : String
@export var name: String
@export var image: Texture2D
# Variaveis min e max sao responsaveis por estabelecer o range que o valor principal podera ser escolhid, estilo borderlands.
# Ex: uma arma com 150 de min e 180 de max pode rolar o valor de dano entre esses valores, quando o jogador
# passar o mouse por cima do numero de dano, deve aparecer os valores minimos e maximos de dano para ele saber
# quão bom/ruim foi o roll daquele stats.
@export var damage_min: float
@export var damage_max: float
# Fire rate determina quantos tiros por segundo são atirados.
@export var fire_rate_min: float
@export var fire_rate_max: float
# Accuracy determina o tamanho do angulo de spread horizontal das armas, vertical é sempre no msm plano para 
# os tiros não terem o risco de ir por cima dos inimigos ou pro chão, porque o jogo é top down.
# Varia de 0.0 a 1.0, representando porcentagem. 0.0 de accuracy resulta em um spread total de 180 graus (+-90),
# permitindo tiros até nas laterais da arma. 1.0 representa 0 graus de spread total.
@export var accuracy_min: float
@export var accuracy_max: float

# Número de projéteis determina o quantos projeteis são disparados por vez.
@export var number_of_projectiles: int
# Range em metros, determina o quao longe vai a bala
@export var min_range: float
@export var max_range: float
# Esse é meio óbvio né, valor de base (arma padrao) é de 20.0
@export var projectile_speed: float

@export var bullet_scene: PackedScene

var damage: float
var fire_rate: float
var accuracy: float
var range: float

## Chamar roll stats toda vez que for gerar uma arma seja para o jogador ou para o inimigo!


func roll_stats(damage_scale: float = 1.0) -> void:
	# 1. Rola um dado de 0.0 a 1.0 (0% a 100%)
	var luck_roll := randf()
	
	# Variáveis para controlar o "range" de perfeição (0.0 = min stat, 1.0 = max stat)
	var pct_min: float = 0.0
	var pct_max: float = 1.0
	var tier_name: String = "NORMAL" # Apenas para debug
	
	# 2. Decide o Tier baseado na sua tabela de chances
	if luck_roll >= 0.995:
	
		# [1%] PERFEITO (Rating 100 fixo)
		# Força todos os stats a serem o valor MAXIMO
		pct_min = 1.0
		pct_max = 1.0
		tier_name = "PERFECT (1%)"
		
	elif luck_roll >= 0.98:
		# [2%] LENDÁRIO (Rating 95+)
		# Força os stats a ficarem entre 90% e 99% do potencial máximo
		pct_min = 0.9
		pct_max = 0.99
		tier_name = "LEGENDARY (2%)"
		
	elif luck_roll <= 0.01: 
		# [1%] LIXO (Rating 50 fixo)
		# Força todos os stats a serem o valor MINIMO
		pct_min = 0.0
		pct_max = 0.1
		tier_name = "TRASH (1%)"
		
	else:
		# [96%] NORMAL (Rating variado, geralmente ~75)
		# Rola stats normais (entre 0% e 100% do range)
		pct_min = 0.0
		pct_max = 1.0
		tier_name = "NORMAL"

	# 3. Aplica os valores baseados no Tier escolhido
	# A função lerp(min, max, peso) pega um valor entre min e max.
	
	# Dano (com scale)
	var dmg_percent = randf_range(pct_min, pct_max)
	damage = lerp(damage_min, damage_max, dmg_percent) * damage_scale
	
	# Fire Rate
	var fr_percent = randf_range(pct_min, pct_max)
	fire_rate = lerp(fire_rate_min, fire_rate_max, fr_percent)
	
	# Accuracy
	var acc_percent = randf_range(pct_min, pct_max)
	accuracy = lerp(accuracy_min, accuracy_max, acc_percent)
	
	# Range
	var rng_percent = randf_range(pct_min, pct_max)
	range = lerp(min_range, max_range, rng_percent)
	
	# Buff Permanente (Também segue a sorte da arma!)
	var buff_percent = randf_range(pct_min, pct_max)
	perma_buff_amount = lerp(perma_buff_percent_min, perma_buff_percent_max, buff_percent)
	perma_buff_type = PermaBuffType.values().pick_random()

	# --- DEBUG PRINTS ---
	print("\n--- WEAPON ROLL: %s ---" % name)
	print("Luck Roll: %.4f | Tier: %s" % [luck_roll, tier_name])
	print("Damage: %.1f (Roll: %.0f%%)" % [damage, dmg_percent * 100])
	print("FireRate: %.2f (Roll: %.0f%%)" % [fire_rate, fr_percent * 100])
	print("Acc: %.2f (Roll: %.0f%%)" % [accuracy, acc_percent * 100])
	
	# Simulação rápida do Rating pra você conferir se bateu com o esperado
	var avg_quality = (dmg_percent + fr_percent + acc_percent + rng_percent) / 4.0
	var sim_rating = int(round(50 + (avg_quality * 50)))
	print(">> ESTIMATED RATING: %d" % sim_rating)
	print("-------------------------")
