extends CharacterBody3D

var camera = preload("res://Cowboy_Player/PlayerCamera.tscn").instantiate()
var spring_arm_pivot = camera.get_node("SpringArmPivot")
var spring_arm = camera.get_node("SpringArmPivot/SpringArm3D")

@onready var blend_space = $AnimationTree.get('parameters/Combat/MoveStrafe/blend_position')
@onready var blend_space2 = $AnimationTree.get('parameters/Combat/MoveStrafe/blend_position')
var current_blend_amount = 0.0
var target_blend_amount = 0.0
var blend_lerp_speed = 5.0  # Adjust the speed of blending


@onready var armature = $RootNode/Armature/Skeleton3D
@onready var jump_wave = get_tree().get_nodes_in_group("Jump_wave")
@onready var dust_trail = get_tree().get_nodes_in_group("dust_trail")
@onready var wall_wave = get_tree().get_nodes_in_group("wall_wave")
@onready var InputBuffer = get_node("/root/InputBuffer")


#Basic Movement
@export var mouse_sensitivity = 0.005
@export var joystick_sensitivity = 0.005
@export var BASE_SPEED = 3
@export var MAX_SPEED = 7
var SPEED = BASE_SPEED
var target_speed = BASE_SPEED
var current_speed = 0.0


@export var JUMP_VELOCITY = 8
@export var SHORT_JUMP = 4
@export var LONG_JUMP = 8
@export var RUNJUMP_MULTIPLIER = 1.3
var jump_timer = 0.0
var jump_tap_timer = 0.1
var jump_height = 128

#Acceleration and Speed
@export var ACCELERATION = 5.0 #the higher the value the faster the acceleration
@export var DECELERATION = 25.0 #the lower the value the slippier the stop
var BASE_ACCELERATION = 3
var BASE_DECELERATION = 15.0 
@export var DASH_ACCELERATION = 20
@export var DASH_DECELERATION = 7
var DASH_MAX_SPEED = BASE_SPEED * 3
var is_dodging = false
var dash_timer = 0.0
@export var dash_duration = 0.04




var WALL_JUMP_VELOCITY_MULTIPLIER = 2.5

var air_time = 0.0
var landing_animation_threshold = 1.0
var WALL_STAY_DURATION = 0.5  # Adjust this value to control how long the player stays on the wall after a jump
var wall_stay_timer = 0.0
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
var LERP_VAL = 0.2
var DODGE_LERP_VAL = 1
var wall_jump_position = Vector3.ZERO

var custom_gravity = 27.0 #The lower the value the floatier
var sprinting = false
var dodging = false
var is_in_air = false

var is_sprinting = false
var light_attack1 = false
var light_attack2 = false
var medium_attack1 = false
var landing_position = Vector3.ZERO
var can_wall_jump = true
var has_wall_jumped = false

var fall = Vector3()
var wall_normal
var direction = Vector3()


# Hitbox variables
var hitbox = null
var hitbox_active = false
var hitbox_duration = 0.2  # Adjust the duration of the hitbox here
var is_attacking = false
var jumping = Input.is_action_just_pressed("move_jump")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()

	if event is InputEventMouseMotion:

		var rotation_x = spring_arm_pivot.rotation.x - event.relative.y * mouse_sensitivity
		var rotation_y = spring_arm_pivot.rotation.y - event.relative.x * mouse_sensitivity

		rotation_x = clamp(rotation_x, deg_to_rad(-60), deg_to_rad(30))

		spring_arm_pivot.rotation.x = rotation_x
		spring_arm_pivot.rotation.y = rotation_y
		
	
	
	
func _proccess_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)
	
	
	if direction:
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, ACCELERATION * delta)
		else:
			current_speed = move_toward(current_speed, target_speed, DECELERATION * delta)
	
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if direction && !is_sprinting:
			target_blend_amount = 0.0
			current_blend_amount = lerp(current_blend_amount, target_blend_amount, blend_lerp_speed * delta)
			$AnimationTree.set("parameters/Blend3/blend_amount", current_blend_amount)
		else:
			target_blend_amount = -1.0
		
#		if is_sprinting:
#			ACCELERATION = ACCELERATION * 1.5
#			DECELERATION = DECELERATION * 1
#		else:
#			ACCELERATION = BASE_ACCELERATION
#			DECELERATION = BASE_DECELERATION


	
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
		
	else:
		if !direction:
			velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
			velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
			current_speed = sqrt(velocity.x * velocity.x + velocity.z * velocity.z)
			$AnimationTree.set("parameters/Blend3/blend_amount", -1) 
	
	
	
	if sprinting && direction:
		is_sprinting = true
		target_speed = MAX_SPEED
		ACCELERATION = DASH_ACCELERATION
		DECELERATION = DASH_DECELERATION
		target_blend_amount = 1.0
		current_blend_amount = lerp(current_blend_amount, target_blend_amount, blend_lerp_speed * delta)
		$AnimationTree.set("parameters/Blend3/blend_amount", current_blend_amount)
		
