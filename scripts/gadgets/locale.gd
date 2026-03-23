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


# Abstract coroutine — override in subclasses with actual animation logic.
func update_positions() -> void:
	await get_tree().process_frame


## Immediately reposition all pieces to match current world transform.
## Call this after the parent node moves or rotates.
func update_positions_immediate() -> void:
	for i in range(pieces.size()):
		if pieces[i] != null:
			pieces[i].position = get_position_for_slot(i)
			pieces[i].rotation_degrees = global_rotation_degrees


func add_piece(piece: GamePiece) -> void:
	if piece not in pieces:
		for i in range(pieces.size()):
			if pieces[i] == null:
				await insert_piece(piece, i)
				return
	else:
		await update_positions()


func insert_piece(piece: GamePiece, i: int) -> void:
	if null not in pieces:
		return

	if piece.in_locale != null:
		piece.in_locale.remove_piece(piece)
	piece.in_locale = self

	if pieces[i] == null:
		pieces[i] = piece
		if not autoupdate:
			var pos := get_position_for_slot(i)
			await piece.move_to(pos.x, pos.y)
			return
	else:
		pieces.insert(i, piece)
		# Remove one null to keep array the same size
		var null_idx := pieces.find(null)
		if null_idx != -1:
			pieces.remove_at(null_idx)

	await update_positions()


func vacate(slot: int) -> GamePiece:
	var vacated = pieces[slot]
	pieces[slot] = null
	if autoupdate:
		update_positions()  # fire-and-forget
	return vacated


func remove_piece(gamepiece: GamePiece) -> void:
	for i in range(pieces.size()):
		if pieces[i] == gamepiece:
			vacate(i)
			return


func get_slot(gamepiece: GamePiece):
	var result := pieces.find(gamepiece)
	if result == -1:
		return null
	return result
