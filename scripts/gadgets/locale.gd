class_name Locale
extends Node2D
## Abstract base for positioning containers. Tracks an array of GamePiece
## references and computes target positions for them.
## Extends Node2D so position/rotation are managed by the scene tree;
## subclasses compute slot positions via to_global() and override
## update_positions().

var width: float = 0.0
var height: float = 0.0

var pieces: Array[GamePiece] = []
var autoupdate: bool = true


func get_midpoint() -> Vector2:
	return to_global(Vector2(width / 2.0, height / 2.0))


# Abstract - override in subclasses
func get_position_for_slot(_slot: int) -> Vector2:
	return Vector2.ZERO


# Abstract - override in subclasses
func update_positions(_callback: Callable = Callable()) -> void:
	pass


## Immediately reposition all pieces to match current world transform.
## Call this after the parent node moves or rotates.
func update_positions_immediate() -> void:
	for i in range(pieces.size()):
		if pieces[i] != null:
			pieces[i].position = get_position_for_slot(i)
			pieces[i].rotation_degrees = global_rotation_degrees


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
