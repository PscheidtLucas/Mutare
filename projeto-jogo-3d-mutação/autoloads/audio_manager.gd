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
	player.pitch_scale = pitch_scale + randf_range(-random_pitch, random_pitch)
	player.play()
# -------------------------------------------------------------
#	Música: trocas mais controladas
# -------------------------------------------------------------
var t_out: Tween
var t_in: Tween

func play_music(stream : AudioStream) -> void:
	# 1. Verifica se já é a música DESEJADA (intenção atual)
	if current_music == stream:
		# Se já está tocando e tocando (ou em processo de tocar), sai.
		if music_player.playing:
			return
		# Se estava pausada ou parada, deixamos continuar para dar play

	# 2. Atualiza a intenção IMEDIATAMENTE
	# Isso impede que uma chamada futura ache que a música antiga ainda é a vigente
	current_music = stream

	var prev_player := music_player
	
	# Mata tweens anteriores para evitar conflitos
	if t_out:
		t_out.kill()
	if t_in:
		t_in.kill()
	
	# Fade-out fixo
	if prev_player.playing:
		t_out = create_tween()
		t_out.tween_property(prev_player, "volume_db", -40.0, fade_time)
		
		# Espera o fade acabar
		await t_out.finished
		
		# 3. CHECAGEM DE SEGURANÇA PÓS-AWAIT
		# Se, durante esse tempo de espera (await), alguém chamou play_music de novo,
		# a variável 'current_music' terá mudado. Se mudou, abortamos essa execução antiga.
		if current_music != stream:
			return 

		prev_player.stop()

	# 4. Checagem Dupla (caso o player não estivesse tocando, mas a música mudou rápido)
	if current_music != stream:
		return

	# Toca a música nova
	music_player.stream = stream # Usa a variável local ou current_music (que agora são iguais)
	music_player.volume_db = -40.0
	music_player.play()

	# Fade-in com destino fixo
	t_in = create_tween()
	t_in.tween_property(music_player, "volume_db", 0.0, fade_time)
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

		# guarda o volume atual
		_stored_music_volume = music_player.volume_db

		# diminui até -15
		if t_v:
			t_v.kill()
		t_v = create_tween()
		t_v.tween_property(music_player, "volume_db", -15.0, 0.3)

	else:
		if not _is_music_paused:
			return
		_is_music_paused = false

		# restaura o volume anterior
		if t_v:
			t_v.kill()
		t_v = create_tween()
		t_v.tween_property(music_player, "volume_db", _stored_music_volume, 0.3)
