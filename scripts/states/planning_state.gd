class_name PlanningState
extends "res://scripts/core/game_state.gd"
## Planning gamestate: players assign dice to slots, preview goat movements,
## and confirm their turn.

var original_squares: Dictionary = {}  # Goat -> Square
var original_slots: Dictionary = {}    # Goat -> int
var movements_confirming: bool = false
var first_move_made: bool = false
var movements: Dictionary = {}  # mountain(int) -> int


func _init(play_state) -> void:
	ps = play_state
	gamestate_tag = Reg.GS_PLANNING


func refresh():
	movements = {}
	for mountain in range(5, 11):
		movements[mountain] = 0
	for mountain in range(5, 11):
		var goat = ps.goats[ps.current_player][mountain]
		original_squares[goat] = goat.square
		original_slots[goat] = goat.in_locale.get_slot(goat)
	movements_confirming = false
	first_move_made = false
	GameSystem.mouse_mgr.set_active([Reg.TAG_GOAT, Reg.TAG_DIE, Reg.TAG_TOKEN])

	if GameConfig.online_mode and ps.current_player != GameConfig.local_player_index:
		# Spectator mode: receive opponent's planning updates.
		ps.remote_planning_received.connect(_apply_remote_planning)
		ps.remote_turn_confirmed.connect(_on_remote_turn_confirmed, CONNECT_ONE_SHOT)

	return self


func handle(event) -> void:
	# During online mode, ignore all input when it is not the local player's turn.
	if GameConfig.online_mode and ps.current_player != GameConfig.local_player_index:
		if event.type == GameEvent.Type.SWITCH_STATE:
			_disconnect_remote_signals()
			GameSystem.events.switch_state(event.gamestate_ref)
		return

	match event.type:
		GameEvent.Type.MOUSE_DOWN:
			_handle_mouse_down(event.object)

		GameEvent.Type.MOUSE_WHEEL:
			if event.object is Die:
				if event.object.change_wild(event.int_value, ps.dice_box):
					_judge_movements()

		GameEvent.Type.DRAGGER_DROPPED:
			_handle_dragger_dropped(event.object)

		GameEvent.Type.MOVEMENTS_CONFIRMED:
			_handle_movements_confirmed()

		GameEvent.Type.SWITCH_STATE:
			GameSystem.events.switch_state(event.gamestate_ref)

		GameEvent.Type.AI_CAST_WILD:
			var die = event.die_ref
			var target_val: int = event.int_value
			var delta: int = target_val - die.value
			if delta != 0:
				die.change_wild(delta, ps.dice_box)

		GameEvent.Type.AI_PLACE_DIE:
			GameSystem.mouse_mgr.set_active([])
			await ps.dice_box.to_slot(event.int_value, event.die_ref)

		GameEvent.Type.AI_ADVANCE_GOAT:
			_check_first_move()
			movements[event.int_value] += 1
			_judge_movements()
			await get_tree().create_timer(1.0).timeout


func _handle_mouse_down(obj) -> void:
	if obj is Die:
		GameSystem.dragger.dragged = obj
		GameSystem.mouse_mgr.set_active([Reg.TAG_DICE_BOX])

	elif obj is Goat:
		if obj.player == ps.current_player and not obj.is_moving:
			GameSystem.dragger.dragged = obj
			GameSystem.mouse_mgr.set_active([Reg.TAG_SQUARE])

	elif obj is Token:
		if obj.token_kind == Reg.TokenKind.MOUNTAIN:
			var mountaintop_clicked: int = obj.token_mountain
			var goat = ps.goats[ps.current_player][mountaintop_clicked]
			if goat.square.square_type == Reg.SquareType.MOUNTAINTOP:
				for token in goat.square.tokens:
					if token.is_moving:
						return
				movements[goat.square.mountain] += 1
				_judge_movements()


func _handle_dragger_dropped(obj) -> void:
	if obj is Goat:
		var hovered = GameSystem.mouse_mgr.hovered
		if hovered is Square:
			var result = _is_valid_drop(obj, hovered)
			if result == null:
				_cancel_drop(obj)
			else:
				movements[obj.square.mountain] = result
		else:
			_cancel_drop(obj)
		_judge_movements()
		GameSystem.mouse_mgr.set_active([Reg.TAG_GOAT, Reg.TAG_DIE, Reg.TAG_TOKEN])

	elif obj is Die:
		var hovered = GameSystem.mouse_mgr.hovered
		if hovered is DiceBox:
			var slot: int = hovered.get_slot_at_mouse()
			if slot < 0:
				obj.in_locale.update_positions()
			else:
				hovered.to_slot(slot, obj)
				_judge_movements()
		else:
			obj.in_locale.update_positions()
		GameSystem.mouse_mgr.set_active([Reg.TAG_GOAT, Reg.TAG_DIE, Reg.TAG_TOKEN])


func _handle_movements_confirmed() -> void:
	if movements_confirming:
		return
	movements_confirming = true
	var mountain_resolving_wait: float = 0.0
	ps.dice_box.unreserve_all()

	for mountain in range(5, 11):
		ps.goats[ps.current_player][mountain].toggle_preview(false)
		mountain_resolving_wait = maxf(_resolve_mountaintop(mountain), mountain_resolving_wait)

	await get_tree().create_timer(mountain_resolving_wait).timeout
	var bonus_wait := _resolve_bonus_tokens()
	await get_tree().create_timer(bonus_wait).timeout
	ps.check_for_game_end()
	ps.update_ranks()
	# Emit turn_ended before advancing player (current_player still identifies the active player).
	if GameConfig.online_mode:
		ps.turn_ended.emit(_build_planning_snapshot())
	ps.next_player()


