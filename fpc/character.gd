extends CharacterBody3D


@export_category("Character")
@export var base_speed : float = 3.0
@export var sprint_speed : float = 6.0
@export var crouch_speed : float = 1.0
@export var slide_speed : float = 5.0
@export var ladder_speed : float = 2.0
@export var acceleration : float = 10.0
@export var jump_velocity : float = 4.5
@export var mouse_sensitivity : float = 0.1
@export var joystick_sensitivity_x : float = 300
@export var joystick_sensitivity_y : float = 200
@export var joystick_aim_sensitivity_x : float = 150
@export var joystick_aim_sensitivity_y : float = 150
@export var joystick_deadzone: float = .08
@export var immobile : bool = false

@export_group("Nodes")
@export var HEAD : Node3D
@export var CAMERA : Camera3D
@export var HEADBOB_ANIMATION : AnimationPlayer
@export var JUMP_ANIMATION : AnimationPlayer
@export var CROUCH_ANIMATION : AnimationPlayer
@export var COLLISION_MESH : CollisionShape3D
@export var RAYCAST : RayCast3D

@export_group("Controls")
# We are using UI controls because they are built into Godot Engine so they can be used right away
@export var JUMP : String = "ui_accept"
@export var LEFT : String = "ui_left"
@export var RIGHT : String = "ui_right"
@export var FORWARD : String = "ui_up"
@export var BACKWARD : String = "ui_down"
@export var PAUSE : String = "ui_cancel"
@export var CROUCH : String
@export var SPRINT : String

# Uncomment if you want full controller support
#@export var LOOK_LEFT : String
#@export var LOOK_RIGHT : String
#@export var LOOK_UP : String
#@export var LOOK_DOWN : String

@export_group("Feature Settings")
@export var jumping_enabled : bool = true
@export var in_air_control : bool = true
@export var motion_smoothing : bool = true
@export var sprint_enabled : bool = true
@export var crouch_enabled : bool = true
@export_enum("Hold to Crouch", "Toggle Crouch") var crouch_mode : int = 0
@export_enum("Hold to Sprint", "Toggle Sprint") var sprint_mode : int = 0
@export var dynamic_fov : bool = true
@export var continuous_jumping : bool = false
@export var view_bobbing : bool = true
@export var jump_animation : bool = true
@export var pausing_enabled : bool = true
@export var gravity_enabled : bool = true



# Member variables
var speed : float = base_speed
var current_speed : float = 0.0
# States: normal, crouching, sprinting
var state : String = "normal"
var low_ceiling : bool = false # This is for when the cieling is too low and the player needs to crouch.
var was_on_floor : bool = true # Was the player on the floor last frame (for landing animation)

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") # Don't set this as a const, see the gravity section in _physics_process


func _ready():
	#It is safe to comment this line if your game doesn't start with the mouse captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# If the controller is rotated in a certain direction for game design purposes, redirect this rotation into the head.
	HEAD.rotation.y = rotation.y
	rotation.y = 0
	
	HEAD = $Head
	CAMERA = $Head/HeadAnimationLayer/Camera
	HEADBOB_ANIMATION = $Head/HeadbobAnimation
	JUMP_ANIMATION = $Head/JumpAnimation
	CROUCH_ANIMATION = $CrouchAnimation
	COLLISION_MESH = $Collision
	
	# Reset the camera position
	# If you want to change the default head height, change these animations.
	#HEADBOB_ANIMATION.play("RESET")
	#JUMP_ANIMATION.play("RESET")
	#CROUCH_ANIMATION.play("RESET")
	
	check_controls()

