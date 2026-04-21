extends Node2D

const PORT = 7000
var peer = ENetMultiplayerPeer.new()

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	$Player.set_multiplayer_authority(1)

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

@rpc("call_local")
func spawn_player(id):
	var player = preload("res://player.tscn").instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	add_child(player)

func _on_host_pressed():
	host_game()
	$CanvasLayer.hide()

func _on_join_pressed():
	var ip = $CanvasLayer/VBoxContainer/LineEdit.text
	join_game(ip)
	$CanvasLayer.hide()
