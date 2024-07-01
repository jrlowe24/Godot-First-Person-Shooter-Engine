extends Node3D

@export var character : CharacterBody3D

@export_group("Sway")
@export var swayEnabled : bool
@export var swayAmount : float = 0.01
@export var maxSwayAmount : float = 0.02
@export var AdsSwayMultiplier : float = 0.5
@export var swaySmooth : float = 1
@export var rotSwayAmount : float
var swayPosition : Vector3

@export_group("Bob")
@export var bobEnabled : bool
@export var bobLimit = Vector3(.01, .005, .01)
@export var travelLimit = Vector3(.02, .005, .025)
@export var multiplier = Vector3(.01, .01, .01)
@export var smoothRot : float = 15
@export var bobAdsMultiplier : float = .05
@export var bobCurveMultiplier : float = 2
@export var runPosition : Vector3
@export var sprintRotation : Vector3
@export var maxBobSpeed : float
var bobPosition : Vector3
var bobEulerRotation : Vector3
var basePosition : Vector3
var baseRotation : Vector3

# current values
var sway
var maxSway
var bobMultiplier
var travel
var bobLim

var walkInput : Vector2
var lookInput : Vector2
var speedCurve : float = 0.01

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_input(delta)
	speedCurve += delta * min(get_speed(), maxBobSpeed)  * bobCurveMultiplier + .01
	if swayEnabled:
		process_sway(delta)
	if bobEnabled:
		process_bob(delta)
		process_bobRotation(delta)
	
	self.position = lerp(self.position, swayPosition + bobPosition + basePosition, delta * swaySmooth)
	self.quaternion = self.quaternion.slerp(Quaternion.from_euler(bobEulerRotation) * Quaternion.from_euler(baseRotation), delta * smoothRot)
	
	# Zero out mouse delta due to issues with it updating with 0
	#lookInput.x = 0
	#lookInput.y = 0

func process_bobRotation(delta):
	bobEulerRotation.x = bobMultiplier.x * sin(2 * speedCurve) if walkInput != Vector2.ZERO else (bobMultiplier.x * sin(2 * speedCurve)) / 2
	bobEulerRotation.y = bobMultiplier.y * cos(speedCurve) if walkInput != Vector2.ZERO else 0
	bobEulerRotation.z = bobMultiplier.z * cos(speedCurve) * walkInput.x if walkInput != Vector2.ZERO else 0
	# not really part of bob but included anyways
	bobEulerRotation.z = -walkInput.x * rotSwayAmount

func process_bob(delta):
	var vel = character.get_real_velocity()
	if character.is_on_floor():
		bobPosition.x = (cos(speedCurve) * bobLim.x) - (walkInput.x * travel.x)
		bobPosition.y = (sin(speedCurve * 2) * bobLim.y) - (vel.y * 2 * travel.y)
		bobPosition.z = -(walkInput.y * travel.z)
	else:
		bobPosition.x = - (walkInput.x * travel.x)
		bobPosition.y = - (vel.y * 2 * travel.y)
		bobPosition.z = - (walkInput.y * travel.z)

func process_sway(delta):		
	var invertLook : Vector2 = lookInput * -sway
	invertLook.x = clamp(invertLook.x, -maxSway, maxSway)
	invertLook.y = clamp(invertLook.y, -maxSway, maxSway)
	swayPosition = Vector3(invertLook.x, -invertLook.y, 0)

func get_speed():
	var vel = character.get_real_velocity()
	var origin = Vector3(0,0,0)
	return origin.distance_to(vel)

func process_input(delta):
	# We want to affect all the parameters if we are ADSing
	if Input.is_action_pressed("aim"):
		sway = swayAmount * AdsSwayMultiplier
		maxSway = maxSwayAmount * AdsSwayMultiplier
		bobMultiplier = multiplier * bobAdsMultiplier
		travel = travelLimit * bobAdsMultiplier
		bobLim = bobLimit * bobAdsMultiplier
	else:
		sway = swayAmount
		maxSway = maxSwayAmount
		bobMultiplier = multiplier
		travel = travelLimit
		bobLim = bobLimit
	
		
	# make bobLim a gradient based on speed
	bobLim = bobLim *  max(get_speed(), .4)
	
	if character.state == "sprinting":
		basePosition = runPosition
		baseRotation = sprintRotation
		bobLim = bobLim * 1.5
	else:
		basePosition = Vector3.ZERO
		baseRotation = Vector3.ZERO

	## Gamepad support
	var x_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var y_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var x = 0
	var y = 0
	# attempt at an exponential aim curve
	if abs(x_axis) > character.joystick_deadzone:
		x = x_axis * character.joystick_aim_sensitivity_x * delta
	if abs(y_axis) > character.joystick_deadzone:
		y = y_axis * character.joystick_aim_sensitivity_y * delta
	lookInput.x = x * 8
	lookInput.y = y * 8
	
	var move_x_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var move_y_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	walkInput.x = move_x_axis
	walkInput.y = move_y_axis
	if abs(move_x_axis) > character.joystick_deadzone:
		walkInput.x = move_x_axis
	else:
		walkInput.x = 0
	if abs(move_y_axis) > character.joystick_deadzone:
		walkInput.y = move_y_axis
	else:
		walkInput.y = 0
	## End Gamepad Support
	
	## Keyboard Support
	#if Input.is_action_pressed("ui_left"):
	#	walkInput.x = -1
	#elif Input.is_action_pressed("ui_right"):
	#	walkInput.x = 1
	#else:
	#	walkInput.x = 0
	## End Keyboard Support
		
	
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pass
		#lookInput.x = event.relative.x
		#lookInput.y = event.relative.y
