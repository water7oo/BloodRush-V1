extends CharacterBody3D

@onready var spring_arm_pivot = $SpringArmPivot
@onready var spring_arm = $SpringArmPivot/SpringArm3D
@onready var sword = $RootNode/Armature/Skeleton3D/BoneAttachment3D/Sword  # Reference to the SwordHolder node
@onready var Hitbox = $RootNode/Armature/Skeleton3D/BoneAttachment3D/Sword/Hitbox
@onready var armature = $RootNode/Armature/Skeleton3D
@onready var jump_wave = get_tree().get_nodes_in_group("Jump_wave")
@onready var dust_trail = get_tree().get_nodes_in_group("dust_trail")
@onready var wall_wave = get_tree().get_nodes_in_group("wall_wave")
@onready var InputBuffer = get_node("/root/InputBuffer")
@onready var camera = $SpringArmPivot/SpringArm3D/Camera3D
@onready var CamCollider = $SpringArmPivot/SpringArm3D/Camera3D/CamCollider
@onready var slash1_anim = $RootNode/Armature/Skeleton3D/Slash1/AnimationPlayer
@onready var slash2_anim = $RootNode/Armature/Skeleton3D/Slash2/AnimationPlayer




var mouse_sensitivity = 0.005
var BASE_SPEED = 5
var MAX_SPEED = BASE_SPEED * 1.9
var SPEED = BASE_SPEED
var ACCELERATION = 15.0
var DECELERATION = 75.0
var DASH_ACCELERATION = 2000
var DASH_DECELERATION = 2000
var DASH_MAX_SPEED = BASE_SPEED * 5
var is_dodging = false
var dash_timer = 0.0
var dash_duration = 0.04



var JUMP_VELOCITY = 7
var WALL_JUMP_VELOCITY_MULTIPLIER = 2.5
var wall_jump_direction = Vector3()
var air_time = 0.0
var landing_animation_threshold = 1.0
var RUNJUMP_MULTIPLIER = 1.2
var WALL_STAY_DURATION = 0.5  # Adjust this value to control how long the player stays on the wall after a jump
var wall_stay_timer = 0.0
var ORIGINAL_JUMP_VEL = JUMP_VELOCITY
var RUN_JUMP_VELOCITY = JUMP_VELOCITY * RUNJUMP_MULTIPLIER
var LERP_VAL = 0.2
var DODGE_LERP_VAL = 1
var wall_jump_position = Vector3.ZERO

var custom_gravity = 30.0
var sprinting = false
var dodging = false
var is_in_air = false
var current_speed = 0.0
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
		
		#Current Cam situation
#		spring_arm_pivot.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
#		spring_arm_pivot.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
#		spring_arm_pivot.rotation.x = clamp(spring_arm_pivot.rotation.x, deg_to_rad(-60), deg_to_rad(20))
		
		#Older Cam situation
		#spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		#spring_arm.rotate_x(-event.relative.y * 0.005)
		#spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta):
	if not is_on_floor():
		air_time += delta
		$AnimationPlayer.play("Armature_002|Player_Air")
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

	if is_on_floor():
		if Input.is_action_just_pressed("move_jump"):
			is_in_air = true
			velocity.y = JUMP_VELOCITY
	
	
	
	if is_on_wall():
		#current_speed = 0.0
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

#	if Input.is_action_pressed("move_jump"):
#		if is_on_wall():
#			wall_jump_direction = -get_wall_normal().normalized()
#			velocity = wall_jump_direction * (JUMP_VELOCITY * WALL_JUMP_VELOCITY_MULTIPLIER)
#			velocity.y += JUMP_VELOCITY * WALL_JUMP_VELOCITY_MULTIPLIER
#			await get_tree().create_timer(1).timeout
#			if is_on_wall() && Input.is_action_pressed("move_jump"):
#				print_debug("Player is jumping off of the wall")
#	else:
#		velocity += Vector3(0, -custom_gravity * delta * 2.5, 0)

