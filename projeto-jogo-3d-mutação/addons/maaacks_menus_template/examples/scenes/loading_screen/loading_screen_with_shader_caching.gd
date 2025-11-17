extends LoadingScreen
## Loading Screen extension that pre-loads shaders before opening the next scene.

## Path to directory with the material shaders that should be pre-loaded.
@export_dir var _spatial_shader_material_dir : String
## Path to the scene that should trigger a shader pre-loading.
@export_file("*.tscn") var _cache_shaders_scene : String
## Mesh object that the material shaders should be applied to.
@export var _mesh : Mesh
@export_group("Advanced")
## Includes material scenes with extensions that match the strings.
@export var _matching_extensions : Array[String] = [".tres", ".material", ".res"]
## Excludes subfolders that match the strings.
@export var _ignore_subfolders : Array[String] = [".", ".."]
## Delay between loading each shader onto the mesh.
@export var _shader_delay_timer : float = 0.1

var _loading_shader_cache : bool = false

var _caching_progress : float = 0.0 :
	set(value):
		if value <= _caching_progress:
			return
		_caching_progress = value
		update_total_loading_progress()
		_reset_loading_stage()

func can_load_shader_cache() -> bool:
	return not _spatial_shader_material_dir.is_empty() and \
	not _cache_shaders_scene.is_empty() and \
	SceneLoader.is_loading_scene(_cache_shaders_scene)

func update_total_loading_progress() -> void:
	var partial_total := _scene_loading_progress
	if can_load_shader_cache():
		partial_total += _caching_progress
		partial_total /= 2
	_total_loading_progress = partial_total

func _set_scene_loading_complete() -> void:
	super._set_scene_loading_complete()
	
	# PRINT DE DEBUG
	if can_load_shader_cache() and not _loading_shader_cache:
		print_rich("[color=yellow]--- INICIANDO CACHE DE SHADERS ---[/color]")
		_loading_shader_cache = true
		_show_all_draw_passes_once()
	elif not can_load_shader_cache() and not _loading_shader_cache:
		# Se não entrar no cache, avisa o porquê
		if _spatial_shader_material_dir.is_empty(): print("Cache ignorado: Pasta vazia")
		elif not SceneLoader.is_loading_scene(_cache_shaders_scene): print("Cache ignorado: Não é a cena alvo")
	
	if can_load_shader_cache() and _caching_progress < 1.0:
		return
	
	# PRINT DE DEBUG
	if _loading_shader_cache:
		print_rich("[color=green]--- CACHE FINALIZADO. INICIANDO JOGO ---[/color]")
		
	SceneLoader._background_loading = false
	SceneLoader.set_process(true)

func _show_all_draw_passes_once() -> void:
	var all_materials := _traverse_folders(_spatial_shader_material_dir)
	var total_material_count := all_materials.size()
	
	# PRINT DE DEBUG
	print_rich("[color=cyan]Materiais encontrados na pasta: %s[/color]" % total_material_count)
	
	var cached_material_count := 0
	for material_path in all_materials:
		_load_material(material_path)
		cached_material_count += 1
		_caching_progress = float(cached_material_count) / total_material_count
		if _shader_delay_timer > 0:
			await(get_tree().create_timer(_shader_delay_timer).timeout)

func _traverse_folders(dir_path:String) -> PackedStringArray:
	var material_list:PackedStringArray = []
	if not dir_path.ends_with("/"):
		dir_path += "/"
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("failed to access the path ", dir_path)
		return []
	if dir.list_dir_begin() != OK:
		push_error("failed to access the path ", dir_path)
		return []
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var matches : bool = false
			for extension in _matching_extensions:
				if file_name.ends_with(extension):
					matches = true
					break
			if matches:
				material_list.append(dir_path + file_name)
		else:
			var subfolder_name := file_name
			if not subfolder_name in _ignore_subfolders:
				material_list.append_array(_traverse_folders(dir_path + subfolder_name))
		file_name = dir.get_next()
	
	return material_list

func _load_material(path:String) -> void:
	# PRINT DE DEBUG
	print("Carregando shader: %s" % path.get_file())
	
	var material_shower := MeshInstance3D.new()
	material_shower.mesh = _mesh
	var material := ResourceLoader.load(path) as Material
	
	# PRINT DE DEBUG
	if material == null:
		print_rich("[color=red]ERRO: Falha ao carregar material ou arquivo inválido![/color]")
	
	material_shower.set_surface_override_material(0, material)
	%SpatialShaderTypeCaches.add_child(material_shower)

func _ready() -> void:
	if OS.has_feature("web"):
		%ProgressBar.hide()
	# PRINT DE DEBUG
	print_rich("[color=yellow]Loading Screen Iniciada.[/color]")
	print("Pasta Alvo: %s" % _spatial_shader_material_dir)
	print("Cena Alvo: %s" % _cache_shaders_scene)
	
	SceneLoader._background_loading = true
