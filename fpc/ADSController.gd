extends Node3D


@export_group("ADS Settings")
@export var ADS_Speed : float = 5
@export var AdsPos: Vector3 = Vector3(-0.077,0.01,0.15)

var ADS : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ADS:
		self.position = lerp(self.position, AdsPos, delta * ADS_Speed)
	else:
		self.position = lerp(self.position, Vector3.ZERO, delta * ADS_Speed)
