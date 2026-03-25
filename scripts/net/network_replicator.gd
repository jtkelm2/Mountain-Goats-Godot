extends Node
## Signal bridge between game logic and the relay network.
## Attached as a child of PlayState only when online_mode is true.
## Game states emit signals on PlayState; this node sends them to the server,
## and routes incoming server messages back as PlayState signals.

var _ps = null  # PlayState reference (get_parent())


func _ready() -> void:
	_ps = get_parent()

	# Outbound: game signals → relay server
	_ps.dice_rolled.connect(_on_dice_rolled)
	_ps.planning_updated.connect(_on_planning_updated)
	_ps.turn_ended.connect(_on_turn_ended)

	# Inbound: relay server messages → game signals on PlayState
	NetworkManager.message_received.connect(_on_network_message)


func _on_dice_rolled(dice_data: Array) -> void:
	# Only the active (local) player sends roll results.
	if _ps.current_player == GameConfig.local_player_index:
		NetworkManager.send({"type": "roll_result", "dice": dice_data})


func _on_planning_updated(snapshot: Dictionary) -> void:
	# Only send when it is the local player's turn.
	if _ps.current_player == GameConfig.local_player_index:
		NetworkManager.send({"type": "planning_update", "snapshot": snapshot})


func _on_turn_ended(final_state: Dictionary) -> void:
	# Emitted before next_player(), so current_player is still the active player.
	if _ps.current_player == GameConfig.local_player_index:
		NetworkManager.send({"type": "turn_confirmed", "state": final_state})


func _on_network_message(data: Dictionary) -> void:
	match data.get("type", ""):
		"roll_result":
			_ps.remote_roll_received.emit(data.get("dice", []))
		"planning_update":
			_ps.remote_planning_received.emit(data.get("snapshot", {}))
		"turn_confirmed":
			_ps.remote_turn_confirmed.emit(data.get("state", {}))
		"opponent_disconnected":
			_ps.opponent_disconnected.emit()
