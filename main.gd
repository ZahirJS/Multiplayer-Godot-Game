extends Node2D

const PORT = 7000
var peer = ENetMultiplayerPeer.new()
var client_player = null # referencia al jugador del cliente
var victory_reached = false

func _ready():
	# conectar señal cuando un jugador se une
	multiplayer.peer_connected.connect(_on_player_connected)
	# el jugador en escena siempre es el host con tipo luz
	$Player.set_multiplayer_authority(1)
	$Player.type = "light"
	$Fade/ColorRect.color.a = 0
	$HUD.visible = false

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
	if not multiplayer.is_server():
		player.get_node("Label").visible = true
	client_player = player
	client_player.set_physics_process(true)

func _on_host_pressed():
	fade_transition(func():
		host_game()
		$MainScreen.hide()
		$Player.set_physics_process(true)
		$HUD.visible = true
		$Player.get_node("Label").visible = true
	)

func _on_join_pressed():
	var ip = $MainScreen/VBoxContainer/LineEdit.text
	fade_transition(func():
		join_game(ip)
		$MainScreen.hide()
		$Player.set_physics_process(true)
		$HUD.visible = true
	)

func show_death_screen():
	# pausar musica y mostrar pantalla de muerte con fade
	$AudioStreamPlayer.stop()
	fade_transition(func():
		$DeathScreen.visible = true
		$HUD.visible = false
	)

@rpc("any_peer", "call_local")
func restart_game():
	# reiniciar ambos jugadores a su posicion inicial en ambas maquinas
	fade_transition(func():
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
		$HUD.visible = true
	)

func _on_death_button_pressed() -> void:
	restart_game.rpc()

func show_victory_screen():
	if victory_reached:
		return
	victory_reached = true
	show_victory_rpc.rpc()

@rpc("any_peer", "call_local")
func show_victory_rpc():
	$AudioStreamPlayer.stop()
	fade_transition(func():
		$Player.set_physics_process(false)
		if client_player != null:
			client_player.set_physics_process(false)
		$VictoryScreen.visible = true
		$VictorySound.play()
		$HUD.visible = false
	)

func _on_victory_button_pressed() -> void:
	fade_transition(func():
		victory_return()
	)

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
	$HUD.visible = false
	$Player.get_node("Label").visible = false
	victory_reached = false

func fade_transition(callable):
	var tween = create_tween()
	$Fade/ColorRect.color.a = 0
	tween.tween_property($Fade/ColorRect, "color:a", 1, 0.5)
	await tween.finished
	callable.call()
	tween = create_tween()
	tween.tween_property($Fade/ColorRect, "color:a", 0, 0.5)
	
func _on_pause_button_pressed():
	pause_game.rpc()

@rpc("any_peer", "call_local")
func pause_game():
	$PauseScreen.visible = true
	get_tree().paused = true

func _on_resume_button_pressed():
	resume_game.rpc()

@rpc("any_peer", "call_local")
func resume_game():
	$PauseScreen.visible = false
	get_tree().paused = false

func _on_close_button_pressed():
	close_game.rpc()

@rpc("any_peer", "call_local")
func close_game():
	get_tree().quit()

func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