func check_controls(): # If you add a control, you might want to add a check for it here.
	if !InputMap.has_action(JUMP):
		push_error("No control mapped for jumping. Please add an input map control. Disabling jump.")
		jumping_enabled = false
	if !InputMap.has_action(LEFT):
		push_error("No control mapped for move left. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(RIGHT):
		push_error("No control mapped for move right. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(FORWARD):
		push_error("No control mapped for move forward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(BACKWARD):
		push_error("No control mapped for move backward. Please add an input map control. Disabling movement.")
		immobile = true
	if !InputMap.has_action(PAUSE):
		push_error("No control mapped for move pause. Please add an input map control. Disabling pausing.")
		pausing_enabled = false
	if !InputMap.has_action(CROUCH):
		push_error("No control mapped for crouch. Please add an input map control. Disabling crouching.")
		crouch_enabled = false
	if !InputMap.has_action(SPRINT):
		push_error("No control mapped for sprint. Please add an input map control. Disabling sprinting.")
		sprint_enabled = false

func _physics_process(delta):
	# Big thanks to github.com/LorenzoAncora for the concept of the improved debug values
	current_speed = Vector3.ZERO.distance_to(get_real_velocity())
	$UserInterface/DebugPanel.add_property("Speed", snappedf(current_speed, 0.001), 1)
	$UserInterface/DebugPanel.add_property("Target speed", speed, 2)
	var cv : Vector3 = get_real_velocity()
	var vd : Array[float] = [
		snappedf(cv.x, 0.001),
		snappedf(cv.y, 0.001),
		snappedf(cv.z, 0.001)
	]
	var readable_velocity : String = "X: " + str(vd[0]) + " Y: " + str(vd[1]) + " Z: " + str(vd[2])
	$UserInterface/DebugPanel.add_property("Velocity", readable_velocity, 3)
	
	handle_input(delta)
	# Gravity
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity") # If the gravity changes during your game, uncomment this code
	if not is_on_floor() and gravity and gravity_enabled and state != "climbing":
		velocity.y -= gravity * delta
	
	handle_jumping()
	
	var input_dir = Vector2.ZERO
	if !immobile: # Immobility works by interrupting user input, so other forces can still be applied to the player
		## Keyboard
		#input_dir = Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD)
		## Gamepad
		var axis_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var axis_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		var input_x = 0
		var input_y = 0
		if abs(axis_x) > self.joystick_deadzone:
			input_x = axis_x
		else:
			input_x = 0
		if abs(axis_y) > self.joystick_deadzone:
			input_y = axis_y
		else:
			input_y = 0
		input_dir = Vector2(input_x, input_y)
	handle_movement(delta, input_dir)
	
	# The player is not able to stand up if the ceiling is too low
	low_ceiling = $CrouchCeilingDetection.is_colliding()
	
	handle_state(input_dir)
	if dynamic_fov: # This may be changed to an AnimationPlayer
		update_camera_fov()
	
	if view_bobbing:
		headbob_animation(input_dir)
	
	if jump_animation:
		if !was_on_floor and is_on_floor(): # The player just landed
			match randi() % 2: #TODO: Change this to detecting velocity direction
				0:
					pass
					JUMP_ANIMATION.play("land_left", 0.25)
				1:
					pass
					JUMP_ANIMATION.play("land_right", 0.25)
	
	was_on_floor = is_on_floor() # This must always be at the end of physics_process

func handle_input(delta):
	var sens_x = joystick_sensitivity_x
	var sens_y = joystick_sensitivity_y
	if Input.is_action_pressed("aim"):
		sens_x = joystick_aim_sensitivity_x
		sens_y = joystick_aim_sensitivity_y
	
	
	
	var x_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var y_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var x = 0
	var y = 0
	if abs(x_axis) > joystick_deadzone:
		x = (pow(2.6, abs(x_axis)) - 1.1) * sens_x * delta
		if x_axis > 0:
			x = -x
	if abs(y_axis) > joystick_deadzone:
		y = (pow(2.6, abs(y_axis)) - 1.1) * sens_y * delta
		if y_axis > 0:
			y = -y
	
	HEAD.rotation_degrees.y += x
	HEAD.rotation_degrees.x += y

func handle_jumping():
	if jumping_enabled:
		if continuous_jumping: # Hold down the jump button
			if Input.is_action_pressed(JUMP) and can_jump():
				if jump_animation:
					pass
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity # Adding instead of setting so jumping on slopes works properly
		else:
			if Input.is_action_just_pressed(JUMP) and can_jump():
				if jump_animation:
					pass
					JUMP_ANIMATION.play("jump", 0.25)
				velocity.y += jump_velocity
				if state == "crouching":
					enter_normal_state()

func handle_movement(delta, input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	move_and_slide()
	
	if state == "climbing":
		var vertical_input = input_dir.y
		var climb_speed = ladder_speed
		if vertical_input > 0:
			climb_speed *= 1.5
		velocity.y = lerp(velocity.y, -vertical_input * climb_speed, acceleration * delta)
		global_transform.origin.x = lerp(global_transform.origin.x, self.ladder.get_node("Coords").global_transform.origin.x, 10 * delta)
		global_transform.origin.z = lerp(global_transform.origin.z, self.ladder.get_node("Coords").global_transform.origin.z, 10 * delta)
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
			velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
			var current_speed = Vector2(velocity.x, velocity.z).length()
			if current_speed > speed:
				var scale_factor = speed / current_speed
				velocity.x *= scale_factor
				velocity.z *= scale_factor
		else:
			
			var air_control_sensitivity = 0.075
			# Adjust air control based on input direction
			velocity.x += direction.x * air_control_sensitivity
			velocity.z += direction.z * air_control_sensitivity
			
			## clamp max air speed
			var max_air_speed = 0
			if state == "sprinting":
				max_air_speed = sprint_speed * 0.8
			else:
				max_air_speed = base_speed * 0.8
			var current_speed = Vector2(velocity.x, velocity.z).length()
			if current_speed > max_air_speed:
				var scale_factor = max_air_speed / current_speed
				velocity.x *= scale_factor
				velocity.z *= scale_factor
		
func handle_state(moving):
	if sprint_enabled:
		# hold to sprint
		if sprint_mode == 0:
			if Input.is_action_pressed(SPRINT) and Input.is_action_pressed(FORWARD) and state != "climbing" and !Input.is_action_pressed("aim"):
				if moving:
					if state != "sprinting":
						enter_sprint_state()
				else:
					if state == "sprinting":
						enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()
		# toggle sprint
		elif sprint_mode == 1:
			if moving and Input.is_action_pressed(FORWARD)  and !Input.is_action_pressed("aim"):
				# If the player is holding sprint before moving, handle that scenerio
				if Input.is_action_pressed(SPRINT) and state == "normal" and self.is_on_floor():
					enter_sprint_state()
				if Input.is_action_just_pressed(SPRINT):
					match state:
						"normal":
							if self.is_on_floor():
								enter_sprint_state()
						"crouching":
							enter_sprint_state()
						"sprinting":
							enter_normal_state()
			elif state == "sprinting":
				enter_normal_state()

	if crouch_enabled:
		# hold to crouch
		if crouch_mode == 0:
			if Input.is_action_pressed(CROUCH) and state != "sprinting" and state != "climbing":
				if state != "crouching":
					enter_crouch_state()
			elif state == "crouching" and !$CrouchCeilingDetection.is_colliding():
				enter_normal_state()
		# toggle crouch
		elif crouch_mode == 1:
			if Input.is_action_just_pressed(CROUCH):
				match state:
					"normal":
						enter_crouch_state()
					"crouching":
						if !$CrouchCeilingDetection.is_colliding():
							enter_normal_state()
							
	#climbing section
	if can_climb_ladder(moving):
		# jump will cancel the climbing
		if Input.is_action_just_pressed(JUMP):
			enter_normal_state()
		if moving:
			# enter climbing state
			if state != "climbing" and Input.is_action_pressed("ui_up"):
				enter_climb_state()
			# if on floor and you move away from ladder, leave climbing state.
			if state == "climbing":
				if is_on_floor() and Input.is_action_pressed("ui_down"):
					enter_normal_state()
		
var ladder: Node = null
func on_ladder_entered(node, ladder):
	if node == self:
		#print("Player entered the ladder area!")
		self.ladder = ladder
		
	# Add your code for ladder interaction here

func on_ladder_exited(node, ladder):
	if node == self:
		#print("Player exited the ladder area!")
		enter_normal_state()
		self.ladder = null
	# Add your code for ladder interaction here
	
func can_climb_ladder(input_dir):
	var direction = input_dir.rotated(-HEAD.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	
	if self.ladder:	
		# check collisions
		if RAYCAST.is_colliding():
			var collider = RAYCAST.get_collider()
			# the parent of this collision would be the ladder
			var ladderNode = collider.get_parent_node_3d()
			if self.ladder == ladderNode:
				#print("Raycast hit object: ", ladderNode)
				return true
		#RAYCAST.enabled = false
	else:
		return false

func can_jump():
	return (is_on_floor() or state == "climbing") and !low_ceiling

# Any enter state function should only be called once when you want to enter that state, not every frame.

func enter_normal_state():
	print("entering normal state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "normal"
	speed = base_speed

func enter_crouch_state():
	print("entering crouch state")
	var prev_state = state
	state = "crouching"
	speed = crouch_speed
	CROUCH_ANIMATION.play("crouch")

func enter_sprint_state():
	print("entering sprint state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "sprinting"
	speed = sprint_speed
	
# Climbing ladders
func enter_climb_state():
	print("entering climb state")
	var prev_state = state
	if prev_state == "crouching":
		CROUCH_ANIMATION.play_backwards("crouch")
	state = "climbing"
	velocity.x = 0
	velocity.z = 0

func update_camera_fov():
	if state == "sprinting":
		CAMERA.fov = lerp(CAMERA.fov, 85.0, 0.3)
	else:
		CAMERA.fov = lerp(CAMERA.fov, 75.0, 0.3)

func headbob_animation(moving):
	if moving and is_on_floor():
		var use_headbob_animation : String
		match state:
			"normal","crouching","climbing":
				use_headbob_animation = "walk"
			"sprinting":
				use_headbob_animation = "sprint"
		
		var was_playing : bool = false
		if HEADBOB_ANIMATION.current_animation == use_headbob_animation:
			was_playing = true
		
		HEADBOB_ANIMATION.play(use_headbob_animation, 0.25)
		HEADBOB_ANIMATION.speed_scale = (current_speed / base_speed) * 1.75
		if !was_playing:
			HEADBOB_ANIMATION.seek(float(randi() % 2)) # Randomize the initial headbob direction
			# Let me explain that piece of code because it looks like it does the opposite of what it actually does.
			# The headbob animation has two starting positions. One is at 0 and the other is at 1.
			# randi() % 2 returns either 0 or 1, and so the animation randomly starts at one of the starting positions.
			# This code is extremely performant but it makes no sense.
		
	else:
		if HEADBOB_ANIMATION.is_playing():
			HEADBOB_ANIMATION.play("RESET", 0.25)
			HEADBOB_ANIMATION.speed_scale = 1

func _process(delta):
	$UserInterface/DebugPanel.add_property("FPS", Performance.get_monitor(Performance.TIME_FPS), 0)
	var status : String = state
	if !is_on_floor() and state != "climbing":
		status += " in the air"
	$UserInterface/DebugPanel.add_property("State", status, 4)
	
	if pausing_enabled:
		if Input.is_action_just_pressed(PAUSE):
			match Input.mouse_mode:
				Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$UserInterface/DebugPanel.add_property("Camera Rotation", CAMERA.rotation, 5)
	$UserInterface/DebugPanel.add_property("Head Rotation", HEAD.rotation, 5)
	HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Uncomment if you want full controller support
	#var controller_view_rotation = Input.get_vector(LOOK_LEFT, LOOK_RIGHT, LOOK_UP, LOOK_DOWN)
	#HEAD.rotation_degrees.y -= controller_view_rotation.x * 1.5
	#HEAD.rotation_degrees.x -= controller_view_rotation.y * 1.5

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		HEAD.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		HEAD.rotation_degrees.x -= event.relative.y * mouse_sensitivity
