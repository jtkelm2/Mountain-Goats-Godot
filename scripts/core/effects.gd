class_name Effects
extends Node
## Manages tween-based visual effects (transparency, movement).

# Stores active tweens per object: { sprite: { "transparing": Tween, "moving": Tween } }
var _registry: Dictionary = {}


func _register(obj: Sprite2D) -> void:
	if not _registry.has(obj):
		_registry[obj] = { "transparing": null, "moving": null }


func toggle_transparing(obj: Sprite2D, enabled: bool) -> void:
	_register(obj)
	var entry: Dictionary = _registry[obj]
	if entry.transparing is Tween:
		entry.transparing.kill()
		entry.transparing = null
	obj.modulate.a = 1.0

	if enabled:
		var tw := create_tween().set_loops()
		tw.tween_property(obj, "modulate:a", 0.5, 0.5)
		tw.tween_property(obj, "modulate:a", 1.0, 0.5)
		entry.transparing = tw


func transpare(obj: Sprite2D) -> void:
	toggle_transparing(obj, false)
	obj.modulate.a = 0.5


func detranspare(obj: Sprite2D) -> void:
	toggle_transparing(obj, false)
	obj.modulate.a = 1.0


func fade_out(obj: Sprite2D) -> void:
	_register(obj)
	toggle_transparing(obj, false)
	obj.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(obj, "modulate:a", 0.0, 1.0)
	_registry[obj].transparing = tw


func fade_in(obj: Sprite2D) -> void:
	_register(obj)
	toggle_transparing(obj, false)
	obj.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(obj, "modulate:a", 1.0, 1.0)
	_registry[obj].transparing = tw


func quad_move(piece: GamePiece, dest_x: float, dest_y: float,
		callback: Callable = Callable()) -> void:
	piece.is_moving = true
	var dest := Vector2(dest_x, dest_y)
	var dist_sq := piece.position.distance_squared_to(dest)
	var duration := clampf(dist_sq / 10000.0, 0.01, Reg.MAX_MOVE_TIME)

	var tw := create_tween()
	tw.tween_property(piece, "position", dest, duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		piece.is_moving = false
		if callback.is_valid():
			callback.call(piece)
	)


func instant_move(piece: GamePiece, dest_x: float, dest_y: float,
		callback: Callable = Callable()) -> void:
	piece.position = Vector2(dest_x, dest_y)
	if callback.is_valid():
		callback.call(piece)
