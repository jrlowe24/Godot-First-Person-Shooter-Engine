extends Node3D

var soundPlayers : Array
@onready var stepsound1 = $AudioStreamPlayer3D
@onready var stepsound2 = $AudioStreamPlayer3D2
@onready var stepsound3 = $AudioStreamPlayer3D3
@onready var stepsound4 = $AudioStreamPlayer3D4
@onready var stepsound5 = $AudioStreamPlayer3D5
@onready var stepsound6 = $AudioStreamPlayer3D6
@onready var stepsound7 = $AudioStreamPlayer3D7
@onready var stepsound8 = $AudioStreamPlayer3D8

@export var swayController : Node3D

@export var character : CharacterBody3D
var step_sounds : Array
# Called when the node enters the scene tree for the first time.
func _ready():
	step_sounds = [stepsound1,stepsound2,stepsound3,stepsound4,stepsound5,stepsound6,stepsound7,stepsound8]
	for i in range(len(step_sounds) - 1):
		step_sounds[i].volume_db = -5.0

var speedCurve = 0
var prev_gunMovementY = 0
var gunMovementY = 0
var hasSoundPlayed = false

var lastFrameInAir = false

func _process(delta):
	var vel = character.get_real_velocity()
	vel.y = 0
	var origin = Vector3(0,0,0)
	#var walk_speed = clampf(origin.distance_to(vel), 0, 4)
	var walk_speed = origin.distance_to(vel)
	
	speedCurve += delta * min(walk_speed, swayController.maxBobSpeed) * swayController.bobCurveMultiplier + .01
	#var gunMovementY = (sin(speedCurve * 2) * swayController.bobLim.y)
	var gunMovementY = (sin(speedCurve * 2) * swayController.getBobLimit_y())
	if character.is_on_floor() and walk_speed > 0:
		#if gunMovementY < prev_gunMovementY and abs(gunMovementY + swayController.bobLim.y) < 0.0001:
		if gunMovementY < prev_gunMovementY and abs(gunMovementY + swayController.getBobLimit_y()) < 0.0001:
			if not hasSoundPlayed:
				var sound_idx = randi() % (len(step_sounds))
				step_sounds[sound_idx].play()
				hasSoundPlayed = true
		elif gunMovementY > 0:
			hasSoundPlayed = false
			
	if lastFrameInAir and walk_speed == 0 and character.is_on_floor():
		var sound_idx = randi() % (len(step_sounds))
		step_sounds[sound_idx].play()
		lastFrameInAir = false
	if !character.is_on_floor():
		lastFrameInAir = true
	prev_gunMovementY = gunMovementY
