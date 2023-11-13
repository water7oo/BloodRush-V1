extends Node3D

@export var target: NodePath
@export var speed := 1.0
@export var enabled: bool
@export var spring_arm_pivot : Node3D
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.005 

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_as_top_level(true)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y
		
	
	



func _process(delta: float) -> void:
	_unhandled_input(delta)

	var target_node := get_node(target) as Node3D

	if not enabled or not target_node:
		return

	global_transform = global_transform.interpolate_with(
		target_node.global_transform, speed * delta)