#		if InputBuffer.is_action_press_buffered("move_jump") and is_on_floor():
#			velocity.y = RUN_JUMP_VELOCITY

	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = ACCELERATION
		DECELERATION = DECELERATION
		
		
	
	#Dodging
	if dodging && is_on_floor():
		is_dodging = true
		current_speed = DASH_MAX_SPEED
		dash_timer = dash_duration 
		LERP_VAL = DODGE_LERP_VAL

	if is_dodging:
		dash_timer -= delta
		is_sprinting = false

		if dash_timer <= 0:
			is_dodging = false
			LERP_VAL = 0.2
		else:
			current_speed = move_toward(current_speed, DASH_MAX_SPEED, DASH_DECELERATION * delta)
	
	
	for node in dust_trail:
		var particle_emitter = node.get_node("GPUParticles3D")
		if particle_emitter && input_dir != Vector2.ZERO && is_on_floor():
			var should_emit_particles = is_sprinting && !is_in_air && current_speed >= MAX_SPEED
			particle_emitter.set_emitting(should_emit_particles)

			if is_in_air:
				pass
#		if is_in_air && is_on_floor():
#			is_in_air = false
#			for node in jump_wave:
#				node.global_transform.origin = landing_position
#				if node.has_node("AnimationPlayer"):
#					node.get_node("AnimationPlayer").play("CloudAnim")
		

func _proccess_jump(delta):
	if Input.is_action_just_pressed("move_jump"):
			jump_timer = 0.1
			jump_timer-=delta
	if jump_timer > 0 && is_on_floor():
			jump_timer = 0.0
			is_in_air = true
			if is_sprinting:
				velocity.y = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
			else:
				velocity.y = JUMP_VELOCITY

func _physics_process(delta):
#	var fps = Engine.get_frames_per_second()
#	var lerp_interval = direction / fps
#	var lerp_position = global_transform.origin + lerp_interval
#
#
#	if fps > 30:
#		armature.set_as_toplevel(true)
#		armature.global_transform.origin = armature.global_transform.origin.lerp(lerp_position, 20 * delta)
#	else:
#		armature.global_transform = global_transform
#		armature.set_as_toplevel(false)
#
#
#
#
	_proccess_movement(delta)
	_proccess_jump(delta)
	_unhandled_input(delta)
	if is_on_wall():
		if Input.is_action_just_pressed("move_jump"):
			var wall_normal = get_wall_normal()
			if wall_normal != null && wall_normal != Vector3.ZERO:
				wall_normal = wall_normal.normalized() 
				velocity = wall_normal * (JUMP_VELOCITY * WALL_JUMP_VELOCITY_MULTIPLIER)
				velocity.y += WALL_JUMP_VELOCITY_MULTIPLIER
				
				has_wall_jumped = true
				can_wall_jump = false
				wall_jump_position = global_transform.origin
				if has_wall_jumped:
					for node in wall_wave:
							node.global_transform.origin = wall_jump_position
							if node.has_node("AnimationPlayer"):
								node.get_node("AnimationPlayer").play("Landing_strong_001|CircleAction_002")
		
			else:
				velocity.x = 0
				velocity.z = 0
				velocity.y += custom_gravity * delta
		else:
			velocity += Vector3(0, -custom_gravity * delta * 6, 0)
			


	if not is_on_floor():
		air_time += delta
		if not is_on_wall():
			velocity.y -= custom_gravity * delta
		else:
			velocity.y = -0.5 * delta
			wall_stay_timer = WALL_STAY_DURATION
			has_wall_jumped = false
			can_wall_jump = true
			air_time = 0.0
	if air_time > landing_animation_threshold:
		air_time = 0.0
		is_in_air = true
	else:
		landing_position = global_transform.origin
		wall_jump_position = global_transform.origin
		can_wall_jump = true

	if Input.is_action_just_pressed("mouse_left"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	sprinting = Input.is_action_pressed("move_sprint")
	dodging = Input.is_action_just_pressed("move_dodge")
	
	
	
	
	move_and_slide()


func respawn():
	get_tree().reload_current_scene()
#Time Stop
#func hit_stop(timeScale, duration):
#	if is_attacking:
#		Engine.time_scale = timeScale
#		var timer = get_tree().create_timer(timeScale*duration)
#		await timer.timeout
#		Engine.time_scale = 1
#
#
#func _on_timer_timeout():
#	pass # Replace with function body.
#
#
##Enemy to player
#func _on_enemy_area_entered(area):
#	pass # Replace with function body.
