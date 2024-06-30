extends Node3D

@export var TTL : float = 3

var animationPlayer : AnimationPlayer
var decal : Decal
# Called when the node enters the scene tree for the first time.
func _ready():
	animationPlayer = $AnimationPlayer
	decal = $Decal

var currTTL : float = TTL
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	currTTL -= delta
	if currTTL <= 0:
		decal.modulate.a -= delta
		if decal.modulate.a <= 0:
			queue_free()
	
