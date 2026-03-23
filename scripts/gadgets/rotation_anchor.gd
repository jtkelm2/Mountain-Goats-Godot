class_name RotationAnchor
extends RefCounted
## Anchors a group of objects for coordinated rotation and translation.
## Works with both Node2D (Sprite2D etc.) and Locale objects via duck typing.

var anchored_objects: Array = []

var anchor_x: float = 0.0:
	set(new_x):
		if anchor_x != 0.0 or new_x != 0.0:
			var dx := new_x - anchor_x
			for obj in anchored_objects:
				_translate_obj(obj, dx, 0)
		anchor_x = new_x

var anchor_y: float = 0.0:
	set(new_y):
		if anchor_y != 0.0 or new_y != 0.0:
			var dy := new_y - anchor_y
			for obj in anchored_objects:
				_translate_obj(obj, 0, dy)
		anchor_y = new_y

var anchor_angle: float = 0.0:
	set(new_angle):
		var angle_diff := new_angle - anchor_angle
		var pivot := Vector2(anchor_x, anchor_y)
		for obj in anchored_objects:
			_rotate_obj(obj, pivot, angle_diff)
		anchor_angle = new_angle


func _init(ax: float = 0.0, ay: float = 0.0) -> void:
	anchor_x = ax
	anchor_y = ay
	anchor_angle = 0.0


func add_obj(obj) -> void:
	anchored_objects.append(obj)


func _translate_obj(obj, dx: float, dy: float) -> void:
	if obj is Node2D:
		obj.position.x += dx
		obj.position.y += dy
	elif obj is Locale:
		obj.x += dx
		obj.y += dy


func _get_midpoint(obj) -> Vector2:
	if obj is Node2D:
		if obj.has_method("get_midpoint"):
			return obj.get_midpoint()
		# Fallback: assume origin at center
		return Vector2(
			obj.position.x + obj.texture.get_width() / 2.0 if obj.texture else obj.position.x,
			obj.position.y + obj.texture.get_height() / 2.0 if obj.texture else obj.position.y
		)
	elif obj is Locale:
		return obj.get_midpoint()
	return Vector2.ZERO


func _rotate_obj(obj, pivot: Vector2, angle_diff: float) -> void:
	var old_mid := _get_midpoint(obj)
	var new_mid := Locale._pivot_degrees(old_mid, pivot, angle_diff)
	var delta := new_mid - old_mid

	if obj is Node2D:
		obj.position.x += delta.x
		obj.position.y += delta.y
		obj.rotation_degrees += angle_diff
	elif obj is Locale:
		obj.x += delta.x
		obj.y += delta.y
		obj.angle += angle_diff
