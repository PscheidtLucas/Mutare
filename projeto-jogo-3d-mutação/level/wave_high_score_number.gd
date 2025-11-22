class_name WaveHighScoreLabel extends Label


func _ready() -> void:
	text = str(SaveManager.high_score.highest_wave)
	SaveManager.high_score.changed.connect(_update_label)

func _update_label() -> void:
	text = str(SaveManager.high_score.highest_wave)
