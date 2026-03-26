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

# Online multiplayer UI
var _online_section: Control = null
var _online_status_label: Label = null
var _room_code_label: Label = null
var _join_code_input: LineEdit = null
var _online_start_btn: Button = null
var _is_hosting: bool = false
var _matchmaker = null  # OnlineMatchmaker


func _ready() -> void:
	_build_ui()
	_refresh_player_rows()
	_matchmaker = load("res://scripts/net/online_matchmaker.gd").new()
	add_child(_matchmaker)
	_matchmaker.room_created.connect(_on_room_created)
	_matchmaker.opponent_connected.connect(_on_opponent_connected)
	_matchmaker.opponent_ready_to_start.connect(_on_opponent_ready_to_start)


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

	_build_online_section(parent)


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

	GameConfig.online_mode = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# --- Online multiplayer section ---

func _build_online_section(parent: Control) -> void:
	parent.add_child(HSeparator.new())

	var header := Label.new()
	header.text = "Play Online"
	header.add_theme_font_size_override("font_size", 22)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(header)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	parent.add_child(btn_row)

	var host_btn := Button.new()
	host_btn.text = "Host Game"
	host_btn.pressed.connect(_on_host_pressed)
	btn_row.add_child(host_btn)

	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	join_row.add_theme_constant_override("separation", 8)
	btn_row.add_child(join_row)

	_join_code_input = LineEdit.new()
	_join_code_input.placeholder_text = "GOAT-0000"
	_join_code_input.custom_minimum_size = Vector2(130, 0)
	join_row.add_child(_join_code_input)

	var join_btn := Button.new()
	join_btn.text = "Join Game"
	join_btn.pressed.connect(_on_join_pressed)
	join_row.add_child(join_btn)

	_online_section = VBoxContainer.new()
	_online_section.add_theme_constant_override("separation", 8)
	_online_section.visible = false
	parent.add_child(_online_section)

	_room_code_label = Label.new()
	_room_code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_code_label.add_theme_font_size_override("font_size", 20)
	_online_section.add_child(_room_code_label)

	_online_status_label = Label.new()
	_online_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_section.add_child(_online_status_label)

	_online_start_btn = Button.new()
	_online_start_btn.text = "Start Online Game"
	_online_start_btn.add_theme_font_size_override("font_size", 18)
	_online_start_btn.visible = false
	_online_start_btn.pressed.connect(_on_online_start_pressed)
	_online_section.add_child(_online_start_btn)


func _on_host_pressed() -> void:
	_is_hosting = true
	_online_section.visible = true
	_online_status_label.text = "Connecting to relay server…"
	_room_code_label.text = ""
	_online_start_btn.visible = false
	_matchmaker.host()


func _on_join_pressed() -> void:
	var code := _join_code_input.text.strip_edges().to_upper()
	if code.is_empty():
		return
	_is_hosting = false
	_online_section.visible = true
	_online_status_label.text = "Connecting…"
	_room_code_label.text = ""
	_online_start_btn.visible = false
	_matchmaker.join(code)


func _on_room_created(code: String) -> void:
	_room_code_label.text = "Room code: %s" % code
	_online_status_label.text = "Waiting for opponent to join…"


func _on_opponent_connected() -> void:
	if _is_hosting:
		_online_status_label.text = "Opponent connected!"
		_online_start_btn.visible = true
	else:
		_online_status_label.text = "Connected! Waiting for host to start…"


func _on_opponent_ready_to_start() -> void:
	# Joiner: host has started the game — enter as player 1 (remote = player 0).
	GameConfig.online_mode = true
	GameConfig.is_host = false
	GameConfig.local_player_index = 1
	GameConfig.player_count = 2
	GameConfig.player_types[0] = GameSystem.PlayerType.REMOTE
	GameConfig.player_types[1] = GameSystem.PlayerType.HUMAN
	GameConfig.ai_difficulties[0] = -1
	GameConfig.ai_difficulties[1] = -1
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_online_start_pressed() -> void:
	# Host: notify joiner then enter as player 0 (remote = player 1).
	_matchmaker.start_match()
	GameConfig.online_mode = true
	GameConfig.is_host = true
	GameConfig.local_player_index = 0
	GameConfig.player_count = 2
	GameConfig.player_types[0] = GameSystem.PlayerType.HUMAN
	GameConfig.player_types[1] = GameSystem.PlayerType.REMOTE
	GameConfig.ai_difficulties[0] = -1
	GameConfig.ai_difficulties[1] = -1
	get_tree().change_scene_to_file("res://scenes/main.tscn")
