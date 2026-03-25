extends Control
## Main menu screen. Entry point of the game.


var _rules_container: Control = null


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(500, 0)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Mountain Goats"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "A dice placement game for 2–4 players"
	sub.add_theme_font_size_override("font_size", 16)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	vbox.add_child(HSeparator.new())

	# How to Play toggle button
	var rules_btn := Button.new()
	rules_btn.text = "How to Play"
	rules_btn.toggle_mode = true
	vbox.add_child(rules_btn)

	# Rules panel (hidden by default)
	_rules_container = _build_rules_panel()
	_rules_container.visible = false
	vbox.add_child(_rules_container)

	rules_btn.toggled.connect(func(pressed: bool):
		_rules_container.visible = pressed
	)

	vbox.add_child(HSeparator.new())

	# Play button
	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.add_theme_font_size_override("font_size", 24)
	play_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")
	)
	vbox.add_child(play_btn)


func _build_rules_panel() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 280)

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.text = _get_rules_text()
	scroll.add_child(rtl)

	return scroll


func _get_rules_text() -> String:
	return """[b]Goal[/b]
Score the most points by sending your goat to mountaintops and collecting tokens.

[b]On Your Turn[/b]
1. [b]Roll[/b] — Click to stop the four dice.
2. [b]Plan[/b] — Drag dice into up to four slots. Each slot's sum must equal a mountain number (5–10). Drag your goat up that many squares, or drag it to a specific square.
3. [b]Confirm[/b] — Press the confirm button to end your turn.

[b]Scoring[/b]
- Reaching the [b]mountaintop[/b] awards you a token. Each token is worth points equal to the mountain number (e.g. a token from mountain 8 = 8 pts).
- Any other goat at the top is knocked to the foot of that mountain.
- [b]Bonus tokens[/b] are awarded when you collect more tokens from every mountain than your current minimum. They add bonus points directly to your score.

[b]Wild Dice[/b]
Scroll the mouse wheel over a die showing [b]1[/b] to change it to any value (2–6). One die showing 1 stays as-is; extra 1s become wilds.

[b]Game End[/b]
When enough mountains run out of tokens, the [b]final round[/b] begins. All players finish the round, then the highest score wins."""
