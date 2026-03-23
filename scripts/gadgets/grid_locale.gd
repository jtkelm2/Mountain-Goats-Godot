class_name GridLocale
extends Locale
## Positions pieces in a grid layout.

var grid_cols: int
var grid_rows: int
var starting_corner: int  # 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right


func _init(lx: float, ly: float, lw: float, lh: float,
		g_rows: int, g_cols: int, auto: bool = true, corner: int = 0) -> void:
	x = lx
	y = ly
	width = lw
	height = lh
	grid_cols = g_cols
	grid_rows = g_rows
	starting_corner = corner
	autoupdate = auto
	pieces = []
	for _i in range(g_cols * g_rows):
		pieces.append(null)


func get_position_for_slot(slot: int) -> Vector2:
	var col_dir := 1 if starting_corner % 2 == 0 else -1
	var row_dir := 1 if starting_corner < 2 else -1
	@warning_ignore("integer_division")
	var col: int = col_dir * (slot % grid_cols)
	@warning_ignore("integer_division")
	var row: int = row_dir * (slot / grid_cols)
	return Vector2(
		x + (float(col) / grid_cols) * width,
		y + (float(row) / grid_rows) * height
	)


func update_positions(callback: Callable = Callable()) -> void:
	if autoupdate:
		pieces = pieces.filter(func(p): return p != null)
		while pieces.size() < grid_cols * grid_rows:
			pieces.append(null)

	for i in range(pieces.size()):
		if pieces[i] != null:
			var new_pos := get_position_for_slot(i)
			pieces[i].move_to(new_pos.x, new_pos.y, callback)
