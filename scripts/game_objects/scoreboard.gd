class_name Scoreboard
extends Sprite2D
## Player scoreboard panel that rotates around the board edges.

var turn_order: int = 0
var rank_sprite: Sprite2D = null
var tokens_raw: Dictionary = {}  # {5: count, 6: count, ..., 11: bonus_points}
var token_locales: Dictionary = {}  # mountain -> Locale
var bonus_tokens_awarded: int = 0
var _bonus_token_locale: Locale = null
var score_label: Label = null
var _anchor: RotationAnchor = null
var player: int = 0
var origin: Vector2 = Vector2.ZERO


func _init() -> void:
	pass


func setup(p: int, main_scene: Node) -> void:
	player = p
	centered = false
	texture = load("res://assets/panel.png")
	hframes = maxi(1, int(texture.get_width() / Reg.PANEL_WIDTH))
	vframes = maxi(1, int(texture.get_height() / Reg.PANEL_HEIGHT))
	frame = player
	origin = Vector2(Reg.PANEL_WIDTH / 2.0, Reg.PANEL_HEIGHT / 2.0)

	_anchor = RotationAnchor.new(origin.x, origin.y)
	_anchor.add_obj(self)

	turn_order = 0
	tokens_raw = {}
	for i in range(5, 12):
		tokens_raw[i] = 0
	bonus_tokens_awarded = 0

	_init_rank(main_scene)
	_init_score(main_scene)
	_init_locales()
	rotate_board(4 - player)


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)


func _init_rank(main_scene: Node) -> void:
	rank_sprite = Sprite2D.new()
	rank_sprite.texture = load("res://assets/rank.png")
	rank_sprite.centered = false
	rank_sprite.hframes = maxi(1, int(rank_sprite.texture.get_width() / Reg.RANK_SIZE))
	rank_sprite.vframes = 1
	rank_sprite.position = Vector2(
		position.x + Reg.PANEL_WIDTH - Reg.RANK_SIZE,
		position.y + Reg.SPACING
	)
	_anchor.add_obj(rank_sprite)
	main_scene.add_child(rank_sprite)


func _init_score(main_scene: Node) -> void:
	score_label = Label.new()
	score_label.position = Vector2(
		position.x + Reg.PANEL_WIDTH - Reg.RANK_SIZE,
		position.y + Reg.PANEL_HEIGHT - Reg.TOKEN_SIZE
	)
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", roundi(0.8 * Reg.TOKEN_SIZE))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.custom_minimum_size = Vector2(Reg.RANK_SIZE, 0)
	_anchor.add_obj(score_label)
	main_scene.add_child(score_label)


func _init_locales() -> void:
	token_locales = {}
	for mountain in range(5, 11):
		var loc := GridLocale.new(
			position.x + Reg.SPACING + (mountain - 5) * Reg.TOKEN_SIZE,
			position.y + Reg.SPACING - 1,
			Reg.TOKEN_SIZE,
			2.0 * (Reg.PANEL_HEIGHT - Reg.TOKEN_SIZE),
			12, 1
		)
		token_locales[mountain] = loc
		_anchor.add_obj(loc)

	_bonus_token_locale = GridLocale.new(
		score_label.position.x, score_label.position.y,
		0, 0, 4, 1, false
	)
	_anchor.add_obj(_bonus_token_locale)


func change_rank(new_rank: int) -> void:
	rank_sprite.frame = new_rank


func rotate_board(times: int) -> void:
	turn_order = (turn_order - times + 400) % 4  # +400 to avoid negative mod

	var old_mid := get_midpoint()
	var new_mid: Vector2 = Reg.PANEL_PLACEMENTS[turn_order]
	_anchor.anchor_x += new_mid.x - old_mid.x
	_anchor.anchor_y += new_mid.y - old_mid.y
	_anchor.anchor_angle += 90.0 * times


func award(token: Token) -> void:
	if token.token_kind == Reg.TokenKind.MOUNTAIN:
		var mountain: int = token.token_mountain
		token.toggle_preview(false)
		token_locales[mountain].insert_piece(token, 0, func(_p):
			token.awarded = true
			_update_scores()
		)
		tokens_raw[mountain] += 1
	else:  # BONUS
		var n: int = token.token_bonus_value
		token.toggle_preview(false)
		_bonus_token_locale.add_piece(token, func(_p):
			token.awarded = true
			GameSystem.effects.fade_out(token)
			_update_scores()
		)
		tokens_raw[11] += n
		bonus_tokens_awarded += 1


func _update_scores() -> void:
	var total := 0
	for n in range(6):
		total += tokens_raw[n + 5] * (n + 5)
	total += tokens_raw[11]
	score_label.text = str(total)
