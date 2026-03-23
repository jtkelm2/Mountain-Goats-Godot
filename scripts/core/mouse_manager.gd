class_name MouseManager
extends Node
## Registers sprites for mouse interaction via Area2D children and
## routes events through the event queue.

var hovered = null  # Currently hovered sprite

# tag -> Array[{sprite, area}]
var _clickable_registry: Dictionary = {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			GameSystem.events.handle(GameEvent.mouse_clicked())


## Register a sprite for mouse interaction.
func init_clickable(sprite: Sprite2D, tag: String) -> void:
	var area := Area2D.new()
	area.input_pickable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()

	var frame_w: float = 32
	var frame_h: float = 32
	if sprite.texture:
		frame_w = sprite.texture.get_width() / maxf(sprite.hframes, 1)
		frame_h = sprite.texture.get_height() / maxf(sprite.vframes, 1)

	rect.size = Vector2(frame_w, frame_h)
	shape.shape = rect
	shape.position = Vector2(frame_w / 2.0, frame_h / 2.0)
	area.add_child(shape)
	sprite.add_child(area)

	# Connect signals
	area.input_event.connect(func(_vp, ev, _idx):
		_on_area_input(sprite, ev)
	)
	area.mouse_entered.connect(func():
		hovered = sprite
		GameSystem.events.handle(GameEvent.mouse_over(sprite))
	)
	area.mouse_exited.connect(func():
		if hovered == sprite:
			hovered = null
		GameSystem.events.handle(GameEvent.mouse_out(sprite))
	)

	if not _clickable_registry.has(tag):
		_clickable_registry[tag] = []
	_clickable_registry[tag].append({"sprite": sprite, "area": area})


func _on_area_input(sprite: Sprite2D, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				GameSystem.events.handle(GameEvent.mouse_down(sprite))
			else:
				GameSystem.events.handle(GameEvent.mouse_up(sprite))
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			GameSystem.events.handle(GameEvent.mouse_wheel(sprite, 1))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			GameSystem.events.handle(GameEvent.mouse_wheel(sprite, -1))


## Enable input only for sprites with the given tags.
func set_active(active_tags: Array) -> void:
	for tag in _clickable_registry:
		var enabled: bool = tag in active_tags
		_clickable_toggle(tag, enabled)


func _clickable_toggle(tag: String, enabled: bool) -> void:
	if _clickable_registry.has(tag):
		for entry in _clickable_registry[tag]:
			(entry.area as Area2D).input_pickable = enabled
