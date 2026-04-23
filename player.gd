extends CharacterBody2D

const SPEED = 450.0
const JUMP_FORCE = -600.0
const GRAVITY = 1750.0
var type = "light"
var spawn_position = Vector2.ZERO

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and is_multiplayer_authority():
		if Input.is_action_pressed("ui_right"):
			velocity.x = SPEED
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -SPEED
		else:
			velocity.x = 0
			
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_FORCE
		
		sync_position.rpc(position)

	move_and_slide()
	
@rpc("any_peer", "unreliable")
func sync_position(pos: Vector2):
	if not is_multiplayer_authority():
		position = pos

func die():
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and is_multiplayer_authority():
		die_rpc.rpc()

@rpc("any_peer", "call_local")
func die_rpc():
	visible = false
	set_physics_process(false)
	get_node("/root/Main").show_death_screen()

func _ready():
	spawn_position = position
	set_physics_process(false)
