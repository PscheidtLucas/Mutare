extends Node

# UID → UID path da cena 3D
const UI_3D_SCENES := {
	"smg": "uid://cj02uiptxm4cm",
	"pistol": "uid://cppfoidptoola",
	"cannon": "uid://b0tcmmelme3mj",
	"pulse": "uid://b8t7hgybqk1pn",
}

# Cache real de PackedScenes
var cache: Dictionary = {}


func _ready() -> void:
	for key in UI_3D_SCENES:
		preload_scene(UI_3D_SCENES[key])


func preload_scene(uid_path: String) -> void:
	# Se já está pré-carregado, não faz nada
	if cache.has(uid_path):
		return

	# Evita erros caso o UID não exista no import database
	var packed := load(uid_path)
	if packed is PackedScene:
		cache[uid_path] = packed
	else:
		push_error("CacheUIScenes: Falhou ao carregar cena: %s" % uid_path)

func get_scene(uid_path: String) -> PackedScene:
	# Carrega sob demanda se não estiver no cache
	if not cache.has(uid_path):
		preload_scene(uid_path)

	return cache.get(uid_path, null)
