extends Node
## Global game system singleton. Autoloaded as "GameSystem".
## Holds references to all subsystems and the main scene.

var ps = null  # PlayState — untyped: autoload is parsed before PlayState is known

var events: Events = null
var dragger: Dragger = null
var mouse_mgr: MouseManager = null
var players: Array = []  # Array[Player]

enum PlayerType { HUMAN, AI, REMOTE }

class Player:
	var type: int
	var controller = null  # AIManager, RemoteManager, or null (human)


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

	_init_players(ps)


func _init_players(play_state) -> void:
	var AIManagerScript = load("res://scripts/ai/ai_manager.gd")
	var AILabScript = load("res://scripts/ai/ai_lab.gd")
	var RemoteManagerScript = load("res://scripts/net/remote_manager.gd")
	players = []

	for i in range(GameConfig.player_count):
		var p := Player.new()
		p.type = GameConfig.player_types[i]
		match p.type:
			PlayerType.AI:
				p.controller = AIManagerScript.new(
					play_state,
					_callable_for_difficulty(AILabScript, GameConfig.ai_difficulties[i])
				)
			PlayerType.REMOTE:
				p.controller = RemoteManagerScript.new()
		players.append(p)


func _callable_for_difficulty(AILabScript, difficulty: int) -> Callable:
	match difficulty:
		GameConfig.AIDifficulty.EASY:
			return AILabScript.random_ai()
		GameConfig.AIDifficulty.MEDIUM:
			return AILabScript.tokenized_weighted_mover_ai()
		_:  # HARD
			return AILabScript.handcraft_score_ai()


func prompt_player(gamestate) -> void:
	var player_info: Player = players[ps.current_player]
	if player_info.controller != null:
		player_info.controller.on_prompt(gamestate)
