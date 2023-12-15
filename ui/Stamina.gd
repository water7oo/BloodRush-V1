extends ProgressBar


func _ready():
	pass # Replace with function body.

func _process(delta):
	if value <= 100:
		value += 1 * delta
	pass
