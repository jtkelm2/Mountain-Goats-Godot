class_name GamePiece
extends Sprite2D
## Base class for movable game pieces (Die, Goat, Token).
## Equivalent to the Haxe Gamepiece interface.

var in_locale: Locale = null
var is_moving: bool = false
var teleport_mode: bool = true
var origin: Vector2 = Vector2.ZERO  # Rotation/drag center offset

var _transparing_tween: Tween = null

signal moved


func load_spritesheet(path: String, frame_width: int, frame_height: int = 0) -> void:
	texture = load(path)
	centered = false
	if frame_height == 0:
		frame_height = frame_width
	hframes = maxi(1, int(float(texture.get_width()) / frame_width))
	vframes = maxi(1, int(float(texture.get_height()) / frame_height))
	origin = Vector2(frame_width / 2.0, frame_height / 2.0)


func load_static(path: String) -> void:
	texture = load(path)
	centered = false
	origin = Vector2(texture.get_width() / 2.0, texture.get_height() / 2.0)


func move_to(dest_x: float, dest_y: float) -> void:
	var dest := Vector2(dest_x, dest_y)
	if teleport_mode:
		position = dest
		await get_tree().process_frame
		moved.emit()
		return
	is_moving = true
	var dist_sq := position.distance_squared_to(dest)
	var duration := clampf(dist_sq / 10000.0, 0.01, Reg.MAX_MOVE_TIME)
	var tw := create_tween()
	tw.tween_property(self, "position", dest, duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	is_moving = false
	moved.emit()


func toggle_transparing(enabled: bool) -> void:
	if _transparing_tween is Tween:
		_transparing_tween.kill()
		_transparing_tween = null
	modulate.a = 1.0
	if enabled:
		_transparing_tween = create_tween().set_loops()
		_transparing_tween.tween_property(self, "modulate:a", 0.5, 0.5)
		_transparing_tween.tween_property(self, "modulate:a", 1.0, 0.5)


func transpare() -> void:
	toggle_transparing(false)
	modulate.a = 0.5


func detranspare() -> void:
	toggle_transparing(false)
	modulate.a = 1.0


func fade_out() -> void:
	toggle_transparing(false)
	modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)


func fade_in() -> void:
	toggle_transparing(false)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)


func get_tag() -> String:
	return ""  # Override in subclasses