#	if Input.is_action_pressed("move_jump"):
#		if Input.is_action_pressed("move_forward"):
#			if is_on_wall():
#				wall_normal = get_slide_collision(0)
#				await get_tree().create_timer(1).timeout
#				fall.y = 0
#				direction = - wall_normal.normal * BASE_SPEED

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)

	var target_speed = BASE_SPEED

	if sprinting:
		is_sprinting = true
		target_speed = MAX_SPEED
		
		if Input.is_action_just_pressed("move_jump") and is_on_floor():
			velocity.y = RUN_JUMP_VELOCITY
	else:
		is_sprinting = false
		target_speed = BASE_SPEED
		ACCELERATION = ACCELERATION
		
		
	#Dodging
	if dodging && is_on_floor():
		is_dodging = true
		current_speed = 0
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
	
	var acceleration = ACCELERATION
	var deceleration = DECELERATION
	
	
	if is_attacking && is_on_floor():
		current_speed = 0.0
	elif direction:
		if current_speed < target_speed:
			current_speed = move_toward(current_speed, target_speed, acceleration * delta)
			
		else:
			current_speed = move_toward(current_speed, target_speed, deceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0, deceleration * delta)

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

#		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VAL)
		
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

	if not is_on_floor():
		$AnimationPlayer.play("Armature_002|Player_Air")

	if is_in_air && is_on_floor():
		is_in_air = false
		for node in jump_wave:
			node.global_transform.origin = landing_position
			if node.has_node("AnimationPlayer"):
				node.get_node("AnimationPlayer").play("CloudAnim")
			

	light_attack1 = Input.is_action_just_pressed("attack_light1")
	light_attack2 = Input.is_action_just_pressed("attack_light2")
	medium_attack1 = Input.is_action_just_pressed("attack_medium1")
	
	if light_attack1 && is_on_floor():
		slash1_anim.play("Slash1")
		is_attacking = true
		Hitbox.monitoring = true
	
	if medium_attack1 && is_on_floor():
		slash1_anim.play("Slash_2")
		is_attacking = true
		Hitbox.monitoring = true
		
		
#	$AnimationTree.set("parameters/conditions/IDLE", input_dir == Vector2.ZERO && is_on_floor())
#	$AnimationTree.set("parameters/conditions/Walk", input_dir != Vector2.ZERO && is_on_floor() && !is_sprinting)
#	$AnimationTree.set("parameters/conditions/RUN", input_dir != Vector2.ZERO && is_on_floor() && is_sprinting)
#	$AnimationTree.set("parameters/conditions/JumpAir", !is_on_floor() || Input.is_action_just_pressed("move_jump"))
#	$AnimationTree.set("parameters/conditions/SwordLight1", light_attack1 && is_on_floor())
#	$AnimationTree.set("parameters/conditions/SwordLight2", light_attack2 && is_on_floor())
#	$AnimationTree.set("parameters/conditions/MA1", medium_attack1 && is_on_floor())
#	$AnimationTree.set("parameters/conditions/Dashing", is_dodging && is_on_floor() && input_dir != Vector2.ZERO)
#	$AnimationTree.set("parameters/conditions/FallHard", air_time == 0.5 && is_on_floor() && !is_in_air)
	move_and_slide()

func _input(event):
	if event.is_action_pressed("attack_light1") || event.is_action_pressed("attack_light2") || event.is_action_pressed("attack_medium1"):
		is_attacking = true
	else:
		is_attacking = false
		
		

#Sword to Enemy collision
func _on_hitbox_area_entered(area):
	if area.is_in_group("enemy") && is_attacking:
		hit_stop(0.05, 0.3)
	pass # Replace with function body.


func hit_stop(timeScale, duration):
	if is_attacking:
		Engine.time_scale = timeScale
		var timer = get_tree().create_timer(timeScale*duration)
		await timer.timeout
		Engine.time_scale = 1


func _on_timer_timeout():
	pass # Replace with function body.


#Enemy to player
func _on_enemy_area_entered(area):
	pass # Replace with function body.
