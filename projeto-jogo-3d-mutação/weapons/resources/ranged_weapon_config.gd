extends Resource
class_name Ranged_Weapon_Config

@export var name: String

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
@export var range: float
# Esse é meio óbvio né, valor de base (arma padrao) é de 20.0
@export var projectile_speed: float

@export var model: PackedScene
@export var bullet_scene: PackedScene

var damage: float
var fire_rate: float
var accuracy: float

# O damage_scale serve como um multiplicador no late-game para 
# deixar as armas com mais dano conforme o jogador vai avançando
func roll_stats(damage_scale: float = 1.0) -> void:
	damage = randf_range(damage_min, damage_max) * damage_scale
	fire_rate = randf_range(fire_rate_min, fire_rate_max)
	accuracy = randf_range(accuracy_min, accuracy_max)
