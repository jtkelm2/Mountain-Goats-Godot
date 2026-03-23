class_name GamePiece
extends Sprite2D
## Base class for movable game pieces (Die, Goat, Token).
## Equivalent to the Haxe Gamepiece interface.

var in_locale: Locale = null
var is_moving: bool = false
var teleport_mode: bool = true
var origin: Vector2 = Vector2.ZERO  # Rotation/drag center offset


func load_spritesheet(path: String, frame_width: int, frame_height: int = 0) -> void:
	texture = load(path)
	centered = false
	if frame_height == 0:
		frame_height = frame_width
	hframes = maxi(1, int(texture.get_width() / frame_width))
	vframes = maxi(1, int(texture.get_height() / frame_height))
	origin = Vector2(frame_width / 2.0, frame_height / 2.0)


func load_static(path: String) -> void:
	texture = load(path)
	centered = false
	origin = Vector2(texture.get_width() / 2.0, texture.get_height() / 2.0)


func move_to(dest_x: float, dest_y: float, callback: Callable = Callable()) -> void:
	if teleport_mode:
		GameSystem.effects.instant_move(self, dest_x, dest_y, callback)
	else:
		GameSystem.effects.quad_move(self, dest_x, dest_y, callback)


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)


func get_tag() -> String:
	return ""  # Override in subclasses
