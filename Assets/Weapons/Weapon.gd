extends Node3D

@export var gun_stats: Resource

var rigidbody : RigidBody3D
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer
var arms : Node3D
var gunMesh : MeshInstance3D
var state : String
var weaponController : Node3D


func _ready():
	if animationPlayer:
		animationPlayer.play("Reset")
		weaponController = get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d().get_parent_node_3d()
		weaponController.connect("shoot_signal", _on_shoot)
	#rigidbody = $RigidBody3D
	#arms = $Arms
	#gunMesh = $GunMesh
	#rigidbody.set_physics_process(true)

func _process(delta):
	pass
	
func _on_shoot():
	animationPlayer.play("Shoot2")
	
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
	
