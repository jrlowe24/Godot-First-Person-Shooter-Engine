extends Node3D

@onready var FakeLensMesh : MeshInstance3D = $MeshInstance3D;
var shader
var fade_timer : float
var fade_speed : float = 5
var target_alpha : float
var curr_alpha : float = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	shader = FakeLensMesh.get_active_material(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$SubViewport/Camera3D.global_transform = $Marker3D.global_transform
	
	if Input.is_action_pressed("aim"):
		target_alpha = 0
	else:
		target_alpha = 1
		
	curr_alpha = lerp(curr_alpha, target_alpha, delta * fade_speed)
	var curr_albedo = shader.get_shader_parameter("albedo")
	curr_albedo.a = curr_alpha
	shader.set_shader_parameter("albedo", curr_albedo)

