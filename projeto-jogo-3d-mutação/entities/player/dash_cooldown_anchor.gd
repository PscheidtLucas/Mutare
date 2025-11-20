extends Node3D

@onready var dash_cooldown_timer: Timer = $"../StateMachine/DashCooldownTimer"
@onready var dash_progress_bar: ProgressBar = $DashBarSprite/SubViewport/DashProgressBar
@onready var dash_bar_sprite: Sprite3D = $DashBarSprite

func _ready() -> void:
	# Garante que a barra comece visível e atualizada
	dash_bar_sprite.visible = true
	update_dash_bar()

func _process(delta: float) -> void:
	update_dash_bar()

func update_dash_bar() -> void:
	# Verifica se o timer está parado (Dash PRONTO)
	if dash_cooldown_timer.is_stopped():
		dash_bar_sprite.visible = true # Agora mantemos visível
		dash_progress_bar.value = 100  # Força a barra a ficar cheia
	
	# Se o timer está rodando (Dash em COOLDOWN)
	else:
		dash_bar_sprite.visible = true
		
		# Calcula quanto já passou do tempo (vai de 0.0 a 1.0)
		var ratio = 1.0 - (dash_cooldown_timer.time_left / dash_cooldown_timer.wait_time)
		
		dash_progress_bar.value = ratio * 100
