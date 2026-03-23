class_name AILab
extends RefCounted
## Collection of AI strategies. Each AI is a Callable(gamestate: Dictionary,
## moves: Array[Dictionary]) -> Dictionary that picks the best move.


## Returns a random move.
static func random_ai() -> Callable:
	return func(gs: Dictionary, moves: Array) -> Dictionary:
		return moves[randi() % moves.size()]


## Wraps a heuristic (gs, player) -> float into an AI that picks the move
## maximizing the heuristic from the current player's perspective.
static func heuristic_ai(heuristic: Callable) -> Callable:
	return func(gs: Dictionary, moves: Array) -> Dictionary:
		var best_move = moves[0]
		var best_val: float = -INF
		for move in moves:
			var child := GameRaw.copy_game(gs)
			GameRaw.make_move(child, move)
			var val: float = heuristic.call(child, gs.player)
			if val >= best_val:
				best_val = val
				best_move = move
		return best_move


## Wraps a move heuristic (gs, move) -> float into an AI.
static func move_heuristic_ai(move_heuristic: Callable) -> Callable:
	return func(gs: Dictionary, moves: Array) -> Dictionary:
		var best_move = moves[0]
		var best_val: float = -INF
		for move in moves:
			var val: float = move_heuristic.call(gs, move)
			if val >= best_val:
				best_val = val
				best_move = move
		return best_move


# ---- Heuristics ----

static func total_score_heuristic() -> Callable:
	return func(gs: Dictionary, player: int) -> float:
		return float(gs.scoreboards[player][11])


static func handcraft_score_heuristic() -> Callable:
	return func(gs: Dictionary, player: int) -> float:
		var total: float = gs.scoreboards[player][11] * 100.0
		var smallest := 4
		for mountain in range(5, 11):
			if gs.scoreboards[player][mountain] < smallest:
				smallest = gs.scoreboards[player][mountain]
		for mountain in range(5, 11):
			if gs.tokens[mountain] == 0:
				continue
			var mountain_bonus: float = 2.0 if gs.scoreboards[player][mountain] == smallest else 0.0
			total += gs.board[mountain][player] * (mountain + mountain_bonus)
		return total


static func tokenized_weight_move_heuristic() -> Callable:
	return func(gs: Dictionary, move: Dictionary) -> float:
		var result: float = 0.0
		for mountain in range(5, 11):
			var factor: float = 0.0 if gs.tokens[mountain] == 0 else 1.0
			result += factor * mountain * move[mountain]
		return result


# ---- Pre-built AIs ----

static func handcraft_score_ai() -> Callable:
	return heuristic_ai(handcraft_score_heuristic())


static func tokenized_weighted_mover_ai() -> Callable:
	return move_heuristic_ai(tokenized_weight_move_heuristic())


static func score_naive_ai() -> Callable:
	return heuristic_ai(total_score_heuristic())
