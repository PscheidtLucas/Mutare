@tool
class_name RotateChild extends Node3D

@export_group("Configurações da Rotação")
## Duração (em segundos) para uma rotação completa de 360 graus.
@export var rotation_duration: float = 5.0:
	set(value):
		rotation_duration = value
		# Garante que a duração seja positiva para evitar erros
		if rotation_duration <= 0:
			rotation_duration = 0.01
		_restart_tween()

## Eixo ao redor do qual o filho irá rotacionar. Padrão (0, 1, 0) para girar em torno do eixo Y.
@export var rotation_axis: Vector3 = Vector3.UP:
	set(value):
		rotation_axis = value
		_restart_tween()

@export_group("Controles do Editor")
## Botões para controlar a rotação de preview no editor.
@export_tool_button("Ativar Rotação no Editor") var _start_btn = _start_editor_rotation
@export_tool_button("Parar Rotação no Editor") var _stop_btn = _stop_editor_rotation


var tween: Tween

# Chamado quando o nó entra na árvore da cena (no jogo ou no editor).
func _ready() -> void:
	# No jogo, inicia a rotação automaticamente.
	if not Engine.is_editor_hint():
		call_deferred("start_rotation_tween")


# Esta função reinicia o tween. É chamada pelos 'setters' das variáveis exportadas.
func _restart_tween() -> void:
	if not is_inside_tree():
		return
	
	# Se estivermos no jogo, reinicia o tween.
	if not Engine.is_editor_hint():
		start_rotation_tween()
	# Se estivermos no editor, SÓ reinicia se o tween já estiver ativo
	# (ou seja, se o usuário clicou em "Ativar Rotação")
	elif tween and tween.is_valid():
		start_rotation_tween()

# ---- Funções dos Botões do Editor ----

func _start_editor_rotation():
	if not Engine.is_editor_hint():
		print("Este botão funciona apenas no editor.")
		return
	if not is_inside_tree():
		push_warning("RotateChild: Nó não está na árvore da cena.")
		return
	
	print("RotateChild: Iniciando rotação no editor...")
	start_rotation_tween()

func _stop_editor_rotation():
	if not Engine.is_editor_hint():
		print("Este botão funciona apenas no editor.")
		return

	print("RotateChild: Parando rotação no editor...")
	if tween and tween.is_valid():
		tween.kill()
	
	# Reseta a rotação do filho
	_reset_child_rotation()

# Função auxiliar para resetar a rotação do filho
func _reset_child_rotation():
	if get_child_count() > 0:
		var child = get_child(0)
		if child is Node3D:
			child.rotation = Vector3.ZERO

# ----------------------------------------

# Configura e inicia o tween de rotação
func start_rotation_tween() -> void:
	# 1. Limpa qualquer tween anterior que possa estar rodando
	if tween and tween.is_valid():
		tween.kill()

	# 2. Verifica se há um filho para rotacionar
	if get_child_count() == 0:
		if Engine.is_editor_hint():
			print("RotateChild: Aguardando um nó filho para rotacionar.")
		return

	var child = get_child(0)
	if not child is Node3D:
		if Engine.is_editor_hint():
			print("RotateChild: O primeiro filho não é um Node3D.")
		return
		
	# 3. Reseta a rotação do filho para um loop limpo e consistente
	child.rotation = Vector3.ZERO

	# 4. Cria e configura o Tween
	tween = create_tween()
	tween.set_loops() # Loop infinito
	tween.set_trans(Tween.TRANS_LINEAR) # Transição linear para velocidade constante
	tween.set_ease(Tween.EASE_IN_OUT)   # Sem aceleração/desaceleração

	# 5. Define a animação
	tween.tween_property(
		child,                          # O alvo
		"rotation",                     # A propriedade a animar
		rotation_axis.normalized() * 2 * PI, # O valor final (360 graus no eixo)
		rotation_duration               # A duração
	).from(Vector3.ZERO) # Garante que cada loop comece do zero


# Garante que o tween reinicie sozinho SE ESTIVER NO JOGO.
func _process(delta: float) -> void:
	# No jogo, garante que o tween esteja sempre rodando
	if not Engine.is_editor_hint():
		if tween == null or not tween.is_valid():
			start_rotation_tween()
