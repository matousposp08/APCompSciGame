extends Node

@onready var main_menu = $"CanvasLayer/Main Menu"
@onready var address_entry = $"CanvasLayer/Main Menu/MarginContainer/VBoxContainer/AddressEntry"


const player = preload("res://MULTIPLAYER STUFF DON'T TOUCH/AP GAME ONLY/scenes/player/player2.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

var paused = false

signal pause
signal unpause

func add_player(peer_id):
	var player = player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _on_host_pressed():
	main_menu.hide()
	$bg.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	add_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(add_player)
	print("Host joined")

func _on_join_pressed():
	$bg.hide()
	if(address_entry.text == ""):
		enet_peer.create_client("localhost", PORT)
	main_menu.hide()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause_game(): 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#get_tree().paused = true #In case you want to pause the game
	pause.emit()

func unpause_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#get_tree().paused = false
	unpause.emit()

func _process(_delta):
	if Input.is_action_just_released("game_pause"):
		paused = !paused
		if paused:
			pause_game()
		else:
			unpause_game()




