extends Node3D

@export_file var default_reticle
@export var userInterface : Control
@export var character : CharacterBody3D
@export var recoilController : Node3D
# used for adding bullet hole decals to scene
@export var Evironment : Node3D

var bulletRayCast : RayCast3D

var audioStreamPlayer : AudioStreamPlayer3D
# weapon animations
var weaponOperations : AnimationPlayer

# time since last shot
var shootTimer : float = 0
# counter to keep track of animation time
var animationTime : float
# whether we are aiming down sites
var ADS : bool = false
# state of weapon (swapping, idle)
var weaponState : String

# The reticle should always have a Control node as the root
var RETICLE : Control

## Item Slots
# node that holds the weapon scene
var weaponHolder : Node3D
# list of weapons
var weaponList : Array
# max number of weapons
var maxWeapons : int = 2
# index of current weapon
var curr_weapon : int = 0

signal swap_weapons


func _ready():
	audioStreamPlayer = $AudioStreamPlayer3D
	bulletRayCast = $RayCast3D
	weaponOperations = $WeaponOperations
	weaponHolder = $GunRecoilController/SwayController/AnimationLayer/WeaponHolder
	recoilController = $GunRecoilController
	weaponOperations.play("Reset")
	weaponState = "Idle"
	if default_reticle:
		change_reticle(default_reticle)
		
	
	## inventory stuff
	var primary = preload("res://Assets/Weapons/Ak47/ak_47_rig_v_4.tscn").instantiate()
	var secondary = preload("res://Assets/Weapons/M4/m4_rig.tscn").instantiate()
	var sidearm = preload("res://Assets/Weapons/Glock/glock_rig.tscn").instantiate()
	weaponList.append(primary)
	weaponList.append(secondary)
	weaponList.append(sidearm)
	weaponHolder.add_child(primary)
	weaponHolder.add_child(secondary)
	weaponHolder.add_child(sidearm)
	secondary.visible = false
	sidearm.visible = false
	updateSounds(0)
	
	emit_signal("swap_weapons")
	
func _process(delta):
	process_inputs(delta)
	
	## ADS logic
	if getCurrWeapon():
		handleAiming(delta)
	
	## Weapon Swapping
	if weaponState == "swapping":
		# wait until animation putting away current weapon is done
		if animationTime <= 0:
			swapWeapons()
			
	if weaponState == "dropping":
		if animationTime <= 0:
			dropWeapon()
			
	animationTime -= delta
	shootTimer += delta
	
func process_inputs(delta):
	if Input.is_action_pressed("aim"):
		ADS = true
	else:
		ADS = false
	
	# weapon swapping
	if Input.is_action_just_pressed("item1") and len(weaponList) > 1:
		startWeaponSwap()
	
	if Input.is_action_just_pressed("dropItem") and len(weaponList) > 0:
		startWeaponDrop()
	
	var fire_mode = getCurrWeaponProperty("Default_Fire_Mode")
	# full auto
	if fire_mode == 0:
		if Input.is_action_pressed("shoot") and len(weaponList) > 0:
			useWeapon(delta)
	# semi auto
	if fire_mode == 1:
		if Input.is_action_just_pressed("shoot") and len(weaponList) > 0:
			useWeapon(delta)

func handleAiming(delta):
	var target_position : Vector3
	if ADS:
		RETICLE.visible = false
		target_position = getCurrWeaponProperty("ADS_Position")
	else:
		RETICLE.visible = true
		target_position = Vector3.ZERO
	weaponHolder.position = lerp(weaponHolder.position, target_position, delta * getCurrWeaponProperty("ADS_Speed"))

func swapWeapons():
	if curr_weapon <= len(weaponList) - 1:
		weaponList[curr_weapon].visible = false
	curr_weapon = (curr_weapon + 1) % len(weaponList)
	weaponList[curr_weapon].visible = true
	weaponOperations.play_backwards("WeaponExit")
	emit_signal("swap_weapons")
	weaponState = "idle"
	
func startWeaponSwap():
	weaponOperations.play("WeaponExit")
	updateSounds((curr_weapon + 1) % len(weaponList))
	weaponState = "swapping"
	animationTime = weaponOperations.get_animation("WeaponExit").length
	
