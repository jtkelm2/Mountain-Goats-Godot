extends Node
## Signal bridge between game logic and the relay network.
## Attached as a child of PlayState only when online_mode is true.
##
## Outbound: listens to PlayState signals, sends to relay when it is the local
## player's turn (guards by player type, not by GameConfig flags).
##
## Inbound: translates relay messages into GameEvents queued on the event system,
## so game states handle them identically to local input — no special-case branches.

var _ps = null  # PlayState reference (get_parent())


func _ready() -> void:
	_ps = get_parent()

	# Outbound: game signals → relay server
	_ps.dice_rolled.connect(_on_dice_rolled)
	_ps.planning_updated.connect(_on_planning_updated)
	_ps.turn_ended.connect(_on_turn_ended)

	# Inbound: relay server messages → GameEvents on the event queue
	NetworkManager.message_received.connect(_on_network_message)


func _on_dice_rolled(dice_data: Array) -> void:
	if GameSystem.players[_ps.current_player].type != GameSystem.PlayerType.REMOTE:
		NetworkManager.send({"type": "roll_result", "dice": dice_data})


func _on_planning_updated(snapshot: Dictionary) -> void:
	if GameSystem.players[_ps.current_player].type != GameSystem.PlayerType.REMOTE:
		NetworkManager.send({"type": "planning_update", "snapshot": snapshot})


func _on_turn_ended(final_state: Dictionary) -> void:
	if GameSystem.players[_ps.current_player].type != GameSystem.PlayerType.REMOTE:
		NetworkManager.send({"type": "turn_confirmed", "state": final_state})


func _on_network_message(data: Dictionary) -> void:
	match data.get("type", ""):
		"roll_result":
			GameSystem.events.queue(GameEvent.remote_roll(data.get("dice", [])))
		"planning_update":
			GameSystem.events.queue(GameEvent.remote_planning(data.get("snapshot", {})))
		"turn_confirmed":
			GameSystem.events.queue(GameEvent.remote_confirmed(data.get("state", {})))
		"opponent_disconnected":
			_ps.opponent_disconnected.emit()
