class_name Goat
extends GamePiece
## A player's goat piece that climbs mountains.

var square = null  # Current Square reference
var player: int = 0


func setup(p: int, starting_square) -> void:
	load_spritesheet("res://assets/goat.png", Reg.GOAT_SIZE, Reg.GOAT_SIZE)
	frame = p
	player = p
	teleport_mode = true
	starting_square.add_goat(self)
	teleport_mode = false
	is_moving = false
	GameSystem.mouse_mgr.init_clickable(self, Reg.TAG_GOAT)


func get_tag() -> String:
	return Reg.TAG_GOAT


func toggle_preview(enabled: bool) -> void:
	toggle_transparing(enabled)
