extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LineEdit

var ps = 1
var areas = {}

const Player = preload("res://scenes/player/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$PMenu.hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("game_pause"):
		if $PMenu.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$PMenu.hide()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$PMenu.show()
	
func add_player(peer_id):
	$Label.text = str(ps)
	var player = Player.instantiate()
	#print(ps)
	player.from = $Label.text
	player.name = str(peer_id)
	#print(player.from)
	#print(player.name)
	add_child(player)
	player.add_to_group($Label.text)
	#print(str(ps) + " " + player.from + " " + $Label.text + str(player.is_multiplayer_authority()))
	print("Peer ID:" + str(peer_id))
	if not player.is_multiplayer_authority(): return
	player.get_node('Area3D').add_to_group($Label.text)
	player.get_node('head/crowbar').add_to_group($Label.text)
	player.get_node('head/crowbar/Area3D').add_to_group("crowbar"+player.get_node("Username").text)
	print(player.get_node("Username").text+": " + str(peer_id))
	$CanvasLayer/Oig2.position = Vector2(1000000000000000,1000000000000)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		#ps -= 1
		player.queue_free()

func _on_host_button_pressed():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	main_menu.hide()
	
	$CanvasLayer/ColorRect.hide()
	$CanvasLayer/Oig2.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	ps = 1
	var player_id = multiplayer.get_unique_id()
	add_player(multiplayer.get_unique_id())
	print("host joined")
	set_player_initial_position(player_id)
	
	#upnp_setup()

func _on_join_button_pressed(): 
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	if address_entry.text == "":
		enet_peer.create_client("localhost", PORT)
	main_menu.hide()
	$CanvasLayer/ColorRect.hide()
	$CanvasLayer/Oig2
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	ps += 1
	var player_id = multiplayer.get_unique_id()
	print(player_id)
	add_player(player_id)
	set_player_initial_position(player_id)

func set_player_initial_position(player_id):
	# Set the initial position to (0, 0, 0) for the player with the given ID
	var player = get_node_or_null(str(player_id))
	if player:
		player.global_transform.origin = player.spawn_locations.pick_random()
		
func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
