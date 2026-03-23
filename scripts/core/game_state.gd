class_name GameState
extends Node
## Base class for all game states. Extend this and override refresh() and handle().

var ps = null  # PlayState — untyped to avoid circular parse-time dependency
var gamestate_tag: String = ""


func refresh() -> GameState:
	return self


func handle(_event: GameEvent) -> void:
	pass
