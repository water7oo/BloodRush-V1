extends Node3D

@export var target : Node  # Assign the SAP_socket node in the editor
var offset : Vector3 = Vector3(0, 0, 0)
var smooth_speed : float = 0.125

var velocity : Vector3 = Vector3.ZERO

func _process(delta):
	if target:
		# Get the position of SAP_socket in global coordinates
		var sap_socket_global_position : Vector3 = target.global_transform.origin

		# Calculate the desired camera position using the offset from SAP_socket
		var desired_position : Vector3 = sap_socket_global_position + offset

		# Smoothly interpolate towards the desired position
		var smoothed_position : Vector3 = lerp(global_transform.origin, desired_position, smooth_speed)

		# Set the camera's position
		global_transform.origin = smoothed_position

		# Make the camera look at SAP_socket
		look_at(sap_socket_global_position, Vector3.UP)
	else:
		print("Target not assigned.")
