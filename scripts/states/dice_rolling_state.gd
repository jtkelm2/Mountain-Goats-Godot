class_name DiceRollingState
extends GameState
## DiceRolling gamestate: animates dice rolling and waits for click to stop.

var pause_input: bool = true
var rolling_locale: GridLocale = null
var dice_roller: Sprite2D = null


func _init(play_state: PlayState) -> void:
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


func refresh() -> GameState:
	GameSystem.mouse_mgr.set_active([])
	pause_input = true
	_tray_in()
	_start_rolling_after_delay()
	return self


func handle(event: GameEvent) -> void:
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
	var t := 0
	for die in ps.dice_box.dice:
		die.start_rolling()
		var callback := Callable()
		if t == 3:
			callback = func(_p):
				pause_input = false
				GameSystem.prompt_ai(self)
		var local_t := t
		var local_die: Die = die
		var local_cb := callback
		get_tree().create_timer(local_t * Reg.MAX_MOVE_TIME * 0.5).timeout.connect(func():
			rolling_locale.add_piece(local_die, local_cb)
		)
		t += 1


func _stop_rolling() -> void:
	var t := 0
	for die in ps.dice_box.dice:
		var callback := Callable()
		if t == 3:
			callback = func(_p):
				GameSystem.events.handle(
					GameEvent.switch_state(GameSystem.events.planning_state)
				)
		var local_t := t
		var local_die: Die = die
		var local_cb := callback
		get_tree().create_timer(local_t / 5.0).timeout.connect(func():
			local_die.stop_rolling(ps.dice_box, local_t, local_cb)
		)
		t += 1
	_tray_out_after_delay()


func _tray_in() -> void:
	var vp_w: float = ps.get_viewport().get_visible_rect().size.x
	var tw: Tween = create_tween()
	tw.tween_property(dice_roller, "position:x",
		vp_w / 2.0 - 3 * Reg.DIE_SIZE - Reg.SPACING, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _tray_out_after_delay() -> void:
	await get_tree().create_timer(3.0).timeout
	_tray_out()


func _tray_out() -> void:
	var vp_w: float = ps.get_viewport().get_visible_rect().size.x
	var tw: Tween = create_tween()
	tw.tween_property(dice_roller, "position:x", 2.0 * vp_w, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	dice_roller.position.x = -vp_w
