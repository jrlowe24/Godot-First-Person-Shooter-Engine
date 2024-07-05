extends Node3D

enum weaponTypes {
	M4,
	AK47,
	Glock,
	Sniper
}

@export var weaponType : weaponTypes

var weaponSceneDict = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var model : PackedScene
	var rig : PackedScene
	match weaponType:
		weaponTypes.M4:
			model = preload("res://Assets/Weapons/M4/M4.tscn")
			rig = preload("res://Assets/Weapons/M4/m4_rig.tscn")
		weaponTypes.AK47:
			model = preload("res://Assets/Weapons/Ak47/AK47.tscn")
			rig = preload("res://Assets/Weapons/Ak47/ak_47_rig_v_4.tscn")
		weaponTypes.Glock:
			model = preload("res://Assets/Weapons/Glock/Glock.tscn")
			rig = preload("res://Assets/Weapons/Glock/glock_rig.tscn")
		weaponTypes.Sniper:
			model = preload("res://Assets/Weapons/Sniper/Sniper.tscn")
			rig = preload("res://Assets/Weapons/Sniper/sniper_rig.tscn")
	
	var weaponMesh = model.instantiate()
	self.weaponSceneDict[weaponType] = rig.instantiate()
	self.add_child(weaponMesh)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
# return the type of weapon this scene represents
func getType():
	return weaponSceneDict[weaponType]
