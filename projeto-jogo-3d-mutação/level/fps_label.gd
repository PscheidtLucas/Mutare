extends Label

#func _ready() -> void:
	#if Engine.is_editor_hint():
		#pass
	#else:
		#self.queue_free()
		

func _process(delta: float) -> void:
	text = "FPS: " + str(Engine.get_frames_per_second())
