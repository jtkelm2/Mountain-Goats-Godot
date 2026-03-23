class_name QueryRegion
extends RefCounted
## Defines rectangular regions for mouse position queries.

var regions: Array[Rect2] = []


func add_region(rx: float, ry: float, rw: float, rh: float) -> QueryRegion:
	regions.append(Rect2(rx, ry, rw, rh))
	return self


func add_region_grid(rx: float, ry: float, rw: float, rh: float,
		grid_rows: int, grid_cols: int) -> QueryRegion:
	var region_w := rw / grid_cols
	var region_h := rh / grid_rows
	for row in range(grid_rows):
		for col in range(grid_cols):
			add_region(
				rx + col * region_w,
				ry + row * region_h,
				region_w, region_h
			)
	return self


func query(qx: float = NAN, qy: float = NAN):
	var mx: float
	var my: float
	if is_nan(qx):
		var tree := Engine.get_main_loop() as SceneTree
		var mouse_pos := tree.root.get_viewport().get_mouse_position()
		mx = mouse_pos.x
		my = mouse_pos.y
	else:
		mx = qx
		my = qy

	for i in range(regions.size()):
		if regions[i].has_point(Vector2(mx, my)):
			return i
	return null
