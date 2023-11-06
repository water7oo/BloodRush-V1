extends Area3D

func _on_Area2D_body_entered(body):
	if "PLAYER_COWBOY" in body.name:
		body.respawn()
		print_debug("Player has respawned")
	pass
