extends Node
## Low-level WebSocket layer for online multiplayer. Autoloaded as "NetworkManager".
## Connects to the relay server and routes messages. No game logic.

const RELAY_URL_LOCAL := "ws://localhost:8765"
const RELAY_URL_PROD  := "wss://your-relay-server.example.com"

# Change this to RELAY_URL_PROD before deploying.
const RELAY_URL := RELAY_URL_LOCAL

signal room_created(code: String)
signal opponent_connected()
signal opponent_disconnected()
signal message_received(data: Dictionary)

var _socket: WebSocketPeer = null
var _connected: bool = false


func connect_to_server() -> void:
	_socket = WebSocketPeer.new()
	var err := _socket.connect_to_url(RELAY_URL)
	if err != OK:
		push_error("NetworkManager: failed to connect to relay (%s)" % RELAY_URL)


func create_room() -> void:
	_send_raw({"type": "create_room"})


func join_room(code: String) -> void:
	_send_raw({"type": "join_room", "code": code})


func send(data: Dictionary) -> void:
	_send_raw({"type": "relay", "data": data})


func disconnect_from_server() -> void:
	if _socket:
		_socket.close()
	_socket = null
	_connected = false


func _process(_delta: float) -> void:
	if _socket == null:
		return

	_socket.poll()
	var state := _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _connected:
			_connected = true

		while _socket.get_available_packet_count() > 0:
			var raw := _socket.get_packet().get_string_from_utf8()
			var msg = JSON.parse_string(raw)
			if msg == null:
				continue
			_dispatch(msg)

	elif state == WebSocketPeer.STATE_CLOSED:
		if _connected:
			_connected = false
			message_received.emit({"type": "opponent_disconnected"})
		_socket = null


func _send_raw(data: Dictionary) -> void:
	if _socket == null or _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_warning("NetworkManager: tried to send while not connected")
		return
	_socket.send_text(JSON.stringify(data))


func _dispatch(msg: Dictionary) -> void:
	match msg.get("type", ""):
		"room_created":
			room_created.emit(msg.get("code", ""))
		"opponent_connected":
			opponent_connected.emit()
		"opponent_disconnected":
			opponent_disconnected.emit()
		"relay":
			var data = msg.get("data", {})
			if data is Dictionary:
				message_received.emit(data)
		"error":
			push_warning("NetworkManager relay error: %s" % msg.get("message", "unknown"))
