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
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	
	main_menu.hide()
	$bg.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	
	print("Host joined")
	
	#upnp_setup()
	
	add_player(multiplayer.get_unique_id())

func _on_join_pressed():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	
	$bg.hide()
	if(address_entry.text == ""):
		enet_peer.create_client("localhost", PORT)
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	main_menu.hide()
	
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

func upnp_setup():
	var upnp = UPNP.new()
	print("Works 1")
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	print("Works 2")

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	print("Works 3")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	print("Works 4")
	
	print("Success! Join Address: %s" % upnp.query_external_address())
