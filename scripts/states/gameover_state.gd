class_name GameoverState
extends "res://scripts/core/game_state.gd"
## Gameover gamestate: shows final scores and navigation options.


func _init(play_state) -> void:
	ps = play_state
	gamestate_tag = Reg.GS_GAMEOVER


func refresh():
	GameSystem.mouse_mgr.set_active([])
	_show_gameover_overlay()
	return self


func handle(_event) -> void:
	pass


func _show_gameover_overlay() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	ps.add_child(overlay)

	var vp_size: Vector2 = ps.get_viewport().get_visible_rect().size

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = vp_size
	overlay.add_child(dim)

	# Build sorted player data
	var player_scores := []
	for p in range(GameConfig.player_count):
		player_scores.append({
			"player": p,
			"score": int(ps.scoreboards[p].score_label.text),
			"is_human": GameConfig.player_types[p] == 0,
		})
	player_scores.sort_custom(func(a, b): return a.score > b.score)

	var top_score: int = player_scores[0].score
	var winners := player_scores.filter(func(e): return e.score == top_score)

	# Panel container centered in viewport
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	_add_label(vbox, "Game Over!", 30, true)

	# Separator
	vbox.add_child(HSeparator.new())

	# Winner line
	var winner_text: String
	if winners.size() == 1:
		winner_text = "Winner: Player %d!" % (winners[0].player + 1)
	else:
		var nums := PackedStringArray()
		for w in winners:
			nums.append(str(w.player + 1))
		winner_text = "Tie: Players %s!" % ", ".join(nums)
	_add_label(vbox, winner_text, 20, true)

	vbox.add_child(HSeparator.new())

	# Ranked player list
	for i in range(player_scores.size()):
		var entry: Dictionary = player_scores[i]
		var p_type: int = GameConfig.player_types[entry.player]
		var type_str := "Human" if p_type == GameSystem.PlayerType.HUMAN \
			else ("Online" if p_type == GameSystem.PlayerType.REMOTE else "AI")
		var row_text := "%d. Player %d (%s) — %d pts" % [
			i + 1, entry.player + 1, type_str, entry.score
		]
		_add_label(vbox, row_text, 16, false)

	vbox.add_child(HSeparator.new())

	# Buttons
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var play_again_btn := Button.new()
	play_again_btn.text = "Play Again"
	play_again_btn.pressed.connect(func():
		ps.get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	hbox.add_child(play_again_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.pressed.connect(func():
		ps.get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	hbox.add_child(menu_btn)

	# Center the panel after layout (deferred so minimum size is computed)
	panel.set_deferred(&"position",
		Vector2((vp_size.x - 380.0) / 2.0, (vp_size.y - 260.0) / 2.0)
	)


func _add_label(parent: Node, text: String, font_size: int, centered: bool) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)
