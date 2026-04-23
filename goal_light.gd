extends Area2D

var type = "light" # tipo de meta
var player_inside = false # indica si el jugador correcto esta dentro

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	# si el jugador es del tipo correcto marcar como dentro y revisar victoria
	if body.has_method("die") and body.type == type:
		player_inside = true
		check_victory()

func _on_body_exited(body):
	# si el jugador correcto sale, ya no esta dentro
	if body.has_method("die") and body.type == type:
		player_inside = false

func check_victory():
	# revisar si todas las metas tienen a su jugador dentro
	var other_goal = get_tree().get_nodes_in_group("goal")
	for goal in other_goal:
		if goal != self and not goal.player_inside:
			return
	# si todas las metas estan activas, llamar victoria
	get_node("/root/Main").show_victory_screen()
