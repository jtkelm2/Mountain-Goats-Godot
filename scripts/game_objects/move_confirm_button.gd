class_name MoveConfirmButton
extends Sprite2D
## The button players click to confirm their moves.

var origin: Vector2 = Vector2.ZERO
var _callback: Callable = Callable()


func _init() -> void:
	pass


func setup(bx: float, by: float, cb: Callable) -> void:
	position = Vector2(bx, by)
	centered = false
	texture = load("res://assets/moveconfirm.png")
	hframes = maxi(1, int(float(texture.get_width()) / Reg.MOVE_CONFIRM_WIDTH))
	vframes = maxi(1, int(float(texture.get_height()) / Reg.MOVE_CONFIRM_HEIGHT))
	origin = Vector2(Reg.MOVE_CONFIRM_WIDTH / 2.0, Reg.MOVE_CONFIRM_HEIGHT / 2.0)
	_callback = cb
	modulate.a = 0.0

	# Use Area2D for click detection
	var area := Area2D.new()
	area.input_pickable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(Reg.MOVE_CONFIRM_WIDTH, Reg.MOVE_CONFIRM_HEIGHT)
	shape.shape = rect
	shape.position = Vector2(Reg.MOVE_CONFIRM_WIDTH / 2.0, Reg.MOVE_CONFIRM_HEIGHT / 2.0)
	area.add_child(shape)
	add_child(area)

	area.input_event.connect(func(_vp, ev, _idx):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if modulate.a > 0.1 and _callback.is_valid():
				_callback.call()
	)


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)
