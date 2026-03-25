class_name GridLocale
extends Locale
## Positions pieces in a grid layout.
## position is LOCAL to the parent node (world position when parent has no
## transform, e.g. PlayState). get_position_for_slot() converts to world coords
## via to_global(), so all callers receive world-space positions regardless of
## where this node sits in the hierarchy.

var grid_cols: int
var grid_rows: int
var starting_corner: int  # 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right


func _init(lx: float, ly: float, lw: float, lh: float,
		g_rows: int, g_cols: int, auto: bool = true, corner: int = 0) -> void:
	position = Vector2(lx, ly)
	width = lw
	height = lh
	grid_cols = g_cols
	grid_rows = g_rows
	starting_corner = corner
	autoupdate = auto
	pieces.clear()
	pieces.resize(g_cols * g_rows)


func get_position_for_slot(slot: int) -> Vector2:
	var col_dir := 1 if starting_corner % 2 == 0 else -1
	var row_dir := 1 if starting_corner < 2 else -1
	@warning_ignore("integer_division")
	var col: int = col_dir * (slot % grid_cols)
	@warning_ignore("integer_division")
	var row: int = row_dir * (slot / grid_cols)
	var local_pos := Vector2(
		(float(col) / grid_cols) * width,
		(float(row) / grid_rows) * height
	)
	return to_global(local_pos)


func update_positions() -> void:
	if autoupdate:
		pieces = pieces.filter(func(p): return p != null)
		while pieces.size() < grid_cols * grid_rows:
			pieces.append(null)

	var moving := []
	for i in range(pieces.size()):
		if pieces[i] != null:
			var new_pos := get_position_for_slot(i)
			moving.append(pieces[i])
			pieces[i].move_to(new_pos.x, new_pos.y)

	if moving.is_empty() or not is_inside_tree():
		return
	while moving.any(func(p): return p.is_moving):
		await get_tree().process_frame
