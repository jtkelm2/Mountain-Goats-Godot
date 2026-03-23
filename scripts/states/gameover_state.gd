extends RefCounted
## Gameover gamestate: game stops accepting moves.

var ps  # PlayState reference (untyped: loaded at runtime, class resolution unavailable)
var gamestate_tag: String = Reg.GS_GAMEOVER


func _init(play_state) -> void:
	ps = play_state


func refresh():
	GameSystem.mouse_mgr.set_active([])
	return self


func handle(_event: GameEvent) -> void:
	pass
