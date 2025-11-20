class_name PyramidEnemy extends Enemy

## O nó visual que vai girar (pode ser o MeshInstance ou um Node3D pai dele)
@export var model_anchor_node: Node3D

## Velocidade de rotação em Graus por segundo (360 = 1 volta completa por segundo)
@export var rotation_speed: float = 180.0 

# Usamos _process para rotação visual ficar bem lisa (smooth)
func _process(delta: float) -> void:
	if model_anchor_node:
		# Converte graus para radianos e rotaciona no eixo Y local do modelo
		model_anchor_node.rotate_y(deg_to_rad(rotation_speed) * delta)

# Sobrescrevemos apenas para adicionar alguma lógica específica se precisar,
# mas mantemos o super() para ele herdar toda a IA de perseguição
func _physics_process(delta: float) -> void:
	super(delta)
	# Se você quiser que a velocidade de rotação mude baseado no estado,
	# pode adicionar lógica aqui. Exemplo:
	# if current_state == State.CHASE:
	#     rotation_speed = 360.0
	# else:
	#     rotation_speed = 90.0
