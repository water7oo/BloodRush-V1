extends CharacterBody3D

const SPEED = 6.0
const SPRINT_SPEED = 10.0
var JUMP_VELOCITY = 7
var RUNJUMP_MULTIPLIER = 2
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER

var custom_gravity = 30.0
var lookat
var lastLookAtDirection: Vector3
var sprinting = false
var is_in_air = false  # New variable to track if the player is in the air

func _ready():
	lookat = get_tree().get_nodes_in_group("CameraController")[0].get_node("LookAt")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	if not is_on_floor():
		velocity.y -= custom_gravity * delta
		is_in_air = true  # Player is in the air

	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	if Input.is_action_just_pressed("mouse_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	sprinting = Input.is_action_pressed("move_sprint")

	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if sprinting:
		$DUST/GPUParticles3D.show()
		velocity.x = direction.x * SPRINT_SPEED
		velocity.z = direction.z * SPRINT_SPEED
		if Input.is_action_just_pressed("move_jump") and is_on_floor():
			velocity.y = RUN_JUMP_VELOCITY
	else:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		$DUST/GPUParticles3D.hide()

	if direction:
		var lerpDirection = lerp(lastLookAtDirection, Vector3(lookat.global_position.x, global_position.y, lookat.global_position.z), 0.05)
		look_at(Vector3(lerpDirection.x, global_position.y, lerpDirection.z))
		lastLookAtDirection = lerpDirection
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if is_in_air && is_on_floor():
		print_debug("Player has landed after a fall or jump")
		is_in_air = false  # Reset the flag when the player lands
		$JUMP_WAVE/AnimationPlayer2.play("Landing_strong_001|CircleAction_002")

	$AnimationTree.set("parameters/conditions/IDLE", input_dir == Vector2.ZERO && is_on_floor())
	$AnimationTree.set("parameters/conditions/Walk", input_dir != Vector2.ZERO && is_on_floor())
	$AnimationTree.set("parameters/conditions/RUN", input_dir != Vector2.ZERO && is_on_floor() && Input.is_action_pressed("move_sprint"))
	move_and_slide()
