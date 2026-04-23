extends Node2D

const PORT = 7000
var peer = ENetMultiplayerPeer.new()
var client_player = null

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	$Player.set_multiplayer_authority(1)
	$Player.type = "light"
	
func host_game():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print("Server created on port ", PORT)

func join_game(ip: String):
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Connecting to ", ip)

func _on_player_connected(id):
	if multiplayer.is_server():
		spawn_player.rpc(id)

@rpc("authority", "call_local")
func spawn_player(id):
	var player = preload("res://player.tscn").instantiate()
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
	$DeathScreen.visible = true

@rpc("any_peer", "call_local")
func restart_game():
	$DeathScreen.visible = false
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
	show_victory_rpc.rpc()

@rpc("any_peer", "call_local")
func show_victory_rpc():
	$VictoryScreen.visible = true

func _on_victory_button_pressed() -> void:
	victory_return()

func victory_return():
	$Player.set_physics_process(false)
	if client_player != null:
		client_player.queue_free()
		client_player = null
	$Player.position = $Player.spawn_position
	$Player.velocity = Vector2.ZERO
	multiplayer.multiplayer_peer = null
	peer = ENetMultiplayerPeer.new()
	$VictoryScreen.visible = false
	$MainScreen.visible = true
