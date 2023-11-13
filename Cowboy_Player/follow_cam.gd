extends Node3D

@export var target : Node  # Assign the player node in the editor
@export var offset : Vector3 = Vector3(0, 0, 0)  # Adjust this offset based on your needs
@export var lag_factor: float = 0.007  # Adjust this factor to control the lag effect
@export var mouse_sensitivity : float = 0.005

@export var spring_arm_pivot : Node3D
@export var spring_arm : Node3D

var velocity : Vector3 = Vector3.ZERO

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		var rotation_x = rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = rotation.y - event.relative.x * mouse_sensitivity
		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))
		rotation.x = rotation_x
		rotation.y = rotation_y

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	if target:
		# Calculate the desired camera position
		var desired_position : Vector3 = target.global_transform.origin + offset

		# Gradually move the camera towards the desired position with a lag effect
		var lagged_position : Vector3 = global_transform.origin.lerp(desired_position, lag_factor)

		# Set the camera's position based on the lagged position
		global_transform.origin = lagged_position

		# Update the position of the Spring_Arm_Pivot
		spring_arm_pivot.global_transform.origin = target.global_transform.origin

		# Smoothly rotate the camera towards the target's rotation
		var target_rotation = target.global_transform.basis.get_euler()
		var smoothed_rotation : Vector3 = rotation.lerp(target_rotation, mouse_sensitivity * delta)
		rotation = smoothed_rotation
