extends Area2D

var type = "light" # tipo de meta
var player_inside = false # indica si el jugador correcto esta dentro

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$AnimatedSprite2D.play("idle")
	
func _on_body_entered(body):
	# si el jugador es del tipo correcto marcar como dentro y revisar victoria
	if body.has_method("die") and body.type == type:
		player_inside = true
		$AnimatedSprite2D.play("open")
		check_victory()

func _on_body_exited(body):
	# si el jugador correcto sale, ya no esta dentro
	if body.has_method("die") and body.type == type:
		player_inside = false
		$AnimatedSprite2D.play("idle")

func check_victory():
	var other_goal = get_tree().get_nodes_in_group("goal2")
	for goal in other_goal:
		if goal != self and not goal.player_inside:
			return
	get_node("/root/Main").show_victory_screen()
