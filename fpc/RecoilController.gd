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
@export var GunRecoilEnabled : bool
var gunRecoilX : float
var gunRecoilY : float
var gunRecoilZ : float
var gunRotRecoilX : float
var gunRecoilSnappiness : float
var gunReturnSpeed : float

var WeaponController : Node3D
var camera : Camera3D
var Head : Node3D
# we want first shot accuracy, don't move the camera up on first shot
var isFirstShot : bool = true
var cooldown : float = 0
var currRecoilCooldown : float = 0
var HeadOffset : Vector3
var head_starting_rot : Vector3
var computeHeadOffset = false
var start_lerp

var base_fov : float = 0
var target_fov : float = 0
var curr_fov : float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	WeaponController = self.get_parent_node_3d()
	camera = self.get_parent_node_3d().get_parent()
	Head = self.get_parent_node_3d().get_parent().get_parent_node_3d().get_parent_node_3d()
	base_fov = camera.fov
	curr_fov = base_fov
	
	## For grabbing stats from weapons
	#_on_weapon_swap()
	WeaponController.connect("swap_weapons", _on_weapon_swap)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	## Camera Recoil
	if CameraRecoilEnabled:
		# camTargetRotation is the building recoil vector, once you stop shooting this gets set to zero again
		if camTargetRotation != Vector3.ZERO:
			camera.rotation = lerp(camera.rotation, camTargetRotation, camSnappiness * delta)
		
		if cooldown <= 0:
			isFirstShot = true
		if currRecoilCooldown <= 0:
			# Compute offset between the head movement one time once we stop shooting
			if computeHeadOffset:
				computeHeadOffset = false
				HeadOffset.x = clampf(head_starting_rot.x - Head.global_rotation.x, 0, camTargetRotation.x)
				HeadOffset.y = clampf(head_starting_rot.y - Head.global_rotation.y, 0, camTargetRotation.y)
				#HeadOffset.z = clampf(head_starting_rot.z - Head.global_rotation.z, 0, camTargetRotation.z)
				start_lerp = true
			
			camTargetRotation = Vector3.ZERO
			camera.rotation = lerp(camera.rotation, HeadOffset + Vector3.ZERO, camReturnSpeed * delta)
			
			# I couldn't find a better way to do this
			# Basically, when player moves the head in order to compensate for recoil, we don't want
			# the camera to snap back to zero, otherwise perfect aim will snap down the verticle recoil amount
			# if we keep that offset, eventually the camera gets super out of rotation with the head and
			# affects the player view. After the reoil snaps back, we essentially move the head
			# to where the camera rotation is and then set the camera rotation back to zero.
			# This keeps everything in sync
			if start_lerp and (camera.rotation.x - HeadOffset.x) < .02:
				Head.rotation += Vector3(camera.rotation.x, camera.rotation.y, 0)
				camera.rotation = Vector3.ZERO
				HeadOffset = Vector3.ZERO
				start_lerp = false

	cooldown -= delta
	currRecoilCooldown -= delta
	
	## Gun Recoil
	if GunRecoilEnabled:
		print(gunRecoilZ)
		self.rotation = lerp(self.rotation, gunTargetRotation, gunRecoilSnappiness * delta)
		# return back to home
		gunTargetPosition = lerp(gunTargetPosition, Vector3.ZERO, gunReturnSpeed * delta)
		gunTargetRotation = lerp(gunTargetRotation, Vector3.ZERO, gunReturnSpeed * delta)
		self.position = gunTargetPosition
		self.rotation = gunTargetRotation
	
	## FOV Recoil
	target_fov = lerp(target_fov, base_fov, delta*10.0)
	camera.fov = target_fov
func shoot():
	computeHeadOffset = true
	var recX = 0
	var recY = 0
	if !isFirstShot:
		recX = - camRecoilX
		recY = randf_range(-camRecoilY, camRecoilY)
	else:
		head_starting_rot = Head.global_rotation
		Head.rotation += Vector3(camera.rotation.x, camera.rotation.y, 0)
		camera.rotation = Vector3.ZERO
	camTargetRotation += Vector3(recX, recY, randf_range(-camRecoilZ, camRecoilZ))
	camTargetRotation.z = clampf(camTargetRotation.z, -camRecoilZ, camRecoilZ)
	
	camTargetRotation.x = clampf(camTargetRotation.x, 0, maxVerticalLift)
	# if we are at max vertical recoil, randomize some up and down
	if camTargetRotation.x >= maxVerticalLift:
		camTargetRotation.x += randf_range(-camRecoilX, camRecoilX)
	
	if WeaponController.ADS:
		gunTargetPosition += Vector3(randf_range(-gunRecoilX, gunRecoilX), gunRecoilY / 3,gunRecoilZ)
		gunTargetRotation += Vector3(gunRotRecoilX, 0,0)
	else:
		gunTargetRotation += Vector3(gunRotRecoilX, 0,0)
		gunTargetPosition += Vector3(randf_range(-gunRecoilX, gunRecoilX), gunRecoilY,gunRecoilZ)
	cooldown = CooldownLastShot
	currRecoilCooldown = RecoilCooldown
	isFirstShot = false
	
	target_fov += 2
	target_fov = clampf(target_fov, 0, base_fov + 2)
	
func _on_weapon_swap():
	print("sdfsdf")
	gunRecoilX = WeaponController.getCurrWeaponProperty("Gun_Recoil").x
	gunRecoilY = WeaponController.getCurrWeaponProperty("Gun_Recoil").y
	gunRecoilZ = WeaponController.getCurrWeaponProperty("Gun_Recoil").z
	gunRotRecoilX = WeaponController.getCurrWeaponProperty("Gun_Rot_Recoil_X")
	gunRecoilSnappiness = WeaponController.getCurrWeaponProperty("Gun_Recoil_Snappiness")
	gunReturnSpeed = WeaponController.getCurrWeaponProperty("Gun_Return_Speed")
	
