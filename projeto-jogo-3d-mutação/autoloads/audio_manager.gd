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
func play_music(stream : AudioStream) -> void:
	if current_music == stream and music_player.playing:
		return

	var prev_player := music_player

	# Fade-out fixo
	if prev_player.playing:
		var t_out := create_tween()
		t_out.tween_property(prev_player, "volume_db", -40.0, fade_time)
		await t_out.finished
		prev_player.stop()

	# Troca a música
	current_music = stream
	music_player.stream = current_music
	music_player.volume_db = -40.0
	music_player.play()

	# Fade-in com destino fixo (não mais "old_volume")
	var t_in := create_tween()
	t_in.tween_property(music_player, "volume_db", 0.0, fade_time)


# -------------------------------------------------------------
#	Utilidades
# -------------------------------------------------------------
func _find_free_player(pool: Array[AudioStreamPlayer]) -> AudioStreamPlayer:
	for p in pool:
		if not p.playing:
			return p
	return null


func _fade_volume(player: AudioStreamPlayer, from_db: float, to_db: float, time: float) -> void:
	var t := create_tween()
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
		var t := create_tween()
		t.tween_property(music_player, "volume_db", -15.0, 0.3)

	else:
		if not _is_music_paused:
			return
		_is_music_paused = false

		# restaura o volume anterior
		var t := create_tween()
		t.tween_property(music_player, "volume_db", _stored_music_volume, 0.3)
