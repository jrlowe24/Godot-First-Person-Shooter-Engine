extends Node3D

@export var scale_size : Vector2i

@onready var mainMenu = $CanvasLayer/MainMenu
@onready var addressEntry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry


const PORT = 9999
var enetPeer = ENetMultiplayerPeer.new()

const player = preload("res://fpc/character.tscn")

func _onready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_tree().root.content_scale_size = scale_size
	
func add_player(peerId):
	var player = player.instantiate()
	player.name = str(peerId)
	add_child(player)

func _on_host_button_pressed():
	mainMenu.hide()
	
	enetPeer.create_server(PORT)
	multiplayer.multiplayer_peer = enetPeer
	multiplayer.peer_connected.connect(add_player)
	
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	mainMenu.hide()
	enetPeer.create_client("Localhost", PORT)
	multiplayer.multiplayer_peer = enetPeer
