class_name PlayState
extends Node2D
## Main game scene. Sets up the board, goats, dice, tokens, scoreboards.

# --- Online multiplayer signals ---
# Outbound (game → NetworkReplicator → relay server)
signal dice_rolled(dice_data: Array)
signal planning_updated(snapshot: Dictionary)
signal turn_ended(final_state: Dictionary)
# Inbound (relay server → NetworkReplicator → game states)
signal remote_roll_received(dice_data: Array)
signal remote_planning_received(snapshot: Dictionary)
signal remote_turn_confirmed(final_state: Dictionary)
signal opponent_disconnected()

var current_player: int = 0
var mountains: Dictionary = {}  # int(5-10) -> Array[Square]
var goats: Dictionary = {}      # int(player) -> {int(mountain): Goat}
var scoreboards: Dictionary = {}  # int(player) -> Scoreboard
var dice_box: DiceBox = null
var dice_roller_sprite: Sprite2D = null
var move_confirm_button: MoveConfirmButton = null
var bonus_tokens: Array = []
var _bonus_token_locale: Locale = null
var _bonus_tokens_awarded: int = 0
var game_ending_this_round: bool = false

const COLUMN_SIZES: Dictionary = {5: 4, 6: 4, 7: 3, 8: 3, 9: 2, 10: 2}


func _ready() -> void:
	GameSystem.init_system(self)
	_init_bg()
	_init_move_confirm_button()
	_init_scoreboards()
	_init_board()
	_init_goats()
	_init_dice_box()
	_init_tokens()
	if GameConfig.online_mode:
		var rep = load("res://scripts/net/network_replicator.gd").new()
		rep.name = "NetworkReplicator"
		add_child(rep)
	GameSystem.events.init_gamestate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("fast_forward"):
		Engine.time_scale = 20.0
	elif event.is_action_released("fast_forward"):
		Engine.time_scale = 1.0


func _init_bg() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/bg.png")
	bg.centered = false
	bg.z_index = Reg.Z_BG
	add_child(bg)


func _init_move_confirm_button() -> void:
	move_confirm_button = MoveConfirmButton.new()
	move_confirm_button.z_index = Reg.Z_UI
	move_confirm_button.setup(
		Reg.MOVE_CONFIRM_X, Reg.MOVE_CONFIRM_Y,
		func():
			if move_confirm_button.modulate.a > 0.1:
				GameSystem.events.queue(GameEvent.movements_confirmed())
	)
	add_child(move_confirm_button)


func _init_board() -> void:
	var x_pos: int = Reg.BOARD_X
	for mountain in range(5, 11):
		mountains[mountain] = []

	for mountain in range(5, 11):
		var y_pos: int = Reg.BOARD_Y + Reg.TOKEN_SIZE
		mountains[mountain].append(
			_init_square(x_pos, y_pos, Reg.SquareType.MOUNTAINTOP,
				mountain, COLUMN_SIZES[mountain])
		)
		y_pos += Reg.SQUARE_SIZE
		for row in range(COLUMN_SIZES[mountain] - 1):
			mountains[mountain].append(
				_init_square(x_pos, y_pos, Reg.SquareType.MOUNTAIN,
					mountain, COLUMN_SIZES[mountain] - row - 1)
			)
			y_pos += Reg.SQUARE_SIZE
		mountains[mountain].append(
			_init_square(x_pos, y_pos, Reg.SquareType.MOUNTAIN_FOOT,
				mountain, 0)
		)
		mountains[mountain].reverse()
		x_pos += Reg.SQUARE_SIZE


func _init_square(sx: int, sy: int, sq_type: int,
		mountain: int, mountain_height: int) -> Square:
	var square := Square.new()
	square.setup(sx, sy, sq_type, mountain, mountain_height, self)
	add_child(square)
	return square


func _init_goats() -> void:
	goats = {}
	for player in range(GameConfig.player_count):
		goats[player] = {}
		for mountain in range(5, 11):
			goats[player][mountain] = _init_goat(player, mountains[mountain][0])


func _init_goat(player: int, square: Square) -> Goat:
	var goat := Goat.new()
	add_child(goat)
	goat.setup(player, square)
	return goat


func _init_scoreboards() -> void:
	scoreboards = {}
	for player in range(GameConfig.player_count):
		_init_scoreboard(player)


func _init_scoreboard(player: int) -> void:
	var sb := Scoreboard.new()
	sb.z_index = Reg.Z_SCOREBOARD
	add_child(sb)
	sb.setup(player)
	scoreboards[player] = sb


func _init_dice_box() -> void:
	dice_roller_sprite = Sprite2D.new()
	dice_roller_sprite.texture = load("res://assets/diceroller.png")
	dice_roller_sprite.centered = false
	dice_roller_sprite.z_index = Reg.Z_DICE_BOX
	add_child(dice_roller_sprite)

	dice_box = DiceBox.new()
	dice_box.z_index = Reg.Z_DICE_BOX
	add_child(dice_box)
	dice_box.setup(Reg.DICEBOX_X, Reg.DICEBOX_Y, self)


func _init_tokens() -> void:
	# Mountain tokens are initialized by Square.setup() for mountaintops.
	# Bonus tokens:
	bonus_tokens = []
	var vp_h: float = get_viewport().get_visible_rect().size.y
	_bonus_token_locale = GridLocale.new(
		Reg.SPACING, vp_h - Reg.SPACING - Reg.TOKEN_SIZE,
		2.0 * Reg.TOKEN_SIZE, roundi(1.25 * Reg.TOKEN_SIZE),
		GameConfig.bonus_token_values.size(), 1, true, 2
	)
	add_child(_bonus_token_locale)
	_bonus_tokens_awarded = 0

	for k in range(GameConfig.bonus_token_values.size()):
		var token := Token.new()
		add_child(token)
		token.setup(0, 0, Reg.TokenKind.BONUS, GameConfig.bonus_token_values[k])
		bonus_tokens.insert(0, token)
		_bonus_token_locale.insert_piece(token, 0)

	for token in bonus_tokens:
		token.teleport_mode = false


func check_for_game_end() -> void:
	var mountains_exhausted := 0
	for mountain in range(5, 11):
		var squares: Array = mountains[mountain]
		if squares[squares.size() - 1].out_of_tokens():
			mountains_exhausted += 1

	var all_bonus_awarded := true
	for token in bonus_tokens:
		if not token.awarded:
			all_bonus_awarded = false

	game_ending_this_round = mountains_exhausted >= GameConfig.mountains_to_end_game or all_bonus_awarded


func next_player() -> void:
	current_player = (current_player + 1) % GameConfig.player_count
	for player in scoreboards:
		scoreboards[player].rotate_board(1)

	var next_state
	if game_ending_this_round and current_player == 0:
		next_state = GameSystem.events.gameover_state
	else:
		next_state = GameSystem.events.dice_rolling_state

	move_confirm_button.fade_out()
	GameSystem.events.queue(GameEvent.switch_state(next_state))


func update_ranks() -> void:
	var total_scores: Array[int] = []
	for player in range(GameConfig.player_count):
		total_scores.append(int(scoreboards[player].score_label.text))
	total_scores.sort()
	total_scores.reverse()

	for player in range(GameConfig.player_count):
		var my_score: int = int(scoreboards[player].score_label.text)
		var rank := 0
		for other_score in total_scores:
			if other_score > my_score:
				rank += 1
		scoreboards[player].change_rank(rank)
