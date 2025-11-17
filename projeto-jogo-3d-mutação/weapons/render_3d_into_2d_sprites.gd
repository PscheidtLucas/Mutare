@tool
class_name Render3Dto2D extends SubViewport

@export var rows: int = 8
@export var columns: int = 8

@export var anchor_rotate_node: Node3D
@export var model : Node3D

@export_tool_button("Generate Spritesheet")
var generate_sprite = func():
	var angle = 0.0
	var format = get_texture().get_image().get_format()
	var result = Image.create_empty(size.x * columns, size.y * rows, false, format)
	for r in rows:
		for c in columns:
			anchor_rotate_node.rotation.y = angle
			await RenderingServer.frame_post_draw
			var image = get_texture().get_image()
			result.blit_rect(image, Rect2i(0, 0, size.x, size.y), Vector2i(size.x * c, size.y * r))
			angle += TAU / (rows * columns)
	
	result.save_png("res://" + str(model.name) + ".png" )
