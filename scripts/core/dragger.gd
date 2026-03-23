class_name Dragger
extends Node
## Handles drag-and-drop of game objects.

var _dragged_obj = null  # Currently dragged Sprite2D
var _prev_mouse: Vector2 = Vector2.ZERO
var _prev_z_index: int = 0

var dragged:
	get:
		return _dragged_obj
	set(new_val):
		var old_val = _dragged_obj
		_dragged_obj = new_val
		if new_val != null:
			var mouse_pos := get_viewport().get_mouse_position()
			new_val.position.x += mouse_pos.x - (new_val.position.x + new_val.origin.x)
			new_val.position.y += mouse_pos.y - (new_val.position.y + new_val.origin.y)
			_prev_z_index = (new_val as GamePiece).z_index
			(new_val as GamePiece).z_index = Reg.Z_DRAGGED
			(new_val as GamePiece).transpare()
		elif old_val != null:
			(old_val as GamePiece).z_index = _prev_z_index
			(old_val as GamePiece).detranspare()
			GameSystem.events.handle(GameEvent.dragger_dropped(old_val))


func _process(_delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	if _dragged_obj != null:
		_dragged_obj.position += mouse_pos - _prev_mouse
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			self.dragged = null
	_prev_mouse = mouse_pos
