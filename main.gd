extends Node2D

const PORT = 7000
var peer = ENetMultiplayerPeer.new()
var client_player = null # referencia al jugador del cliente

func _ready():
	# conectar señal cuando un jugador se une
	multiplayer.peer_connected.connect(_on_player_connected)
	# el jugador en escena siempre es el host con tipo luz
	$Player.set_multiplayer_authority(1)
	$Player.type = "light"
	
func host_game():
	# crear servidor en el puerto definido
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Server created on port ", PORT)

func join_game(ip: String):
	# conectarse al servidor con la ip ingresada
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip)

func _on_player_connected(id):
	# cuando alguien se conecta el host hace spawn del cliente
	if multiplayer.is_server():
		spawn_player.rpc(id)

@rpc("authority", "call_local")
func spawn_player(id):
	# instanciar jugador del cliente y asignarle tipo oscuridad
	var player = preload("res://player_light.tscn").instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.type = "dark"
	add_child(player)
	client_player = player
	client_player.set_physics_process(true)

func _on_host_pressed():
	host_game()
	$MainScreen.hide()
	$Player.set_physics_process(true)

func _on_join_pressed():
	var ip = $MainScreen/VBoxContainer/LineEdit.text
	join_game(ip)
	$MainScreen.hide()
	$Player.set_physics_process(true)

func show_death_screen():
	# pausar musica y mostrar pantalla de muerte
	$AudioStreamPlayer.stop()
	$DeathScreen.visible = true

@rpc("any_peer", "call_local")
func restart_game():
	# reiniciar ambos jugadores a su posicion inicial en ambas maquinas
	$DeathScreen.visible = false
	$Player.get_node("DeathSound").stop()
	if client_player != null:
		client_player.get_node("DeathSound").stop()
	if multiplayer.is_server():
		$AudioStreamPlayer.stop()
		$AudioStreamPlayer.play()
	$Player.visible = true
	$Player.set_physics_process(true)
	$Player.position = $Player.spawn_position
	$Player.velocity = Vector2.ZERO
	if client_player != null:
		client_player.visible = true
		client_player.set_physics_process(true)
		client_player.position = client_player.spawn_position
		client_player.velocity = Vector2.ZERO

func _on_death_button_pressed() -> void:
	restart_game.rpc()

func show_victory_screen():
	# llamar victoria en ambas maquinas via rpc
	show_victory_rpc.rpc()

@rpc("any_peer", "call_local")
func show_victory_rpc():
	# mostrar pantalla de victoria y reproducir sonido en ambas maquinas
	$VictoryScreen.visible = true
	$AudioStreamPlayer.stop()
	$VictorySound.play()

func _on_victory_button_pressed() -> void:
	victory_return()

func victory_return():
	# limpiar jugadores, desconectar red y volver al menu
	$Player.set_physics_process(false)
	if client_player != null:
		client_player.queue_free()
		client_player = null
	$Player.position = $Player.spawn_position
	$Player.velocity = Vector2.ZERO
	$VictorySound.stop()
	$VictoryScreen.visible = false
	$MainScreen.visible = true
	multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