func dropWeapon():
	var currentWeapon = getCurrWeapon()
	# add weapon object into the world, this is just a proof of concept
	var weaponObjectDrop = preload("res://Assets/Weapons/WeaponObject.tscn").instantiate()
	weaponObjectDrop.setWeaponMesh(getCurrWeaponProperty("WeaponMeshPath"))
	var forward_direction = -character.HEAD.global_transform.basis.z
	weaponObjectDrop.global_position = self.global_position + forward_direction * 1
	Evironment.add_child(weaponObjectDrop)
	
	# clear out the cur
	currentWeapon.queue_free()
	weaponList.remove_at(curr_weapon)
	if len(weaponList) > 0:
		weaponState = "swapping"
	else:
		weaponState = "idle"

func startWeaponDrop():
	#getCurrWeapon().drop()
	weaponState = "dropping"
	weaponOperations.play("WeaponExit")
	animationTime = weaponOperations.get_animation("WeaponExit").length

func useWeapon(delta):
	if shootTimer > (1 / getCurrWeaponProperty("Fire_Rate")) and weaponState != "swapping":
		shootTimer = 0
		audioStreamPlayer.play()
		recoilController.shoot()
		# vibration doesn't work in this godot version
		#Input.start_joy_vibration(0, .5, .5, .1)
		
		## Ray Cast stuff
		#var space_state = get_world_3d().direct_space_state
		#var from = bulletRayCast.global_transform.origin
		#var to = from + bulletRayCast.global_transform.basis.z.normalized() * 50
		#var params = PhysicsRayQueryParameters3D.create(from, to)
		#var result = space_state.intersect_ray(params)  # Adjust the collision mask (last argument) as per your needs
		
		#if result and result.collider.is_class("MeshInstance"):
			#print(result)
			#var mesh_instance = result.collider
			#var collision_point = result.position
			#var collision_normal = result.normal.normalized()
		
		# may want to use space state raycast to get mesh and not collider
		# adjust the "accuracy" accuracy of the raycast before checking collsion
		var horizontal_spread : float
		var vertical_spread : float
		bulletRayCast.target_position.x = 0
		bulletRayCast.target_position.z = 0
		if Input.is_action_pressed("aim"):
			horizontal_spread = getCurrWeaponProperty("ADS_Horizontal_Bullet_Spread")
			vertical_spread = getCurrWeaponProperty("ADS_Vertical_Bullet_Spread")
		else:
			horizontal_spread = getCurrWeaponProperty("Hipfire_Horizontal_Bullet_Spread")
			vertical_spread = getCurrWeaponProperty("Hipfire_Vertical_Bullet_Spread")
		bulletRayCast.target_position.x = randf_range(-horizontal_spread, horizontal_spread)
		bulletRayCast.target_position.z = randf_range(-vertical_spread, vertical_spread)
		bulletRayCast.force_raycast_update()
		if bulletRayCast.is_colliding():
			make_bullet_hole()

func updateSounds(weapon_idx):
	var shootSound = load(getWeaponProperty(weapon_idx, "Shoot_Sound_Path")) as AudioStream
	audioStreamPlayer.stream = shootSound

# returns the currently equipped weapon node
func getCurrWeapon():
	if self.curr_weapon <= len(self.weaponList) - 1:
		return self.weaponList[self.curr_weapon]
	else:
		return null

func getCurrWeaponProperty(property):
	return self.weaponList[self.curr_weapon].gun_stats.get(property)

func getWeaponProperty(idx, property):
	return self.weaponList[idx].gun_stats.get(property)

func make_bullet_hole():
	var collider = bulletRayCast.get_collider()
	var collision_point = bulletRayCast.get_collision_point()
	var collision_normal = bulletRayCast.get_collision_normal()
	# Not sure how this will work with simple colliders on complex meshes
	# We will want all assets to have a material type, and pick the decal texture
	# accordingly
	
	var decal = preload("res://Assets/Weapons/bulletDecal.tscn").instantiate()
	Evironment.add_child(decal)

	decal.global_transform.origin = collision_point
	
	# align the decal to the normal
	decal.global_transform.basis.y = collision_normal
	var potential_z = -decal.global_transform.basis.x.cross(collision_normal)
	var potential_x = -decal.global_transform.basis.z.cross(collision_normal)
	if potential_z.length() > potential_x.length():
		decal.global_transform.basis.x = potential_z
	else:
		decal.global_transform.basis.x = potential_x
	decal.global_transform.basis.z = decal.global_transform.basis.x.cross(decal.global_transform.basis.y)
	decal.global_transform.basis = decal.global_transform.basis.orthonormalized()
	
	var random_angle = randf() * 360
	decal.global_rotation.x = random_angle

func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()
	
	RETICLE = load(reticle).instantiate()
	RETICLE.character = self.character
	userInterface.add_child(RETICLE)
