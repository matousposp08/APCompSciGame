extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LineEdit
@onready var username = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/Username

const Player = preload("res://scenes/player/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$PMenu.hide()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("game_pause"):
		if $PMenu.visible:
			$PMenu.hide()
		else:
			$PMenu.show()
	
func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _on_host_button_pressed():
	main_menu.hide()
	
	$CanvasLayer/ColorRect.hide()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

	var player_id = multiplayer.get_unique_id()
	add_player(multiplayer.get_unique_id())
	print("host joined")
	set_player_initial_position(player_id)
	
	#upnp_setup()

func _on_join_button_pressed():
	if address_entry.text == "":
		enet_peer.create_client("localhost", PORT)
	main_menu.hide()
	$CanvasLayer/ColorRect.hide()
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

	var player_id = multiplayer.get_unique_id()
	add_player(player_id)
	set_player_initial_position(player_id)

func set_player_initial_position(player_id):
	# Set the initial position to (0, 0, 0) for the player with the given ID
	var player = get_node_or_null(str(player_id))
	if player:
		player.global_transform.origin = Vector3(randi_range(-10, 10), 2, randi_range(-10, 10))
		
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
