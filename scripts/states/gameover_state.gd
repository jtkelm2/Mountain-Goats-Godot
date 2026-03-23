class_name GameoverState
extends GameState
## Gameover gamestate: game stops accepting moves.


func _init(play_state: PlayState) -> void:
	ps = play_state
	gamestate_tag = Reg.GS_GAMEOVER


func refresh() -> GameState:
	GameSystem.mouse_mgr.set_active([])
	return self


func handle(_event: GameEvent) -> void:
	pass
