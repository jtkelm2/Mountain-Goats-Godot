class_name Token
extends GamePiece
## Represents a point token (mountain or bonus).

var token_kind: int = Reg.TokenKind.MOUNTAIN  # Reg.TokenKind enum
var token_mountain: int = 0  # For MOUNTAIN tokens: which mountain (5-10)
var token_bonus_value: int = 0  # For BONUS tokens: point value
var awarded: bool = false


func setup(tx: float, ty: float, kind: int, n: int) -> void:
	position = Vector2(tx, ty)
	awarded = false
	is_moving = false
	teleport_mode = true

	if kind == Reg.TokenKind.MOUNTAIN:
		token_kind = Reg.TokenKind.MOUNTAIN
		token_mountain = n
		load_spritesheet("res://assets/token.png", Reg.TOKEN_SIZE, Reg.TOKEN_SIZE)
		frame = n - 5
	else:
		token_kind = Reg.TokenKind.BONUS
		token_bonus_value = n
		load_spritesheet("res://assets/bonustoken.png", Reg.TOKEN_SIZE * 2, Reg.TOKEN_SIZE)
		@warning_ignore("integer_division")
		frame = roundi((n - 6) / 3.0)

	GameSystem.mouse_mgr.init_clickable(self, Reg.TAG_TOKEN)


func get_tag() -> String:
	return Reg.TAG_TOKEN


func token_value() -> int:
	if token_kind == Reg.TokenKind.MOUNTAIN:
		return token_mountain
	return token_bonus_value


func toggle_preview(enabled: bool) -> void:
	toggle_transparing(enabled)
