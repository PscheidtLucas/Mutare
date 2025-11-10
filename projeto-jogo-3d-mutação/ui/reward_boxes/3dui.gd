extends MarginContainer

@export var headbox: HeadBox

var head_ui_image: Node


func _ready() -> void:
	GameEvents.head_selected.connect(func(head_config) -> void:
		for child in get_children():
			child.queue_free()
			head_ui_image = null
		)

	if headbox and not headbox.update_labels.is_connected(_on_update_head):
		headbox.update_labels.connect(_on_update_head)

func _on_update_head(head_config: HeadRewardConfig) -> void:
	if head_config.ui_scene == null or head_config.ui_scene == "":
		return
	var head_ui_scene_path : String = head_config.ui_scene
	var loaded_scene := load(head_ui_scene_path)
	var instance : Control = loaded_scene.instantiate()
	add_child(instance)
	head_ui_image = instance
