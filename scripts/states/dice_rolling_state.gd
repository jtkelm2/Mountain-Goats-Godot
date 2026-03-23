class_name DiceRollingState
extends "res://scripts/core/game_state.gd"
## DiceRolling gamestate: animates dice rolling and waits for click to stop.

var pause_input: bool = true
var rolling_locale: GridLocale = null
var dice_roller: Sprite2D = null

signal _all_settled
var _pending: int = 0


func _init(play_state) -> void:
	ps = play_state
	gamestate_tag = Reg.GS_DICE_ROLLING
	var vp_w: float = ps.get_viewport().get_visible_rect().size.x
	var vp_h: float = ps.get_viewport().get_visible_rect().size.y

	rolling_locale = GridLocale.new(
		vp_w / 2.0 - 3 * Reg.DIE_SIZE,
		vp_h / 2.0 - Reg.DIE_SIZE,
		8.0 * Reg.DIE_SIZE, 2.0 * Reg.DIE_SIZE,
		1, 4, false
	)
	ps.add_child(rolling_locale)
	dice_roller = ps.dice_roller_sprite
	dice_roller.position.x = -vp_w
	dice_roller.position.y = vp_h / 2.0 - Reg.DIE_SIZE - Reg.SPACING


func refresh():
	GameSystem.mouse_mgr.set_active([])
	pause_input = true
	_tray_in()
	_start_rolling_after_delay()
	return self


func handle(event) -> void:
	match event.type:
		GameEvent.Type.MOUSE_CLICKED:
			if not pause_input:
				_stop_rolling()
				pause_input = true
		GameEvent.Type.SWITCH_STATE:
			GameSystem.events.switch_state(event.gamestate_ref, true)


func _start_rolling_after_delay() -> void:
	await get_tree().create_timer(1.0).timeout
	_start_rolling()


func _start_rolling() -> void:
	for die in ps.dice_box.dice:
		die.start_rolling()

	# Stagger each die into the rolling locale in parallel.
	# _add_die_after_delay decrements _pending and emits _all_settled when done.
	_pending = ps.dice_box.dice.size()
	for t in range(ps.dice_box.dice.size()):
		_add_die_after_delay(ps.dice_box.dice[t], t)
	await _all_settled

	pause_input = false
	GameSystem.prompt_ai(self)


func _add_die_after_delay(die: Die, t: int) -> void:
	await get_tree().create_timer(t * Reg.MAX_MOVE_TIME * 0.5).timeout
	await rolling_locale.add_piece(die)
	_pending -= 1
	if _pending == 0:
		_all_settled.emit()


func _stop_rolling() -> void:
	# Stagger each die's stop animation in parallel, then switch state.
	_pending = ps.dice_box.dice.size()
	for t in range(ps.dice_box.dice.size()):
		_stop_die_after_delay(ps.dice_box.dice[t], t)
	await _all_settled

	GameSystem.events.handle(
		GameEvent.switch_state(GameSystem.events.planning_state)
	)
	_tray_out()


func _stop_die_after_delay(die: Die, slot: int) -> void:
	await get_tree().create_timer(slot / 5.0).timeout
	await die.stop_rolling(ps.dice_box, slot)
	_pending -= 1
	if _pending == 0:
		_all_settled.emit()


func _tray_in() -> void:
	var vp_w: float = ps.get_viewport().get_visible_rect().size.x
	var tw: Tween = create_tween()
	tw.tween_property(dice_roller, "position:x",
		vp_w / 2.0 - 3 * Reg.DIE_SIZE - Reg.SPACING, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _tray_out() -> void:
	var vp_w: float = ps.get_viewport().get_visible_rect().size.x
	var tw: Tween = create_tween()
	tw.tween_property(dice_roller, "position:x", 2.0 * vp_w, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	dice_roller.position.x = -vp_w
