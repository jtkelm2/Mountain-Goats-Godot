class_name AIManager
extends RefCounted
## Translates between the game's visual state and AIRaw data.
## Produces event sequences from AI decisions.

var ps  # PlayState reference
var ai_raw: Callable  # (gamestate_raw, moves) -> move


func _init(play_state, ai_func: Callable) -> void:
	ps = play_state
	ai_raw = ai_func


func on_prompt(gamestate) -> void:
	match gamestate.gamestate_tag:
		Reg.GS_DICE_ROLLING:
			GameSystem.events.handle(GameEvent.mouse_clicked())
		Reg.GS_PLANNING:
			_execute_raw_response(_get_raw_response())


func _execute_raw_response(response: Dictionary) -> void:
	# response = { move_with_mold: {move:[], mold:[]}, wilds: [] }
	var one_dice: Array = ps.dice_box.dice.filter(func(d): return d.value == 1)

	for i in range(response.wilds.size()):
		GameSystem.events.queue(
			GameEvent.ai_cast_wild(one_dice[i], response.wilds[i])
		)

	for slot_idx in range(4):
		for die_num in response.move_with_mold.mold[slot_idx]:
			var die = ps.dice_box.dice[die_num]
			GameSystem.events.queue(
				GameEvent.ai_place_die(die, slot_idx)
			)

	var move_arr: Array = response.move_with_mold.move
	for val in move_arr:
		if val != 0:
			GameSystem.events.queue(
				GameEvent.ai_advance_goat(val)
			)


func _get_raw_response() -> Dictionary:
	var gs_raw := _get_gamestate_raw()
	var dice_values: Array = ps.dice_box.dice.map(func(d): return d.value)
	var one_count: int = dice_values.count(1)
	var wild_count: int = maxi(one_count - 1, 0)

	# Generate all possible wild assignments interspersed with natural 1s
	var wild_possibilities := _generate_wild_possibilities(wild_count, one_count)

	# Get all molded moves from the dice
	var molded_moves := GameRaw.roll_to_moves(dice_values)

	# Convert move array to dictionary for the AI
	var move_dicts: Array = molded_moves.map(func(mm):
		return GameRaw.move_array_to_dict(mm.move)
	)

	# Ask the raw AI for its preferred move
	var raw_response_move: Dictionary = ai_raw.call(gs_raw, move_dicts)

	# Convert AI's chosen move dict back to sorted array form
	var converted := [0, 0, 0, 0]
	for mountain in range(5, 11):
		for _k in range(raw_response_move[mountain]):
			converted.erase(0)
			converted.append(mountain)
	converted.sort()

	# Find the matching molded move
	var raw_response = null
	for mm in molded_moves:
		if mm.move == converted:
			raw_response = mm
			break

	if raw_response == null:
		push_warning("AIManager: didn't find matching move for AI response")
		raw_response = molded_moves[0]

	# Find a wilds combination that fits the chosen mold
	var wilds_output = null
	for wilds in wild_possibilities:
		if _fits_mold(dice_values, raw_response.mold, wilds, converted):
			wilds_output = wilds
			break

	if wilds_output == null:
		push_warning("AIManager: failed to find wilds combination")
		wilds_output = []

	return {"move_with_mold": raw_response, "wilds": wilds_output}


func _fits_mold(dice: Array, mold: Array, wilds: Array, target: Array) -> bool:
	var applied := GameRaw.apply_wilds(dice, wilds)
	var applied_mold := []
	for column in mold:
		var col_sum := 0
		for idx in column:
			col_sum += applied[idx]
		applied_mold.append(col_sum)
	applied_mold.sort()

	for i in range(4):
		if target[i] != 0 and target[i] != applied_mold[i]:
			return false
	return true


func _generate_wild_possibilities(wild_count: int, one_count: int) -> Array:
	if wild_count == 0:
		if one_count == 0:
			return [[]]
		return [[1]]

	var base_combos := GameRaw._array_pow([1, 2, 3, 4, 5, 6], wild_count)
	var result := []
	for combo in base_combos:
		# Intersperse natural 1s into the wilds sequence
		var interspersals := _intersperse(combo)
		for inter in interspersals:
			result.append(inter)
	return result


func _intersperse(wilds: Array) -> Array:
	var output := []
	for i in range(wilds.size() + 1):
		var copy := wilds.duplicate()
		copy.insert(i, 1)
		output.append(copy)
	return output


func _get_gamestate_raw() -> Dictionary:
	var board := {}
	for mountain in range(5, 11):
		board[mountain] = {}
		for player in range(GameConfig.player_count):
			board[mountain][player] = ps.goats[player][mountain].square.mountain_height

	var tokens := {}
	for mountain in range(5, 11):
		var squares: Array = ps.mountains[mountain]
		tokens[mountain] = squares[squares.size() - 1].token_count()

	var bonus_tokens_arr := []
	for token in ps.bonus_tokens:
		if not token.awarded:
			bonus_tokens_arr.append(token.token_value())
	bonus_tokens_arr.sort()

	var scoreboards := {}
	for player in range(GameConfig.player_count):
		scoreboards[player] = {}
		scoreboards[player][11] = 0
		for mountain in range(5, 11):
			scoreboards[player][mountain] = ps.scoreboards[player].tokens_raw[mountain]
			scoreboards[player][11] += ps.scoreboards[player].tokens_raw[mountain] * mountain
		scoreboards[player][11] += ps.scoreboards[player].tokens_raw[11]

	return {
		"board": board,
		"tokens": tokens,
		"bonus_tokens": bonus_tokens_arr,
		"scoreboards": scoreboards,
		"player": ps.current_player,
	}
