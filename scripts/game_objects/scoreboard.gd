class_name Scoreboard
extends Node2D
## Player scoreboard panel that rotates around the board edges.
## Extends Node2D so that rank_sprite, score_label, and token locales are all
## children and rotate/translate automatically when this node moves.

var turn_order: int = 0
var rank_sprite: Sprite2D = null
var tokens_raw: Dictionary = {}  # {5: count, 6: count, ..., 11: bonus_points}
var token_locales: Dictionary = {}  # mountain -> Locale
var bonus_tokens_awarded: int = 0
var _bonus_token_locale: Locale = null
var score_label: Label = null
var player: int = 0

var _panel: Sprite2D = null


func setup(p: int) -> void:
	player = p

	_panel = Sprite2D.new()
	_panel.texture = load("res://assets/panel.png")
	_panel.centered = false
	_panel.hframes = maxi(1, int(float(_panel.texture.get_width()) / Reg.PANEL_WIDTH))
	_panel.vframes = maxi(1, int(float(_panel.texture.get_height()) / Reg.PANEL_HEIGHT))
	_panel.frame = player
	add_child(_panel)

	turn_order = 0
	tokens_raw = {}
	for i in range(5, 12):
		tokens_raw[i] = 0
	bonus_tokens_awarded = 0

	_init_rank()
	_init_score()
	_init_locales()
	rotate_board(GameConfig.player_count - player)


## Returns the world-space center of the panel.
func get_midpoint() -> Vector2:
	return to_global(Vector2(Reg.PANEL_WIDTH / 2.0, Reg.PANEL_HEIGHT / 2.0))


func _init_rank() -> void:
	rank_sprite = Sprite2D.new()
	rank_sprite.texture = load("res://assets/rank.png")
	rank_sprite.centered = false
	rank_sprite.hframes = maxi(1, int(float(rank_sprite.texture.get_width()) / Reg.RANK_SIZE))
	rank_sprite.vframes = 1
	rank_sprite.position = Vector2(
		Reg.PANEL_WIDTH - Reg.RANK_SIZE,
		Reg.SPACING
	)
	add_child(rank_sprite)


func _init_score() -> void:
	score_label = Label.new()
	score_label.position = Vector2(
		Reg.PANEL_WIDTH - Reg.RANK_SIZE,
		Reg.PANEL_HEIGHT - Reg.TOKEN_SIZE
	)
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", roundi(0.8 * Reg.TOKEN_SIZE))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.custom_minimum_size = Vector2(Reg.RANK_SIZE, 0)
	add_child(score_label)


func _init_locales() -> void:
	token_locales = {}
	for mountain in range(5, 11):
		var loc := GridLocale.new(
			Reg.SPACING + (mountain - 5) * Reg.TOKEN_SIZE,
			Reg.SPACING - 1,
			Reg.TOKEN_SIZE,
			2.0 * (Reg.PANEL_HEIGHT - Reg.TOKEN_SIZE),
			12, 1
		)
		token_locales[mountain] = loc
		add_child(loc)

	_bonus_token_locale = GridLocale.new(
		score_label.position.x, score_label.position.y,
		0, 0, 4, 1, false
	)
	add_child(_bonus_token_locale)


func change_rank(new_rank: int) -> void:
	rank_sprite.frame = new_rank


func rotate_board(times: int) -> void:
	turn_order = posmod(turn_order - times, GameConfig.player_count)

	# Place the panel center at the target world position with the correct rotation.
	# PANEL_PLACEMENTS stores world-space center points for each turn_order.
	var target_center: Vector2 = Reg.PANEL_PLACEMENTS[turn_order]
	var target_rotation := deg_to_rad((4 - turn_order) % 4 * 90.0)

	rotation = target_rotation
	# After rotation, the local panel-center offset is rotated, so subtract it
	# from the target world center to find the correct node origin position.
	var local_center := Vector2(Reg.PANEL_WIDTH / 2.0, Reg.PANEL_HEIGHT / 2.0)
	global_position = target_center - local_center.rotated(target_rotation)

	# Pieces in locales are children of PlayState (world space), not of this node,
	# so they don't rotate automatically. Snap them to their new world positions.
	for loc: Locale in token_locales.values():
		loc.update_positions_immediate()
	_bonus_token_locale.update_positions_immediate()


func award(token: Token) -> void:
	if token.token_kind == Reg.TokenKind.MOUNTAIN:
		var mountain: int = token.token_mountain
		token.toggle_preview(false)
		tokens_raw[mountain] += 1
		_award_mountain_token(token, mountain)  # fire-and-forget
	else:  # BONUS
		var n: int = token.token_bonus_value
		token.toggle_preview(false)
		tokens_raw[11] += n
		bonus_tokens_awarded += 1
		_award_bonus_token(token)  # fire-and-forget


func _award_mountain_token(token: Token, mountain: int) -> void:
	token.z_index = Reg.Z_DRAGGED
	await token_locales[mountain].insert_piece(token, 0)
	token.z_index = Reg.Z_TOKEN
	token.awarded = true
	_update_scores()


func _award_bonus_token(token: Token) -> void:
	token.z_index = Reg.Z_DRAGGED
	await _bonus_token_locale.add_piece(token)
	token.z_index = Reg.Z_TOKEN
	token.awarded = true
	token.fade_out()
	_update_scores()


func _update_scores() -> void:
	var total := 0
	for n in range(6):
		total += tokens_raw[n + 5] * (n + 5)
	total += tokens_raw[11]
	score_label.text = str(total)
