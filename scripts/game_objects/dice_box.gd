class_name DiceBox
extends Sprite2D
## The dice box with four slots. Manages die placement and validates moves.

var locales: Array[GridLocale] = []
var query_region: QueryRegion = null
var dice: Array[Die] = []
var slot_counts: Array[int] = [0, 0, 0, 0]
var one_count: int = 0
var origin: Vector2 = Vector2.ZERO


func _init() -> void:
	pass


func setup(bx: float, by: float, main_scene: Node) -> void:
	position = Vector2(bx, by)
	centered = false
	texture = load("res://assets/dicebox.png")
	origin = Vector2(texture.get_width() / 2.0, texture.get_height() / 2.0)

	query_region = QueryRegion.new().add_region_grid(
		bx + Reg.SPACING, by + Reg.SPACING,
		4 * Reg.DIE_SIZE, 4 * Reg.DIE_SIZE,
		1, 4
	)

	locales = []
	dice = []
	for i in range(4):
		var loc := GridLocale.new(
			bx + i * Reg.DIE_SIZE + Reg.SPACING,
			by + Reg.SPACING,
			Reg.DIE_SIZE, 4.0 * Reg.DIE_SIZE,
			4, 1
		)
		locales.append(loc)
		var die := _init_die(i, main_scene)
		dice.append(die)

	GameSystem.mouse_mgr.init_clickable(self, Reg.TAG_DICE_BOX)


func _init_die(slot: int, main_scene: Node) -> Die:
	var die := Die.new()
	main_scene.add_child(die)
	die.setup()
	to_slot(slot, die)
	die.teleport_mode = false
	return die


func get_midpoint() -> Vector2:
	return Vector2(position.x + origin.x, position.y + origin.y)


func to_slot(slot: int, die: Die, callback: Callable = Callable()) -> void:
	locales[slot].add_piece(die, callback)
	die.slot = slot
	update_slot_values()


func update_slot_values() -> void:
	slot_counts = [0, 0, 0, 0]
	one_count = 0
	for die in dice:
		slot_counts[die.slot] += die.value
		if die.value == 1:
			one_count += 1


func judge_movements(movements: Dictionary) -> Dictionary:
	for die in dice:
		die.toggle_reserve(false)

	var output: Dictionary = {}
	var dice_by_slot: Array = [[], [], [], []]
	for die in dice:
		dice_by_slot[die.slot].append(die)

	for mountain in range(5, 11):
		if movements[mountain] == 0:
			output[mountain] = true
			continue
		var is_valid := false
		var reserved: Array[int] = []
		for slot in range(4):
			if slot_counts[slot] == mountain:
				reserved.append(slot)
			if reserved.size() == movements[mountain]:
				is_valid = true
				break
		output[mountain] = is_valid
		if is_valid:
			for slot in reserved:
				for die in dice_by_slot[slot]:
					die.toggle_reserve(true)

	return output


func unreserve_all() -> void:
	for die in dice:
		die.toggle_reserve(false)
