extends AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the animation library
	var anim_library = load("res://GAMEPLAYER_ANIMATIONS.glb")

	# Add the animation library to the AnimationPlayer
	add_animation_library("GAMEPLAYER_ANIMATIONS", anim_library)

	# Now you can access and play individual animations from the library
	play("AnimationNameFromLibrary")  # Replace "AnimationNameFromLibrary" with the actual animation name you want to play.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
