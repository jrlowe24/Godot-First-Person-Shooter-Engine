extends SubViewport

var screen_size : Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().size_changed.connect(resize)
	screen_size = get_window().size
	size = screen_size
	
func resize():
	screen_size = get_window().size
	size = screen_size
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
