extends Node
## Global game system singleton. Autoloaded as "GameSystem".
## Holds references to all subsystems and the main scene.

var ps = null  # Main scene (PlayState equivalent)

var events: Events = null
var dragger: Dragger = null
var effects: Effects = null
var mouse_mgr: MouseManager = null
var players: Dictionary = {}  # int -> {type: "human"} or {type: "ai", ai: AIManager}

enum PlayerType { HUMAN, AI }


func init_system(play_state) -> void:
	ps = play_state
	Reg.init_reg()

	ps.current_player = 0
	ps.game_ending_this_round = false

	dragger = Dragger.new()
	ps.add_child(dragger)
	effects = Effects.new()
	ps.add_child(effects)
	mouse_mgr = MouseManager.new()
	ps.add_child(mouse_mgr)
	events = Events.new(ps)

	_init_ai(ps)


func _init_ai(play_state) -> void:
	var AIManagerScript = load("res://scripts/ai/ai_manager.gd")
	var AILabScript = load("res://scripts/ai/ai_lab.gd")
	var ai_func: Callable = AILabScript.handcraft_score_ai()

	players = {
		0: {"type": PlayerType.HUMAN},
		1: {"type": PlayerType.AI, "ai": AIManagerScript.new(play_state, ai_func)},
		2: {"type": PlayerType.AI, "ai": AIManagerScript.new(play_state, ai_func)},
		3: {"type": PlayerType.AI, "ai": AIManagerScript.new(play_state, ai_func)},
	}


func prompt_ai(gamestate) -> void:
	var player_info: Dictionary = players[ps.current_player]
	if player_info.type == PlayerType.AI:
		player_info.ai.on_prompt(gamestate)
