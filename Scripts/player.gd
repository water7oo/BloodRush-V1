extends RigidBody3D

var move_speed := 4
var dash_speed := 8  # Adjust the dash speed as needed
var dash_duration := 0.2  # Adjust the dash duration as needed
var dash_cooldown := 1.0  # Adjust the dash cooldown as needed
var mouse_sens := 0.005
var twist_input := 0.0
var pitch_input := 0.0

var can_jump = true
var jump_power := 15
var air_damping := 1
var jump_cooldown = false
var dash_cooldown_timer = 0.0

@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Movement
	var input = Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")

	# Apply move speed
	input *= move_speed

	# Detect Jump
	if $RayCast.is_colliding() and !jump_cooldown:  # Check if the RayCast is colliding with the ground and not in jump cooldown
		can_jump = true

	# Jumping
	if Input.is_action_just_pressed("jump") and can_jump:
		apply_impulse(Vector3(0, 1, 0) * jump_power)  # Adjust jump_force as needed
		can_jump = false
		jump_cooldown = true

		# Sets a timer to reset the jump cooldown
		$JumpCooldownTimer.start()

	# Dash
	if Input.is_action_just_pressed("move_rush") and !jump_cooldown and dash_cooldown_timer <= 0.0:
		var dash_direction = twist_pivot.basis * input
		dash_direction.y = 0  # Prevent dashing vertically
		dash_direction = dash_direction.normalized()
		dash_cooldown_timer = dash_cooldown

		# Apply dash velocity
		linear_velocity = dash_direction * dash_speed

	# Air Damping
	if !can_jump and (input.x != 0.0 or input.z != 0.0):
		var air_damping_force = -linear_velocity * air_damping
		apply_central_impulse(air_damping_force)

	#Mouse Functionality
	apply_central_force(twist_pivot.basis * input * 1200 * delta)

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-40), deg_to_rad(40))

	twist_input = 0.0
	pitch_input = 0.0

#Handles mouse Inputs
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = - event.relative.x * mouse_sens
			pitch_input = - event.relative.y * mouse_sens

func _on_JumpCooldownTimer_timeout():
	jump_cooldown = false

func _physics_process(delta):
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
