extends Node3D

var camCurrentRotation : Vector3
var camTargetRotation : Vector3
var gunTargetPosition : Vector3
var gunTargetRotation : Vector3
var gunCurrentRotation : Vector3

#hipfire recoil
@export_category("CameraRecoil")
@export var camRecoilX : float
@export var camRecoilY : float
@export var camRecoilZ : float
@export var camSnappiness : float
@export var camReturnSpeed : float
@export var CameraRecoilEnabled : bool
@export var CooldownLastShot : float = .15
@export var RecoilCooldown : float = .25
@export var maxVerticalLift : float = .1

@export_category("GunRecoil")
@export var gunRecoilX : float
@export var gunRecoilY : float
@export var gunRecoilZ : float
@export var gunRotRecoilX : float
@export var gunRecoilSnappiness : float
@export var gunReturnSpeed : float
@export var GunRecoilEnabled : bool

var gunRecoilController : Node3D
var WeaponController : Node3D
var isFirstShot : bool = true
var cooldown : float = 0
var currRecoilCooldown : float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	gunRecoilController = $Camera/WeaponController/GunRecoilController # Replace with function body.
	WeaponController = $Camera/WeaponController

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if CameraRecoilEnabled:
		self.rotation = lerp(self.rotation, camTargetRotation, camSnappiness * delta)
		#camTargetRotation = lerp(camTargetRotation, Vector3.ZERO, camReturnSpeed * delta)
	cooldown -= delta
	currRecoilCooldown -= delta
	if cooldown <= 0:
		isFirstShot = true
	if currRecoilCooldown <= 0:
		camTargetRotation = lerp(camTargetRotation, Vector3.ZERO, camReturnSpeed * delta)
		
	if GunRecoilEnabled:
		gunRecoilController.rotation = lerp(gunRecoilController.rotation, gunTargetRotation, gunRecoilSnappiness * delta)
		
		# return back to home
		gunTargetPosition = lerp(gunTargetPosition, Vector3.ZERO, gunReturnSpeed * delta)
		gunTargetRotation = lerp(gunTargetRotation, Vector3.ZERO, gunReturnSpeed * delta)
		gunRecoilController.position = gunTargetPosition
		gunRecoilController.rotation = gunTargetRotation
	
func shoot():
	var recX = 0
	var recY = 0
	if !isFirstShot:
		recX = - camRecoilX
		recY = randf_range(-camRecoilY, camRecoilY)
	camTargetRotation += Vector3(recX, recY, randf_range(-camRecoilZ, camRecoilZ))
	camTargetRotation.z = clampf(camTargetRotation.z, -camRecoilZ, camRecoilZ)
	
	camTargetRotation.x = clampf(camTargetRotation.x, 0, maxVerticalLift)
	# if we are at max vertical recoil, randomize some up and down
	if camTargetRotation.x >= maxVerticalLift:
		camTargetRotation.x += randf_range(-camRecoilX, camRecoilX)
	
	if WeaponController.ADS:
		print("ads")
		#gunTargetRotation += Vector3(gunRotRecoilX * .001, 0,0)
		gunTargetPosition += Vector3(randf_range(-gunRecoilX, gunRecoilX), gunRecoilY / 3,gunRecoilZ)
	else:
		gunTargetRotation += Vector3(gunRotRecoilX, 0,0)
		gunTargetPosition += Vector3(randf_range(-gunRecoilX, gunRecoilX), gunRecoilY,gunRecoilZ)
	cooldown = CooldownLastShot
	currRecoilCooldown = RecoilCooldown
	isFirstShot = false
