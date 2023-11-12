extends Node3D

@export var target : Node  # Assign the SAP_socket node in the editor
@export var player : Node

@onready var spring_arm_pivot = $SpringArmPivot
@export var offset : Vector3 = Vector3(0, 0, 0)
@export var smooth_speed : float = 0.001
@export var mouse_sensitivity = 0.005

var velocity : Vector3 = Vector3.ZERO

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	if target:
		# Move the spring_arm_pivot to the player's position
		spring_arm_pivot.global_transform.origin = player.global_transform.origin

		# Make the camera look at the player
		look_at(target.global_transform.origin, Vector3.UP)
	else:
		print("Target not assigned.")
