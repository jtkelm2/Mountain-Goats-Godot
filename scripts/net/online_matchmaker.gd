extends Node
## Handles the WebSocket lobby handshake: host, join, and game-start exchange.
## LobbyScreen instantiates this and reacts to its signals; has no game logic.

signal room_created(code: String)
signal opponent_connected()
signal opponent_ready_to_start()  # joiner received game_start from host


func host() -> void:
	NetworkManager.room_created.connect(_on_room_created, CONNECT_ONE_SHOT)
	NetworkManager.opponent_connected.connect(_on_opponent_connected, CONNECT_ONE_SHOT)
	NetworkManager.connect_to_server()
	await get_tree().create_timer(1.0).timeout
	NetworkManager.create_room()


func join(code: String) -> void:
	NetworkManager.opponent_connected.connect(_on_opponent_connected, CONNECT_ONE_SHOT)
	NetworkManager.message_received.connect(_on_message_for_join)
	NetworkManager.connect_to_server()
	await get_tree().create_timer(1.0).timeout
	NetworkManager.join_room(code)


func start_match() -> void:
	NetworkManager.send({"type": "game_start"})


func _on_room_created(code: String) -> void:
	room_created.emit(code)


func _on_opponent_connected() -> void:
	opponent_connected.emit()


func _on_message_for_join(data: Dictionary) -> void:
	if data.get("type") == "game_start":
		NetworkManager.message_received.disconnect(_on_message_for_join)
		opponent_ready_to_start.emit()