func _is_valid_drop(goat: Goat, square: Square):
	if goat.square.mountain == square.mountain:
		return square.mountain_height - original_squares[goat].mountain_height
	return null


func _judge_movements() -> void:
	var results: Dictionary = ps.dice_box.judge_movements(movements)
	for mountain in range(5, 11):
		var goat = ps.goats[ps.current_player][mountain]
		if results[mountain] and movements[mountain] > 0:
			_check_first_move()
			var orig_square = original_squares[goat]
			var new_height: int = orig_square.mountain_height + movements[mountain]
			var mountaintop_height: int = ps.mountains[mountain].size() - 1
			var tokens_to_preview: int = new_height - mountaintop_height
			if orig_square.square_type != Reg.SquareType.MOUNTAINTOP:
				tokens_to_preview += 1
			var new_square = ps.mountains[mountain][mini(new_height, mountaintop_height)]
			new_square.add_goat(goat)
			if new_square.square_type == Reg.SquareType.MOUNTAINTOP:
				new_square.toggle_token_previews(tokens_to_preview)
			goat.toggle_preview(true)
		else:
			_cancel_drop(goat)

	# Broadcast planning state to opponent.
	if GameConfig.online_mode and ps.current_player == GameConfig.local_player_index:
		ps.planning_updated.emit(_build_planning_snapshot())


func _cancel_drop(goat: Goat) -> void:
	goat.toggle_preview(false)
	if goat.square.square_type == Reg.SquareType.MOUNTAINTOP:
		goat.square.toggle_token_previews(0)
	if original_squares[goat] != goat.square:
		original_squares[goat].insert_goat(goat, original_slots[goat])
	else:
		goat.in_locale.update_positions()
	movements[goat.square.mountain] = 0


func _resolve_mountaintop(mountain: int) -> float:
	var wait_time: float = 0.0
	var goat = ps.goats[ps.current_player][mountain]
	if goat.square.square_type == Reg.SquareType.MOUNTAINTOP:
		var mountain_foot = ps.mountains[mountain][0]
		wait_time = maxf(goat.square.award_tokens(ps.scoreboards[ps.current_player]), wait_time)
		for other_player in range(GameConfig.player_count):
			if other_player != ps.current_player:
				var other_goat = ps.goats[other_player][mountain]
				if other_goat.square.square_type == Reg.SquareType.MOUNTAINTOP:
					wait_time = maxf(2.0 * Reg.MAX_MOVE_TIME, wait_time)
					mountain_foot.add_goat(other_goat)
	return wait_time


func _resolve_bonus_tokens() -> float:
	var min_token_count := 999
	var sb = ps.scoreboards[ps.current_player]
	for mountain in range(5, 11):
		min_token_count = mini(min_token_count, sb.tokens_raw[mountain])
	return _award_bonus_tokens(min_token_count - sb.bonus_tokens_awarded)


func _award_bonus_tokens(quantity: int) -> float:
	var wait_time: float = 0.0
	for _i in range(quantity):
		for token in ps.bonus_tokens:
			if not token.awarded:
				ps.scoreboards[ps.current_player].award(token)
				wait_time = Reg.MAX_MOVE_TIME + 2.0
				break
	return wait_time


func _check_first_move() -> void:
	if not first_move_made:
		# Don't show the confirm button when spectating an opponent's turn.
		if not (GameConfig.online_mode and ps.current_player != GameConfig.local_player_index):
			ps.move_confirm_button.fade_in()
		first_move_made = true


# --- Online multiplayer helpers ---

func _build_planning_snapshot() -> Dictionary:
	return {
		"dice": ps.dice_box.dice.map(func(d: Die): return {
			"value": d.value,
			"is_wild": d.is_wild,
			"slot": d.slot
		}),
		"movements": movements.duplicate()
	}


func _disconnect_remote_signals() -> void:
	if ps.remote_planning_received.is_connected(_apply_remote_planning):
		ps.remote_planning_received.disconnect(_apply_remote_planning)


func _apply_remote_planning(snapshot: Dictionary) -> void:
	# Apply die slot/value data (slot is set synchronously before the async animation).
	var dice_data: Array = snapshot.get("dice", [])
	for i in range(mini(dice_data.size(), ps.dice_box.dice.size())):
		var d: Die = ps.dice_box.dice[i]
		var dd: Dictionary = dice_data[i]
		d.value = dd.get("value", d.value)
		d.is_wild = dd.get("is_wild", d.is_wild)
		d.frame = d.value - 1 if not d.is_wild or d.value == 1 else d.value + 5
		var new_slot: int = dd.get("slot", d.slot)
		if d.slot != new_slot:
			ps.dice_box.to_slot(new_slot, d)  # fire-and-forget animation
		else:
			ps.dice_box.update_slot_values()

	# Apply movements dict.
	var mov: Dictionary = snapshot.get("movements", {})
	for key in mov:
		movements[int(key)] = mov[key]

	# Update goat preview positions using the same logic as local planning.
	_judge_movements()


func _on_remote_turn_confirmed(final_state: Dictionary) -> void:
	_disconnect_remote_signals()
	# Sync to the authoritative final planning state before resolving.
	if not final_state.is_empty():
		_apply_remote_planning(final_state)
	_handle_movements_confirmed()
