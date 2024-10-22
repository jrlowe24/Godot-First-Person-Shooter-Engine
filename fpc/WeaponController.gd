extends Node3D

@export_file var default_reticle
@export_file var hitmarker
# The reticle should always have a Control node as the root
var RETICLE : Control
var Hitmarker : Control
@onready var timer : Timer = $Timer

@export var userInterface : Control
@export var character : CharacterBody3D
# used for adding bullet hole decals to scene
@export var Evironment : Node3D
@export var hitmarker_visible_duration: float = .1
@onready var interactRayCast : RayCast3D = $InteractRayCast


@onready var audioStreamPlayer : AudioStreamPlayer3D = $AudioStreamPlayer3D
# weapon animations
@onready var weaponOperations : AnimationPlayer = $WeaponOperations

# time since last shot
var shootTimer : float = 0
# counter to keep track of animation time
var animationTime : float
# whether we are aiming down sites
var ADS : bool = false
# state of weapon (swapping, idle)
var weaponState : String


## Item Slots
# node that holds the weapon scene
@onready var weaponHolder : Node3D = $GunRecoilController/SwayController/AnimationLayer/WeaponHolder
# list of weapons
var weaponList : Array
# max number of weapons
var maxWeapons : int = 2
# index of current weapon
var curr_weapon : int = 0

signal swap_weapons
signal shoot_signal

func _ready():
	weaponOperations.play("Reset")
	weaponState = "Idle"
	if default_reticle:
		change_reticle(default_reticle)
		
	Hitmarker = load(hitmarker).instantiate()
	userInterface.add_child(Hitmarker)
	Hitmarker.visible = false
	timer.timeout.connect(_on_Timer_timeout)
	
	var timer = $Timer  # Adjust the path to your Timer node
	timer.connect("timeout",  Callable(self, "_on_Timer_timeout"))
	## inventory stuff
	#var primary = preload("res://Assets/Weapons/Ak47/ak_47_rig_v_4.tscn").instantiate()
	#var secondary = preload("res://Assets/Weapons/M4/m4_rig.tscn").instantiate()
	var sidearm = preload("res://Assets/Weapons/Glock/glock_rig.tscn").instantiate()
	var sniper = preload("res://Assets/Weapons/Sniper/sniper_rig.tscn").instantiate()
	#weaponList.append(primary)
	#weaponList.append(secondary)
	weaponList.append(sidearm)
	weaponList.append(sniper)
	#weaponHolder.add_child(primary)
	#weaponHolder.add_child(secondary)
	weaponHolder.add_child(sidearm)
	weaponHolder.add_child(sniper)
	#primary.set_active(true)
	sidearm.hit_detected.connect(_on_weapon_hit_detected)
	sidearm.set_active(true)
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
	processInteract(delta)
	
func process_inputs(delta):
	if Input.is_action_pressed("aim"):
		ADS = true
	else:
		ADS = false
	
	# weapon swapping
	if Input.is_action_just_pressed("item1") and len(weaponList) > 1:
		startWeaponSwap()
		#weaponOperations.play("SwapWeapons")
	
	if Input.is_action_just_pressed("dropItem") and len(weaponList) > 0:
		startWeaponDrop()

func processInteract(delta):
	if interactRayCast.is_colliding():
		var collider = interactRayCast.get_collider()
		#print(collider.name)
		
		# if we are in here, that means we can pick up the weapon
		if Input.is_action_just_pressed("interact"):
			pickupWeapon(collider.get_parent().getType())

func handleAiming(delta):
	if ADS:
		RETICLE.visible = false
	else:
		RETICLE.visible = true

func pickupWeapon(weapon):
	#var weapon = load(type).instantiate()
	print("picking up weapon")
	weaponList.append(weapon)
	weaponHolder.add_child(weapon)
	weapon.hit_detected.connect(_on_weapon_hit_detected)
	print("Connected hit_detected signal for weapon:", weapon)
	if len(weaponList) == 1:
		weapon.set_active(true)
		weaponOperations.play_backwards("WeaponExit")
	else:
		startWeaponSwap()
	
	emit_signal("swap_weapons")
	
func _on_Timer_timeout():
	Hitmarker.visible = false	

func _on_weapon_hit_detected(hit_info):
	## Add logic for when hit detection hits a player
	#Hitmarker.visible = true
	print("hit")
	timer.start(hitmarker_visible_duration)


func swapWeapons():
	#if curr_weapon <= len(weaponList) - 1:
		#weaponList[curr_weapon].set_active(false)
	#curr_weapon = (curr_weapon + 1) % len(weaponList)
	weaponList[curr_weapon].set_active(false)
	curr_weapon = (curr_weapon + 1) % len(weaponList)
	weaponList[curr_weapon].set_active(true)
	weaponOperations.play_backwards("WeaponExit")
	emit_signal("swap_weapons")
	weaponState = "idle"
	
func startWeaponSwap():
	weaponOperations.play("WeaponExit")
	#getCurrWeapon().set_enabled(false)
	if curr_weapon <= len(weaponList) - 1:
		weaponList[curr_weapon].set_enabled(false)

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

func change_reticle(reticle): # Yup, this function is kinda strange
	if RETICLE:
		RETICLE.queue_free()
	
	RETICLE = load(reticle).instantiate()
	RETICLE.character = self.character
	userInterface.add_child(RETICLE)
