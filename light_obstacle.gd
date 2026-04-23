extends Area2D

var type = "light" # tipo del obstaculo

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# si el jugador es de tipo contrario al obstaculo, muere
	if body.has_method("die") and body.type != type:
		body.die()
