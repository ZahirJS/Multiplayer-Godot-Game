extends CharacterBody2D

const SPEED = 450.0
const JUMP_FORCE = -700.0
const GRAVITY = 1750.0
var type = "light" # tipo del jugador: light o dark
var spawn_position = Vector2.ZERO # posicion inicial guardada al arrancar

func _ready():
	# guardar posicion inicial y desactivar fisica hasta que inicie la partida
	spawn_position = position
	set_physics_process(false)

func _physics_process(delta):
	# aplicar gravedad cuando esta en el aire
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# solo el jugador dueno del personaje puede controlarlo
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and is_multiplayer_authority():
		if Input.is_action_pressed("ui_right"):
			velocity.x = SPEED
			$AnimatedSprite2D.flip_h = false
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -SPEED
			$AnimatedSprite2D.flip_h = true
		else:
			velocity.x = 0
			
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_FORCE
		
		# sincronizar posicion y animacion con el otro jugador
		sync_position.rpc(position)
		sync_animation.rpc($AnimatedSprite2D.animation, $AnimatedSprite2D.flip_h)

	move_and_slide()
	update_animation()

func update_animation():
	# cambiar animacion segun el estado del jugador
	if not is_on_floor():
		$AnimatedSprite2D.play("jump")
	elif velocity.x != 0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")

@rpc("any_peer", "unreliable")
func sync_position(pos: Vector2):
	# actualizar posicion en la maquina que no es duena del personaje
	if not is_multiplayer_authority():
		position = pos

@rpc("any_peer", "unreliable")
func sync_animation(anim: String, flip: bool):
	# actualizar animacion y direccion en la maquina que no es duena
	if not is_multiplayer_authority():
		$AnimatedSprite2D.play(anim)
		$AnimatedSprite2D.flip_h = flip

func die():
	# solo el dueno del personaje puede iniciar la muerte
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and is_multiplayer_authority():
		die_rpc.rpc()

@rpc("any_peer", "call_local")
func die_rpc():
	# ocultar jugador y mostrar pantalla de muerte en ambas maquinas
	visible = false
	set_physics_process(false)
	$DeathSound.play()
	get_node("/root/Main").show_death_screen()
