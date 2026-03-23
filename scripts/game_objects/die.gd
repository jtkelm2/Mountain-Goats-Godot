class_name Die
extends GamePiece
## A single die that can be rolled, made wild, and placed in dice box slots.

var value: int = 1
var slot: int = 0
var is_wild: bool = false
var currently_rolling: bool = false
var _roll_timer: float = 0.0


func setup() -> void:
	load_spritesheet("res://assets/die.png", Reg.DIE_SIZE, Reg.DIE_SIZE)
	roll()
	currently_rolling = false
	teleport_mode = true
	is_moving = false
	z_index = Reg.Z_DIE
	GameSystem.mouse_mgr.init_clickable(self, Reg.TAG_DIE)


func _process(delta: float) -> void:
	if currently_rolling:
		_roll_timer -= delta
		if _roll_timer < 0:
			roll(true)
			_roll_timer += 0.2


func get_tag() -> String:
	return Reg.TAG_DIE


func roll(fake_roll: bool = false) -> int:
	var new_value := randi_range(1, 6)
	if fake_roll and new_value == value:
		new_value = new_value % 6 + 1
	value = new_value
	frame = value - 1
	is_wild = (value == 1)
	return value


func start_rolling() -> void:
	_roll_timer = 0.2
	currently_rolling = true


func stop_rolling(dice_box, target_slot: int) -> void:
	var cur_y := position.y
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.8, 1.8), 0.3)
	tw.parallel().tween_property(self, "position:y", cur_y - Reg.DIE_SIZE * 2, 0.3)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(self, "position:y", cur_y, 0.5) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	await tw.finished
	currently_rolling = false
	await get_tree().create_timer(1.5).timeout
	await dice_box.to_slot(target_slot, self)


func change_wild(delta: int, dice_box) -> bool:
	if is_wild and (value == 1 and dice_box.one_count > 1 or value != 1):
		value += delta
		if value < 1:
			value = 6
		elif value > 6:
			value = 1
		# Frame 0-5 = normal faces, 6-11 = wild faces
		frame = value - 1 if value == 1 else value + 5
		dice_box.update_slot_values()
		return true
	return false


func toggle_reserve(enabled: bool) -> void:
	toggle_transparing(enabled)
