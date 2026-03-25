class_name GameRaw
extends RefCounted
## Pure data representation of game state, decoupled from UI.
## Used by AI for move evaluation and simulation.

# Mountain heights: 5->4, 6->4, 7->3, 8->3, 9->2, 10->2
const MOUNTAIN_HEIGHTS: Dictionary = {5: 4, 6: 4, 7: 3, 8: 3, 9: 2, 10: 2}

# All mold patterns for grouping 4 dice into up to 4 sums
const MOLDS: Array = [
	[[0], [1], [2], [3]], [[0], [1], [2, 3], []], [[0], [1, 2], [3], []],
	[[0], [1, 3], [2], []], [[0], [1, 2, 3], [], []], [[0, 2], [1], [3], []],
	[[0, 3], [1], [2], []], [[0, 1], [2], [3], []], [[0, 1], [2, 3], [], []],
	[[0, 3], [1, 2], [], []], [[0, 2], [1, 3], [], []],
	[[0, 1, 3], [2], [], []], [[0, 2, 3], [1], [], []],
	[[0, 1, 2], [3], [], []], [[0, 1, 2, 3], [], [], []],
]


static func blank_gamestate_raw() -> Dictionary:
	var board := {}
	var tokens := {}
	var scoreboards := {}
	for mountain in range(5, 11):
		board[mountain] = {}
		for player in range(GameConfig.player_count):
			board[mountain][player] = 0
		tokens[mountain] = GameConfig.tokens_per_mountain[mountain]
	for player in range(GameConfig.player_count):
		scoreboards[player] = {}
		for i in range(5, 12):
			scoreboards[player][i] = 0
	return {
		"board": board,
		"tokens": tokens,
		"bonus_tokens": GameConfig.bonus_token_values.duplicate(),
		"scoreboards": scoreboards,
		"player": 0,
	}


static func is_over(gs: Dictionary) -> bool:
	if gs.player == 0:
		var piles_exhausted := 0
		for mountain in range(5, 11):
			if gs.tokens[mountain] == 0:
				piles_exhausted += 1
		return piles_exhausted >= GameConfig.mountains_to_end_game or gs.bonus_tokens.size() == 0
	return false


static func winner(gs: Dictionary) -> int:
	var best_player := 0
	var best_score: float = gs.scoreboards[0][11]
	for p in range(1, GameConfig.player_count):
		if gs.scoreboards[p][11] > best_score:
			best_score = gs.scoreboards[p][11]
			best_player = p
	return best_player


static func make_move(gs: Dictionary, move: Dictionary) -> Dictionary:
	for mountain in range(5, 11):
		_make_mountain_move(gs, mountain, move[mountain])
	gs.player = (gs.player + 1) % GameConfig.player_count
	return gs


static func copy_game(gs: Dictionary) -> Dictionary:
	var board := {}
	for mountain in range(5, 11):
		board[mountain] = {}
		for player in range(GameConfig.player_count):
			board[mountain][player] = gs.board[mountain][player]
	var tokens := {}
	for mountain in range(5, 11):
		tokens[mountain] = gs.tokens[mountain]
	var scoreboards := {}
	for player in range(GameConfig.player_count):
		scoreboards[player] = {}
		for i in range(5, 12):
			scoreboards[player][i] = gs.scoreboards[player][i]
	return {
		"board": board,
		"tokens": tokens,
		"bonus_tokens": gs.bonus_tokens.duplicate(),
		"scoreboards": scoreboards,
		"player": gs.player,
	}


static func _make_mountain_move(gs: Dictionary, mountain: int, movement: int) -> void:
	if movement == 0:
		return
	var height: int = MOUNTAIN_HEIGHTS[mountain]
	var current_pos: int = gs.board[mountain][gs.player]
	var to_award: int = (current_pos + movement) - height
	if current_pos != height:
		to_award += 1
	gs.board[mountain][gs.player] += movement
	if gs.board[mountain][gs.player] >= height:
		gs.board[mountain][gs.player] = height
		_knock_other_goats_off(gs, mountain)
		_award_tokens(gs, mountain, to_award)


static func _knock_other_goats_off(gs: Dictionary, mountain: int) -> void:
	for player in range(GameConfig.player_count):
		if player == gs.player:
			continue
		if gs.board[mountain][player] == MOUNTAIN_HEIGHTS[mountain]:
			gs.board[mountain][player] = 0


static func _award_tokens(gs: Dictionary, mountain: int, number: int) -> void:
	for _i in range(number):
		if gs.tokens[mountain] > 0:
			gs.tokens[mountain] -= 1
			if _completes_set(gs, mountain):
				_award_bonus_token(gs)
			gs.scoreboards[gs.player][mountain] += 1
			gs.scoreboards[gs.player][11] += mountain


static func _completes_set(gs: Dictionary, mountain: int) -> bool:
	for other in range(5, 11):
		if other == mountain:
			continue
		if gs.scoreboards[gs.player][other] <= gs.scoreboards[gs.player][mountain]:
			return false
	return true


static func _award_bonus_token(gs: Dictionary) -> void:
	if gs.bonus_tokens.size() > 0:
		var bonus: int = gs.bonus_tokens.pop_back()
		gs.scoreboards[gs.player][11] += bonus


static func apply_wilds(values: Array, wilds: Array) -> Array:
	var replaced_count := 0
	var output := []
	for value in values:
		if value == 1:
			output.append(wilds[replaced_count])
			replaced_count += 1
		else:
			output.append(value)
	return output


static func _make_wild(roll: Array) -> Array:
	var wild_count := roll.count(1) - 1
	if wild_count < 0:
		wild_count = 0
	var combos := _array_pow([1, 2, 3, 4, 5, 6], wild_count)
	var result := []
	for wilds in combos:
		result.append(apply_wilds(roll, wilds + [1]))
	return result


static func roll_to_moves(roll: Array) -> Array:
	var wild_rolls := _make_wild(roll)
	var drop_options := _array_pow([0, 1], 4)

	var all_moves := []
	for combination in wild_rolls:
		for mold in MOLDS:
			var base_move := []
			for column in mold:
				var col_sum := 0
				for idx in column:
					col_sum += combination[idx]
				var val: int = col_sum if (col_sum >= 5 and col_sum <= 10) else 0
				base_move.append(val)

			for drop in drop_options:
				var dropped_move := []
				for k in range(4):
					dropped_move.append(drop[k] * base_move[k])
				dropped_move.sort()

				var entry := {"move": dropped_move, "mold": mold}
				var is_dup := false
				for existing in all_moves:
					if existing.move == dropped_move:
						is_dup = true
						break
				if not is_dup:
					all_moves.append(entry)

	return all_moves


## Convert a move array [0,0,7,8] to a move dictionary {5:0, 6:0, 7:1, 8:1, 9:0, 10:0}
static func move_array_to_dict(move_arr: Array) -> Dictionary:
	var result := {}
	for mountain in range(5, 11):
		result[mountain] = move_arr.count(mountain)
	return result


## Cartesian power of an array: xs^n
static func _array_pow(xs: Array, n: int) -> Array:
	if n == 0:
		return [[]]
	var prev := _array_pow(xs, n - 1)
	var result := []
	for combo in prev:
		for x in xs:
			result.append(combo + [x])
	return result
