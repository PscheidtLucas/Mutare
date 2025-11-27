extends Node

@export var sfx_bus: StringName = &"SFX"
@export var music_bus: StringName = &"Music"

# Pools de players reutilizáveis
@export var pool_size_sfx := 12
@export var pool_size_music := 2

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []

@export var fade_time := 1.2

var current_music : AudioStream = null
var music_player : AudioStreamPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_pools()
	# Um único player de música, fácil de gerenciar
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)


func _init_pools() -> void:
	for i in pool_size_sfx:
		var p := AudioStreamPlayer.new()
		p.bus = sfx_bus
		add_child(p)
		_sfx_players.append(p)

	for i in pool_size_music:
		var m := AudioStreamPlayer.new()
		m.bus = music_bus
		add_child(m)
		_music_players.append(m)
# -------------------------------------------------------------
#	SFX: sons rápidos e múltiplos
# -------------------------------------------------------------
func play_sfx(
		stream: AudioStream,
		volume_db: float = 0.0,
		pitch_scale: float = 1.0,
		random_pitch: float = 0.15
) -> void:
	if stream == null:
		return

	var player := _find_free_player(_sfx_players)
	if player == null:
		# tudo ocupado: pega o mais antigo
		player = _sfx_players[0]

	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	var final_pitch := pitch_scale + randf_range(-random_pitch, random_pitch)
	final_pitch = max(final_pitch, 0.05) # garante pitch válido
	player.pitch_scale = final_pitch
	player.play()
# -------------------------------------------------------------
#	Música: trocas mais controladas
# -------------------------------------------------------------
var t_out: Tween
var t_in: Tween

func play_music(stream : AudioStream) -> void:
	# 1. Verifica se já é a música DESEJADA
	if current_music == stream:
		if music_player.playing:
			return

	# 2. Atualiza a intenção
	current_music = stream

	var prev_player := music_player
	
	if t_out: t_out.kill()
	if t_in: t_in.kill()
	
	# Fade-out fixo
	if prev_player.playing:
		t_out = create_tween()
		t_out.tween_property(prev_player, "volume_db", -40.0, fade_time)
		
		# O código dorme aqui...
		await t_out.finished
		# ... E ACORDA AQUI. O mundo pode ter mudado (jogo pausado).
		
		if current_music != stream:
			return 

		prev_player.stop()

	if current_music != stream:
		return

	music_player.stream = stream
	
	# --- CORREÇÃO DA LÓGICA DE PAUSE ---
	if _is_music_paused:
		# Se acordamos e o jogo está pausado, NÃO fazemos fade para 0.0.
		# Vamos direto para o volume de pause (-15) e tocamos.
		music_player.volume_db = -15.0
		music_player.play()
		
		# TRUQUE: Forçamos o "volume salvo" a ser 0.0. 
		# Assim, quando o jogador despausar, o set_music_paused(false)
		# vai ler esse 0.0 e levar a música para o volume máximo correto.
		_stored_music_volume = 0.0
	else:
		# Comportamento padrão (Fade In normal)
		music_player.volume_db = -40.0
		music_player.play()

		t_in = create_tween()
		t_in.tween_property(music_player, "volume_db", 0.0, fade_time)
	# -----------------------------------
# -------------------------------------------------------------
#	Utilidades
# -------------------------------------------------------------
func _find_free_player(pool: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for p in pool:
		if not p.playing:
			return p
	return null

var t: Tween
func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, time: float) -> void:
	if t:
		t.kill()
	t = create_tween()
	t.tween_property(player, "volume_db", to_db, time).from(from_db)


# -------------------------------------------------------------
#	Funções extra para facilitar a vida
# -------------------------------------------------------------
func stop_all_sfx() -> void:
	for p in _sfx_players:
		p.stop()

func stop_all_music() -> void:
	for m in _music_players:
		m.stop()

var _stored_music_volume := 0.0
var _is_music_paused := false
var t_v
func set_music_paused(paused: bool) -> void:
	if music_player == null:
		return

	if paused:
		if _is_music_paused:
			return
		_is_music_paused = true

		# --- CORREÇÃO DO BUG ---
		# Verificamos se o tween de Fade In (t_in) existe e está rodando.
		if t_in and t_in.is_valid() and t_in.is_running():
			# Se estamos no meio de uma transição de entrada, o volume atual está "incompleto".
			# Então, matamos o fade-in...
			t_in.kill()
			# ...e forçamos o volume salvo a ser 0.0 (o volume normal cheio)
			_stored_music_volume = 0.0
		else:
			# Se não tem fade rolando, aí sim podemos confiar no volume atual
			_stored_music_volume = music_player.volume_db
		# -----------------------

		# diminui até -15 (Efeito abafado)
		if t_v:
			t_v.kill()
		t_v = create_tween()
		t_v.tween_property(music_player, "volume_db", -15.0, 0.3)

	else:
		if not _is_music_paused:
			return
		_is_music_paused = false

		# restaura o volume anterior (que agora será 0.0 se interrompemos um fade, ou o original)
		if t_v:
			t_v.kill()
		t_v = create_tween()
		t_v.tween_property(music_player, "volume_db", _stored_music_volume, 0.3)
