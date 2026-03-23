class_name Locale
extends RefCounted
## Abstract base for positioning containers. Tracks an array of GamePiece
## references and computes target positions for them.

var x: float = 0.0:
	set(new_x):
		if pieces != null:
			var dx := new_x - x
			for piece in pieces:
				if piece != null:
					piece.position.x += dx
		x = new_x

var y: float = 0.0:
	set(new_y):
		if pieces != null:
			var dy := new_y - y
			for piece in pieces:
				if piece != null:
					piece.position.y += dy
		y = new_y

var width: float = 0.0
var height: float = 0.0

var angle: float = 0.0:
	set(new_angle):
		if pieces != null:
			var mid := get_midpoint()
			var angle_diff := new_angle - angle
			for piece in pieces:
				if piece != null:
					var old_mid := piece.get_midpoint()
					var new_mid := old_mid
					new_mid = _pivot_degrees(new_mid, mid, angle_diff)
					piece.position.x += new_mid.x - old_mid.x
					piece.position.y += new_mid.y - old_mid.y
					piece.rotation_degrees += angle_diff
		angle = new_angle

var pieces: Array[GamePiece] = []
var autoupdate: bool = true


func get_midpoint() -> Vector2:
	return Vector2(x + width / 2.0, y + height / 2.0)


# Abstract - override in subclasses
func get_position_for_slot(slot: int) -> Vector2:
	return Vector2.ZERO


# Abstract - override in subclasses
func update_positions(callback: Callable = Callable()) -> void:
	pass


func add_piece(piece: GamePiece, callback: Callable = Callable()):
	if piece not in pieces:
		for i in range(pieces.size()):
			if pieces[i] == null:
				return insert_piece(piece, i, callback)
	else:
		var new_cb := Callable()
		if callback.is_valid():
			new_cb = func(other_piece):
				if other_piece == piece:
					callback.call(piece)
		update_positions(new_cb)
	return null


func insert_piece(piece: GamePiece, i: int, callback: Callable = Callable()):
	if null not in pieces:
		return null

	if piece.in_locale != null:
		piece.in_locale.remove_piece(piece)
	piece.in_locale = self

	var new_cb := Callable()
	if callback.is_valid():
		new_cb = func(other_piece):
			if other_piece == piece:
				callback.call(piece)

	if pieces[i] == null:
		pieces[i] = piece
		if not autoupdate:
			var pos := get_position_for_slot(i)
			piece.move_to(pos.x, pos.y, callback)
			return i
	else:
		pieces.insert(i, piece)
		# Remove one null to keep array the same size
		var null_idx := pieces.find(null)
		if null_idx != -1:
			pieces.remove_at(null_idx)

	update_positions(new_cb)
	return i


func vacate(slot: int, callback: Callable = Callable()) -> GamePiece:
	var vacated = pieces[slot]
	pieces[slot] = null
	if autoupdate:
		update_positions(callback)
	return vacated


func remove_piece(gamepiece: GamePiece, callback: Callable = Callable()):
	for i in range(pieces.size()):
		if pieces[i] == gamepiece:
			vacate(i, callback)
			return i
	return null


func get_slot(gamepiece: GamePiece):
	var result := pieces.find(gamepiece)
	if result == -1:
		return null
	return result


static func _pivot_degrees(point: Vector2, pivot: Vector2, degrees: float) -> Vector2:
	var radians := deg_to_rad(degrees)
	var rel := point - pivot
	var cos_a := cos(radians)
	var sin_a := sin(radians)
	return Vector2(
		pivot.x + rel.x * cos_a - rel.y * sin_a,
		pivot.y + rel.x * sin_a + rel.y * cos_a
	)
