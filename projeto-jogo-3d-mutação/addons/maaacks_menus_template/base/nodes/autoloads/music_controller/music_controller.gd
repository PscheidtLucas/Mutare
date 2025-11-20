extends Node

@onready var player := AudioStreamPlayer.new()

var current_music: AudioStream = null
var fade_tween: Tween = null
var is_fading := false

func _ready() -> void:
	player.bus = "Music"
	player.autoplay = false
	player.stream = null
	player.volume_db = 0
	add_child(player)

func play_music(stream: AudioStream, fade_time := 0.5) -> void:
	if stream == current_music:
		return
	
	# Evita explosão de tweens
	_cancel_fade()
	
	is_fading = true
	current_music = stream
	
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", -80, fade_time)
	fade_tween.tween_callback(Callable(self, "_swap_and_fade_in")).bind(stream, fade_time)
	fade_tween.finished.connect(_on_fade_finished)

func _swap_and_fade_in(stream: AudioStream, fade_time: float) -> void:
	player.stream = stream
	player.play()
	
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", 0, fade_time)
	fade_tween.finished.connect(_on_fade_finished)

func stop_music(fade_time := 0.5) -> void:
	_cancel_fade()
	
	is_fading = true
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", -80, fade_time)
	fade_tween.tween_callback(Callable(player, "stop"))
	fade_tween.finished.connect(_on_fade_finished)

func _cancel_fade() -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	fade_tween = null
	is_fading = false

func _on_fade_finished() -> void:
	is_fading = false
