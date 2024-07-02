extends Node3D

@export var gun_stats: Resource

var rigidbody : RigidBody3D
var arms : Node3D
var gunMesh : MeshInstance3D
var state : String


func _ready():
	pass
	#rigidbody = $RigidBody3D
	#arms = $Arms
	#gunMesh = $GunMesh
	#rigidbody.set_physics_process(true)

func _process(delta):
	pass
	
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
