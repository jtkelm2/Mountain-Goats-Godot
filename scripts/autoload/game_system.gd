extends Node
## Global game system singleton. Autoloaded as "GameSystem".
## Holds references to all subsystems and the main scene.

var ps = null  # PlayState — untyped: autoload is parsed before PlayState is known

var events: Events = null
var dragger: Dragger = null
var mouse_mgr: MouseManager = null
var players: Array = []  # Array[Player]

enum PlayerType { HUMAN, AI }

class Player:
	var type: int
	var ai = null  # AIManager or null


func init_system(play_state) -> void:
	ps = play_state
	Reg.init_reg()

	ps.current_player = 0
	ps.game_ending_this_round = false

	dragger = Dragger.new()
	ps.add_child(dragger)
	mouse_mgr = MouseManager.new()
	ps.add_child(mouse_mgr)
	events = Events.new(ps)

	_init_ai(ps)


func _init_ai(play_state) -> void:
	var AIManagerScript = load("res://scripts/ai/ai_manager.gd")
	var AILabScript = load("res://scripts/ai/ai_lab.gd")
	var ai_func: Callable = AILabScript.handcraft_score_ai()

	var human := Player.new()
	human.type = PlayerType.HUMAN
	players = [human]

	for _i in range(3):
		var p := Player.new()
		p.type = PlayerType.AI
		p.ai = AIManagerScript.new(play_state, ai_func)
		players.append(p)


func prompt_ai(gamestate) -> void:
	var player_info: Player = players[ps.current_player]
	if player_info.type == PlayerType.AI:
		player_info.ai.on_prompt(gamestate)
