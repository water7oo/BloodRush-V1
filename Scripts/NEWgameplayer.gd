extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var armature = $RootNode/Armature/Skeleton3D/Human_Body_001

var BASE_SPEED = 6.5  # Store the base walking speed
var SPEED = BASE_SPEED  # Initialize SPEED with the base speed
const SPRINT_MULTI = 1.8
var JUMP_VELOCITY = 7
var RUNJUMP_MULTIPLIER = 2
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
const LERP_VAL = .15

var custom_gravity = 30.0
var sprinting = false
var is_in_air = false  # New variable to track if the player is in the air

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:
		spring_arm_pivot.rotate_y(-event.relative.x * .005)
		spring_arm.rotate_x(-event.relative.y * .005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= custom_gravity * delta
		is_in_air = true  # Player is in the air

	if Input.is_action_just_pressed("mouse_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	sprinting = Input.is_action_pressed("move_sprint")

	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() 
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	if sprinting:
		$DUST/GPUParticles3D.show()
		SPEED = BASE_SPEED * SPRINT_MULTI  # Set SPEED to the sprinting speed
		if Input.is_action_just_pressed("move_jump") and is_on_floor():
			velocity.y = RUN_JUMP_VELOCITY
	else:
		$DUST/GPUParticles3D.hide()
		SPEED = BASE_SPEED  # Reset SPEED to the base walking speed

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
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
