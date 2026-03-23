class_name GameoverState
extends "res://scripts/core/game_state.gd"
## Gameover gamestate: game stops accepting moves.


func _init(play_state) -> void:
	ps = play_state
	gamestate_tag = Reg.GS_GAMEOVER


func refresh():
	GameSystem.mouse_mgr.set_active([])
	return self


func handle(_event) -> void:
	pass
