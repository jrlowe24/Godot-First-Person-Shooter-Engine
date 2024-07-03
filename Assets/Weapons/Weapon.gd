extends Node3D

### The class that defines a weapon and a weapons functionality
@export var gun_stats: Resource

var rigidbody : RigidBody3D
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
@onready var audioStreamPlayer : AudioStreamPlayer3D = $AudioStreamPlayer3D
var recoilController : Node3D
var arms : Node3D
var gunMesh : MeshInstance3D
var bulletRayCast : RayCast3D
var state : String
var weaponController : Node3D
var shootTimer : float
var ADS : bool
var isActive : bool = false
@onready var particleEmitter : GPUParticles3D = $GPUParticles3D


func _ready():
	self.set_active(false)
	if animationPlayer:
		animationPlayer.play("Reset")
	
	weaponController = get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d()
	recoilController = get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d()
	bulletRayCast = get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_child(0) 
var delay = 0
func _process(delta):
	self.audioStreamPlayer.global_transform = weaponController.global_transform
	print(self.audioStreamPlayer.global_position)
	if isActive:
		process_inputs(delta)
		
		if delay >= 1:
			if particleEmitter:
				#particleEmitter.emitting = true
				#particleEmitter.restart()
				delay = 0
		delay += delta	
		
		var target_position : Vector3
		if ADS:
			target_position = gun_stats.get("ADS_Position")
		else:
			target_position = Vector3.ZERO
		self.position = lerp(self.position, target_position, delta * gun_stats.get("ADS_Speed"))
	shootTimer += delta
	
func set_active(isActive):
	self.isActive = isActive
	if isActive == false:
		self.visible = false
		if bulletRayCast:
			bulletRayCast.enabled = false
	else:
		self.visible = true
		if bulletRayCast:
			bulletRayCast.enabled = true
	
func set_enabled(isEnabled):
	self.isActive = isEnabled
	
func process_inputs(delta):
	if Input.is_action_pressed("aim"):
		ADS = true
		#ADS
	else:
		ADS = false
	
	
	# full auto
	if gun_stats.get("Default_Fire_Mode") == 0:
		if Input.is_action_pressed("shoot"):
			useWeapon(delta)
	# semi auto
	if gun_stats.get("Default_Fire_Mode") == 1:
		if Input.is_action_just_pressed("shoot"):
			useWeapon(delta)
		
		
func useWeapon(delta):
	if shootTimer > (1 / gun_stats.get("Fire_Rate")):
		shootTimer = 0
		audioStreamPlayer.play()
		recoilController.shoot()
		
		
		if animationPlayer:
			animationPlayer.play("Shoot2")
		if particleEmitter:
			#particleEmitter.set
			particleEmitter.emitting = true
			#particleEmitter.restart()
			
		var horizontal_spread : float
		var vertical_spread : float
		bulletRayCast.target_position.x = 0
		bulletRayCast.target_position.z = 0
		if Input.is_action_pressed("aim"):
			horizontal_spread = gun_stats.get("ADS_Horizontal_Bullet_Spread")
			vertical_spread = gun_stats.get("ADS_Vertical_Bullet_Spread")
		else:
			horizontal_spread = gun_stats.get("Hipfire_Horizontal_Bullet_Spread")
			vertical_spread = gun_stats.get("Hipfire_Vertical_Bullet_Spread")
		bulletRayCast.target_position.x = randf_range(-horizontal_spread, horizontal_spread)
		bulletRayCast.target_position.z = randf_range(-vertical_spread, vertical_spread)
		bulletRayCast.force_raycast_update()
		if bulletRayCast.is_colliding():
			make_bullet_hole()

func make_bullet_hole():
	var collider = bulletRayCast.get_collider()
	var collision_point = bulletRayCast.get_collision_point()
	var collision_normal = bulletRayCast.get_collision_normal()
	# Not sure how this will work with simple colliders on complex meshes
	# We will want all assets to have a material type, and pick the decal texture
	# accordingly
	
	var decal = preload("res://Assets/Weapons/bulletDecal.tscn").instantiate()
	collider.add_child(decal)

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

	 



## Signals
func pickUp():
	state = "held"
	rigidbody.visible = false
	arms.visible = true
	
func drop():
	print("dropped")
	state = "grounded"
	arms.visible = false
	rigidbody.visible = true
	gunMesh.set_layer_mask_value(2, false)
	gunMesh.set_layer_mask_value(1, true)
	
