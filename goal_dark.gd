extends Area2D

var type = "dark"
var player_inside = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("die") and body.type == type:
		player_inside = true
		check_victory()

func _on_body_exited(body):
	if body.has_method("die") and body.type == type:
		player_inside = false

func check_victory():
	var other_goal = get_tree().get_nodes_in_group("goal")
	for goal in other_goal:
		if goal != self and not goal.player_inside:
			return
	get_node("/root/Main").show_victory_screen()
