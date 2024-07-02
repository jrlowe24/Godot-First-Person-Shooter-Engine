extends RigidBody3D

var WeaponMesh : Node3D
var weaponCollisionShape : CollisionShape3D
@export var collisionShape : CollisionShape3D
# Called when the node enters the scene tree for the first time.
func _ready():
	collisionShape = $CollisionShape3D


func setWeaponMesh(path):
	WeaponMesh = load(path).instantiate()
	weaponCollisionShape = WeaponMesh.get_child(1) as CollisionShape3D
	self.add_child(WeaponMesh)
	self.collisionShape.scale = weaponCollisionShape.scale
	self.collisionShape.shape = weaponCollisionShape.shape

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
