extends Control
## Lobby screen: configure players, AI difficulty, and rules variations.


const PLAYER_OPTIONS := ["Human", "Easy AI", "Medium AI", "Hard AI"]
const MAX_PLAYERS := 4
const MIN_PLAYERS := 2

var _player_count_spin: SpinBox = null
var _player_rows: Array = []       # Array of VBoxContainer (one per player slot)
var _player_options: Array = []    # Array of OptionButton (one per player slot)
var _adv_rules_body: Control = null

# Advanced rules widgets
var _tokens_spins: Dictionary = {}  # mountain -> SpinBox
var _mountains_end_spin: SpinBox = null
var _bonus_spins: Array = []


func _ready() -> void:
	_build_ui()
	_refresh_player_rows()


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
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(520, 0)
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Game Setup"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_build_player_section(vbox)

	vbox.add_child(HSeparator.new())

	_build_advanced_section(vbox)

	vbox.add_child(HSeparator.new())

	_build_nav_buttons(vbox)


func _build_player_section(parent: Control) -> void:
	# Header row: "Number of Players" label + spinbox
	var header := HBoxContainer.new()
	parent.add_child(header)

	var count_label := Label.new()
	count_label.text = "Number of Players:"
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(count_label)

	_player_count_spin = SpinBox.new()
	_player_count_spin.min_value = MIN_PLAYERS
	_player_count_spin.max_value = MAX_PLAYERS
	_player_count_spin.step = 1
	_player_count_spin.value = GameConfig.player_count
	header.add_child(_player_count_spin)

	_player_count_spin.value_changed.connect(func(_v): _refresh_player_rows())

	# Player rows
	for i in range(MAX_PLAYERS):
		var row := _build_player_row(i)
		parent.add_child(row)
		_player_rows.append(row)


func _build_player_row(i: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl := Label.new()
	lbl.text = "Player %d:" % (i + 1)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl)

	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in PLAYER_OPTIONS:
		opt.add_item(option)

	# Set default: player 0 = Human, others = Hard AI
	if i == 0:
		opt.selected = 0  # Human
	else:
		opt.selected = 3  # Hard AI

	# Restore from current GameConfig
	var current_type: int = GameConfig.player_types[i]
	if current_type == 0:
		opt.selected = 0  # Human
	else:
		var diff: int = GameConfig.ai_difficulties[i]
		opt.selected = clamp(diff + 1, 1, 3)

	row.add_child(opt)
	_player_options.append(opt)

	return row


func _refresh_player_rows() -> void:
	var count := int(_player_count_spin.value)
	for i in range(MAX_PLAYERS):
		var active := i < count
		_player_rows[i].modulate.a = 1.0 if active else 0.4
		_player_rows[i].mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE


func _build_advanced_section(parent: Control) -> void:
	var toggle_btn := Button.new()
	toggle_btn.text = "Advanced Rules"
	toggle_btn.toggle_mode = true
	parent.add_child(toggle_btn)

	_adv_rules_body = VBoxContainer.new()
	_adv_rules_body.add_theme_constant_override("separation", 10)
	_adv_rules_body.visible = false
	parent.add_child(_adv_rules_body)

	toggle_btn.toggled.connect(func(pressed: bool):
		_adv_rules_body.visible = pressed
	)

	# Tokens per mountain
	var tok_label := Label.new()
	tok_label.text = "Tokens per mountain (5–10):"
	tok_label.add_theme_font_size_override("font_size", 16)
	_adv_rules_body.add_child(tok_label)

	var tok_grid := GridContainer.new()
	tok_grid.columns = 6
	_adv_rules_body.add_child(tok_grid)

	for mountain in range(5, 11):
		var col := VBoxContainer.new()
		tok_grid.add_child(col)

		var m_lbl := Label.new()
		m_lbl.text = "M%d" % mountain
		m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(m_lbl)

		var spin := SpinBox.new()
		spin.min_value = 1
		spin.max_value = 20
		spin.step = 1
		spin.value = GameConfig.tokens_per_mountain[mountain]
		spin.custom_minimum_size = Vector2(70, 0)
		col.add_child(spin)
		_tokens_spins[mountain] = spin

	# Mountains to end game
	var end_row := HBoxContainer.new()
	_adv_rules_body.add_child(end_row)

	var end_lbl := Label.new()
	end_lbl.text = "Mountains exhausted to trigger final round:"
	end_lbl.add_theme_font_size_override("font_size", 16)
	end_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_row.add_child(end_lbl)

	_mountains_end_spin = SpinBox.new()
	_mountains_end_spin.min_value = 1
	_mountains_end_spin.max_value = 6
	_mountains_end_spin.step = 1
	_mountains_end_spin.value = GameConfig.mountains_to_end_game
	end_row.add_child(_mountains_end_spin)

	# Bonus token values
	var bonus_label := Label.new()
	bonus_label.text = "Bonus token values (lowest to highest):"
	bonus_label.add_theme_font_size_override("font_size", 16)
	_adv_rules_body.add_child(bonus_label)

	var bonus_row := HBoxContainer.new()
	bonus_row.add_theme_constant_override("separation", 10)
	_adv_rules_body.add_child(bonus_row)

	for k in range(4):
		var spin := SpinBox.new()
		spin.min_value = 1
		spin.max_value = 99
		spin.step = 1
		var default_val: int = GameConfig.bonus_token_values[k] if k < GameConfig.bonus_token_values.size() else (k + 1) * 3 + 3
		spin.value = default_val
		spin.custom_minimum_size = Vector2(70, 0)
		bonus_row.add_child(spin)
		_bonus_spins.append(spin)


func _build_nav_buttons(parent: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	parent.add_child(hbox)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	)
	hbox.add_child(back_btn)

	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(_on_start_game)
	hbox.add_child(start_btn)


func _on_start_game() -> void:
	var count := int(_player_count_spin.value)
	GameConfig.player_count = count

	for i in range(MAX_PLAYERS):
		var sel: int = _player_options[i].selected
		if sel == 0:
			GameConfig.player_types[i] = 0  # HUMAN
			GameConfig.ai_difficulties[i] = -1
		else:
			GameConfig.player_types[i] = 1  # AI
			GameConfig.ai_difficulties[i] = sel - 1  # 0=Easy, 1=Med, 2=Hard

	for mountain in range(5, 11):
		GameConfig.tokens_per_mountain[mountain] = int(_tokens_spins[mountain].value)

	GameConfig.mountains_to_end_game = int(_mountains_end_spin.value)

	GameConfig.bonus_token_values = []
	for spin in _bonus_spins:
		GameConfig.bonus_token_values.append(int(spin.value))

	get_tree().change_scene_to_file("res://scenes/main.tscn")
