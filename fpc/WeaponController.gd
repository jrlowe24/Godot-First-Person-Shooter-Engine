extends Node3D

@export_file var default_reticle
@export var userInterface : Control
@export var character : CharacterBody3D
@export var recoilController : Node3D
@export var Evironment : Node3D
@export var WeaponList : Array

var weaponState : String
#temp gun variables
@export var fireRate : float = 10

var bulletRayCast : RayCast3D
# The reticle should always have a Control node as the root
var RETICLE : Control
var audioStreamPlayer : AudioStreamPlayer3D
var weaponOperations : AnimationPlayer
# time since last shot
var shootTimer : float = 0
var ADS : bool = false
var animationTime : float

func _ready():
	audioStreamPlayer = $AudioStreamPlayer3D
	bulletRayCast = $RayCast3D
	weaponOperations = $WeaponOperations
	weaponOperations.play("Reset")
	weaponState = "Idle"
	if default_reticle:
		change_reticle(default_reticle)

func _process(delta):
	process_inputs(delta)
	if ADS:
		RETICLE.visible = false
		$GunRecoilController/SwayController/ADSController.ADS = true
	else:
		RETICLE.visible = true
		$GunRecoilController/SwayController/ADSController.ADS = false
	
func process_inputs(delta):
	shootTimer += delta
	if Input.is_action_pressed("shoot"):
		useWeapon(delta)
	if Input.is_action_pressed("aim"):
		ADS = true
	else:
		ADS = false
		
	# weapon swapping
	if Input.is_action_just_pressed("item1"):
		weaponOperations.play("WeaponExit")
		weaponState = "swapping"
		animationTime = weaponOperations.get_animation("WeaponExit").length

	if weaponState == "swapping":
		if animationTime <= -.2:
			weaponOperations.play_backwards("WeaponExit")
			weaponState = "idle"
	
	animationTime -= delta
		
func useWeapon(delta):
	if shootTimer > (1 / fireRate) and weaponState != "swapping":
		recoilController.shoot()
		Input.start_joy_vibration(0, .5, .5, .1)
		#Input.v
		var space_state = get_world_3d().direct_space_state
		var from = bulletRayCast.global_transform.origin
		var to = from + bulletRayCast.global_transform.basis.z.normalized() * 50
		#var params = PhysicsRayQueryParameters3D.create(from, to)
		#var result = space_state.intersect_ray(params)  # Adjust the collision mask (last argument) as per your needs
		
		#if result and result.collider.is_class("MeshInstance"):
			#print(result)
			#var mesh_instance = result.collider
			#var collision_point = result.position
			#var collision_normal = result.normal.normalized()
		
		if bulletRayCast.is_colliding():
			make_bullet_hole()
		audioStreamPlayer.play()
		shootTimer = 0
	
func make_bullet_hole():
	var collider = bulletRayCast.get_collider()
	print(collider)
	var collision_point = bulletRayCast.get_collision_point()
	var collision_normal = bulletRayCast.get_collision_normal()
	# Not sure how this will work with simple colliders on complex meshes
	# We will want all assets to have a material type, and pick the decal texture
	# accordingly
	
	var decal = preload("res://Assets/bulletDecal.tscn").instantiate()
	Evironment.add_child(decal)

	decal.global_transform.origin = collision_point
	align_decal_with_normal(decal, collision_normal)

# Function to align the decal with the surface normal
func align_decal_with_normal(decal: Node3D, normal: Vector3) -> void:
	#decal.look_at(decal.global_transform.origin + normal, Vector3.UP)
	decal.global_transform.basis.y = normal
	var potential_z = -decal.global_transform.basis.x.cross(normal)
	var potential_x = -decal.global_transform.basis.z.cross(normal)
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
