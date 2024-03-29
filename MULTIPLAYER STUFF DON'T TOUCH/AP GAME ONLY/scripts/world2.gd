extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/LineEdit

var ps = 1
var areas = {}
var game = false
var end = false
var pause = false
var grav =  9.8
var best
var nonlocal = false

var players = []
var score = {}
var time = false

const Player = preload("res://scenes/player/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	$Label.visible = false
	$Label2.visible = false
	$PMenu.hide()

func add_score(attacker, dead, method):
	score[attacker] += 1
	if method == "fireball":
		print(get_node(attacker+"/Username").text + " burned "+get_node(dead+"/Username").text)

func checkScore(player, score):
	if not(get_node(best) == null):
		print(str(score) + " "+player + " " + str(get_node(best).death))
		if score < get_node(best).death:
			$Label2.text = player

func game_start(mode, timer):
	game = true
	'''
	if timer:
		time = true
		$Timer.wait_time = 10
		$Timer.start()
	'''
	if mode == 0:
		grav = 9.8
		$Label.text = "0"
	if mode == 1:
		pass
		$Label.text = "1"
	if mode == 2:
		grav = 2
		$Label.text = "2"
	for x in players:
		get_node(x).start()

func game_end():
	end = true
	$results/Label.text = "MATCH OVER"
	$Label.visible = false
	$results.visible = true
	$results/AudioStreamPlayer.play()

func _process(delta: float) -> void:
	best = $Label2.text
	if Input.is_action_just_pressed("game_pause"):
		pause = not(pause)
		if $PMenu.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$PMenu.hide()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$PMenu.show()

func add_player(peer_id):
	var player = Player.instantiate()
	#print(ps)
	player.from = $Label.text
	player.name = str(peer_id)
	#print(player.from)
	#print(player.name)
	add_child(player)
	player.add_to_group($Label.text)
	#print(str(ps) + " " + player.from + " " + $Label.text + str(player.is_multiplayer_authority()))
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
	players.append(str(player_id))
	score[str(player_id)] = 0
	print(score)
	print("host joined")
	set_player_initial_position(player_id)
	
	$CanvasLayer/CheckButton.visible = false
	if nonlocal:
		upnp_setup()

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
	players.append(str(player_id))
	score[str(player_id)] = 0
	print(score)
	set_player_initial_position(player_id)
	$CanvasLayer/CheckButton.visible = false

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


func _on_timer_timeout():
	game_end()


func _on_check_button_toggled(toggled_on):
	nonlocal = not(nonlocal)
