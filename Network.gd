# Typical lobby implementation, imagine this being in /root/lobby

extends Node

# Connect all functions
const SERVER_PORT = 9500;
const MAX_PLAYERS = 2;
const SERVER_IP = "127.0.0.1";


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

# Player info, associate ID to data
var player_info = {}
# Info we send to other players
var my_info = { name = "Johnson Magenta", favorite_color = Color8(255, 0, 255) }

func create_server():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func create_client():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().set_network_peer(peer)

func _player_connected(id):
	print("Server player connected: " + str(id));

func _player_disconnected(id):
    player_info.erase(id) # Erase player from info

func _connected_ok():
	print("Client connected to server: ");
	print("Client notifying my existence: ");
	# Only called on clients, not server. Send my ID and info to all the other peers
	rpc("register_player", get_tree().get_network_unique_id(), my_info);

func _server_disconnected():
	pass # Server kicked us, show error and abort

func _connected_fail():
	pass # Could not even connect to server, abort

remote func register_player(id, info):
	print("Server received player info: " + str(id));
	print(info.name);
	# Store the info
	player_info[id] = info
	
	print("Server broadcasting new player: " + str(id));
	
	# If I'm the server, let the new guy know about existing players
	if get_tree().is_network_server():
	    # Send my info to new player
	    rpc_id(id, "register_player", 1, my_info)
	    # Send the info of existing players
	    for peer_id in player_info:
	        rpc_id(id, "register_player", peer_id, player_info[peer_id])
	
	# Call function to update lobby UI here
