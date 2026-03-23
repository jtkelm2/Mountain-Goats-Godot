class_name Square
extends Sprite2D
## A single board square. Mountaintops hold tokens.

var has_locale: Locale = null  # Locale for goats on this square
var square_type: int = Reg.SquareType.MOUNTAIN
var mountain: int = 5
var mountain_height: int = 0
var origin: Vector2 = Vector2.ZERO

var _free_token_locale: Locale = null
var _previewed_token_locale: Locale = null
var tokens: Array = []  # Array of Token (only on mountaintops)
var previewed_tokens: Array = []


func _init() -> void:
	pass


func setup(sx: float, sy: float, sq_type: int, mtn: int, mtn_height: int,
		main_scene: Node) -> void:
	position = Vector2(sx, sy)
	square_type = sq_type
	mountain = mtn
	mountain_height = mtn_height
	centered = false

	load_spritesheet_manual("res://assets/square.png", Reg.SQUARE_SIZE, Reg.SQUARE_SIZE)

	var locale_spacing := 2
	var dist_between := Reg.SQUARE_SIZE - 2 * locale_spacing - Reg.GOAT_SIZE

	match sq_type:
		Reg.SquareType.MOUNTAINTOP:
			has_locale = GridLocale.new(
				sx + Reg.SQUARE_SIZE / 2.0 - Reg.GOAT_SIZE / 2.0,
				sy + Reg.SQUARE_SIZE / 2.0 - Reg.GOAT_SIZE / 2.0,
				1.5 * Reg.GOAT_SIZE, 0, 1, 2)
			_init_tokens(sx, sy, main_scene)
		Reg.SquareType.MOUNTAIN:
			has_locale = GridLocale.new(
				sx + locale_spacing, sy + locale_spacing,
				2.0 * dist_between, 2.0 * dist_between, 2, 2)
		Reg.SquareType.MOUNTAIN_FOOT:
			has_locale = GridLocale.new(
				sx + locale_spacing, sy + locale_spacing,
				2.0 * dist_between, 2.0 * dist_between, 2, 2)

	# Set animation frame based on mountain and height
	match mountain:
		5: frame = (4 - mountain_height) * 6
		6: frame = (4 - mountain_height) * 6 + 1
		7: frame = (3 - mountain_height) * 6 + 2
		8: frame = (3 - mountain_height) * 6 + 3
		9: frame = (2 - mountain_height) * 6 + 4
		_: frame = (2 - mountain_height) * 6 + 5

	GameSystem.mouse_mgr.init_clickable(self, Reg.TAG_SQUARE)


func load_spritesheet_manual(path: String, frame_w: int, frame_h: int) -> void:
	texture = load(path)
	centered = false
	hframes = maxi(1, int(texture.get_width() / frame_w))
	vframes = maxi(1, int(texture.get_height() / frame_h))
	origin = Vector2(frame_w / 2.0, frame_h / 2.0)


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)


func add_goat(goat) -> void:
	if goat.square == self:
		has_locale.update_positions()
	else:
		goat.square = self
		has_locale.add_piece(goat)


func insert_goat(goat, slot: int, callback: Callable = Callable()) -> void:
	has_locale.insert_piece(goat, slot, callback)
	goat.square = self


func _init_tokens(sx: float, sy: float, main_scene: Node) -> void:
	tokens = []
	for i in range(17 - mountain):
		var token := Token.new()
		token.setup(
			sx + i * Reg.SPACING, sy + i * Reg.SPACING,
			Reg.TokenKind.MOUNTAIN, mountain
		)
		tokens.append(token)
		main_scene.add_child(token)

	_free_token_locale = GridLocale.new(
		sx, sy - Reg.TOKEN_SIZE,
		Reg.SQUARE_SIZE - Reg.TOKEN_SIZE, Reg.TOKEN_SIZE,
		1, tokens.size()
	)
	for token in tokens:
		_free_token_locale.add_piece(token)
		token.teleport_mode = false

	_previewed_token_locale = GridLocale.new(
		sx, sy, Reg.SQUARE_SIZE, Reg.TOKEN_SIZE, 1, 4
	)
	previewed_tokens = []


func _add_token_preview() -> void:
	var previewed_token = null
	for token in tokens:
		if not token.awarded and token not in previewed_tokens:
			previewed_token = token
	if previewed_token == null:
		return
	_previewed_token_locale.add_piece(previewed_token)
	previewed_token.toggle_preview(true)
	previewed_tokens.append(previewed_token)


func toggle_token_previews(n: int) -> void:
	var diff := n - previewed_tokens.size()
	if diff > 0:
		for _i in range(diff):
			_add_token_preview()
	elif diff < 0:
		for _i in range(-diff):
			var token = previewed_tokens.pop_back()
			token.toggle_preview(false)
			_free_token_locale.add_piece(token)


func award_tokens(scoreboard) -> float:
	var wait_time: float = 0.0
	for i in range(previewed_tokens.size()):
		var token = previewed_tokens[i]
		var delay: float = (Reg.MAX_MOVE_TIME + 0.05) * i
		GameSystem.ps.get_tree().create_timer(delay).timeout.connect(func():
			scoreboard.award(token)
		)
		wait_time += Reg.MAX_MOVE_TIME + 0.05
	if wait_time > 0:
		wait_time += Reg.MAX_MOVE_TIME
	previewed_tokens = []
	return wait_time


func out_of_tokens() -> bool:
	for token in tokens:
		if not token.awarded:
			return false
	return true


func token_count() -> int:
	var count := 0
	for token in tokens:
		if not token.awarded:
			count += 1
	return count
