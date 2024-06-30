extends Node3D

@export var TTL : float = 3
@export var sizeVariation : float = .02

var currTTL : float = TTL
var decal : Decal
# Called when the node enters the scene tree for the first time.
func _ready():
	decal = $Decal
	var currSize = decal.size.x
	var adjustment = randf_range(- sizeVariation, sizeVariation)
	var newSize = currSize + adjustment
	decal.size = Vector3(newSize, newSize, newSize)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	currTTL -= delta
	if currTTL <= 0:
		decal.modulate.a -= delta
		if decal.modulate.a <= 0:
			queue_free()
	
