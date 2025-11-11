extends Label

@export var game_state: GameState

func _ready() -> void:
	setup.call_deferred()

func setup() -> void:
	text = str(game_state.wave_number)
	game_state.wave_number_changed.connect(func() -> void:
		text = str(game_state.wave_number)
		)
